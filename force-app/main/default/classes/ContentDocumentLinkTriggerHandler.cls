/**

* @description :  ContentDocumentLinkTriggerHandler

* @purpose : Trigger Handler Class for ContentDocumentLinkTrigger

* @history :

* Version    Developer              Date         User Story	  

*  1.1      Chandrakanth Suram    18/02/2021      ECM-3950 
*  1.2      Monalisa Halder  	  18/03/2019      ES20-198  
*  1.3      Preyanka Ghosh        01/04/2019      ES20-676
*  1.4      Aparajita			  10/05/2021   	  ES20-9665
*  1.5	    Monalisa Halder	      27/07/2021	  ES20-9662
*  1.6 		Rajarshi Lahiri		  06/01/2023	  ES20-13639
*  1.7		Saurav Prasad		  05/09/2023	  145098 - Optimize the ContentDocumentTrigger_SFDC_Technical Debt 
*/

public with sharing class ContentDocumentLinkTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ContentDocumentLinkTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {

        EDGE_ContentDocumentLinkTriggerHelper.checkFeedItem(newItems);
        if(triggerDisabled==false){//ES20-13639 For Feed Items we do not require to invoke these methods. This is to avoid governor limit issue
            EDGE_ContentDocumentLinkTriggerHelper.checkRecordTypePerObject(newItems);
            EDGE_ContentDocumentLinkTriggerHelper.validateContractSignedDate(newItems);
            //EDGE_ContentDocumentLinkTriggerHelper.checkDocumentExtension(newItems);
            EDGE_ContentDocumentLinkTriggerHelper.checkNoOfFile(newItems);
            EDGE_ContentDocumentLinkTriggerHelper.changeVisiblityPublic(newItems);
            EDGE_ContentDocumentLinkTriggerHelper.readOnlyAttach(newItems);
        }
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_ContentDocumentLinkTriggerHelper.readOnlyAttach(newItems.values());
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        EDGE_ContentDocumentLinkTriggerHelper.readOnlyAttach(oldItems.values());
        EDGE_ContentDocumentLinkTriggerHelper.uncheckPsInvoiceAttachment(oldItems.values()); //ECM-6787
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_ContentDocumentLinkTriggerHelper.updateContentVersionId(newItems);
        if(triggerDisabled==false){//ES20-13639 For Feed Items we do not require to invoke these methods. This is to avoid governor limit issue
            //ECM_ContentDocumentLinkTriggerHelper.recordTypeUpdate(newItems);//Commented by Saurav(ECM-4992)
            EDGE_ContentDocumentLinkTriggerHelper.recordTypeUpdate(newItems);//Added by Saurav(ECM-4992)
            EDGE_ContentDocumentLinkTriggerHelper.updatePaymentFields(newItems);//changes by Pravalika(ECM-4429)
            //145098 - commented 
            /*
            EDGE_ContentDocumentLinkTriggerHelper.insertCaseAttachmentToFeed(newItems); //changes by Aparajita(ES20-9665)
            EDGE_ContentDocumentLinkTriggerHelper.insertCaseAttachmentToSNowTicket(newItems); // ES20-9662
            */
            //145098
            EDGE_ContentDocumentLinkTriggerHelper.processCaseAttachments(newItems);//changes by Aparajita(ES20-9665) &  ES20-9662
            
            EDGE_ContentDocumentLinkTriggerHelper.onAddingContractAttachment(newItems); // ECM-5900, 5901
        }
        //Customer Concerns
        List<ContentDocumentLink> relevantEvidences = new List<ContentDocumentLink>();
        for(SObject o : newItems.values()){
            ContentDocumentLink cdl = (ContentDocumentLink)o;
            //String objectName = CC_ContentDocumentLinkTriggerHelper.retrieveObjectNameFromId();
            //145098
            if(cdl.LinkedEntityId.getSObjectType() == CC_Customer_Concern__c.sObjectType){
                relevantEvidences.add(cdl);
            }
        }
        if(relevantEvidences.size()>0){
            CC_ContentDocumentLinkTriggerHelper.cloneEvidences(relevantEvidences);
        }
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}