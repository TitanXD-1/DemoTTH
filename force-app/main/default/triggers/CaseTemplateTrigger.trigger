/**
* @Name: CaseTemplateTrigger

* @Purpose: This is to handle CaseTemplateTrigger Trigger Events

* @History                                                            
                                                          
* @VERSION      AUTHOR             DATE              DETAIL
*  1.0          Anand Uppalapati   10/01/2022        ES20-11891    
**/

trigger CaseTemplateTrigger on Case_Template__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
		TriggerDispatcher.run(new CaseTemplateTriggerHandler());
}