/*
@Name: ECM_VolumeInputScreenControllerTest
@description: This Class is to cover the "ECM_VolumeInputScreenController" 
@History                                                            

VERSION    AUTHOR                DATE              DETAIL
1.0      Saurav Prasad							Initial Development
1.1      Manikandan T         16/07/2021        Development for ECM-4663
1.2		 Saurav Prasad		  16/07/2021		Development for ECM-4663
1.3		 Saurav Prasad		  20/12/2021		ECM-5067 - CLONE - Tech Debt_Work on test CLS to maintain best practice_GLO_Part 2

*/

@isTest
public class ECM_VolumeInputScreenControllerTest {
    @isTest
    public static void dataSetup(){
        //User profile creation
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = ECM_UtilityTestClass.createUser('testcm1230@test.com',prof.Id);
        usr.firstName = 'test1';
        insert usr;
        Id geographyId;
        //Spain geography
        System.runAs(usr){
            geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        }
        //create territory
        Territory__c testterritory=ECM_UtilityTestClass.createTerritory(geographyId);
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        //create territory hierarchy
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        //update territory hierarchy
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Country__c= geographyId;
        testterritory.Region__c=hirarchy.Id;
        update testterritory;
        //create agreement type
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        //create market setting
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        //update market setting
        mktSetting.Depletion_market__c=false;
        mktSetting.Ecm_Enable_Target__c = true;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay at tier 3 rate any exceeding volume (opt.1)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        update mktSetting;
        //retrieving record type for Pick_Up_Options__c
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //create banner type record
        Pick_Up_Options__c banner= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        banner.Name='Range[ES]';
        insert banner;
        //create budget type record
        Pick_Up_Options__c budgetType= ECM_UtilityTestClass.createPickUpOption(geographyId,budgetTypeRecordTypeId);
        budgetType.Name='TI[ES]';
        insert budgetType;
        //retrieve outlet record type for account
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        //create outlet acoount
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.IsOperator__c=true;
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Email_for_contracts_payments__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        insert outlet; 
        outlet.country__c = geographyId;
        update outlet;
        //create payment frequency
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = Date.today().toStartOfMonth();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.ECM_Duration__c=12;
        objContract.Ownerid = usr.id;
        insert objContract;
        objContract.Status ='Active';
        update objContract;
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product uom
        Product_UOM__c prdtUOM = ECM_UtilityTestClass.createProductUOM(product.Id);
        prdtUOM.Unique_ID__c='Test123';
        insert prdtUOM;
        //create product uom
        Product_UOM__c prdtUOM1 = ECM_UtilityTestClass.createProductUOM(product1.Id);
        prdtUOM1.Unique_ID__c='Test1234';
        insert prdtUOM1;
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = usr.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = usr.Id;
        insert marketassort1;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort.Id);
        insert productagg;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg1 = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort1.Id);
        insert productagg1;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort.id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        insert newcontractitem;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort1.id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        insert newcontractitem1;
        //create tier
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        //retrieve contract
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        //create Depletions
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i++){
            Depletions__c tempUpsert = new Depletions__c();
            tempUpsert.Contract__c = con.Id;
            tempUpsert.ECM_Geography__c = con.Account.Country__c;
            tempUpsert.ECM_Outlet__c = con.Accountid;
            tempUpsert.ECM_UoM__c = 'BTL';
            tempUpsert.ECM_Volume__c = 100;
            tempUpsert.Forecast_Volume__c = 10;
            tempUpsert.ECM_Product__c = product.id;
            DateTime monthName =objContract.StartDate.addMonths(i);
            String monthFormat =monthName.format('MMMMM')+'_'+monthName.format('yyyy');
            tempUpsert.Unique_ID__c =  con.Id+'_'+con.Accountid+'_'+product.id+'_'+monthFormat;
            tempUpsert.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
            tempUpsert.ECM_End_Period__c = objContract.StartDate.addMonths(i+1).addDays(-1);
            tempUpsert.OwnerId = usr.id;
            delpetionList.add(tempUpsert);
        }
        Insert delpetionList;
        //create Payment_Summary
        List<ECM_Payment_Summary__c> payList = new List<ECM_Payment_Summary__c>();
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i=i+3){
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Contract__c = objContract.Id;
        paymemtSummary.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
        paymemtSummary.ECM_End_Period__c = objContract.StartDate.addMonths(i+3).addDays(-1);
        paymemtSummary.ECM_Budget_types__c = budgetType.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        payList.add(paymemtSummary);
        }
        Insert payList;
        //create Payment_Summary_Item
        list<ECM_Payment_Summary_Item__c> payItemList = new List<ECM_Payment_Summary_Item__c>();
        for(Integer i=0;i<payList.size();i++){
            ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem.ECM_Confirm__c = true;
            paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
            paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
            paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
            payItemList.add(paymemtSummaryItem);
            //create Payment_Summary_Item
            ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem1.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem1.ECM_Confirm__c = true;
            paymemtSummaryItem1.ECM_Confirmed_Volume__c = 10;
            paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
            paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =100;
            payItemList.add(paymemtSummaryItem1);
        }
        Insert payItemList;
        
        Test.startTest();
        //update Payment_Summary
        for(Integer i=0;i<payList.size();i++){
            payList[i].ECM_Payment_Summary_Status__c = Math.MOD(i, 2) == 0?'Completed':'Open';
        }
        update payList;
        //function call
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        //Assert check for retrieved records
        system.assertEquals(12,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'Wrong number of records recieved');
        //run method as per sales rep
        System.runAs(usr){ 
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        }
        //ECM-5617
        //Testing sample data. No Link with Database
        //List<Object> s = ECM_VolumeInputScreenController.getMap(30);
        Test.stopTest();
    }
    
    @isTest
    public static void dataSetup1(){
        //User profile creation
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = ECM_UtilityTestClass.createUser('testcm124@test.com',prof.Id);
        usr.firstName = 'test1';
        insert usr;
        Id geographyId;
        //Spain geography
        System.runAs(usr){
            geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        }
        //create territory
        Territory__c testterritory=ECM_UtilityTestClass.createTerritory(geographyId);
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        //create territory hierarchy
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        //update territory hierarchy
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Country__c= geographyId;
        testterritory.Region__c=hirarchy.Id;
        update testterritory;
        //create agreement type
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        //create market setting
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        //update market setting
        mktSetting.Depletion_market__c=false;
        mktSetting.Ecm_Enable_Target__c = true;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay at tier 3 rate any exceeding volume (opt.1)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        update mktSetting;
        //retrieving record type for Pick_Up_Options__c
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //create banner type record
        Pick_Up_Options__c banner= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        banner.Name='Range[ES]';
        insert banner;
        //create budget type record
        Pick_Up_Options__c budgetType= ECM_UtilityTestClass.createPickUpOption(geographyId,budgetTypeRecordTypeId);
        budgetType.Name='TI[ES]';
        insert budgetType;
        //retrieve outlet record type for account
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        //create outlet acoount
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.IsOperator__c=true;
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Email_for_contracts_payments__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        insert outlet; 
        outlet.country__c = geographyId;
        update outlet;
        //create payment frequency
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = Date.today().toStartOfMonth();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.ECM_Duration__c=12;
        objContract.Ownerid = usr.id;
        insert objContract;
        objContract.Status ='Active';
        update objContract;
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product uom
        Product_UOM__c prdtUOM = ECM_UtilityTestClass.createProductUOM(product.Id);
        prdtUOM.Unique_ID__c='Test123';
        insert prdtUOM;
        //create product uom
        Product_UOM__c prdtUOM1 = ECM_UtilityTestClass.createProductUOM(product1.Id);
        prdtUOM1.Unique_ID__c='Test1234';
        insert prdtUOM1;
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = usr.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = usr.Id;
        insert marketassort1;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort.Id);
        insert productagg;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg1 = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort1.Id);
        insert productagg1;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort.id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        insert newcontractitem;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort1.id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        insert newcontractitem1;
        //create tier
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        //retrieve contract
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        //create Depletions
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i++){
            Depletions__c tempUpsert = new Depletions__c();
            tempUpsert.Contract__c = con.Id;
            tempUpsert.ECM_Geography__c = con.Account.Country__c;
            tempUpsert.ECM_Outlet__c = con.Accountid;
            tempUpsert.ECM_UoM__c = 'BTL';
            tempUpsert.ECM_Volume__c = 100;
            tempUpsert.Forecast_Volume__c = 10;
            tempUpsert.ECM_Product__c = product.id;
            DateTime monthName =objContract.StartDate.addMonths(i);
            String monthFormat =monthName.format('MMMMM')+'_'+monthName.format('yyyy');
            tempUpsert.Unique_ID__c =  con.Id+'_'+con.Accountid+'_'+product.id+'_'+monthFormat;
            tempUpsert.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
            tempUpsert.ECM_End_Period__c = objContract.StartDate.addMonths(i+1).addDays(-1);
            tempUpsert.OwnerId = usr.id;
            delpetionList.add(tempUpsert);
        }
        Insert delpetionList;
        //create Payment_Summary
        List<ECM_Payment_Summary__c> payList = new List<ECM_Payment_Summary__c>();
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i=i+3){
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Contract__c = objContract.Id;
        paymemtSummary.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
        paymemtSummary.ECM_End_Period__c = objContract.StartDate.addMonths(i+3).addDays(-1);
        paymemtSummary.ECM_Budget_types__c = budgetType.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        payList.add(paymemtSummary);
        }
        Insert payList;
        //create Payment_Summary_Item
        list<ECM_Payment_Summary_Item__c> payItemList = new List<ECM_Payment_Summary_Item__c>();
        for(Integer i=0;i<payList.size();i++){
            ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem.ECM_Confirm__c = true;
            paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
            paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
            paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
            payItemList.add(paymemtSummaryItem);
            //create Payment_Summary_Item
            ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem1.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem1.ECM_Confirm__c = true;
            paymemtSummaryItem1.ECM_Confirmed_Volume__c = 10;
            paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
            paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =100;
            payItemList.add(paymemtSummaryItem1);
        }
        Insert payItemList;
        
        Test.startTest();
        //update Payment_Summary
        for(Integer i=0;i<payList.size();i++){
            payList[i].ECM_Payment_Summary_Status__c = Math.MOD(i, 2) == 0?'Completed':'Open';
        }
        update payList;
        //function call
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        //Assert check for retrieved records
        system.assertEquals(12,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'Wrong number of records recieved');
        //update tier
        tier.ECM_Tier_1_volume_limit__c=400;
        update tier;
        //Assert check for retrieved records
        system.assertEquals(400,tier.ECM_Tier_1_volume_limit__c,'Wrong Tier 1 volume limit');
        //run method as per sales rep
        System.runAs(usr){ 
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        }
        Test.stopTest();
    }
    @isTest
    public static void dataSetup2(){
        //User profile creation
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = ECM_UtilityTestClass.createUser('testcm125@test.com',prof.Id);
        usr.firstName = 'test1';
        insert usr;
        Id geographyId;
        //Spain geography
        System.runAs(usr){
            geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        }
        //create territory
        Territory__c testterritory=ECM_UtilityTestClass.createTerritory(geographyId);
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        //create territory hierarchy
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        //update territory hierarchy
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Country__c= geographyId;
        testterritory.Region__c=hirarchy.Id;
        update testterritory;
        //create agreement type
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        //create market setting
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        //update market setting
        mktSetting.Depletion_market__c=false;
        mktSetting.Ecm_Enable_Target__c = true;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay at tier 3 rate any exceeding volume (opt.1)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        update mktSetting;
        //retrieving record type for Pick_Up_Options__c
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //create banner type record
        Pick_Up_Options__c banner= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        banner.Name='Range[ES]';
        insert banner;
        //create budget type record
        Pick_Up_Options__c budgetType= ECM_UtilityTestClass.createPickUpOption(geographyId,budgetTypeRecordTypeId);
        budgetType.Name='TI[ES]';
        insert budgetType;
        //retrieve outlet record type for account
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        //create outlet acoount
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.IsOperator__c=true;
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Email_for_contracts_payments__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        insert outlet; 
        outlet.country__c = geographyId;
        update outlet;
        //create payment frequency
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = Date.today().toStartOfMonth();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.ECM_Duration__c=12;
        objContract.Ownerid = usr.id;
        insert objContract;
        objContract.Status ='Active';
        update objContract;
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product uom
        Product_UOM__c prdtUOM = ECM_UtilityTestClass.createProductUOM(product.Id);
        prdtUOM.Unique_ID__c='Test123';
        insert prdtUOM;
        //create product uom
        Product_UOM__c prdtUOM1 = ECM_UtilityTestClass.createProductUOM(product1.Id);
        prdtUOM1.Unique_ID__c='Test1234';
        insert prdtUOM1;
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = usr.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = usr.Id;
        insert marketassort1;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort.Id);
        insert productagg;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg1 = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort1.Id);
        insert productagg1;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort.id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        insert newcontractitem;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort1.id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        insert newcontractitem1;
        //create tier
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        //retrieve contract
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        //create Depletions
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i++){
            Depletions__c tempUpsert = new Depletions__c();
            tempUpsert.Contract__c = con.Id;
            tempUpsert.ECM_Geography__c = con.Account.Country__c;
            tempUpsert.ECM_Outlet__c = con.Accountid;
            tempUpsert.ECM_UoM__c = 'BTL';
            tempUpsert.ECM_Volume__c = 100;
            tempUpsert.Forecast_Volume__c = 10;
            tempUpsert.ECM_Product__c = product.id;
            DateTime monthName =objContract.StartDate.addMonths(i);
            String monthFormat =monthName.format('MMMMM')+'_'+monthName.format('yyyy');
            tempUpsert.Unique_ID__c =  con.Id+'_'+con.Accountid+'_'+product.id+'_'+monthFormat;
            tempUpsert.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
            tempUpsert.ECM_End_Period__c = objContract.StartDate.addMonths(i+1).addDays(-1);
            tempUpsert.OwnerId = usr.id;
            delpetionList.add(tempUpsert);
        }
        Insert delpetionList;
        //create Payment_Summary
        List<ECM_Payment_Summary__c> payList = new List<ECM_Payment_Summary__c>();
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i=i+3){
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Contract__c = objContract.Id;
        paymemtSummary.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
        paymemtSummary.ECM_End_Period__c = objContract.StartDate.addMonths(i+3).addDays(-1);
        paymemtSummary.ECM_Budget_types__c = budgetType.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        payList.add(paymemtSummary);
        }
        Insert payList;
        //create Payment_Summary_Item
        list<ECM_Payment_Summary_Item__c> payItemList = new List<ECM_Payment_Summary_Item__c>();
        for(Integer i=0;i<payList.size();i++){
            ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem.ECM_Confirm__c = true;
            paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
            paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
            paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
            payItemList.add(paymemtSummaryItem);
            //create Payment_Summary_Item
            ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem1.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem1.ECM_Confirm__c = true;
            paymemtSummaryItem1.ECM_Confirmed_Volume__c = 10;
            paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
            paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =100;
            payItemList.add(paymemtSummaryItem1);
        }
        Insert payItemList;
        
        Test.startTest();
        //update Payment_Summary
        for(Integer i=0;i<payList.size();i++){
            payList[i].ECM_Payment_Summary_Status__c = Math.MOD(i, 2) == 0?'Completed':'Open';
        }
        update payList;
        //function call
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        //Assert check for retrieved records
        system.assertEquals(12,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'Wrong number of records recieved');
        //run method as per sales rep
        tier.ECM_Tier_2_volume_limit__c=400;
        update tier;
        //Assert check for retrieved records
        system.assertEquals(400,tier.ECM_Tier_2_volume_limit__c,'Wrong Tier 2 volume limit');
        System.runAs(usr){ 
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        }
        Test.stopTest();
    }
    @isTest
    public static void dataSetup3(){
        //User profile creation
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = ECM_UtilityTestClass.createUser('testcm126@test.com',prof.Id);
        usr.firstName = 'test1';
        insert usr;
        Id geographyId;
        //Spain geography
        System.runAs(usr){
            geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        }
        //create territory
        Territory__c testterritory=ECM_UtilityTestClass.createTerritory(geographyId);
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        //create territory hierarchy
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        //update territory hierarchy
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Country__c= geographyId;
        testterritory.Region__c=hirarchy.Id;
        update testterritory;
        //create agreement type
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.getAgreementType(geographyId);
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        //create market setting
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        //update market setting
        mktSetting.Depletion_market__c=false;
        mktSetting.Ecm_Enable_Target__c = true;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay at tier 3 rate any exceeding volume (opt.1)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        update mktSetting;
        //retrieving record type for Pick_Up_Options__c
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        //create banner type record
        Pick_Up_Options__c banner= ECM_UtilityTestClass.createPickUpOption(geographyId,bannerRecordTypeId);
        banner.Name='Range[ES]';
        insert banner;
        //create budget type record
        Pick_Up_Options__c budgetType= ECM_UtilityTestClass.createPickUpOption(geographyId,budgetTypeRecordTypeId);
        budgetType.Name='TI[ES]';
        insert budgetType;
        //retrieve outlet record type for account
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
        //create outlet acoount
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test_Outlet';
        outlet.RecordTypeId = accRecordTypeId;
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Sydney';
        outlet.IsOperator__c=true;
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountry = 'Australia';
        outlet.BillingCountryCode = 'AU';
        outlet.Outlet_Email_Address__c = 'test@test.com';
        outlet.Email_for_contracts_payments__c = 'test@test.com';
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        insert outlet; 
        outlet.country__c = geographyId;
        update outlet;
        //create payment frequency
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        //retrieve outlet record type for contract
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        //create contract
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = Date.today().addMonths(13).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = Date.today().toStartOfMonth();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.ECM_Duration__c=12;
        objContract.Ownerid = usr.id;
        insert objContract;
        objContract.Status ='Active';
        update objContract;
        //create product
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;
        //create product
        Product__c product1 = ECM_UtilityTestClass.createProduct(geographyId,'Test 2');
        product1.Product_Full_Name__c='Test 2';
        insert product1;
        //create product uom
        Product_UOM__c prdtUOM = ECM_UtilityTestClass.createProductUOM(product.Id);
        prdtUOM.Unique_ID__c='Test123';
        insert prdtUOM;
        //create product uom
        Product_UOM__c prdtUOM1 = ECM_UtilityTestClass.createProductUOM(product1.Id);
        prdtUOM1.Unique_ID__c='Test1234';
        insert prdtUOM1;
        //create marketassort product 
        Market_Assortment_Product__c marketassort = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        marketassort.OwnerId = usr.Id;
        insert marketassort;
        //create marketassort product 
        Market_Assortment_Product__c marketassort1 = ECM_UtilityTestClass.createMarketAssortmentProduct(product1.Id,geographyId);
        marketassort1.OwnerId = usr.Id;
        insert marketassort1;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort.Id);
        insert productagg;
        //create Product_Agreement
        ECM_Product_Agreement__c productagg1 = ECM_UtilityTestClass.createProductAgreement(contractType.Id,Marketassort1.Id);
        insert productagg1;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort.id);
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        newcontractitem.ECM_Volume_Target_per_PF__c = 10.5;
        insert newcontractitem;
        //create Contract_Item
        ECM_Contract_Item__c newcontractitem1= ECM_UtilityTestClass.createcontractitem(objContract.Id,Marketassort1.id);
        newcontractitem1.ECM_UoM__c = '1';
        newcontractitem1.ECM_Lead_Brand__c = false;
        newcontractitem1.ECM_Volume_Target_per_PF__c = 5.5;
        insert newcontractitem1;
        //create tier
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        //retrieve contract
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        //create Depletions
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i++){
            Depletions__c tempUpsert = new Depletions__c();
            tempUpsert.Contract__c = con.Id;
            tempUpsert.ECM_Geography__c = con.Account.Country__c;
            tempUpsert.ECM_Outlet__c = con.Accountid;
            tempUpsert.ECM_UoM__c = 'BTL';
            tempUpsert.ECM_Volume__c = 100;
            tempUpsert.Forecast_Volume__c = 10;
            tempUpsert.ECM_Product__c = product.id;
            DateTime monthName =objContract.StartDate.addMonths(i);
            String monthFormat =monthName.format('MMMMM')+'_'+monthName.format('yyyy');
            tempUpsert.Unique_ID__c =  con.Id+'_'+con.Accountid+'_'+product.id+'_'+monthFormat;
            tempUpsert.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
            tempUpsert.ECM_End_Period__c = objContract.StartDate.addMonths(i+1).addDays(-1);
            tempUpsert.OwnerId = usr.id;
            delpetionList.add(tempUpsert);
        }
        Insert delpetionList;
        //create Payment_Summary
        List<ECM_Payment_Summary__c> payList = new List<ECM_Payment_Summary__c>();
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i=i+3){
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Contract__c = objContract.Id;
        paymemtSummary.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
        paymemtSummary.ECM_End_Period__c = objContract.StartDate.addMonths(i+3).addDays(-1);
        paymemtSummary.ECM_Budget_types__c = budgetType.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        payList.add(paymemtSummary);
        }
        Insert payList;
        //create Payment_Summary_Item
        list<ECM_Payment_Summary_Item__c> payItemList = new List<ECM_Payment_Summary_Item__c>();
        for(Integer i=0;i<payList.size();i++){
            ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem.ECM_Confirm__c = true;
            paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
            paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
            paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
            payItemList.add(paymemtSummaryItem);
            //create Payment_Summary_Item
            ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
            paymemtSummaryItem1.ECM_Payment_Summary__c = payList[i].Id;
            paymemtSummaryItem1.ECM_Confirm__c = true;
            paymemtSummaryItem1.ECM_Confirmed_Volume__c = 10;
            paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem1.id;			
            paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =100;
            payItemList.add(paymemtSummaryItem1);
        }
        Insert payItemList;
        
        Test.startTest();
        //update Payment_Summary
        for(Integer i=0;i<payList.size();i++){
            payList[i].ECM_Payment_Summary_Status__c = Math.MOD(i, 2) == 0?'Completed':'Open';
        }
        update payList;
        //function call
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        //Assert check for retrieved records
        system.assertEquals(12,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'Wrong number of records recieved');
        //run method as per sales rep
        tier.ECM_Tier_3_volume_limit__c=300;
        update tier;
        //Assert check for retrieved records
        system.assertEquals(300,tier.ECM_Tier_3_volume_limit__c,'Wrong Tier 3 volume limit');
        System.runAs(usr){ 
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        }
        Test.stopTest();
    }
}