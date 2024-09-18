/**
*@ Description Name: EDGE_Send_Market_Cycle_Alert

*@ History :                                                            
1.0    Mayukh S Roy    11/01/2021      US-2429747
**/

global class EDGE_Send_Market_Cycle_Alert implements Database.Batchable<sObject> {
    global Database.QueryLocator start(Database.BatchableContext bc) {
        Date current = Date.today();
        Boolean Active = True;
        String queryString = 'Select Id,Active__c, Geography__c,Geography__r.Name,Geography__r.MDM_Queue__c,End_Date__c, Name,Start_Date__c from Market_Cycle__c where Active__c =: Active';
        return Database.getQueryLocator(queryString);
    }
  
    global void execute(Database.BatchableContext bc, List<Market_Cycle__c> cycles) {
        EDGE_Send_Market_Cycle_AlertHelper.sendEmail(cycles);
    }
  
    global void finish(Database.BatchableContext bc) {
    }
}