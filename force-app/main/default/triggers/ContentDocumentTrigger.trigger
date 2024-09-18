/**********************************************************************
Name: ContentDocumentTrigger
=======================================================================
Purpose: This is to handle ContentDocument Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Monalisa Halder    18/03/2019        ES20-198       
***********************************************************************/

trigger ContentDocumentTrigger on ContentDocument (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ContentDocumentTriggerHandler());
}