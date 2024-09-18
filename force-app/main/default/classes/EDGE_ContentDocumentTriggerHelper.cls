/*
*Name: EDGE_ContentDocumentTriggerHelper
*
*History                                                            
*                                                            
*VERSION			AUTHOR				DATE				DETAIL
*1.0			Monalisa Halder		18/03/2019			ES20-198
*2.0			Preyanka Ghosh		22/03/2019			Add the logic to update Promotion record with content data
*3.0			Preyanka Ghosh		02/04/2019			ES20-676
*4.0			Preyanka Ghosh		24/04/2019			As per design proposed, refactor the code
*5.0			Pratik Somani		10/03/2022			ECM-6787 - Logic to uncheck Invoice and Evidence attachment_Payment Summary Attachment_SFDC
*6.0			Saurav Prasad		31/08/2023			145098 - Optimize the ContentDocumentTrigger_SFDC_Technical Debt
*/
public with sharing class EDGE_ContentDocumentTriggerHelper {
    
    private static final String PAYMENT_SUMMARY_RECORD_TYPE = 'ECM_Payments';
    
    /*
     * Method  : updateContentVersionId
     * Purpose : This methods used to update Content Document Id and Content Version Id 
     * on Promotion and Account 
     */
    public static void updateContentVersionId(Map<Id,SObject> newItems) {
        Map<Id,ContentDocumentLink> mapContentDoc = new Map<Id,ContentDocumentLink>();
        Set<Id> setContentDoc = new Set<Id>();
        String contentWorkSpaceName;
        Id linkedEntityId;
        Map<Id,List<Id>> mapLinkedEntityId = new Map<Id,List<Id>>();
        
        try{
            if(newItems != null && newItems.size()>0){
                setContentDoc = newItems.keySet();
                Map<String, File_Setting__mdt> mapObjectFileSetting = getFileSetting();
                //To get the Record Type Name need to do the query
                for(ContentDocumentLink objConDocLink :[Select Id, LinkedEntityId, ContentDocumentId,ContentDocument.LatestPublishedVersionId, 
                                                        ContentDocument.Title, ContentDocument.FileExtension, ContentDocument.LatestPublishedVersion.RecordTypeId, 
                                                        ContentDocument.LatestPublishedVersion.RecordType.Name, ContentDocument.LatestPublishedVersion.RecordType.DeveloperName, ContentDocument.LatestPublishedVersion.Content_Type__c
                                                        FROM ContentDocumentLink 
                                                        WHERE ContentDocumentId IN :setContentDoc]
                   ){
                       //Others Record Type and Outlet-Survey response RT does not required any update  
                       //Add Pioneer Record Type.PION-955
                       if(objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name != 'Others' && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name != 'Outlet-Survey Response'  && objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c != 'Other'
                          && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name != 'Direct Customer' ){
                              String sobjectName = (objConDocLink.LinkedEntityId).getSObjectType().getDescribe().getName();
                              if(mapObjectFileSetting.containskey(sobjectName) && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name == mapObjectFileSetting.get(sobjectName).MasterLabel && 
                                 (objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name == 'Account' && (objConDocLink.ContentDocument.Title).contains('OutletImage_') ||
                                  ((objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name == 'Product' && (objConDocLink.ContentDocument.LatestPublishedVersion.Content_Type__c).contains('Product Image'))) ||
                                  (objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name != 'Account' && objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name != 'Product'))
                                ){
                                    mapContentDoc.put(objConDocLink.ContentDocumentId, objConDocLink); 
                                    contentWorkSpaceName = objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.Name;
                                    if(mapLinkedEntityId.containsKey(objConDocLink.ContentDocumentId)){
                                        mapLinkedEntityId.get(objConDocLink.ContentDocumentId).add(objConDocLink.LinkedEntityId);
                                    } else {
                                        mapLinkedEntityId.put(objConDocLink.ContentDocumentId, new List<Id> {objConDocLink.LinkedEntityId});
                                    }
                                    //linkedEntityId = objConDocLink.LinkedEntityId;
                                }                        
                          }                    
                   }
                System.debug(LoggingLevel.Debug,'mapLinkedEntityId = '+ mapLinkedEntityId);
                if((String.isNotBlank(linkedEntityId) || (mapLinkedEntityId != null && mapLinkedEntityId.size()>0)) && String.isNotBlank(contentWorkSpaceName)){
                    EDGE_ContentDocumentLinkTriggerHelper.upsertSobjectData(mapContentDoc, contentWorkSpaceName, mapLinkedEntityId, false, false);
                }                
            }
        } catch(Exception excption){
            System.debug(LoggingLevel.Debug,'Exception updateContentVersionId in CDT::::'+excption.getLineNumber()+'::'+excption.getMessage()+excption.getCause()); 
        }
        
    }
    
    /*
     * Method  : checkDocExtforUpdate
     * Purpose : This methods used to check that there should be one pdf per 
     * promotion
     */ 
    public static void checkDocExtforUpdate(Map<Id, SObject> newItems){ 
        
        Map<Id,String> conDocMap = new Map<Id,String>();
        List<String> acceptedExtensions;
        System.debug(LoggingLevel.Debug,'newItems::'+newItems);
        if(newItems != null && newItems.size()>0){
            Map<String, File_Setting__mdt> mapObjectFileSetting = new Map<String, File_Setting__mdt>();
            //145098
            for(File_Setting__mdt objFile : File_Setting__mdt.getAll().values()){
                mapObjectFileSetting.put(objFile.MasterLabel, objFile);
            }            
            Map<Id, ContentDocument> mapContentDoc = (Map<Id, ContentDocument>)newItems;
            for(ContentVersion objConVer : [SELECT Id, ContentDocumentId, RecordTypeId, RecordType.Name, RecordType.DeveloperName 
                                            FROM ContentVersion 
                                            WHERE ContentDocumentId IN :mapContentDoc.keySet()
                                           ]
               ){
                   ContentDocument objConDoc = mapContentDoc.get(objConVer.ContentDocumentId);
                   System.debug(LoggingLevel.Debug,'objConVer.RecordType.Name::'+objConVer.RecordType.DeveloperName);
                   System.debug(LoggingLevel.Debug,'objConVer.RecordType.Name::'+mapObjectFileSetting.containsKey(objConVer.RecordType.DeveloperName));
                   if(objConVer.RecordTypeId != null && mapObjectFileSetting.containsKey(objConVer.RecordType.DeveloperName) 
                      && mapObjectFileSetting.get(objConVer.RecordType.Name).Accepted_Extension__c != null
                     ){
                         String acceptedExtension = mapObjectFileSetting.get(objConVer.RecordType.DeveloperName).Accepted_Extension__c;
                         acceptedExtensions = acceptedExtension.split(';'); 
                         if(acceptedExtensions != null && acceptedExtensions.size()>0 && !acceptedExtensions.contains(objConDoc.FileType)){
                             acceptedExtension = acceptedExtension.replaceAll(';', ', ');
                             String errorMessage = label.PromotionalPdf;
                             errorMessage = errorMessage.replace('Pdf', acceptedExtension);
                             objConDoc.addError(errorMessage);
                         }
                     }
               }
        }        
    }
    
    /*
     * Method  : getFileSetting
     * Purpose : This methods used to get details for each object
     */
    public static Map<String, File_Setting__mdt> getFileSetting(){
        Map<String, File_Setting__mdt> mapObjectFileSetting = new Map<String, File_Setting__mdt>();
        //145098
        for(File_Setting__mdt objFile : File_Setting__mdt.getAll().values()){
            //mapObjectFileSetting.put(objFile.MasterLabel, objFile);
            mapObjectFileSetting.put(objFile.Object_Api_Name__c, objFile);
        }
        return mapObjectFileSetting;        
    }
    
    /*
     * Method  : clearFieldDetails
     * Purpose : This methods used to clear field details in object
     */ 
    public static void clearFieldDetails(Map<Id, SObject> oldItems){
        EDGE_ContentDocumentLinkTriggerHelper.clearFieldDetails(oldItems);
    }
    
    
    /*
     * Method  : readOnlyAttach
     * Purpose : Lock the chile record when claim is approved/rejected
     */ 
    public static void readOnlyAttach(Map<Id, SObject> contentDocs){
        Map<Id, ContentDocument> newItems = (Map<Id, ContentDocument>)contentDocs;
        Map<string,string> mapOfClaimtoDoc = new Map<string,string>();
        for(ContentDocumentLink objConDocLink :[Select Id, LinkedEntityId,ContentDocumentId FROM ContentDocumentLink 
                                                WHERE ContentDocumentId IN :newItems.keySet()]) {
                                                    if(objConDocLink.LinkedEntityId != null && (objConDocLink.LinkedEntityId.getSObjectType() == CST_Claim__c.sObjectType)){       
                                                        mapOfClaimtoDoc.put(objConDocLink.LinkedEntityId,objConDocLink.ContentDocumentId);   
                                                    }
                                                }
        
        Id userId = UserInfo.getUserId();
        //145098
        if(!mapOfClaimtoDoc.isEmpty()){
            for(CST_Claim__c objClaims : [select id,CST_Status__c,CreatedById from CST_Claim__c where id IN :mapOfClaimtoDoc.keyset()]){
                if(objClaims.CST_Status__c == 'Approved' || objClaims.CST_Status__c == 'Rejected'){
                    if(mapOfClaimtoDoc.containskey(objClaims.id) && newItems.containskey(mapOfClaimtoDoc.get(objClaims.id))){
                        newItems.get(mapOfClaimtoDoc.get(objClaims.id)).addError('Claim Status is Approved/Rejected, Please Contact Administrator.');
                    }
                }
                else if(objClaims.CreatedById == userId && (objClaims.CST_Status__c == 'Assigned to Default Approver' ||  objClaims.CST_Status__c == 'Assigned To Approver')){
                    if(mapOfClaimtoDoc.containskey(objClaims.id) && newItems.containskey(mapOfClaimtoDoc.get(objClaims.id))){
                        newItems.get(mapOfClaimtoDoc.get(objClaims.id)).addError('Claim Status is Assigned to Default Approver/Assigned To Approver, Please Contact Administrator.');
                    }
                }
            }
        } 
    } 
    
    //Added as part of ECM-6787
    /*
	 * @description : uncheckPsInvoiceAttachment - This is used to update payment summary
	 * @return : void
	 * @param newItems 
	 */
    public static void uncheckPsInvoiceAttachment(Map<Id, SObject> contentDocs){
        Set<Id> psIdSet = new Set<Id>();
        Map<Id, ContentDocument> oldItems = (Map<Id, ContentDocument>)contentDocs;
        //145098
        for(ContentDocumentLink objConDocLink :[Select Id, LinkedEntityId,ContentDocumentId,
                                                ContentDocument.LatestPublishedVersion.RecordType.DeveloperName,
                                                ContentDocument.LatestPublishedVersion.Content_Type__c
                                                FROM ContentDocumentLink 
                                                WHERE ContentDocumentId IN :oldItems.keySet() WITH SECURITY_ENFORCED]){
                                                    if(objConDocLink.LinkedEntityId.getSObjectType() == ECM_Payment_Summary__c.sObjectType &&
                                                       objConDocLink.ContentDocument.LatestPublishedVersion.RecordType.DeveloperName == PAYMENT_SUMMARY_RECORD_TYPE ){
                                                           psIdSet.add(objConDocLink.LinkedEntityId);    
                                                       }
                                                }
        if(!psIdSet.isEmpty()){
            updatePsInvoiceAttachment(psIdSet);
        }
    }
    
   /*
    * @description : updatePsInvoiceAttachment - This is used to update payment summary
    * 					//145098 updated to handle in future
    * @return : void
    * @param Set 
    */
    @future
    public static void updatePsInvoiceAttachment(Set<Id> psIdSet){
        //145098
        set<Id> psInvoice = new set<Id>();
        set<Id> psEvidence = new set<Id>();
        List<ECM_Payment_Summary__c> lstToUpdate = new List<ECM_Payment_Summary__c>();
        
        for(ContentDocumentLink contDoc : [SELECT Id,LinkedEntityId,ContentDocument.LatestPublishedVersion.RecordType.DeveloperName,
                                           ContentDocument.LatestPublishedVersion.Content_Type__c
                                           FROM ContentDocumentLink 
                                           WHERE LinkedEntityId IN:psIdSet WITH SECURITY_ENFORCED]){
                                               if(contDoc.ContentDocument.LatestPublishedVersion.Content_Type__c == 'Invoice'){
                                                  psInvoice.add(contDoc.LinkedEntityId);
                                               }else if(contDoc.ContentDocument.LatestPublishedVersion.Content_Type__c == 'Evidence'){
                                                   psEvidence.add(contDoc.LinkedEntityId);
                                               }
                                           } 
        
        
        for(ECM_Payment_Summary__c psObj:
            [SELECT Id,ECM_Invoice_Attachment__c,
             ECM_Evidence_Attachment__c
             FROM ECM_Payment_Summary__c 
             WHERE Id IN:psIdSet WITH SECURITY_ENFORCED]){
                 if(!psInvoice.contains(psObj.Id)){
                     psObj.ECM_Invoice_Attachment__c = false;
                 }
                 if(!psEvidence.contains(psObj.Id)){
                     psObj.ECM_Evidence_Attachment__c = false;
                 }
                 lstToUpdate.add(psObj);
             }
        
        if(!lstToUpdate.isEmpty() && Schema.sObjectType.ECM_Payment_Summary__c.isUpdateable()){
            update lstToUpdate;
        }
        
        /*if(!psMapInvoice.isEmpty()){
            updatePsInvoice(psMapInvoice);
        }
        if(!psMapEvidence.isEmpty()){
            updatePsEvidence(psMapEvidence);
        }*/
    }
    
    /* 
	 * @description : getContDocAttach - This is used to update payment summary
	 * @return : void
	 * @param Object,Map,Map 
	 */
    /* public static void getContDocAttach(ContentDocumentLink contDoc, Map<Id,Decimal> psMapInvoice, Map<Id,Decimal> psMapEvidence){
        if(contDoc.ContentDocument.LatestPublishedVersion.Content_Type__c == 'Invoice'){
            if(psMapInvoice.containsKey(contDoc.LinkedEntityId)){
                psMapInvoice.put(contDoc.LinkedEntityId,(psMapInvoice.get(contDoc.LinkedEntityId)+1));
            }else{
                psMapInvoice.put(contDoc.LinkedEntityId,1);
            }
        }   
         else if(contDoc.ContentDocument.LatestPublishedVersion.Content_Type__c == 'Evidence'){
             if(psMapEvidence.containsKey(contDoc.LinkedEntityId)){
                 psMapEvidence.put(contDoc.LinkedEntityId,(psMapEvidence.get(contDoc.LinkedEntityId)+1));
             }else{
                 psMapEvidence.put(contDoc.LinkedEntityId,1);
             }  
         } 
     }*/
    
    /* 
	 * @description : updatePsInvoice - This is used to update payment summary
	 * @return : void
	 * @param Map 
	 */
    /*public static void updatePsInvoice( Map<Id,Decimal> psMapInvoice){
        Set<Id> psIdSettoUpdt = new Set<Id>();
        Set<ECM_Payment_Summary__c> lstToUpdt = new Set<ECM_Payment_Summary__c>();
        if(!psMapInvoice.keySet().isEmpty()){
            for(Id psId : psMapInvoice.keySet()){
                if(psMapInvoice.get(psId)==1){
                    psIdSettoUpdt.add(psId);
                }
            }
        }
        if(!psIdSettoUpdt.isEmpty()){
            for(ECM_Payment_Summary__c psObj:[SELECT Id,ECM_Invoice_Attachment__c FROM ECM_Payment_Summary__c WHERE Id IN:psIdSettoUpdt WITH SECURITY_ENFORCED]){
                psObj.ECM_Invoice_Attachment__c = false;
                lstToUpdt.add(psObj);
            }
        }
        if(!lstToUpdt.isEmpty() && Schema.sObjectType.ECM_Payment_Summary__c.isUpdateable()){
            List<ECM_Payment_Summary__c> lstFinalUpdt = new List<ECM_Payment_Summary__c>(lstToUpdt); 
            update lstFinalUpdt;
        }  
    }*/
    
   /*
    * @description : updatePsEvidence - This is used to update payment summary
    * @return : void
    * @param Map 
    */
    /*public static void updatePsEvidence(Map<Id,Decimal> psMapEvidence){
        Set<Id> psIdSettoUpdt1 = new Set<Id>();
        Set<ECM_Payment_Summary__c> lstToUpdt = new Set<ECM_Payment_Summary__c>();
        if(!psMapEvidence.keySet().isEmpty()){
            for(Id psEvidId : psMapEvidence.keySet()){
                if(psMapEvidence.get(psEvidId)==1){
                    psIdSettoUpdt1.add(psEvidId);
                }
            }
        }
        if(!psIdSettoUpdt1.isEmpty()){      
            for(ECM_Payment_Summary__c psObj:[SELECT Id,ECM_Evidence_Attachment__c FROM ECM_Payment_Summary__c WHERE Id IN:psIdSettoUpdt1 WITH SECURITY_ENFORCED]){
                psObj.ECM_Evidence_Attachment__c = false;
                lstToUpdt.add(psObj);
            }
        }
        if(!lstToUpdt.isEmpty() && Schema.sObjectType.ECM_Payment_Summary__c.isUpdateable()){
            List<ECM_Payment_Summary__c> lstFinalUpdt = new List<ECM_Payment_Summary__c>(lstToUpdt); 
            update lstFinalUpdt;
        }
    }*/
}