@isTest
public class ECM_SchdleBchPrmPrPytPSfor100PrPyt_Test {
    @isTest
	public static void scheduleBatchForPaymntSumryMethod() {
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcm_'+userinfo.getOrganizationId()+'_123@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='AU';
        insert usrmngr;
        system.assert(usrmngr.Id != null,'usrmngr Id should not be null');
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm_'+userinfo.getOrganizationId()+'_1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= usr.Id;
        outletAccount.OwnerId = usr.Id;
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Country__c = geographyId;
        outletAccount.IsOperator__c=true;
        insert outletAccount;

        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();

        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[AU]';
        bannerAU.Geography__c=geographyId;
        bannerAU.RecordTypeId=BannerRecordTypeId;
        insert bannerAU;
        Pick_Up_Options__c budjectEU= new Pick_Up_Options__c();
        budjectEU.Name='TI [ES]';
        budjectEU.Geography__c=geographyId;
        budjectEU.RecordTypeId=BudgetTypeRecordTypeId;
        insert budjectEU;
        
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='100% Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;

        /*Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;*/
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
         contractType.ECM_Volume_UoM_for_Beer__c='EU';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        insert contractType;

        Territory_Hierarchy__c hirarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
        insert hirarchy;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.country__c=geographyId;
		territory.Primary_Sales_Rep__c = usr.id;
        //insert territory;
        /*Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        insert hirarchy;
        territory.Primary_Sales_Rep__c = usr.id;
        update territory;*/
        
            
        territory.Business_Unit__c=hirarchy.id;
        insert territory;
        
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();

        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        objContract.AccountId=outletAccount.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.ECM_Selected_Payment_Schedule_AU__c =paymfreq.Id;
        objContract.Contract_End_Date__c = system.today()+360;
        objContract.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c = 200;
        objContract.ECM_Upfront_Payment_Spent__c = 100;
        ObjContract.UOS_Earnt__c = 500;
        ObjContract.ECM_UOS_Upfront_Target__c = 200;
        ObjContract.ECM_Upfront_Last_Payment_date__c = system.today().addYears(-1);
        ObjContract.UOS_Target__c = 100;
        ObjContract.ECM_Duration__c = 8;
        insert objContract;
        
        objContract.Status = 'Active';
        update objContract;
        
        Contract objContract2 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract2.Status = 'Draft';
        objContract2.Contract_End_Date__c = System.today()+29;
        objContract2.AccountId=outletAccount.Id;
        objContract2.ECM_Territory__c=testterritory.Id;
        //objContract2.ECM_Contract_Type__c=contractType.Id;
        objContract2.recordTypeId=contractRecordTypeId;
        objContract2.ECM_Channel__c='On-Premise';
        objContract2.ECM_Selected_Payment_Schedule_AU__c =paymfreq.Id;
        objContract2.StartDate = system.today()+150;
        objContract2.Contract_End_Date__c = system.today()+360;
        objContract2.ECM_Agreement_Type__c=contractType.Id;
        objContract2.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c = 200;
        objContract2.ECM_Payment_Schedule_Date_AU__c = system.today();
        insert objContract2;

        objContract2.Status = 'Active';
        update objContract2;

        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Unique_ID__c='Test1238';
        insert prdtUOM;
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        insert marketassort;
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;
        //contractItemslist.add(newcontractitem);
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContract.Id;
        newcontractitem1.ECM_Product__c=Marketassort.id;
        insert newcontractitem1;
        //contractItemslist1.add(newcontractitem1);
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContract2.Id;
        newcontractitem2.ECM_Product__c=Marketassort.id;
        insert newcontractitem2;
        //Sales driver Records
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        insert terriBudget;
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.ECM_Budget_Type__c = budjectEU.Id;
        insert salesDriver;
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract.Id,ECM_Sales_Driver__c=SalesDriver.Id,ECM_Payment_Frequency__c=paymfreq.Id,
                                                                     ECM_Payment_Date__c=system.today());
        insert eSCDI;
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem1);
        insert salesDetails1;
        List<ECM_Sales_Driver_Item__c> eSDList = new List<ECM_Sales_Driver_Item__c>();
        eSDList.add(eSCDI);
        
        Test.StartTest();
        ECM_SchdleBatchPromoPrePytPsfor100PrePyt sh1 = new ECM_SchdleBatchPromoPrePytPsfor100PrePyt();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, sh1);
        Test.StopTest();
    }
}