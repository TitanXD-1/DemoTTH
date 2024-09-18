/*
 * @class: PNR_AttachmentTriggerHelper
 * @description: This is helper class for EmailMessage object
 *
 * */
public class PNR_EmailMessageTriggerHelper {
    
    public static void afterInsert(Map<Id, SObject> newItems){
        List<EmailMessage> newRecItems = (list<EmailMessage>)newItems.values();
        List<EmailMessage> msgToProcess = new List<EmailMessage>();
        
        for(EmailMessage msg : newRecItems)
        {
            //Checking if the email message is associated with any Case
            if(msg.ParentId != null){
                msgToProcess.add(msg);
            }
        }
        if(msgToProcess.size() > 0){
            PNR_CreateContactFromEmailMessage.createContact(msgToProcess);
        }
    }
    
    /*
     * @description: this method is used to prevent the user from deleting email message record, when the subject is approved and approval request
     * @author: Sai Kiran Sagaram
     * @return: void
     * @signature: List<SObject> oldItems
     * */
    public static void beforeDelete(List<SObject> oldItems){
        //variable declaration
        list<EmailMessage> emOldList = (list<EmailMessage>)oldItems;//assigning records to list collection
        set<Id> caseIdSet = new set<Id>();
        Set<String> statusSet = new Set<String>{'Externally Approved', 'Externally Approved With Change', 'Sent for External Approval' , 'Awaiting Billing', 'Externally Rejected', 'Closed'};
            //for loop starts; iterating through email message record collection
            for(EmailMessage em : emOldList){
                if((em.Subject.contains('Approval request') || em.Subject.contains('Approved') || em.Subject.contains('Rejected') || em.Subject.contains('Change')) && em.ParentId != null && String.valueOf(em.ParentId).startsWith('500')){
                    caseIdSet.add(em.ParentId);
                }
            }
        //forming condition
        Map<Id,Case> caseMap = new Map<Id,Case>([select id,Status from case where Id IN: caseIdSet and RecordType.DeveloperName ='Direct_Disputes' and Status IN: statusSet]);
        //for loop starts
        //Iterating through list collection and preventing user from deleting email message; displaying error message.
        for(EmailMessage em : emOldList){
            if((em.Subject.contains('Approval request') || em.Subject.contains('Approved') || em.Subject.contains('Rejected') || em.Subject.contains('Change')) && em.ParentId != null && String.valueOf(em.ParentId).startsWith('500') && caseMap.containsKey(String.valueOf(em.ParentId))){
                em.addError('You cannot delete an Approval related Email Message.');
            }
        }
    }
}