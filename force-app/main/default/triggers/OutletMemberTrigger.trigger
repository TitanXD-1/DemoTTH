/**********************************************************************
  Name: OutletMemberTrigger
=======================================================================
  Purpose: This is to handle Territory Member Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                 DATE              DETAIL
    1.0 -    Anuja Chattopadhyay    04/09/2019      Initial Development
***********************************************************************/

trigger OutletMemberTrigger on Outlet_Member__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new OutletMemberTriggerHandler());
}