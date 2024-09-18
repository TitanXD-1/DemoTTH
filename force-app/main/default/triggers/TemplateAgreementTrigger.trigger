/**********************************************************************
Name: TemplateAgreementTrigger
=======================================================================
Purpose: This is to handle Template Agreement Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  	AUTHOR            		 DATE              DETAIL
1.0      Saurav Prasad            18/12/2020      Initial Development
***********************************************************************/
trigger TemplateAgreementTrigger on ECM_Template_Agreement__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    
    ECM_TemplateAgreementTriggerHandler handler = new ECM_TemplateAgreementTriggerHandler();
    
    /* After Insert */
    if(Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }
    /* After Update */
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }
}