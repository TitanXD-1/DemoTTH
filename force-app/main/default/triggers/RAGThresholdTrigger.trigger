/**********************************************************************
Name: RAGThresholdTrigger
=======================================================================
Purpose: This is to handle KPI_RAG_Threshold__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Preyanka Ghosh    29/04/2019        ES20-1034       
***********************************************************************/

trigger RAGThresholdTrigger on KPI_RAG_Threshold__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new RAGThresholdTriggerHandler());
}