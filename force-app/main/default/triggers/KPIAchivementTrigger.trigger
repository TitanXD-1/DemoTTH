/**********************************************************************
  Name: KPIAchivementTrigger
=======================================================================
  Purpose: This is to handle KPI Achivement Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Manikant           29-Oct-2019      Initial Development
***********************************************************************/

trigger KPIAchivementTrigger on KPI_Achivement__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new KPIAchivementTriggerHandler());
}