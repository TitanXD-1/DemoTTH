/*
* @description :  EDGE_TerritoryWrapper
* @purpose : This is the Wrapper for EDGE_TerritoryProcessStatusUpdateHelper
* @history :
* Version    Developer         		Date           			User Story/Purpose
	1.0		Dipanjan Das		24.06.2024			154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
*/
/**
* @description Wrapper class for EDGE_TerritoryProcessStatusUpdateBatch
*/

public class EDGE_TerritoryWrapper {
      /**
     * @description Set of teritory
     * @return Set<Id>
     */
	Public Set<Id> territoryIdSet {get;set;}
     /**
     * @description Set of Sales teritory
     * @return Set<Id>
     */
	Public Set<Id> salesTerrIdSet {get;set;}
    /**
     * @description Set of Quality teritory
     * @return Set<Id>
     */
	Public Set<Id> dispenseTerrIdSet {get;set;}
    /**
     * @description Set of Activation teritory
     * @return Set<Id>
     */
	Public Set<Id> activationTerIdSet {get;set;}
}