/*
* Class Name: EDGE_OpportunitiesWithoutTemplateBatch
* Test Class: EDGE_OpportunitiesWOTemplateBatchTest
* Brief Description: This class is used to send bell notification & email notification to the MDMs if there is any Opportunities without template
* Created Date: 
* History: 
* VERSION			AUTHOR				DATE				DETAIL
*  1.0              Suvendu Roy         20/08/2024          155301 - GB Opportunity Scoring:  Salesforce Bell Notification to MDMs on Opportunities without Templates
*  2.0              Sudipta Nandy       23/08/2024          155541 - GB Opportunity Scoring:  Salesforce Email Notification to MDMs on Opportunities without Templates
*/

public class EDGE_OpportunitiesWithoutTemplateBatch implements Database.Batchable<SObject>,Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    Market_Batch_Setting__mdt batchSetting; 
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    String opportunityNotification;
    
  /**
    * @description : Interface Method
    * @param : batchSetting
    */
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    /**
    * @description : start - start method for the Batch
    * @return : Database.QueryLocator
    * @param : Database.BatchableContext
    */
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        Market_setting__c marketSetting = [SELECT Id,Opportunity_Notification__c,Language__c FROM Market_Setting__c WHERE Geography__r.Code__c =:countryCode];
        opportunityNotification = marketSetting.Opportunity_Notification__c;  
        String strQuery= '';
        if( opportunityNotification != null){
            strQuery = 'SELECT Id, Name, AccountId, StageName, Type, Source__c FROM Opportunity WHERE Opportunity_Template__c = null '+ 
                'AND StageName IN (\'Open\', \'Pending\') AND Type IN (\'Cycle Brief\', \'MAS\', \'MPA\', \'WPA\', \'NPA\') '+
                'AND Source__c != null AND Account.Country_Code__c =:countryCode LIMIT 1';
        }else{
            strQuery = 'SELECT Id FROM Opportunity LIMIT 0';
        }
        return Database.getQueryLocator(strQuery);
    }
    
    /**
    * @description : execute - execute method for the Batch
    * @return : void
    * @param : Database.BatchableContext, List<Contract> 
    */
    public void execute(Database.BatchableContext bc, List<Opportunity> scope){
        
        String tempStr = countryCode+'_'+'MDM';
        Set<Id> userIdList = new Set<Id>();
        List<String> emailList = new List<String>();
        
        for(GroupMember member : [SELECT Group.Name,UserOrGroupId, UserOrGroup.Email FROM GroupMember WHERE Group.name =:tempStr AND Group.type='Queue' ]){   
            userIdList.add(member.UserOrGroupId);
            emailList.add(member.UserOrGroup.Email);
        }
        //Calling flow for bell notification
        if(!userIdList.isEmpty() && opportunityNotification.contains('Bell Notification')){
            Map<String, Object> params = new Map<String, Object>();
            params.put('recipientList',userIdList);
            //create instance of flow
            Flow.Interview.EDGE_Opportunity_Without_Template_Notification stage = new Flow.Interview.EDGE_Opportunity_Without_Template_Notification(params);
            stage.start();
        }
        // Sent Email Notification to MDM Queue Member
        if(opportunityNotification.contains('Email Notification')){
            EDGE_OppWithoutOppTempEmailNotification.sendEmail(countryCode);
        }
    }
    
    /**
    * @description : finish - Finish method for the Batch
    * @return : void
    * @param : Database.BatchableContext - Batchable Context
    */  
    public void finish(Database.BatchableContext bc){
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        String reducedExceptionMsg = '';
        hasError = !hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed';
        if(hasError){ //Update Batch Job Status
            reducedExceptionMsg = (exceptionMsg != null  && exceptionMsg.length() >= 32768)? exceptionMsg.substring(0, 32768): exceptionMsg; 
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OpportunitiesWithoutTemplateBatch', reducedExceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }   
}