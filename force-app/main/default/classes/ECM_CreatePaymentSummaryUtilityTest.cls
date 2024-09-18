/*
* Class Name: ECM_CreatePaymentSummaryUtilityTest
* @description: This Class is test class for ECM_CreatePaymentSummaryUtility class.
* @history:                                                        
* VERSION		AUTHOR                  DATE            DETAIL
* 1.0			Manikandan.T			15/03/2021      Initial Development
* 2.0			Anivesh Muppa			02/11/2021		ECM-4883 coverage
* 3.0			Pratap/Subhrojit		02/08/2022		ECM-5964 coverage
* 3.1           Pratap/Subhrojit        17/08/2022      ECM-6029 coverage
* 3.2			Abhishek S.             17/08/2022      ECM-5966 coverage
* 3.3           Tanishq Banerjee        31/10/2022      ECM-6273 coverage
*/
@isTest 
public class ECM_CreatePaymentSummaryUtilityTest 
{
    @testSetup public static void setupData(){
        //List<Account> acclist = new List<Account>();
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcmMngruniq1234@diageo.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='ES';
        insert usrmngr;
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcmunique123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        
        system.debug(LoggingLevel.Debug,'(USer==>  '+usr);
        user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
        insert newuser;
        /*Map<string,string> fieldsformappingrecords= new  Map<string,string>{'Draught Discounts' => 'ECM_Draught_Spirits_Discount_Level__c',
            'Pouring Discounts' => 'ECM_Spirits_Pouring_Discount_Level__c',
            'Premium Discounts' => 'ECM_Spirits_Premium_Discount_Level__c',
            'Reserve Discounts' => 'ECM_Spirits_Reserve_Discount_Level__c',
            'RTD Discount' => 'ECM_RTD_Discount_Level__c',
            'Spirits Discounts' => 'ECM_Spirits_Discount_Level__c'};
                Map<String,contract> mapstringrecordvalue = new Map<string,contract>();*/
        List<ECM_Contract_Item__c> contractItemslist = new List<ECM_Contract_Item__c>();
        //List<ECM_Contract_Item__c> contractItemslist1 = new List<ECM_Contract_Item__c>();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        
        
        
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        Territory__c testterritory=New Territory__c();
        testterritory.Name='Testterriotory';
        testterritory.Territory_Type__c='Sales';
        testterritory.Country__c= geographyId;
        testterritory.Status__c='Active';
        testterritory.Primary_Sales_Rep__c = usr.id;
        insert testterritory;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c = 'KEG';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;Investment;';
        insert contractType;
        
        Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
        insert mktSetting;
        
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='Range[ES]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        insert banner;
        
        Pick_Up_Options__c budgetType= new Pick_Up_Options__c();
        budgetType.Name='TI[ES]';
        budgetType.Geography__c=geographyId;
        budgetType.RecordTypeId=budgetTypeRecordTypeId;
        insert budgetType;
        
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
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c = 'Retailer';
        outlet.Global_Segment__c = 'Hypermarket';
        outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
        outlet.Status__c= 'Active';
        insert outlet; 
        outlet.country__c = geographyId;
        update outlet;
        
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        insert territory;
        Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
        hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
        insert hirarchy;
        
        territory.Primary_Sales_Rep__c = usr.id;
        territory.Country__c= geographyId;
        territory.Region__c=hirarchy.Id;
        update territory;
        
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Partial Prepayment';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        //paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_Prepayment__c=true;
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        
        ECM_Payment_Frequency__c paymfreq1 = new ECM_Payment_Frequency__c();
        paymfreq1.ECM_Type__c='Monthly';
        paymfreq1.ECM_Other_Investment__c=true;
        paymfreq1.ECM_Geography__c=geographyId;
        paymfreq1.ECM_Number_of_months_for_recurrence__c = '1';
        paymfreq1.ECM_From_When_Starts__c = 'Contract Start Date';
        Insert paymfreq1;
        
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today().addMonths(12).toStartOfMonth().addDays(-1);
        objContract.AccountId=outlet.Id;
        objContract.ECM_Territory__c=testterritory.Id;
        //objContract.ECM_Contract_Type__c=contractType.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.recordTypeId=contractRecordTypeId;
        objContract.ECM_Channel__c='On-Premise';
        objContract.ECM_Banner__c=banner.Id;
        objContract.StartDate = system.today();
        objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
        objContract.ECM_Duration__c = objContract.StartDate.monthsBetween(objContract.Contract_End_Date__c) + 1;
        objContract.ECM_Amended__c = false;
        insert objContract;
        
        Contract objContractCpy = objContract.clone(false,true,false,false);
        objContractCpy.ECM_Amended__c = false;
        objContractCpy.StartDate = System.today().addDays(50);
        objContractCpy.Contract_End_Date__c = System.today().addDays(51);
        insert objContractCpy;
        
        Contract objContractCpyAmnd = objContract.clone(false,true,false,false);
        objContractCpyAmnd.ECM_Amended__c = true;
        objContractCpyAmnd.ECM_Parent_Contract__c = objContractCpy.Id;
        objContractCpyAmnd.StartDate = System.today().addDays(50);
        insert objContractCpyAmnd;
        
        Business_Role__c businessRole =new Business_Role__c();
        businessRole.Name='Spain Mainland';
        businessRole.Country__c=geographyId;
        businessRole.Call_Type__c='Telephone';
        insert businessRole;
        
        User_Business_Role__c userBusinessRole =new User_Business_Role__c();        
        userBusinessRole.Business_Role__c=businessRole.Id;
        userBusinessRole.User__c=usr.Id;
        insert userBusinessRole;
        User_Business_Role__c ubr = new User_Business_Role__c();
        ubr.Business_Role__c= businessRole.Id ;
        ubr.User__c=userinfo.getUserId();
        insert ubr;
        
        ECM_Role_Agreement__c  roleAgreement =new ECM_Role_Agreement__c();        
        //roleAgreement.Business_Role__c=userBusinessRole.Business_Role__c;
        roleAgreement.Business_Role__c=businessRole.Id;
        roleAgreement.Agreement_Type__c=contractType.Id;
        insert roleAgreement;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Unique_ID__c='23';
        insert prdtUOM;
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        insert marketassort;
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=Marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        
        ECM_Contract_Item__c newcontractitem= new ECM_Contract_Item__c();
        newcontractitem.ECM_Contract__c=objContract.Id;
        newcontractitem.ECM_Product__c=Marketassort.id;
        insert newcontractitem;     
        contractItemslist.add(newcontractitem);
        
        ECM_Contract_Item__c newcontractitem1= new ECM_Contract_Item__c();
        newcontractitem1.ECM_Contract__c=objContractCpy.Id;
        newcontractitem1.ECM_Product__c=Marketassort.id;
        insert newcontractitem1;     
        contractItemslist.add(newcontractitem1);
        
        ECM_Contract_Item__c newcontractitem2= new ECM_Contract_Item__c();
        newcontractitem2.ECM_Contract__c=objContractCpyAmnd.Id;
        newcontractitem2.ECM_Product__c=Marketassort.id;
        insert newcontractitem2;     
        contractItemslist.add(newcontractitem2);
        
        //Sales driver Records
        Territory_Budget__c terriBudget = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        insert terriBudget;
        Territory_Budget__c terriBudget1 = ECM_UtilityTestClass.createTerritoryBudget(territory.Id, hirarchy.Id);
        //terriBudget1.ECM_Budget_Type__c=budjectEU.Id;
        insert terriBudget1;
        ECM_Sales_Driver__c salesDriver = ECM_UtilityTestClass.getSalesdriver(terriBudget1.Id,geographyId);
        salesDriver.ECM_Budget_Type__c=budgetType.id;
        insert salesDriver;
        Org_Setting__c org= new Org_Setting__c();
        org.Run_Triggers__c=true;
        insert org;
        ECM_Sales_Driver_Item__c eSCDI = new ECM_Sales_Driver_Item__c(Contract__c=objContract.Id,ECM_Sales_Driver__c=salesDriver.Id,
                                                                      ECM_Payment_Frequency__c=paymfreq.id,ECM_Prepayment__c=50,
                                                                      ECM_Payment_date__c=System.today().addDays(50),ECM_Remaining_Payment_Date__c=System.today().addDays(50),
                                                                      ECM_Investment_Yr1__c=20,ECM_Investment_Yr2__c=30,ECM_Investment_Yr3__c=10,ECM_Payment_Date_Yr1__c=system.today()+40,
                                                                      ECM_Payment_Date_Yr2__c=system.today()+60,ECM_Payment_Date_Yr3__c=system.today()+80
                                                                     );
        insert eSCDI;
        ECM_Sales_Driver_Item__c eSCDI1 = new ECM_Sales_Driver_Item__c(Contract__c=objContractCpyAmnd.Id,ECM_Sales_Driver__c=salesDriver.Id,
                                                                      ECM_Payment_Frequency__c=paymfreq.id,ECM_Prepayment__c=50,
                                                                      ECM_Payment_date__c=System.today().addDays(50),ECM_Remaining_Payment_Date__c=System.today().addDays(50),
                                                                      ECM_Investment_Yr1__c=20,ECM_Investment_Yr2__c=30,ECM_Investment_Yr3__c=10,ECM_Payment_Date_Yr1__c=system.today()+40,ECM_Payment_Via_SAP__c=false,
                                                                      ECM_Payment_Date_Yr2__c=system.today()+60,ECM_Payment_Date_Yr3__c=system.today()+80
                                                                     );
        insert eSCDI1;
        ECM_Sales_Driver_Item__c eSCDI2 = new ECM_Sales_Driver_Item__c(Contract__c=objContractCpyAmnd.Id,ECM_Sales_Driver__c=salesDriver.Id,
                                                                      ECM_Payment_Frequency__c=paymfreq1.id,ECM_Prepayment__c=50,
                                                                      ECM_Payment_date__c=System.today().addDays(50),ECM_Remaining_Payment_Date__c=System.today().addDays(50),
                                                                      ECM_Investment_Yr1__c=20,ECM_Investment_Yr2__c=30,ECM_Investment_Yr3__c=10,ECM_Payment_Date_Yr1__c=system.today()+40,
                                                                      ECM_Payment_Date_Yr2__c=system.today()+60,ECM_Payment_Date_Yr3__c=system.today()+80
                                                                     );
        insert eSCDI2;
        
        eSCDI.ECM_Investment_Yr1__c=26;
        update eSCDI;// Covers ECM_SalesDriverItemTrigger trigger
        ECM_Sales_Driver_Item__c eSCDIObj = new ECM_Sales_Driver_Item__c(Contract__c=objContract.Id,ECM_Sales_Driver__c=salesDriver.Id,
                                                                      ECM_Payment_Frequency__c=paymfreq.id,ECM_Prepayment__c=50,
                                                                      ECM_Payment_date__c=System.today().addDays(50),ECM_Remaining_Payment_Date__c=System.today().addDays(50),
                                                                      ECM_Investment_Yr1__c=20,ECM_Investment_Yr2__c=30,ECM_Investment_Yr3__c=10,ECM_Payment_Date_Yr1__c=system.today()+40,
                                                                      ECM_Payment_Date_Yr2__c=system.today()+60,ECM_Payment_Date_Yr3__c=system.today()+80
                                                                     );
        insert eSCDIObj;
        
        ECM_Sales_Driver_Item__c eSCDIObj1 = new ECM_Sales_Driver_Item__c(Contract__c=objContractCpyAmnd.Id,ECM_Sales_Driver__c=salesDriver.Id,
                                                                      ECM_Payment_Frequency__c=paymfreq.id,ECM_Prepayment__c=50,
                                                                      ECM_Payment_date__c=System.today().addDays(50),ECM_Remaining_Payment_Date__c=System.today().addDays(50),
                                                                      ECM_1st_Prepayment_Date__c = System.today().addDays(50),
                                                                      ECM_Investment_Yr1__c=20,ECM_Investment_Yr2__c=30,ECM_Investment_Yr3__c=10,ECM_Payment_Date_Yr1__c=system.today()+40,
                                                                      ECM_Payment_Date_Yr2__c=system.today()+60,ECM_Payment_Date_Yr3__c=system.today()+80
                                                                     );
        insert eSCDIObj1;
        
        delete eSCDIObj;
        delete eSCDIObj1;
        
        ECM_Payment_Summary__c paymentSummary1 = ECM_UtilityTestClass.getPaymentSummary(objContractCpy.id); 
        paymentSummary1.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary1.ECM_Type__c='Promo-PrePayment';
        paymentSummary1.ECM_Budget_types__c=budgetType.id;
        paymentSummary1.ECM_Total_Amount_Confirmed__c=50;
        paymentSummary1.ECM_Payment_Frequency__c = paymfreq.id;
        paymentSummary1.ECM_Start_Period__c = System.today().addDays(50);
        paymentSummary1.ECM_End_Period__c = System.today().addDays(50);
        insert paymentSummary1;
        
        ECM_Payment_Summary__c paymentSummary2 = ECM_UtilityTestClass.getPaymentSummary(objContractCpy.id); 
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary2.ECM_Type__c='Promo-Standard';
        paymentSummary2.ECM_Budget_types__c=budgetType.id;
        paymentSummary2.ECM_Total_Amount_Confirmed__c=50;
        paymentSummary2.ECM_Payment_Frequency__c = paymfreq.id;
        paymentSummary2.ECM_Start_Period__c = System.today().addDays(50);
        paymentSummary2.ECM_End_Period__c = System.today().addDays(50);
        insert paymentSummary2;
        
        ECM_Payment_Summary__c paymentSummary3 = ECM_UtilityTestClass.getPaymentSummary(objContractCpy.id); 
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary3.ECM_Type__c='Promo-Standard';
        paymentSummary3.ECM_Budget_types__c=budgetType.id;
        paymentSummary3.ECM_Total_Amount_Confirmed__c=50;
        paymentSummary3.ECM_Payment_Frequency__c = paymfreq1.id;
        paymentSummary3.ECM_Start_Period__c = System.today().addDays(50);
        paymentSummary3.ECM_End_Period__c = System.today().addDays(51);
        insert paymentSummary3;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem1 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary1.id,newcontractitem1.id);
        paymemtSummaryItem1.ECM_Confirmed_Amount_Per_Payment__c = 50;
        insert paymemtSummaryItem1;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem2 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary2.id,newcontractitem1.id);
        paymemtSummaryItem2.ECM_Confirmed_Amount_Per_Payment__c = 50;
        insert paymemtSummaryItem2;
        
        ECM_Payment_Summary_Item__c paymemtSummaryItem3 = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary3.id,newcontractitem1.id);
        paymemtSummaryItem3.ECM_Confirmed_Amount_Per_Payment__c = 50;
        insert paymemtSummaryItem3;
        
		paymentSummary1.ECM_Payment_Summary_Status__c = 'Completed';
        paymentSummary2.ECM_Payment_Summary_Status__c = 'Completed';
        paymentSummary3.ECM_Payment_Summary_Status__c = 'Completed';
        update paymentSummary1;
        update paymentSummary2;
        update paymentSummary3;
        
        ECM_Addendum__c addendum = new ECM_Addendum__c();
        addendum.ECM_Contract__c = objContract.ID;
        insert addendum;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails1 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI, newcontractitem);
        salesDetails1.ECM_Addendum__c = addendum.Id;
        insert salesDetails1;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails2 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI1, newcontractitem2);
        insert salesDetails2;
        
        ECM_Sales_Driver_Item_Detail__c salesDetails3 = ECM_UtilityTestClass.insertSalesdriverDetails(eSCDI2, newcontractitem2);
        insert salesDetails3;
        
        List<ECM_Sales_Driver_Item__c> eSDList1 = new List<ECM_Sales_Driver_Item__c>();
        eSDList1.add(eSCDI1);
        
        List<ECM_Sales_Driver_Item__c> eSDList = new List<ECM_Sales_Driver_Item__c>();
        eSDList.add(eSCDI);
        
        newcontractitem.ECM_Addendum__c = addendum.ID;     
        contractItemslist.add(newcontractitem);
        
    } 
    
    @isTest static void eCMcreatePromoStandardPrePaymentPSTest(){
        
        Test.starttest();
        contract c = [SELECT id,Status,ECM_Amended__c,(SELECT Id FROM Sales_Driver_Masters__r) FROM contract WHERE ECM_Amended__c = false LIMIT 1];
        c.status='Approved';
        update c;
        
        contract cAmend = [SELECT id,Status,ECM_Amended__c,ECM_Parent_Contract__c,(SELECT Id FROM Sales_Driver_Masters__r) FROM contract WHERE ECM_Amended__c = true LIMIT 1];
        cAmend.status = 'Approved';
        update cAmend;
        
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;
        c.status='Active';
        update c;
        cAmend.status='Active';
        update cAmend;
        
        Set<Id> sdidSet1 = (new Map<Id,ECM_Sales_Driver_Item__c>(cAmend.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromoStandardPrePaymentPS(sdidSet1, null);
        ECM_CreatePaymtSummaryUtility.ECM_createPromoPrepaymentSummaries(sdidSet1, null);
        
        List<ECM_Addendum__c> addndm = [SELECT Id, Name, ECM_Contract__c FROM ECM_Addendum__c];
        Map<Id,Id> conWithAddendum = new Map<Id,Id>();
        conWithAddendum.put(addndm[0].ECM_Contract__c,addndm[0].Id);
        Set<Id> sdidSet = (new Map<Id,ECM_Sales_Driver_Item__c>(c.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromoStandardPrePaymentPS(sdidSet, conWithAddendum);
        
        List<Ecm_payment_Summary__c>summarylist = [SELECT id,name FROM Ecm_payment_Summary__c WHERE ecm_contract__c =: c.id];
        System.assertEquals(summarylist.size(),0,'SummaryList size should match');
        system.debug(LoggingLevel.Debug,'summarylist'+summarylist);
        Test.stoptest();
        
    }

    
    @isTest static void eCMcreatePromStandardRecurringPSTest1(){
        Test.starttest();
        ECM_Payment_Frequency__c paymfreq = [SELECT id,ECM_Other_Investment__c,ECM_End_Date__c,ECM_Type__c,ECM_Prepayment__c,ECM_Number_of_months_for_recurrence__c,ECM_From_When_Starts__c FROM ECM_Payment_Frequency__c  WHERE ECM_Type__c='Partial Prepayment' Limit 1];
        paymfreq.ECM_Prepayment__c = false;
        paymfreq.ECM_End_Date__c = false;
        paymfreq.ECM_Limit_for_prepayment_in_LC__c=null;
        paymfreq.ECM_Volume_target__c  = true;
        update paymfreq; 
        paymfreq.ECM_Number_of_months_for_recurrence__c = '1';
        paymfreq.ECM_From_When_Starts__c = 'Contract Start Date';
        update paymfreq;
        
        contract c = [SELECT id,Status,ECM_Amended__c FROM contract WHERE ECM_Amended__c = false Limit 1];
        c.status='Approved';
        update c;
        
        contract cAmend = [SELECT id,Status,ECM_Amended__c,ECM_Parent_Contract__c,(SELECT Id FROM Sales_Driver_Masters__r) FROM contract WHERE ECM_Amended__c = true LIMIT 1];
        cAmend.status = 'Approved';
        update cAmend;
        
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;
        c.status='Active';
        update c;
        cAmend.status='Active';
        update cAmend;
        
        Set<Id> sdidSet1 = (new Map<Id,ECM_Sales_Driver_Item__c>(cAmend.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPS(sdidSet1, null);
        
        
        List<Ecm_payment_Summary__c>summarylist=[select id,name from Ecm_payment_Summary__c where ecm_contract__c=:c.id];
        System.assertEquals(summarylist.size(),0,'Summary List Size should match');
        Test.stoptest();
        
    }
    
    @isTest static void eCMcreatePromStandardRecurringPSSingleYearPFTest(){
        
        Test.starttest();
        
        ECM_Payment_Frequency__c paymfreq = [select id,ECM_Type__c,ECM_Prepayment__c,ECM_Number_of_months_for_recurrence__c,ECM_From_When_Starts__c from ECM_Payment_Frequency__c Limit 1];
        paymfreq.ECM_Type__c='Single yearly payments';
        //paymfreq.ECM_Number_of_months_for_recurrence__c='4';
        paymfreq.ECM_Prepayment__c=false;
        paymfreq.ECM_From_When_Starts__c='Contract Start Date';
        paymfreq.ECM_End_Date__c=false;
        paymfreq.ECM_Limit_for_prepayment_in_LC__c=null;
        paymfreq.ECM_Volume_target__c  = false;
        update paymfreq;
        paymfreq.ECM_Number_of_months_for_recurrence__c='4';
        update paymfreq;
        contract c=[select id,Status from contract Limit 1];
        c.status='Approved';
        update c;
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;
        c.status='Active';
        update c;
        List<Ecm_payment_Summary__c>summarylist=[select id,name from Ecm_payment_Summary__c where ecm_contract__c=:c.id];
        System.assertEquals(summarylist.size(),0,'summarylist size should match');
        Test.stoptest();
        
    }
    
    @isTest static void eCMcreatePromStandardAfteractivationPSTest(){
        Test.starttest();
        
        ECM_Payment_Frequency__c paymfreq = [SELECT Id,ECM_Type__c,ECM_Prepayment__c FROM ECM_Payment_Frequency__c WHERE ECM_Type__c='Partial Prepayment' Limit 1];
        paymfreq.ECM_Type__c='Payment after activation';
        paymfreq.ECM_Prepayment__c=false;
        paymfreq.ECM_End_Date__c=false;
        update paymfreq;
        
        contract c = [SELECT id,Status,ECM_Amended__c FROM contract WHERE ECM_Amended__c = true LIMIT 1];
        c.status='Approved';
        update c;
        
        contract cAmend = [SELECT id,Status,ECM_Amended__c,ECM_Parent_Contract__c,(SELECT Id FROM Sales_Driver_Masters__r) FROM contract WHERE ECM_Amended__c = true LIMIT 1];
        cAmend.status = 'Approved';
        update cAmend;
        
        
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;
        c.status='Active';
        update c;
        
        cAmend.status='Active';
        update cAmend;
        
        List<ECM_Addendum__c> addndm = [SELECT Id, Name, ECM_Contract__c FROM ECM_Addendum__c];
        Map<Id,Id> conWithAddendum = new Map<Id,Id>();
        conWithAddendum.put(addndm[0].ECM_Contract__c,addndm[0].Id);
        Set<Id> sdidSet = (new Map<Id,ECM_Sales_Driver_Item__c>(c.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromStandardAfteractivationPS(sdidSet, conWithAddendum);
        
        Set<Id> sdidSet1 = (new Map<Id,ECM_Sales_Driver_Item__c>(cAmend.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromStandardAfteractivationPS(sdidSet1, null);
        
        List<Ecm_payment_Summary__c>summarylist = [SELECT Id,name FROM Ecm_payment_Summary__c WHERE ecm_contract__c =: c.Id];
        System.assertEquals(summarylist.size(),0,'summarylist size should match');
        
        Test.stoptest();
    }
        
    
    @isTest static void eCMcreatePromStandardEndofContractTest(){
        Test.starttest();
        
        ECM_Payment_Frequency__c paymfreq = [SELECT Id,ECM_Type__c,ECM_Prepayment__c,ECM_From_When_Starts__c,ECM_Number_of_months_for_recurrence__c,ECM_End_Date__c FROM ECM_Payment_Frequency__c WHERE ECM_Type__c='Partial Prepayment' LIMIT 1];
        paymfreq.ECM_Type__c='At the End of the Contract';
        paymfreq.ECM_Prepayment__c=false;
        paymfreq.ECM_From_When_Starts__c=null;
        paymfreq.ECM_Number_of_months_for_recurrence__c=null;
        paymfreq.ECM_End_Date__c=false;
        update paymfreq;
        
        paymfreq.ECM_End_Date__c=true;
        update paymfreq;
        
        contract c=[select id,Status,ECM_Amended__c from contract WHERE ECM_Amended__c = false Limit 1];
        ECM_Sales_Driver_Item__c sdi=[select id,ECM_Payment_Frequency__c,Contract__c from ECM_Sales_Driver_Item__c where Contract__c=:c.id];
        sdi.ECM_Payment_Frequency__c=paymfreq.id;
        update sdi;
        
        contract cAmend = [SELECT id,Status,ECM_Amended__c,ECM_Parent_Contract__c,(SELECT Id FROM Sales_Driver_Masters__r) FROM contract WHERE ECM_Amended__c = true LIMIT 1];
        List<ECM_Sales_Driver_Item__c> sdi1=[select id,ECM_Payment_Frequency__c,Contract__c from ECM_Sales_Driver_Item__c where Contract__c=:cAmend.id];
        List<ECM_Sales_Driver_Item__c> sdUpdt  = new List<ECM_Sales_Driver_Item__c>();
        for(ECM_Sales_Driver_Item__c sd : sdi1){
            sd.ECM_Payment_Frequency__c=paymfreq.id;
            sdUpdt.add(sd);
        }
        if(!sdUpdt.isEmpty()){
            update sdUpdt;
        }
        List<ECM_Payment_Summary__c> ps1=[select id,ECM_Payment_Frequency__c,ECM_Contract__c from ECM_Payment_Summary__c where ECM_Contract__c=:cAmend.id];
        List<ECM_Payment_Summary__c> psUpdt  = new List<ECM_Payment_Summary__c>();
        for(ECM_Payment_Summary__c psId : ps1){
            psId.ECM_Payment_Frequency__c = paymfreq.id;
            psUpdt.add(psId);
        }
        if(!psUpdt.isEmpty()){
            update psUpdt;
        }
        
                
      //  contract c = [SELECT id,Status FROM contract LIMIT 1];
        c.status='Approved';
        update c;
        cAmend.status = 'Approved';
        update cAmend;
        
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;
        c.status='Active';
        update c;
        cAmend.status='Active';
        update cAmend;
        
        List<ECM_Addendum__c> addndm = [SELECT Id, Name, ECM_Contract__c FROM ECM_Addendum__c];
        Map<Id,Id> conWithAddendum = new Map<Id,Id>();
        conWithAddendum.put(addndm[0].ECM_Contract__c,addndm[0].Id);
        Set<Id> sdidSet = (new Map<Id,ECM_Sales_Driver_Item__c>(c.Sales_Driver_Masters__r)).keySet();
        Set<Id> sdidSet1 = (new Map<Id,ECM_Sales_Driver_Item__c>(cAmend.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromStandardEndofContract(sdidSet, conWithAddendum);
        ECM_CreatePaymtSummaryUtility.ECM_createPromStandardEndofContract(sdidSet1, null);
        
        List<Ecm_payment_Summary__c>summarylist=[SELECT Id,name FROM Ecm_payment_Summary__c WHERE ecm_contract__c =: c.id];
        System.assertEquals(summarylist.size(),0,'summarylist size should match');
        Test.stoptest();
        
    }
    @isTest static void eCMcreatePromStandardRecurringPSTest(){
        Test.starttest();
        Id georecId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        List<Geography__c> geographyId = [SELECT id,name from Geography__c where RecordTypeId =: georecId]; 
        
        ECM_Payment_Frequency__c paymfreq1 = new ECM_Payment_Frequency__c();
        paymfreq1.ECM_Type__c='Monthly Retrospective';
        paymfreq1.ECM_From_When_Starts__c='Contract Start Date';
        paymfreq1.ECM_Other_Investment__c=true;
        paymfreq1.ECM_Volume_target__c=false;
        paymfreq1.ECM_Number_of_months_for_recurrence__c='1';
        paymfreq1.ECM_Prepayment__c=false;
        paymfreq1.ECM_Geography__c=geographyId[0].Id;
        insert paymfreq1;
        
        contract conRec=[select id,Status from contract Limit 1];
        ECM_Sales_Driver_Item__c sdi=[select id,ECM_Payment_Frequency__c,Contract__c from ECM_Sales_Driver_Item__c where Contract__c=:conRec.id];
        sdi.ECM_Payment_Frequency__c=paymfreq1.id;
        update sdi;
        
        conRec.status='Approved';
        update conRec;
        
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;
        conRec.status='Active';
        update conRec;
        
           List<ECM_Addendum__c> addndm = [SELECT Id, Name, ECM_Contract__c FROM ECM_Addendum__c];
        Map<Id,Id> conWithAddendum = new Map<Id,Id>();
        conWithAddendum.put(addndm[0].ECM_Contract__c,addndm[0].Id);
        Set<Id> sdidSet = (new Map<Id,ECM_Sales_Driver_Item__c>(conRec.Sales_Driver_Masters__r)).keySet();
        ECM_CreatePaymtSummaryUtility.ECM_createPromStandardRecurringPS(sdidSet, conWithAddendum);

        List<Ecm_payment_Summary__c>summarylist=[select id,name from Ecm_payment_Summary__c where ecm_contract__c=:conRec.id];
        System.assertEquals(summarylist.size(),0,'summarylist size should match');
        
        Test.stoptest();
    }
    
    @isTest static void eCMcreateVolBasedRecurringPSTest2(){
        Test.starttest();
        Id georecId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        List<Geography__c> geographyId = [SELECT id,name FROM Geography__c WHERE RecordTypeId =: georecId]; 
        
        ECM_Payment_Frequency__c paymfreq2 = new ECM_Payment_Frequency__c();
        paymfreq2.ECM_Type__c='Monthly';
        paymfreq2.ECM_From_When_Starts__c='Contract Start Date';
        paymfreq2.ECM_Other_Investment__c=false;
        paymfreq2.ECM_Volume_target__c=true;
        paymfreq2.ECM_Number_of_months_for_recurrence__c='1';
        paymfreq2.ECM_Prepayment__c=false;
        paymfreq2.ECM_Geography__c=geographyId[0].Id;
        insert paymfreq2;
        
        contract conRec = [SELECT id,Status,ECM_Amended__c,ECM_Payment_Frequency__c FROM contract WHERE ECM_Amended__c = false LIMIT 1];       
        conRec.status='Approved';
        update conRec;
        
        contract cAmend = [SELECT id,Status,ECM_Amended__c,ECM_Parent_Contract__c,(SELECT Id FROM Sales_Driver_Masters__r) FROM contract WHERE ECM_Amended__c = true LIMIT 1];
        cAmend.status = 'Approved';
        update cAmend;
        
        ContractTriggerHandler.isFirstTime=true;
        ContractTriggerHandler.triggerDisabled=false;  
        conRec.ECM_Payment_Frequency_type__c=paymfreq2.id;
        conRec.status='Active';
        update conRec;
        
        cAmend.status='Active';
        update cAmend;
        
        List<ECM_Addendum__c> addndm = [SELECT Id, Name, ECM_Contract__c FROM ECM_Addendum__c];
        Map<Id,Id> conWithAddendum = new Map<Id,Id>();
        conWithAddendum.put(addndm[0].ECM_Contract__c,addndm[0].Id);
        
        Set<Id> conLst = new Set<Id>();
        conLst.add(cAmend.id);
       
        ECM_CreatePaymtSummaryUtility.ECM_createVolBasedRecurringPS(null,conWithAddendum);
        ECM_CreatePaymtSummaryUtility.ECM_createVolBasedRecurringPS(conLst,null);
        
        List<Ecm_payment_Summary__c>summarylist = [SELECT id,name FROM Ecm_payment_Summary__c WHERE ecm_contract__c =: conRec.id];
        System.assertEquals(summarylist.size(),0,'summarylist size should match');
        
        Test.stoptest();
        
    }  
}