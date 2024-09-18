/**********************************************************************
  Name: GTProjectTrigger
=======================================================================
  Purpose: This is to handle GT Project Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                 DATE              DETAIL
    1.0 -    Tanishq         	18/07/2023      Initial Development
***********************************************************************/
trigger GTProjectTrigger on GT_Project__c (before insert,before update,after insert, after update,before delete,after delete,after undelete) {
	TriggerDispatcher.run(new GT_ProjectTriggerHandler());
}