/*
 * @class: PNR_CorrDocumentFailedRecoveryBatch
 * @description: When CD record status is 500,502, 404, 401, we are running batch class to the record again to SAP.
 * This class is written for PION-1645 change.
 * */
public class PNR_CorrDocumentFailedRecoveryBatch  implements Database.Batchable<sObject>, Database.AllowsCallouts {
	
    public Database.QueryLocator start(Database.BatchableContext BC){
      Integer minCount = Integer.ValueOf(Label.PNR_CDBatch_MinCount);
      Integer maxCount = Integer.ValueOf(Label.PNR_CDBatch_MaxCount);
        //getting CD records for status 500, 502, 404, 401
      return Database.getQueryLocator([select id, PNR_Order_Response_Status_Code__c, PNR_Re_Trial_Count__c from Correction_Document__c where 
                                       PNR_Order_Response_Status_Code__c !=NULL AND PNR_Order_Response_Status_Code__c !=200 AND (PNR_Re_Trial_Count__c  >= :minCount AND PNR_Re_Trial_Count__c < :maxCount) ]);
   }

   public void execute(Database.BatchableContext BC, List<Correction_Document__c> docList){
       List<Correction_Document__c> corrDocList = new List<Correction_Document__c>();
       set<id> corrIds = new set<id>();
       for(Correction_Document__c cd : docList){
           corrIds.add(cd.Id);
       }
       //sending CD id to handler class. invoking handler class
       PNR_CorrDocuTriggerHelper.getDocLineItems(corrIds);
   }

   public void finish(Database.BatchableContext BC){
   }
}