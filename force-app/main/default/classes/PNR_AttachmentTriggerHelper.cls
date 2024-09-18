/*
 * @class: PNR_AttachmentTriggerHelper
 * @description: This class stops deletion of attachments, for direct dispute cases,
 * when the status is 'Externally Approved', 'Externally Approved With Change', 'Awaiting Billing', 'Closed'
 * @author: Sai Kiran Sagaram
 * This class is written for PION-1715 change.
 * */
public class PNR_AttachmentTriggerHelper {
    //getting records for before Delete
    public static void beforeDelete(List<SObject> oldItems){
        list<Attachment> attOldList = (list<Attachment>)oldItems;//assigning oldItems to list collection
        set<Id> caseIdSet = new set<Id>();
        String attachmentName;
        //creation of set for status condition
        Set<String> statusSet = new Set<String>{'Externally Approved', 'Externally Approved With Change', 'Awaiting Billing', 'Closed', 'Sent for External Approval', 'Externally Rejected'};
            //iterating records to get caseId
            for(Attachment att : attOldList){
                if(att.ParentId != null && String.valueOf(att.ParentId).startsWith('500')){
                    caseIdSet.add(att.ParentId);
                    attachmentName = att.Name;
                }
            }//for loop ends
        //forming condition
        Map<Id,Case> caseMap = new Map<Id,Case>([select id,Status from case where Id IN: caseIdSet and RecordType.DeveloperName ='Direct_Disputes' and Status IN: statusSet]);
        //displaying error, preventing user to delete the attachment
        for(Attachment att : attOldList){
            if(att.ParentId != null && String.valueOf(att.ParentId).startsWith('500') && caseMap.containsKey(String.valueOf(att.ParentId)) && att.Name.contains('Approval request')){
                att.addError('You cannot delete any attachment if it is either approved or rejected');
            }
        }
    }
}