/**
@name EDGE_DynamicTLCaseTaskCreationHelper
@description Helper class to create Case, Case Task when Dynamic Target List Member is made Active
@history
VERSION     	AUTHOR           DATE           DETAIL
1.0         Monalisa Halder    11/01/2022		ES20-11865,Defect ES20-11972
2.0 		Prasanth T		   11/01/2022		ES20-11866
3.0 		Subhodeep Sarkar   31/01/2022		ES20-11757
4.0 		Swaraj Samanta	   31/01/2022		ES20-11932
5.0       Monalisa Halder      15/02/2022       ES20-11870 - Removed the method deleteCaseTask
6.0			Wribhu Bose		   07/03/2022		ES20-12161 - Added Case Task Name population in method createCaseTask
7.0			Swaraj Samanta		16/03/2022 		ES20-12353
**/

public with sharing class EDGE_DynamicTLCaseTaskCreationHelper {
    final static String QualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    /**
* @description : This method is used to create Case and Case Task 
* @return : void
* @param : Map<Id,Set<Id>>
*/
    public static void processCaseAndCaseTask(Map<Id,Set<Id>> outletIdCaseTemplateIdMap){
        Map<Id, Case_Template__c> caseTemplateMap;
        Set<Id> allCaseTemplateIdSet = new Set<Id>();
        
        for(Id outletId :outletIdCaseTemplateIdMap.keyset()){
            Set<Id> caseTemplateIdSet = outletIdCaseTemplateIdMap.get(outletId);
            allCaseTemplateIdSet.addAll(caseTemplateIdSet);
        }
       
        //CreateCase Template map
        caseTemplateMap = new Map<Id,Case_Template__c>([SELECT Id,Case_Sub_Type__c, Case_Task_Type__c , Case_Type__c ,Case_Notes__c ,
                                                        Country__c, Asset__c, Task_Comment__c , Due_Date_Time__c, Product__c, Quantity__c, Case_Task_Name__c 
                                                        FROM Case_Template__c WHERE Id IN :allCaseTemplateIdSet]);
        List<Case> caseListToInsert = createCase(outletIdCaseTemplateIdMap,caseTemplateMap);
        
        if(caseListToInsert != null && caseListToInsert.size()>0){
            Database.insert(caseListToInsert,false);
            List<Case_Task__c> caseTaskListToInsert = createCaseTask(caseListToInsert,caseTemplateMap);
            if(caseTaskListToInsert != null && caseTaskListToInsert.size()>0){
                Database.insert(caseTaskListToInsert,false);
            }
        }
        
        
    }
    
    /**
* @description : This method is used to return of list of Cases to be created
* @return : List<Case>
* @param : Map<Id,Id> outletIdCaseTemplateIdMap,Map<Id, Case_Template__c> caseTemplateMap
*/
    Private static List<Case> createCase(Map<Id,Set<Id>> outletIdCaseTemplateIdMap,Map<Id, Case_Template__c> caseTemplateMap){
        List<Case> caseListToInsert = new List<Case>();
        for(Id outletId :outletIdCaseTemplateIdMap.keySet()){
            Set<Id> caseTempIdSet = outletIdCaseTemplateIdMap.get(outletId);
            if(caseTempIdSet != null){
                for(Id caseTempId :caseTempIdSet){
                    if(caseTemplateMap.containsKey(caseTempId)){
                        Case cse = new case();
            			cse.AccountId = outletId;
                        Case_Template__c caseTemplate = caseTemplateMap.get(caseTempId);
                        cse.Case_Type__c = caseTemplate.Case_Type__c;
                        cse.Case_Sub_Type__c = caseTemplate.Case_Sub_Type__c;
                        cse.Origin = 'EDGE 365';
                        cse.Case_Template__c = caseTemplate.Id;
                        if(caseTemplate.Case_Notes__c != null){
                            cse.Case_Notes__c = caseTemplate.Case_Notes__c; 
                            
                        }
                        if(caseTemplate.Due_Date_Time__c == null){
                            cse.Manual_SLA_Extension__c = false; 
                         }else{
                            cse.Due_Date_Time__c = caseTemplate.Due_Date_Time__c ; 
                            cse.Manual_SLA_Extension__c = true; 
                         }
                       
                    cse.RecordTypeId = QualityRecordTypeId;
                    cse.Status = EDGE_Constant.OPEN_QUALITYCASE;
                    caseListToInsert.add(cse);
                        
                    }
                    
                    
                }   
            }
            
            
        }
        return caseListToInsert;
    }
    /**
* @description : This method is used to return of Case Task to be created
* @return : List<Case_Task__c>
* @param : List<Case> caseListToInsert,Map<Id, Case_Template__c> caseTemplateMap
*/
    Private static List<Case_Task__c> createCaseTask(List<Case> caseListToInsert, Map<Id,Case_Template__c> caseTemplateMap){
        List<Case_Task__c> caseTaskListToInsert = new List<Case_Task__c>();
        for(Case cse :caseListToInsert){
            Case_Task__c taskRec = new Case_Task__c();
            taskRec.Case__c  = cse.Id;
            
           if( caseTemplateMap.containsKey(cse.Case_Template__c)){
                Case_Template__c caseTemplate = caseTemplateMap.get(cse.Case_Template__c);
                taskRec.Country__c = caseTemplate.Country__c;
                taskRec.Case_Task_Type__c = caseTemplate.Case_Task_Type__c;
                if(caseTemplate.Asset__c != null){
                    taskRec.Asset__c = caseTemplate.Asset__c;    
                }
                if(caseTemplate.Task_Comment__c != null){
                    taskRec.Case_Task_Notes__c = caseTemplate.Task_Comment__c;    
                }
                if(caseTemplate.Product__c != null){
                    taskRec.Product__c = caseTemplate.Product__c;    
                }
                if(caseTemplate.Quantity__c != null){
                    taskRec.Quantity__c = caseTemplate.Quantity__c;    
                }
                if(caseTemplate.Case_Task_Name__c != null){
                    taskRec.Case_Task_Name__c = caseTemplate.Case_Task_Name__c; 
                }
                taskRec.Achievement_Status__c = 'Open';
                caseTaskListToInsert.add(taskRec); 
            }
            
            
        }
        return caseTaskListToInsert;
    }
    public static void updateStatusOfCaseTask(Map<Id, Set<Id>> deleteTargetListOutletMap,Boolean updateAtl){
        // system.debug('@@updateStatusOfCaseTask inside');
        final String caseTemplateRecordTypeId = Activity_Target_List__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Template').getRecordTypeId();     
        Set<Id> targetListIdSet = new Set<Id>();
        Set<Id> targetOutletIdSet = new Set<Id>();
        Set<Id> caseTemplateIdSet = new Set<Id>();
        List<Case_Task__c> caseTaskToUpdateList = new List<Case_Task__c>();
        
        if(deleteTargetListOutletMap != null && deleteTargetListOutletMap.Size()>0){
            
            for(Id targetListId: deleteTargetListOutletMap.keySet()){
                targetListIdSet.add(targetListId);
                Set<Id> deleteOutletsIdSet = deleteTargetListOutletMap.get(targetListId);
                targetOutletIdSet.addAll(deleteOutletsIdSet);
            }
        }
        
        if(targetListIdSet != null && targetListIdSet.size()>0){
            List<Activity_Target_List__c> activityTargetLists = new List<Activity_Target_List__c>();
            if (updateAtl == true){
               activityTargetLists =  [SELECT Id,Name,Target_List__c,Case_Template__c FROM Activity_Target_List__c 
                                                              WHERE Target_List__c IN:targetListIdSet 
                                                              AND RecordTypeId =: caseTemplateRecordTypeId 
                                                              AND Case_Template__c != null
                                       						AND (Status__c ='Waiting Removal'  
                                            				OR (Status__c ='Inactive' AND LastModifiedDate = TODAY ))];
             }else{
             activityTargetLists =  [SELECT Id,Name,Target_List__c,Case_Template__c FROM Activity_Target_List__c 
                                                              WHERE Target_List__c IN:targetListIdSet 
                                                              AND RecordTypeId =: caseTemplateRecordTypeId 
                                                              AND Case_Template__c != null] ;
             }
            for(Activity_Target_List__c activityTargetList : activityTargetLists ){
                caseTemplateIdSet.add(activityTargetList.Case_Template__c);
            }
      
        }
        // system.debug('@@caseTemplateIdSet' +caseTemplateIdSet);
        if(targetOutletIdSet != null && targetOutletIdSet.size()>0 && caseTemplateIdSet != null && caseTemplateIdSet.size()>0){
            for(Case_Task__c caseTaskRecord: [SELECT Id,Achievement_Status__c, Case__c, Case__r.Status,Case__r.AccountId,Case__r.Case_Template__c 
                                              FROM Case_Task__c 
                                              WHERE Case__r.AccountId IN:targetOutletIdSet 
                                              AND Case__r.Case_Template__c IN: caseTemplateIdSet]){
                                                  if(caseTaskRecord.Achievement_Status__c != null){
                                                      
                                                      if(caseTaskRecord.Achievement_Status__c == 'Open' || caseTaskRecord.Achievement_Status__c == 'Pending'){
                                                          
                                                          caseTaskRecord.Achievement_Status__c = 'Cancelled';
                                                          caseTaskToUpdateList.add(caseTaskRecord);
                                                      }
                                                  }    
                                              }
        }
        if(caseTaskToUpdateList != null && caseTaskToUpdateList.Size()>0){
            //ES20-13673
            Database.update(caseTaskToUpdateList, false);
            //update caseTaskToUpdateList;
        }
    }
    
   
}