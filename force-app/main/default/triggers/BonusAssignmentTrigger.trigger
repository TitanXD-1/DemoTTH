/**********************************************************************
  Name: BonusAssignmentTrigger
=======================================================================
  Purpose: This is to handle Bonus Assignments Trigger Events
=======================================================================
    History                                                            
    -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  1.0       Vikas Anand      08-Jan-2020      Initial Development
***********************************************************************/
trigger BonusAssignmentTrigger on Bonus_Assignment__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new BonusAssignmentTriggerHandler());
}