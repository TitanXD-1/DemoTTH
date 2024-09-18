/**

* @Description: Edge_UpdateCTSuggestedUserBatchHelper

* @Purpose: Helper class for Update Case Task Suggested User on Primay user JML

* @VERSION     AUTHOR          DATE            DETAIL

*   1.1       Sudipta     25/01/2022       ES20-11823

*   1.2       Anamika     12/02/2022       ES20-12029
*   1.3       Monalisa Halder     	29/04/2022       					ES20-12520
*/ 
public class Edge_UpdateCTSuggestedUserBatchHelper {
    
    public static Map<Id,Case_Task__c>  processCaseTaskSuggestedUser(List<Case_Task__c> caseTaskList, Boolean isLineCleaningBatch){ 

        Map<Id,Case_Task__c> caseTaskToUpdate = new Map<Id,Case_Task__c>();
        Set<Id> accounIds = new Set<Id>();
        Set<Id> caseTaskType = new Set<Id>();
        for(Case_Task__c caseTaskobj:caseTaskList){
            if(caseTaskobj.Account__c != null && caseTaskobj.Case_Task_Type__c !=null){
                accounIds.add(caseTaskobj.Account__c);
                caseTaskType.add(caseTaskobj.Case_Task_Type__c);
            }
        }
        Map<Id, String> caseTaskTypeRole = new Map<Id, String>();
        if(caseTaskType.size() > 0 && !caseTaskType.isEmpty()){
            for(Quality_Case_Configuration__c caseTaskTypeName :[SELECT Id,Name,Default_Business_Role__c from Quality_Case_Configuration__c WHERE Id IN:caseTaskType]){
                caseTaskTypeRole.put(caseTaskTypeName.Id, caseTaskTypeName.Default_Business_Role__c);
            }
        }
        Map<Id,List<Id>> outletToTerritoryMap = new Map<Id,List<Id>>();
        Map<String,Id> terrToUserMap = new Map<String,Id>();
        Map<String,String> userToRoleMap = new Map<String,String>();
        Set<Id> terrIds = new Set<Id>();
        List<Id> userIds = new List<Id>();
        for(Outlet_Territory__c outletTerr :[SELECT Id,Name,Outlet__c, Territory__c from Outlet_Territory__c WHERE Outlet__c IN:accounIds and Active__c=:EDGE_Constant.ACTIVE]){
            terrIds.add(outletTerr.Territory__c);
            if(outletToTerritoryMap.containsKey(outletTerr.outlet__c)){
                outletToTerritoryMap.get(outletTerr.outlet__c).add(outletTerr.Territory__c);
            }
            else{
                outletToTerritoryMap.put(outletTerr.outlet__c, new List<Id>{outletTerr.Territory__c});
            }
        }
        if(terrIds != null && terrIds.size()>0){
            for(Territory__c terrInfo :[SELECT Id,Primary_Sales_Rep__c from Territory__c where Id IN :terrIds]){
                if(terrInfo.Primary_Sales_Rep__c !=null){
                    terrToUserMap.put(terrInfo.Id, terrInfo.Primary_Sales_Rep__c);
                }
            }
        }
        if(terrToUserMap != null && terrToUserMap.values().size() >0){
            for(User_Business_Role__c userRole : [Select Id, User__c,Business_Role__r.Global_Equivalent__c from User_Business_Role__c 
                                                  where User__c IN : terrToUserMap.values()])
            {
                userToRoleMap.put(userRole.User__c, userRole.Business_Role__r.Global_Equivalent__c);
            }
        }
        //joiner, mover, leaver scenarios
        for(Case_Task__c caseTaskRec: caseTaskList){
            if(outletToTerritoryMap.containsKey(caseTaskRec.Account__c)){
                String defaultRole = caseTaskTypeRole.get(caseTaskRec.Case_Task_Type__c);
                List<Id> territories = outletToTerritoryMap.get(caseTaskRec.Account__c);
                for(Id ter : territories){
                    if(terrToUserMap.containsKey(ter)){//territory exists default role matches with primary rep business role(joiner,mover)
                        String userId = terrToUserMap.get(ter);                            
                        if(userToRoleMap.containsKey (userId) && defaultRole == userToRoleMap.get(userId)){

                            if(isLineCleaningBatch){
                                if(caseTaskRec.User_Assigned_To__c == null || (caseTaskRec.User_Assigned_To__c != null && caseTaskRec.User_Assigned_To__c != userId)){
                                    // if matching user already exists in the record, not updating it again
                                    caseTaskRec.User_Assigned_To__c = userId;
                                    caseTaskToUpdate.put(caseTaskRec.Id,caseTaskRec);
                                    break;
                                }
                                else{
                                    break;
                                }
                            }
                            else{

                            if(caseTaskRec.Suggested_User__c == null || (caseTaskRec.Suggested_User__c != null && caseTaskRec.Suggested_User__c != userId)){
                                // if matching user already exists in the record, not updating it again
                                caseTaskRec.Suggested_User__c = userId;
                                caseTaskToUpdate.put(caseTaskRec.Id,caseTaskRec);
                                break;
                            }
                            else{
                                break;
                            }
                        }

                            
                        }
                        else{//territory exists but business role of primary rep doesnt match with default role
                            if(isLineCleaningBatch){
                                caseTaskRec.User_Assigned_To__c = null;
                            }
                            else{
                                caseTaskRec.Suggested_User__c = null;
                            }

                            caseTaskToUpdate.put(caseTaskRec.Id,caseTaskRec);
                        }
                    }
                    else{// if there is no primary rep for the territory : leaver

                        if(isLineCleaningBatch){
                            caseTaskRec.User_Assigned_To__c = null;
                        }
                        else{
                            caseTaskRec.Suggested_User__c = null;
                        }

                        caseTaskToUpdate.put(caseTaskRec.Id,caseTaskRec);
                    }
                }
            }else {//ES20-12520 - else block
                if(caseTaskRec.Suggested_User__c != null){
                   caseTaskRec.Suggested_User__c = null; 
                }
                caseTaskToUpdate.put(caseTaskRec.Id,caseTaskRec);
            }
        }
        return caseTaskToUpdate;
    }  
    
}