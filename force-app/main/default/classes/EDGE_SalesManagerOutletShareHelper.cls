/**

* @description :  EDGE_SalesManagerOutletShareBatch

* @purpose : Share Outlets with Sales Managers by Outlet Member and Account Team

* @history :

* Version    Developer                Date             User Story/Purpose

*  1.1       Mayukh SRoy            01/02/2023        ES20-13558 - Change in Existing Batch Logic To Add Sales Manager to a region with more than 10000 accounts_ SFDC_ Technical Debt
*  1.2      Supriya/Joshraj         30/05/2024        154332
*/

public with sharing class EDGE_SalesManagerOutletShareHelper {
    public static Date currentDate = Date.today();
    public static Map<string,Mapping_Account_Team_and_Outlet_Member__mdt> userRoleMap = new Map<string,Mapping_Account_Team_and_Outlet_Member__mdt>();
    
    //Get OutletMember To Insert
    public static List<Outlet_Member__c> getOutletMemberList(List<Outlet_Territory__c> otList,Map<Id,Id> thmUserMap,Set<Id> usrSet){
        List<Outlet_Member__c> outletMemberToInsert = new List<Outlet_Member__c>();
        Set<String> exOutletMembersSet = new Set<String>();
        List<String> outletUserKeyList = new List<String>();
        Map<Id, User> userToProfileMap = new Map<Id, User>();
        Map<id,String> userBusinessRoleMap = new Map<id,String>();
        Set<Id> regionSet = new Set<Id>();
        Set<Id> outletSet = new Set<Id>();
        
        for(Outlet_Territory__c ot:oTList){
            if(salesManagerAdditionCheck(thmUserMap,ot.Territory__r.Region__c) && ot.Outlet__c != Null){
                regionSet.add(ot.Territory__r.Region__c);
                outletSet.add(ot.Outlet__c);
                String usr = thmUserMap.get(ot.Territory__r.Region__c);
                String key = usr+'_'+ot.Outlet__c;
                outletUserKeyList.add(key);
            }
        }
        
        
        if(usrSet!=Null && usrSet.size()>0){
            userToProfileMap = getuserToProfileMap(usrSet);
            getaccoutletMemberMetadataMap();
            userBusinessRoleMap = getuserBusinessRoleMap(usrSet);
            exOutletMembersSet = getexOutletMemberKeys(outletSet,usrSet);
        }
        
        
        System.debug(LoggingLevel.DEBUG,outletUserKeyList);
        
        for(String outletUserKey : outletUserKeyList){
            if(!exOutletMembersSet.contains(outletUserKey)){
                Outlet_Member__c outletMemberRec  = new Outlet_Member__c();
                outletMemberRec = createOutletMember(outletUserKey,userToProfileMap,userBusinessRoleMap);
                outletMemberToInsert.add(outletMemberRec);
            }
        }
        return outletMemberToInsert;
    }
    
    
    
    
    //get MetaData for Role Mapping
    public static void getaccoutletMemberMetadataMap(){
        for(Mapping_Account_Team_and_Outlet_Member__mdt cusData : [Select id,Account_Team_Role__c,Global_Equivalent_Role__c, Outlet_Member_Role__c from Mapping_Account_Team_and_Outlet_Member__mdt WITH SECURITY_ENFORCED] ){
            if(!userRoleMap.containsKey(cusData.Global_Equivalent_Role__c)){
                userRoleMap.put(cusData.Global_Equivalent_Role__c,cusData);
            }
        }
    }
    
    
    
    
    //Get User and Global Equivalents
    public static Map<id,String> getuserBusinessRoleMap(Set<Id> usrSet){
        Map<id,String> userBusinessRoleMap = new Map<id,String>();
        for(User_Business_Role__c userRole : [Select id, User__c, Business_Role__c,Business_Role__r.Global_Equivalent__c from User_Business_Role__c where User__c IN:usrSet WITH SECURITY_ENFORCED]){
            if(!userBusinessRoleMap.containsKey(userRole.User__c) && userRole.Business_Role__c != null){
                userBusinessRoleMap.put(userRole.User__c,userRole.Business_Role__r.Global_Equivalent__c);
            }
        }
        return userBusinessRoleMap;
    }
    
    
    
    
    //get ProfileMap of the Users
    public static Map<Id, User> getuserToProfileMap(Set<Id> usrSet){
        Map<Id, User> userToProfileMap = new Map<Id, User>();
        for(User userRecord : [Select Id, IsActive, Profile.Name from User where Id in :usrSet WITH SECURITY_ENFORCED]){
            userToProfileMap.put(userRecord.Id, userRecord);
        }
        return userToProfileMap;
    }
    
    
    
    
    //Fetching Existing Outlet Members for Selected Regions and Outlets
    public static Set<String> getexOutletMemberKeys(Set<Id> outletSet,Set<Id> usrSet){
        Set<String> exOutletMembersSet = new Set<String>();
        for(Outlet_Member__c outletMem : [SELECT Id, Outlet__c, User__c FROM Outlet_Member__c WHERE Outlet__c IN :outletSet AND User__c IN :usrSet WITH SECURITY_ENFORCED]){
            String userOutletkey = outletMem.User__c + '_' + outletMem.Outlet__c;
            exOutletMembersSet.add(userOutletkey);            
        }
        return exOutletMembersSet;
    }
    
    
    //Check if the salesmanager needs to be added for this OT
    public static boolean salesManagerAdditionCheck(Map<Id,Id> thmUserMap,String region){
        Boolean isValid = false;
        if(thmUserMap!=Null && thmUserMap.containsKey(region) && thmUserMap.get(region)!=Null){
            isValid = true;
        }
        return isValid;
    }
    
    
    
    //create Outlet Member Records
    public static Outlet_Member__c createOutletMember(String outletUserKey,Map<Id, User>userToProfileMap,Map<Id, String>userBusinessRoleMap){
        Outlet_Member__c outletMemberRec = new Outlet_Member__c();
        List<String> omKey = outletUserKey.split('_');
        String user = omKey[0];
        String outlet = omKey[1];
        outletMemberRec.User__c = User;
        outletMemberRec.Outlet__c = outlet;
        if(!userToProfileMap.isEmpty() && userToProfileMap.containsKey(user)){
            outletMemberRec.Outlet_Role__c = getOutletRole(user,userToProfileMap,userBusinessRoleMap); 
        }
        outletMemberRec.OutletUser__c = user + '-' + outlet;
        return outletMemberRec;
    }
    
    
    
    
    //get OutletMember Role
    public static String getOutletRole(String user,Map<Id, User>userToProfileMap,Map<Id, String>userBusinessRoleMap){
        String outletRole;
        if(userToProfileMap.get(user).Profile.Name.contains('Sales Manager')){//Support DSM 154332
            outletRole = 'Sales Manager'; 
        }
        /*else if(userToProfileMap.get(user).Profile.Name == 'Activation Specialist'){
        outletRole = 'Activation Specialist';
        //ES20-9831
        }*/
        else if(userToProfileMap.get(user).Profile.Name == 'Quality Manager' && userBusinessRoleMap != null && userBusinessRoleMap.size() > 0 && userRoleMap != null && userRoleMap.size() > 0) {
            string managerBusinessRole = getmanagerBusinessRole(userBusinessRoleMap,user); 
            string managerRole = getmanagerRole(managerBusinessRole);
            outletRole = managerRole;
        }
        return outletRole;
    }
    
    
    
    
    //get ManagerBusinessRole
    public static String getmanagerBusinessRole(Map<Id, String>userBusinessRoleMap,String user){
        String businessRole;
        businessRole = userBusinessRoleMap.get(user) != null ? userBusinessRoleMap.get(user) : ''; 
        return businessRole;
    }
    
    
    
    
    //get managerRole for OutletRole
    public static String getmanagerRole(String managerBusinessRole){
        String managerRole;
        managerRole = managerBusinessRole != ''? userRoleMap.get(managerBusinessRole).Outlet_Member_Role__c:'';
        return managerRole;
    }
}