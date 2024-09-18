/*
@Name:ECM_VolumeInputScreenController_Test
@Purpose: This Class is to cover the "ECM_VolumeInputScreenController" 
@History                                                                                                                  
VERSION    AUTHOR                DATE              DETAIL
1.0      Saurav Prasad							Initial Development
1.1      Manikandan T         16/07/2021        Development for ECM-4663
1.2		 Saurav Prasad		  16/07/2021		Development for ECM-4663
1.3      Joshraj/Sakshi       04/04/2024        152305
*/

@isTest
public class ECM_VolumeInputScreenController_Test {
    static Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
    static String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
    static String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
    static String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
    static String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    static Account outlet=new Account();
    static Territory__c testterritory=new Territory__c();
    @isTest
    public static void dataSetup(){
        User usr = ECM_VolumeInputScreenController_Test.getUsr();
        testterritory= ECM_VolumeInputScreenController_Test.getTestterritory(usr);
        ECM_Contract_Type__c contractType= ECM_VolumeInputScreenController_Test.getContractType();
        Market_Setting__c mktSetting=new Market_Setting__c();
        mktSetting = ECM_VolumeInputScreenController_Test.getMktSetting();
        Pick_Up_Options__c banner= ECM_VolumeInputScreenController_Test.getBanner();
        Pick_Up_Options__c budgetType= ECM_VolumeInputScreenController_Test.getBudgetType();
        outlet = ECM_VolumeInputScreenController_Test.getOutlet();
        ECM_Payment_Frequency__c paymfreq = ECM_VolumeInputScreenController_Test.getPaymfreq();
        Contract objContract = ECM_VolumeInputScreenController_Test.getObjContract(contractType,banner,paymfreq);
        Product__c product = ECM_VolumeInputScreenController_Test.getProduct();
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM =ECM_VolumeInputScreenController_Test.getPrdtUOM(product);
        Market_Assortment_Product__c marketassort = ECM_VolumeInputScreenController_Test.getMarketassort(product);
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg=ECM_VolumeInputScreenController_Test.getProductagg(marketassort,contractType);
        ECM_Contract_Item__c newcontractitem= ECM_VolumeInputScreenController_Test.getNewcontractitem(objContract,marketassort);
        System.debug(LoggingLevel.Debug,'newcontractitem--->'+newcontractitem);
        ECM_Tiering__c tier= ECM_VolumeInputScreenController_Test.getTier(newcontractitem);
        System.debug(LoggingLevel.Debug,'tier-->'+tier);
        List<Depletions__c> depList = new List<Depletions__c>();
        depList=ECM_VolumeInputScreenController_Test.getDepList(outlet,product);
        List<ECM_Payment_Summary__c> paymemtSummaryList = ECM_VolumeInputScreenController_Test.getPaymemtSummaryList(objContract,budgetType);
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = ECM_VolumeInputScreenController_Test.getPaymemtSummaryItemList(paymemtSummaryList[0],newcontractitem,paymemtSummaryList[1]);
        System.debug(LoggingLevel.Debug,'PaymemtSummaryItem1--->'+paymemtSummaryItemList[1]);
        List<ECM_Payment_Summary__c> payCheck = [select id from ECM_Payment_Summary__c];
        System.debug(LoggingLevel.Debug,'payCheck-->'+payCheck.size());
        Test.startTest();
        paymemtSummaryList[1].ECM_Payment_Summary_Status__c = 'Completed';
        update paymemtSummaryList[1];
        //    System.runAs(usr){     
        List<ECM_VolumeInputScreenController.VolumeInputWrapper> volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        system.assertEquals(2,[Select Id,Name,Contract__c,ECM_End_Period__c,Forecast_Volume__c,ECM_Outlet__c,ECM_Product__c,ECM_Start_Period__c,Unique_ID__c,ECM_Volume__c FROM Depletions__c].size(),'The size of depletions should be as expected');
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        volumeWrap = ECM_VolumeInputScreenController.getProductValues((String)objContract.id);
        tier.ECM_Tier_1_volume_limit__c=0.1;
        update tier;
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        tier.ECM_Tier_2_volume_limit__c=0.2;
        update tier;
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        tier.ECM_Tier_3_volume_limit__c=0.3;
        update tier;
        ECM_VolumeInputScreenController.saveDepletions(JSON.serialize(volumeWrap),(String)objContract.id);
        Test.stopTest();
        //   }   
    }
    public static User getUsr(){
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
    public static Territory__c getTestterritory(User usr){
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        testterritory.Primary_Sales_Rep__c = usr.id;
        testterritory.Country__c= geographyId;
        testterritory.Region__c=hirarchy.Id;
        update testterritory;
        return testterritory;
    }
    public static ECM_Contract_Type__c getContractType(){
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='CAS';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
        insert contractType;
        return contractType;
    }
    public static Market_Setting__c getMktSetting(){
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        mktSetting.Depletion_market__c=false;
        mktSetting.ECM_Payment_Opt_for_Exceeding_Tier_3_Vol__c = 'Pay only per tier 3 volume limit (opt.2)';
        mktSetting.ECM_Tiering_for_Volume_investment__c = true;
        mktSetting.ECM_Tiering_Payment_Amount_Calculation__c = 'Top-Level Achievement';
        update mktSetting;
        return mktSetting;
    }
    public static Pick_Up_Options__c getBanner(){
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        return banner;
    }
    public static Pick_Up_Options__c getBudgetType(){
        Pick_Up_Options__c budgetType= new Pick_Up_Options__c();
        budgetType.Name='TI[ES]';
        budgetType.Geography__c=geographyId;
        budgetType.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetType;
        return budgetType;
    }
    public static Account getOutlet(){
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
    public static ECM_Payment_Frequency__c getPaymfreq(){
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        //paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        return paymfreq;
     }
     public static Contract getObjContract(ECM_Contract_Type__c contractType,Pick_Up_Options__c banner,ECM_Payment_Frequency__c paymfreq){
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = Date.today().addMonths(12).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = Date.today().toStartOfMonth();
        objContract.ECM_Duration__c=20;
        objContract.ECM_Amended__c=true;
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        insert objContract;
        objContract.Status ='Active';
        update objContract;
        return objContract;
    }
    public static Product__c getProduct(){
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        return product;
    }
    public static Product_UOM__c getPrdtUOM(Product__c product){
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Unique_ID__c='Test123';
        prdtUOM.Conversion_Factor__c = 2;
        insert prdtUOM;
        return prdtUOM;
    }
    public static Market_Assortment_Product__c getMarketassort(Product__c product){
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        insert marketassort;
        return marketassort;
    }
    public static ECM_Product_Agreement__c getProductagg(Market_Assortment_Product__c marketassort,ECM_Contract_Type__c contractType){
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        return productagg;
    }
    public static ECM_Contract_Item__c getNewcontractitem(Contract objContract,Market_Assortment_Product__c marketassort){
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Product__c=marketassort.id;
        newcontractitem.ECM_UoM__c = '1';
        newcontractitem.ECM_Lead_Brand__c = TRUE;
        insert newcontractitem;
        return newcontractitem;
    }
    public static ECM_Tiering__c getTier(ECM_Contract_Item__c newcontractitem){
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
    public static List<Depletions__c> getDepList(Account outlet,Product__c product){
        List<Depletions__c> depList = new List<Depletions__c>();
        Depletions__c dep = new Depletions__c();
        dep.ECM_Volume__c = 100.00;
        dep.ECM_Outlet__c = outlet.id;
        dep.ECM_Geography__c=geographyId;
        dep.ECM_Start_Period__c = Date.today().toStartOfMonth();
        dep.ECM_End_Period__c = Date.today().addmonths(1).toStartOfMonth().addDays(-1);
        dep.ECM_Product__c = product.id;
        dep.Forecast_Volume__c = 10;
        depList.add(dep);
        Depletions__c dep1 = new Depletions__c();
        dep1.ECM_Volume__c = 100.00;
        dep1.ECM_Outlet__c = outlet.id;
        dep1.ECM_Geography__c=geographyId;
        dep1.ECM_Start_Period__c = system.today().addmonths(1).toStartOfMonth();
        dep1.ECM_End_Period__c = system.today().addmonths(2).toStartOfMonth().addDays(-1);
        dep1.ECM_Product__c = product.id;
        dep1.Forecast_Volume__c=200;
        depList.add(dep1);
        insert depList;
        return depList;
    }
    public static List<ECM_Payment_Summary__c> getPaymemtSummaryList(Contract objContract,Pick_Up_Options__c budgetType){
        List<ECM_Payment_Summary__c> paymemtSummaryList = new List<ECM_Payment_Summary__c>();
        ECM_Payment_Summary__c paymemtSummary = new ECM_Payment_Summary__c();
        paymemtSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymemtSummary.ECM_Type__c = 'Volume-Based';
        paymemtSummary.ECM_Invoice_Status__c='Requested';
        paymemtSummary.ECM_Contract__c = objContract.Id;
        paymemtSummary.ECM_Start_Period__c = Date.today().toStartOfMonth().addDays(50);
        paymemtSummary.ECM_End_Period__c = Date.today().addMonths(3).toStartOfMonth().addDays(-1);
        paymemtSummary.ECM_Budget_types__c = budgetType.id;
        paymemtSummary.ECM_Invoice_Status__c ='Approved';
        paymemtSummary.ECM_Invoice_Receival_Date__c = system.today()+1;
        // paymemtSummary.ownerid = uid;
        paymemtSummary.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymemtSummaryList.add(paymemtSummary);
        ECM_Payment_Summary__c paymemtSummary2 = new ECM_Payment_Summary__c();
        paymemtSummary2.ECM_Total_Amount_Confirmed__c = 20.00;
        paymemtSummary2.ECM_Payment_Summary_Status__c = 'Submitted';
        paymemtSummary2.ECM_Type__c = 'Volume-Based';
        paymemtSummary2.ECM_Contract__c = objContract.id;
        paymemtSummary2.ECM_Start_Period__c = Date.today().addMonths(3).toStartOfMonth();
        paymemtSummary2.ECM_End_Period__c = Date.today().addMonths(6).toStartOfMonth().addDays(-1);
        paymemtSummary2.ECM_Budget_types__c = budgetType.id;
        paymemtSummary2.ECM_Invoice_Status__c ='Approved';
        paymemtSummary2.ECM_Invoice_Receival_Date__c = system.today()+1;
        paymemtSummary2.ECM_Tax_Rate__c='Standard Rate';
        paymemtSummary2.ECM_Recommended_IO_Code__c='MHJ0WACF6900';
        paymemtSummaryList.add(paymemtSummary2);
        insert paymemtSummaryList;
        return paymemtSummaryList;
    }
    public static List<ECM_Payment_Summary_Item__c> getPaymemtSummaryItemList(ECM_Payment_Summary__c paymemtSummary,ECM_Contract_Item__c newcontractitem,ECM_Payment_Summary__c paymemtSummary2){
        List<ECM_Payment_Summary_Item__c> paymemtSummaryItemList = new List<ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem.ECM_Payment_Summary__c = paymemtSummary.id;
        paymemtSummaryItem.ECM_Confirm__c = true;
        paymemtSummaryItem.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItemList.add(paymemtSummaryItem);
        System.debug(LoggingLevel.Debug,'PaymemtSummaryItem--->'+paymemtSummaryItem);
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = new ECM_Payment_Summary_Item__c();
        paymemtSummaryItem1.ECM_Payment_Summary__c = paymemtSummary2.id;
        paymemtSummaryItem1.ECM_Confirm__c = true;
        paymemtSummaryItem1.ECM_Confirmed_Volume__c = 1;
        paymemtSummaryItem1.ECM_Contract_Item__c = newcontractitem.id;			
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c =10;
        paymemtSummaryItemList.add(paymemtSummaryItem1);
        insert paymemtSummaryItemList;
        return paymemtSummaryItemList;
    }
}