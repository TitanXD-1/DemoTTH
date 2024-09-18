/********************************************************************************************
Class Name: EDGE_NewsFeedStatusUpdateBatch

Author          Version    Date           Detail
Sandip Ghosh    V1.0       17/03/2020     [ES20-7585]This Edge365 Newsfeed batch is used to 
activate the Newsfeeds
*********************************************************************************************/

public class EDGE_NewsFeedStatusUpdateBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String newsFeedRecordTypeId = Notification__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Edge365 Newsfeed').getRecordTypeId();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
  
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        String countryCode = batchSetting.Country_Code__c;        
        String queryString = 'SELECT Id, Status__c, Content_Document_Id__c, Content_Version_Id__c,'+
            ' Country__c, Start_Date__c, End_Date__c, Image_Document_Id__c, Image_Version_Id__c,URL__c'+
            ' from Notification__c where recordTypeId = :newsFeedRecordTypeId AND Status__c <> \'Expired\' AND Country__r.Code__c = \'' + countryCode +'\'';
        System.debug('queryString = '+ queryString);
        return Database.getQueryLocator(queryString);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<sObject> scope){     
    	
        List<Notification__c> notificationListToUpdate = new List<Notification__c>();
        System.debug('scope  = '+ scope);
        System.debug('scope size  = '+ scope.size());
        
        try{
            if(scope != null && scope.size() > 0){
                
                Date todaysDate = Date.today();
                List<Notification__c> notificationList = (List<Notification__c>)scope;
                
                for(Notification__c notificationRec : notificationList){
                    
                    Boolean isImagePresent = (notificationRec.Image_Document_Id__c != null && notificationRec.Image_Version_Id__c != null);
                    Boolean isPDFPresent = (notificationRec.Content_Document_Id__c != null && notificationRec.Content_Version_Id__c != null);
                    
                    System.debug('notificationRec = '+ notificationRec);
                    System.debug('isImagePresent = '+ isImagePresent);
                    System.debug('isPDFPresent = '+ isPDFPresent);
                    System.debug('notificationRec.URL__c = '+ notificationRec.URL__c);
                    System.debug('if expression1 = '+ (isImagePresent && (notificationRec.URL__c != null || isPDFPresent)));
                    
                    if(notificationRec.Start_Date__c != null && notificationRec.End_Date__c != null &&
                       (isImagePresent && (notificationRec.URL__c != null || isPDFPresent))){
                           if( !(isImagePresent && notificationRec.URL__c != null && isPDFPresent) && notificationRec.Start_Date__c <= todaysDate && todaysDate <= notificationRec.End_Date__c){
                               System.debug('hello1 =');
                               Notification__c notificationRecToUpdate = new Notification__c(Id = notificationRec.Id);
                               notificationRecToUpdate.Status__c = 'Active';
                               notificationListToUpdate.add(notificationRecToUpdate);                               
                           }else if(notificationRec.End_Date__c != null && todaysDate > notificationRec.End_Date__c){
                               System.debug('hello2 =');
                               Notification__c notificationRecToUpdate = new Notification__c(Id = notificationRec.Id);
                               notificationRecToUpdate.Status__c = 'Expired';
                               notificationListToUpdate.add(notificationRecToUpdate);
                           }
                       }
                }
                
                System.debug('notificationListToUpdate = '+ notificationListToUpdate);
                if(notificationListToUpdate.size() > 0){                  
                    Database.update(notificationListToUpdate,false);
                }
            }            
        }catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            hasError = true;
        }
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OrderStatusUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
    }
}