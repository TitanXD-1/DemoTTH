/**

* @Description: EDGE_QualityCaseTriggerHelper

* @Purpose : Quality Trigger Helper Class for Case

* @History:

* @Version     Developer		   Date			     Story/Purpose
*    1.1       Aparajita		 17/09/2021		   ES20-11127(Method:pushNotificationMethodforCase)  
*	 1.2	   Anamika Shukla 	 20/09/2021		   ES20-10781(Method: populateSLAMetForCase)
*    1.3	   Anamika Shukla 	 20/09/2021		   ES20-11126(Method: pauseMilestone)
*	 1.4	   Prasanth T		 20/09/2021		   ES20-10763(Method: setDueDateOnCase) 
*    1.5       Sudipta           20/09/2021        ES20-11106(Method: updateQualityEntitlementName
*    1.6       Anand U           13/01/2021        ES20-11752(Method: enableManualSLAExtensionFlag)
*	 1.7	   Anamika   	     07/04/2022		   ES20-12361(Method: restrictCaseStatusUpdate)


*/

public with Sharing class EDGE_QualityCaseTriggerHelper {
    
    final static String QualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();     
    
    
    
    public static void pauseMilestone(Map<Id,SObject> newItems,Map<Id,SObject> oldItems){
        
        Map<Id,Case> caseRecordMap = (Map<id,Case>)newItems;
        Map<Id,Case> caseOldRecordMap = (Map<id,Case>)oldItems;
        Set<Id> casesToUpdate = new Set<Id>();
        if(caseRecordMap != null && caseRecordMap.Size()>0){
            for( Case newCaseId : caseRecordMap.values()){
                if(newCaseId.RecordTypeId == QualityRecordTypeId){
                    if(newCaseId.status == EDGE_Constant.ONHOLD_QUALITYCASE && newCaseId.status != caseOldRecordMap.get(newCaseId.ID).status){
                        newCaseId.IsStopped = True;
                        casesToUpdate.add(newCaseId.Id);
                    }
                    else if (newCaseId.status != EDGE_Constant.ONHOLD_QUALITYCASE)
                    {
                        newCaseId.IsStopped = false;
                    }
                }
            }
        }
        if (casesToUpdate != null && casesToUpdate.Size()>0) {
            System.enqueueJob(new EDGE_QualityCaseMilestoneUtils(casesToUpdate,true));
        }
        
    }  
    
    public static void populateSLAMetForCase(Map<Id,SObject> newItems,Map<Id,SObject> oldItems){
        Map<Id,Case> caseNewRecMap = (Map<id,Case>)newItems;
        Map<Id,Case> caseOldRecMap = (Map<id,Case>)oldItems;
        Set<Id> casesToUpdate = new Set<Id>();
        List<Case_Task__c> caseTaskToUpdate= new List<Case_Task__c>();
        if(caseNewRecMap != null && caseNewRecMap.Size()>0){
            for( Case newCaseId : caseNewRecMap.values()){               
                if(newCaseId.RecordTypeId == QualityRecordTypeId && newCaseId.status == EDGE_Constant.CLOSED_QUALITYCASE && newCaseId.status != caseOldRecMap.get(newCaseId.ID).status){
                    if (System.now() == newCaseId.Due_Date_Time__c || System.now() < newCaseId.Due_Date_Time__c){
                        newCaseId.Case_SLA_Met__c = True;
                    }
                    casesToUpdate.add(newCaseId.Id);
                }
                else if(newCaseId.RecordTypeId == QualityRecordTypeId && caseOldRecMap.get(newCaseId.ID).status == EDGE_Constant.CLOSED_QUALITYCASE && newCaseId.status != caseOldRecMap.get(newCaseId.ID).status){
                    if (System.now() == newCaseId.Due_Date_Time__c || System.now() < newCaseId.Due_Date_Time__c){
                        newCaseId.Case_SLA_Met__c = False;
                        casesToUpdate.add(newCaseId.Id);
                    }
                    
                }
            }
            if (casesToUpdate != null && casesToUpdate.Size()>0) {
                populateSLAonMetAndMileStone(casesToUpdate);



            }
        }
    }
    public static void populateSLAonMetAndMileStone(Set<Id> caseIds) {
        List<CaseMilestone> casesMileStoneToUpdate = new List<CaseMilestone>();
        if (caseIds != null && caseIds.Size()>0 ){
            for (CaseMilestone milestone : [
                select Id,
                CaseId,
                Case.AccountId,
                Case.Status,
                MilestoneType.Name,
                TargetDate,
                CompletionDate
                from CaseMilestone
                where CaseId in :caseIds AND CompletionDate = null
            ]) {
                casesMileStoneToUpdate.add(new CaseMilestone(
                    Id = milestone.Id,
                    CompletionDate = System.now()
                ));
            }
        }
        if (casesMileStoneToUpdate != null && casesMileStoneToUpdate.Size()>0) {
            update casesMileStoneToUpdate;
        }
        
    }
    
    public static void setDueDateOnCase(Map<Id,SObject> newItems,Map<Id,SObject> oldItems, Boolean pushNotification){
        Map<Id,Case> caseRecordMap = (Map<id,Case>)newItems;
        Map<Id,Case> caseOldRecordMap = (Map<id,Case>)oldItems;
        Set<Id> casesToUpdate = new Set<Id>();
        
        if (caseRecordMap != null && caseRecordMap.Size()>0 && pushNotification == false){     
            for( Case newCaseId : caseRecordMap.values()){            
                if(newCaseId.RecordTypeId == QualityRecordTypeId && newCaseId.status != EDGE_Constant.ONHOLD_QUALITYCASE){
                    casesToUpdate.add(newCaseId.Id);

                    

                }
            }
            if (casesToUpdate != null && casesToUpdate.Size()>0) {
                System.enqueueJob(new EDGE_QualityCaseMilestoneUtils(casesToUpdate,pushNotification));
            }
        }
        if (caseRecordMap != null && caseRecordMap.Size()>0 && caseOldRecordMap != null && caseOldRecordMap.Size()>0 && pushNotification == true){
            for( Case newCaseId : caseRecordMap.values()){
                
                if(newCaseId.RecordTypeId == QualityRecordTypeId && newCaseId.status != EDGE_Constant.ONHOLD_QUALITYCASE && newCaseId.status != EDGE_Constant.CLOSED_QUALITYCASE &&  newCaseId.status != caseOldRecordMap.get(newCaseId.Id).status){
                    casesToUpdate.add(newCaseId.Id);
                    
                }
            }
            if (casesToUpdate != null && casesToUpdate.Size()>0) {
                System.enqueueJob(new EDGE_QualityCaseMilestoneUtils(casesToUpdate,pushNotification));
            }
        }
    }
    
    /**

    * @description : pushNotificationMethodforCase - Sends push notification to the applicable users upon case status update
    
    * @return : void
    
    * @param : List<Case>, String, Map<String, Object>
    
    */
    public static void pushNotificationMethodforCase(List<String> users, String msgBody, Map<String, Object> custom){
        
        
        String isPushNotificationEnabled = System.label.EDGE_IsQualityCasePushNotificationEnabled;
        Set<String> usersList = new Set<String>();
        /*for(String user: users)
		usersList.add(user);*/
        //System.debug('@@@' + users + isPushNotificationEnabled );
        if(isPushNotificationEnabled != null && isPushNotificationEnabled.equalsIgnoreCase('Yes') 
           && users != null && !users.isEmpty()){
               usersList.addAll(users);
               System.debug('@@@'+users);
               Messaging.PushNotification msg = new Messaging.PushNotification();
               Map<String, Object> payload = Messaging.PushNotificationPayload.apple(msgBody,null,null,custom);
               msg.setPayload(payload);
               System.debug('@@@payload'+payload);
               if(!Test.isRunningTest()){
                   msg.send('Edge_SFA_2_0', usersList);  
               }
           }       
        
    }  
    /**

* @description :  enableManualSLAExtensionFlag- Enables the Manual SLA extension check box when manually edits the DUE date

* @return : void

* @param : List<Case>, Map<String, Object>

*/
    public static void enableManualSLAExtensionFlag(List<SObject> newItems,Map<Id,SObject> oldItems){
        List<Case> newCaseList = (List<Case>)newItems;
        Map<Id,Case> oldCaseMap= (Map<Id,Case>) oldItems;
        
        if(newCaseList!=null && newCaseList.Size()>0){


            for(Case newCaseRec:newCaseList){
                if(newCaseRec.RecordTypeId == QualityRecordTypeId && !System.isQueueable()){
                    if(oldCaseMap != null && oldCaseMap.Size()>0){
                        Case oldCaseRec= oldCaseMap.get(newCaseRec.Id);
                        if(oldCaseRec.Due_Date_Time__c!=newCaseRec.Due_Date_Time__c){
                            newCaseRec.Manual_SLA_Extension__c=true;


                        }
                    }
                }
            }
        }               
    }

    /**
* @Description: restrictCaseStatusUpdate
* @Purpose: When logged in as the mentioned profiles in the story, I am restricted when:
I am trying to close a Case that has one or more open/pending CTs
* @Parameters: Map<Id,SObject> newItems,Map<Id,SObject> oldItems
**/    
    public static void restrictCaseStatusUpdate(Map<Id,SObject> newItems,Map<Id,SObject> oldItems){
        List<String> profilesToRestrict = System.Label.EDGE_RestrictCaseStatusEditProfiles.split(';');
        List<String> eligibleCTStatus = System.Label.EDGE_CaseTaskStatus.split(';');
        Map<Id,Case> newCaseMap = (Map<Id,Case>)newItems;
        Map<Id,Case> oldCaseMap = (Map<Id,Case>)oldItems;
        Set<Id> profileSet = new Set<Id>();

        for(Profile prof : [SELECT Id, Name FROM Profile WHERE Name IN : profilesToRestrict]){
            profileSet.add(prof.Id);
        }
        
        if(newCaseMap.keySet()!=null && newCaseMap.keySet().size()>0){
            for(Case_Task__c ct : [SELECT Id, Case__r.Status FROM Case_Task__c WHERE Achievement_Status__c IN : eligibleCTStatus 
                                   AND Case__c IN : newCaseMap.keySet()])
            {
                Case oldCase = oldCaseMap.get(ct.Case__c);
                Case updatedCase = newCaseMap.get(ct.Case__c);
                if(oldCase != null && oldCase.Status != updatedCase.Status && updatedCase.Status == 'Closed' && profileSet.contains(UserInfo.getProfileId())){
                    updatedCase.addError(System.Label.EDGE_CaseWithOpenCTCannotBeClosed);  
                }
            }
        }
    }


}