/**********************************************************************
Name: ECM_SharingofDepletionrecords_Batch
=======================================================================
Purpose: This Class is used to insert records to Accruals and AccrualItem objects through batch.
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0       Manikandan.T          14/01/2021        Initial Development


***********************************************************************/ 


    global class ECM_SharingofDepletionrecords_Batch implements Database.Batchable<sObject> {
    
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        
        return Database.getQueryLocator([
            select Id,Name,ECM_Geography__c from depletions__c   
        ]);
    }
    
    global void execute(Database.BatchableContext BC, List<Depletions__c>scope){
    

        EDGE_SharingUtil.validateCreatePermission(scope, 'ECM_Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(scope, 'ECM_Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(scope, 'ECM_Geography__c', 'Down', 'Edit');
        
    }
    
    global void finish(Database.BatchableContext BC){
        
    }

}