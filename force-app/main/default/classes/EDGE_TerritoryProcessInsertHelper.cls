/*
* Class Name: EDGE_TerritoryProcessInsertHelper
* Test Class: EDGE_TerritoryProcessRepBatchTest & EDGE_TerritoryProcessInsertExtHelperTest
* Author: 
* Brief Description: This class is helper class for EDGE_TerritoryProcessRepInsertBatch.
* Created Date: 20/06/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0			    Suvendu Roy		    20/06/2024			154642 - Helper Class for inserting outlet reps
* 2.0               Joshraj Sen         28/06/2024          154642 - Fixed the SCA ApexDoc
*/
/**
 * @description Helper of EDGE_TerritoryProcessRepInsertBatch
*/
public with sharing class EDGE_TerritoryProcessInsertHelper {
    //Assignment
    final static String SALESRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String QUALITYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();  
    final static String ACTIVATIONRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); 
    //static Set<Id> outletIdSet;
    
    /**
     * @ADO Number : 154642
     * @Name : getUserRoleMap
	 * @description : This method to return map of Mapping_Account_Team_and_Outlet_Member__mdt.
     * @return Map<string,Mapping_Account_Team_and_Outlet_Member__mdt>
	 */
    public static Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> getUserRoleMap() {
        Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap = new Map<string,Mapping_Account_Team_and_Outlet_Member__mdt>();
        //Get Metadata for Role Mapping ES20-9768
        for(Mapping_Account_Team_and_Outlet_Member__mdt cusData : [Select id,Account_Team_Role__c,Global_Equivalent_Role__c, Outlet_Member_Role__c from Mapping_Account_Team_and_Outlet_Member__mdt WITH SECURITY_ENFORCED] ){
            if(!userRoleMap.containsKey(cusData.Global_Equivalent_Role__c)){
                userRoleMap.put(cusData.Global_Equivalent_Role__c,cusData);
            }
        }
        return userRoleMap;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getCombinedWrapper
	 * @description : This method to return EDGE_BatchSObjectCombinedWrapper to the batch class.
	 * This method puts together all the major maps and sets like userBusinessRoleMap,territoryMap, territoryIdSet etc.
	 * and put in the EDGE_BatchSObjectCombinedWrapper. These are used throughout all the batch methods
     * @return EDGE_BatchSObjectCombinedWrapper
     * @param terrMemList
	 */
    public static EDGE_BatchSObjectCombinedWrapper getCombinedWrapper(List<Territory_Member__c> terrMemList) {
        EDGE_BatchSObjectCombinedWrapper combinedWraapper = new EDGE_BatchSObjectCombinedWrapper();
        Set<Id> territoryIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        
        for(Territory_Member__c terrMem : terrMemList){
            territoryIdSet.add(terrMem.Territory__c);
            userIdSet.add(terrMem.User__c);
        }
        combinedWraapper.territoryIdSet = territoryIdSet;
        combinedWraapper.userIdSet = userIdSet;
        combinedWraapper.userBusinessRoleMap = getUserBusinessRoleMap(userIdSet);
        combinedWraapper.territoryMap = getTerritoryMap(territoryIdSet);
        getTerritoryOutletMap(combinedWraapper);
        combinedWraapper.existingOutletMemMap = getExistingOutletMemMap(userIdSet, combinedWraapper.outletIdSet);
        return combinedWraapper;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getUserBusinessRoleMap
	 * @description : This method to return map of UserBusinessRole to getCombinedWrapper method.
     * @return Map<id,String>
     * @param userIdSet
	 */
    public static Map<id,String> getUserBusinessRoleMap(Set<Id> userIdSet) {
        Map<id,String> userBusinessRoleMap = new Map<id,String>();
        for(User_Business_Role__c userRole : [Select id, User__c, Business_Role__c,Business_Role__r.Global_Equivalent__c from User_Business_Role__c where User__c IN:userIdSet WITH SECURITY_ENFORCED]){
            if(!userBusinessRoleMap.containsKey(userRole.User__c)){
                if(userRole.Business_Role__c != null){
                    userBusinessRoleMap.put(userRole.User__c,userRole.Business_Role__r.Global_Equivalent__c);
                }
            }
        }
        return userBusinessRoleMap;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getTerritoryMap
	 * @description : This method to return map of Territory to getCombinedWrapper method.
     * @return Map<id,Territory__c>
     * @param territoryIdSet
	 */
    public static Map<id,Territory__c> getTerritoryMap(Set<Id> territoryIdSet) {
        Map<id,Territory__c> territoryMap = new Map<id,Territory__c>();
        // Get Territory Map for getting Territory Type ES20-9768
        for(Territory__c terrRec : [select Id, RecordTypeId, RecordType.Name from Territory__c where id in :territoryIdSet WITH SECURITY_ENFORCED]){
            if(!territoryMap.containsKey(terrRec.id)){
                territoryMap.put(terrRec.id, terrRec);
            }
        }
        return territoryMap;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getTerritoryOutletMap
	 * @description  This method to return map of Outlet Territory to getCombinedWrapper method.
	 * returns Map : key -> Territory Id, Value -> List of outlet ids under that outlet
	 * outletIdSet -> List of all outetlets under the territory records in the context of the batch
     * @param combinedWraapper
	 */
    public static void getTerritoryOutletMap(EDGE_BatchSObjectCombinedWrapper combinedWraapper) {
        Map<Id, List<Id>> territoryOutletMap = new Map<Id, List<Id>>();
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> territoryIdSet = combinedWraapper.territoryIdSet;
        for(Outlet_Territory__c outTerr : [Select Id, Active__c, Outlet__c, Territory__c, Outlet__r.OwnerId from Outlet_Territory__c 
                                           WHERE Territory__c in :territoryIdSet AND 
                                           (Active__c =:EDGE_Constant.WAITING_ACTIVATION OR Active__c =:EDGE_Constant.ACTIVE) WITH SECURITY_ENFORCED]){
                                               outletIdSet.add(outTerr.Outlet__c);
                                               //Create Territory & Outlet Map
                                               if(territoryOutletMap.containsKey(outTerr.Territory__c)){
                                                   List<Id> tempList = territoryOutletMap.get(outTerr.Territory__c);
                                                   tempList.add(outTerr.Outlet__c);
                                                   territoryOutletMap.put(outTerr.Territory__c, tempList);
                                               }else{
                                                   territoryOutletMap.put(outTerr.Territory__c, new List<Id>{outTerr.Outlet__c});
                                               }
                                           }
        combinedWraapper.territoryOutletMap = territoryOutletMap;
        combinedWraapper.outletIdSet = outletIdSet;
        //return combinedWraapper;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getExistingOutletMemMap
	 * @description : This method to return map of Outlet Member to getCombinedWrapper method.
     * @return Map<String, Outlet_Member__c>
     * @param userIdSet
     * @param outletIdSet
	 */
    public static Map<String, Outlet_Member__c> getExistingOutletMemMap(Set<Id> userIdSet, Set<Id> outletIdSet){
        Map<String, Outlet_Member__c> existingOutletMemMap  = new Map<String, Outlet_Member__c>();
        for(Outlet_Member__c outMem : [Select Id, Flag_For_Deletion__c, User__c, User__r.Default_Country__c, Outlet__c, Outlet_Role__c,Temporary_Assigned__c,Pending_for_Rep_Insert_Batch__c from Outlet_Member__c 
                                       WHERE Outlet__c in :outletIdSet AND User__c =: userIdSet WITH SECURITY_ENFORCED]){//ES20-13483
                                           existingOutletMemMap.put(outMem.User__c+'_'+outMem.Outlet__c, outMem);
                                       }
        return existingOutletMemMap;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getUserTerritoryMemberMap
	 * @description  This method to return map of Territory Member to the batch class.
	 * userTerritoryMemberMap : key -> userId + '_' + outletId, Value : List of territory members
     * @return Map<String, List<Territory_Member__c>>
     * @param terrMem 
     * @param territoryOutletMap
	 */
    public static Map<String, List<Territory_Member__c>> getUserTerritoryMemberMap(Territory_Member__c terrMem , Map<Id, List<Id>> territoryOutletMap) {
        Map<String, List<Territory_Member__c>> userTerritoryMemberMap = new Map<String, List<Territory_Member__c>>();
        Id userId = terrMem.User__c;
        Id territoryId = terrMem.Territory__c;
        if(!territoryOutletMap.isEmpty() && territoryOutletMap.containsKey(territoryId)){
            //List<Id> outletIdList = territoryOutletMap.get(territoryId);
            for(Id outletId : territoryOutletMap.get(territoryId)){
                string key = userId + '_' + outletId;
                if(userTerritoryMemberMap.containsKey(key)){
                    List<Territory_Member__c> tempTMList = userTerritoryMemberMap.get(key);
                    tempTMList.add(terrMem);
                    userTerritoryMemberMap.put(key, tempTMList);
                }else{
                    userTerritoryMemberMap.put(key, new List<Territory_Member__c>{terrMem});
                }                
            }
        }
        return userTerritoryMemberMap;
    }
    

}