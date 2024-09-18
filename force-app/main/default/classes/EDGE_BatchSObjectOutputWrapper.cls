/**
* @Name : EDGE_BatchSObjectOutputWrapper
* Brief Description: This Wrapper class to return values from EDGE_TerritoryProcessInsertExtHelper.getWrapperRecordsAndTraxUsers method to the EDGE_TerritoryProcessRepInsertBatch class.
* Created Date: 20/06/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0			    Suvendu Roy		    20/06/2024			154642 - EDGE Classes_Fix Static Code Analysis Error_Story_4
* 2.0               Joshraj Sen         28/06/2024          154642 - Fixed the SCA ApexDoc
*/
/**
 * @description Returns the combined Wrapper for Outlet Members, Trax User Updates, EDGE_BatchSObjectWrappers
 */
public class EDGE_BatchSObjectOutputWrapper {
        /**
     * @description Set of EDGE_BatchSObjectWrapper
     * @return List<EDGE_BatchSObjectWrapper> 
     */
    public List<EDGE_BatchSObjectWrapper> wrapperRecords{get;set;}
      /**
     * @description Set of Trax User Updates
     * @return List<Trax_User_Update__c>
     */
    public List<Trax_User_Update__c> traxUserUpdate{get;set;}
     /**
     * @description Set of Outlet Members
     * @return Map<String, Outlet_Member__c>
     */
    public Map<String, Outlet_Member__c> uniOutletTeamMap{get;set;}
}