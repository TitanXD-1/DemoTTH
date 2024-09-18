/**
* @description :  ECM_contractRecallCtrlTest
* @purpose : This is the test class of ECM_ContractRecallCtrl apex class
* @since :
* Version      	Developer            		Date          	User Story/Purpose
* 1.1       	Anuja Chattopadhyay     	12/01/2022    	ECM-5097
* 1.2			Tanishq Banerjee			01/02/2022		ECM-5140
* 1.3			Vinay Tummala				01/02/2022		ECM-5140
* 1.4			Anshu Prakash				01/02/2022		ECM-5111
*/
@isTest
public class ECM_contractRecallCtrlTest {
    /**
	* @description : createAccountShare - This methods used to Create Contract Share
	* @return : void
	* @param : Account Id, SalesRep Id
	*/
    public static void createAccountShare(Id accountId,Id salesRepId){
        AccountShare accountShare = new AccountShare();
        accountShare.AccountId = accountId;
        accountShare.UserOrGroupId = salesRepId;
        accountShare.AccountAccessLevel = 'Edit';
        accountShare.ContactAccessLevel = 'Edit';
        accountShare.OpportunityAccessLevel = 'Edit';
        insert accountShare;
    }
    /**
	* @description : validateContractOwner - This methods used to Validate if Contract Owner is Recalling
	* @return : void
	* @param : Void
	*/
    @isTest 
    public static void validateContractOwner(){
        WrapperInst wrapObj1 = createData();
        createAccountShare(wrapObj1.acc,wrapObj1.salesRep1.Id);
        Test.startTest();
        System.runAs(wrapObj1.salesRep1){
            String error=ECM_ContractRecallCtrl.validateRecall(wrapObj1.contr);
            System.debug(LoggingLevel.Debug,error);
            System.assertEquals(Label.ECM_Recall_ContractOwner_Error,ECM_ContractRecallCtrl.validateRecall(wrapObj1.contr),'null');
        }
        Test.stopTest();
    }
    /**
	* @description : validationforAgreementTypeTest - This methods used to Validate agreement type while recalling
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void validationforAgreementTypeTest()
    {
          WrapperInst wrapObj = createData();
        Test.startTest();
        try{
            System.runAs(wrapObj.salesRep){
                List<Sobject> recallCtrl = new List<Sobject>(); 
                ECM_ContractRecallCtrl.validationforAgreementType(wrapObj.contr);
                System.assert(recallCtrl!=null,'recallCtrl should not be null');
            }
        }catch(Exception ex){
           System.debug(LoggingLevel.Debug,ex); 
        }
    }
    /**
	* @description : sendRecallNotificationTest - This methods used to Validate recall Notification
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void sendRecallNotificationTest(){
        WrapperInst wrapObj = createData();
        Test.startTest();
        try{
            System.runAs(wrapObj.salesRep){
                List<Sobject> recallCtrl1 = new List<Sobject>(); 
                ECM_ContractRecallCtrl.sendRecallNotification(wrapObj.contr);
                System.assert(recallCtrl1!=null,'recallCtrl1 should not be null');
            }
        }catch(Exception ex){
           System.debug(LoggingLevel.Debug,ex); 
        }
    }
    /**
	* @description : recallAgeementError - This methods used to Validate recall Agreement Error
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void recallAgeementError(){
       WrapperInst wrapObj = createData();
        System.runAs(wrapObj.salesRep){
            System.assertEquals(Label.ECM_Recall_Agreement_Error,ECM_ContractRecallCtrl.validateRecall(wrapObj.contr3),'null');
        }
    }
    /**
	* @description : validateContractRecallCtrlTest - This methods used to Validate recall Error
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void validateContractRecallCtrlTest(){
        WrapperInst wrapObj = createData();
        createAccountShare(wrapObj.acc,wrapObj.salesRep.Id);
        Test.startTest();
        try{
            System.runAs(wrapObj.mdm){
                System.assertEquals(Label.ECM_Recall_Profile_Error,ECM_ContractRecallCtrl.validateRecall(wrapObj.contr),'null');
            }
            System.runAs(wrapObj.salesRep){
                System.assertEquals(Label.ECM_Recall_Contract_Error,ECM_ContractRecallCtrl.validateRecall(wrapObj.contr),'null');
                System.assertEquals(Label.ECM_Recall_Contract_Error,ECM_ContractRecallCtrl.validateRecall(wrapObj.contr2),'null');
                System.assertEquals(Label.ECM_Recall_Agreement_Error,ECM_ContractRecallCtrl.validateRecall(wrapObj.contr1),'null'); 
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        Test.stopTest();
    }
    /**
	* @description : createData - This methods used to Create all Test Data
	* @return : Wrapper
	* @param : Void
	*/
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
   /*public static WrapperInstAU createDataAU()
     {
         Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
         User salesRep = ECM_UtilityTestClass.createUser('srpau',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRepDevAU1234@test.com';
        insert salesRep;
          Account acc = EDGE_UtilityTestClass.getShedRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='saleau';
        acc.SAP_Sold_to__c ='sapsoldau';
        insert acc;
        
        //creating agreement type with Enable Recall of Contract as False
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.ECM_Enable_Recall_of_Contract__c=False;
        insert contractType;
         
         //creating contract of draft status
        Contract contr = ECM_UtilityTestClass.createContract(acc.Id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        contr.Status = 'Draft';
        insert contr;
          WrapperInstAU wrapObj = new WrapperInstAU();
        wrapObj.salesRep = salesRep;
        wrapObj.contr=contr.Id;
        wrapObj.acc=acc.Id;
        wrapObj.contractType=contractType.Id;
        wrapObj.contrRecTypeId=contrRecTypeId;
        wrapObj.geographyId=geographyId;
        return wrapObj;  
         
         

         
     }*/
    /**
	* @description : ValidateConfirmRecall - This methods used to Validate Recall
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void validateConfirmRecall(){
        WrapperInst wrapObj = createData();
        Contract conObj = new Contract();
        conObj.ECM_Parent_Contract__c = wrapObj.contr;
        List<Sobject> recallCtrl2 = new List<Sobject>();
        ECM_ContractRecallCtrl.confirmRecall(wrapObj.contr,conObj,'Re-negotiation with the customer');
        System.assert(recallCtrl2!=null,'recallCtrl2 should not be null');
       /* WrapperInstAU wrapObjAU = createDataAU();
        Contract conObjAU = new Contract();
        conObjAU.ECM_Parent_Contract__c = wrapObjAU.contr;
        ECM_ContractRecallCtrl.confirmRecall(wrapObjAU.contr,conObjAU,'Re-negotiation with the customer');*/
        
    }
    /**
	* @description : sendRecallNotificationValidate - This methods used to test sendRecallNotification
	* @return : void
	* @param : Void
	*/
    @isTest
    public static void sendRecallNotificationValidate(){
        WrapperInst wrapObj = createData();
        List<Sobject> recallCtrl3 = new List<Sobject>();
        ECM_ContractRecallCtrl.sendRecallNotification(wrapObj.contr);
        System.assert(recallCtrl3!=null,'recallCtrl3 should not be null');
    }
    /**
	* @description :  WrapperInst
	* @purpose : This is the Wrapper class to send Data
	*/
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
     /*class WrapperInstAU{
        String geographyId{get;set;}
        String contrRecTypeId{get;set;}
        String contractType{get;set;}
        String acc{get;set;}
        String contr{get;set;}
        User salesRep{get;set;}
    }*/
    
}