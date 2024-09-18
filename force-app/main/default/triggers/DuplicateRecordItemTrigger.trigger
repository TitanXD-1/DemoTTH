/**********************************************************************
  Name: DuplicateRecordItem 
=======================================================================
  Purpose: This is to handle DuplicateRecordItem Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION      AUTHOR            DATE              DETAIL
       1.0 -     Saurav Paul       09/03/2021      Initial Development
***********************************************************************/

trigger DuplicateRecordItemTrigger on DuplicateRecordItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new DuplicateRecordItemTriggerHandler());
}