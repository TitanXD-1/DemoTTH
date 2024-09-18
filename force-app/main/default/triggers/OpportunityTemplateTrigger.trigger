/**********************************************************************
  Name: OpportunityTemplateTrigger
=======================================================================
  Purpose: This is to handle Opportunity Template Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0      Sandeep Sahoo     16-Apr-2019      Initial Development
***********************************************************************/

trigger OpportunityTemplateTrigger on Opportunity_Template__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new OpportunityTemplateTriggerHandler());
}