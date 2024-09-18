/**********************************************************************
Name: QualityCaseConfigurationTrigger
=======================================================================
Purpose: This is to handle Quality Case Configuration Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                    DATE              DETAIL
1.0 -    Sudipta Nandi            26/07/2021      Initial Development
***********************************************************************/
trigger QualityCaseConfigurationTrigger on Quality_Case_Configuration__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
	TriggerDispatcher.run(new CaseConfigurationTriggerHandler());
}