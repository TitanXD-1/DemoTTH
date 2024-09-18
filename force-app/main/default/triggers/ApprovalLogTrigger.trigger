/**********************************************************************
Name: ApprovalLogTrigger
=======================================================================
Purpose: This is to handle ApprovalLogTrigger Events
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR          DATE              DETAIL
1.0         Manikandan.T   13/05/2022      Initial Development
***********************************************************************/
trigger ApprovalLogTrigger on ECM_Approval_Log__c (before insert, before update, after insert, after update) {
    
    
    TriggerDispatcher.run(new ECM_ApprovalLogTriggerHandler());    
    

    

}