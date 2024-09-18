/**********************************************************************
  Name: ContactTrigger
=======================================================================
  Purpose: This is to handle ContactTrigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Sandeep Sahoo 06/02/2019      Initial Development
***********************************************************************/
trigger ContactTrigger on Contact(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new ContactTriggerHandler());
}