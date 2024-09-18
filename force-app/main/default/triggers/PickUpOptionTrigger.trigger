/**********************************************************************
  Name: PickUpOptionTrigger
=======================================================================
  Purpose: This is to handle Pick Up Option Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            		DATE              DETAIL
    1.0 -    Saurav Paul            25/03/2019      Initial Development
***********************************************************************/
trigger PickUpOptionTrigger on Pick_Up_Options__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new PickUpOptionTriggerHandler());
}