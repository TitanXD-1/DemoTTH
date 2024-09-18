@isTest
public class ECM_RequestAddendumEUControllerTest {
    @isTest
    static void outletcreation(){
        Profile prof = [select id from profile where name=: 'Sales Representative'];
        User user = new User();
        user.firstName = 'test1';
        user.lastName = 'test2';
        user.profileId = prof.id;        
        user.email = 'test@test.com';
        user.Username ='testcm123@test.com';
        user.Alias='test';
        user.Timezonesidkey='America/Los_Angeles';
        user.LocaleSidKey='en_US';
        user.LanguageLocaleKey='en_US';
        user.EmailEncodingKey='UTF-8';
        user.Available_Countries__c='ES';
        insert user;
        system.assert(user!= null,'user should not be null');
        system.runAs(user){
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
            Geography__c geoId=[Select Id,Name from Geography__c where id=:geographyId];
            geoId.Name='Spain';
            update geoId;
            //user newuser = EDGE_UtilityTestClass.runAsUser('Testabc','System Administrator');
            //insert newuser;
            Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
            insert territory;
            ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Activation_Spend_Table_Configuration__c = 'Activation Spend Sub Group;Activity Type Description;Delivery Date;Must Do';
        contractType.ECM_Contract_Approval_mail_to_Customer__c = true;
        insert contractType;
            Account acc = EDGE_UtilityTestClass.getOutletRecord();
            insert acc;
            Date myDate = Date.newInstance(2020, 5, 17);
            Contract con = new Contract(Name = 'Test',UOS_Rebate_Rate__c=88, UOS_Target__c=99,AccountId =Acc.id,Contract_End_Date__c=myDate,ECM_Agreement_Type__c=contractType.id,ECM_Duration__c=2,ECM_Overall_Investment_Amount__c=40.00,ECM_Territory__c=territory.id,UOS_Earnt__c=3.00,UOS_AP_Rate__c=2.00,AP_Spent__c=2.00,Opening_AP_Balance__c=5.00,ECM_Channel__c='Hybrid',Venue_Type__c ='Premium[AU]',RecordTypeId = contractRecordTypeId);
            insert con;
            
            ECM_RequestAddendumEUController.updateLastSavedPageCon(con.Id);  
            
            ECM_RequestAddendumEUController.getContract(con.Id);

            ECM_RequestAddendumEUController.getUserCountry();
            ECM_RequestAddendumEUController.checkAddendumRecord(con.Id,'test');
            ECM_RequestAddendumEUController.submitAddendumRequestEU(con.Id,'00012345','test');
            //ECM_CreateContractController.cancelAddendum(con.Id);
            
            
            
        }
    }
    @isTest
    public static void sendRecallNotificationValidate(){
        WrapperInst wrapObj = createData();
        Contract conObj = new Contract();
        conObj.ECM_Parent_Contract__c = wrapObj.contr;
        conObj.ECM_Amended__c =true;
        conObj.ECM_Last_saved_page__c =1;
   Contract co = ECM_RequestAddendumEUController.handleChangeContract(wrapObj.contr,conObj);
   system.assert(co!= null,'co should not be null');

    }
    public static WrapperInst createData(){
        
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        //creating salesrep user
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        insert salesRep;
        User salesRep1 = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep1.Username = 'salesRp12345@test.com';
        insert salesRep1;
        
        //creating mdm user
        User mdm = ECM_UtilityTestClass.createUser('testmdm',ECM_UtilityTestClass.getProfile('Master Data Manager').Id);
        mdm.Username = 'testMDM1234@test.com';
        insert mdm;
        
        //creating account to which contract will be associated
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        
        //creating agreement type with Enable Recall of Contract as False
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
        
        //creating agreement type with Enable Recall of Contract as True
        ECM_Contract_Type__c contractType1 = ECM_UtilityTestClass.createContractType(geographyId);
        contractType1.ECM_Enable_Recall_of_Contract__c=True;
        insert contractType1;
        
        
        //creating contract of draft status
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.Status = 'Draft';
        insert contr;
        
        //creating contract with approved status
        Contract contr1 = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr1.ECM_Agreement_Type__c = contractType.Id;
        contr1.ownerId = salesRep.Id;
        contr1.Status = 'Draft';
        insert contr1;
        contr1.Status = 'Approved';
        contr1.ECM_Parent_Contract__c=contr.Id;
        update contr1;
        
        //creating contract with active status
        Contract contr2 = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr2.ECM_Agreement_Type__c = contractType1.Id;
        contr2.ownerId = salesRep.Id;
        contr2.Status = 'Draft';
        insert contr2;
        contr2.Status = 'In Approval Process';
        update contr2;
        
        Contract contr3 = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr3.ECM_Agreement_Type__c = contractType.Id;
        contr3.ownerId = salesRep.Id;
        contr3.Status = 'Draft';
        insert contr3;
        contr3.Status = 'In Approval Process';
        update contr3;
       
        //Setting up Payment Summary in Approved Status
        ECM_Payment_Summary__c paymentSummary = ECM_UtilityTestClass.getPaymentSummary(contr2.id);
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary.ECM_Type__c = 'Volume-Based';
        paymentSummary.ECM_Invoice_Status__c='Approved';
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        insert paymentSummary;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Approved';
        update paymentSummary;
        
        ECM_Approval_Log__c approvLog = new ECM_Approval_Log__c();
        approvLog.ECM_Time_Date_Log__c	 = system.now();
        approvLog.Name = 'abc@gmail.com';
        approvLog.ECM_Contract__c = contr.id;
        approvLog.ECM_Status__c = 'Requested';
        insert approvLog;
        
        //wrapping up all the test data
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.mdm = mdm;
        wrapObj.salesRep = salesRep;
        wrapObj.salesRep1 = salesRep1;
        wrapObj.contr=contr.Id;
        wrapObj.contr1=contr1.Id;
        wrapObj.contr2=contr2.Id;
        wrapObj.contr3=contr3.Id;
        wrapObj.acc=acc.Id;
        wrapObj.contractType=contractType.Id;
        wrapObj.contrRecTypeId=contrRecTypeId;
        wrapObj.geographyId=geographyId;
        return wrapObj; 
        
    }
     class WrapperInst{
        String geographyId{get;set;}
        String contrRecTypeId{get;set;}
        String contractType{get;set;}
        String acc{get;set;}
        String contr{get;set;}
        String contr1{get;set;}
        String contr2{get;set;}
        String contr3{get;set;}
        User salesRep{get;set;}
        User salesRep1{get;set;}
        User mdm{get;set;}
    }
}