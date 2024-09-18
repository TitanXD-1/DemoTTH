/**

* @description :  EDGE_SalesManagerSharingOperations

* @purpose : Sales force Sharing Rules - Technical - ES20-3836 

* @history :

* Version    Developer         Date             User Story/Purpose

*  1.1      Dipanjan D        09/09/2019        Methods : salesManagerOutletShare, salesManagerOutletRemove
*  1.2      Sandip Ghosh      28/10/2020        ES20-8778 (Methods : Updated salesManagerOutletShare, salesManagerOutletRemove methods for adding & removing Activation Specialist)
*  1.3      Dinesh Sharma     18/06/2021        ES20-9831 : salesManagerOutletShare method updated to add Quality Manager to the Account Team and Outlet Member.
*  1.4      Sudipta Nandi     12/30/2021        ES20-11763 : User id null checking before inserting in outlet member record.
*  1.5      Mayukh SRoy       08/11/2022        ES20-13505 - Fix for Batch Failure
*  1.6      Mayukh SRoy       06/12/2022        ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.7      Supriya/Joshraj   30/05/2024        154332
*/
public without sharing class EDGE_SalesManagerSharingOperations {
    
    /**

* @description : salesManagerOutletShare - Create Outlet Members and Account Members for Sales Manager

* @return : void

* @param : Map<Id, Id>, Map<Id, Id>

*/
    
  //public static void salesManagerOutletShare(Map<Id, Id> regionWithSalesManagerORAsMap, Map<Id, Id> outletWithRegionORATMap){
    public static List<AccountTeamMember> salesManagerOutletShare(Map<Id, Id> regionWithSalesManagerORAsMap, Map<Id, List<Id>> outletWithRegionORATMap){      //ES20-13624
        Set<String> exOutletMembersSet = new Set<String>();
        Map<Id, Set<Id>> salesManagerWithOutletsMap = new Map<Id, Set<Id>>();
        List<Outlet_Member__c> outletMemberListToInsert = new List<Outlet_Member__c>();
        //ES20-8778
        Map<Id, User> userToProfileMap = new Map<Id, User>();
        Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap = new Map<string,Mapping_Account_Team_and_Outlet_Member__mdt>();
        Map<id,String> userBusinessRoleMap = new Map<id,String>();
        List<AccountTeamMember> AccToInsList = new List<AccountTeamMember>();
        
        
        //Get Metadata for Role Mapping  ES20-9831
        for(Mapping_Account_Team_and_Outlet_Member__mdt cusData : [Select id,Account_Team_Role__c,Global_Equivalent_Role__c, Outlet_Member_Role__c from Mapping_Account_Team_and_Outlet_Member__mdt] ){
            if(!userRoleMap.containsKey(cusData.Global_Equivalent_Role__c)){
                userRoleMap.put(cusData.Global_Equivalent_Role__c,cusData);
            }
        }
        
        if(regionWithSalesManagerORAsMap != null && regionWithSalesManagerORAsMap.size()  > 0){
            //Get User and Global Equivalent Map ES20-9831
            for(User_Business_Role__c userRole : [Select id, User__c, Business_Role__c,Business_Role__r.Global_Equivalent__c, User_Country_Code__c from User_Business_Role__c where User__c IN:regionWithSalesManagerORAsMap.values()]){
                if(!userBusinessRoleMap.containsKey(userRole.User__c)){
                    if(userRole.Business_Role__c != null){
                        userBusinessRoleMap.put(userRole.User__c,userRole.Business_Role__r.Global_Equivalent__c);
                    }
                }
            }
        }
        
        //Fetching Existing Outlet Members for Selected Regions and Outlets
        for(Outlet_Member__c outletMem : [SELECT Id, Outlet__c, User__c FROM Outlet_Member__c WHERE Outlet__c IN :outletWithRegionORATMap.keySet() AND User__c IN :regionWithSalesManagerORAsMap.values()]){
            String key = outletMem.User__c + '_' + outletMem.Outlet__c;
            exOutletMembersSet.add(key);            
        }
        //ES20-8778
        for(User userRecord : [Select Id, IsActive, Profile.Name from User where Id in :regionWithSalesManagerORAsMap.values()]){
            userToProfileMap.put(userRecord.Id, userRecord);
        }
        //Iterating Account list to exclude the existing records and populate manager with outlets map
        for(Id outletId : outletWithRegionORATMap.keySet()){
            //Id managerORASId = regionWithSalesManagerORAsMap.get(outletWithRegionORATMap.get(outletId));
            List <Id> RegionsList = outletWithRegionORATMap.get(outletId);    //ES20-13624
            for(Id Reg : RegionsList){                                        //ES20-13624
                Id managerORASId = regionWithSalesManagerORAsMap.get(Reg);
                String key = managerORASId + '_' + outletId;
                if(!exOutletMembersSet.contains(key)){
                    if(salesManagerWithOutletsMap.containsKey(managerORASId)){
                        salesManagerWithOutletsMap.get(managerORASId).add(outletId);
                    }else{
                        salesManagerWithOutletsMap.put(managerORASId, new Set<Id>{ outletId });
                    }          
            	}
        	}
        }
        
        //Creating Outlet Members to insert
        
        for(Id managerORASId : salesManagerWithOutletsMap.keySet()){
            for(Id outletId : salesManagerWithOutletsMap.get(managerORASId)){
                Outlet_Member__c outletMemberRec = new Outlet_Member__c();
                outletMemberRec.Outlet__c = outletId;
                outletMemberRec.User__c = managerORASId;
                //ES20-8778 : start
                if(!userToProfileMap.isEmpty() && userToProfileMap.containsKey(managerORASId)){
                    if(userToProfileMap.get(managerORASId).Profile.Name.contains('Sales Manager')){//Support DSM 154332
                        outletMemberRec.Outlet_Role__c = 'Sales Manager'; 
                    }else if(userToProfileMap.get(managerORASId).Profile.Name == 'Activation Specialist'){
                        outletMemberRec.Outlet_Role__c = 'Activation Specialist';
                    }else if(userToProfileMap.get(managerORASId).Profile.Name == 'Quality Manager'){//ES20-9831
                        //logic for mapping
                        if(userBusinessRoleMap != null && userBusinessRoleMap.size() > 0 && userRoleMap != null && userRoleMap.size() > 0) {
                            string managerBusinessRole = userBusinessRoleMap.get(managerORASId) != null ? userBusinessRoleMap.get(managerORASId) : ''; 
                            string managerRole = managerBusinessRole != ''? userRoleMap.get(managerBusinessRole).Outlet_Member_Role__c:'';
                            outletMemberRec.Outlet_Role__c = managerRole;
                        }
                    }
                }
                //ES20-8778 :End
                outletMemberRec.OutletUser__c = managerORASId + '-' + outletId;

                if(outletMemberRec.User__c != null && userToProfileMap.containsKey(outletMemberRec.User__c) && userToProfileMap.get(outletMemberRec.User__c).IsActive == true){ //ES20-11763. Null Checking before adding.REQUIRED_FIELD_MISSING, Required fields are missing in Account Team issue

                    outletMemberListToInsert.add(outletMemberRec);  
                }
                          
            }
        }
        system.debug('outletMemberListToInsert='+outletMemberListToInsert);
        if(outletMemberListToInsert.size() > 0 && outletMemberListToInsert != null){
            Database.insert(outletMemberListToInsert);
            AccToInsList = EDGE_OutletMemberAccountTeamSync.createAccountTeamMember(outletMemberListToInsert);
            if(EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch){ 					 //ES20-13505
                EDGE_OutletMemberTriggerHelper.createContactSharing(outletMemberListToInsert,null);
            }
        }           
        return AccToInsList; //ES20-13624
    }
    
    /**

* @description : salesManagerOutletRemove - Delete Outlet Members and Account Members for Sales Manager

* @return : void

* @param : Set<Id>, Set<Id>

*/
  //public static void salesManagerOutletRemove(Set<Id> managerORASIds, Set<Id> outletIds){
    public static List<AccountTeamMember> salesManagerOutletRemove(Map<Id, Id> regionWithSalesManagerORAsMap, Map<Id,List<Id>> OutletWithRegionMap){  //ES20-13624
        Set<Outlet_Member__c> OutletMembersSetToDelete = new Set<Outlet_Member__c>();
        List<Outlet_Member__c> outletMemberListToDelete = new List<Outlet_Member__c>(); 
        List<AccountTeamMember> AccTmMemToRemove = new List<AccountTeamMember>();
        Map<String,Outlet_Member__c> KeyOMMap = new Map<String,Outlet_Member__c>();
        
        //Fetching Outlet Members for Selected Outlets to delete
        for(Outlet_Member__c outletMem : [SELECT Id, Outlet__c, User__c FROM Outlet_Member__c WHERE Outlet__c IN :OutletWithRegionMap.keySet() AND User__c IN :regionWithSalesManagerORAsMap.values()]){
            String key = outletMem.User__c + '_' + outletMem.Outlet__c;
            //OutletMembersSetToDelete.add(key);
            KeyOMMap.put(key,outletMem);
        }
        
        for(Id outletId : OutletWithRegionMap.keySet()){
            List <Id> RegionsList = OutletWithRegionMap.get(outletId);
            for(Id Reg : RegionsList){
                String CompKey = regionWithSalesManagerORAsMap.get(Reg)+ '_' +outletId;
                if(KeyOMMap.containsKey(CompKey)){
                    OutletMembersSetToDelete.add(KeyOMMap.get(CompKey));
                }
            }
        }
        
        if(OutletMembersSetToDelete != null && OutletMembersSetToDelete.size() > 0){
            outletMemberListToDelete.addAll(OutletMembersSetToDelete);
        }
        System.debug('outletMemberListToDelete:: '+outletMemberListToDelete);
        //Deleting Outlet Members and Account Team
        if(outletMemberListToDelete != null && outletMemberListToDelete.size() > 0){
            AccTmMemToRemove = EDGE_OutletMemberAccountTeamSync.deleteAccountTeamMember(outletMemberListToDelete);
            Database.delete(outletMemberListToDelete);
        }
        return AccTmMemToRemove; //ES20-13624
    }
}