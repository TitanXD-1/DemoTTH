/**********************************************************************
Name: CC_ApproveOrRejectConcernController
=======================================================================
Purpose: Server side controller for Approving or Rejecting Concerns
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S		06/04/2021		Initial Development
***********************************************************************/
public class CC_ApproveOrRejectConcernController {
    
    @AuraEnabled
    public static String checkStatus(Id recordId){
        String status = '';
        Case c = [SELECT Id, Status FROM Case WHERE Id =: recordId];
        if(c.Status == 'Approved' || c.Status == 'Rejected')
            status = c.Status;
        return status;
    }
    
    @AuraEnabled
    public static void approveOrRejectConcern(Id recordId, Boolean isRejected, String rejectionComments){
        Case c = [SELECT Id, Status, CC_Comments__c FROM Case WHERE Id =: recordId];
        if(isRejected){
            c.Status = 'Rejected';
            c.CC_Comments__c = rejectionComments;
        }else{
            c.Status = 'Approved';
        }
        update c;
    }
}