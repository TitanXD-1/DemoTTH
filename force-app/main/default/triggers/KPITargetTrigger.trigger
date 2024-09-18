/**********************************************************************
    Name: KPITargetTrigger
=======================================================================
    Purpose: This is to handle KPI Target Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Dipanjan Das      15/05/2019        Initial Development
***********************************************************************/

trigger KPITargetTrigger on KPIs_Target__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new KPITargetTriggerHandler());
}