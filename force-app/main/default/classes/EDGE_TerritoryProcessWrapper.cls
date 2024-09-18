/*
* @description :  EDGE_TerritoryProcessWrapper
* @purpose : This is the Wrapper for EDGE_TerritoryProcessStatusUpdateHelper
* @history :
* Version    Developer         		Date           			User Story/Purpose
	1.0		Dipanjan Das		24.06.2024			154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
*/

/**
* @description Wrapper class for EDGE_TerritoryProcessStatusUpdateBatch
*/

public class EDGE_TerritoryProcessWrapper {
    /**
     * @description Map of User and Region of Sales type
     * @return Map<Id,Id>
     */
	Public Map<Id,Id> salesTerrRepMap {get;set;}
      /**
     * @description Map of User and Region of Activation type
     * @return Map<Id,Id>
     */
	Public Map<Id,Id> activationRepMemberMap {get;set;}
     /**
     * @description Map of User and Region of Quality type
     * @return Map<Id,Id>
     */

	Public Map<Id, String> dispenseRepMemberMap {get;set;}
    /**
     * @description List of User and Region of for Traxe
     * @return List<Trax_User_Update__c>
     */
	Public List<Trax_User_Update__c> traxUserUpdate {get;set;}
}