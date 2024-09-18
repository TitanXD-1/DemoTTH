/**********************************************************************
Name: ExtraApprovalTrigger
=======================================================================
Purpose: This is to handle Extra Approval Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  	AUTHOR            		 DATE              DETAIL
1.0      Saurav Prasad            07/12/2020      Initial Development
***********************************************************************/
trigger ExtraApprovalTrigger on ECM_Extra_Approval__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    ECM_ExtraApprovalTriggerHandler handler = new ECM_ExtraApprovalTriggerHandler();
    
    /* After Insert */
    if(Trigger.isInsert && Trigger.isAfter){
        handler.onAfterInsert(Trigger.new, Trigger.newMap);
    }
    /* After Update */
    if(Trigger.isUpdate && Trigger.isAfter){
        handler.onAfterUpdate(Trigger.old, Trigger.oldMap, Trigger.new, Trigger.newMap);
    }
    
}