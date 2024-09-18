@isTest
public class ECM_CreatePaymentSummaryForAU_Test {
    @isTest
    public static void scheduleBatchForPaymntSumryMethod() {
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcmMngr@test.com';
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
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='AU';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
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

        Pick_Up_Options__c pickUpOtion = new Pick_Up_Options__c();
        pickUpOtion.Name='Upfront Payment [AU]';
        pickUpOtion.Geography__c=geographyId;
        pickUpOtion.RecordTypeId=BudgetTypeRecordTypeId;
        insert pickUpOtion;
        
        ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
        paymfreq.ECM_Type__c='Equal Instalments';
        paymfreq.ECM_Other_Investment__c=true;
        paymfreq.ECM_Volume_target__c=true;
        paymfreq.ECM_Number_of_months_for_recurrence__c='20';
        paymfreq.ECM_From_When_Starts__c='Calendar Year';
        paymfreq.ECM_Geography__c=geographyId;
        Insert paymfreq;
        
        ECM_Payment_Frequency__c paymfreqRetro = new ECM_Payment_Frequency__c();
        paymfreqRetro.ECM_Type__c='Retrospective';
        paymfreqRetro.ECM_Other_Investment__c=true;
        paymfreqRetro.ECM_Volume_target__c=true;
        paymfreqRetro.ECM_Number_of_months_for_recurrence__c='20';
        paymfreqRetro.ECM_From_When_Starts__c='Calendar Year';
        paymfreqRetro.ECM_Geography__c=geographyId;
        Insert paymfreqRetro;


        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
        insert contractType;

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
        objContract2.ECM_Total_Upfront_Payment_Loan_Over_Term__c = 200;
        objContract2.ECM_Payment_Schedule_Date_AU__c = system.today();
        insert objContract2;

        objContract2.Status = 'Active';
        update objContract2;
        
        Contract objContract3 = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract3.Status = 'Draft';
        objContract3.Contract_End_Date__c = System.today()+29;
        objContract3.AccountId=outletAccount.Id;
        objContract3.ECM_Territory__c=testterritory.Id;
        //objContract3.ECM_Contract_Type__c=contractType.Id;
        objContract3.recordTypeId=contractRecordTypeId;
        objContract3.ECM_Channel__c='On-Premise';
         objContract3.ECM_Selected_Payment_Schedule_AU__c =paymfreq.Id;
        objContract3.StartDate = system.today()+150;
        objContract3.Contract_End_Date__c = system.today()+360;
        objContract3.ECM_Agreement_Type__c=contractType.Id;
        objContract3.ECM_Total_Upfront_Payment_Loan_Over_Term__c = 200;
        objContract3.ECM_Payment_Schedule_Date_AU__c = system.today();
        ObjContract3.UOS_Earnt__c = 500;
        ObjContract3.ECM_UOS_Upfront_Target__c = 200;
        ObjContract3.ECM_Upfront_Payment_Spent__c = 100;
        insert objContract3;

        objContract3.Status = 'Active';
        update objContract2;
        
        list<Contract> conList = new List<Contract>();
        conList.add(objContract2);
        
        list<Contract> conList2 = new List<Contract>();
        conList2.add(objContract3);
        conList2.add(objContract);
        Test.StartTest();
        ECM_CreateFirstPaymentSummaryForAU.insertPaymentSummaries(conList);
        conList[0].ECM_Selected_Payment_Schedule_AU__c =paymfreqRetro.Id;
        ECM_CreateFirstPaymentSummaryForAU.insertPaymentSummaries(conList);
        ECM_CreateOngoingPaymentSummaryForAU.insertPaymentSummaries(conList2);
        Test.StopTest();
    }
}