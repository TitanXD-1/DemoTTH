/**
* @Name: EDGE_OutletMemberTriggerExtnHelper

* @Purpose: Create user in AccountTeamMember whenever Outlet_Member__c is created or updated

* @History                                                            
                                                           
* @VERSION       AUTHOR               DATE              DETAIL
*  1.0	        Anand Uppalapati      02/08/2021	 	ES20-10707
*  2.0	        Sandip Ghosh	      10/06/2021	 	ES20-10803
*  3.0          Sudipta Nandi         12/30/2021        ES20-11763 : User id null checking before inserting in outlet member record.
*/

public with sharing class EDGE_OutletMemberTriggerExtnHelper {
    final static String OutletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    
    public static void createAccTeam(List<Outlet_Member__c> newItems,Map<Id, SObject> oldItems){
        
        Map<String,String> omRoletoRoleCustomMetadata = EDGE_OutletMemberAccountTeamSync.getOutletRoleAccTeamRoleMapping();
        
        List<Outlet_Member__c> outletMemberList = (List<Outlet_Member__c>)newItems;
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        List<AccountTeamMember> updateAtmUserAccessList = new List<AccountTeamMember>();
        Map<id,id> accRecTypeMap = new Map<id,id>();
        Set<id> outletIdSet = new Set<id>();
        Set<id> userIds = new Set<id>();
        Map<id,Boolean> userIdStatusMap = new Map<id,Boolean>();
        Map<Id,List<Id>> outUserIdMap = new Map<Id,List<Id>> ();
        Map<Id,Id> atmIdUserIdMap= new Map<Id,Id>();
        Boolean decideInsertDML;
        
        if(outletMemberList!=null && outletMemberList.size()>0){
            for(Outlet_Member__c oiD : outletMemberList){
                outletIdSet.add(oiD.outlet__c);  
                userIds.add(oiD.User__c);
            }
        }
        
        if(outletIdSet!=null && outletIdSet.size()>0){
            //extraction AccountId and RecordType
            for(Account acciD : [SELECT id,Recordtypeid FROM Account WHERE id IN :outletIdSet]){                
                accRecTypeMap.put(acciD.id,acciD.Recordtypeid);
            }
            for(User userId : [SELECT id,IsActive FROM User WHERE id IN :userIds]){                
                userIdStatusMap.put(userId.id,userId.IsActive);
            }
            
            //Extaraction if AccountTeamMember User for that AccountId
            for(AccountTeamMember atmUserOutlet: [SELECT id,AccountId,UserId FROM AccountTeamMember WHERE AccountId = :outletIdSet]){
                if(!outUserIdMap.containsKey(atmUserOutlet.AccountId) ){
                    outUserIdMap.put(atmUserOutlet.AccountId, new List<Id>{atmUserOutlet.UserId});
                }else if(!outUserIdMap.get(atmUserOutlet.AccountId).contains(atmUserOutlet.UserId)){
                    outUserIdMap.get(atmUserOutlet.AccountId).add(atmUserOutlet.UserId);
                }
                
                atmIdUserIdMap.put(atmUserOutlet.UserId,atmUserOutlet.Id);
            }
            
            if(outletMemberList != null && outletMemberList.Size()>0){
                
                for(Outlet_Member__c oM :outletMemberList){
                    
                    if(accRecTypeMap.get(om.outlet__c) == OutletRecordTypeId){
                        AccountTeamMember newAccTeamMember = new AccountTeamMember();
                        newAccTeamMember.AccountId = oM.Outlet__c;
                        newAccTeamMember.UserId = oM.User__c;
                        if(omRoletoRoleCustomMetadata != null && omRoletoRoleCustomMetadata.containsKey(om.Outlet_Role__c)){
                            newAccTeamMember.TeamMemberRole = omRoletoRoleCustomMetadata.get(om.Outlet_Role__c);
                        }else{
                            newAccTeamMember.TeamMemberRole = oM.Outlet_Role__c;
                        }
                        newAccTeamMember.AccountAccessLevel = 'Edit';
                        newAccTeamMember.OpportunityAccessLevel = 'Edit';
                        newAccTeamMember.ContactAccessLevel = 'Edit';
                        newAccTeamMember.CaseAccessLevel = 'Edit';
                        if(outUserIdMap != null && outUserIdMap.Size()>0 ){
                            if(outUserIdMap.get(oM.Outlet__c) != null && outUserIdMap.get(oM.Outlet__c).contains(oM.User__c)){
                            //Account team member record for the User is present but case access might not be there
                                newAccTeamMember.Id= atmIdUserIdMap.get(oM.User__c);
                                //newAccTeamMember.Userid= oM.User__c;
                            }
                        }
                        if(oM.User__c != null && userIdStatusMap.get(oM.User__c) == true){ //ES20-11763. Null Checking before adding. Required fields "user" are missing in Account Team issue
                            accountMembersList.add(newAccTeamMember);
                        }
                	}
                }
            } 
        }       
        
        if(accountMembersList !=null && accountMembersList.size() > 0 && (Schema.sObjectType.AccountTeamMember.isCreateable() ||  Schema.sObjectType.AccountTeamMember.isUpdateable())){
            EDGE_OutletMemberExtnUtility.createAccTeam(accountMembersList);// modified as a part of ES20-10803
        }
    }
}