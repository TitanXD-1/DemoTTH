/**

* @description :  EDGE_OutletMemberAccountTeamSync

* @purpose : ES20-262

* @history :

* @Version    Developer         Date           User Story/Purpose

*  1.1       Sagar Barman      28/02/2019      Initial Development
*  1.2		 Dinesh Sharma     24/05/2021      ES20-9768 (Enhancement for Quality Territory Account Team Member)
*  1.3       Joshraj, Rajarshi 01/11/2022      ES20-13475
*  1.4       Mayukh SRoy       06/12/2022      ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.5.      Joshraj Sen       06/01/2023      ES20-13714 - Null Checks at Lines 119,184,254 and Quality Territory Check at Line 61,66
*/

public inherited  sharing class EDGE_OutletMemberAccountTeamSync {
    
    //ES20-9768
    static final  String qualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    
    /**

* @description : getOutletRoleAccTeamRoleMapping - Map for Outlet Member Role and Account Team Role

* @return : Map<String,String>

* @param : void

*/    
    
    public static Map<String,String> getOutletRoleAccTeamRoleMapping(){ 
        
        Map<String,String> userRoleMap = new Map<string,String>();
        
        //Get Metadata for Role Mapping ES20-9768
        for(Mapping_Account_Team_and_Outlet_Member__mdt cusData : [Select Account_Team_Role__c,Outlet_Member_Role__c 
                                                                   from Mapping_Account_Team_and_Outlet_Member__mdt] )
        {
            if(!userRoleMap.containsKey(cusData.Outlet_Member_Role__c)){
                userRoleMap.put(cusData.Outlet_Member_Role__c,cusData.Account_Team_Role__c);
            }
        }
        return userRoleMap;
    }
    
    /**

* @description : getOutletToTerrMap - The below method creates Map for Account and Territory Record Type

* @return : Map<Id,Id>

* @param : void

*/   
    
    public static Map<Id,Id> getOutletToTerrMap(Set<Id> outletIds)
    { 
        
        Map<Id,Id> outletToTerrMap = new Map<Id,Id>();
        String edgeQualityTerritoryString='Quality Territory';//ES20-13714 
        if(outletIds != null)
        {
            //Get Metadata for Role Mapping ES20-9768
            for(Outlet_Territory__c ot : [Select Outlet__c,Territory__r.RecordTypeId from Outlet_Territory__c 
                                          where Outlet__c IN :outletIds and Territory__r.RecordType.Name=:edgeQualityTerritoryString])//ES20-13714 
            {
                if(!outletToTerrMap.containsKey(ot.Outlet__c))
                {
                    outletToTerrMap.put(ot.Outlet__c,ot.Territory__r.RecordTypeId);
                }
            }
        }
        return outletToTerrMap;
    }
    
        /**

* @description : getOutletIds - The below method stores outlets Ids to filter it in the Outlet Territory

* @return : Set<Id>

* @param : List<Outlet_Member__c>

*/  
    
    private static Set<Id> getOutletIds(List<Outlet_Member__c> outletMemberList){
        Set<Id> outletIds = new Set<Id> ();
        for(Outlet_Member__c outletmember: outletMemberList)
        {
            outletIds.add(outletmember.outlet__c);
        }
        return outletIds;
    }
    /**

* @description : createAccountTeamMembers - The below method creates Account Share and Salesforce standard 

* @return : void

* @param : List<Outlet_Member__c>

*/   
    public static void createAccountTeamMembers(List<Outlet_Member__c> outletMemberList)
    { 
        
        Map<String,String> omRoletoRoleCustomMetadata = getOutletRoleAccTeamRoleMapping();
        Set<Id> outletIds = getOutletIds(outletMemberList);
        Map<Id,Id> outletToTerrMap = getOutletToTerrMap(outletIds);
        
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        //System.debug('@@@ Reaches Here EDGE_OutletMemberAccontTeamSync');
        for(Outlet_Member__c om:outletMemberList)
        {             
            //Create account team member records for each user in outlet member
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = om.Outlet__c;
            newAccTeamMember.UserId = om.User__c;
            if(outletToTerrMap != null && omRoletoRoleCustomMetadata != null && 
               outletToTerrMap.get(om.Outlet__c) == qualityRecordTypeId 
               && omRoletoRoleCustomMetadata.get(om.Outlet_Role__c)!=null)//ES20-13714
            {//Quality Members
                newAccTeamMember.TeamMemberRole = omRoletoRoleCustomMetadata.get(om.Outlet_Role__c);
            }else
            {//Sales and AT members
                newAccTeamMember.TeamMemberRole = om.Outlet_Role__c;
            }
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            newAccTeamMember.CaseAccessLevel = 'Edit';
            accountMembersList.add(newAccTeamMember);
        }
        //create Account Share
        if(accountMembersList.size() > 0 && Schema.sObjectType.AccountTeamMember.isCreateable())
        {
            System.enqueueJob(new EDGE_AccTeamMemQueueable(accountMembersList, 'Insert'));//ES20-13475
            //Database.insert(accountMembersList,false);
        }
    }
    
    /**

* @description : updateAccountTeamMembers - The below method updates standard AccountTeamMember records

* @return : void

* @param : List<Outlet_Member__c>

*/  
    public static void updateAccountTeamMembers(List<Outlet_Member__c> outletMemberList)
    {
        
        Map<String,String> omRoletoRoleCustomMetadata = getOutletRoleAccTeamRoleMapping();
        Set<Id> outletIds = getOutletIds(outletMemberList);
        Map<Id,Id> outletToTerrMap = getOutletToTerrMap(outletIds);
        
        Map<String,Outlet_Member__c> mapOutletMember = new Map<String,Outlet_Member__c>(); 
        Set<Id> userSet = new Set<Id>();
        Set<Id> outletSet = new Set<Id>();
        //populating map of OutletMember
        for(Outlet_Member__c om : outletMemberList)
        {
            mapOutletMember.put(om.outlet__c+'_'+om.user__c,om);
            userSet.add(om.user__c);
            outletSet.add(om.outlet__c);
        }
        
        //get the list of AccountTeamMember 
        List<AccountTeamMember> accTeamMemberList = new List<AccountTeamMember>();
        if(Schema.sObjectType.AccountTeamMember.isAccessible())
        {
            accTeamMemberList=[SELECT AccountId, UserId, TeamMemberRole FROM AccountTeamMember WHERE AccountId in:outletSet
                               AND userId in:userSet];   
        }
        List<AccountTeamMember> accTeamMemberToUpdateList=new List<AccountTeamMember>();
        //System.debug('@@@ Reaches Here updateACcountTeamMembers EDGE_OutletMemberAccountTeamSync');
        for(AccountTeamMember atm:accTeamMemberList)
        {
            // check if member role got changed, add to update list
            if(mapOutletMember.containsKey(atm.AccountId+'_'+atm.UserId)){
                Outlet_Member__c outletMember  = mapOutletMember.get(atm.AccountId+'_'+atm.UserId);
                
                if(outletMember != null && atm.TeamMemberRole!= outletMember.Outlet_Role__c){ 
                    
                    if(outletToTerrMap != null && omRoletoRoleCustomMetadata != null 
                       && outletToTerrMap.get(outletMember.Outlet__c) == qualityRecordTypeId 
                       && omRoletoRoleCustomMetadata.get(outletMember.Outlet_Role__c)!=null)//ES20-13714
                    {
                        atm.TeamMemberRole = omRoletoRoleCustomMetadata.get(outletMember.Outlet_Role__c);
                    }else{
                        atm.TeamMemberRole= outletMember.Outlet_Role__c;
                    }
                    accTeamMemberToUpdateList.add(atm);
                }                    
            }          
        }            
        //update Account Members
        if(accTeamMemberToUpdateList.size()>0 && Schema.sObjectType.AccountTeamMember.isUpdateable())
        {
            Database.update(accTeamMemberToUpdateList,false);
        }
    }
    
    /**
* @description : deleteAccountTeamMembers - The below method deletes standard AccountTeamMember records  

* @return : void

* @param : List<Outlet_Member__c>

*/   
    public static void deleteAccountTeamMembers(List<Outlet_Member__c> outletMemberList)
    {
        List<AccountTeamMember> accountMembersListToDel = new List<AccountTeamMember>();
        Set<Id> userSet = new Set<Id>();
        Set<Id> outletSet = new Set<Id>();
        //get the outlet    
        for(Outlet_Member__c om : outletMemberList)
        {            
            userSet.add(om.user__c);
            outletSet.add(om.outlet__c);
        }
        
        //Get AccountTeamMember
        accountMembersListToDel = [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN :outletSet and UserId IN :userSet];
       
        if(accountMembersListToDel.size()>0  && Schema.sObjectType.AccountTeamMember.isDeletable())
        {
            System.enqueueJob(new EDGE_AccTeamMemQueueable(accountMembersListToDel, 'Delete'));
            //database.delete(accountMembersListToDel,false);
        }
    }
    
//ES20-13624    
   /**
* @description : createAccountTeamMember - The below method creates Account Share and Salesforce standard 

* @return : void

* @param : List<Outlet_Member__c>

*/   
    public static List<AccountTeamMember> createAccountTeamMember(List<Outlet_Member__c> outletMemberList)
    { 
        
        Map<String,String> omRoletoRoleCustomMetadata = getOutletRoleAccTeamRoleMapping();
        Set<Id> outletIds = getOutletIds(outletMemberList);
        Map<Id,Id> outletToTerrMap = getOutletToTerrMap(outletIds);
        List<AccountTeamMember> accountMembersList = new List<AccountTeamMember>();
        for(Outlet_Member__c om:outletMemberList)
        {             
            //Create account team member records for each user in outlet member
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = om.Outlet__c;
            newAccTeamMember.UserId = om.User__c;
            if(outletToTerrMap != null && omRoletoRoleCustomMetadata != null 
               && outletToTerrMap.get(om.Outlet__c) == qualityRecordTypeId 
               && omRoletoRoleCustomMetadata.get(om.Outlet_Role__c)!=null)//ES20-13714
            {
                newAccTeamMember.TeamMemberRole = omRoletoRoleCustomMetadata.get(om.Outlet_Role__c);
            }else
            {
                newAccTeamMember.TeamMemberRole = om.Outlet_Role__c;
            }
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            newAccTeamMember.CaseAccessLevel = 'Edit';
            accountMembersList.add(newAccTeamMember);
        }
        return accountMembersList;
    }
    
//ES20-13624  
    /**
* @description : deleteAccountTeamMember - The below method deletes standard AccountTeamMember records  

* @return : void

* @param : List<Outlet_Member__c>

*/   
    public static List<AccountTeamMember> deleteAccountTeamMember(List<Outlet_Member__c> outletMemberList)
    {
        List<AccountTeamMember> accountMembersListToDel = new List<AccountTeamMember>();
        Set<Id> userSet = new Set<Id>();
        Set<Id> outletSet = new Set<Id>();
        Set<String> omKeySet = new Set<String>();
        //Set<String> amKeySet = new Set<String>();
        //Map<String,AccountTeamMember> KeyAMMap = new Map<String,AccountTeamMember>();
        
        //get the outlet    
        for(Outlet_Member__c om : outletMemberList)
        {            
            userSet.add(om.user__c);
            outletSet.add(om.outlet__c);
            String omKey = om.user__c+'_'+om.outlet__c;
            omKeySet.add(omKey);
        }
        
        //Get AccountTeamMember
        for(AccountTeamMember accTm : [SELECT Id, AccountId, UserId FROM AccountTeamMember WHERE AccountId IN :outletSet and UserId IN :userSet])
        {
            String amKey = accTm.UserId+ '_' +accTm.AccountId;
            if(omKeySet.contains(amKey))
            {
                accountMembersListToDel.add(accTm);
            }
        }
       
        return accountMembersListToDel;
    }
}