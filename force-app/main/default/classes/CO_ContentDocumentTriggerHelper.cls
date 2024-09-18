/*
* @Description: CO_ContentDocumentTriggerHelper
* @Purpose: Helper Class for CO ContentDocument functionalities
* @History:
* @Version		Developer		 Date			User-Story
* 	1.0			Aparajita		20/04/2023		CONS-528
*/
public with sharing class CO_ContentDocumentTriggerHelper {
    
    /*
* @Method: restrictFileDeletion -> CONS-528
* @Purpose: Restricts deletion of files on the Customer Request record for all users
* @Param: Map<Id, SObject> oldItems
*/
    public static void restrictFileDeletion(Map<Id, SObject> oldItems){
        Map<Id, ContentDocument> conDocMap = (Map<Id, ContentDocument>)oldItems;
        for(ContentDocumentLink cdl : [Select Id, LinkedEntityId,ContentDocumentId FROM ContentDocumentLink 
                                       WHERE ContentDocumentId IN :conDocMap.keySet() WITH SECURITY_ENFORCED])
        {
            if(Schema.sObjectType.Customer_Request__c.isAccessible() && cdl.LinkedEntityId != null && cdl.LinkedEntityId.getSObjectType() == Customer_Request__c.sObjectType){       
                conDocMap.get(cdl.ContentDocumentId).addError('Files cannot be deleted');  
            }
        }
    }
}