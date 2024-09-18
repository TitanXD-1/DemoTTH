/**********************************************************************
  Name: AccountContactRelationTrigger
=======================================================================
  Purpose: This is to handle AccountContactRelationTrigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Sagar Barman    20/03/2019      Initial Development
***********************************************************************/
trigger AccountContactRelationTrigger on AccountContactRelation(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new AccountContactRelationTriggerHandler());
}