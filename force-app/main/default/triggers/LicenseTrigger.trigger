/**********************************************************************
    Name: LicenseTrigger
=======================================================================
    Purpose: This is to handle License Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 -    Name           23/04/2019      Initial Development
***********************************************************************/
trigger LicenseTrigger on License__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new LicenseTriggerHandler());
}