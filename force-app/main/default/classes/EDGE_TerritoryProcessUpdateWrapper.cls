/*
* @description :  EDGE_TerritoryProcessUpdateWrapper
* @purpose : This is the Wrapper for EDGE_TerritoryProcessStatusUpdateHelper & EDGE_TerritoryProcessStatusUpdateHlpExtn
* @history :
* Version    Developer         		Date           			User Story/Purpose
	1.0		Dipanjan Das & Sudipta Nandy		24.06.2024			154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
*/

/**
* @description Wrapper class for EDGE_TerritoryProcessStatusUpdateBatch
*/

public class EDGE_TerritoryProcessUpdateWrapper {
      /**
     * @description List of Account
     * @return List<Account>
     */
	Public List<Account> outletsToUpdateList {get;set;}
     /**
     * @description List of Account for Activation details
     * @return List<Account>
     */
	Public List<Account> activationTerrAccListToUpdate {get;set;}
     /**
     * @description List of Account for quality details
     * @return List<Account>
     */
	Public List<Account> dispenseRepAccListToUpdate {get;set;}
    /**
     * @description List of territory
     * @return List<Territory__c>
     */
	Public List<Territory__c> territoryListtoUpdate {get;set;}
    /**
     * @description outletWithRegionListMapToShare
     * @return Map<Id,List<Id>>
     */
	Public Map<Id, List<Id>> outletWithRegionListMapToShare {get;set;}
    /**
     * @description outletWithRegionListMapToRemove
     * @return Map<Id,List<Id>>
     */
	Public Map<Id, List<Id>> outletWithRegionListMapToRemove {get;set;}
     /**
     * @description List of o-t of waiting activation
     * @return List<Outlet_Territory__c>
     */
	Public List<Outlet_Territory__c> updateOTList {get;set;}
     /**
     * @description List of o-t of waiting removal
     * @return List<Outlet_Territory__c>
     */
	Public List<Outlet_Territory__c> deleteOTList {get;set;}
}