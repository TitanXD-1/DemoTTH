/**
* @Name: EDGE_OutletMemberExtnUtility

* @Purpose: Upsert AccountTeamMember whenever Outlet_Member__c is created or updated

* @History                                                            
                                                           
* @VERSION       AUTHOR               DATE              DETAIL
*  1.0	        Sandip Ghosh	      10/06/2021	 	ES20-10803

   2.0          Sudipta Nandi		  10/19/2021        ES20-10804

*/public without sharing class EDGE_OutletMemberExtnUtility {
	/**
    * @description :upsert Account Team member(ES20-10803)
	* @return : Void
	* @param : List
	*/
    public static void createAccTeam(List<AccountTeamMember> accountMembersList){
        Database.upsert(accountMembersList, false);
    }


    /**
    * @description :delete Account Team member(ES20-10804)
	* @return : Void
	* @param : List
	*/
    public static void deleteAccTeam(List<AccountTeamMember> accountMembersList){
        Database.delete(accountMembersList, false);
    }
     /**
    * @description :delete Account Team member(ES20-10804)
	* @return : Void
	* @param : List
	*/
    public static void deleteOutletMember(List<Outlet_Member__c> delOutletMemList){
        Database.delete(delOutletMemList,false);
    }


}