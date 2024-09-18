/**
* @Description: EDGE_UserBusinessRoleTriggerHelper
* @Purpose: The requirement is to check Business Roles assigned to users 
ES20-148 - assignBusinessRole
ES20-148 - checkBusinessRoleInsert

* @History                                                            

* @VERSION   	AUTHOR            DATE              DETAIL
* 	1.0       Sandeep Sahoo     02/25/2019        Initial Development
*	1.1       Srutadeba C       02/12/2020        Defect 7163 change Business Role Id on user when 
												  users Business Role is changing .
*	1.2		  Pradeep Kumar	    25/11/2020		  User Story ECM-3346 - CIO & Legal user Addition to business role
*	1.3		  Pradeep Kumar 	07/12/2020		  User Story ECM-3432 - Validation for Update Functionality
*	1.4		  Supriya G			07/04/2022		  ES20-12426(Method: getChildCountryCode, getUserBRMap, assignUserToTerritories, deleteAllExistingTerritoryAssignment, createTerritoryAssignments, createUserTerrList)
*	1.5		Shivam Chauhan		18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt

**/

public with sharing class EDGE_UserBusinessRoleTriggerHelper {
    
    public static List<UserTerritory2Association> usrTerritorylist=new List<UserTerritory2Association>();
    public static boolean isRecursive = true; //to stop recursion
    public static Map<String,String> countryCodeMap = new Map<String,String>();
    public static Set<String> userSet = new Set<String>(); 
    public static Map<Id,String> userBRMap = new Map<Id,String>();
    public static Map<Id,List<String>> userCountryMap = new Map<Id,List<String>>();
    public static String allQualityTerritoryBR = System.Label.Standard_Territory_Global_Equivalent;
    public static String[] allQualityTerritoryBRList = allQualityTerritoryBR.split(';');
    Map<String,List<String>> childClusterCountryMap = new Map<String,List<String>>();//Map of cluster country with their respective child countries
    Map<Id,List<String>> userChildClusterCountryMap = new Map<Id,List<String>>();//Map of users with lowest level country under cluster
    List<String> allClusterCountryList = new List<String>();
    Map<Id,List<String>> userHubCountryMap = new Map<Id,List<String>>();//Map of users with Hub country        
    Map<String,List<String>> childHubCountryMap = new Map<String,List<String>>();//Map of Hub country with their respective child countries
    Map<Id,List<String>> userChildHubCountryMap = new Map<Id,List<String>>();//Map of users with lowest level country under Hub
    public static List<String> newUsersAllCountryList= new List<String>();
    public static Set<String> countrySet = new Set<String>();
    public static Map<String,Id> childTerritoryNameMap = new Map<String,Id>();    
    public static Set<String> terrUserIdKey = new Set<String>();
    
    //Purpose: This method is used to populate Business Role Id & Business Role Name of User
    public static void assignBusinessRole(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){              
        List<User> lstUsersToUpdate = new List<User>();     //  list of users to be updated        
        Set<ID> businessRoleSet = new Set<ID>();
        Set<ID> usrBusinessRoleSet = new Set<ID>();
        Set<ID> usrIdSet = new Set<ID>();
        
        
        //Create Business Role Id Set
        //Case: 1 - After Insert
        if(oldItems == null){
            for(SObject uc : newItems.values()){
                User_Business_Role__c newubr = (User_Business_Role__c)uc;
                businessRoleSet.add(newubr.Business_Role__c);
                usrBusinessRoleSet.add(newubr.Id);
                usrIdSet.add(newubr.User__c);
            }
        }
        
        //Case: 2 - After Update
        if(oldItems != null){
            for(SObject uc : newItems.values()){
                User_Business_Role__c newubr = (User_Business_Role__c)uc;
                User_Business_Role__c oldubr = (User_Business_Role__c)oldItems.get(newubr.id);
                if((newubr.Business_Role__c != oldubr.Business_Role__c) || (newubr.User__c != oldubr.User__c)){
                    businessRoleSet.add(newubr.Business_Role__c);
                    usrBusinessRoleSet.add(newubr.Id);
                    usrIdSet.add(newubr.User__c);
                }
            }
        }
        
        if(businessRoleSet.size()>0){
            //Get Business Role Details
            Map<Id, Business_Role__c> businessRoleMap = new Map<Id, Business_Role__c>([Select Id, Name from Business_Role__c where Id in : businessRoleSet]);
            Map<Id, User> userMap = new Map<Id, User>([Select Id, Name, Profile.Name, Business_Role__c, Business_Role_ID__c From User where id in: usrIdSet and (Profile.Name = 'CIO User' or Profile.Name = 'Legal User')]);
            //Update Business Role Id on User
            if(usrBusinessRoleSet.size()>0){
                for(Id ubrId : usrBusinessRoleSet){
                    User_Business_Role__c newubr = (User_Business_Role__c)newItems.get(ubrId);
                    if(newubr.User__c != null && newubr.Business_Role__c != null){
                        if(!userMap.containskey(newubr.User__c)){
                            User objUser = new User(Id = newubr.User__c, 
                                                    Business_Role__c = businessRoleMap.get(newubr.Business_Role__c).Name, 
                                                    Business_Role_ID__c = newubr.Business_Role__c);
                            
                            lstUsersToUpdate.add(objUser);
                        }
                    }
                }
            }
        }
        
        //check if the size of the list is > 0, then update the list
        if(lstUsersToUpdate.size()>0){
            Database.update(lstUsersToUpdate);
        }
    }
    
    //Purpose: This method is used to validate user has same country as Business Role  
    public static void checkBusinessRoleInsert(List<SObject> newItems){
        Set<Id> brIdset = new Set<Id>();
        Set<Id> userIdset = new Set<Id>();
        Map<Id, List<String>> userMap = new Map<Id, List<String>>();
        Map<Id, String> businessRoleMap = new Map<Id, String>();
        List<String> userbusinessRolelist = new List<String>();
        Map<Id, List<String>> businessRoleUniqueMap = new Map<Id, List<String>>();
        Map<String, List<String>> countyCodeUniqueMap = new Map<String, List<String>>();
        Map<Id, Business_Role__c> businessRoleRecMap = new Map<Id, Business_Role__c>();
        Map<Id, User> userRecMap = new Map<Id, User>();
        
        for(SObject obj :newItems){
            User_Business_Role__c newubr = (User_Business_Role__c)obj; 
            brIdset.add(newubr.Business_Role__c);
            userIdset.add(newubr.User__c);
        }
        
        if(Schema.sObjectType.User.isAccessible()) {
            userRecMap = new Map<Id, User>([Select Id, Available_Countries__c, Profile.Name from User where Id IN:userIdset]);
            for(User u : userRecMap.Values()){
                if(u.Available_Countries__c != null && u.Available_Countries__c != '' ){
                    userMap.put(u.Id, u.Available_Countries__c.split(';'));
                }
            }
        }
        
        if(Schema.sObjectType.Business_Role__c.isAccessible()) {
            businessRoleRecMap = new Map<Id, Business_Role__c>([Select Id, Country__c, Country__r.Code__c from Business_Role__c where Id IN:brIdset]);
            if(businessRoleRecMap.size()>0){
                for(Business_Role__c br : businessRoleRecMap.values()){
                    businessRoleMap.put(br.Id, br.Country__r.Code__c);
                }
            }
        }
        
        if(Schema.sObjectType.User_Business_Role__c.isAccessible()) {
            for(User_Business_Role__c ubr : [Select ID, Business_Role__c, Unique_Key__c, User__c, User__r.Profile.Name, Business_Role__r.Country__r.Code__c from User_Business_Role__c where User__c IN:userIdset]){
                if(ubr.User__r.Profile.Name == 'CIO User' || ubr.User__r.Profile.Name == 'Legal User'){
                    if(businessRoleUniqueMap.containsKey(ubr.Business_Role__c)){
                        List<String> uniqueKeyList = businessRoleUniqueMap.get(ubr.Business_Role__c);
                        uniqueKeyList.add(ubr.Unique_Key__c);
                        businessRoleUniqueMap.put(ubr.Business_Role__c,uniqueKeyList);
                    }
                    else{
                        List<String> uniqueKeyList = new List<String>();
                        uniqueKeyList.add(ubr.Unique_Key__c);
                        businessRoleUniqueMap.put(ubr.Business_Role__c,uniqueKeyList);
                    }
                    if(countyCodeUniqueMap.containsKey(ubr.Business_Role__r.Country__r.Code__c)){
                        List<String> uniqueKeyList = countyCodeUniqueMap.get(ubr.Business_Role__r.Country__r.Code__c);
                        uniqueKeyList.add(ubr.Unique_Key__c);
                        countyCodeUniqueMap.put(ubr.Business_Role__r.Country__r.Code__c,uniqueKeyList);
                    }
                    else{
                        List<String> uniqueKeyList = new List<String>();
                        uniqueKeyList.add(ubr.Unique_Key__c);
                        countyCodeUniqueMap.put(ubr.Business_Role__r.Country__r.Code__c,uniqueKeyList);
                    }
                }
                else{
                    userbusinessRolelist.add(ubr.Unique_Key__c.split('_')[0]);
                }
            }
        }
        
        if(userbusinessRolelist.size()>0 || businessRoleUniqueMap.size()>0){
            for(SObject obj :newItems){
                User_Business_Role__c ubr = (User_Business_Role__c)obj;
                if(userRecMap.get(ubr.User__c).Profile.Name == 'CIO User' || userRecMap.get(ubr.User__c).Profile.Name == 'Legal User'){
                    if(businessRoleUniqueMap.containskey(ubr.Business_Role__c)){
                        if(businessRoleUniqueMap.get(ubr.Business_Role__c).contains(ubr.User__c+'_'+businessRoleRecMap.get(ubr.Business_Role__c).Country__r.Code__c)){
                            ubr.addError(label.UniqueBusinessRoleForCIOandLegal);
                        }
                    }
                    else if(countyCodeUniqueMap.containsKey(businessRoleRecMap.get(ubr.Business_Role__c).Country__r.Code__c)){
                        if(countyCodeUniqueMap.get(businessRoleRecMap.get(ubr.Business_Role__c).Country__r.Code__c).contains(ubr.User__c+'_'+businessRoleRecMap.get(ubr.Business_Role__c).Country__r.Code__c)){
                            ubr.addError(label.UniqueBusinessRoleForCIOandLegal);
                        }
                    }
                }
                else{
                    if(userbusinessRolelist.contains(ubr.User__c)){
                        ubr.addError(label.UniqueBusinessRole);
                    }
                }
            }
        }
        
        if(userMap.size()>0 && businessRoleMap.size()>0){
            for(SObject obj :newItems){
                User_Business_Role__c ubr = (User_Business_Role__c)obj;
                List<string> usrConList = new List<string>();
                usrConList = userMap.get(ubr.User__c);
                if(!usrConList.contains(businessRoleMap.get(ubr.Business_Role__c))){
                    ubr.addError(label.BusinessRoleCountry);
                }
            }
        }
    }
    
      
	//Purpose: This method is used to validate user has same country as Business Role while updating
    public static void checkBusinessRoleUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        if(EDGE_UserBusinessRoleTriggerHelper.isRecursive || Test.isRunningTest()){
            EDGE_UserBusinessRoleTriggerHelper.isRecursive = false;
            Set<Id> brIdset = new Set<Id>();
            Set<Id> userIdset = new Set<Id>();
            Map<Id, List<String>> userMap = new Map<Id, List<String>>();
            Map<Id, String> businessRoleMap = new Map<Id, String>();
            Map<Id, Business_Role__c> businessRoleRecMap = new Map<Id, Business_Role__c>();
            Map<Id, User> userRecMap = new Map<Id, User>();
            Map<Id, User_Business_Role__c> userUBRMap = new Map<Id, User_Business_Role__c>();
            Map<String, User_Business_Role__c> uniqueKeyUBRMap = new Map<String, User_Business_Role__c>();
            
            for(SObject uc : newItems.values()){
                User_Business_Role__c newubr = (User_Business_Role__c)uc;
                User_Business_Role__c oldubr = (User_Business_Role__c)oldItems.get(newubr.id);
                if((newubr.Business_Role__c != oldubr.Business_Role__c) || (newubr.User__c != oldubr.User__c)){
                    brIdset.add(newubr.Business_Role__c);
                    userIdset.add(newubr.User__c);
                }
            }
            
            if(Schema.sObjectType.User.isAccessible()) {
                userRecMap = new Map<Id, User>([Select Id, Available_Countries__c, Profile.Name from User where Id IN:userIdset]);
                for(User u : userRecMap.Values()){
                    if(u.Available_Countries__c != null && u.Available_Countries__c != '' ){
                        userMap.put(u.Id, u.Available_Countries__c.split(';'));
                    }
                }
            }
            
            if(Schema.sObjectType.Business_Role__c.isAccessible()) {
                businessRoleRecMap = new Map<Id, Business_Role__c>([Select Id, Country__c, Country__r.Code__c from Business_Role__c where Id IN:brIdset]);
                if(businessRoleRecMap.size()>0){
                    for(Business_Role__c br : businessRoleRecMap.values()){
                        businessRoleMap.put(br.Id, br.Country__r.Code__c);
                    }
                }
            }
            
            for(SObject uc : newItems.values()){
                User_Business_Role__c newubr = (User_Business_Role__c)uc;
                User_Business_Role__c oldubr = (User_Business_Role__c)oldItems.get(newubr.id);
                if(newubr.User__c != oldubr.User__c){
                    if(userRecMap.containskey(newubr.User__c)){
                        if(userRecMap.get(newubr.User__c).Profile.Name == 'CIO User' || userRecMap.get(newubr.User__c).Profile.Name == 'Legal User'){
                            string uniqueKey = newubr.User__c + '_'+businessRoleRecMap.get(newubr.Business_Role__c).Country__r.Code__c;
                            if(uniqueKeyUBRMap.containsKey(uniqueKey)){
                                newubr.addError(label.UniqueBusinessRoleForCIOandLegal);
                            }
                            else{
                                uniqueKeyUBRMap.put(uniqueKey,newubr);
                            }
                        }
                        else{
                            if(userUBRMap.containskey(newubr.User__c)){
                                newubr.addError(label.UniqueBusinessRole);
                            }
                            else{
                                userUBRMap.put(newubr.User__c,newubr);
                            }
                        }
                    }
                }
            }
            
            if(Schema.sObjectType.User_Business_Role__c.isAccessible()) {
                if(userUBRMap.Size()>0){
                    for(User_Business_Role__c ubr : [Select ID, Business_Role__c, Unique_Key__c, User__c, User__r.Profile.Name from User_Business_Role__c where User__c IN:userUBRMap.Keyset()]){
                        if(userRecMap.get(ubr.User__c).Profile.Name == 'CIO User' || userRecMap.get(ubr.User__c).Profile.Name == 'Legal User'){
                            
                        }
                        else{
                            User_Business_Role__c newUBR = userUBRMap.get(ubr.User__c);
                            newUBR.addError(label.UniqueBusinessRole);
                        }
                    }
                }
                if(uniqueKeyUBRMap.Size()>0){
                    for(User_Business_Role__c ubr : [Select ID, Business_Role__c, Unique_Key__c, User__c, User__r.Profile.Name from User_Business_Role__c where Unique_Key__c IN:uniqueKeyUBRMap.Keyset()]){
                        if(userRecMap.get(ubr.User__c).Profile.Name == 'CIO User' || userRecMap.get(ubr.User__c).Profile.Name == 'Legal User'){
                            User_Business_Role__c newUBR = uniqueKeyUBRMap.get(ubr.Unique_Key__c);
                            newUBR.addError(label.UniqueBusinessRoleForCIOandLegal);
                        }
                    }
                }
            }
            
            if(userMap.size()>0 && businessRoleMap.size()>0){
                for(SObject obj :newItems.values()){
                    User_Business_Role__c ubr = (User_Business_Role__c)obj;
                    List<string> usrConList = new List<string>();
                    usrConList = userMap.get(ubr.User__c);
                    if(!usrConList.contains(businessRoleMap.get(ubr.Business_Role__c))){
                        ubr.addError(label.BusinessRoleCountry);
                    }
                }
            }
        }
    }
    
    //ES20-12426
    //populate country code map in below method
    public static Map<String,String> getCountryCodeMap (){
        //fetching the country code and country name from custom metadata and creating MAP with Country code and country Name   
        for(CountryCode_To_StandardTerritory_Setting__mdt ccode : [SELECT MasterLabel, QualifiedApiName,Standard_Territory_Country_Name__c FROM CountryCode_To_StandardTerritory_Setting__mdt]){            
            countryCodeMap.put(ccode.QualifiedApiName,ccode.Standard_Territory_Country_Name__c);  
        }
        return countryCodeMap;
    }
    
    //get country Names -ES20-12426 
    public static Map<String,List<String>> getChildCountryCode(List<String> countryCodeList,String geoType){
        //Set<String> countrySet = new Set<String>();
        Map<String,List<String>> mapCountryCode = new Map<String,List<String>>();
        List<Geography__c> countryList = new List<Geography__c>();        
        if(geoType == 'cluster' && Schema.SObjectType.Geography__c.isAccessible()){
            countryList = [SELECT Id,Code__c,Parent_Geography__r.Code__c FROM Geography__c WHERE Parent_Geography__r.Code__c IN:countryCodeList];       
            for(Geography__c geo : countryList){
                if(mapCountryCode.containsKey(geo.Parent_Geography__r.Code__c)){
                    mapCountryCode.get(geo.Parent_Geography__r.Code__c).add(geo.Code__c);                        
                }
                else{
                    mapCountryCode.put(geo.Parent_Geography__r.Code__c, new List<String>{geo.Code__c});
                }
            }
        }
        if(geoType == 'hub' && Schema.SObjectType.Geography__c.isAccessible()){           
            countryList = [SELECT Id,Code__c,Parent_Geography__r.Parent_Geography__r.Code__c FROM Geography__c WHERE Parent_Geography__r.Parent_Geography__r.Code__c IN:countryCodeList]; 
            for(Geography__c geo : countryList){
                if(mapCountryCode.containsKey(geo.Parent_Geography__r.Parent_Geography__r.Code__c)){
                    mapCountryCode.get(geo.Parent_Geography__r.Parent_Geography__r.Code__c).add(geo.Code__c);                        
                }
                else{
                    mapCountryCode.put(geo.Parent_Geography__r.Parent_Geography__r.Code__c, new List<String>{geo.Code__c});
                }
            }
        }
        if(geoType == 'market' && Schema.SObjectType.Geography__c.isAccessible() ){
            countryList = [SELECT Id,Code__c,Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c FROM Geography__c WHERE Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c IN:countryCodeList];      
            for(Geography__c geo : countryList){
                if(mapCountryCode.containsKey(geo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c)){
                    mapCountryCode.get(geo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c).add(geo.Code__c);                        
                }
                else{
                    mapCountryCode.put(geo.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c, new List<String>{geo.Code__c});
                }
            }
        }              
        return mapCountryCode; 
    }
    
    //get User Business Role Name of User- ES20-12426
    public static Map<Id,String> getUserBRMap(Set<Id> userIdSet){
        Map<Id,String> userBRMap = new Map<Id,String>();
        if(Schema.sObjectType.User_Business_Role__c.isAccessible()){
            List<User_Business_Role__c> userBRList = [SELECT id,User__c,Business_Role__c, Business_Role__r.Global_Equivalent__c,User__r.FirstName  from User_Business_Role__c where User__c IN : userIdSet];
            for(User_Business_Role__c ubr : userBRList){
                userBRMap.put(ubr.user__c,ubr.Business_Role__r.Global_Equivalent__c); 
            }
        }           
        return userBRMap;
        
    }
    
    //12426
    public static void assignUserToTerritories(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){          
        countryCodeMap = getCountryCodeMap();
        Set<id> userIdSet = new Set<id>();
        Map<id, id> userMapvalue = new  Map<id, id>();
        Map<id, id> userOldMapvalue = new  Map<id, id>();
        Map<Id,User_Business_Role__c> newUBRMap = (Map<id,User_Business_Role__c>)newItems;
        Map<Id,User_Business_Role__c> oldUBRMap = (Map<id,User_Business_Role__c>)oldItems;
        
        for(User_Business_Role__c ubr : newUBRMap.values()){
            userMapvalue.put(ubr.id,ubr.User__c);
            userIdSet.add(ubr.User__c);
        }
        
        userBRMap = getUserBRMap(userIdSet);
        
        if(oldUBRMap!= null && oldUBRMap.size()>0){
            for(User_Business_Role__c ubr : oldUBRMap.values()){
                userOldMapvalue.put(ubr.id,ubr.User__c);
            }
        }
        userSet = new Set<String>();            
        userCountryMap = new Map<Id,List<String>>(); 
        Set<String> newUsersHubCountryList = new Set<String>();
        Set<String> newUsersClusterCountryList = new Set<String>();
        Set<String> newUsersMarketCountryList = new Set<String>();
        Map<Id,List<String>> userClusterCountryMap = new Map<Id,List<String>>();//Map of users with cluster country        
        Map<String,List<String>> childClusterCountryMap = new Map<String,List<String>>();//Map of cluster country with their respective child countries
        Map<Id,List<String>> userChildClusterCountryMap = new Map<Id,List<String>>();//Map of users with lowest level country under cluster
        List<String> allClusterCountryList = new List<String>();
        Map<Id,List<String>> userHubCountryMap = new Map<Id,List<String>>();//Map of users with Hub country        
        Map<String,List<String>> childHubCountryMap = new Map<String,List<String>>();//Map of Hub country with their respective child countries
        Map<Id,List<String>> userChildHubCountryMap = new Map<Id,List<String>>();//Map of users with lowest level country under Hub
        List<String> allHubCountryList = new List<String>();
        Map<Id,List<String>> userMarketCountryMap = new Map<Id,List<String>>();//Map of users with Hub country        
        Map<String,List<String>> childMarketCountryMap = new Map<String,List<String>>();//Map of Hub country with their respective child countries
        Map<Id,List<String>> userChildMarketCountryMap = new Map<Id,List<String>>();//Map of users with lowest level country under Market
        List<String> allMarketCountryList = new List<String>();
        Map<id, User> user1Map = new Map<id, User>();
       
        for(User u : [Select id, Assigned_Hubs__c,Assigned_Clusters__c,Assigned_Markets__c,Available_Countries__c,ProfileId from
                      User where id IN: userMapvalue.values()]){
                          user1Map.put(u.id,u); 
                      }        
        
        
        for(User_Business_Role__c sob :newUBRMap.values()){           
            User newUser = user1Map.get(sob.User__c);
            
            if((oldItems == null) || (oldItems!= null && 
                                      ((newUser.Assigned_Clusters__c != null)
                                       || (newUser.Assigned_Hubs__c != null)
                                       || (newUser.Assigned_Markets__c != null)
                                       || (newUser.Available_Countries__c != null ) )) 
               
              ){
                  
                  if(allQualityTerritoryBRList.contains(userBRMap.get(newUser.Id))){
                      
                      List<String> tempCountryList = new List<String>();                
                      if(newUser.Assigned_Clusters__c != null){  //as we are deleting all previous territory assignment first, existing valid assignment may be deleted,so avoiding old new check                     
                          tempCountryList = new List<String>(); 
                          tempCountryList = (newUser.Assigned_Clusters__c).split(';');
                          userClusterCountryMap.put(newUser.Id,tempCountryList);  
                      }
                      if(newUser.Assigned_Hubs__c != null){ 
                          tempCountryList = new List<String>();
                          tempCountryList = (newUser.Assigned_Hubs__c).split(';');
                          userHubCountryMap.put(newUser.Id,tempCountryList);
                      }                    
                      if(newUser.Assigned_Markets__c != null){
                          tempCountryList = new List<String>(); 
                          tempCountryList = (newUser.Assigned_Markets__c).split(';'); 
                          userMarketCountryMap.put(newUser.Id,tempCountryList);
                      }                
                  }    
              }                   
        } 
        List<String> tempChildCountryList = new List<String>();
        //Cluster
        //populating the list of all cluster countries for the users getiing updated        
        for(List<String> ccountryList : userClusterCountryMap.values()){            
            allClusterCountryList.addAll(ccountryList);
        }        
        //get the map of cluster country with their respective child countries from database
        childClusterCountryMap = getChildCountryCode(allClusterCountryList,'cluster');        
        //map of users with child country codes
        for(String uid:userClusterCountryMap.keySet()){
            if(null != userClusterCountryMap.get(uid)){
                tempChildCountryList = new List<String>();
                for(String ccountry : userClusterCountryMap.get(uid)){
                    if(null !=childClusterCountryMap.get(ccountry)){
                        tempChildCountryList.addAll(childClusterCountryMap.get(ccountry));                                         
                        userChildClusterCountryMap.put(uid,tempChildCountryList);    
                    }                               
                }     
            }            
        }        
        //Cluster End
        //Hub Start
        //populating the list of all hub countries for the users getiing updated        
        for(List<String> ccountryList : userHubCountryMap.values()){            
            allHubCountryList.addAll(ccountryList);             
        }        
        //get the map of cluster country with their respective child countries from database
        childHubCountryMap = getChildCountryCode(allHubCountryList,'hub');        
        //map of users with child country codes
        for(String uid:userHubCountryMap.keySet()){
            if(null!= userHubCountryMap.get(uid)){
                tempChildCountryList = new List<String>();
                for(String ccountry : userHubCountryMap.get(uid)){
                    if(null!=childHubCountryMap.get(ccountry)){
                        tempChildCountryList.addAll(childHubCountryMap.get(ccountry));                                           
                        userChildHubCountryMap.put(uid,tempChildCountryList);
                    }    
                }     
            }            
        }
        //Hub end
        //Market Start
        //populating the list of all hub countries for the users getiing updated        
        for(List<String> ccountryList : userMarketCountryMap.values()){            
            allMarketCountryList.addAll(ccountryList);
        }       
        //get the map of cluster country with their respective child countries from database
        childMarketCountryMap = getChildCountryCode(allMarketCountryList,'Market');        
        //map of users with child country codes
        for(String uid:userMarketCountryMap.keySet()){            
            if(null != userMarketCountryMap.get(uid)){
                tempChildCountryList = new List<String>();
                for(String ccountry : userMarketCountryMap.get(uid)){                    
                    if(null != childMarketCountryMap.get(ccountry)){
                        tempChildCountryList.addAll(childMarketCountryMap.get(ccountry));                                                
                        userChildMarketCountryMap.put(uid,tempChildCountryList);    
                    }                               
                }    
            }             
        }        
        //Market End
        
        //the below for loop is to derive the users lowest level country
        for(User_Business_Role__c sob :newUBRMap.values()){           
            User newUser = user1Map.get(sob.User__c);
                       
            newUsersAllCountryList= new List<String>(); //this list is to capture all lowest level countries of an user be it from hub,market,cluster or country itself               
            Boolean geographyAdded = false;
            //check if available country has changed  
            List<String> tempCountryList = new List<String>();                                        
            if((oldItems == null) || (oldItems!= null && 
                                      ((newUser.Assigned_Clusters__c != null)
                                       || (newUser.Assigned_Hubs__c != null )
                                       || (newUser.Assigned_Markets__c != null)
                                       || (newUser.Available_Countries__c != null )))
               
              ){
                  if(newUser.Available_Countries__c != null){ 
                      tempCountryList = new List<String>();
                      tempCountryList = (newUser.Available_Countries__c).split(';');
                      for(String str : tempCountryList){ // can't avoid this for loop                        
                          if(null != countryCodeMap.get(str)){
                              newUsersAllCountryList.add(countryCodeMap.get(str));    
                          }
                      }
                      geographyAdded = true;
                  }
                  if(newUser.Assigned_Clusters__c != null){  
                      tempCountryList = new List<String>(); 
                      geographyAdded = true;
                      if(null != userChildClusterCountryMap.get(newUser.Id)){
                          for(String temp : userChildClusterCountryMap.get(newUser.Id)){
                              newUsersClusterCountryList.add(temp);  
                          }    
                      }            
                      for(String str : newUsersClusterCountryList){ // can't avoid this for loop
                          if(null != countryCodeMap.get(str)){
                              newUsersAllCountryList.add(countryCodeMap.get(str));
                          }
                      }                              
                  }
                  if(newUser.Assigned_Hubs__c != null){ 
                      tempCountryList = new List<String>(); 
                      geographyAdded = true;
                      if(null != userChildHubCountryMap.get(newUser.Id)){
                          for(String temp : userChildHubCountryMap.get(newUser.Id)){
                              newUsersHubCountryList.add(temp);  
                          }    
                      }             
                      for(String str : newUsersHubCountryList){ // can't avoid this for loop
                          if(null != countryCodeMap.get(str)){
                              newUsersAllCountryList.add(countryCodeMap.get(str));
                          }
                      }                            
                  }
                  if(newUser.Assigned_Markets__c != null){ 
                      geographyAdded = true;
                      if(null != userChildMarketCountryMap.get(newUser.Id)){
                          for(String temp : userChildMarketCountryMap.get(newUser.Id)){
                              newUsersMarketCountryList.add(temp);  
                          }    
                      }             
                      for(String str : newUsersMarketCountryList){ // can't avoid this for loop
                          if(null != countryCodeMap.get(str)){
                              newUsersAllCountryList.add(countryCodeMap.get(str));
                          }
                      }                              
                  } 
              }      
            if((geographyAdded == true)){       
                //creating set of country names from all users in context
                countrySet.addAll(newUsersAllCountryList);                        
                //creating map of users and their respective country names                                   
                userCountryMap.put(newUser.Id,newUsersAllCountryList); 
                userSet.add(newUser.Id);              
            }else if(geographyAdded == false){
                userSet.add(newUser.Id);    
            }
        }        
        //fetching the existing user territory assignment details and delete those records.
        String readWriteBR = System.label.Standard_Territory_Global_Equivalent;
        List<String> listOfReadWriteBR = readWriteBR.split(';');
        Set<string> usrGlobalEqSet = new Set<String>();
        
        for(User_Business_Role__c ubr : [SELECT id,User__c,Business_Role__c, Business_Role__r.Global_Equivalent__c,User__r.FirstName  from User_Business_Role__c where Business_Role__r.Global_Equivalent__c Not IN : listOfReadWriteBR and User__c In: userSet]){
            usrGlobalEqSet.add(ubr.User__c);
        }
        if(!userSet.isEmpty() && !countrySet.isEmpty()){
            deleteAllExistingTerritoryAssignment(usrGlobalEqSet);
        }
        if(!countrySet.isEmpty()){
            createTerritoryAssignments(countrySet,userCountryMap,userBRMap);
        }
    }    
    
    
    /** 
* @description: deleteAllExistingTerritoryAssignment 
* @purpose: The below method deletes the existing territory assignment. This is needed to remove Assigned Territory ig Global Equivalent doesnt matches users in Business Role.    
* @parameters: Set<String> userIdSet
*/
    public static void  deleteAllExistingTerritoryAssignment(Set<String> userIdSet){
        try{
            List<UserTerritory2Association> userterritoryreclist=new List<UserTerritory2Association>([SELECT Id,UserId,Territory2.Name FROM UserTerritory2Association WHERE UserId IN :userIdSet]);
            
            List<UserTerritory2Association> userterritorytodel=new List<UserTerritory2Association>(); 
            
            for(UserTerritory2Association uta:userterritoryreclist){
                if(uta.Territory2.Name.equals(System.label.Quality_Manager_Read_Write)){
                    userterritorytodel.add(uta);
                }
            }
            if(userterritoryreclist.size()>0){
                System.enqueueJob(new EDGE_UBRTriggerHelperQueueable(userterritorytodel, 'Delete'));
            }
        }catch(Exception ex){   
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
        }   
    }   
    /** 
* @description: createTerritoryAssignments
* @purpose: The below method creates Territory assignment with the users
* @parameters: Set<String> countrySet,Map<Id,List<String>> userCountryMap,Map<Id,String> userBRMap
*/
    public static void createTerritoryAssignments(Set<String> countrySet,Map<Id,List<String>> userCountryMap,Map<Id,String> userBRMap){
        usrTerritorylist=new List<UserTerritory2Association>();            
        //getting all child territories where Parent is Country/Cluster  name and grand parent is Sales Territory 
        Map<Id,Territory2> childTerritoryMap=new Map<Id,Territory2>([SELECT Id,Name,ParentTerritory2.ParentTerritory2.Name,ParentTerritory2.Name 
                                                                     FROM Territory2 
                                                                     WHERE ParentTerritory2.Name IN :countrySet AND 
                                                                     (ParentTerritory2.ParentTerritory2.Name=:System.Label.EDGE_Parent_Sales_Territory OR ParentTerritory2.ParentTerritory2.ParentTerritory2.Name=:System.Label.EDGE_Parent_Sales_Territory)]);         
        for(Territory2 territory : childTerritoryMap.values()){
            if(territory.ParentTerritory2.Name != null){
                String tempName = territory.ParentTerritory2.Name+territory.Name;                
                childTerritoryNameMap.put(tempName,territory.Id);
            } 
        }
        
        String readWriteBR = System.label.Standard_Territory_Global_Equivalent;
        List<String> listOfReadWriteBR = readWriteBR.split(';');
        
        //Assign Users to territories according to User Business Role 
        for(Id userId : userCountryMap.keySet()){               
            for(String countryName : userCountryMap.get(userId)){                  
                
                if(!userBRMap.isEmpty() && listOfReadWriteBR.size() > 0 && listOfReadWriteBR.contains(userBRMap.get(userId))){
                    
                    String tempName = countryName+System.label.Quality_Manager_Read_Write;  
                    
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        
                        createUserTerrList(usrTerAsso);
                        
                    }
                } 
                
                
            }                
        }
        
        try{
            //Inserting the list for assigning users to territory
            if(usrTerritorylist.size()>0){                
                //Database.Insert(usrTerritorylist); 
                System.enqueueJob(new EDGE_UBRTriggerHelperQueueable(usrTerritorylist, 'After Insert'));
                
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'-- Exception ex'+ex+'--on line--'+ex.getLineNumber());    
        }   
    }
    
    /**
* @description  : createUserTerrList -> ES20-12426 
* @purpose : Creates a list of UserTerritory2Association to be inserted later
* @parameters: UserTerritory2Association 
*/
    public static void createUserTerrList(UserTerritory2Association usrTerAsso){
        String key = usrTerAsso.Territory2Id+'_'+usrTerAsso.UserId;
        if(!terrUserIdKey.contains(key))
        {
            terrUserIdKey.add(key);
            usrTerritorylist.add(usrTerAsso);  
        }     
    }
    
    
}