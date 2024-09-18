/*
 * Class Name : EDGE_CSTClaimTriggerHelperTest
 * @description: This is CLaim Item Trigger Helper Test Class
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team          19/05/2021        Initial Development
*/


@isTest
public class EDGE_CSTClaimTriggerHelperTest {
    
    
/**

* @description claimtriggerTest

* @return void 

* @param 

*/
    
    @isTest
    public static void claimtriggerTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcm1Mngr2@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='ES';
        usrmngr.Sales_Organisation__c = 'AT01' ;
        insert usrmngr;
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1234@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Sales_Organisation__c = 'AT01' ;
        usr.ManagerId = usrmngr.Id;
        insert usr;
        
        Profile prof1 = [select id from profile where name=: 'CST Approver'];
        User usrmngr1 = new User();
        usrmngr1.firstName = 'testManager';
        usrmngr1.lastName = 't2';
        usrmngr1.profileId = prof1.id;        
        usrmngr1.email = 'test.Mamager@test.com';
        usrmngr1.Username ='testcmMngr54@test11.com';
        usrmngr1.Alias='test';
        usrmngr1.Timezonesidkey='America/Los_Angeles';
        usrmngr1.LocaleSidKey='en_US';
        usrmngr1.LanguageLocaleKey='en_US';
        usrmngr1.EmailEncodingKey='UTF-8';
        usrmngr1.Available_Countries__c='ES';
        usrmngr1.Sales_Organisation__c = 'BE01' ;
        insert usrmngr1;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof1.id;        
        usr1.email = 'test@test.com';
        usr1.Username ='testcm1239@test22.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='ES';
        usr1.ManagerId = usrmngr.Id;
        usr1.DelegatedApproverId = usr.Id;
        usr1.Sales_Organisation__c = 'AT01' ;
        insert usr1;
        
        //usr1.Sales_Organisation__c = 'CE01' ;
        //update usr1;
        
       /* Profile prof2 = [select id from profile where name=: 'CST Creator'];
        User usr2 = new User();
        usr2.firstName = 'test12';
        usr2.lastName = 'test22';
        usr2.profileId = prof2.id;        
        usr2.email = 'test@test2.com';
        usr2.Username ='testcm1239@test222.com';
        usr2.Alias='test23';
        usr2.Timezonesidkey='America/Los_Angeles';
        usr2.LocaleSidKey='en_US';
        usr2.LanguageLocaleKey='en_US';
        usr2.EmailEncodingKey='UTF-8';
        usr2.Available_Countries__c='AU';
        usr2.ManagerId = usrmngr.Id;
        usr2.DelegatedApproverId = usr.Id;
        usr2.Sales_Organisation__c = 'CE01' ;
        insert usr2;

           */
        
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('BE');
        //Id cntryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[BE]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        upsert pickupOption;
        System.assert(pickupOption.id!=null,'pickupOption should not be null');
        
        /*Sales_Organisation__c salesOrg = new Sales_Organisation__c();
        salesOrg.Name='Test';
        salesOrg.Description__c='test';
        salesOrg.Code__c='BE01';
        salesOrg.Country__c=countryId;
        insert salesOrg;*/
        
        Sales_Organisation__c salesOrg1 = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesOrg1.Name='Test';
        salesOrg1.Description__c='test';
        salesOrg1.Code__c='BE01';

        /*Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Tax Code');
        pickupOption1.Name = 'Gold[BE]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        pickupOption1.Sales_Organisation__c= salesOrg.Id;
        insert pickupOption1;*/
        
        

        
        /*Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        upsert outletAccount;
        outletAccount.Direct_Customer__c=true;
        update outletAccount;  */      
        
       	Test.startTest();
         
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, null);
        claim.CST_Sales_Organisation__c=salesOrg1.Id;
        claim.OwnerId = usr1.Id;
        insert claim;
        
        Map<Id,CST_Claim__c> oldItem = new Map<Id,CST_Claim__c>();
        oldItem.put(claim.id,claim);
        
        claim.CST_Country__c=countryId;
        claim.CST_Invoice_Number__c='1';
        claim.CST_Invoice_Date__c=System.today()-2;
        claim.CurrencyIsoCode= 'AUD';
        claim.CST_Approver__c=usr.id;
        //claim.CST_Account__c=outletAccount.Id;
        claim.CST_Total_Amount__c=10;
        //claim.Claim_Tax_Code__c= pickupOption1.id;
        //claim.OwnerId = usr1.Id;
        claim.CST_Sales_Organisation__c=salesOrg1.Id;
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
        System.debug(loggingLevel.debug,'test oldItem'+newItem);
        //EDGE_CSTClaimTriggerHelper.updateClaimItemCurrency(newItem,oldItem);
        
        //EDGE_CSTClaimTriggerHelper.sendforApproval(ids);
        //EDGE_CSTClaimTriggerHelper.validateAndReGenerateSharing(newItem.values(),oldItem);
       // EDGE_CSTClaimTriggerHelper.submitApproval(newItem,oldItem);
       // EDGE_CSTClaimTriggerHelper.rejectRecordProcess(newItem,oldItem);
       // EDGE_CSTClaimTriggerHelper.approveRecordsProcess(newItem,oldItem);
       
      
        
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
           
        
        
        claim.CST_Status__c = 'Assigned To Approver';
        update claim;
        //Change 
        claim.Claim_Reassign__c = usrmngr1.Id;
        update claim;
           
        /*claim.CST_Status__c = 'Rejected';
        update claim;
        claim.CST_Status__c = 'New';
        //claim.OwnerId = usrmngr1.id;
        update claim;
        delete claim; */  
        
        Test.stopTest();
         }
    }
    
    //
    @isTest
    public static void claimtriggerfeedTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcm1Mngr76@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='ES';
        usrmngr.Sales_Organisation__c = 'AT01' ;
        insert usrmngr;
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1246@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Sales_Organisation__c = 'AT01' ;
        usr.ManagerId = usrmngr.Id;
        insert usr;
        
        Profile prof1 = [select id from profile where name=: 'CST Approver'];
        User usrmngr1 = new User();
        usrmngr1.firstName = 'testManager';
        usrmngr1.lastName = 't2';
        usrmngr1.profileId = prof1.id;        
        usrmngr1.email = 'test.Mamager@test.com';
        usrmngr1.Username ='testcmMngr08@test11.com';
        usrmngr1.Alias='test';
        usrmngr1.Timezonesidkey='America/Los_Angeles';
        usrmngr1.LocaleSidKey='en_US';
        usrmngr1.LanguageLocaleKey='en_US';
        usrmngr1.EmailEncodingKey='UTF-8';
        usrmngr1.Available_Countries__c='ES';
        usrmngr1.Sales_Organisation__c = 'AT01' ;
        insert usrmngr1;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof1.id;        
        usr1.email = 'test@test.com';
        usr1.Username ='testcm123067@test22.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='ES';
        usr1.Sales_Organisation__c = 'AT01' ;
        usr1.ManagerId = usrmngr.Id;
        insert usr1;
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('BE');
        //Id cntryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[BE]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        upsert pickupOption;
        System.assert(pickupOption.id!=null,'pickupOption should not be null');
        
        Sales_Organisation__c salesOrg1 = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesOrg1.Name='Test';
        salesOrg1.Description__c='test';
        salesOrg1.Code__c='BE01';

        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Tax Code');
        pickupOption1.Name = 'Gold[BE]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        pickupOption1.Sales_Organisation__c= salesOrg1.Id;
        //insert pickupOption1;
        
        

        Test.startTest();
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        //upsert outletAccount;
        outletAccount.Direct_Customer__c=true;
        //update outletAccount;        
        
        
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, outletAccount.Id);
        claim.CST_Sales_Organisation__c=salesOrg1.Id;
        claim.OwnerId = usr1.Id;
        insert claim;
        
        Map<Id,CST_Claim__c> oldItem = new Map<Id,CST_Claim__c>();
        oldItem.put(claim.id,claim);
        
        claim.CST_Country__c=countryId;
        claim.CST_Invoice_Number__c='1';
        claim.CST_Invoice_Date__c=System.today()-2;
        claim.CurrencyIsoCode= 'AUD';
        claim.CST_Approver__c=usr.id;
        //claim.CST_Account__c=outletAccount.Id;
        claim.CST_Total_Amount__c=10;
        claim.Claim_Tax_Code__c= pickupOption1.id;
        //claim.OwnerId = usr1.Id;
        claim.CST_Sales_Organisation__c=salesOrg1.Id;
        //claim.CST_Status__c='New';
        update claim;

     
        FeedItem feed = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'TextPost', claim.Id);
        feed.ParentId= claim.Id;
        feed.Status = 'Published';
        insert feed;
        
        //FeedItem feed1 = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'TextPost', outletAccount.Id);
        //feed1.ParentId= outletAccount.Id;
        //feed1.Status = 'Published';
        //insert feed1;
        
       System.runAs(usr){
        
        claim.CST_Status__c = 'Assigned to Default Approver';
        claim.CST_Approver__c=usrmngr.id;
        claim.OwnerId = usrmngr.id;
        update claim;
        //Database.delete(feed1);
        
        
        
        Test.stopTest();
         }
    }
    //
    
    
      @isTest
    public static void claimtriggerTest1(){
        EDGE_UtilityTestClass.createOrgSettings();
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Mamager@test.com';
        usrmngr.Username ='testcm1Mngr807@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='ES';
        usrmngr.Sales_Organisation__c = 'AT01' ;
        insert usrmngr;
        System.assert(usrmngr.id!=null,'usrmngr should not be null');
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm1234702@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.ManagerId = usrmngr.Id;
        usr.Sales_Organisation__c = 'AT01' ;
        insert usr;
        
        Profile prof1 = [select id from profile where name=: 'CST Approver'];
        User usrmngr1 = new User();
        usrmngr1.firstName = 'testManager';
        usrmngr1.lastName = 't2';
        usrmngr1.profileId = prof1.id;        
        usrmngr1.email = 'test.Mamager@test.com';
        usrmngr1.Username ='test605cmMngr@test11.com';
        usrmngr1.Alias='test';
        usrmngr1.Timezonesidkey='America/Los_Angeles';
        usrmngr1.LocaleSidKey='en_US';
        usrmngr1.LanguageLocaleKey='en_US';
        usrmngr1.EmailEncodingKey='UTF-8';
        usrmngr1.Available_Countries__c='ES';
        usrmngr1.Sales_Organisation__c = 'AT01' ;
        insert usrmngr1;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof1.id;        
        usr1.email = 'test@test.com';
        usr1.Username ='testcm76123@test22.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='ES';
        usr1.Sales_Organisation__c = 'AT01' ;
        usr1.ManagerId = usrmngr.Id;
        insert usr1;
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('BE');
        //Id cntryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Id geographyId = countryId;
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[BE]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        upsert pickupOption;
        
        Sales_Organisation__c salesOrg1 = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesOrg1.Name='Test';
        salesOrg1.Description__c='test';
        salesOrg1.Code__c='BE01';

        String pickupRecordType1 = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Tax Code');
        pickupOption1.Name = 'Gold[BE]';
        pickupOption1.RecordTypeId = pickupRecordType1 ;
        pickupOption1.Status__c = 'Active';
        pickupOption1.CST_Tax_Rate__c= 10;
        pickupOption1.CST_Type__c = 'A&P'; 
        pickupOption1.CST_Default_record__c = true;
        pickupOption1.Sales_Organisation__c= salesOrg1.Id;
       // insert pickupOption1;
        
        

        Test.startTest();
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c=pickupOption.Id;
        //upsert outletAccount;
        outletAccount.Direct_Customer__c=true;
        //update outletAccount;        
        
       
         
        CST_Claim__c claim = EDGE_UtilityTestClass.getclaimRecord(countryId, outletAccount.Id);
        claim.CST_Sales_Organisation__c=salesOrg1.Id;
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
        claim.CST_Sales_Organisation__c=salesOrg1.Id;
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
        System.debug(loggingLevel.debug,'test oldItem'+newItem);
        //EDGE_CSTClaimTriggerHelper.updateClaimItemCurrency(newItem,oldItem);
        
        //EDGE_CSTClaimTriggerHelper.sendforApproval(ids);
        //EDGE_CSTClaimTriggerHelper.validateAndReGenerateSharing(newItem.values(),oldItem);
       // EDGE_CSTClaimTriggerHelper.submitApproval(newItem,oldItem);
       // EDGE_CSTClaimTriggerHelper.rejectRecordProcess(newItem,oldItem);
       // EDGE_CSTClaimTriggerHelper.approveRecordsProcess(newItem,oldItem);
       
      
        
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
       
        /*claim.CST_Status__c = 'Assigned to Default Approver';
        claim.CST_Approver__c=usrmngr.id;
        claim.OwnerId = usrmngr.id;
        update claim;
           
        
        
        claim.CST_Status__c = 'Assigned To Approver';
        update claim;*/
        
        claim.CST_Status__c = 'Rejected';
        update claim;
        claim.CST_Status__c = 'New';
        //claim.OwnerId = usrmngr1.id;
        update claim;
        delete claim;    
        
        Test.stopTest();
         }
    }
    //
    //
    /////////////
      /////////////
     @isTest
    public static void testUserAssgnment()
    {             
        
        
        //create MDM User
        User testMDMUser = EDGE_UtilityTestClass.runAsUser('MDMuser','Master Data Manager');
        testMDMUser.Available_Countries__c = 'AU';
        testMDMUser.Sales_Organisation__c = 'AT01';
        insert testMDMUser;
        
        //create MDM User
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('Adminuser','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        testAdminUser.Sales_Organisation__c = 'AT01';
        insert testAdminUser;
        
        User testCStApp3 = EDGE_UtilityTestClass.runAsUser('CSTApp3','CST Approver');
        testCStApp3.Available_Countries__c = 'AU';
        testCStApp3.Sales_Organisation__c = 'AT01';
        //testCSTApp.DelegatedApproverId = testAdminUser.Id;
        insert testCStApp3;
        
      /*  User testCStApp23 = EDGE_UtilityTestClass.runAsUser('CSTApp23','CST Approver');
        testCStApp23.Available_Countries__c = 'AU';
        testCStApp23.Sales_Organisation__c = 'AT01';
        testCSTApp23.DelegatedApproverId = testCStApp3.Id;
        insert testCStApp23;
        
        
        testCSTApp23.DelegatedApproverId = testAdminUser.Id;
        testCSTApp3.DelegatedApproverId = testAdminUser.Id;
        
        storeuser.add(testCStApp23);
        storeuser.add(testCStApp3);
        
        update storeuser;  */
        
        
        ID geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        //EDGE_UtilityTestClass.createOrgSettings(); 
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        //run as MDM user and update Sales Rep user
        System.runAs(testAdminUser) 
        {
            //Create Pick up Option Records
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
            pickupOption.Name = 'GOLD[AU]';
            insert pickupOption;
            
            //create account with geography Australia
            Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            ownerAccount.Global_Channel__c = 'Off Trade';
            ownerAccount.Global_Sub_Channel__c ='Retailer';
            ownerAccount.Global_Segment__c = 'Discounter';
            ownerAccount.Global_Sub_Segment__c = 'Modern Discounter';
            ownerAccount.Person_Responsible__c = testAdminUser.id;
            ownerAccount.IsOwner__c = true;
            insert ownerAccount; 
            System.assert(ownerAccount != null,'ownerAccount inserted');
            
            Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            operator.IsOperator__c = true;
            operator.Person_Responsible__c = testAdminUser.id;
            //insert operator;   
            
            Account owner = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            owner.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            owner.IsOwner__c = true;
            owner.Person_Responsible__c = testAdminUser.id;
            insert owner;
            Test.startTest();
            //create outlet record 
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outletAccount.Global_Channel__c = 'Off Trade';
            outletAccount.Global_Sub_Channel__c ='Retailer';
            outletAccount.Global_Segment__c = 'Discounter';
            outletAccount.Global_Sub_Segment__c = 'Modern Discounter'; 
            outletAccount.Independent_of_Operator__c = false;
            outletAccount.Independent_of_Owner__c = false;
            //outletAccount.Operator__c = operator.Id;
            outletAccount.ParentId = owner.Id;
            insert outletAccount;                
            
            User testSalesManagerUser = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            insert testSalesManagerUser;
            //create Sales Rep user
            User runSalesRepUser = EDGE_UtilityTestClass.runAsUser('salesrepuser','Sales Representative'); 
            //runSalesRepUser.Available_Countries__c  = 'AUS';
            runSalesRepUser.ManagerId =  testSalesManagerUser.Id;  
            runSalesRepUser.Trax_User__c=true;
            runSalesRepUser.Calls_Per_Day__c = 1;
            insert runSalesRepUser;        
            // EDGE_UtilityClass.printGovLimits(88); 
            //check if any UserTerritory2Association record created. 
            List<UserTerritory2Association> utaList = [SELECT Id,UserId,Territory2Id FROM UserTerritory2Association WHERE UserId =: runSalesRepUser.id]; 
            Integer territoryListSize = utaList.size();           
            System.debug(loggingLevel.debug,'@@@size'+territoryListSize);
            //Test.startTest();
            
            //create mdm user
            User testMDMUser2 = EDGE_UtilityTestClass.runAsUser('testMDMUser2','Master Data Manager'); 
            testMDMUser2.Trax_User__c=true;     
            insert testMDMUser2;
            
            List<Territory_Hierarchy__c> insertTerr = new List<Territory_Hierarchy__c>();
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Business Unit');
           // insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            //insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            //insert terriHier;  
            
            insertTerr.add(terriHierBU);
            insertTerr.add(terriHierSA);
            insertTerr.add(terriHier);
            
            insert insertTerr;
            
            
            
            Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
            terr.Territory_Type__c = 'Sales';
            terr.Region__c = terriHier.Id;
            terr.Sales_Area__c = terriHierSA.Id;
            terr.Business_Unit__c = terriHierBU.Id;
            terr.Country__c = geographyId;
            insert terr; 
            // EDGE_UtilityClass.printGovLimits(155);
			Outlet_Territory__c outletTerr = new Outlet_Territory__c();
            outletTerr.Territory__c = terr.Id;
            outletTerr.Outlet__c = outletAccount.Id;
            insert outletTerr;
            
            
            //CST-764
        List<User> storeuser = new List<User>();
        List<User> insertStoreuser = new List<User>();
        
        
            
        User testCStApp = EDGE_UtilityTestClass.runAsUser('CSTApp','CST Approver');
        testCStApp.Available_Countries__c = 'AU';
        testCStApp.Sales_Organisation__c = 'AT01';
        //testCSTApp.DelegatedApproverId = testAdminUser.Id;
        //insert testCStApp;
        
        User testCStApp0 = EDGE_UtilityTestClass.runAsUser('CSTApp0','CST Approver');
        testCStApp0.Available_Countries__c = 'AU';
        testCStApp0.Sales_Organisation__c = 'AT01';
        testCSTApp0.DelegatedApproverId = testCStApp.Id;
        
        User testCStApp2 = EDGE_UtilityTestClass.runAsUser('CSTApp2','CST Approver');
        testCStApp2.Available_Countries__c = 'AU';
        testCStApp2.Sales_Organisation__c = 'AT01';
        testCSTApp2.DelegatedApproverId = testCStApp.Id;
        //insert testCStApp2;
        insertStoreuser.add(testCStApp2);
        insertStoreuser.add(testCStApp); 
        
        insert insertStoreuser;
            
        
        testCSTApp2.DelegatedApproverId = testCSTApp0.Id;
        testCSTApp.DelegatedApproverId = testCSTApp3.Id;
        
        storeuser.add(testCStApp2);
        storeuser.add(testCStApp);
        
        update storeuser;
            
        Test.stopTest();
            
            Territory_Hierarchy_member__c terrHierMem2 = new Territory_Hierarchy_member__c();
            terrHierMem2.Territory_Hierarchy__c = terriHier.Id;
            terrHierMem2.User__c= testSalesManagerUser.Id;
            terrHierMem2.Start_Date__c = system.today();
            terrHierMem2.End_Date__c = system.today().addDays(25);
            insert terrHierMem2;
            //Test.stopTest();
            
            runSalesRepUser.Calls_Per_Day__c = 2;
            update runSalesRepUser;
            
            //Test.stopTest();
        } 
    }
    
}