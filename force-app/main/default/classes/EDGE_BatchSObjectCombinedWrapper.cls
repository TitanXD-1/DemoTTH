/**
* @Name : EDGE_BatchSObjectOutputWrapper
* Brief Description: This Wrapper class to return values from EDGE_TerritoryProcessInsertHelper.getCombinedWrapper method to the EDGE_TerritoryProcessRepInsertBatch class.
* Created Date: 20/06/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0			    Suvendu Roy		    20/06/2024			154642 - EDGE Classes_Fix Static Code Analysis Error_Story_4
* 2.0               Joshraj Sen         28/06/2024          154642 - Fixed the SCA ApexDoc
*/
/**
 * @description Returns the combined Wrapper for Territories, Users, Outlets, Outlet Members,Business Roles
 */
public class EDGE_BatchSObjectCombinedWrapper {
    /**
     * @description Set of Terriory IDs
     * @return Set<Id>
     */
    public Set<Id> territoryIdSet{get;set;}
        /**
     * @description Set of User IDs
     * @return Set<Id>
     */
    public Set<Id> userIdSet{get;set;}
            /**
     * @description Set of Outlet IDs
     * @return Set<Id>
     */
    public Set<Id> outletIdSet{get;set;}
         /**
     * @description Set of user business role details
     * @return Map<id,String>
     */
    public Map<id,String> userBusinessRoleMap{get;set;}
      /**
     * @description Set of territory Details
     * @return Map<id,Territory__c>
     */
    public Map<id,Territory__c> territoryMap{get;set;}
     /**
     * @description Set of territory and Outlet Details
     * @return Map<id,List<Id>>
     */
    public Map<Id, List<Id>> territoryOutletMap{get;set;}
    /**
     * @description Set of Outlet Members
     * @return Map<String, Outlet_Member__c>
     */
    public Map<String, Outlet_Member__c> existingOutletMemMap{get;set;}
}