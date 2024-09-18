/*
* @description :  EDGE_TerrProcessStatusUpdateOperations

* @purpose : This is the Extended Helper class for the batch class EDGE_TerritoryProcessStatusUpdateBatch & EDGE_TerritoryProcessStatusUpdateHelper

* @Test Class: EDGE_TerritoryProcessStUpdateBatchTest 

* @history :

* Version    Developer         		Date           			User Story/Purpose
1.0		Dipanjan Das		24.06.2024			154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
1.0		Sudipta Nandy		24.06.2024			154640 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
*/

/**
* @description Extended class for EDGE_TerritoryProcessStatusUpdateBatch
*/

public without sharing class EDGE_TerrProcessStatusUpdateOperations {
    /** 
* @description  Update Territory List
* @return Database.SaveResult[]
* @param territoryListtoUpdate
**/
    public Database.SaveResult[] territoryOperations(List<Territory__c>territoryListtoUpdate){
        Database.SaveResult[] saveTerritoryResList = new Database.SaveResult[]{};
            if(territoryListtoUpdate != null && territoryListtoUpdate.size() > 0){
                saveTerritoryResList = Database.update(territoryListtoUpdate, false);		
            }
        return saveTerritoryResList;
    }
    
    /** 
* @description  Update Outlet List
* @return Database.SaveResult[]
* @param sObjectUpdateWrap
**/
    public Database.SaveResult[] outletOperations(EDGE_TerritoryProcessUpdateWrapper sObjectUpdateWrap){
        Map<Id,Account> outletsMapToUpdate = new Map<Id,Account>();
        outletsMapToUpdate = EDGE_TerritoryProcessStatusUpdateHlpExtn.getOutletMapToUpdate(sObjectUpdateWrap);
        Database.SaveResult[] saveAccountResList = new Database.SaveResult[]{};
            if(outletsMapToUpdate.values()!=null &&  outletsMapToUpdate.Values().size()>0){
                saveAccountResList = Database.update(outletsMapToUpdate.Values(),false);
            }
        return saveAccountResList;
    }
    
    /** 
* @description  Update Outlet-territory List
* @return Database.SaveResult[]
* @param updateOTList
**/
    
    public Database.SaveResult[] updateOutletTerirtoryOperations(List<Outlet_Territory__c> updateOTList){
        Database.SaveResult[] saveOTResList = new Database.SaveResult[]{};
            if(updateOTList.size()>0){
                saveOTResList = Database.update(updateOTList,false); 
            }
        return saveOTResList;
    }
    
     /** 
* @description  Delete Outlet-Territory List
* @return Database.DeleteResult[]
* @param deleteOTList
**/
    public Database.DeleteResult[] deleteOutletTerirtoryOperations(List<Outlet_Territory__c> deleteOTList){
        Database.DeleteResult[] saveOTDelResList = new Database.DeleteResult[]{};
            if(deleteOTList.size()>0){
                saveOTDelResList = Database.delete(deleteOTList, false);
            } 
        return saveOTDelResList;
    }
    
  /** 
* @description  Remove Sales Manager
* @return Database.DeleteResult[]
* @param salesManToRemove
**/
    public Database.DeleteResult[] salesManagerRemoval(List<AccountTeamMember> salesManToRemove){
        Database.DeleteResult[] saveaccManRemList = new Database.DeleteResult[]{};
            if(salesManToRemove != Null && salesManToRemove.size()>0){ //ES20-14015 
                saveaccManRemList = Database.delete(salesManToRemove, false);
            }
        return saveaccManRemList;
    }
    
  /** 
* @description  Addition of Sales Manager
* @return Database.UpsertResult[]
* @param salesManToAdd
**/
    public Database.UpsertResult[] salesManagerAddition(List<AccountTeamMember> salesManToAdd){
        Database.UpsertResult[] saveaccManAddList = new Database.UpsertResult[]{};
            if(salesManToAdd != Null && salesManToAdd.size()>0){ //ES20-14015 
                saveaccManAddList = Database.upsert(salesManToAdd,false);
            }
        return saveaccManAddList;
    }
}