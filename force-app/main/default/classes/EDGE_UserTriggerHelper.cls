/**
* @Description: EDGE_UserTriggerHelper

* @Purpose: The requirement is to assign users to the Standard Territory and manage their access level
(Eg: Sales Rep will have ReadOnly Access & MDM has Read/Write Access) to Accounts(Outlet, Supplier, Owner/Operator)   
User Story : ES20-219


* @History                                                            


* @VERSION   		AUTHOR            	DATE              DETAIL

* 	1.0   	Sagar Barman          13/02/2019      	Initial Development
* 	1.1   	Anuja Chattopadhyay   10/09/2019      	Added method updateCallPerDayInTerHierarchy,US3343-Region Calls Per Day
* 	1.2   	Aparajita             15/03/2021      	Added method addTraxUserUpdate(ES20-9820)
* 	1.3   	Dinesh Sharma         22/04/2021      	Updated the method createTerritoryAssignments (ES20-10193)
* 	1.4   	Aparajita			  20/05/2021	   	Updated the method createTerritoryAssignments (ES20-10074)
* 	1.5		Monalisa Halder	      20/05/2021		ES20-10013
* 	1.6   	Amar Deep             14/06/2021		NCP-3454
* 	1.7   	Aparajita			  15/06/2021       	Added the method fetchInactiveDistSRSMFromAccount (ES20-10310)
* 	1.8   	Aparajita			  27/12/2021       	ES20-11673(Method:checkAndGenerateSharing,fetchHighestGeoCodeMethod)
* 	1.9   	Sukanya Chatterjee    28/12/2021	    ES20-11674(Method:validateAndReGenerateSharing)
*   2.0   	Prasanth T            28/12/2021	    ES20-11675(Method:validateAndReGenerateSharing)
*   2.1     Sayan Mullick         15/11/2021        Method:addUserToPublicGroup
*	2.2		Aparajita	          25/02/2022		ES20-12083(Method:createTerritoryAssignments(modified), createUserTerrList(new))
*   2.3     Narayana              14/04/2022        NCP-6401
*   2.4     Jagadeesh Yarra       24/06/2022        Add Users to All CST Users Group.
*   2.5     SaiKiran              09/02/2023        CUS-42. Giving Territory access to Ireland Persona.
*   2.6     Tanishq Banerjee      21/04/2023        GT-14 - Create a new node and add the assignment rules in Standard Territory Model and new Hub, cluster and country
*   2.7     Wribhu Bose           18/05/2023        GT-66 - Added GT permission sets in fetch query through label (method: createTerritoryAssignments)
*	2.9		Shivam Chauhan		  18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*   3.0     Kapil Baliyan         11/03/2024        151346 : Commented WITH SECURITY_ENFORCED
*/

public without sharing class EDGE_UserTriggerHelper {
    
    public static Map<Id,List<String>> userCountryMap = new Map<Id,List<String>>();
    public static Map<Id,String> userProfileMap = new Map<Id,String>();
    public static List<String> newUsersAllCountryList= new List<String>();
    public static Set<String> countrySet = new Set<String>();
    public static Set<String> userSet = new Set<String>();        
    public static Map<String,Id> childTerritoryNameMap = new Map<String,Id>();        
    public static List<UserTerritory2Association> usrTerritorylist=new List<UserTerritory2Association>();        
    public static List<UserTerritory2Association> usrTerritorySet=new List<UserTerritory2Association>();        
    public static Map<String,String> countryCodeMap = new Map<String,String>(); 
    //getting eligible standard territory profiles
    public static String allSalesTerritoryProfiles = System.Label.Territory_Profiles;
    public static String[] allSalesTerritoryProfilesList = allSalesTerritoryProfiles.split(',');
    
    //GT-14
    public static String allGlobalTravelProfiles = System.Label.Global_Travel_Profiles;
    public static String[] allGlobalTravelProfilesList = allGlobalTravelProfiles.split(',');
    
    //ES20-10013
    private static String DIST_SALES_REP_PROFILE_STR = 'Distributor Sales Representative';
    private static String DIST_SALES_MANAGER_PROFILE_STR = 'Distributor Sales Manager';
    private static String DIST_DATA_MANAGER_PROFILE_STR = 'Distributor Data Manager';
    //added by Aparajita -> ES20-12083
    public static Set<String> terrUserIdKey = new Set<String>();
    public static List<String> D1_PROFILE_IDS =  new List<String>();
    
    
    
    //populate country code map in below method
    public static Map<String,String> getCountryCodeMap (){
        //fetching the country code and country name from custom metadata and creating MAP with Country code and country Name   
        for(CountryCode_To_StandardTerritory_Setting__mdt ccode : [SELECT MasterLabel, QualifiedApiName,Standard_Territory_Country_Name__c FROM CountryCode_To_StandardTerritory_Setting__mdt]){            
            countryCodeMap.put(ccode.QualifiedApiName,ccode.Standard_Territory_Country_Name__c);  
        }
        return countryCodeMap;
    }
    //get profile Name of User
    public static Map<Id,String> getUserProfileMap(Set<Id> userIdSet){
        Map<Id,String> userProfileMap = new Map<Id,String>();
        if(Schema.sObjectType.User.isAccessible()){
            List<User> userList = [SELECT Id,Name,ProfileId,Profile.Name FROM User WHERE ID IN : userIdSet];
            for(User usr : userList){
                userProfileMap.put(usr.Id,usr.Profile.Name);        
            }
        }           
        return userProfileMap; 
    } 
    
    //get country Names 
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
    
    /** 
* @description: assignUserToTerritories
* @purpose: The below method takes all the users which are getting updated, then it checks the users profile and availablle to countries. 
After that it calls the createTerritoryAssignments method to assign to the territories as per their profile.
* @parameters: Map<Id, SObject> newItems, Map<Id, SObject> oldItems
*/
    public static void assignUserToTerritories(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){          
        countryCodeMap = getCountryCodeMap(); 
        userProfileMap = getUserProfileMap(newItems.keySet());
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
        for(SObject sob :newItems.values()){           
            User newUser = (User)sob;
            User oldUser;
            if(oldItems != null){
                oldUser = (User)oldItems.get(newUser.Id);    
            }
            if((oldItems == null) || (oldItems!= null && 
                                      ((newUser.Assigned_Clusters__c != null && (oldUser.Assigned_Clusters__c != newUser.Assigned_Clusters__c))
                                       || (newUser.Assigned_Hubs__c != null && (oldUser.Assigned_Hubs__c != newUser.Assigned_Hubs__c))
                                       || (newUser.Assigned_Markets__c != null && (oldUser.Assigned_Markets__c != newUser.Assigned_Markets__c))
                                       || (newUser.Available_Countries__c != null && (oldUser.Available_Countries__c != newUser.Available_Countries__c))
                                       || (newUser.ProfileId != oldUser.ProfileId)))   
              ){
                  //GT-14
                  if(allSalesTerritoryProfilesList.contains(userProfileMap.get(newUser.Id)) 
                     || allGlobalTravelProfilesList.contains(userProfileMap.get(newUser.Id))){
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
            //GT-14
            for(String str: ccountryList){
                if(!System.Label.Global_Travel_Hub_Code.equalsIgnoreCase(str)){
                    allHubCountryList.add(str);
                }
            }            
            //allHubCountryList.addAll(ccountryList);             
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
        for(SObject sob :newItems.values()){
            User newUser = (User)sob;
            User oldUser;
            if(oldItems != null){
                oldUser = (User)oldItems.get(newUser.Id);    
            }            
            newUsersAllCountryList= new List<String>(); //this list is to capture all lowest level countries of an user be it from hub,market,cluster or country itself               
            Boolean geographyAdded = false;
            //check if available country has changed  
            List<String> tempCountryList = new List<String>();                                        
            if((oldItems == null) || (oldItems!= null && 
                                      ((newUser.Assigned_Clusters__c != null && (oldUser.Assigned_Clusters__c != newUser.Assigned_Clusters__c))
                                       || (newUser.Assigned_Hubs__c != null && (oldUser.Assigned_Hubs__c != newUser.Assigned_Hubs__c))
                                       || (newUser.Assigned_Markets__c != null && (oldUser.Assigned_Markets__c != newUser.Assigned_Markets__c))
                                       || (newUser.Available_Countries__c != null && (oldUser.Available_Countries__c != newUser.Available_Countries__c))))
               || (newUser.ProfileId != oldUser.ProfileId) || (newUser.C360_Customer_360_User__c != oldUser.C360_Customer_360_User__c)
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
                      //GT-14
                      if(newUser.Assigned_Hubs__c.contains(System.Label.Global_Travel_Hub_Code)){
                          newUsersAllCountryList.add(System.Label.Global_Travel_Terr_Model_Name);
                      }
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
        if(!userSet.isEmpty() && !countrySet.isEmpty()){
            System.debug(LoggingLevel.DEBUG,'Enters here...');
            deleteAllExistingTerritoryAssignment(userSet);
        }
        if(!countrySet.isEmpty()){
            
            createTerritoryAssignments(countrySet,userCountryMap,userProfileMap);
        }
    }    
    
    /** 
* @description: deleteAllExistingTerritoryAssignment
* @purpose: The below method deletes all the existing territory assignment. This is needed to remove duplicate error while assigning users in Territory.    
* @parameters: Set<String> userIdSet
*/
    public static void  deleteAllExistingTerritoryAssignment(Set<String> userIdSet){
        try{
            List<UserTerritory2Association> userterritoryreclist=new List<UserTerritory2Association>([SELECT Id,UserId,Territory2Id FROM UserTerritory2Association 
                                                                                                      WHERE UserId IN :userSet]);
            if(userterritoryreclist.size()>0){
                Database.Delete(userterritoryreclist);
            }
        }catch(Exception ex){   
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
        }   
    }   
    
    /** 
* @description: createTerritoryAssignments
* @purpose: The below method creates Territory assignment with the users
* @parameters: Set<String> countrySet,Map<Id,List<String>> userCountryMap,Map<Id,String> userProfileMap
*/
    public static void createTerritoryAssignments(Set<String> countrySet,Map<Id,List<String>> userCountryMap,Map<Id,String> userProfileMap){
        usrTerritorylist=new List<UserTerritory2Association>();            
        //getting all child territories where Parent is Country/Cluster  name and grand parent is Sales Territory 
        Map<Id,Territory2> childTerritoryMap=new Map<Id,Territory2>([SELECT Id,Name,ParentTerritory2.ParentTerritory2.Name,ParentTerritory2.Name 
                                                                     FROM Territory2 
                                                                     WHERE ParentTerritory2.Name IN :countrySet AND 
                                                                     (ParentTerritory2.ParentTerritory2.Name=:System.Label.EDGE_Parent_Sales_Territory OR ParentTerritory2.ParentTerritory2.ParentTerritory2.Name=:System.Label.EDGE_Parent_Sales_Territory
                                                                      OR ParentTerritory2.Name =:System.Label.Global_Travel_Terr_Model_Name)]);  //GT-14       
        for(Territory2 territory : childTerritoryMap.values()){
            if(territory.ParentTerritory2.Name != null){
                String tempName = territory.ParentTerritory2.Name+territory.Name;
                childTerritoryNameMap.put(tempName,territory.Id);
            } 
        }
        //CUS-439 Change Start
        Map<Id,User> logisticUserMap = new Map<Id,User>([SELECT Id, C360_Customer_360_User__c FROM User WHERE Id IN: userCountryMap.keySet() 
                                                         AND C360_Customer_360_User__c= TRUE 
                                                         AND Profile.Name =: System.Label.C360_Minumum_Access]);
        Set<Id> logisticUserPerSetGroupId = new Set<Id>();
        if(!logisticUserMap.isEmpty()){
            for(PermissionSetAssignment prSetAssignment: [SELECT Id,AssigneeId FROM PermissionSetAssignment WHERE 
                                                          AssigneeId IN: logisticUserMap.keySet() AND 
                                                          PermissionSetGroup.DeveloperName =: System.Label.C360_Logistic_Team]){
                                                              logisticUserPerSetGroupId.add(prSetAssignment.AssigneeId);
                                                          }
        }
        //CUS-439 Change End
        //CUS-42 Change Start
        Map<Id,User> c360UserMap = new Map<Id,User>([SELECT Id, C360_Customer_360_User__c FROM User WHERE Id IN: userCountryMap.keySet() AND C360_Customer_360_User__c= TRUE]);//CUS
        Set<Id> permissionSetIds = new Set<Id>();
        for (SetupEntityAccess access : [SELECT ParentId FROM SetupEntityAccess WHERE SetupEntityId IN (SELECT Id 
                                                                                                        FROM CustomPermission 
                                                                                                        WHERE DeveloperName =: System.Label.C360_Custom_Permission
                                                                                                       )                
                                        ]) {
                                            permissionSetIds.add(access.ParentId);
                                        }
        
        Set<Id> userPerSetGroupId = new Set<Id>();
        if(!c360UserMap.isEmpty() && permissionSetIds.size() >0){
            for(PermissionSetAssignment prSetAssignment: [SELECT Id,Assignee.Name,PermissionSetId, PermissionSet.Label 
                                                          FROM PermissionSetAssignment WHERE AssigneeId IN: c360UserMap.keySet() AND 
                                                          PermissionSetId IN: permissionSetIds]){
                                                              if(!logisticUserPerSetGroupId.contains(prSetAssignment.AssigneeId)){
                                                                  userPerSetGroupId.add(prSetAssignment.AssigneeId);
                                                              }
                                                          }
        }
        //CUS-42 Change End
        
        String readOnlyProfiles = System.label.Standard_Territory_Read_Only_Profiles;
        List<String> listOfReadOnlyProfiles = readOnlyProfiles.split(';');
        String readWriteProfiles = System.label.Standard_Territory_Read_Write_Profiles;
        List<String> listOfReadWriteProfiles = readWriteProfiles.split(';');
        
        
        //ES20-10193
        String distributorReadOnlyProfiles = System.label.Standard_Territory_Distributor_Read_Only_Profile;
        List<String> listOfDistributorReadOnlyProfile = distributorReadOnlyProfiles.split(';');
        
        //ES20-10074
        String distributorSalesUserReadOnlyProfiles = System.label.Standard_Territory_Distributor_Sales_User_Read_Only_Profile;
        List<String> listOfDistributorSalesUserReadOnlyProfile = distributorSalesUserReadOnlyProfiles.split(';');
        
        String readWriteD1Profiles = System.label.D1_Territory_Read_Write_Profiles;
        List<String> listOfD1ReadWriteProfiles = readWriteD1Profiles.split(';');
        String readD1Profiles = System.label.D1_Territory_Read_Profiles;
        List<String> listOfD1ReadProfiles = readD1Profiles.split(';');
        //CST changes
        String cstReadProfiles = System.label.CST_Read_Profiles;
        List<String> listOfCSTReadProfiles = cstReadProfiles.split(';');
        
        //GT-14
        List<String> gtPermissionSet = System.Label.GT_Permission_Set.split(','); //GT-66
        List<PermissionSetAssignment> lstGTPerSet = [SELECT Id, PermissionSet.Name,AssigneeId
                                                     FROM PermissionSetAssignment
                                                     WHERE PermissionSet.Name IN:gtPermissionSet]; //WITH SECURITY_ENFORCED -- Commented By Kapil for 151346 because this is causing registration issue for D1                                                        
        //Assign Users to territories according to User Profiles
        for(Id userId : userCountryMap.keySet()){               
            for(String countryName : userCountryMap.get(userId)){                  
                if(!userProfileMap.isEmpty() && listOfReadOnlyProfiles.size() > 0 && listOfReadOnlyProfiles.contains(userProfileMap.get(userId))){                                                 
                    String tempName = countryName+System.label.Read_Only;                                              
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){                          
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                }
                else if(!userProfileMap.isEmpty() && listOfReadWriteProfiles.size() > 0 && listOfReadWriteProfiles.contains(userProfileMap.get(userId))){                        
                    String tempName = countryName+System.label.Read_Write;                                              
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                } 
                
                //ES20-10193
                
                else if(!userProfileMap.isEmpty() && listOfDistributorReadOnlyProfile.size() > 0 && listOfDistributorReadOnlyProfile.contains(userProfileMap.get(userId))){ //userprofile null check,//null check for list, list size check
                    String tempName = countryName+System.label.Distributor_Read_Only; 
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    
                    
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){    // childTerritoryNameMap null check      map.containsKey childTerritoryNameMap.get(tempName) != null                
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                }
                
                //ES20-10074
                else if(!userProfileMap.isEmpty() && listOfDistributorSalesUserReadOnlyProfile.size() > 0 && listOfDistributorSalesUserReadOnlyProfile.contains(userProfileMap.get(userId))){ //userprofile null check,//null check for list, list size check
                    String tempName = countryName+System.label.Distributor_Sales_Rep_Manager_Read_Only; 
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){    // childTerritoryNameMap null check      map.containsKey childTerritoryNameMap.get(tempName) != null                
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                }
                
                if(listOfD1ReadWriteProfiles.contains(userProfileMap.get(userId))){ //NCP-4791
                    String tempName;    
                    if(userProfileMap.get(userId)== System.label.D1_QCT_Profile_Name){//NCP-4791
                        tempName = countryName+System.label.D1_Territory_Read_Write_QCT;  //NCP-4791
                    }                            
                    else{
                        tempName = countryName+System.label.D1_Territory_Read_Write;   
                    }              
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                } else if(listOfD1ReadProfiles.contains(userProfileMap.get(userId))) {
                    String tempName = countryName+System.label.D1_Territory_Read;                                              
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                }                
                //CST changes
                if(listOfCSTReadProfiles.contains(userProfileMap.get(userId))) {
                    String tempName = countryName+System.label.CST_Territory_Read;                                              
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  //added by Aparajita -> ES20-12083  
                    }
                }  
                //C360 logic CUS-439 -> start
                if(!logisticUserPerSetGroupId.isEmpty() && logisticUserPerSetGroupId.contains(userId)) {
                    String tempName = countryName+System.Label.C360_Logistic_Rep_RW;
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  
                    }
                }
                //C360 logic CUS-439 -> end
                //C360 logic CUS-42 -> start
                if(!userPerSetGroupId.isEmpty() && userPerSetGroupId.contains(userId)) {
                    String tempName = countryName+System.label.C360_Territory_Read_Write;
                    UserTerritory2Association usrTerAsso = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso.UserId=userId;
                        createUserTerrList(usrTerAsso);  
                    }
                    tempName = countryName+System.label.C360_Read_Write_Support;
                    UserTerritory2Association usrTerAsso1 = new UserTerritory2Association();
                    if(!childTerritoryNameMap.isEmpty() && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){                            
                        usrTerAsso1.Territory2Id=childTerritoryNameMap.get(tempName);
                        usrTerAsso1.UserId=userId;
                        createUserTerrList(usrTerAsso1);  
                    }
                }
                //C360 logic CUS-42 -> end
                //GT-14 
                if(allGlobalTravelProfilesList.contains(userProfileMap.get(userId))){
                    Boolean flagPermSet = false;
                    for(PermissionSetAssignment usrPerSet:lstGTPerSet){//RDM
                        if(usrPerSet.AssigneeId == userId){
                            flagPermSet=true;
                            break;
                        }
                    }                    
                    
                    String tempName ='';                  
                    if(flagPermSet){//RDM
                        tempName = countryName+System.Label.GT_Read_Write;    
                    }
                    if(tempName != '' && flagPermSet && !childTerritoryNameMap.isEmpty() 
                       && childTerritoryNameMap.containsKey(tempName) && childTerritoryNameMap.get(tempName) != null){
                           UserTerritory2Association usrTerAsso = new UserTerritory2Association();
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
                Database.Insert(usrTerritorylist);  
            }
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG, '-- Exception ex'+ex+'--on line--'+ex.getLineNumber());    
        }   
    }
    /**
* @description  : createUserTerrList -> ES20-12083 
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
    
    /**
* @description  : assignUserToGroup
* @purpose : Assigned user to particular geography group to give access in records
* @parameters: Map<Id, SObject> newItems, Map<Id, SObject> oldItems
*/
    public static void assignUserToGroup(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id,User> mapOldUser;
        Map<Id,User> mapNewUser = (Map<Id,User>) newItems;
        Map<String, String> mapGroupName = new Map<String, String>();
        Map<String,List<String>> mapUserWithCountry = new Map<String,List<String>>();
        Map<String,List<String>> mapDeleteUserWithCountry = new Map<String,List<String>>();
        Map<String, List<String>> mapOldUserCountry = new Map<String, List<String>>();
        List<GroupMember> lstGroupMember = new List<GroupMember>(); 
        List<GroupMember> lstDeleteGroupMember = new List<GroupMember>(); 
        List<Id> lstGroupId = new List<Id>();
        List<String> lstGroupName = new List<String>();
        Map<Id,String> mapUserWithType = new Map<Id,String>();
        Map<Id,String> mapUserWithD1UserType = new Map<Id,String>();
        List<String> d1InternalSharingProfileNames = Label.D1_Internal_Group_Sharing_Profiles.split(';');//NCP-6401
        for(Profile p:[select id from profile where name IN : d1InternalSharingProfileNames] ) {
            D1_PROFILE_IDS.add(p.id);
        }
        try{
            //Create a Map User id as key and Country code as value which can be user later to compare whether new code is added or deleted
            if(oldItems != null && oldItems.size()>0){
                mapOldUser = (Map<Id,User>) oldItems;
                for(User oldUser : mapOldUser.values()){
                    List<String> userTypeVal = Label.Required_User_Type.split(';');
                    for(String typeObj : userTypeVal){
                        if(oldUser.UserType == typeObj){
                            List<String> lstOldUserCountry = createListCountryCode(oldUser);
                            if(lstOldUserCountry != null && lstOldUserCountry.size()>0){
                                for(String countryCode : lstOldUserCountry){
                                    if(mapOldUserCountry.containsKey(oldUser.Id)){
                                        mapOldUserCountry.get(oldUser.Id).add(countryCode);                    
                                    } else{
                                        mapOldUserCountry.put(oldUser.Id, new List<String>{countryCode});
                                    }
                                }
                            }                        
                        }    
                    }
                }
            }
            
            if(mapNewUser != null && mapNewUser.size()>0){
                Map<Id,User> mapStandardUser = new Map<Id,User>();
                for(User newUser : mapNewUser.values()){
                    // Added NCP-3454
                    if(newUser.D1_User_Type__c != null){
                        mapUserWithD1UserType.put(newUser.Id,newUser.D1_User_Type__c);                          
                    } 
                    List<String> userTypeVal = Label.Required_User_Type.split(';');
                    for(String typeObj : userTypeVal){
                        if(newUser.UserType == typeObj ){
                            mapStandardUser.put(newUser.Id,newUser);
                            List<String> lstNewUserCountry = createListCountryCode(newUser);
                            //Create a MAP which contains only those country code record that is newly added
                            if(lstNewUserCountry != null && lstNewUserCountry.size()>0){
                                for(String countryCode : lstNewUserCountry){
                                    lstGroupName.add(countryCode);
                                    if(mapOldUser == null || (mapOldUser != null && mapOldUserCountry != null && mapOldUserCountry.containsKey(newUser.Id) && !(mapOldUserCountry.get(newUser.Id)).contains(countryCode))
                                       || (newUser.ProfileId != mapOldUser.get(newUser.Id).ProfileId)){
                                           mapUserWithType.put(newUser.Id,newUser.UserType);
                                           if(mapUserWithCountry.containsKey(countryCode)){
                                               mapUserWithCountry.get(countryCode).add(newUser.Id);
                                           } else {
                                               mapUserWithCountry.put(countryCode, new List<Id>{newUser.Id});
                                           }                            
                                       }
                                }
                            }
                            
                            //Create a MAP which contains only those country code record that is needs to be removed
                            if(mapOldUserCountry != null && mapOldUserCountry.containsKey(newUser.Id)){
                                List<String> lstOldUserCountry = mapOldUserCountry.get(newUser.Id);
                                for(String countryCode : lstOldUserCountry){
                                    lstGroupName.add(countryCode);
                                    if(!lstNewUserCountry.contains(countryCode)){
                                        if(mapDeleteUserWithCountry.containsKey(countryCode)){
                                            mapDeleteUserWithCountry.get(countryCode).add(newUser.Id);
                                        } else {
                                            mapDeleteUserWithCountry.put(countryCode, new List<Id>{newUser.Id});
                                        }                            
                                    }
                                }
                                mapOldUserCountry.clear();
                            }
                        }
                    }
                }
                mapNewUser.clear();
                mapNewUser = mapStandardUser;
            }
            
            if((mapUserWithCountry != null && mapUserWithCountry.size()>0) || (mapDeleteUserWithCountry != null && mapDeleteUserWithCountry.size()>0)){
                Id globalRecordTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName().get('Global').getRecordTypeId();
                String groupDown = EDGE_Constant.EDGE_GROUP_DOWN;
                String groupUp = EDGE_Constant.EDGE_GROUP_UP; 
                if(Schema.sObjectType.Geography__c.isAccessible()){
                    //Query geography record to fetch the name of group from Sharing_Group_Name__c
                    List<Geography__c> lstGeographyDetails = [SELECT Id, D1_External_Group_Name__c,D1_Internal_Group_Name__c, Sharing_Group_Name__c, Code__c, Parent_Geography__c, Parent_Geography__r.Code__c, 
                                                              Parent_Geography__r.Parent_Geography__c, Parent_Geography__r.Parent_Geography__r.Code__c,
                                                              Parent_Geography__r.Parent_Geography__r.Parent_Geography__c, Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c 
                                                              FROM Geography__c 
                                                              WHERE RecordTypeId != :globalRecordTypeId 
                                                              AND Code__c IN :lstGroupName
                                                             ];                    
                    //Create map of group name and code
                    if(lstGeographyDetails != null && lstGeographyDetails.size()>0){
                        validateGeographySelection(lstGeographyDetails, mapNewUser);
                        for(Geography__c geographyDetails : lstGeographyDetails){
                            mapGroupName.put(geographyDetails.Sharing_Group_Name__c+groupDown, geographyDetails.Code__c);
                            mapGroupName.put(geographyDetails.Sharing_Group_Name__c+groupUp, geographyDetails.Code__c);
                            mapGroupName.put(geographyDetails.D1_External_Group_Name__c, geographyDetails.Code__c);
                            mapGroupName.put(geographyDetails.D1_Internal_Group_Name__c,geographyDetails.Code__c);//NCP-6401
                            mapGroupName.put(geographyDetails.Code__c+'_Direct', geographyDetails.Code__c); // Added NCP-3454
                            mapGroupName.put(geographyDetails.Code__c+'_Indirect', geographyDetails.Code__c);// Added NCP-3454                            
                        }
                    }                    
                }
                System.debug(LoggingLevel.DEBUG,'sharing test'+mapNewUser);
                if(mapGroupName != null && mapGroupName.size()>0){
                    for(Group groupDetails : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :mapGroupName.keySet()]){
                        //Create List of Group Member that needs to be inserted
                        if(mapGroupName.containsKey(groupDetails.DeveloperName) && mapUserWithCountry.containsKey(mapGroupName.get(groupDetails.DeveloperName))){
                            List<String> lstUser = mapUserWithCountry.get(mapGroupName.get(groupDetails.DeveloperName));
                            for(String userId : lstUser){
                                if(mapUserWithType!= null && mapUserWithType.containsKey(userId)){
                                    if((mapUserWithType.get(userId)=='Standard' && !groupDetails.DeveloperName.startsWith('D1'))
                                       || ( (mapUserWithType.get(userId)=='Standard' && groupDetails.DeveloperName.contains(Label.D1_Internal_Group_Prefix)) && (D1_PROFILE_IDS.size()>0 && D1_PROFILE_IDS.contains(mapNewUser.get(userId).ProfileId)) ) //NCP-6401
                                       ||(mapUserWithType.get(userId)=='PowerCustomerSuccess' && groupDetails.DeveloperName.startsWith('D1'))
                                       ||((mapUserWithD1UserType!= null && mapUserWithD1UserType.containsKey(userId)) 
                                          && ((mapUserWithD1UserType.get(userId) == 'Direct Buyer' && groupDetails.DeveloperName.contains('Direct')) 
                                              ||(mapUserWithD1UserType.get(userId) == 'Outlet/Retailers' && groupDetails.DeveloperName.contains('Indirect'))))){// Added NCP-3454
                                                  GroupMember objGroupMember = new GroupMember();
                                                  objGroupMember.GroupId = groupDetails.Id;
                                                  objGroupMember.UserOrGroupId = userId;
                                                  lstGroupMember.add(objGroupMember);
                                              }
                                }
                            }
                        } else if(mapGroupName.containsKey(groupDetails.DeveloperName) && mapDeleteUserWithCountry.containsKey(mapGroupName.get(groupDetails.DeveloperName))){
                            //Create List of Group Member that needs to be deleted
                            List<String> lstUser = mapDeleteUserWithCountry.get(mapGroupName.get(groupDetails.DeveloperName));
                            lstGroupId.add(groupDetails.Id);
                            for(String userId : lstUser){
                                if(mapOldUserCountry.containsKey(userId)){
                                    mapOldUserCountry.get(userId).add(groupDetails.Id);
                                } else {
                                    mapOldUserCountry.put(userId, new List<Id>{groupDetails.Id});
                                }                               
                            }
                        }                       
                    }
                    
                    if(lstGroupId != null && lstGroupId.size()>0 && mapOldUserCountry != null && mapOldUserCountry.size()>0){
                        //Fetch Group Member details that needs to be deleted
                        for(GroupMember groupMemberDetails : [SELECT ID, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :lstGroupId AND UserOrGroupId IN :mapOldUserCountry.keySet()]){
                            if(mapOldUserCountry.containsKey(groupMemberDetails.UserOrGroupId) && (mapOldUserCountry.get(groupMemberDetails.UserOrGroupId)).contains(groupMemberDetails.GroupId)){
                                lstDeleteGroupMember.add(groupMemberDetails);                            
                            }
                        }
                        
                        if(lstDeleteGroupMember != null && lstDeleteGroupMember.size()>0){
                            Database.delete(lstDeleteGroupMember);
                        }
                    }
                    
                    if(lstGroupMember != null && lstGroupMember.size()>0){
                        Database.upsert(lstGroupMember);
                    } 
                }
            }            
        } catch(Exception excption){
            List<SObject> errorItem = newItems.values();
            System.debug(LoggingLevel.DEBUG,'Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);            
        }      
    }
    
    /**
* @description  : createListCountryCode
* @purpose : To create a list of country code
* @parameters: User newUser
*/ 
    public static List<String> createListCountryCode(User newUser){        
        List<String> lstNewUserCountry = new List<String>();
        try{
            if(newUser != null){
                if(String.isNotBlank(newUser.Assigned_Clusters__c)){
                    lstNewUserCountry.addAll((newUser.Assigned_Clusters__c).split(';'));                    
                }
                if(String.isNotBlank(newUser.Available_Countries__c)){
                    lstNewUserCountry.addAll((newUser.Available_Countries__c).split(';'));
                }
                if(String.isNotBlank(newUser.Assigned_Hubs__c)){
                    lstNewUserCountry.addAll((newUser.Assigned_Hubs__c).split(';'));
                }
                if(String.isNotBlank(newUser.Assigned_Markets__c)){
                    lstNewUserCountry.addAll((newUser.Assigned_Markets__c).split(';'));
                }            
            }            
        } catch(Exception excption){
            System.debug(LoggingLevel.DEBUG,'Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, newUser);            
        }        
        return lstNewUserCountry;        
    }
    
    /**
* @description  : validateGeographySelection
* @purpose : Validation that does not allow to assign the user to geographies of different levels and same hierarchy. 
* @parameters: List<Geography__c> lstGeographyDetails, Map<Id,User> mapNewUser
*/ 
    public static void validateGeographySelection(List<Geography__c> lstGeographyDetails, Map<Id,User> mapNewUser){
        try{            
            if(mapNewUser != null && mapNewUser.size()>0 && Schema.sObjectType.Profile.isAccessible()){                
                //get UserProfileMap
                userProfileMap = getUserProfileMap(mapNewUser.keySet());
                String readOnlyProfiles = System.label.Standard_Territory_Read_Only_Profiles;
                List<String> listOfReadOnlyProfiles = readOnlyProfiles.split(';'); 
                //CST changes
                String cstOnlyProfiles = System.label.CST_Read_Profiles;
                List<String> listOfCSTOnlyProfiles = cstOnlyProfiles.split(';');               
                for(Id userId : mapNewUser.keySet()){
                    //If profile is Sales Rep than filled data only in Available country multi select picklist
                    if((listOfReadOnlyProfiles.contains(userProfileMap.get(userId))) ||(listOfCSTOnlyProfiles.contains(userProfileMap.get(userId)))){ // mapNewUser.get(userId)).ProfileId == salesRep.Id
                        if(String.isNotBlank(mapNewUser.get(userId).Assigned_Clusters__c) || String.isNotBlank(mapNewUser.get(userId).Assigned_Hubs__c) || String.isNotBlank(mapNewUser.get(userId).Assigned_Markets__c)){
                            mapNewUser.get(userId).addError(Label.SalesRepUserMessage);
                        }
                    } else {
                        //Validation that does not allow to assign the user to geographies of different levels and same hierarchy.
                        List<String> lstNewUserCountry = createListCountryCode(mapNewUser.get(userId));
                        for(Geography__c geography : lstGeographyDetails){
                            if(lstNewUserCountry.contains(geography.Code__c) && 
                               ((geography.Parent_Geography__c != null && 
                                 geography.Parent_Geography__r.Code__c != null && geography.Parent_Geography__r.Code__c !='GL' &&
                                 lstNewUserCountry.contains(geography.Parent_Geography__r.Code__c)) ||
                                (geography.Parent_Geography__r.Parent_Geography__c != null && 
                                 geography.Parent_Geography__r.Parent_Geography__r.Code__c != null && 
                                 geography.Parent_Geography__r.Parent_Geography__r.Code__c != 'GL' && 
                                 lstNewUserCountry.contains(geography.Parent_Geography__r.Parent_Geography__r.Code__c)) || 
                                (geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c != null && 
                                 geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c != null && 
                                 geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c != 'GL' && 
                                 lstNewUserCountry.contains(geography.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c))
                               )
                              ){
                                  mapNewUser.get(userId).addError(label.User_Geography_Hierarchy);
                              }
                        }                        
                    }                    
                }
            }            
        } catch(Exception excption){
            List<SObject> errorItem = mapNewUser.values();
            System.debug(LoggingLevel.DEBUG,'Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);            
        }          
    }
    
    /** 
* @description: addTraxUser
* @purpose: The below method creates Territory assignment with the users
* @parameters: Map<Id,SObject> newUserMap,Map<Id,SObject> oldUserMap
*/
    public static void addTraxUser(Map<Id,SObject> newUserMap,Map<Id,SObject> oldUserMap){
        //List<Trax_User_Update__c> traxUserUpdate=new List<Trax_User_Update__c>();
        Map<Id,user> newUser=(Map<Id,user>)newUserMap;
        Map<Id,user> oldUser;
        Set<Id> userIdSet = new Set<Id>();
        if(oldUserMap!=null){
            oldUser=( Map<Id,user>)oldUserMap;
        }
        
        for(Id uobj: newUser.keyset()){
            
            if((oldUser==null && newUser.get(uobj).Trax_User__c) ||
               (oldUser.get(uobj).Trax_User__c != newUser.get(uobj).Trax_User__c) ||
               ((!newUser.get(uobj).isActive) && oldUser.get(uobj).isActive != newUser.get(uobj).isActive &&
                (newUser.get(uobj).Trax_User__c || oldUser.get(uobj).Trax_User__c)) &&
               Schema.SObjectType.Trax_User_Update__c.isCreateable()){
                   userIdSet.add(uobj);                             
               }
        }        
        
        if(!System.isBatch() && !userIdSet.isEmpty()){//change for ES20-9820
            addTraxUserUpdate(userIdSet);   
        }  
    }
    
    /**
* @description  : addTraxUserUpdate //change for ES20-9820
* @purpose : Adding user to Trax User Update Custom Settings
* @parameters : Set<Id> userIdSet
*/  
    @future
    public static void addTraxUserUpdate(Set<Id> userIdSet){
        List<Trax_User_Update__c> traxUserUpdate=new List<Trax_User_Update__c>();
        Map<Id,User> userMap = new Map<Id,User>([Select id,Default_Country__c,Available_Countries__c from User where id in : userIdSet] ) ;  
        String availableCountry ='';
        for(Id userId : userIdSet){
            //User usrObj = new User(Id = userId);
            if(userMap.get(userId) != null){
                if(userMap.get(userId).Default_Country__c!=null){
                    availableCountry = EDGE_BatchUtilityClass.getUserCountryCode(userMap.get(userId).Default_Country__c,userMap.get(userId).Available_Countries__c);    
                }
                else{
                    availableCountry = EDGE_BatchUtilityClass.getUserCountryCode(null,userMap.get(userId).Available_Countries__c);  
                }
                traxUserUpdate.add(new Trax_User_Update__c(name=userId,Country_Code__c=availableCountry));
            }
            
        }
        
        try{
            if(Schema.sObjectType.Trax_User_Update__c.isCreateable()){
                insert traxUserUpdate;
            }           
        }
        catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'Exception Found'+e); 
        }  
    }
    
    /**
* @description  : updateCallPerDayInTerHierarchy //change for ES20-9820
* @purpose : Update Call Per Day In Territory Hierarchy 
* @parameters : Map<Id, SObject> newItems, Map<Id, SObject> oldItems
*/
    public static void updateCallPerDayInTerHierarchy(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        //Variables
        Map<Id, User> oldUserMap = (Map<Id, User>) oldItems;
        Map<Id, User> newUserMap = (Map<Id, User>) newItems;
        Map<Id,List<User>> newUserManagermap = new Map<Id,List<User>>();
        Map<Id,List<User>> oldUserManagermap = new Map<Id,List<User>>(); 
        Map<Id,List<User>> existingUserManagermap = new Map<Id,List<User>>();
        Map<Id,List<User>> existingUserManagermapOldMngr = new Map<Id,List<User>>();
        Map<Id,Id> userTerritoryHierarchyMap = new Map<Id,Id>();
        List<Territory_Hierarchy__c> terHierarchyToUpdate = new List<Territory_Hierarchy__c>();
        
        for(User usrObj :newUserMap.values()){
            if(usrObj.UserType != 'PowerCustomerSuccess'){
                //If user's manager gets changed to a new Manager or manager gets updated from null        
                if(oldUserMap.get(usrObj.Id).ManagerId==null || (oldUserMap.get(usrObj.Id).ManagerId!= usrObj.ManagerId) ||oldUserMap.get(usrObj.Id).Calls_Per_Day__c!= usrObj.Calls_Per_Day__c){ 
                    //Prepare the map of manager and user list for bulk records which are being updated in trigger
                    if(newUserManagermap.containsKey(usrObj.ManagerId)){
                        List<User> userList = newUserManagermap.get(usrObj.ManagerId);
                        userList.add(usrObj);
                        newUserManagermap.put(usrObj.ManagerId,userList);
                    }else{
                        newUserManagermap.put(usrObj.ManagerId,new List<User>{usrObj});
                    }
                    
                }
                //If Calls Per Day gets updated on user
                if(usrObj.ManagerId==null ||(oldUserMap.get(usrObj.Id).ManagerId!= usrObj.ManagerId)){
                    //Prepare the map of old manager and list for bulk records which are being updated in trigger
                    if(oldUserManagermap.containsKey(oldUserMap.get(usrObj.Id).ManagerId)){
                        List<User> userList = oldUserManagermap.get(oldUserMap.get(usrObj.Id).ManagerId);
                        userList.add(usrObj);
                        oldUserManagermap.put(oldUserMap.get(usrObj.Id).ManagerId,userList);
                    }else{
                        oldUserManagermap.put(oldUserMap.get(usrObj.Id).ManagerId,new List<User>{usrObj});
                    }
                    
                }
            }
        }
        
        //When Manager  or Call Per day gets changed,query all existing users for the new manager
        if(newUserManagermap!=null && newUserManagermap.size()>0 ){
            for(User userObj : [Select Id,ManagerId,Calls_Per_Day__c from User where ManagerId in :newUserManagermap.KeySet() AND UserType != 'PowerCustomerSuccess']){
                if(existingUserManagermap.containsKey(userObj.ManagerId)){
                    List<User> userList = existingUserManagermap.get(userObj.ManagerId);
                    userList.add(userObj);
                    existingUserManagermap.put(userObj.ManagerId,userList);
                }else{
                    existingUserManagermap.put(userObj.ManagerId,new List<User>{userObj});
                }
                
            }   
        }
        //When Manager gets changed,query all existing users for the old manager
        if(oldUserManagermap!=null && oldUserManagermap.size()>0 ){
            for(User userObj : [Select Id,ManagerId,Calls_Per_Day__c from User where ManagerId in :oldUserManagermap.KeySet() AND UserType != 'PowerCustomerSuccess']){
                if(existingUserManagermapOldMngr.containsKey(userObj.ManagerId)){
                    List<User> userList = existingUserManagermapOldMngr.get(userObj.ManagerId);
                    userList.add(userObj);
                    existingUserManagermapOldMngr.put(userObj.ManagerId,userList);
                }else{
                    existingUserManagermapOldMngr.put(userObj.ManagerId,new List<User>{userObj});
                }
                
            }   
        }
        //Fetch existing Territory Hierarchy Records for which manager gets changed or Calls Per Day gets changed
        for(Territory_Hierarchy_Member__c terHierarchyMemObj : [Select Id,User__c,Territory_Hierarchy__c 
                                                                from Territory_Hierarchy_Member__c where (User__c IN :newUserManagermap.KeySet() OR User__c IN :oldUserManagermap.KeySet())
                                                                and Status__c ='Active' ]){                  
                                                                    userTerritoryHierarchyMap.put(terHierarchyMemObj.Territory_Hierarchy__c,terHierarchyMemObj.User__c);                                                 
                                                                } 
        
        //Iterate over Territory Hierarchy records where manager is present as member
        if(userTerritoryHierarchyMap!=null && userTerritoryHierarchyMap.size()>0){
            for(Id terHierarcyId : userTerritoryHierarchyMap.keySet()){
                Territory_Hierarchy__c terHierarchyObj = new Territory_Hierarchy__c(Id= terHierarcyId);
                List<User> assignedRepList = new List<User>(); 
                //Adding existing records to the list for new Manager
                if(existingUserManagermap!=null && existingUserManagermap.containsKey(userTerritoryHierarchyMap.get(terHierarcyId))){
                    assignedRepList.addAll(existingUserManagermap.get(userTerritoryHierarchyMap.get(terHierarcyId)));
                }
                //Adding existing records to the list for old Manager
                if(existingUserManagermapOldMngr!=null && existingUserManagermapOldMngr.containsKey(userTerritoryHierarchyMap.get(terHierarcyId))){
                    assignedRepList.addAll(existingUserManagermapOldMngr.get(userTerritoryHierarchyMap.get(terHierarcyId)));
                }
                
                Decimal sum = 0.0;
                for(User usr : assignedRepList) {
                    if(usr.Calls_Per_Day__c!=null){
                        sum = sum +usr.Calls_Per_Day__c;                          
                    }
                }
                
                if(assignedRepList.size()>0){
                    terHierarchyObj.Calls_per_day__c = sum/assignedRepList.size();   
                }
                terHierarchyToUpdate.add(terHierarchyObj);
            }
            
        }
        // Added isUpdateable check by Vikas
        if(terHierarchyToUpdate!=null && terHierarchyToUpdate.size()>0 && Schema.sObjectType.Territory_Hierarchy__c.isUpdateable()){
            update terHierarchyToUpdate;
        }
        //ID territoryHierJobID = System.enqueueJob(new EDGE_TerrHierarchyAsyncUpdate(terHierarchyToUpdate));
    }
    
    /** 
* @description: distSalesRepMangerCreation //change for ES20-10013
* @purpose: The below method creates Territory assignment with the users
* @parameters: List<SObject> newItems,Map<Id, SObject> oldItems
*/
    public static void distSalesRepMangerCreation(List<SObject> newItems,Map<Id, SObject> oldItems){
        List<User> newUserList = (List<User>)newItems;
        Id createdByUserProfileId;
        List<Id> newUserProfileIdList = new List<Id>();
        Map<Id, Set<User>> ddmUserIdToSRSMIdsMap = new Map<Id, Set<User>>();
        Map<Id,String> profileIdNameMap = new Map<Id,String>();
        
        for(Profile prof :[SELECT Id , Name FROM Profile WHERE Name = :DIST_SALES_REP_PROFILE_STR OR Name = :DIST_SALES_MANAGER_PROFILE_STR OR Name = :DIST_DATA_MANAGER_PROFILE_STR]){
            if(prof.Name == DIST_DATA_MANAGER_PROFILE_STR){
                createdByUserProfileId = prof.Id ;
            }else if (prof.Name == DIST_SALES_MANAGER_PROFILE_STR || prof.Name == DIST_SALES_REP_PROFILE_STR){
                newUserProfileIdList.add(prof.Id);      
            }
            profileIdNameMap.put(prof.Id,prof.Name);
        }         
        
        if(newUserList != null){
            for(User user :newUserList){
                Boolean profileMatch = newUserProfileIdList.contains(user.ProfileId);
                
                if(UserInfo.getProfileId() == createdByUserProfileId && profileMatch == true){
                    if(ddmUserIdToSRSMIdsMap.get(user.CreatedById) != null){
                        ddmUserIdToSRSMIdsMap.get(user.CreatedById).add(user);
                    }
                    else{
                        Set<User> distUserSet = new Set<User>();
                        distUserSet.add(user);
                        ddmUserIdToSRSMIdsMap.put(user.CreatedById,distUserSet);
                    }                      
                }       
            }
            if(ddmUserIdToSRSMIdsMap != null && ddmUserIdToSRSMIdsMap.size() > 0){
                EDGE_AccountTriggerPersonRespHelper.initiateShareWithSRSM(ddmUserIdToSRSMIdsMap,profileIdNameMap);    
            }
        }
    }
    
    /** 
* @description: fetchInactiveDistSRSMFromAccount -> ES20-10310
* @purpose: calls deleteInactiveDistSRSMFromAccountTeamAndGroup to delete inactive Distributor Sales User from AccountTeamMember and Groups
* @parameters: List<SObject> newItems,Map<Id, SObject> oldItems
*/
    public static void fetchInactiveDistSRSMFromAccount(List<SObject> newItems,Map<Id, SObject> oldItems)
    {
        List<User> newUserList = (List<User>)newItems;
        Set<Id> inactiveUserIdSet = new Set<Id>();
        
        if(newUserList != null && newUserList.size()>0)
        {
            List<User> inactiveUserList = [SELECT Id FROM User WHERE Id IN : newUserList 
                                           AND (Profile.Name =: DIST_SALES_MANAGER_PROFILE_STR 
                                                OR Profile.Name =: DIST_SALES_REP_PROFILE_STR) 
                                           AND isActive = false]; 
            inactiveUserIdSet = (new Map<Id,User>(inactiveUserList)).keySet();
            if(inactiveUserIdSet != null && inactiveUserIdSet.size()>0)
                EDGE_AccountTriggerPersonRespHelper.deleteInactiveDistSRSMFromAccountTeamAndGroup(inactiveUserIdSet);
        }
    }     
    
    /*




* @Method  : addUserToPublicGroup
* @Purpose :  add/ remove the user from the public group of the sales
organisation in base of the public group naming conventions 
*/ 
    public static void addUserToPublicGroup(Map<Id,sObject> newItems,Map<Id, SObject> oldItems)
    {
        Map<Id,User> mapOldUser;
        Map<Id,User> mapNewUser = (Map<Id,User>) newItems;
        Map<String, String> mapGroupName = new Map<String, String>();
        Map<String,List<String>> mapUserWithSOrg = new Map<String,List<String>>();
        Map<String,List<String>> mapDeleteUserWithSOrg = new Map<String,List<String>>();
        Map<String, List<String>> mapOldUserSalesOrg = new Map<String, List<String>>();
        Map<Id,User> mapStandardUser = new Map<Id,User>();
        List<GroupMember> lstGroupMember = new List<GroupMember>(); 
        List<GroupMember> lstDeleteGroupMember = new List<GroupMember>(); 
        List<Id> lstGroupId = new List<Id>();
        List<String> lstGroupName = new List<String>();
        Map<Id,String> mapUserWithType = new Map<Id,String>();
        try{
            //Create a Map User id as key and Country code as value which can be user later to compare whether new code is added or deleted
            if(oldItems != null && oldItems.size()>0){
                mapOldUser = (Map<Id,User>) oldItems;
                List<String> userSOrg = new List<String>();
                for(User oldUser : mapOldUser.values()){
                    List<String> userTypeVal = Label.Required_User_Type.split(';');
                    for(String typeObj : userTypeVal){
                        if(oldUser.UserType == typeObj){
                            if(String.isNotBlank(oldUser.Sales_Organisation__c)){
                                userSOrg=oldUser.Sales_Organisation__c.split(';');
                            }
                            if(userSOrg != null && userSOrg.size()>0){
                                for(String salesOrg : userSOrg){
                                    if(mapOldUserSalesOrg.containsKey(oldUser.Id)){
                                        mapOldUserSalesOrg.get(oldUser.Id).add(salesOrg);                    
                                    } else{
                                        mapOldUserSalesOrg.put(oldUser.Id, new List<String>{salesOrg});
                                    }
                                }
                            }                        
                        }    
                    }
                }
                System.debug(LoggingLevel.DEBUG,'mapOldUserSalesOrg:::'+mapOldUserSalesOrg);
            }
            
            
            System.debug(LoggingLevel.DEBUG,'mapNewUser'+mapNewUser);
            if(mapNewUser != null && mapNewUser.size()>0){                
                List<String>newUserSOrg = new List<String>();
                for(User newUser : mapNewUser.values()){                     
                    List<String> userTypeVal = Label.Required_User_Type.split(';');
                    if(String.isNotBlank(newUser.Sales_Organisation__c)){
                        newUserSOrg=newUser.Sales_Organisation__c.split(';');
                    }
                    for(String typeObj : userTypeVal){
                        if(newUser.UserType == typeObj ){
                            mapStandardUser.put(newUser.Id,newUser);
                            
                            System.debug(LoggingLevel.DEBUG,'newUserSOrg'+newUserSOrg);
                            //List<String> lstNewUserCountry = createListCountryCode(newUser);
                            //Create a MAP which contains only those country code record that is newly added
                            if(newUserSOrg != null && newUserSOrg.size()>0){
                                for(String sOrgCode : newUserSOrg){
                                    lstGroupName.add(sOrgCode);
                                    if(mapOldUser == null || (mapOldUser != null && mapOldUserSalesOrg != null && mapOldUserSalesOrg.containsKey(newUser.Id) && !(mapOldUserSalesOrg.get(newUser.Id)).contains(sOrgCode))
                                       || (newUser.ProfileId != mapOldUser.get(newUser.Id).ProfileId) || (newUser.Sales_Organisation__c != mapOldUser.get(newUser.Id).Sales_Organisation__c)){
                                           mapUserWithType.put(newUser.Id,newUser.UserType);
                                           if(mapUserWithSOrg.containsKey(sOrgCode)){
                                               mapUserWithSOrg.get(sOrgCode).add(newUser.Id);
                                               System.debug(LoggingLevel.DEBUG,'mapUserWithSOrg from if:::'+mapUserWithSOrg);
                                           } else {
                                               mapUserWithSOrg.put(sOrgCode, new List<Id>{newUser.Id});
                                               System.debug(LoggingLevel.DEBUG,'mapUserWithSOrg from else:::'+mapUserWithSOrg);
                                           }                            
                                       }
                                }
                                System.debug(LoggingLevel.DEBUG,'mapUserWithSOrg:::'+mapUserWithSOrg);                    
                            }
                            
                            //Create a MAP which contains only those country code record that is needs to be removed
                            if(mapOldUserSalesOrg != null && mapOldUserSalesOrg.containsKey(newUser.Id)){
                                List<String> lstOldUserSOrg = mapOldUserSalesOrg.get(newUser.Id);
                                for(String SOrg : lstOldUserSOrg){
                                    lstGroupName.add(SOrg);
                                    if(!newUserSOrg.contains(SOrg)){
                                        if(mapDeleteUserWithSOrg.containsKey(SOrg)){
                                            mapDeleteUserWithSOrg.get(SOrg).add(newUser.Id);
                                        } else {
                                            mapDeleteUserWithSOrg.put(SOrg, new List<Id>{newUser.Id});
                                        }                            
                                    }
                                }
                                mapOldUserSalesOrg.clear();
                                System.debug(LoggingLevel.DEBUG,'mapDeleteUserWithSOrg:::'+mapDeleteUserWithSOrg);
                            }
                        }
                    }
                }
                //mapNewUser.clear();
                //mapNewUser = mapStandardUser;
                //System.debug('mapNewUser::'+mapNewUser);
            }
            if((mapUserWithSOrg != null && mapUserWithSOrg.size()>0) || (mapDeleteUserWithSOrg != null && mapDeleteUserWithSOrg.size()>0)){
                List<Sales_Organisation__c> sOrgListDetails = [SELECT Id, Name, Code__c, Country__c FROM Sales_Organisation__c WHERE Code__c IN :lstGroupName];
                System.debug(LoggingLevel.DEBUG,'sOrgListDetails:::'+sOrgListDetails);
                
                //Create map of group name and code
                if(sOrgListDetails != null && sOrgListDetails.size()>0){
                    //validateGeographySelection(lstGeographyDetails, mapNewUser);
                    for(Sales_Organisation__c salesOrgDetails : sOrgListDetails){
                        mapGroupName.put('SO_'+salesOrgDetails.Code__c+'_Read', salesOrgDetails.Code__c);
                        mapGroupName.put('SO_'+salesOrgDetails.Code__c+'_Write', salesOrgDetails.Code__c);
                    }
                }                    
            }
            System.debug(LoggingLevel.DEBUG,'mapGroupName:::'+mapGroupName); 
            System.debug(LoggingLevel.DEBUG,'mapUserWithSOrg:::'+mapUserWithSOrg); 
            System.debug(LoggingLevel.DEBUG,'mapUserWithType:::'+mapUserWithType);
            if(mapGroupName != null && mapGroupName.size()>0){
                for(Group groupDetails : [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN :mapGroupName.keySet()]){
                    //Create List of Group Member that needs to be inserted
                    if(mapGroupName.containsKey(groupDetails.DeveloperName) && mapUserWithSOrg.containsKey(mapGroupName.get(groupDetails.DeveloperName))){
                        List<String> lstUser = mapUserWithSOrg.get(mapGroupName.get(groupDetails.DeveloperName));
                        for(String userId : lstUser){
                            if(mapUserWithType!= null && mapUserWithType.containsKey(userId)){
                                if((mapUserWithType.get(userId)=='Standard') ||(mapUserWithType.get(userId)=='PowerCustomerSuccess')){
                                    GroupMember objGroupMember = new GroupMember();
                                    objGroupMember.GroupId = groupDetails.Id;
                                    objGroupMember.UserOrGroupId = userId;
                                    lstGroupMember.add(objGroupMember);
                                }
                            }
                        }
                    } else if(mapGroupName.containsKey(groupDetails.DeveloperName) && mapDeleteUserWithSOrg.containsKey(mapGroupName.get(groupDetails.DeveloperName))){
                        //Create List of Group Member that needs to be deleted
                        List<String> lstUser = mapDeleteUserWithSOrg.get(mapGroupName.get(groupDetails.DeveloperName));
                        lstGroupId.add(groupDetails.Id);
                        for(String userId : lstUser){
                            if(mapOldUserSalesOrg.containsKey(userId)){
                                mapOldUserSalesOrg.get(userId).add(groupDetails.Id);
                            } else {
                                mapOldUserSalesOrg.put(userId, new List<Id>{groupDetails.Id});
                            }                               
                        }
                    }                       
                }
                
                System.debug(LoggingLevel.DEBUG,'lstGroupMember:::'+lstGroupMember); 
                System.debug(LoggingLevel.DEBUG,'mapOldUserSalesOrg:::'+mapOldUserSalesOrg); 
                System.debug(LoggingLevel.DEBUG,'mapGroupName:::'+mapGroupName); 
                
                if(lstGroupId != null && lstGroupId.size()>0 && mapOldUserSalesOrg != null && mapOldUserSalesOrg.size()>0){
                    //Fetch Group Member details that needs to be deleted
                    for(GroupMember groupMemberDetails : [SELECT ID, GroupId, UserOrGroupId FROM GroupMember WHERE GroupId in :lstGroupId AND UserOrGroupId IN :mapOldUserSalesOrg.keySet()]){
                        if(mapOldUserSalesOrg.containsKey(groupMemberDetails.UserOrGroupId) && (mapOldUserSalesOrg.get(groupMemberDetails.UserOrGroupId)).contains(groupMemberDetails.GroupId)){
                            lstDeleteGroupMember.add(groupMemberDetails);                            
                        }
                    }
                    
                    System.debug(LoggingLevel.DEBUG,'lstDeleteGroupMember:::'+lstDeleteGroupMember); 
                    
                    if(lstDeleteGroupMember != null && lstDeleteGroupMember.size()>0){
                        Database.delete(lstDeleteGroupMember);
                    }
                }
                
                if(lstGroupMember != null && lstGroupMember.size()>0){
                    Database.upsert(lstGroupMember);
                } 
            }
        }            
        catch(Exception excption){
            List<SObject> errorItem = newItems.values();
            System.debug(LoggingLevel.DEBUG,'Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);            
        } 
    }  
    
    
    /*




* @description  : checkAndGenerateSharing -> ES20-11673
* @purpose : Create sharing records for users on insert
* @parameter : List<SObject> newItems
*/
    public static void checkAndGenerateSharing(List<SObject> newItems){
        
        //Assignment
        Map<Id,Set<String>> userIdGeoCodeMap = new Map<Id,Set<String>>();
        Map<Id,Set<Geography__c>> finalUserGeoMap = new Map<Id,Set<Geography__c>>();  
        Map<String,Boolean> profileSharingCheckMap = new Map<String,Boolean>();
        Map<Id,String> profileNameMap = new Map<Id,String>();
        Set<Id> profileIdset = new Set<Id>();
        List<User> newUserList = (List<User>)newItems;
        
        //Creating a set of profiles of the users
        if(newUserList!=null && newUserList.size()>0){
            for(User usr : newUserList){
                profileIdset.add(usr.ProfileId);
            }
        }
        
        //Creating a mapping of profile id and profile name
        if(profileIdset!=null && profileIdset.size()>0){
            for(Profile Profile : [SELECT Id,Name FROM Profile WHERE Id =:profileIdset]){
                profileNameMap.put(profile.id,profile.Name);
            }
        }
        
        //Creating a mapping of profile name and active flag in access sharing metadata    
        for(Profile_Access_Sharing_Check__mdt accessSharingCheck: [SELECT Id, Profile_Name__c, User_Access_Sharing__c
                                                                   FROM Profile_Access_Sharing_Check__mdt
                                                                   WHERE User_Access_Sharing__c = TRUE])
        {
            profileSharingCheckMap.put(accessSharingCheck.Profile_Name__c,accessSharingCheck.User_Access_Sharing__c);
        }
        
        //Fetching geo-codes for users
        if(newUserList!=null && newUserList.size()>0){
            for(User usr : newUserList){       
                
                Set<String> geoCodeSet = new Set<String>();    
                String profileName = profileNameMap.get(usr.ProfileId);
                
                if(profileName != null && profileSharingCheckMap.containsKey(profileName) && profileSharingCheckMap.get(profileName) ==TRUE){  
                    
                    //Creating a set of geo-codes
                    if(usr.Assigned_Markets__c!=null){
                        geoCodeSet.addAll(usr.Assigned_Markets__c.split(';'));
                    }      
                    if(usr.Assigned_Hubs__c!=null){
                        geoCodeSet.addAll(usr.Assigned_Hubs__c.split(';'));
                    }
                    if(usr.Assigned_Clusters__c!=null){
                        geoCodeSet.addAll(usr.Assigned_Clusters__c.split(';'));
                    }
                    if(usr.Available_Countries__c!=null){ 
                        geoCodeSet.addAll(usr.Available_Countries__c.split(';'));
                    }                
                    
                    //Creating a mapping between userId and set of geo-codes
                    if(!userIdGeoCodeMap.containsKey(usr.Id)){
                        userIdGeoCodeMap.put(usr.Id,geoCodeSet);      
                    }
                }
            }
        }
        
        //Fetching a set containing the key 'userId_geography' of the highest geo-levels
        if(!userIdGeoCodeMap.isEmpty()){
            finalUserGeoMap = fetchHighestGeoCodeMethod(userIdGeoCodeMap);
        }
        
        //Creating sharing records
        if(finalUserGeoMap!= null && !finalUserGeoMap.isEmpty()){
            EDGE_SharingUtil.createAndDeleteSharingRecords(finalUserGeoMap, 'Insert');
        }
    }
    
    /* 
* @description  : validateAndReGenerateSharing
* @purpose : Modify, Validate sharing records for users on update
* @parameters : List<User> newItems,Map<Id, SObject> oldItems
*/
    public static void validateAndReGenerateSharing(List<User> newItems,Map<Id, SObject> oldItems){
        
        //Initialization
        Map<Id, User> mapOldItems = (Map<Id,User>)oldItems;
        Map<Id,Set<String>> newUserGeoCodeMap = new Map<Id,Set<String>>(); // Map of userid and country code
        Map<String,Boolean> profileSharingCheckMap = new Map<String,Boolean>();
        Map<Id,String> profileNameMap = new Map<Id,String>();
        Map<Id,Set<String>> accessDeletionMap = new Map<Id,Set<String>>();
        Map<Id,Set<Geography__c>> insertAccessShare;
        Map<Id,Set<Geography__c>> deleteAccessShare;
        //List<String> newItemList= new List<String>();
        Set<Id> profileIdset = new Set<Id>();
        
        //Creating a set of profiles
        for(User usr : newItems){
            profileIdset.add(usr.ProfileId);
        }
        
        //Creating a mapping between profile id and profile name
        if(profileIdset!=null && profileIdset.size()>0){
            for(Profile Profile : [SELECT Id,Name FROM Profile WHERE Id =:profileIdset]){
                profileNameMap.put(profile.id,profile.Name);
            }
        }
        
        //Creating a mapping of profile name and active flag in access sharing metadata    
        for(Profile_Access_Sharing_Check__mdt accessSharingCheck: [SELECT Id, Profile_Name__c, User_Access_Sharing__c
                                                                   FROM Profile_Access_Sharing_Check__mdt
                                                                   WHERE User_Access_Sharing__c = true])
        {
            profileSharingCheckMap.put(accessSharingCheck.Profile_Name__c,accessSharingCheck.User_Access_Sharing__c);
        }
        
        if(newItems!=null && newItems.size()>0){
            for(User userItem : newItems){
                if(userItem.isActive && mapoldItems.containskey(userItem.id)){
                    
                    User oldUser = mapoldItems.get(userItem.id);
                    if(userItem.Available_Countries__c != oldUser.Available_Countries__c ||
                       userItem.Assigned_Clusters__c != oldUser.Assigned_Clusters__c ||
                       userItem.Assigned_Hubs__c != oldUser.Assigned_Hubs__c ||
                       userItem.Assigned_Markets__c != oldUser.Assigned_Markets__c ||
                       userItem.ProfileId != oldUser.ProfileId)
                    {
                        String profileName = profileNameMap.get(userItem.ProfileId);
                        if(profileSharingCheckMap.containsKey(profileName) && profileSharingCheckMap.get(profileName)==TRUE){
                            
                            Set<String> oldCountryCodeSet = new Set<String>();
                            Set<String> newCountryCodeSet = new Set<String>();
                            
                            if(oldUser.Available_Countries__c != null){
                                String oldcountrycode = oldUser.Available_Countries__c;
                                List<String> oldcountryCodeList = oldcountrycode.split(';');
                                oldCountryCodeSet.addAll(oldcountryCodeList);
                            }
                            
                            if(userItem.Available_Countries__c != null ){
                                String newcountrycode = userItem.Available_Countries__c;
                                List<String> newcountryCodeList = newcountrycode.split(';');
                                newCountryCodeSet.addAll(newcountryCodeList);
                            }
                            
                            if(oldUser.Assigned_Clusters__c != null){
                                String oldcountrycode = oldUser.Assigned_Clusters__c;
                                List<String> oldcountryCodeList = oldcountrycode.split(';');
                                oldCountryCodeSet.addAll(oldcountryCodeList);
                            }
                            
                            if(userItem.Assigned_Clusters__c != null ){
                                String newcountrycode = userItem.Assigned_Clusters__c;
                                List<String> newcountryCodeList = newcountrycode.split(';');
                                newCountryCodeSet.addAll(newcountryCodeList);
                            }
                            
                            if(oldUser.Assigned_Hubs__c != null){
                                String oldcountrycode = oldUser.Assigned_Hubs__c;
                                List<String> oldcountryCodeList = oldcountrycode.split(';');
                                oldCountryCodeSet.addAll(oldcountryCodeList);
                            }
                            
                            if(userItem.Assigned_Hubs__c != null ){
                                String newcountrycode = userItem.Assigned_Hubs__c;
                                List<String> newcountryCodeList = newcountrycode.split(';');
                                newCountryCodeSet.addAll(newcountryCodeList);
                            }
                            
                            if(oldUser.Assigned_Markets__c != null){
                                String oldcountrycode = oldUser.Assigned_Markets__c;
                                List<String> oldcountryCodeList = oldcountrycode.split(';');
                                oldCountryCodeSet.addAll(oldcountryCodeList);
                            }
                            
                            if(userItem.Assigned_Markets__c != null ){
                                String newcountrycode = userItem.Assigned_Markets__c;
                                List<String> newcountryCodeList = newcountrycode.split(';');
                                newCountryCodeSet.addAll(newcountryCodeList);
                            }
                            
                            if(oldCountryCodeSet != null && oldCountryCodeSet.size()>0){
                                accessDeletionMap.put(oldUser.Id,oldCountryCodeSet);
                            }
                            if(newCountryCodeSet != null && newCountryCodeSet.size()>0){
                                newUserGeoCodeMap.put(userItem.Id,newCountryCodeSet);
                            }
                        }
                    }
                }
            }
        }
        
        if(accessDeletionMap!= null && accessDeletionMap.size()>0){
            deleteAccessShare = fetchHighestGeoCodeMethod(accessDeletionMap);          
        }
        
        if(newUserGeoCodeMap != null && newUserGeoCodeMap.size()>0){
            insertAccessShare= fetchHighestGeoCodeMethod(newUserGeoCodeMap);     
        }
        
        if(insertAccessShare != null){
            for(Id userId: insertAccessShare.keySet()){
                Set<Geography__c> newGeographySet = insertAccessShare.get(userId);
                for(Geography__c geoObj: newGeographySet){
                    if(deleteAccessShare!= null && deleteAccessShare.get(userId) !=null && deleteAccessShare.get(userId).contains(geoObj)){
                        deleteAccessShare.get(userId).remove(geoObj);
                    }
                }          
            }
        }
        
        if(deleteAccessShare!= null && deleteAccessShare.size()>0){
            EDGE_SharingUtil.createAndDeleteSharingRecords(deleteAccessShare, 'Delete');
        }
        
        if(insertAccessShare!= null && insertAccessShare.size()>0){
            EDGE_SharingUtil.createAndDeleteSharingRecords(insertAccessShare, 'Insert');
        }
    }
    
    /*
* @description  : fetchHighestGeoCodeMethod -> ES20-11673
* @purpose : To fetch the map of 'userId_geographyRec' for the highest geo-levels
* @parameters : Map<Id,Set<String>> userGeoCodeMap
*/
    public static Map<Id,Set<Geography__c>> fetchHighestGeoCodeMethod(Map<Id,Set<String>> userGeoCodeMap){
        
        //Initialization
        Map<String,Geography__c> geoMap = new Map<String,Geography__c>();
        Map<String,Geography__c> userCodeGeoMap = new Map<String,Geography__c>();
        Map<Id,Set<Geography__c>> userIdGeoMap = new Map<Id,Set<Geography__c>> ();
        // Map<String,String> geoCodeVsUserMap = new Map<String,String>();
        Set<String> geoCodeSet = new Set<String>();
        Set<String> allUserGeoCodeSet = new Set<String>();
        
        if(userGeoCodeMap!=null && userGeoCodeMap.size()>0){
            for(Id userId :userGeoCodeMap.keyset()){                 
                for(String geoCode: userGeoCodeMap.get(userId)){
                    geoCodeSet.add(geoCode);
                    allUserGeoCodeSet.add(geoCode + '_' + userId);  
                }
            }
            
            //Creating a mapping between geo-code and geo-record        
            if(geoCodeSet!=null && geoCodeSet.size()>0){
                for(Geography__c geoObj : [SELECT Id, Code__c,Sharing_Group_Name__c, Parent_Geography__c,Parent_Geography__r.Code__c, Parent_Geography__r.Parent_Geography__c,
                                           Parent_Geography__r.Parent_Geography__r.Code__c,Parent_Geography__r.Parent_Geography__r.Parent_Geography__c,
                                           Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c FROM Geography__c WHERE Code__c IN : geoCodeSet])
                {
                    if(!geoMap.containsKey(geoObj.Code__c)){
                        geoMap.put(geoObj.Code__c,geoObj);   
                    }
                }
            }
            
            //Creating a mapping between geoCode_userId key and its geography record
            if(allUserGeoCodeSet!=null && allUserGeoCodeSet.size()>0){
                for(String userGeoCode : allUserGeoCodeSet){
                    if(!userCodeGeoMap.containsKey(userGeoCode)){
                        String geoCode = userGeoCode.split('_').get(0);
                        if(geoCode != null && geoMap.containsKey(geoCode)){
                            userCodeGeoMap.put(userGeoCode,geoMap.get(geoCode));    
                        }     
                    }
                }
            }
            
            if(allUserGeoCodeSet!=null && allUserGeoCodeSet.size()>0){
                for(String userKey : allUserGeoCodeSet){
                    
                    //Initialization
                    Id userId = userKey.split('_').get(1);
                    String geoCode = userKey.split('_').get(0);
                    String userIdSuffix = '_' + userId;
                    String highestGeoCode = null;
                    Geography__c geoRec = geoMap.get(geoCode);
                    
                    if(geoRec != null){
                        //Checking for the highest-level parent of a geo-record//GB,GBH
                        if(geoRec.Code__c !=  null && userCodeGeoMap.containsKey(geoRec.Code__c+userIdSuffix)){
                            highestGeoCode = geoRec.Code__c;
                        }
                        if(geoRec.Code__c !=  null && geoRec.Parent_Geography__r.Code__c != null 
                           && userCodeGeoMap.containsKey(geoRec.Parent_Geography__r.Code__c+userIdSuffix))
                        { 
                            highestGeoCode = geoRec.Parent_Geography__r.Code__c;
                        }
                        if(geoRec.Code__c !=  null && geoRec.Parent_Geography__r.Code__c != null 
                           && geoRec.Parent_Geography__r.Parent_Geography__r.Code__c != null
                           && userCodeGeoMap.containsKey(geoRec.Parent_Geography__r.Parent_Geography__r.Code__c+userIdSuffix))
                        { 
                            highestGeoCode = geoRec.Parent_Geography__r.Parent_Geography__r.Code__c;
                        }
                        if(geoRec.Code__c !=  null && geoRec.Parent_Geography__r.Code__c != null 
                           && geoRec.Parent_Geography__r.Parent_Geography__r.Code__c != null
                           && geoRec.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c != null
                           && userCodeGeoMap.containsKey(geoRec.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c+userIdSuffix))
                        {
                            highestGeoCode = geoRec.Parent_Geography__r.Parent_Geography__r.Parent_Geography__r.Code__c;
                        } 
                        if(geoMap.get(highestGeoCode) != null){
                            if(userIdGeoMap.containsKey(userId)){
                                userIdGeoMap.get(userId).add(geoMap.get(highestGeoCode));
                            }
                            else{
                                userIdGeoMap.put(userId,new Set<Geography__c>{geoMap.get(highestGeoCode)});
                            }
                        }
                    }
                }
            }
        }
        return userIdGeoMap;
    }
    /* CST-495
* @description: As soon as a CST user is created (either CST profile or CST permission set added) they are automatically assigned 
*               to the Customer spend Report folder("All CST User" public group ),and there is no need to add them manually. 
* @retrun: void
* @param: Map<Id,sObject> newItems,Map<Id, SObject> oldItems
* */ 
    @future
    public static void addUserToCSTuserGroup(set<Id> newItems){
        addUserToCSTGroup(newItems);
    }
    public static void addUserToCSTGroup(set<Id> newItems){
        //UserVsPermissionSet
        Map<String,PermissionSetAssignment> userVsAssignemnt = new Map<String,PermissionSetAssignment>();
        List<PermissionSetAssignment> permissionSetAssignmentList = [SELECT Id, PermissionSetId, PermissionSet.Name, PermissionSet.ProfileId, PermissionSet.Profile.Name, AssigneeId, Assignee.Name 
                                                                     FROM PermissionSetAssignment WHERE (PermissionSet.Name='CST_Approver' OR PermissionSet.Name = 'CST_Creator' OR PermissionSet.Name = 'CST_Viewer')];
        
        for(PermissionSetAssignment assignement :  permissionSetAssignmentList){
            userVsAssignemnt.put(assignement.AssigneeId,assignement);
        }
        //Getting the users in Public Group 
        Set<Id> usersAlreadyAssigned = new Set<Id>();
        List<GroupMember> existingGroupMembers = [SELECT UserOrGroupId FROM GroupMember where Group.Name='All CST User'];
        for(GroupMember Grp:existingGroupMembers )
        {
            usersAlreadyAssigned.add(Grp.UserOrGroupId);
        }
        List<GroupMember> cstGroupMembers = new List<GroupMember>();
        Group cstGroup = [SELECT ID, DeveloperName FROM Group WHERE DeveloperName = 'All_CST_User'];
        for(user u : [SELECT Id,Profile.Name FROM User WHERE id in : newItems]){
            if(u.Profile.Name == 'CST Viewer' || u.Profile.Name == 'CST Creator' || 
               u.Profile.Name == 'CST Approver' || userVsAssignemnt.containsKey(u.Id) && (!usersAlreadyAssigned.contains(u.Id)))
            {
                GroupMember gm = new GroupMember();
                gm.GroupId = cstGroup.Id;
                gm.UserOrGroupId = U.Id;
                cstGroupMembers.add(GM);
            }
        }
        //Add users to the public group
        if(!cstGroupMembers.isEmpty()){
            insert cstGroupMembers;
        }
    }
    
    
}