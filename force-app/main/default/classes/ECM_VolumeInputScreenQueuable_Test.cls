/*
 * Class Name : ECM_VolumeInputScreenQueuable_Test
 * @description: This Class used to queue the data from "ECM_updateDepletionsQueuable"
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0      Manikandan T         16/07/2021        	Initial Development
 * 2.0		Saurav Prasad		 16/07/2021			Development for ECM-4663
 * 3.0		Sayan Mullick		 03/09/2021			Development for ECM-4748 -> Payment Summary %Achieved table calc.
 * 4.0      Joshraj Sen          03/04/2024         SCA Fix 152305
*/
    
@isTest
public class ECM_VolumeInputScreenQueuable_Test {
    
    static List<Pick_Up_Options__c> pickUps=new List<Pick_Up_Options__c>();
    static Account outlet=new Account();
    static  User createUser()
    {
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        insert usr;
        return usr;
    }
    static Territory__c getTerritory(Id geographyId,User usr)
    {
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        return testterritory;
        
    }
    static Territory_Hierarchy__c getRegion(Id geographyId,User usr,Territory__c testterritory)
    {
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;        
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Country__c= geographyId;
        testterritory.Region__c=hirarchy.Id;
        update testterritory;
        return hirarchy;
    }
    static ECM_Contract_Type__c getContractType(Id geographyId)
    {
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name ; Brand ; Volume Target';
        insert contractType;
        return contractType;
    }
    static Market_Setting__c getMarketSetting(Id geographyID)
    {
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        mktSetting.Depletion_market__c=false;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay only per tier 3 volume limit (opt.2)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        update mktSetting;
        return mktSetting;
        
    }
    static List<Pick_Up_Options__c> getPickUpOptions(ID geographyId)
    {
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        List<Pick_Up_Options__c> pickups=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        pickups.add(banner);
        
        Pick_Up_Options__c budgetType= new Pick_Up_Options__c();
        budgetType.Name='TI[ES]';
        budgetType.Geography__c=geographyId;
        budgetType.RecordTypeId=budgetTypeRecordTypeId;
        pickups.add(budgetType);
        return pickups;
    }
    static Account getOutlet(Id geographyID)
    {
        String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();      
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
        return outlet;
    }
    static ECM_Payment_Frequency__c getPaymentFrequency(Id geographyId)
    {
        ECM_Payment_Frequency__c paymfreq=new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        //paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        return paymfreq;        
    }
    static Contract getContract(Territory__c testterritory,ECM_Contract_Type__c contractType,ECM_Payment_Frequency__c paymfreq)
    {
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();      
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = Date.today().addMonths(12).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=pickUps[0].Id;
        objContract.StartDate = Date.today().toStartOfMonth();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        insert objContract;
        objContract.Status ='Active';
        update objContract;
        return objContract;
        
    }
    static Product__c getProduct(Id geographyId)
    {
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Unique_ID__c='Test123';
        prdtUOM.Conversion_Factor__c = 2;
        insert prdtUOM;
        return product;        
    }
    static Market_Assortment_Product__c getMarketAssortmentProduct(Id geographyId,Product__c product)
    {
        Market_Assortment_Product__c marketassort=new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //Marketassort.ECM_Strategy__c='2';
        insert marketassort;
        return marketassort;
    }
    static ECM_Product_Agreement__c getProductAgreement(Market_Assortment_Product__c marketassort,ECM_Contract_Type__c contractType)    
    {
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        return productagg;       
    }
    static ECM_Contract_Item__c getContractItems(Contract objContract,Market_Assortment_Product__c marketassort)
    {
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        newcontractitem.ECM_UoM__c = '1';
        insert newcontractitem;
        return newcontractitem;      
    }
    static ECM_Tiering__c getTiering(ECM_Contract_Item__c newcontractitem)
    {       
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=1;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=2;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=3;
        insert tier;
        return tier;       
    }
    static ECM_Tiering__c getTiering2(ECM_Contract_Item__c newcontractitem)
    {
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=400;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=500;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=600;
        insert tier;
        return tier;
    }
    static ECM_Tiering__c getTiering3(ECM_Contract_Item__c newcontractitem)
    {
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=300;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=400;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=500;
        insert tier;
        return tier;
    }
    static ECM_Tiering__c getTiering4(ECM_Contract_Item__c newcontractitem)
    {
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=200;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=300;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=400;
        insert tier;
        return tier;
    }
        static ECM_Tiering__c getTiering5(ECM_Contract_Item__c newcontractitem)
    {
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier.ECM_Contract_Item__c=newcontractitem.Id;
        tier.ECM_Tier_1_rate_per_UoM__c=0.1;
        tier.ECM_Tier_1_volume_limit__c=100;
        tier.ECM_Tier2_rate_per_UoM__c=0.2;
        tier.ECM_Tier_2_volume_limit__c=200;
        tier.ECM_Tier_3_rate_per_UoM__c=0.3;
        tier.ECM_Tier_3_volume_limit__c=300;
        insert tier;
        return tier;
    }
    static List<ECM_Payment_Summary__c> getPaymentSummaries(Contract objContract)
    {
        List<ECM_Payment_Summary__c> paymentSummaries=new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = objContract.Id;
        paymemtSummary.ECM_Start_Period__c = Date.today().toStartOfMonth();
        paymemtSummary.ECM_End_Period__c = Date.today().addMonths(3).toStartOfMonth().addDays(-1);
        paymemtSummary.ECM_Budget_types__c = pickUps[1].Id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        // paymemtSummary.ownerid = uid;
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymentSummaries.add(paymemtSummary);
        
        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = objContract.id;
        paymemtSummary2.ECM_Start_Period__c = Date.today().addMonths(3).toStartOfMonth();
        paymemtSummary2.ECM_End_Period__c = Date.today().addMonths(6).toStartOfMonth().addDays(-1);
        paymemtSummary2.ECM_Budget_types__c = pickUps[1].Id;
        paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary2.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymentSummaries.add(paymemtSummary2);
        insert paymentSummaries;
        return paymentSummaries;
        
    }
    static List<ECM_Payment_Summary_Item__c> getPaymentSummaryItems(List<ECM_Payment_Summary__c> paymentSummaries,ECM_Contract_Item__c newcontractitem)
    {
        List<ECM_Payment_Summary_Item__c> psi =new List<ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItem.ECM_Payment_Summary__c = paymentSummaries[0].Id;
        psi.add(paymemtSummaryItem);
        System.debug(LoggingLevel.Debug,'paymemtSummaryItem--->'+paymemtSummaryItem);
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem1.ECM_Confirm__c = true;
        paymemtSummaryItem1.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItem1.ECM_Payment_Summary__c = paymentSummaries[1].Id;   
        psi.add(paymemtSummaryItem1);
        insert psi;
        return psi;
        
    }
    static List<Depletions__c> getDepletions(Contract objContract,Product__c product)
    {
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
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
            System.debug(LoggingLevel.Debug,'tempUpsert--->'+tempUpsert);
            delpetionList.add(tempUpsert);
            
        }
        Insert delpetionList;
        return delpetionList;        
    }
    static List<Depletions__c> getDepletionsManually(Account outlet,ID geographyId,Product__c product)
    {
        List<Depletions__c> deps =new List<Depletions__c>();
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outlet.id;
        dep.ECM_Geography__c=geographyId;
        dep.ECM_Start_Period__c = Date.today().toStartOfMonth();
        dep.ECM_End_Period__c = Date.today().addmonths(1).toStartOfMonth().addDays(-1);
        dep.ECM_Product__c = product.id;
        dep.Forecast_Volume__c = 10;
        deps.add(dep);
        Depletions__c dep1 = new Depletions__c();
        dep1.ECM_Volume__c = 100.00;
        dep1.ECM_Outlet__c = outlet.id;
        dep1.ECM_Geography__c=geographyId;
        dep1.ECM_Start_Period__c = system.today().addmonths(1).toStartOfMonth();
        dep1.ECM_End_Period__c = system.today().addmonths(2).toStartOfMonth().addDays(-1);
        dep1.ECM_Product__c = product.id;
        dep1.Forecast_Volume__c=200;
        deps.add(dep1);
        insert deps;
        return deps;
    }
    static ECM_Payment_Summary_Item__c getPaymentSummaryItemIndividually(ECM_Contract_Item__c newcontractitem,ECM_Payment_Summary__c paymemtSummary)
    {
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.Id;
        insert paymemtSummaryItem;
        return paymemtSummaryItem;
        
    }
    static List<ECM_Payment_Summary_Item__c> getPaymentSummaryItems2(List<ECM_Payment_Summary__c> paymemtSummary,ECM_Contract_Item__c newcontractitem)
    {
        List<ECM_Payment_Summary_Item__c> psi=new List<ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary[0].Id;
        psi.add(paymemtSummaryItem);
        System.debug(LoggingLevel.Debug,'paymemtSummaryItem--->'+paymemtSummaryItem);
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem1.ECM_Confirm__c = true;
        paymemtSummaryItem1.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItem1.ECM_Payment_Summary__c = paymemtSummary[1].Id;
        psi.add(paymemtSummaryItem1);
        insert psi;
        return psi;
    }
    static List<ECM_Payment_Summary_Item__c> getPaymentSummaryItems3(List<ECM_Payment_Summary__c> paymemtSummary,ECM_Contract_Item__c newcontractitem)
    {
        List<ECM_Payment_Summary_Item__c> psi=new List<ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary[0].id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        psi.add(paymemtSummaryItem);
        System.debug(LoggingLevel.Debug,'paymemtSummaryItem--->'+paymemtSummaryItem);
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem1.ECM_Payment_Summary__c =paymemtSummary[1].id;
        paymemtSummaryItem1.ECM_Confirm__c = true;
        paymemtSummaryItem1.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        psi.add(paymemtSummaryItem1);
        insert psi;
        return psi;
    }
    static List<Depletions__c> getDepletionsWithoutInsert(Contract objContract,Product__c product)
    {
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        for(Integer i=0;i<objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c);i++){
            Depletions__c tempUpsert = new Depletions__c();
            tempUpsert.Contract__c = con.Id;
            tempUpsert.ECM_Geography__c = con.Account.Country__c;
            tempUpsert.ECM_Outlet__c = con.Accountid;
            tempUpsert.ECM_UoM__c = 'BTL';
            tempUpsert.ECM_Volume__c = 1;
            tempUpsert.Forecast_Volume__c = 1;
            tempUpsert.ECM_Product__c = product.id;
            DateTime monthName =objContract.StartDate.addMonths(i);
            String monthFormat =monthName.format('MMMMM')+'_'+monthName.format('yyyy');
            tempUpsert.Unique_ID__c =  con.Id+'_'+con.Accountid+'_'+product.id+'_'+monthFormat;
            tempUpsert.ECM_Start_Period__c = objContract.StartDate.addMonths(i);
            tempUpsert.ECM_End_Period__c = objContract.StartDate.addMonths(i+1).addDays(-1);
            System.debug(LoggingLevel.Debug,'tempUpsert--->'+tempUpsert);
            delpetionList.add(tempUpsert);
            
        }
        return delpetionList;
    }
    static List<Depletions__c> getDepletions2(Account outlet,ID geographyId,Product__c product)
    {
        List<Depletions__c> deps=new List<Depletions__c>();
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outlet.id;
        dep.ECM_Geography__c=geographyId;
        dep.ECM_Start_Period__c = Date.today().toStartOfMonth();
        dep.ECM_End_Period__c = Date.today().addmonths(1).toStartOfMonth().addDays(-1);
        dep.ECM_Product__c = product.id;
        dep.Forecast_Volume__c = 10;
        deps.add(dep);
        //insert dep;
        
        Depletions__c dep1 = new Depletions__c();
        dep1.ECM_Volume__c = 100.00;
        dep1.ECM_Outlet__c = outlet.id;
        dep1.ECM_Geography__c=geographyId;
        dep1.ECM_Start_Period__c = system.today().addmonths(1).toStartOfMonth();
        dep1.ECM_End_Period__c = system.today().addmonths(2).toStartOfMonth().addDays(-1);
        dep1.ECM_Product__c = product.id;
        dep1.Forecast_Volume__c=200;
        deps.add(dep1);
        return deps;
        //insert dep1;
    }
    static List<Depletions__c> getDepletionsLoop2(contract objContract,Product__c product)
    {
        contract con = [select id,Account.Country__c,AccountId from contract where id=:objContract.Id];
        List<Depletions__c> delpetionList = new List<Depletions__c>();
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
            System.debug(LoggingLevel.Debug,'tempUpsert--->'+tempUpsert);
            delpetionList.add(tempUpsert);
            
        }
        Insert delpetionList;
        return delpetionList;
    }
    @isTest
    public static void dataSetup(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId); 
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);     
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier=ECM_VolumeInputScreenQueuable_Test.getTiering(newcontractitem);
        List<ECM_Payment_Summary__c> paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItems = ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItems(paymentSummaries,newcontractitem);   
        System.debug(LoggingLevel.Debug,'paymemtSummaryItem1--->'+paymemtSummaryItems);    
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;            
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        delpetionList=ECM_VolumeInputScreenQueuable_Test.getDepletions(objContract,product);
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        System.debug(LoggingLevel.Debug,'volumeWrap--->'+volumeWrap);
        system.assertEquals(11,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');     
        ECM_updatePaymentSummaryItemsQueuable testQueue = new ECM_updatePaymentSummaryItemsQueuable((String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
    
    @isTest
    public static void dataSetup1(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);    
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);   
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId);    
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);        
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= new ECM_Tiering__c();
        tier=ECM_VolumeInputScreenQueuable_Test.getTiering(newcontractitem);  
        List<Depletions__c> deps=new List<Depletions__c>();
        deps=ECM_VolumeInputScreenQueuable_Test.getDepletionsManually(outlet,geographyId,product);        
        List<ECM_Payment_Summary__c> paymentSummaries=new List<ECM_Payment_Summary__c>();
        paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);
        ECM_Payment_Summary_Item__c paymemtSummaryItem=new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItemIndividually(newcontractitem,paymentSummaries[0]);
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;
        List<Depletions__c> delpetionList = new List<Depletions__c>();
        delpetionList=ECM_VolumeInputScreenQueuable_Test.getDepletionsWithoutInsert(objContract,product);
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        system.assertEquals(2,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');   
        ECM_updateDepletionsQueuable testQueue = new ECM_updateDepletionsQueuable(delpetionList,(String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
    
    @isTest
    public static void dataSetup2(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);    
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);   
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId);    
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);        
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);      
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= ECM_VolumeInputScreenQueuable_Test.getTiering2(newcontractitem);       
        System.debug(LoggingLevel.Debug,'tier-->'+tier);
        List<Depletions__c> deps=new List<Depletions__c>();
        deps=ECM_VolumeInputScreenQueuable_Test.getDepletions2(outlet,geographyId,product);
        List<ECM_Payment_Summary__c> paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItem=new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItem=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItems2(paymentSummaries,newcontractitem);      
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;
        //    System.runAs(usr){     
        List<Depletions__c> deps2=new List<Depletions__c>();
        deps2=ECM_VolumeInputScreenQueuable_Test.getDepletionsLoop2(objContract,product);           
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        System.debug(LoggingLevel.Debug,'volumeWrap--->'+volumeWrap);
        system.assertEquals(11,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');   
        ECM_updatePaymentSummaryItemsQueuable testQueue = new ECM_updatePaymentSummaryItemsQueuable((String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
    
    @isTest
    public static void dataSetup3(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);    
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);   
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId);    
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);        
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);      
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= ECM_VolumeInputScreenQueuable_Test.getTiering3(newcontractitem);    
        System.debug(LoggingLevel.Debug,'tier-->'+tier);      
        List<Depletions__c> deps=new List<Depletions__c>();
        deps=ECM_VolumeInputScreenQueuable_Test.getDepletions2(outlet,geographyId,product);
        List<ECM_Payment_Summary__c> paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);      
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItems = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItems=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItems3(paymentSummaries,newcontractitem);       
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;     
        List<Depletions__c> deps2=new List<Depletions__c>();
        deps2=ECM_VolumeInputScreenQueuable_Test.getDepletionsLoop2(objContract,product);        
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        System.debug(LoggingLevel.Debug,'volumeWrap--->'+volumeWrap);
        system.assertEquals(11,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');              
        ECM_updatePaymentSummaryItemsQueuable testQueue = new ECM_updatePaymentSummaryItemsQueuable((String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
    
    
    @isTest
    public static void dataSetup4(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);    
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);   
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId);    
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);        
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);      
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= ECM_VolumeInputScreenQueuable_Test.getTiering4(newcontractitem);
        System.debug(LoggingLevel.Debug,'tier-->'+tier);      
        List<Depletions__c> deps=new List<Depletions__c>();
        deps=ECM_VolumeInputScreenQueuable_Test.getDepletions2(outlet,geographyId,product);
        List<ECM_Payment_Summary__c> paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);             
        //ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItems = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItems=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItems3(paymentSummaries,newcontractitem);       
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;        
        List<Depletions__c> deps2=new List<Depletions__c>();
        deps2=ECM_VolumeInputScreenQueuable_Test.getDepletionsLoop2(objContract,product);        
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        System.debug(LoggingLevel.Debug,'volumeWrap--->'+volumeWrap);
        system.assertEquals(11,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');              
        ECM_updatePaymentSummaryItemsQueuable testQueue = new ECM_updatePaymentSummaryItemsQueuable((String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
    @isTest
    public static void dataSetup5(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);    
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);   
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId);    
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);        
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);      
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= ECM_VolumeInputScreenQueuable_Test.getTiering5(newcontractitem);
        System.debug(LoggingLevel.Debug,'tier-->'+tier);      
        List<Depletions__c> deps=new List<Depletions__c>();
        deps=ECM_VolumeInputScreenQueuable_Test.getDepletions2(outlet,geographyId,product);
        List<ECM_Payment_Summary__c> paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);             
        //ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItems = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItems=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItems3(paymentSummaries,newcontractitem);       
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;        
        List<Depletions__c> deps2=new List<Depletions__c>();
        deps2=ECM_VolumeInputScreenQueuable_Test.getDepletionsLoop2(objContract,product);        
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        System.debug(LoggingLevel.Debug,'volumeWrap--->'+volumeWrap);
        system.assertEquals(11,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');              
        ECM_updatePaymentSummaryItemsQueuable testQueue = new ECM_updatePaymentSummaryItemsQueuable((String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
    @isTest
    public static void dataSetup6(){
        User usr=ECM_VolumeInputScreenQueuable_Test.createUser();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Territory__c testterritory=ECM_VolumeInputScreenQueuable_Test.getTerritory(geographyId,usr);
        Territory_Hierarchy__c hirarchy= new Territory_Hierarchy__c();
        hirarchy=ECM_VolumeInputScreenQueuable_Test.getRegion(geographyId,usr,testterritory);    
        ECM_Contract_Type__c contractType=ECM_VolumeInputScreenQueuable_Test.getContractType(geographyId);   
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting=ECM_VolumeInputScreenQueuable_Test.getMarketSetting(geographyId);
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay at tier 3 rate any exceeding volume (opt.1)';
        update mktSetting;
        pickUps=ECM_VolumeInputScreenQueuable_Test.getPickUpOptions(geographyId);    
        outlet= ECM_VolumeInputScreenQueuable_Test.getOutlet(geographyId);        
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenQueuable_Test.getPaymentFrequency(geographyId);
        Contract objContract = ECM_VolumeInputScreenQueuable_Test.getContract(testterritory,contractType,paymfreq);   
        Product__c product =ECM_VolumeInputScreenQueuable_Test.getProduct(geographyId);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenQueuable_Test.getMarketAssortmentProduct(geographyId,product);
        ECM_Product_Agreement__c productagg=new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenQueuable_Test.getProductAgreement(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem=new ECM_Contract_Item__c();
        newcontractitem=ECM_VolumeInputScreenQueuable_Test.getContractItems(objContract,marketassort);      
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= ECM_VolumeInputScreenQueuable_Test.getTiering5(newcontractitem);
        System.debug(LoggingLevel.Debug,'tier-->'+tier);      
        List<Depletions__c> deps=new List<Depletions__c>();
        deps=ECM_VolumeInputScreenQueuable_Test.getDepletions2(outlet,geographyId,product);
        List<ECM_Payment_Summary__c> paymentSummaries=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaries(objContract);             
        //ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItems = new List<ECM_Payment_Summary_Item__c>();
        paymemtSummaryItems=ECM_VolumeInputScreenQueuable_Test.getPaymentSummaryItems3(paymentSummaries,newcontractitem);       
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymentSummaries[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummaries;        
        List<Depletions__c> deps2=new List<Depletions__c>();
        deps2=ECM_VolumeInputScreenQueuable_Test.getDepletionsLoop2(objContract,product);        
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        System.debug(LoggingLevel.Debug,'volumeWrap--->'+volumeWrap);
        system.assertEquals(11,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'null');              
        ECM_updatePaymentSummaryItemsQueuable testQueue = new ECM_updatePaymentSummaryItemsQueuable((String)objContract.id,Json.serialize(volumeWrap));
        System.enqueueJob(testQueue);
        Test.stopTest();
    }
}