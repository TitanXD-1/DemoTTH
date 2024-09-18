/**********************************************************************
  Name: DiageoContactTrigger
=======================================================================
  Purpose: This is to handle DiageoContactTrigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Tanmoy Bardhan     04/07/2019      Initial Development
***********************************************************************/
trigger DiageoContactTrigger  on PNR_Diageo_Contact__c (before insert, before update) {
    TriggerDispatcher.run(new PNR_DiageoContactTriggerHandler());
}