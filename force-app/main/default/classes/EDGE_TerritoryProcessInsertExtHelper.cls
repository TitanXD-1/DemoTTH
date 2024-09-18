/*
* Class Name: EDGE_TerritoryProcessInsertExtHelper
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
 * @description Acts as Extended Helper for EDGE_TerritoryProcessRepInsertBatch
*/
public class EDGE_TerritoryProcessInsertExtHelper {
    //Assignment
    final static String SALESRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String QUALITYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();  
    final static String ACTIVATIONRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); 
    
    /**
     * @ADO Number : 154642
     * @Name : getWrapperRecordsAndTraxUsers
	 * @description : This method to return values EDGE_BatchSObjectWrapper List and TraxUserUpdate List to the batch class as a EDGE_BatchSObjectOutputWrapper
     * @return EDGE_BatchSObjectOutputWrapper
     * @param combinedWraapper
     * @param userTerritoryMemberMap
	 */
    public static EDGE_BatchSObjectOutputWrapper getWrapperRecordsAndTraxUsers(EDGE_BatchSObjectCombinedWrapper combinedWraapper,Map<String, List<Territory_Member__c>> userTerritoryMemberMap){
        EDGE_BatchSObjectOutputWrapper returnWrapper = new EDGE_BatchSObjectOutputWrapper();
        returnWrapper.wrapperRecords = new List<EDGE_BatchSObjectWrapper>();
        returnWrapper.traxUserUpdate = new List<Trax_User_Update__c>();
        returnWrapper.uniOutletTeamMap = new Map<String , Outlet_Member__c>();
        Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap  = EDGE_TerritoryProcessInsertHelper.getUserRoleMap();
        Map<String, Outlet_Member__c> existingOutletMemMap  = combinedWraapper.existingOutletMemMap;
        List<EDGE_BatchSObjectWrapper> wrapperRecords = new List<EDGE_BatchSObjectWrapper>();
        //Iterating over userOuletMap (This map contains for which outlet sales rep need access)
        for(String userOuletKey :  userTerritoryMemberMap.Keyset()){
            
            List<Territory_Member__c> terrMemberList = userTerritoryMemberMap.get(userOuletKey);
            Id outletId = userOuletKey.split('_').get(1);
            
            for(Territory_Member__c terrMem : terrMemberList){
                EDGE_BatchSObjectWrapper batchWrapper = new EDGE_BatchSObjectWrapper();
                EDGE_BatchSObjectSecondWrapper secondWrapper = new EDGE_BatchSObjectSecondWrapper();
                secondWrapper.userRoleMap = userRoleMap;
                secondWrapper.terrMem = terrMem;
                secondWrapper.userOuletKey = userOuletKey;
                secondWrapper.outletId = outletId;
                
                //Insert 1st Method
                //check already present in database
                if(existingOutletMemMap != null && existingOutletMemMap.containskey(userOuletKey)){
                    batchWrapper = getWrapperRecordsforExistingTerritoryWithOutletMember(combinedWraapper, userTerritoryMemberMap, secondWrapper);
                }else if(terrMem.End_Date__c == null || (terrMem.End_Date__c != null && terrMem.End_Date__c > Date.today())){
                    getOutputWrapperForTerritoriesWithOutOutletMember(combinedWraapper, secondWrapper, returnWrapper);
                }
                if(batchWrapper.recordToProcess!=null){
                    returnWrapper.wrapperRecords.add(batchWrapper);
                }
                
            }
        }
        return returnWrapper;
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getWrapperRecordsforExistingTerritoryWithOutletMember
	 * @description : This method to return Outlet Member WrapperRecords getWrapperRecordsAndTraxUsers for existing territories.
     * @return EDGE_BatchSObjectWrapper 
     * @param combinedWraapper
     * @param userTerritoryMemberMap
     * @param secondWrapper
	 */
    public static EDGE_BatchSObjectWrapper getWrapperRecordsforExistingTerritoryWithOutletMember(EDGE_BatchSObjectCombinedWrapper combinedWraapper,Map<String, List<Territory_Member__c>> userTerritoryMemberMap, EDGE_BatchSObjectSecondWrapper secondWrapper){
        Date yesterdayDate = Date.today().addDays(-1);
        //Need to Input
        Map<String, Outlet_Member__c> existingOutletMemMap  = combinedWraapper.existingOutletMemMap;
        Map<Id,Territory__c> territoryMap = combinedWraapper.territoryMap;
        Map<id,String> userBusinessRoleMap = combinedWraapper.userBusinessRoleMap;
        Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap  = secondWrapper.userRoleMap;
        String userOuletKey  = secondWrapper.userOuletKey;
        Territory_Member__c terrMem = secondWrapper.terrMem;
        EDGE_BatchSObjectWrapper wrapperRecord = new EDGE_BatchSObjectWrapper();
        Boolean isDelete = terrMem.End_Date__c == yesterdayDate;
        
        Outlet_Member__c om = existingOutletMemMap.get(userOuletKey);
        //If Outlet Member's Flag For Deletion marked as true from TerritoryProcessRepDeleteBatch, update Flag For Deletion & Outlet Role
        Boolean firstCheck = om.Flag_For_Deletion__c == true && !isDelete;
        //If the new Territory Member is Primary and the existing Territory Member was present in database as Secondary,change the existing outlet member's role as primary     
        Boolean secondCheck = territoryMap.get(terrMem.Territory__c).RecordTypeId != null && territoryMap.get(terrMem.Territory__c).RecordTypeId != ACTIVATIONRECORDTYPEID && om.Flag_For_Deletion__c == false &&  om.Outlet_Role__c == 'Secondary' && terrMem.Type__c == 'Primary';
        if(firstCheck || secondCheck){
            om.Flag_For_Deletion__c = firstCheck? false:om.Flag_For_Deletion__c;
            //territoryMap, terrMem, userRoleMap, userBusinessRoleMap,om
            EDGE_BatchSObjectChildWrapper childWrapper = new EDGE_BatchSObjectChildWrapper();
            childWrapper.territoryMap = territoryMap;
            childWrapper.terrMem = terrMem;
            childWrapper.userBusinessRoleMap = userBusinessRoleMap;
            childWrapper.userRoleMap = userRoleMap;
            
            om.Outlet_Role__c = getOutletRoleForTerritoryWithOM(childWrapper);
            wrapperRecord = (outletMemberWrapper(om,'Update'));//ES20-13681
        }
        //ES20-13681 for checking Temporary Assigned in Quality Territory
        else if(territoryMap.get(terrMem.Territory__c).RecordTypeId != null && territoryMap.get(terrMem.Territory__c).RecordTypeId == QUALITYRECORDTYPEID && om.Temporary_Assigned__c){
            wrapperRecord = (outletMemberWrapper(om,'Update'));
        }
        return wrapperRecord;
    }
    
    
    /**
     * @ADO Number : 154642
     * @Name : getOutputWrapperForTerritoriesWithOutOutletMember
	 * @description : This method to return Outlet Member WrapperRecords and Trax user update list as EDGE_BatchSObjectOutputWrapper to getWrapperRecordsAndTraxUsers for territories without OutletMembers.
     * @param combinedWraapper
     * @param secondWrapper
     * @param returnWrapper
	 */
     static void getOutputWrapperForTerritoriesWithOutOutletMember(EDGE_BatchSObjectCombinedWrapper combinedWraapper, EDGE_BatchSObjectSecondWrapper secondWrapper, EDGE_BatchSObjectOutputWrapper returnWrapper){
        
        Map<Id,Territory__c> territoryMap = combinedWraapper.territoryMap;
        Map<id,String> userBusinessRoleMap = combinedWraapper.userBusinessRoleMap;
        Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap  = secondWrapper.userRoleMap;
        Territory_Member__c terrMem = secondWrapper.terrMem;
        Id outletId = secondWrapper.outletId;
        EDGE_BatchSObjectWrapper batchWrapper = new EDGE_BatchSObjectWrapper();
        //Map<String, Outlet_Member__c> uniOutletTeamMap  = new Map<String , Outlet_Member__c>();        
        
        Outlet_Member__c outMem = new Outlet_Member__c();
        outMem.Outlet__c = outletId;
        outMem.User__c = terrMem.User__c;

        EDGE_BatchSObjectChildWrapper childWrapper = new EDGE_BatchSObjectChildWrapper();
        childWrapper.territoryMap = territoryMap;
        childWrapper.terrMem = terrMem;
        childWrapper.userBusinessRoleMap = userBusinessRoleMap;
        childWrapper.userRoleMap = userRoleMap;
        
        outMem.Outlet_Role__c = getOutletRoleForTerritoryWithOutOM(childWrapper);
        outMem.OutletUser__c = terrMem.User__c + '-' + outletId;
        System.debug(LoggingLevel.Debug,'outMem: '+outMem);
        //If a same outlet is associated with two Territories where same member is present as Primary and Secondary.Outlet Member's Role should be set as Primary
        Boolean firstCheck = returnWrapper.uniOutletTeamMap.get(outMem.OutletUser__c)!= null && terrMem.Type__c == 'Primary' && territoryMap != null && territoryMap.Size()> 0;
        if(firstCheck){
            returnWrapper.uniOutletTeamMap.get(outMem.OutletUser__c).Outlet_Role__c =territoryMap.get(terrMem.Territory__c).RecordTypeId == SALESRECORDTYPEID ? terrMem.Type__c : userRoleMap.get(userBusinessRoleMap.get(terrMem.User__c)).Outlet_Member_Role__c;//'Primary';
            returnWrapper.uniOutletTeamMap.get(outMem.OutletUser__c).Pending_for_Rep_Insert_Batch__c = true; //ES20-9804
        }
        else{
            outMem.Pending_for_Rep_Insert_Batch__c = true; //ES20-9804
            returnWrapper.uniOutletTeamMap.put(outMem.OutletUser__c, outMem);
        }
        System.debug(LoggingLevel.Debug,'uniOutletTeamMap: '+returnWrapper.uniOutletTeamMap);
        batchWrapper.operationType = 'Insert';
        batchWrapper.recordToProcess = outMem;
        
        returnWrapper.wrapperRecords.add(batchWrapper);
        
        String countryCode = EDGE_BatchUtilityClass.getUserCountryCode(terrMem.User__r.Default_Country__c, terrMem.User__r.Available_Countries__c);
        Boolean traxCheck = terrMem.User__r.Trax_User__c && null != terrMem.User__c &&countryCode != null && countryCode != '';
        if(traxCheck){
            returnWrapper.traxUserUpdate.add(new Trax_User_Update__c(name=terrMem.User__c,Country_Code__c=countryCode));    
        }
    }
    
    /**
     * @ADO Number : 154642
     * @Name : getOutletRoleForTerritoryWithOM
	 * @description : This method to return Existing Outlet Member's Outlet Role to update
     * @return String
     * @param childWrapper
	 */
     static String getOutletRoleForTerritoryWithOM(EDGE_BatchSObjectChildWrapper childWrapper){
        String outletRole = '';
        if(childWrapper.territoryMap != null && childWrapper.territoryMap.Size()> 0){
            //string recordId = childWrapper.territoryMap.get(childWrapper.terrMem.Territory__c).RecordTypeId == null ? '' : childWrapper.territoryMap.get(childWrapper.terrMem.Territory__c).RecordTypeId;
            
            if(childWrapper.userBusinessRoleMap.get(childWrapper.terrMem.User__c)!=null && childWrapper.userRoleMap.get(childWrapper.userBusinessRoleMap.get(childWrapper.terrMem.User__c)) != null){
                outletRole = childWrapper.userRoleMap.get(childWrapper.userBusinessRoleMap.get(childWrapper.terrMem.User__c)).Outlet_Member_Role__c;   
            }
            if(childWrapper.territoryMap.get(childWrapper.terrMem.Territory__c).RecordTypeId != null){
                outletRole = childWrapper.territoryMap.get(childWrapper.terrMem.Territory__c).RecordTypeId == SALESRECORDTYPEID ? childWrapper.terrMem.Type__c : outletRole; 
            }
        } 
        return outletRole;
    }  
    
    /**
     * @ADO Number : 154642
     * @Name : getOutletRoleForTerritoryWithOutOM
	 * @description : This method to return new Outlet Member's Outlet Role to Insert
     * @param  childWrapper
     * @return  String
	 */
   static String getOutletRoleForTerritoryWithOutOM(EDGE_BatchSObjectChildWrapper childWrapper){
        String outletRole = '';
        if(childWrapper.territoryMap != null && childWrapper.territoryMap.Size()> 0 && 
           childWrapper.territoryMap.get(childWrapper.terrMem.Territory__c).RecordTypeId != null && 
           childWrapper.userRoleMap != null && 
           childWrapper.userBusinessRoleMap.get(childWrapper.terrMem.User__c) != null){
               if(childWrapper.territoryMap.get(childWrapper.terrMem.Territory__c).RecordTypeId != SALESRECORDTYPEID && 
                      childWrapper.userRoleMap.get(childWrapper.userBusinessRoleMap.get(childWrapper.terrMem.User__c)).Outlet_Member_Role__c!=null){
                      outletRole = childWrapper.userRoleMap.get(childWrapper.userBusinessRoleMap.get(childWrapper.terrMem.User__c)).Outlet_Member_Role__c; //ES20-12216,12231,12213 -> for Quality & AT 
                  }else{
                      outletRole = childWrapper.terrMem.Type__c; ////ES20-12216,12231,12213 ->  for Sales
                  }
           }
        return outletRole;
    } 
    
    /**
     * @ADO Number : 154642
     * @Name : outletMemberWrapper
	 * @description : This method is to create Outlet Members  wrapper records for calling the next batch.
     * @param  om
     * @param  type
     * @return EDGE_BatchSObjectWrapper
	 */
    public static EDGE_BatchSObjectWrapper outletMemberWrapper(Outlet_Member__c om,String type){
        EDGE_BatchSObjectWrapper batchWrapper = new EDGE_BatchSObjectWrapper();
        om.Pending_for_Rep_Insert_Batch__c = true; 
        om.Temporary_Assigned__c = false;
        batchWrapper.operationType = type;
        batchWrapper.recordToProcess = om;
        return batchWrapper;
    }
    /**
     * @ADO Number : 154642
     * @Name : EDGE_BatchSObjectSecondWrapper
	 * @description : This Wrapper class to send values to getOutletRoleForTerritoryWithOutOM & getOutletRoleForTerritoryWithOM method.
	 */
    class EDGE_BatchSObjectSecondWrapper {
         /**
     * @description User Role Map
     * @return Map<string,Mapping_Account_Team_and_Outlet_Member__mdt>
     */
        public Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap{get;set;}
          /**
     * @description Territory Member Details
     * @return Territory_Member__c
     */
        public Territory_Member__c terrMem{get;set;}
        /**
     * @description user Outlet Composite Key
     * @return String
     */
        public String userOuletKey{get;set;}
          /**
     * @description Outlet Id
     * @return Id
     */
        public Id outletId{get;set;}
    }
    
    /**
     * @ADO Number : 154642
     * @Name : EDGE_BatchSObjectChildWrapper
	 * @description : This Wrapper class is being used in this same class to return values from getOutletRoleForTerritoryWithOutOM & getOutletRoleForTerritoryWithOM method.
	 */
    //territoryMap, terrMem, userRoleMap, userBusinessRoleMap
     class EDGE_BatchSObjectChildWrapper {
         /**
     * @description User Role Map
     * @return Map<string,Mapping_Account_Team_and_Outlet_Member__mdt>
     */
        public Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap{get;set;}
         /**
     * @description Territory Member Details
     * @return Territory_Member__c
     */
        public Territory_Member__c terrMem{get;set;}
         /**
     * @description Set of User Business Role Details
     * @return Map<id,String>
     */
        public Map<id,String> userBusinessRoleMap{get;set;}
          /**
     * @description Set of Territory Details
     * @return Map<Id,Territory__c> 
     */
        public Map<Id,Territory__c> territoryMap{get;set;}
    }
}