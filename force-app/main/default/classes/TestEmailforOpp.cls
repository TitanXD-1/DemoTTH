public class TestEmailforOpp implements Database.Batchable<sObject>,Database.Stateful,Database.AllowsCallouts,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode = '';
    String languageName = '';
    Id marketBatchJobId;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        String queryString = '';       
            System.debug(LoggingLevel.Debug,'countryCode'+countryCode);
            queryString = 'select Id,Name,Opportunity_Template__c,AccountId,Account.name,Account.Country__c,Account.Country_Code__c from Opportunity where Opportunity_Template__c = null and Account.Country_Code__c =:countryCode'; 
            System.debug(LoggingLevel.Debug,'queryString'+queryString);
        	return Database.getQueryLocator(queryString);
    }
    //execute method
    public void execute(Database.BatchableContext bc, List<Opportunity> oppList){
        String countryCode = batchSetting.Country_Code__c;
        Id grpId;
        String queueName = countryCode + '_MDM';
        Id countryId = oppList[0].Account.Country__c;
        // Fetch Market Setting Record
        Market_setting__c marketSetting = [select id,name,Geography__r.name,Opportunity_Notification__c from Market_Setting__c where Geography__r.Code__c =:countryCode];
        List<String> membersEmailList = new List<String>();
        for(GroupMember grMembers: [Select Id,GroupId,Group.Name,UserOrGroupId,UserOrGroup.Name,UserOrGroup.Email from GroupMember where Group.Name =: queueName]){
            membersEmailList.add(grMembers.UserOrGroup.Email);
            grpId = grMembers.GroupId;   
        }
        if(marketSetting.Opportunity_Notification__c.contains('Email Notification')){
            // Email Flow
        Map<String, Object> params = new Map<String, Object>();
 		params.put('EmailIds', membersEmailList);
        //params.put('geographyId',countryId);
        Flow.Interview.EDGE_Opportunity_Without_Template_Email_Notification sendEmailFlow = new Flow.Interview.EDGE_Opportunity_Without_Template_Email_Notification(params);
            sendEmailFlow.start();
        }
        /*else if(marketSetting.Opportunity_Notification__c.contains('Bell Notification')){
            // Bell Flow
        } */
        
      /*  EmailTemplate emailTemplate = [Select Id,Name,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where DeveloperName = 'Opportunity_w_o_Opportunity_Template'];
        
        Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();    
        message.setTemplateID(emailTemplate.Id);
        message.setToAddresses(membersEmail);
        //message.setWhatId(oppList[0].Id);
        message.setTargetObjectId('003Fg00000Ixj6PIAR');
        Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {message};
        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
        
        if (results[0].success) 
        {
            System.debug(LoggingLevel.Debug,'The email was sent successfully.');
        } else {
            System.debug(LoggingLevel.Debug,'The email failed to send: ' +  results[0].errors[0].message);
        } */
        
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'TestEmailforOpp', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
           // EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
}