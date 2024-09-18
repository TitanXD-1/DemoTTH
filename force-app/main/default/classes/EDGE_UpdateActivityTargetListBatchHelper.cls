/**
Class Name: EDGE_UpdateActivityTargetListBatchHelper

Author              Version     Date           Detail
Rajarshi Lahiri		v1.0		10/07/2023	   142528
*/

public without sharing class EDGE_UpdateActivityTargetListBatchHelper {
    public static List<Target_List_Member__c> updateTLMList= new list<Target_List_Member__c>();
    public static List<Target_List_Member__c> deleteTLMList= new list<Target_List_Member__c>();
    public static Set<Id> updateActTLList= new Set<Id>();
    public static Set<Id> deleteActTLList= new Set<Id>();
    public static Map<Id, Set<Id>> createActivityTargetListMap = new Map<Id, Set<Id>>();
    public static Map<Id, Set<Id>> deleteActivityTargetListMap = new Map<Id, Set<Id>>();
    public static set<string> createOutletOppTemplateSet = new set<string>();
    public static set<string> deleteOutletOppTemplateSet = new set<string>();
    public static set<Id> createOppTemplateIdSet = new set<Id>();
    public static set<Id> deleteOppTemplateIdSet = new set<Id>();
    public static set<Id> createOutletIdSet = new set<Id>();
    public static set<Id> deleteOutletIdSet = new set<Id>();
    public static List<Id> targetListIds=new List<Id>();
    public static Map<Id,List<Target_List_Member__c>> tlmMap=new Map<Id,List<Target_List_Member__c>>();
    
    /** 
    * @description: oppOperationHelper
    * @purpose: The method takes Target List Members and create opportunities or deletes them.
    * @parameters: List<Target_List_Member__c>
    */
    public static Map<String,Set<Id>> oppOperationHelper(List<Target_List_Member__c> targetLstMemList){
        //Create map of Target List Id with List of TLM records
        Map<String,Set<Id>> toReturn=new Map<String,Set<Id>>();
        for(Target_List_Member__c tlm:targetLstMemList){
            targetListIds.add(tlm.Target_List__c);
            tlmMap=createTLMMap(tlmMap,tlm);
            
        }
		//Get Activity Target List for those target lists in the scope
        for(Activity_Target_List__c actTLMem :[SELECT Id, Opportunity_Template__c, Target_List__c, Opportunity_Template__r.Opportunity_Type__c, Status__c FROM Activity_Target_List__c WHERE Opportunity_Template__c != null AND (Status__c='Waiting Activation' or Status__c='Waiting Removal') AND Opportunity_Template__r.Opportunity_Type__c = 'Cycle Brief' AND Target_List__c IN:targetListIds  WITH SECURITY_ENFORCED]){
			setLists(actTLMem);
        }

        //Create Opportunity Block
        if(updateActTLList!=null && !updateActTLList.isEmpty()){
            //Get All Target List Member
            for(Target_List_Member__c targetLstMem : updateTLMList){
                createOutletIdSet.add(targetLstMem.Outlet__c);
                //Create a mapping of outlet id & template id for which we need to create opp
				createOutletOppTemplateSet=createKeySet(createOutletOppTemplateSet,targetLstMem,createActivityTargetListMap);
            }
            
            EDGE_OpportunityOperations.createOpportunities(createOutletOppTemplateSet, createOutletIdSet, createOppTemplateIdSet);
        }
        
        //Delete Opportunity Block
        if(deleteActTLList!=null && !deleteActTLList.isEmpty()){
            //Get All Target List Member
            for( Target_List_Member__c targetLstMem : deleteTLMList){
                deleteOutletIdSet.add(targetLstMem.Outlet__c);
                //Create a mapping of outlet id & template id for which we need to delete opp
				deleteOutletOppTemplateSet=createKeySet(deleteOutletOppTemplateSet,targetLstMem,deleteActivityTargetListMap);
            }
            
            EDGE_OpportunityOperations.deleteOpportunities(deleteOutletOppTemplateSet, deleteOppTemplateIdSet);
        }
        toReturn.put('Update',updateActTLList);
        toReturn.put('Delete',deleteActTLList);
        
        return toReturn;
    }
    public static void setLists(Activity_Target_List__c actTLMem){
        if(actTLMem.Status__c == 'Waiting Activation'){
            //actTLMem.Status__c='Active';
            updateActTLList.add(actTLMem.Id);
            updateTLMList.addAll(tlmMap.get(actTLMem.Target_List__c));
            createOppTemplateIdSet.add(actTLMem.Opportunity_Template__c);
            
            //Create Target List & Activity Target List MAP
            createActivityTargetListMap=createtlATLMap(createActivityTargetListMap,actTLMem);
        }
        else if(actTLMem.Status__c == 'Waiting Removal'){
            deleteActTLList.add(actTLMem.Id);
            deleteOppTemplateIdSet.add(actTLMem.Opportunity_Template__c);
            deleteTLMList.addAll(tlmMap.get(actTLMem.Target_List__c));
            //System.debug('@@deleteOppTemplateIdSet'+deleteOppTemplateIdSet);
            //Create Target List & Activity Target List MAP
            deleteActivityTargetListMap=createtlATLMap(deleteActivityTargetListMap,actTLMem);
        }
    }
    /** 
    * @description: createKeySet
    * @purpose: Creates key for Outlet with Opportunity Template
    * @parameters: set<string>,Target_List_Member__c,Map<Id, Set<Id>>
    */
    public static set<string> createKeySet(set<string> outletOppTemplateSet,Target_List_Member__c targetLstMem,Map<Id, Set<Id>> activityTargetListMap){
        if(activityTargetListMap != null && activityTargetListMap.containsKey(targetLstMem.Target_List__c)){
            for(Id oppTemplateId : activityTargetListMap.get(targetLstMem.Target_List__c)){
                string key = targetLstMem.Outlet__c + '-' + oppTemplateId;
                outletOppTemplateSet.add(key);
            }
        }
        return outletOppTemplateSet;
    }
    /** 
    * @description: createTLMMap
    * @purpose: Takes Target List members and return map of Target List Id with List of TLM records
    * @parameters: Map<Id,List<Target_List_Member__c>>,Target_List_Member__c
    */
    public static Map<Id,List<Target_List_Member__c>> createTLMMap(Map<Id,List<Target_List_Member__c>> tlmMap,Target_List_Member__c tlm){
        if(tlmMap.containsKey(tlm.Target_List__c)){
            tlmMap.get(tlm.Target_List__c).add(tlm);
        }
        else{
            List<Target_List_Member__c> newList=new List<Target_List_Member__c>();
            newList.add(tlm);
            tlmMap.put(tlm.Target_List__c,newList);
        } 
        return tlmMap;
    }
    /** 
    * @description: createtlATLMap
    * @purpose: 
    * @parameters: Map<Id, Set<Id>>,Activity_Target_List__c
    */
    public static Map<Id, Set<Id>> createtlATLMap(Map<Id, Set<Id>> activityTargetListMap,Activity_Target_List__c actTLMem){
        if(activityTargetListMap.containsKey(actTLMem.Target_List__c)){
            activityTargetListMap.get(actTLMem.Target_List__c).add(actTLMem.Opportunity_Template__c);
        }else{
            activityTargetListMap.put(actTLMem.Target_List__c, new Set<Id>{actTLMem.Opportunity_Template__c});
        }
        return activityTargetListMap;
    }
    //method added to store error records in Country Batch Log
    public static String getException(Database.SaveResult[] saveresultList){
        Boolean hasFailed = false; 
        String localExcep = '';//ES20-14015 
        for(Database.SaveResult dsr : saveresultList){
            if(dsr.getErrors() != null && dsr.getErrors().size() > 0){
                hasFailed = true;
                localExcep+= dsr.getId()+'- '+dsr.errors+' ,';
            }
        }
        return localExcep;
    }
    //method added to store error records in Country Batch Log while Deleting
    public static String getException(Database.DeleteResult[] saveresultList){
        Boolean hasFailed = false; 
        String localExcep = '';
        for(Database.DeleteResult dsr : saveresultList){
            if(dsr.getErrors() != null && dsr.getErrors().size() > 0){
                hasFailed = true;
                localExcep+= dsr.getId()+'- '+dsr.errors+' ,';
            }
        }
		return localExcep;
    }
    /** 
    * @description: updateATL
    * @purpose: The method takes List of Activity Target List Ids to update or delete and performs the dml.
    * @parameters: Set<Id>,Set<Id>
    */
    public static String updateATL(Set<Id> updateActTLList, Set<Id> deleteActTLList){
        List<Activity_Target_List__c> actTLListUpdate= new list<Activity_Target_List__c>();
        List<Activity_Target_List__c> actTLListDelete= new list<Activity_Target_List__c>();
        String exceptionMsg='';
        for(Id aTL:updateActTLList){
            Activity_Target_List__c atlUp=new Activity_Target_List__c(Id=aTL);
            atlUp.Status__c='Active';
            actTLListUpdate.add(atlUp);
        }
        for(Id aTL:deleteActTLList){
            Activity_Target_List__c atlUp=new Activity_Target_List__c(Id=aTL);
            actTLListDelete.add(atlUp);
        }
        if(actTLListUpdate!=null && !actTLListUpdate.isEmpty() && Schema.sObjectType.Activity_Target_List__c.isUpdateable()){
            Database.SaveResult[] upRes=Database.update(actTLListUpdate,false);
            exceptionMsg+=getException(upRes);
        }
        if(actTLListDelete!=null && !actTLListDelete.isEmpty() && Schema.sObjectType.Activity_Target_List__c.isDeletable()){
            Database.DeleteResult[] delRes=Database.delete(actTLListDelete,false);
            exceptionMsg+=getException(delRes);
        }
        return exceptionMsg;
    }
    
}