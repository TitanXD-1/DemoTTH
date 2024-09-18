/**********************************************************************
  Name: PersonalInformationTrigger
=======================================================================
  Purpose: This is to handle Personal Information Trigger Events
=======================================================================
    History                                                            
    -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  1.0       Shahbaz Khan      15/02/2020     Initial Development
***********************************************************************/
trigger PersonalInformationTrigger on Personal_Information__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
		TriggerDispatcher.run(new PersonalInformationTriggerHandler());
}