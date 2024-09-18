/*
Name: EDGE_ApprovalRequestCommentsController

History                                                            

VERSION   AUTHOR            DATE              DETAIL
1.0       Mayukh S Roy     29/06/2023         298232 
*/

public with sharing class EDGE_ApprovalRequestCommentsController {

    // ID of the record whose most recent approval process comments to retrieve
    public ID targetObjectId { get; set; }
    
    // The most recent approval process comments
    public String comments {
        get {
            if (comments == null) {
            	ProcessInstanceStep lastStep = getLastApprovalStep();
            	comments = ( lastStep != null ) ? lastStep.comments : '';
            }
            return comments;
        }
        private set;
    }
    
    // Queries the most recent approval process step for the target record
    private ProcessInstanceStep getLastApprovalStep() {
        List<ProcessInstanceStep> steps = new List<ProcessInstanceStep>([SELECT Comments FROM ProcessInstanceStep WHERE ProcessInstance.TargetObjectId = :targetObjectId ORDER BY SystemModStamp DESC LIMIT 1]);
        return ( steps.size() > 0 ) ? steps[0] : null;
    }
    
}