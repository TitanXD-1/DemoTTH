/*
* Class Name: ECM_CustomerResponseEmailServiceTest
* @description: This is the test class for ECM_CustomerResponseEmailServiceTest 
* @history: 
* VERSION      AUTHOR            DATE              DETAIL
* 1.0		 Pratap Sen		  18/07/2022		Initital Development for ECM-5904
* 1.1          Anamika Shukla    19/08/2022     ECM-5967 - added new method testPaySummary() 
*/
@isTest
public class ECM_CustomerResponseEmailServiceTest {
    public static Boolean isPS = true; 
 	/*
    * @description : This method tests all the methods of ECM_CustomerResponseEmailService for correct email subject line
    * @return : void
    * @param : void
    */
    @isTest
    public static void testEmailServicePositiveScenarios(){
        DataWrapper wrapData = setUpData();
        
        Test.startTest();
        
        String conNumber = [SELECT ContractNumber FROM Contract WHERE Id=:wrapData.conRec.Id LIMIT 1].ContractNumber;
        wrapData.email.subject = '  ‘DIAGEO COMMERCIAL AGREEMENT - Contract- '+conNumber+' - REPLY REQUIRED’';//Subject Line Type 1
        
        ECM_CustomerResponseEmailService emailService1 = new ECM_CustomerResponseEmailService();
        emailService1.handleInboundEmail(wrapData.email,wrapData.envelope);
        
        ContentVersion cVersion = [SELECT Id,ContentDocumentId,Content_Type__c,RecordType.Name FROM ContentVersion LIMIT 1];
        System.assert(cVersion.Content_Type__c == 'Customer Emails' && cVersion.RecordType.Name == 'Contracts','Customer Emails and Contracts should be in content Type and recordtype name field respectively');
        
        //Test if email and it's attachments are saved against contract record and validate there file types
        List<String> fileTypes = new List<String>();
        for(ContentDocumentLink conDoc : [SELECT Id,ContentDocument.title,ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId=: wrapData.conRec.Id]){
            fileTypes.add(conDoc.ContentDocument.FileExtension);
        }
        System.assert(fileTypes.size() == 3 && fileTypes.contains('txt') && fileTypes.contains('eml') && fileTypes.contains('png'),'filetypes should have 3 records and it should contaains tc=xt,eml and png');
        
        wrapData.email.subject = ' Sandbox: Anniversary - CONTRACT:'+ conNumber;//Subject Line Type 2
        ECM_CustomerResponseEmailService emailService2 = new ECM_CustomerResponseEmailService();
        emailService2.handleInboundEmail(wrapData.email,wrapData.envelope);
        
        //Test if the saved files are of correct record type & content type
        ContentVersion cVersion1 = [SELECT Id,ContentDocumentId,Content_Type__c, RecordType.Name FROM ContentVersion LIMIT 1];
        System.assert(cVersion1.Content_Type__c == 'Customer Emails' && cVersion1.RecordType.Name == 'Contracts','Customer Emails and Contracts should be in content Type and recordtype name field respectively');
        
        Test.stopTest();
    }
    
    /*
    * @description : This method tests the scenario when email subject line is incorrect
    * @return : void
    * @param : void
    */
    @isTest
    public static void testEmailServiceNegativeScenarios(){
        Try{
            DataWrapper wrapData = setUpData();
            wrapData.email.subject = 'Random Subject';
            ECM_CustomerResponseEmailService emailService = new ECM_CustomerResponseEmailService();
            emailService.handleInboundEmail(wrapData.email,wrapData.envelope);
        }
        Catch(Exception ex){
             System.debug(LoggingLevel.Debug,'Exception Caught in testEmailServiceNegativeMethod '+ ex.getLineNumber() +'\n'+ ex.getMessage());
             System.assert(ex.getMessage() != '','message should not be blank');
        }
    }
    
    @isTest
    public static void testPaySummary(){
        DataWrapper wrapData = setUpData();
        Test.startTest();
        if(isPS){
            String payNumber = [SELECT Id,Name FROM ECM_Payment_Summary__c WHERE Id=:wrapData.payRec.Id LIMIT 1].Name;
            wrapData.email.subject = '  ‘Diageo invoice request for payment of the Trading, Status and Promotional Support Agreement(AL RIMA S.A., Contract number-00012306 and PS-'+payNumber+')’';//Subject Line Type 1
            
            ECM_CustomerResponseEmailService emailService1 = new ECM_CustomerResponseEmailService();
            emailService1.handleInboundEmail(wrapData.email,wrapData.envelope);
            
            ContentVersion cVersion = [SELECT Id,ContentDocumentId,Content_Type__c,RecordType.Name FROM ContentVersion LIMIT 1];
            System.assert(cVersion.Content_Type__c == 'Customer Emails' && cVersion.RecordType.Name == 'Payments','Customer Emails and Payments should be in content Type and recordtype name field respectively');
            
            //Test if email and it's attachments are saved against contract record and validate there file types
            List<String> fileTypes = new List<String>();
            for(ContentDocumentLink conDoc : [SELECT Id,ContentDocument.title,ContentDocument.FileExtension FROM ContentDocumentLink WHERE LinkedEntityId=: wrapData.conRec.Id]){
                fileTypes.add(conDoc.ContentDocument.FileExtension);
            }
            
            wrapData.email.subject = ' Sandbox: New Message for Payment Summary'+ payNumber;//Subject Line Type 2
            ECM_CustomerResponseEmailService emailService2 = new ECM_CustomerResponseEmailService();
            emailService2.handleInboundEmail(wrapData.email,wrapData.envelope);
            
            //Test if the saved files are of correct record type & content type
            //ContentVersion cVersion = [SELECT Id,ContentDocumentId,Content_Type__c, RecordType.Name FROM ContentVersion LIMIT 1];
            //System.assert(cVersion.Content_Type__c == 'Customer Emails' && cVersion.RecordType.Name == 'Contracts');
        }
        Test.stopTest(); 
    }
    
    
    /*
    * @description : Detects the inboundEmail replied on the system sent thread & finds the designated record number/name 
    * @return : Messaging.InboundEmailResult
    * @param : Messaging.InboundEmail email, Messaging.InboundEnvelope envelope
    */
    @isTest
    public static DataWrapper setUpData(){
        //Record Type Ids
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        String contractRecordTypeIdAsset = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Asset Contract').getRecordTypeId();
        String bannerRecordTypeId;
        bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
        //EDGE_UtilityTestClass.createOrgSettings();
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        marketSetting.ECM_Payment_Management_Email__c = 'outletPOC2@acc.com';
        marketSetting.Threshold_Format__c = 'Percent';
        insert marketSetting;
        System.assert(marketSetting.id!=null,'marketSetting should not be null');
        
        //Territory for outlet
        Territory__c  testTerritory = EDGE_UtilityTestClass.getTerritoryRec();
        insert testTerritory;
        
        //Contract Mandatory Records : Account
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Email_for_contracts_payments__c = 'outletPOC@acc.com';
        insert acc;
        
        //Sales Rep & Sales Manager User
        User salesMg = ECM_UtilityTestClass.createUser('sm',ECM_UtilityTestClass.getProfile('Sales Manager').Id);
        salesMg.Username = 'salesMg1234@test.com';
        salesMg.Email = 'salesMg1234@test.com';
        salesMg.Available_Countries__c='ES';
        insert salesMg;
        
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp1234@test.com';
        salesRep.Email = 'salesRp1234@test.com';
        salesRep.ManagerId = salesMg.Id;
        salesRep.Available_Countries__c='ES';
        insert salesRep;
                
        //Contract Mandatory Records : Agreement Type
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        contractType.Name='PromotionalES';
        contractType.ECM_Volume_UoM_for_Beer__c = 'EU';
        contractType.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Volume Target;Rate Per UoM;Investment';
        insert contractType;

		//Setting up contract
        Contract objContract = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeIdAsset);
        objContract.Status = 'Draft';
        objContract.ECM_Territory__c=testterritory.Id;
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.ownerId = salesRep.Id;
        objContract.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContract.ECM_Duration__c = 12;
        objContract.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        insert objContract; 

        //Setting up second contract 
        Contract objContract1 = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContract1.Status = 'Draft';
        objContract1.ECM_Territory__c=testterritory.Id;
        objContract1.ECM_Agreement_Type__c=contractType.Id;
        objContract1.ownerId = salesRep.Id;
        objContract1.StartDate = system.today().addmonths(-6).toStartOfMonth();
        objContract1.ECM_Duration__c = 12;
        objContract1.Contract_End_Date__c = system.today().addmonths(6).addDays(-1);
        insert objContract1; 
        
        //Payment Summary Setup
        ECM_Payment_Summary__c paySummary = new ECM_Payment_Summary__c();
        paySummary.ECM_Payment_Summary_Status__c = 'Submitted';
        paySummary.ECM_Contract__c = objContract.Id;
        paySummary.ECM_Type__c = 'Volume-Based';
        paySummary.ECM_Invoice_Receival_Date__c = System.today();
        paySummary.ECM_Invoice_Status__c = 'Requested';
        paySummary.ECM_Approval_Sub_Status__c = 'CIO Approval';
        insert paySummary;
        
        
        //Set up data for Messaging.InboundEmail email  
        Messaging.InboundEmail email = new Messaging.InboundEmail() ;
  		Messaging.InboundEnvelope envelope = new Messaging.InboundEnvelope();
        email.fromAddress = 'outletPOC@acc.com';
        email.fromname = 'Test_User';
        email.plainTextBody = 'Random Email Body';

        Messaging.InboundEmail.BinaryAttachment binAttachment = new Messaging.InboundEmail.BinaryAttachment();
        binAttachment.body = blob.valueOf('binary attachment Image');
        binAttachment.fileName = 'Imagefile.png';
        binAttachment.mimeTypeSubType = 'image/png';
        email.binaryAttachments = new Messaging.inboundEmail.BinaryAttachment[]{binAttachment};
        
        Messaging.InboundEmail.TextAttachment txtAttachment = new Messaging.InboundEmail.TextAttachment();
        txtAttachment.body = 'Random Text...';
        txtAttachment.fileName = 'Textfile.txt';
        txtAttachment.mimeTypeSubType = 'text/plain';
        email.textAttachments = new Messaging.inboundEmail.TextAttachment[] {txtAttachment};

        //Prepare wrapper data
        DataWrapper wrapper = new DataWrapper();
        wrapper.conRec = objContract;
        wrapper.payRec = paySummary;
        wrapper.email = email;
        wrapper.envelope = envelope;
        return wrapper;
    }
    
    //Wrapper class to send required data to test methods 
    public class DataWrapper{
        public Contract conRec{get;set;}
        public ECM_Payment_Summary__c payRec{get;set;}
        Messaging.InboundEmail email{get;set;}
        Messaging.InboundEnvelope envelope{get;set;}
    }
    
    
}