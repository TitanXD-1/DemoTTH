/**
    *Class Name : CST_SendToApprovalControllerTest
    * @description: CST_SendToApprovalControllerTest
    
* @history

* 1.0         CST Team              19/05/2021        Initial Development

*/
@isTest
public class CST_SendToApprovalControllerTest {
    
/**

* @description testdata

* @return CST_Claim__c

* @param Id

*/
    
    
    public static CST_Claim__c testdata(Id countryId){
     
        
        //Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;






        Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        upsert salesorg;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[SEU]';
        pickupOption.Sales_Organisation__c= salesorg.Id;






        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        upsert pickupOption;
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        outletAccount.CST_Default_Approver__c=UserInfo.getUserId();
        outletAccount.Direct_Customer__c=true;
        insert outletAccount;
        outletAccount.Direct_Customer__c=true;
        outletAccount.Sales_Organisation__c = salesOrg.Id;
        update outletAccount;
        /*Account accnt = EDGE_UtilityTestClass.getOutletRecord();
        accnt.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        accnt.Direct_Customer__c=true;
        //accnt.CST_Default_Approver__c=null;
        upsert accnt;*/
        







        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, outletAccount.Id);
        claim.CST_Total_Amount__c=10.00;
        //claim.CST_Status__c='New';
        //claim.OwnerId=UserInfo.getUserId();
        claim.CST_Approver__c=UserInfo.getUserId();
        claim.CST_Sales_Organisation__c = salesorg.Id;

        insert claim;
        return claim;        
    } 
    /**

* @description approvalTest

*/    
    
    /*@isTest
    public static void approvalTest1(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
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
        usrmngr.Available_Countries__c='ES';
        insert usrmngr;
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
        usr.ManagerId = usrmngr.Id;
        insert usr;
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        
        Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        upsert salesorg;
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        String comment='test';
        String appAction='Approve';
        String rJctReason='';
        Id claimNull;
        
        System.runAs(usr){
            
            CST_Claim__c claim4 = testdata(countryId);
            claim4.CST_Sales_Organisation__c= salesorg.Id;
            claim4.CST_Approver__c=usr.id;
            claim4.OwnerId=usr.id;
            update claim4;
			Test.startTest();

            
            CST_SendToApprovalController.getClaimValidStatus(claim4.Id);
            CST_SendToApprovalController.getClaimValidStatus(claimNull);
            CST_SendToApprovalController.toastNotificationCheck(claim4.Id);
            CST_SendToApprovalController.getUser(usr.Id, claim4.Id);            
            CST_SendToApprovalController.getApproverList(claim4.Id);
            CST_SendToApprovalController.getApproverList(claimNull);
            CST_SendToApprovalController.getPickListForRejectionReason();
            
            Test.stopTest();
        }
    }*/
    
/**

* @description approvalTest

*/    
    
    @isTest
    public static void approvalTest(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcm124@test.com';
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
        usr.Username ='manger123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        upsert salesorg;
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        String comment='test';
        String appAction='Approve';
        String rJctReason='';
        Id claimNull;
        
        System.runAs(usr){
            Test.startTest();
            CST_Claim__c claim4 = testdata(countryId);
            //claim4.CST_Sales_Organisation__c= salesorg.Id;
            claim4.CST_Approver__c=usr.Id;
            //claim4.CST_Status__c= 'Assigned to Default Approver';
            //claim4.CST_Total_Amount__c=0.00;
            claim4.OwnerId=usr.Id;
            //update claim4;
            
            /*Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
            app.setObjectId(claim4.id);
            app.setSubmitterId(usr.Id);
            //app.setComments('Submitting request for approval.');
            //app.setNextApproverIds(new id[]{usr.Id});   
            app.setProcessDefinitionNameOrId('CST_Claim_Approval');
            app.setSkipEntryCriteria(true);
            Approval.ProcessResult result = Approval.process(app);
            
            System.debug('!!!!!!result!!!!!' + result);
            
            List<Id> newWorkItemIds = result.getNewWorkitemIds();
            Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();

            req2.setComments(comment);
            req2.setAction(appAction);
            req2.setNextApproverIds(new id[]{usr.Id});        
            req2.setWorkitemId(newWorkItemIds.get(0));
            Approval.ProcessResult result2 =  Approval.process(req2);*/
            






            //CST_SendToApprovalController.submitForApprovalRecord(claim4.Id,comment,appAction);
            //CST_SendToApprovalController.sendforApproval(claim4.Id, usr.id);
            //CST_SendToApprovalController.sendforApproval(claim4.Id,comment,appAction,rJctReason);
            CST_SendToApprovalController.checkReadyforApproval(claim4.Id);
            CST_SendToApprovalController.checkReadyforApproval(claimNull);
            //CST_SendToApprovalController.checkReadyforApproval(appmatrix.Id);







            //claim4.CST_Status__c='Assigned to Default Approver';
            //update claim4;
            //CST_SendToApprovalController.checkValidForApproval(claim4.Id,true);
            
           
            Test.stopTest();
        }
    }
    
/**

* @description approvalTest2

*/    
    
    @isTest
    public static void approvalTest2(){
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testMngr@test.com';
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
        usr.email = 'test.Mamager@test.com';
        usr.Username ='Mngr@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        insert usr;
        
        Profile prof1 = [select id from profile where name=: 'CST Approver'];
        User usrmngr1 = new User();
        usrmngr1.firstName = 'testManager';
        usrmngr1.lastName = 't2';
        usrmngr1.profileId = prof1.id;        
        usrmngr1.email = 'test.Mamager@test.com';
        usrmngr1.Username ='testcmMngr@test11.com';
        usrmngr1.Alias='test';
        usrmngr1.Timezonesidkey='America/Los_Angeles';
        usrmngr1.LocaleSidKey='en_US';
        usrmngr1.LanguageLocaleKey='en_US';
        usrmngr1.EmailEncodingKey='UTF-8';
        usrmngr1.Available_Countries__c='ES';
        insert usrmngr1;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof1.id;        
        usr1.email = 'test@test.com';
        usr1.Username ='testcm123@test22.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='ES';
        usr1.ManagerId = usrmngr.Id;
        usr1.DelegatedApproverId = usr.Id;
        insert usr1;
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('BE');
        //Id cntryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[BE]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        //upsert pickupOption;
        
        Sales_Organisation__c salesOrg = new Sales_Organisation__c();
        salesOrg.Name='Test';
        salesOrg.Description__c='test';
        salesOrg.Code__c='BE01';
        salesOrg.Country__c=countryId;
        insert salesOrg;

        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Tax Code');
        pickupOption1.Name = 'Gold[BE]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        pickupOption1.Sales_Organisation__c= salesOrg.Id;
        //insert pickupOption1;
        
        

        Test.startTest();
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        //outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        //upsert outletAccount;
        outletAccount.Direct_Customer__c=true;
        //update outletAccount;        
        
       
         
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, null);
        claim.CST_Sales_Organisation__c=salesOrg.Id;
        claim.OwnerId = usr1.Id;
        insert claim;
        
        Map<Id,CST_Claim__c> oldItem = new Map<Id,CST_Claim__c>();
        oldItem.put(claim.id,claim);
        
        claim.CST_Country__c=countryId;
        claim.CST_Invoice_Number__c='1';
        claim.CST_Invoice_Date__c=System.today()-2;
        claim.CurrencyIsoCode= 'AUD';
        claim.CST_Approver__c=usr.id;
        claim.CST_Account__c=outletAccount.Id;
        claim.CST_Total_Amount__c=10;
        //claim.Claim_Tax_Code__c= pickupOption1.id;
        //claim.OwnerId = usr1.Id;
        claim.CST_Sales_Organisation__c=salesOrg.Id;
        //claim.CST_Status__c='New';
        update claim;
        CST_Claim_Item__c claimItem = EDGE_UtilityTestClass.getclaimItemRecord(claim.Id);
        //claimItem.CurrencyIsoCode= 'AUD';
        claimItem.CST_Net_Value__c=10;
        claimItem.Type__c = 'A&P';
        //claimItem.CST_Tax_Code__c= pickupOption.id;
        //insert claimItem;
        
        Set<Id> ids = new Set<Id>();
        ids.add(claim.Id);
        List<CST_Claim__c> listnewItems = new List<CST_Claim__c>();
        listnewItems.add(claim);
       // EDGE_CSTClaimTriggerHelper.updateApproverName(listnewItems);
        Map<Id,CST_Claim__c> newItem = new Map<Id,CST_Claim__c>();
        newItem.put(claim.id,claim);
        System.debug('test oldItem'+newItem);
        //EDGE_CSTClaimTriggerHelper.updateClaimItemCurrency(newItem,oldItem);
        
        //EDGE_CSTClaimTriggerHelper.sendforApproval(ids);
        //EDGE_CSTClaimTriggerHelper.validateAndReGenerateSharing(newItem.values(),oldItem);
       // EDGE_CSTClaimTriggerHelper.submitApproval(newItem,oldItem);
       // EDGE_CSTClaimTriggerHelper.rejectRecordProcess(newItem,oldItem);
       // EDGE_CSTClaimTriggerHelper.approveRecordsProcess(newItem,oldItem);
       String comment='test';
       String appAction='Approve';
       String rJctReason='';
      
        
       System.runAs(usr){
        Approval.ProcessSubmitRequest app = new Approval.ProcessSubmitRequest();
        app.setObjectId(claim.id);
        app.setComments('Submitting request for approval');
        app.setSubmitterId(usr.Id);
        app.setNextApproverIds(new id[]{usr.Id});   
        app.setProcessDefinitionNameOrId('CST_Claim_Approval');
        app.setSkipEntryCriteria(true);
        //Approval.ProcessResult result = Approval.process(app);
        //EDGE_CSTClaimTriggerHelper.sendforApproval(ids, newItem);
        //req2.setNextApproverIds(new id[]{usr.Id});        
        //req2.setWorkitemId(newWorkItemIds.get(0));
        //Approval.ProcessResult result2 =  Approval.process(req2);
       
        claim.CST_Status__c = 'Assigned to Default Approver';
        claim.CST_Approver__c=usrmngr.id;
        claim.OwnerId = usrmngr.id;
        update claim;
           
        CST_SendToApprovalController.sendforApproval(claim.Id,comment,appAction,rJctReason);
        
        /* claim.CST_Status__c = 'Assigned To Approver';
        update claim;
        
        claim.CST_Status__c = 'Rejected';
        update claim;
        claim.CST_Status__c = 'New';
        //claim.OwnerId = usrmngr1.id;
        update claim;
        delete claim; */  
        
        Test.stopTest();
         }
    }
    
    @isTest
    public static void claimTest2(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        CST_Claim__c claim = testdata(countryId);
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        Id userid= UserInfo.getUserId();
        Id claimNull;
        Id userNull;
        Test.startTest();
        CST_SendToApprovalController.getClaimValidStatus(claim.Id);
        CST_SendToApprovalController.toggleQuery(claim.Id,true,userid);
        //CST_SendToApprovalController.toggleQuery(claim.Id,false);
        CST_SendToApprovalController.updateClaim(claim.Id,userid);
        CST_SendToApprovalController.updateClaim(claimNull,userNull);
        CST_SendToApprovalController.updateClaim(appmatrix.Id,userid);
        Test.stopTest();
    }
     @isTest
    public static void validApprovalTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[SEU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        upsert pickupOption;
        Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        salesorg.Tax_Code_Mandatory__c = true;
        upsert salesorg;
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        outletAccount.CST_Default_Approver__c=UserInfo.getUserId();
        outletAccount.Direct_Customer__c=true;
        outletAccount.Sales_Organisation__c = salesorg.Id;
        upsert outletAccount;
        Account accnt = EDGE_UtilityTestClass.getOutletRecord();
        accnt.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        accnt.Direct_Customer__c=true;
        accnt.Sales_Organisation__c = salesorg.Id;
        accnt.Name='TestAcc1';
        upsert accnt;
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        Approver_Matrix__c appmatrix1 = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix1;
        CST_Claim__c newclaim = EDGE_UtilityTestClass.getclaimRecord(countryId, accnt.Id);  
        newclaim.CST_Sales_Organisation__c= salesorg.Id;
        insert newclaim;
        CST_Claim__c claim2 = EDGE_UtilityTestClass.getclaimRecord(countryId, outletAccount.Id);   
        claim2.CST_Sales_Organisation__c= salesorg.Id;
        insert claim2;
        CST_Claim__c claim3 = EDGE_UtilityTestClass.getclaimRecord(countryId, accnt.Id);
        claim3.CST_Sales_Organisation__c= salesorg.Id;
        //claim3.CST_Manual_Validation__c=True;
        insert claim3;
        CST_Claim__c claim4 = EDGE_UtilityTestClass.getclaimRecord(countryId, accnt.Id); 
        claim4.CST_Sales_Organisation__c= salesorg.Id;
        claim4.CST_Total_Amount__c = 100.00;
        claim4.Total_value__c = 100;
        claim4.CST_Approver__c=UserInfo.getUserId();
        claim4.OwnerId=UserInfo.getUserId();
        insert claim4;
        CST_Claim__c claim5 = EDGE_UtilityTestClass.getclaimRecord(countryId, accnt.Id); 
        claim5.CST_Sales_Organisation__c= salesorg.Id;
        claim5.CST_Total_Amount__c = 100.00;
        claim5.Total_value__c = 100;
        claim5.CST_Approver__c=UserInfo.getUserId();
        claim5.OwnerId=UserInfo.getUserId();
        insert claim5;
        CST_Claim__c claim6 = EDGE_UtilityTestClass.getclaimRecord(countryId, accnt.Id);
        claim6.CST_Sales_Organisation__c= salesorg.Id;
        claim6.CST_Total_Amount__c = 100.00;
        claim6.Total_value__c = 100;
        claim6.CST_Approver__c=UserInfo.getUserId();
        claim6.OwnerId=UserInfo.getUserId();
        insert claim6;
        Id claimNull;
        Test.startTest();
        //
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        conVerRec.Title = 'Test.jpeg';
        conVerRec.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('CSTClaim').getRecordTypeId();
        //conVerRec.Content_Type__c = 'CSTClaim';
        insert conVerRec;
        System.assert(conVerRec.Id != null);           
           
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        System.assertEquals(documents.size(), 1);
           
        ContentDocumentLink conDocLnkRec = EDGE_UtilityTestClass.getConDocLink (newclaim.Id,documents[0].Id);
        insert conDocLnkRec;   
        ContentDocumentLink conDocLnkRec1 = EDGE_UtilityTestClass.getConDocLink (claim2.Id,documents[0].Id);
        insert conDocLnkRec1;   
        ContentDocumentLink conDocLnkRec2 = EDGE_UtilityTestClass.getConDocLink (claim3.Id,documents[0].Id);
        insert conDocLnkRec2;   
        ContentDocumentLink conDocLnkRec3 = EDGE_UtilityTestClass.getConDocLink (appmatrix.Id,documents[0].Id);
        insert conDocLnkRec3;
        ContentDocumentLink conDocLnkRec4 = EDGE_UtilityTestClass.getConDocLink (claim4.Id,documents[0].Id);
        insert conDocLnkRec4;
        ContentDocumentLink conDocLnkRec5 = EDGE_UtilityTestClass.getConDocLink (claim5.Id,documents[0].Id);
        insert conDocLnkRec5;
        ContentDocumentLink conDocLnkRec6 = EDGE_UtilityTestClass.getConDocLink (claim6.Id,documents[0].Id);
        insert conDocLnkRec6;
                             
        CST_SendToApprovalController.checkValidForApproval(newclaim.Id,true);
        CST_SendToApprovalController.checkValidForApproval(claimNull,true);
        CST_SendToApprovalController.checkValidForApproval(appmatrix.Id,true);
        CST_SendToApprovalController.checkValidForApproval(claim2.Id,true);
        CST_SendToApprovalController.checkValidForApproval(claim3.Id,true);
        claim3.CST_Status__c='Assigned to Default Approver';
		
        CST_SendToApprovalController.checkValidForApproval(claim3.Id,true);
        claim3.CST_Status__c='In Query';
        update claim3;
        CST_SendToApprovalController.checkValidForApproval(claim3.Id,true);
        
        
        claim4.CST_Sales_Organisation__c= salesorg.Id;
        claim5.CST_Sales_Organisation__c= salesorg.Id;
        claim6.CST_Sales_Organisation__c= salesorg.Id;
        String taxpickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c taxpickupOption = EDGE_UtilityTestClass.getTaxPickUpOption(geographyId,'Tax Code');
        taxpickupOption.Sales_Organisation__c= salesorg.Id;
        taxpickupOption.RecordTypeId = taxpickupRecordType;
        taxpickupOption.CST_Tax_Rate__c= 10;
        taxpickupOption.CST_Type__c = 'A&P'; 
        taxpickupOption.CST_Default_record__c = true;
        upsert taxpickupOption;
        
        Product__c product = new Product__c();
        product.Name='Test';
        product.Product_Full_Name__c = 'Test Product 1 full name';
        product.Country__c=geographyId;
        insert product;
        
        Territory_Hierarchy__c TerritoryHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
        insert TerritoryHierarchy;
        Territory__c  territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Business_Unit__c = TerritoryHierarchy.Id;
        insert territory;
        
        Territory_Budget__c TerritoryBudget = new Territory_Budget__c();
        TerritoryBudget.ECM_Type__c =  'TI';
        TerritoryBudget.Territory__c = territory.id;
        TerritoryBudget.End_Date__c = system.today()+5;
        TerritoryBudget.Initial_Amount__c = 100.00;
        TerritoryBudget.Start_Date__c = system.today()+10;
        TerritoryBudget.ECM_Territory_Hierarchy__c = TerritoryHierarchy.id;
        insert TerritoryBudget;
                
        ECM_Internal_Order__c IORecord = new ECM_Internal_Order__c();
        IORecord.Name = 'IO-123456789';
        IORecord.ECM_Product__c = product.Id;
        IORecord.ECM_Budget_Type__c = TerritoryBudget.Id;
        IORecord.ECM_Budget_Type_Pickup_Option__c = taxpickupOption.Id;
        IORecord.ECM_Geography__c = geographyId;
        IORecord.ECM_Description__c = 'Testing Record';
        IORecord.ECM_Start_Date__c = Date.newInstance(System.today().year(), 7, 17);
        IORecord.ECM_End_Date__c = Date.newInstance(System.today().year(), 7, 27);
        IORecord.ECM_Budget_Amount__c = 100;
        IORecord.SAP_IO_Type__c='A&P IO';
        insert IORecord;
        
        General_Ledger__c genLed =  new General_Ledger__c();
        genLed.Code__c='12345';
        genLed.Name__c='test';
        genLed.Type__c='A&P';
        genLed.Pricing_Condition__c='test';
        genLed.Name='testLedger';
        genLed.CurrencyIsoCode = 'GBP';
        insert genLed;
        claim4.Claim_Tax_Code__c = taxpickupOption.Id;
        claim5.Claim_Tax_Code__c = taxpickupOption.Id;
        claim6.Claim_Tax_Code__c = taxpickupOption.Id;
        CST_Claim_Item__c claimItem = EDGE_UtilityTestClass.getclaimItemRecord(claim4.Id);
        claimItem.Type__c = 'A&P';
        claimItem.CST_Net_Value__c=90.00;
        claimItem.CST_Internal_Order__c=IORecord.Id;
        claimItem.CST_General_Ledger__c=genLed.Id;
        claimItem.CST_Tax_Code__c=taxpickupOption.id;
        insert claimItem;
        CST_Claim_Item__c claimItem1 = EDGE_UtilityTestClass.getclaimItemRecord(claim5.Id);
        claimItem1.Type__c = 'A&P';
        claimItem1.CST_Net_Value__c=99.50;
        claimItem1.CST_Internal_Order__c=IORecord.Id;
        claimItem1.CST_General_Ledger__c=genLed.Id;
        claimItem1.CST_Tax_Code__c=taxpickupOption.id;
        insert claimItem1;
        CST_Claim_Item__c claimItem2 = EDGE_UtilityTestClass.getclaimItemRecord(claim6.Id);
        claimItem2.Type__c = 'A&P';
        claimItem2.CST_Net_Value__c=100.00;
        claimItem2.CST_Internal_Order__c=IORecord.Id;
        claimItem2.CST_General_Ledger__c=genLed.Id;
        claimItem2.CST_Tax_Code__c=taxpickupOption.id;
        insert claimItem2;
        claim4.CST_Status__c='Assigned to Default Approver';
        update claim4;
        claim5.CST_Status__c='Assigned to Default Approver';
        update claim5;
        claim6.CST_Status__c='Assigned to Default Approver';
        update claim6;
        //CST_SendToApprovalController.checkReadyforApproval(claim4.Id);
        CST_SendToApprovalController.checkValidForApproval(claim4.Id,true);
        CST_SendToApprovalController.checkValidForApproval(claim5.Id,true);
        CST_SendToApprovalController.checkValidForApproval(claim6.Id,true);
		CST_SendToApprovalController.getPickListForRejectionReason();
        CST_SendToApprovalController.toastNotificationCheck(claim2.Id);
        CST_SendToApprovalController.toastNotificationCheck(claim4.Id);
        CST_SendToApprovalController.getUser(UserInfo.getUserId(),claim2.Id);
        CST_SendToApprovalController.getUser(UserInfo.getUserId(),null);
        Test.stopTest();
    }
    @isTest
    public static void claimRejectTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        CST_Claim__c claim = testdata(countryId);
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        Id userid= UserInfo.getUserId();
        Id claimNull;
        Id userNull;
        Test.startTest();
         claim.CST_Status__c='Rejected';
         update claim;
         CST_SendToApprovalController.updateRecjectionReason(claim.Id,'Duplication','test');

        try{
           CST_SendToApprovalController.updateRecjectionReason(claimNull,'','');  
        }catch(exception ex){
            system.debug('Something went wrong');
        }

        Test.stopTest();
    }
    @isTest
    public static void validateUpdateClaim(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        CST_Claim__c claim = testdata(countryId);

        
        Approver_Matrix__c appMatrixObj = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        appMatrixObj.Min_Limit_Amount__c = 0;
        appMatrixObj.Max_Limit__c = 2500;
        appMatrixObj.Sales_Org__c = 'SEU'; 

        
        insert appMatrixObj;
        Approver_Matrix__c appMatrixObj1 = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        appMatrixObj1.CurrencyIsoCode = 'AED';
        appMatrixObj1.Min_Limit_Amount__c = 0;
        appMatrixObj1.Max_Limit__c = 2500;
        appMatrixObj1.Sales_Org__c ='SEU';
        insert appMatrixObj1;
        Test.startTest();
        Map<Id,String> approverMap = CST_SendToApprovalController.getApproverList(claim.Id);
        Test.stopTest();
        System.assertEquals(1, approverMap.size());
    }
    






   /* @isTest
    public static void approvalTest2(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
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
        usrmngr.Available_Countries__c='ES';
        insert usrmngr;
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
        usr.ManagerId = usrmngr.Id;
        insert usr;
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        
        Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        upsert salesorg;
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        String comment='test';
        String appAction='Approve';
        String rJctReason='';
        Id claimNull;
        
        System.runAs(usr){
            
            //Test.startTest();
            CST_Claim__c claim4 = testdata(countryId);
            claim4.CST_Sales_Organisation__c= salesorg.Id;
            claim4.CST_Approver__c=usr.id;             
            claim4.OwnerId=usr.id;
            update claim4;
            
            Test.startTest();
            CST_SendToApprovalController.submitForApprovalRecord(claim4.Id,comment,appAction);            
            //CST_SendToApprovalController.sendforApproval(claim4.Id,comment,appAction,rJctReason);             
            Test.stopTest();
        }
    }*/
    
    
    ///
      @isTest
    public static void checkForAttachmentTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[SEU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        //upsert pickupOption;
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        outletAccount.CST_Default_Approver__c=UserInfo.getUserId();
        outletAccount.Direct_Customer__c=true;
        //upsert outletAccount;
        Account accnt = EDGE_UtilityTestClass.getOutletRecord();
        accnt.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        accnt.Direct_Customer__c=true;
        accnt.Name='TestAcc1';
        //upsert accnt;
        Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Default_Approver__c= UserInfo.getUserId();
        upsert salesorg;
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        insert appmatrix;
        CST_Claim__c newclaim = EDGE_UtilityTestClass.getclaimRecord(countryId, null);  
        newclaim.CST_Sales_Organisation__c= salesorg.Id;
        insert newclaim;
        Test.startTest();
        
        CST_SendToApprovalController.checkValidForApproval(newclaim.Id,true);
        newclaim.CST_Status__c='Assigned to Default Approver';
		update newclaim;
        CST_SendToApprovalController.checkValidForApproval(newclaim.Id,true);
       
        
        

        Test.stopTest();
    }
    @isTest
        public static void getClaimValidStatustest(){
            Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
           Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
            upsert salesorg;
            CST_Claim__c newclaim = EDGE_UtilityTestClass.getclaimRecord(countryId, null);  
        	newclaim.CST_Sales_Organisation__c= salesorg.Id;
        	insert newclaim;
            Test.startTest();
            CST_SendToApprovalController.getClaimValidStatus(newclaim.Id);
            Test.stopTest();
        }
   /* @isTest
        public static void updateRecjectionReasontest(){
            Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
           Sales_Organisation__c salesorg= EDGE_UtilityTestClass.getsalesorgRecord(countryId);
            upsert salesorg;
            CST_Claim__c newclaim1 = EDGE_UtilityTestClass.getclaimRecord(countryId, null);  
        	newclaim1.CST_Sales_Organisation__c= salesorg.Id;
        	insert newclaim1;
            Test.startTest();
            try
      {
        String errorRelease = CST_SendToApprovalController.updateRecjectionReason(newclaim1.Id,'test','test1');
      }
      catch(exception e)
         {
}     
            CST_SendToApprovalController.updateRecjectionReason();
             Test.stopTest();

        }*/
}