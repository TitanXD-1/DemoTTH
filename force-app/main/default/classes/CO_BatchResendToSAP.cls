/*
 * @class: CO_BatchResendToSAP
 * @description: When CR record status is 500,502, 404, 401, we are running batch class to send the record again to SAP.
 * This class is written for CONS-272 change.
 * @History                                                                                                                       
 * @VERSION      AUTHOR             DATE              DETAIL
   1.0           Cons Dev Team      11-25-2022        Initial Development
 * */
public class CO_BatchResendToSAP  implements Database.Batchable<sObject>, Database.AllowsCallouts {
	Integer retryCount = 24;
    public Database.QueryLocator start(Database.BatchableContext bc){
      //getting CR records for status 500, 502, 404, 401
      return Database.getQueryLocator([select id,Name,Status_Code__c, CO_Response_received_from_SAP__c from Customer_Request__c where CO_Status__c='SENT TO SAP' AND
                                       Status_Code__c !=NULL AND Status_Code__c !=200 AND CO_Response_received_from_SAP__c  < :retryCount ]);
   }

   public void execute(Database.BatchableContext bc, List<Customer_Request__c> crList){
       List<id> crIds = new List<id>();
       for(Customer_Request__c cr : crList){
           crIds.add(cr.Id);
       }
       CO_SendToSAP.sendDataToSAP(crIds);
   }

   public void finish(Database.BatchableContext bc){
       AsyncApexJob job = [SELECT Id, Status, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email FROM AsyncApexJob WHERE Id = :bc.getJobId()]; 
       System.debug(System.LoggingLevel.INFO, '>>>> finish CO_BatchResendToSAP - ' + job.Status);
       if(job.Status == 'Failed' || job.Status == 'Aborted'){
           EventsLog_Utility.createBatchLog('CO_BatchResendToSAP', 'finish', 'Batch job failure', 0, String.valueOf(job.Status), 'Job ID -'+String.valueOf(job.Id), 'Customer Onboarding SAP <> SF');
       }
       
   }
}