/**

* @description :  EDGE_CaseTriggerHelper

* @history : Trigger Handler Class for Case for EDGE

* Version   Developer     	 	Date       		User Story	  	Purpose
* 1.0      	Dinesh Sharma       19/07/2021      ES20-9229 		Initial Development
* 2.0     	Monalisa Halder     27/07/2021      ES20-9662		insertCaseAttachment

* 3.0	    Monalisa Halder	    17/09/2021		ES20-10567      updateCaseUserCountry
*4.0        Amar Deep           18/10/2021      NCP-5051


*/
public class EDGE_CaseTriggerHelper {
    
    final static String technicalIssueRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
    final static String diageoOneRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
    

    /**
    * @method   createSnowTicket
    * @description This methods used to filter Case record based on record Type 
	*              and send it for callout (ES20-9229)
    *  @return void
    *  @param Map

*/
    public static void createSnowTicket(Map<id,sObject> newItems, Map<id,sObject> oldItems){
        Map<id,Case> oldCaseMap = (Map<id,Case>)oldItems;
        Map<id,Case> caseMap = (Map<id,Case>)newItems;
        Map<Id,Case> techIssueCase = new Map<Id,Case>();
        //List<D1_User_Type__c> userTypeObj = new List<D1_User_Type__c>();
        
        /*List<User> userObj = [SELECT Id,ContactId,Contact.AccountId,Contact.Email,Effective_Account_Id__c,UserType,D1_User_Type_Id__c
                              FROM User 
                              WHERE Id =:  UserInfo.getUserId()]; //NCP-5015

        if(UserInfo.getUserType() != 'Guest' && userObj[0].D1_User_Type_Id__c != null){ //NCP-5015
                userTypeObj = [SELECT Id, Enable_Service_Now__c FROM D1_User_Type__c WHERE Id =: userObj[0].D1_User_Type_Id__c];
        }*/
                            
        for(Case caRec : caseMap.values() ){ 
            if(oldCaseMap == null || (oldCaseMap != null && oldCaseMap.get(caRec.Id).RecordTypeId != caRec.RecordTypeId && oldCaseMap.get(caRec.Id).RecordTypeId == diageoOneRecordTypeId)){
                if(caRec.RecordTypeId == technicalIssueRecordTypeId){
                    techIssueCase.put(caRec.id,caRec);
                }
            }
          
            //As of now we are not using this functionality so we comment this part(as per NCP-6018) but in future if we will have such requirement then we will uncomment and reuse this part 
            /*if(caRec.RecordTypeId == technicalIssueRecordTypeId && caRec.Origin != 'Diageo One'){
                techIssueCase.put(caRec.id,caRec);

            }else if(UserInfo.getUserType() != 'Guest' && caRec.Origin == 'Diageo One' && userTypeObj.size()>0 && userTypeObj[0].Enable_Service_Now__c == True && caRec.RecordTypeId == technicalIssueRecordTypeId){ //NCP-5015
                techIssueCase.put(caRec.id,caRec);
            }else if(UserInfo.getUserType() != 'Guest' && caRec.Origin == 'Diageo One' && userTypeObj.isEmpty() && caRec.RecordTypeId == technicalIssueRecordTypeId){ //NCP-5015

                techIssueCase.put(caRec.id,caRec);
            }else if(caRec.RecordTypeId == technicalIssueRecordTypeId && UserInfo.getUserType() == 'Guest' && caRec.Origin == 'Diageo One'){
                techIssueCase.put(caRec.id,caRec);
            } */
        }
        
        if(techIssueCase != null && techIssueCase.size() > 0){
            System.enqueueJob(new EDGE_CaseIntegrationWithSNOW(techIssueCase));
        }
        
    }

    
    /**
    * @method   insertCaseAttachment
    * @description This methods used to send technical Case attachment to SNOW (ES20-9662)
    *  @return void
    *  @param Map
    */
    

    public static void insertCaseAttachment(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id,Case> oldCaseMap = new Map<Id,Case>(); 
        Map<Id,Case> newCaseMap = new Map<Id,Case>();
        Map<Id,Map<Id, String>> caseIdConVersionMap = new Map<Id,Map<Id, String>>();        
        Map<Id,String> caseSFIdSysIdMap = new Map<Id,String>();
        //Created for Case Comment Integration
        Map<Id,List<String>> caseSysIdCommentMap = new Map<Id,List<String>>();
        Boolean commentPresent = false;
        Boolean attachmentPresent = false;
        
        if(oldItems != null){
            oldCaseMap = (Map<Id,Case>)oldItems;
        } 
        newCaseMap = (Map<Id,Case>)newItems;
        
        for(Id caseId : newCaseMap.keySet()){
            if(newCaseMap.get(caseId).CreatedBy.Profile.Name != 'Integration User Profile' 
               && newCaseMap.get(caseId).recordTypeId == technicalIssueRecordTypeId 
               && (String.isBlank(oldCaseMap.get(caseId).sys_id__c)) 
               && (!String.isBlank(newCaseMap.get(caseId).sys_id__c))){
                   
                   caseSFIdSysIdMap.put(caseId,newCaseMap.get(caseId).sys_id__c);
                   
                   caseSysIdCommentMap.put(caseId,new List<String>{newCaseMap.get(caseId).sys_id__c});
                   
                   
               }
            
        }
        if(caseSFIdSysIdMap.size() >0){
            for(ContentDocumentLink contentDocumentLinkObj:[SELECT Id,ContentDocument.LatestPublishedVersionId,
                                                            ContentDocument.Title,ContentDocument.FileExtension,
                                                            LinkedEntityId FROM ContentDocumentLink 
                                                            WHERE LinkedEntityId IN :caseSFIdSysIdMap.keySet()]){
                                                                string contentDocumentName = contentDocumentLinkObj.ContentDocument.Title + '.' +contentDocumentLinkObj.ContentDocument.FileExtension;                                           
                                                                if(caseIdConVersionMap.get(contentDocumentLinkObj.LinkedEntityId) != null){
                                                                    caseIdConVersionMap.get(contentDocumentLinkObj.LinkedEntityId).put(contentDocumentLinkObj.ContentDocument.LatestPublishedVersionId, contentDocumentName);
                                                                }else{
                                                                    Map<Id, String> contentVersionIdMap = new Map<Id, String>();
                                                                    contentVersionIdMap.put(contentDocumentLinkObj.ContentDocument.LatestPublishedVersionId, contentDocumentName);
                                                                    caseIdConVersionMap.put(contentDocumentLinkObj.LinkedEntityId,contentVersionIdMap);
                                                                    if(contentVersionIdMap != null && contentVersionIdMap.size()>0){
                                                                        attachmentPresent = true;
                                                                    }
                                                                }                                                      
                                                            }
        }  
        //Created for Case Comment Integration
        if(caseSysIdCommentMap.size() > 0){
            for(caseComment caseComId: [SELECT Id,parentId, CommentBody FROM caseComment WHERE parentId IN :caseSysIdCommentMap.keySet()]){
                if(caseComId.CommentBody != null){
                    commentPresent = true;
                    caseSysIdCommentMap.get(caseComId.ParentId).add(caseComId.CommentBody);  
                }
                
            }
        }         
        if(commentPresent && caseSysIdCommentMap != null && caseSysIdCommentMap.size() > 0){
            System.enqueueJob(new EDGE_CaseCommentIntegrationWithSNOW(caseSysIdCommentMap,caseIdConVersionMap,attachmentPresent));
        } 
        if(attachmentPresent && !commentPresent && caseIdConVersionMap != null && caseIdConVersionMap.size() > 0 ){
            System.enqueueJob(new Edge_CaseAttachmentIntegrationWithSNOW(caseIdConVersionMap));
        }                
    }  

    

    /**
    * @method   updateCaseUserCountry
    * @description This methods used to update User Country by created by user country (ES20-10567)
    *  @return void
    *  @param Map
    */
    
   public static void updateCaseUserCountry(Map<Id, SObject> newItems){
   
        List<Case> caseList = new List<Case>();
        Map<Id,Case> caseRecordMap = (Map<Id,Case>)newItems; 
        Map<Id,Case> techIssueCaseMap = new Map<Id,Case>();
        Map<Id, String> userToCountryMap = new Map<Id, String>();
        Set<Id> userIdSet = new Set<Id>();
       
        for(Case caRec : caseRecordMap.values()){
            if(caRec.RecordTypeId == technicalIssueRecordTypeId){
                userIdSet.add(caRec.CreatedById);
                techIssueCaseMap.put(caRec.Id,caRec);
            }
        }
        userToCountryMap = EDGE_CaseIntegrationWithSNOW.fetchUserCountry(userIdSet);
  		
       if(userToCountryMap != null){
            for(Case ca :[Select Id,User_Country__c,createdById from Case where Id IN : techIssueCaseMap.keySet()]){
                if(userToCountryMap.get(ca.createdById) != null ){
                    ca.User_Country__c  = userToCountryMap.get(ca.createdById);
                    caseList.add(ca);
                }
            }
       }
       if(caseList != null && caseList.size() > 0){
            database.update(caseList) ;
       }
        
    }

}