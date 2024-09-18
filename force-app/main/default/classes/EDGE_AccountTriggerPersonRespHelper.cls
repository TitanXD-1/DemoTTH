/**
* @Description: EDGE_AccountTriggerPersonRespHelper

* @Purpose: ES20-5716 : When an outlet is closed, all its associations from other objects / attributes should be removed for keeping the data clean and consistent, and configurable at market level. 

* @History:                                                            

* @VERSION    AUTHOR               DATE           DETAIL

*	1.0      Sandip Ghosh       06-May-2020      ES20-7962
*	1.1      Anamika Shukla     28-April-2021    ES20-10036 (for this story created methods are shareDistToPersonResp,prepAccountTeamMember,createGroup,AddToGroups,grpMemCreate,shareDistUser)
*	1.2      Monalisa Halder    20-May-2021      ES20-10013
*	1.4		 Aparajita          15-June-2021	 ES20-10310 (added: deleteInactiveDistSRSMFromAccountTeamAndGroup, modified: deleteGroupMem)
*	1.5		 Saranya/Aparajita  22-Feb-2022		 ES20-12028/ES20-12027(created: prepareAccountTeamList, recreated: addUpdateAccntShrFromOperator, modified : shareOutletsToPersonResp, populateAccTmMember)
*	1.6		 Prasanth T			15-Jul-2022		 ES20-13107(Manager Id null check introduced for person responsible field)
*	1.7		 Monalisa Halder	12-Sep-2022		 ES20-13286
*	1.8		 Monalisa Halder	27-Apr-2023		 ES20-13988
*	1.9		 Shivam/Rajarshi	03-June-2023	 135726(Replaced 'Distributer Responsible' in DIST_PERSON_RESPONSIBLE_ACCT_TEAM_STR)
*/
public without sharing class EDGE_AccountTriggerPersonRespHelper {
    
    final static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String operatorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
    final static String distributorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId();
    
    //ES20-10013
    private static String DIST_SALES_REP_PROFILE_STR = 'Distributor Sales Representative';
    private static String DIST_SALES_MANAGER_PROFILE_STR = 'Distributor Sales Manager';
    private static String DIST_DATA_MANAGER_PROFILE_STR = 'Distributor Data Manager';
    private static String DIST_SALES_REP_ACCT_TEAM_STR = 'Distributor Sales Rep';
    private static String DIST_SALES_MANAGER_ACCT_TEAM_STR = 'Distributor Sales Manager';
    //private static String DIST_PERSON_RESPONSIBLE_ACCT_TEAM_STR = 'Person Responsible';
    private static String DIST_PERSON_RESPONSIBLE_ACCT_TEAM_STR = 'Distributor Responsible';//135726
    private static String READ_WRITE_STR = 'Read_Write';
    private static String READ_ONLY_STR = 'Read_Only';
    
    public static void shareDistToPersonResp(List<SObject> newItems,Map<Id, SObject> oldItems){
        
        Map<Id,Account> oldAccMap = new Map<Id,Account>();
        List<Account> newAccounts = (List<Account>)newItems;
        List<AccountTeamMember> accTeamListToBeAdded = new List<AccountTeamMember>();
        Map<Id, Set<Id>> distIdToPersonRepIds = new Map<Id, Set<Id>>();
        
        //By ES20-10235
        Map<Id,List<Id>> acctUserIdMap = new Map<Id,List<Id>>();
        //Map<Id,String> userIdProfileMap = new Map<Id,String>();
        
        Set<ID> AccountIdSet = new Set<ID>();
        List<Id> personResIdList = new List<Id>(); 
        Map<Id,String> userIdProfileMap = new Map<Id,String>();
        //
        if(oldItems != null){
            oldAccMap = (Map<Id,Account>)oldItems;
        }
        for(Account accountRec: newAccounts){
            if(accountRec.RecordTypeId == distributorRecordTypeId){
                if(oldItems == null){//Insert Scenario
                    if(accountRec.Person_Responsible__c != null){
                        //ES20-10013 -- have put the user id and the profile name in the map
                        userIdProfileMap.put(accountRec.Person_Responsible__c,'Distributor Data Manager');
                        AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(accountRec,accountRec.Person_Responsible__c,'Distributor Data Manager');
                        accTeamListToBeAdded.add(accnTMToBeAdded);
                        distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, accountRec.Id, accountRec.Person_Responsible__c);
                    }
                    if(accountRec.Person_Responsible_2__c != null){
                        //ES20-10013 -- have put the user id and the profile name in the map
                        userIdProfileMap.put(accountRec.Person_Responsible_2__c,'Distributor Data Manager');
                        AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(accountRec,accountRec.Person_Responsible_2__c,'Distributor Data Manager');
                        accTeamListToBeAdded.add(accnTMToBeAdded);
                        distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, accountRec.Id, accountRec.Person_Responsible_2__c);
                    }
                    if(accountRec.Person_Responsible_3__c != null){
                        //ES20-10013 -- have put the user id and the profile name in the map
                        userIdProfileMap.put(accountRec.Person_Responsible_3__c,'Distributor Data Manager');
                        AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(accountRec,accountRec.Person_Responsible_3__c,'Distributor Data Manager');
                        accTeamListToBeAdded.add(accnTMToBeAdded);
                        distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, accountRec.Id, accountRec.Person_Responsible_3__c);
                    }
                }
                if(oldItems != null){//Update Scenario
                    Account oldAcct=oldAccMap.get(accountRec.Id);
                    if( oldAccMap.get(accountRec.Id).Person_Responsible__c != accountRec.Person_Responsible__c){
                        System.debug(accountRec.RecordType.name);
                        if(accountRec.Person_Responsible__c != null){
                            //ES20-10013 -- have put the user id and the profile name in the map
                            userIdProfileMap.put(accountRec.Person_Responsible__c,'Distributor Data Manager');
                            AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(accountRec, accountRec.Person_Responsible__c,'Distributor Data Manager');
                            accTeamListToBeAdded.add(accnTMToBeAdded);  
                        }
                        distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, accountRec.Id, accountRec.Person_Responsible__c);
                    }
                    if( oldAccMap.get(accountRec.Id).Person_Responsible_2__c != accountRec.Person_Responsible_2__c){
                        System.debug(accountRec.RecordType.name);
                        if(accountRec.Person_Responsible_2__c != null){
                            //ES20-10013 -- have put the user id and the profile name in the map
                            userIdProfileMap.put(accountRec.Person_Responsible_2__c,'Distributor Data Manager');
                            AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(accountRec, accountRec.Person_Responsible_2__c,'Distributor Data Manager');
                            accTeamListToBeAdded.add(accnTMToBeAdded);  
                        }
                        distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, accountRec.Id, accountRec.Person_Responsible_2__c);
                    }
                    if( oldAccMap.get(accountRec.Id).Person_Responsible_3__c != accountRec.Person_Responsible_3__c){
                        System.debug(accountRec.RecordType.name);
                        if(accountRec.Person_Responsible_3__c != null){
                            //ES20-10013 -- have put the user id and the profile name in the map
                            userIdProfileMap.put(accountRec.Person_Responsible_3__c,'Distributor Data Manager');
                            AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(accountRec, accountRec.Person_Responsible_3__c,'Distributor Data Manager');
                            accTeamListToBeAdded.add(accnTMToBeAdded);  
                        }
                        distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, accountRec.Id, accountRec.Person_Responsible_3__c);
                    }
                    
                    
                    //ES20-10235 Logic to delete Account Team Member >> Starts >> Anamika  */
                    if(oldAcct.Person_Responsible__c != accountRec.Person_Responsible__c) {
                        if(oldAcct.Person_Responsible__c != null){
                            personResIdList.add(oldAcct.Person_Responsible__c);  
                        }
                    }
                    if(oldAcct.Person_Responsible_2__c != accountRec.Person_Responsible_2__c){
                        if(oldAcct.Person_Responsible_2__c != null){
                            personResIdList.add(oldAcct.Person_Responsible_2__c);  
                        }
                    }
                    if(oldAcct.Person_Responsible_3__c != accountRec.Person_Responsible_3__c){
                        if(oldAcct.Person_Responsible_3__c != null){
                            personResIdList.add(oldAcct.Person_Responsible_3__c);  
                        }
                    }
                    AccountIdSet.add(oldAcct.id); 
                    if(acctUserIdMap.get(oldAcct.Id)==null && personResIdList != null && personResIdList.size()>0){
                        acctUserIdMap.put(oldAcct.Id,personResIdList);
                    }
                    //Logic to delete Account Team Member >> Ends >> Anamika
                }
            }
        }
        
        list<AccountTeamMember> atmRecList = [Select id,UserId,AccountId,TeamMemberRole from AccountTeamMember
                                              where (TeamMemberRole='Person Responsible'
                                                     AND UserId IN : personResIdList
                                                     AND AccountId IN :AccountIdSet)];
        if(atmRecList != Null && atmRecList.size() > 0){
            Database.delete(atmRecList); 
        }
        
        if(accTeamListToBeAdded.size() > 0){
            insert accTeamListToBeAdded;
        }
        
        if(distIdToPersonRepIds != null){
            EDGE_AccountTriggerPersonRespHelper.createGroup(distIdToPersonRepIds,userIdProfileMap);    
        }
        
        if(acctUserIdMap.size() > 0){
            System.enqueueJob(new EDGE_DistributorGroupMemberDelete(acctUserIdMap)); 
        }
    }
    
    //ES20-10235 : deletes the existing group member(DDM) from Read/Write groups(Anamika)
    //ES20-10310 : deletes the existing group member(Distributor SR/SM) from ReadOnly groups(Aparajita)
    public static void deleteGroupMem(Map<id, List<id>> acctUserIdMap){ 
        
        List<String> groupNameReadWriteList = new  List<String>();
        List<String> groupNameReadOnlyList = new  List<String>();
        List<String> groupNameList = new  List<String>();
        List<ID> userIdList = new List<ID>();               
        //ES20-10310
        List<GroupMember> gMemList = new List<GroupMember>();
        String profileType = '';
        String groupNameFirst = '';
        String groupNameSecond = '';
        System.debug('acctUserIdMap values::'+acctUserIdMap.values());
        if(acctUserIdMap != null && acctUserIdMap.size()> 0){
            List<Id> userIdListFromMap = acctUserIdMap.values().get(0);
            if(userIdListFromMap != null && userIdListFromMap.get(0) != null){
                List<User> users = [SELECT Id, Profile.Name FROM User WHERE Id =:userIdListFromMap.get(0)];
                if(users != null && users.size()> 0){
                    profileType = users[0].Profile.Name; //to check if it's a list of DDMs or DistSRSM
                }
            }
        }
        
        for(Id acc : acctUserIdMap.keySet()){
            if(profileType!=null)
            {
                if(profileType.equals(DIST_DATA_MANAGER_PROFILE_STR))
                {
                    groupNameFirst = READ_WRITE_STR+'_'+String.valueOf(acc);
                    groupNameSecond = READ_ONLY_STR+'_'+String.valueOf(acc);
                    groupNameReadWriteList.add(groupNameFirst);
                }
                else
                {
                    groupNameFirst = READ_ONLY_STR+'_'+String.valueOf(acc);
                    groupNameSecond = READ_WRITE_STR+'_'+String.valueOf(acc);
                    groupNameReadOnlyList.add(groupNameFirst);
                }    
            }
            groupNameList.add(groupNameFirst);
            groupNameList.add(groupNameSecond);
            List<Id> tempUserId = acctUserIdMap.get(acc);
            if(tempUserId != null)
                userIdList.addAll(tempUserId);
        }
        
        if(groupNameReadWriteList.size()>0){
            
            gMemList = [SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMember where Group.DeveloperName in 
                        :groupNameReadWriteList AND UserOrGroupId IN :userIdList];
        }
        else if((profileType.equals(DIST_SALES_REP_PROFILE_STR)||profileType.equals(DIST_SALES_MANAGER_PROFILE_STR)) && groupNameReadOnlyList.size()>0)
        {
            gMemList = [SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMember where Group.DeveloperName in 
                        :groupNameReadOnlyList AND UserOrGroupId IN :userIdList];      
        } 
        if(gMemList.size()>0)
        {
            delete gMemList;
            System.enqueueJob(new EDGE_DistributorRemoveUserSharing(userIdList,groupNameList));       
        } 
    }
    
    /**
* @Description  : initiateShareWithSRSM - ES20-10013
* @Purpose: This method is called from EDGE_UserTriggerHelper.distSalesRepMangerCreation
Creates a Map of Distributor Account and the respective Sales Rep and Manager records who have to be added to the Account Team & Groups
This method will be covered from EDGE_UserTriggerHelperTest.
*/
    public static void initiateShareWithSRSM(Map<Id, Set<User>> ddmUserIdToSRSMIdsMap, Map<Id,String> profileIdNameMap){
        //Map of Distributor Account Id and Set of Sales Rep , Sales Manager User records
        Map<Id, Set<User>> distAccountIdToSRSMUserMap = new Map<Id, Set<User>>();
        //Map of DDM User Id and Set of Distributor Account Id
        Map<Id,Set<Id>> ddmIdDistAccIdsMap = new Map<Id,Set<Id>>();
        for(AccountTeamMember accTeamMem :[Select Id,UserId,AccountId from AccountTeamMember where Account.RecordTypeId =:distributorRecordTypeId 
                                           and UserId IN :ddmUserIdToSRSMIdsMap.keySet()]){
                                               
                                               if(ddmIdDistAccIdsMap.get(accTeamMem.UserId) != null){
                                                   ddmIdDistAccIdsMap.get(accTeamMem.UserId).add(accTeamMem.AccountId);
                                               }
                                               else{
                                                   Set<Id> distAccountIdSet = new Set<Id>();
                                                   distAccountIdSet.add(accTeamMem.AccountId);
                                                   ddmIdDistAccIdsMap.put(accTeamMem.UserId,distAccountIdSet);
                                               }                                     
                                               
                                           }
        for(Id ddmUserId :ddmUserIdToSRSMIdsMap.keySet()){
            Set<User> userSet = ddmUserIdToSRSMIdsMap.get(ddmUserId);
            if(ddmIdDistAccIdsMap.containsKey(ddmUserId)){
                Set<Id> distributorAccIdSet = ddmIdDistAccIdsMap.get(ddmUserId);
                for(Id distAccId : distributorAccIdSet){
                    distAccountIdToSRSMUserMap.put(distAccId,userSet);
                    
                }
                
            }
            
        }
        if(distAccountIdToSRSMUserMap != null){
            
            insertDistAccTeamMemberForSRSM(distAccountIdToSRSMUserMap,profileIdNameMap);    
        }
        
    }
    
    /**
* @Description  : insertDistAccTeamMemberForSRSM - ES20-10013
* @Purpose : 
* @Parameters : Map<Id, Set<User>> distAccountIdToSRSMUserMap,Map<Id,String> profileIdNameMap
*/
    public static void insertDistAccTeamMemberForSRSM(Map<Id, Set<User>> distAccountIdToSRSMUserMap,Map<Id,String> profileIdNameMap){
        Map<Id, Set<Id>> distIdToPersonRepIds = new Map<Id, Set<Id>>();
        List<AccountTeamMember> accTeamListToBeAdded = new List<AccountTeamMember>();
        Map<Id,String> userIdProfileMap = new Map<Id,String>();
        
        for(Id distAccId : distAccountIdToSRSMUserMap.keySet()){
            Set<User> userSet = distAccountIdToSRSMUserMap.get(distAccId);
            for(User usr : userSet){
                if(profileIdNameMap.get(usr.ProfileId) != null){
                    userIdProfileMap.put(usr.Id,profileIdNameMap.get(usr.ProfileId));
                    AccountTeamMember accnTMToBeAdded = prepAccountTeamMember(new Account(Id=distAccId), usr.Id, profileIdNameMap.get(usr.ProfileId));
                    accTeamListToBeAdded.add(accnTMToBeAdded);
                }
                
                distIdToPersonRepIds = populateDistMap(distIdToPersonRepIds, distAccId, usr.Id);
                
                
            }
        }
        
        if(accTeamListToBeAdded.size() > 0){
            insert accTeamListToBeAdded;
        }
        if(distIdToPersonRepIds != null  && userIdProfileMap != null){
            createGroup(distIdToPersonRepIds,userIdProfileMap);    
        }
        
        
    }
    
    /**
* @Description  : populateDistMap
* @Purpose : 
* @Parameters : Map<Id, Set<Id>> distIdToPersonRepIds, Id accountRecId ,Id personRespId
*/
    private static Map<Id, Set<Id>> populateDistMap(Map<Id, Set<Id>> distIdToPersonRepIds, Id accountRecId ,Id personRespId ){
        if(!distIdToPersonRepIds.containsKey(accountRecId)){
            distIdToPersonRepIds.put(accountRecId, new Set<Id>{personRespId});
        }else{
            distIdToPersonRepIds.get(accountRecId).add(personRespId);
        }
        return distIdToPersonRepIds;
    }
    
    /**
* @Description  : prepAccountTeamMember - ES20-10013
* @Purpose : 
* @Parameters : Account accountRec, Id personRespId, String profileName
*/
    private static AccountTeamMember prepAccountTeamMember(Account accountRec, Id personRespId, String profileName){
        
        AccountTeamMember accnTMToBeAdded = new AccountTeamMember();            
        accnTMToBeAdded.AccountId = accountRec.Id;
        accnTMToBeAdded.UserId = personRespId; 
        accnTMToBeAdded.AccountAccessLevel = 'Edit';
        
        if(profileName != null && profileName == DIST_SALES_REP_PROFILE_STR){
            accnTMToBeAdded.TeamMemberRole = DIST_SALES_REP_ACCT_TEAM_STR;     
        }
        if(profileName != null && profileName == DIST_SALES_MANAGER_PROFILE_STR){
            accnTMToBeAdded.TeamMemberRole = DIST_SALES_MANAGER_ACCT_TEAM_STR;     
        }
        if(profileName != null && profileName == DIST_DATA_MANAGER_PROFILE_STR){
            accnTMToBeAdded.TeamMemberRole = DIST_PERSON_RESPONSIBLE_ACCT_TEAM_STR;    
        }
        return accnTMToBeAdded;
    }
    
    /**
* @Description  : createGroup - ES20-10013
* @Purpose : Group creation for DDM user 
* @Parameters : Map<Id, Set<Id>> distIdToPersonRepIds,Map<Id,String> userIdProfileMap
*/
    public static void createGroup(Map<Id, Set<Id>> distIdToPersonRepIds,Map<Id,String> userIdProfileMap){
        
        List<Group> groupToBeCreated = new List<Group>();
        Set<String> groupNames = new Set<String>();
        Set<String> groupNamesToBeCreated = new Set<String>();
        
        for(Id distAccId : distIdToPersonRepIds.keySet()){
            groupNames.add(READ_ONLY_STR+'_'+distAccId);
            groupNames.add(READ_WRITE_STR+'_'+distAccId);
            groupNamesToBeCreated.add(READ_ONLY_STR+'_'+distAccId);
            groupNamesToBeCreated.add(READ_WRITE_STR+'_'+distAccId);            
        }
        if(groupNames.size() > 0){
            for(Group existingGroup : [Select id, Name From Group where Name in :groupNames ]){
                if(groupNamesToBeCreated.contains(existingGroup.Name)){
                    groupNamesToBeCreated.remove(existingGroup.Name);
                    
                }
            }
        }
        if(groupNamesToBeCreated.size() > 0){
            for(String newGroupName :  groupNamesToBeCreated){
                Group gp = new Group(Name=newGroupName);
                groupToBeCreated.add(gp);
            }
        }
        if(groupToBeCreated.size() > 0){
            insert groupToBeCreated;
        } 
        if(distIdToPersonRepIds != null && groupNames != null && userIdProfileMap != null){
            addToGroups(distIdToPersonRepIds,groupNames,userIdProfileMap);    
        }
        
    }  
    // add member to created Group
    public static void addToGroups(Map<Id, Set<Id>> distIdToPersonRepIds, Set<String> groupNames,Map<Id,String> userIdProfileMap){
        
        List<GroupMember>listGroupMember =new List<GroupMember>();
        
        for(Group existingGroup : [Select id, Name From Group where Name in :groupNames ]){
            String groupName = existingGroup.Name;
            String distAccId = groupName.substringAfterLast('_');
            if(groupName.contains(READ_WRITE_STR)){    
                if(distIdToPersonRepIds != null && distIdToPersonRepIds.containsKey(distAccId)){
                    Set<Id> userIds = distIdToPersonRepIds.get(distAccId);
                    // loop the users that have been created
                    for (Id userId : userIds) {
                        //ES20-10013
                        if(userIdProfileMap.containsKey(userId) && userIdProfileMap.get(userId) == DIST_DATA_MANAGER_PROFILE_STR){
                            GroupMember gm = new GroupMember(); 
                            gm.GroupId = existingGroup.id;
                            gm.UserOrGroupId = userId;
                            listGroupMember.add(gm);    
                        }
                        
                    } 
                }
            }
            if(groupName.contains(READ_ONLY_STR)){ //SR /SM Profile check to be done  
                if(distIdToPersonRepIds != null && distIdToPersonRepIds.containsKey(distAccId)){
                    Set<Id> userIds = distIdToPersonRepIds.get(distAccId);
                    // loop the users that have been created
                    for (Id userId : userIds) {
                        //ES20-10013
                        if(userIdProfileMap.containsKey(userId) && (userIdProfileMap.get(userId) == DIST_SALES_REP_PROFILE_STR || userIdProfileMap.get(userId) == DIST_SALES_MANAGER_PROFILE_STR)){  
                            GroupMember gm = new GroupMember(); 
                            gm.GroupId = existingGroup.id;
                            gm.UserOrGroupId = userId;
                            listGroupMember.add(gm);
                        }
                    } 
                }
            }
        }
        
        if(listGroupMember.size() > 0 && distIdToPersonRepIds != null && groupNames != null){
            System.enqueueJob(new EDGE_DistributorGroupManager(listGroupMember,distIdToPersonRepIds,groupNames));    
        }  
    }
    
    // Newly Added
    public static void grpMemCreate(List<GroupMember>listGroupMember , Map<Id, Set<Id>> distIdToPersonRepIds, Set<String> groupNames){
        if(listGroupMember.size() > 0){
            Database.SaveResult[] srList = Database.insert(listGroupMember, false);
            
            // Iterate through each returned result
            for (Database.SaveResult sr : srList) {
                if (sr.isSuccess()) {
                    // Operation was successful, so get the ID of the record that was processed
                    System.debug('Successfully inserted Group Member. Group Member ID: ' + sr.getId());
                }
                else {
                    // Operation failed, so get all errors                
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('The following error has occurred.');                    
                        System.debug(err.getStatusCode() + ': ' + err.getMessage());
                        System.debug('Fields that affected this error: ' + err.getFields());
                    }
                }
            }      
        }
    }
    
    // Newly Added
    public static void shareDistUser(Map<Id, Set<Id>> distIdToPersonRepIds, Set<String> groupNames){
        
        List<UserShare> userShareList = new List<UserShare>();
        for(Group existingGroup : [Select id, Name From Group where Name in :groupNames ]){
            
            String groupName = existingGroup.Name;
            String distAccId = groupName.substringAfterLast('_');
            
            if(groupName.contains(READ_WRITE_STR)){    
                
                if(distIdToPersonRepIds != null && distIdToPersonRepIds.containsKey(distAccId)){
                    
                    Set<Id> userIds = distIdToPersonRepIds.get(distAccId);
                    // loop the users that have been created
                    for (Id userId : userIds) {
                        UserShare ushare = new UserShare();
                        ushare.UserOrGroupId = existingGroup.id;
                        ushare.UserId = userId;
                        ushare.UserAccessLevel = 'Edit';
                        userShareList.add(ushare);
                    } 
                }
            } 
            if(groupName.contains(READ_ONLY_STR)){    
                
                if(distIdToPersonRepIds != null && distIdToPersonRepIds.containsKey(distAccId)){
                    
                    Set<Id> userIds = distIdToPersonRepIds.get(distAccId);
                    // loop the users that have been created
                    for (Id userId : userIds) {
                        UserShare ushare = new UserShare();
                        ushare.UserOrGroupId = existingGroup.id;
                        ushare.UserId = userId;
                        ushare.UserAccessLevel = 'Read';
                        userShareList.add(ushare);
                    } 
                }
            }
        }
        if(userShareList.size() > 0){
            insert userShareList;
        }
    }   
    
    /**
* @Description  : shareOutletsToPersonResp
* @Purpose : This method starts the flow for sharing of an Outlet with an Operator when an account record of type Outlet is inserted or updated or an operator is updated
//ES20-7692 : Operator Person responsible sharing
//ES20-12027/12028 : Operator record insert scenario
* @Parameters : List<SObject> newItems, Map<Id, SObject> oldItems
*/
    public static void shareOutletsToPersonResp(List<SObject> newItems, Map<Id, SObject> oldItems){
        system.debug('Inside Method@@');
        //Assignment
        Set<Id> operatorRemovalIds = new Set<Id>();
        Set<Id> operatorToBeUpdatedIds = new Set<Id>();  
        List<Account> operators = new List<Account>();
        List<Id> operatorIds = new List<Id>();
        List<Id> outletIds = new List<Id>();
        List<AccountTeamMember> accTeamToBeAddedUpdated = new List<AccountTeamMember>();
        List<AccountTeamMember> accTeamToBeRemoved = new List<AccountTeamMember>();
        List<AccountTeamMember> revisedAccTeamToBeRemoved = new List<AccountTeamMember>();     
        List<Account> newAccounts = (List<Account>)newItems;
        Map<Id,Account> oldAccMap = new Map<Id,Account>();
        Map<Id, List<Id>> opToOutletIdsMap  = new Map<Id, List<Id>>();
        Map<Id, Id> operatorToPerResMap = new Map<Id, Id>();
        Map<Id, String> personResIdToProfName = new Map<Id, String> ();
        Map<Id, Id> personResToPerResManagerMap = new Map<Id, Id>(); //ECM-5675
        
        if(oldItems != null){
            oldAccMap = (Map<Id,Account>)oldItems;
        }
        
        //Populating a map of outlet id to their corresponding operator id
        for(Account acc : newAccounts){
            if(oldItems != null){//Outlet record update scenario       
                if(acc.RecordTypeId == outletRecordTypeId && /*acc.Operator__c != null &&*/ oldAccMap.get(acc.Id).Operator__c != acc.Operator__c){
                    if(acc.Operator__c != null){
                        Id opId = acc.Operator__c;
                        if(opToOutletIdsMap.containsKey(opId)){
                            opToOutletIdsMap.get(opId).add(acc.Id);  
                        }else{
                            opToOutletIdsMap.put(opId,new List<Id>{acc.Id});   
                        }
                        operatorIds.add(opId);
                    }
                    outletIds.add(acc.Id);                    
                }
                
                //Operator record update scenario
                if(acc.RecordTypeId == operatorRecordTypeId && oldAccMap.get(acc.Id).Person_Responsible__c != acc.Person_Responsible__c && acc.IsOperator__c){
                    if(acc.Person_Responsible__c == null){
                        operatorRemovalIds.add(acc.Id);
                    }else{
                        operatorToBeUpdatedIds.add(acc.Id);
                    }
                    operatorToPerResMap.put(acc.Id, acc.Person_Responsible__c);
                    //ECM-5675->start
                    if(acc.Person_Responsible__r.ManagerId != Null){
                    	personResToPerResManagerMap.put(acc.Person_Responsible__c,acc.Person_Responsible__r.ManagerId);//ECM-5675
                    }
                    //ECM-5675->End
                    operatorIds.add(acc.Id);
                    
                }                   
            }else{
                //Outlet record insert scenario
                if(acc.RecordTypeId == outletRecordTypeId && acc.Operator__c != null){
                    Id opId = acc.Operator__c;
                    if(opToOutletIdsMap.containsKey(opId)){
                        opToOutletIdsMap.get(opId).add(acc.Id);  
                    }else{
                        opToOutletIdsMap.put(opId,new List<Id>{acc.Id});   
                    }
                    operatorIds.add(opId);
                }
                
                //Operator record insert scenario -> ES20-12027/12028
                if(acc.RecordTypeId == operatorRecordTypeId && acc.Person_Responsible__c != null && acc.IsOperator__c){
                    operatorToBeUpdatedIds.add(acc.Id);
                    operatorIds.add(acc.Id);
                }
            }
        }
        
        //Querying the details of the operator records based on the operator ids
        //ECM-5675- added managerid in query
        if(operatorIds.size() > 0){//opToOutletIdsMap.size() > 0){//opToOutletAccMapInsert.size() > 0 || opToOutletAccMapUpdate.size() > 0
            operators = [Select Id, Person_Responsible__c, Person_Responsible__r.Profile.Name,Person_Responsible__r.ManagerId from Account where Id in :operatorIds
                         and IsOperator__c = true]; //:opToOutletIdsMap.keySet()]; // OR Id in :opToOutletAccMapUpdate.keySet()
        } 
        
        for(Account operatorAcc : operators){
            operatorToPerResMap.put(operatorAcc.Id, operatorAcc.Person_Responsible__c);
            personResIdToProfName.put(operatorAcc.Person_Responsible__c, operatorAcc.Person_Responsible__r.Profile.Name);
            //ECM-5675->start
            if(operatorAcc.Person_Responsible__r.ManagerId != Null){
            	personResToPerResManagerMap.put(operatorAcc.Person_Responsible__c,operatorAcc.Person_Responsible__r.ManagerId);//ECM-5675
            }
            //ECM-5675->End
        }
        
        accTeamToBeRemoved = addUpdateAccntShrFromOutlet(operators, outletIds, accTeamToBeAddedUpdated, accTeamToBeRemoved, opToOutletIdsMap, operatorToPerResMap, personResIdToProfName);
        
        if(operatorRemovalIds.size() > 0 || operatorToBeUpdatedIds.size() > 0){
            //ECM-5675- added last parameter personResToPerResManagerMap
            accTeamToBeRemoved = addUpdateAccntShrFromOperator(accTeamToBeAddedUpdated, accTeamToBeRemoved, operatorRemovalIds, operatorToBeUpdatedIds, operatorToPerResMap, personResIdToProfName,personResToPerResManagerMap);
        }
        
        /*ES20-13286 - change start*/
        /*if(accTeamToBeRemoved.size() > 0){
            Database.delete(accTeamToBeRemoved);
        }*/
        if(accTeamToBeRemoved.size() > 0 || accTeamToBeAddedUpdated.size() > 0){
            
            if(accTeamToBeRemoved.size() > 0 && accTeamToBeAddedUpdated.size() == 0){
               System.enqueueJob(new EDGE_PersonRespAccTeamMemberDelete(accTeamToBeRemoved,null));  
            }else if(accTeamToBeAddedUpdated.size() > 0 && accTeamToBeRemoved.size() == 0){
               System.enqueueJob(new EDGE_PersonRespAccTeamMemberAdd(accTeamToBeAddedUpdated));  
            }else if(accTeamToBeRemoved.size() > 0 && accTeamToBeAddedUpdated.size() > 0){
               System.enqueueJob(new EDGE_PersonRespAccTeamMemberDelete(accTeamToBeRemoved,accTeamToBeAddedUpdated));  
            }
            
        }
        
        /*if(accTeamToBeAddedUpdated.size() > 0){
            Database.insert(accTeamToBeAddedUpdated);
        }*/ 
       /*ES20-13286 - change end*/
    }
    
    /**
* @Description  : addUpdateAccntShrFromOutlet
* @Purpose : This method prepares Account Team records for adding or updating an Operator Responsible Person to the Account team of the outlet(s) which are placed under the Operator. 
             This is for the scenraios where Operator field changes on an outlet.
             //ES20-7692 : Operator Person responsible sharing
* @Parameters : List<Account> operators, List<Id> outletIds, List<AccountTeamMember> accTeamToBeAdded, List<AccountTeamMember> accTeamToBeRemoved, Map<Id, List<Id>> opToOutletIdsMap, Map<Id, Id> operatorToPerResMap, Map<Id, String> personResIdToProfName
*/
    private static List<AccountTeamMember> addUpdateAccntShrFromOutlet(List<Account> operators, List<Id> outletIds, List<AccountTeamMember> accTeamToBeAdded, List<AccountTeamMember> accTeamToBeRemoved, Map<Id, List<Id>> opToOutletIdsMap, Map<Id, Id> operatorToPerResMap, Map<Id, String> personResIdToProfName){
        
        Map<Id, Set<Id>> acctIdToTeamMemberIds = new Map<Id, Set<Id>>();
        
        if(outletIds != null && outletIds.size() > 0){
            List<AccountTeamMember> accTeams = [SELECT Id,AccountId,UserId,Account.Operator__c,TeamMemberRole FROM AccountTeamMember where
                                                AccountId in :outletIds /*and TeamMemberRole = 'Person Responsible'*/];
            for(AccountTeamMember accTeam: accTeams){
                if(accTeam.TeamMemberRole == 'Person Responsible'){
                    accTeamToBeRemoved.add(accTeam);
                }else{
                    Id outletId = accTeam.AccountId;
                    if(outletId != null){
                        if(acctIdToTeamMemberIds.containsKey(outletId)){
                            acctIdToTeamMemberIds.get(outletId).add(accTeam.UserId); 
                        }else{
                            acctIdToTeamMemberIds.put(outletId, new Set<Id>{accTeam.UserId});
                        }
                    }
                }
            }
        }
        
        if(operators != null && operators.size() > 0){          
            for(Account operator : operators){       
                Id operatorId = operator.Id;
                Id personRespId = operatorToPerResMap.get(operatorId);
                String profileName = personResIdToProfName.get(personRespId); 
                if(personRespId != null && profileName != null && !profileName.equalsIgnoreCase('System Administrator') && !profileName.equalsIgnoreCase('Master Data Manager')){
                    populateAccTmMember(acctIdToTeamMemberIds, opToOutletIdsMap.get(operatorId), personRespId, accTeamToBeAdded);
                }
            }        
        }
        return accTeamToBeRemoved;
    }
    
    /**
* @Description  : addUpdateAccntShrFromOperator
* @Purpose : This method prepares Account Team records for adding or updating an Operator Responsible Person to the Account team of the outlet(s) which are placed under the Operator. 
			 This is for the scenarios where Operator field changes on an outlet. 
             This is for the scenario when Operator Responsible person gets changed on the Operator
             //ES20-7692 : Operator Person responsible sharing
             //ES20-12028/ES20-12027 : recreated the method to optimize it and added the logic for insert/removal of OPR from ATM of Operator
             //ECM-5675- added last parameter personResToPerResManagerMap
* @Parameters : List<AccountTeamMember> accTeamToBeAdded, List<AccountTeamMember> accTeamToBeRemoved, Set<Id> operatorRemovalIds, Set<Id> operatorToBeUpdatedIds, Map<Id, Id> operatorToPerResMap, Map<Id, String> personResIdToProfName
*/
    private static List<AccountTeamMember> addUpdateAccntShrFromOperator(List<AccountTeamMember> accTeamToBeAdded, List<AccountTeamMember> accTeamToBeRemoved, Set<Id> operatorRemovalIds, Set<Id> operatorToBeUpdatedIds, Map<Id, Id> operatorToPerResMap, Map<Id, String> personResIdToProfName,Map<Id, Id> personResToPerResManagerMap){
        
        //Assignment
        List<Account> outlets = [Select Id,Operator__c from Account where Operator__c in :operatorRemovalIds OR Operator__c in :operatorToBeUpdatedIds];
        Set<Id> outletIds = (new Map<Id,Account>(outlets)).keySet().clone();
        List<AccountTeamMember> accTeams = new List<AccountTeamMember>();
        List<AccountTeamMember> operatorAccTeams = new List<AccountTeamMember>();
        
        for(AccountTeamMember accTeamRec : [SELECT AccountId,Account.RecordType.Name,Id,Account.Operator__c,TeamMemberRole,UserId FROM AccountTeamMember where
                                            AccountId in :outletIds OR  AccountId in:operatorRemovalIds OR  AccountId in:operatorToBeUpdatedIds])
        {
            if(accTeamRec.Account.RecordType.Name == 'Outlet'){
                //ES20-13988 --start
               if(accTeamRec.TeamMemberRole == 'Person Responsible'){
                   accTeams.add(accTeamRec); 
                }
                //accTeams.add(accTeamRec);
                //ES20-13988 - end 
            }
            if(accTeamRec.Account.RecordType.Name == 'Owner/Operator'){
                operatorAccTeams.add(accTeamRec);
            }             
        }
        //ECM-5675- added last parameter personResToPerResManagerMap
        prepareAccountTeamList(accTeams, operatorRemovalIds, accTeamToBeRemoved, 
                               operatorToBeUpdatedIds,operatorToPerResMap, personResIdToProfName,accTeamToBeAdded, 
                               outlets,true,personResToPerResManagerMap);
        
        //ECM-5675- added last parameter personResToPerResManagerMap
        prepareAccountTeamList(operatorAccTeams, operatorRemovalIds, accTeamToBeRemoved, 
                               operatorToBeUpdatedIds,operatorToPerResMap, personResIdToProfName,accTeamToBeAdded, 
                               outlets,false,personResToPerResManagerMap);
        
        return accTeamToBeRemoved;
    }
    
    /**
* @Description  : prepareAccountTeamList -> ES20-12027/12028
* @Purpose : This method prepares the list of Account Team records for outlets and operators
* @Parameters : List<AccountTeamMember> accTeams, Set<Id> operatorRemovalIds,List<AccountTeamMember> accTeamToBeRemoved, Set<Id> operatorToBeUpdatedIds,
				Map<Id, Id> operatorToPerResMap, Map<Id, String> personResIdToProfName,List<AccountTeamMember> accTeamToBeAdded, List<Account> outlets,Boolean isOutlet
                //ECM-5675- added last parameter personResToPerResManagerMap
*/
    @TestVisible
    private static void prepareAccountTeamList(List<AccountTeamMember> accTeams, Set<Id> operatorRemovalIds,
                                               List<AccountTeamMember> accTeamToBeRemoved, Set<Id> operatorToBeUpdatedIds,
                                               Map<Id, Id> operatorToPerResMap, Map<Id, String> personResIdToProfName,
                                               List<AccountTeamMember> accTeamToBeAdded, List<Account> outlets,
                                               Boolean isOutlet,Map<Id, Id> personResToPerResManagerMap)
    {
        //Assignment
        Map<Id, List<Id>> opToOutletsMap = new Map<Id, List<Id>>();
        Map<Id, Set<Id>> acctIdToTeamMemberIds = new Map<Id, Set<Id>>();
        List<AccountTeamMember> accTeamMembers = new List<AccountTeamMember>();
        
        //ECM-5675- added sales manager condtion in below for loop
        for(AccountTeamMember accTeam: accTeams){
            if(accTeam.TeamMemberRole == 'Person Responsible' || accTeam.TeamMemberRole == 'Sales Manager'){
                accTeamMembers.add(accTeam);
            }else{
                Id outletId = accTeam.AccountId;
                if(outletId != null){
                    if(acctIdToTeamMemberIds.containsKey(outletId)){
                        acctIdToTeamMemberIds.get(outletId).add(accTeam.UserId);
                    }else{
                        acctIdToTeamMemberIds.put(outletId, new Set<Id>{accTeam.UserId});
                    }
                }
            }
        }
        
        if(accTeamMembers != null && !accTeamMembers.isEmpty()){
            for(AccountTeamMember accTeam : accTeamMembers){
                Id operatorId = isOutlet ? accTeam.Account.Operator__c:accTeam.AccountId;
                if(operatorRemovalIds.contains(operatorId)){
                    accTeamToBeRemoved.add(accTeam);
                }
                if(operatorToBeUpdatedIds.contains(operatorId)){
                    accTeamToBeRemoved.add(accTeam);
                    Id personRespId = operatorToPerResMap.get(operatorId);
                    String profileName = personResIdToProfName.get(personRespId);
                    Id personRespManagerId = personResToPerResManagerMap.get(personRespId);//ECM-5675
                    if(personRespId != null && profileName != null && !profileName.equalsIgnoreCase('System Administrator') && !profileName.equalsIgnoreCase('Master Data Manager')){
                        populateAccTmMember(acctIdToTeamMemberIds,new List<Id>{accTeam.AccountId}, personRespId, accTeamToBeAdded);
                        if(personRespManagerId != null){ //ES20-13107
                            populateAccTmMemberManager(acctIdToTeamMemberIds,new List<Id>{operatorId}, personRespManagerId, accTeamToBeAdded);//ECM-5675
                        }
                    }
                }
            }
        }else{// Adding Person Responsible to an Operator record where PR was blank previously
            if(isOutlet){
                for(Account outlet : outlets){
                    Id opId = outlet.Operator__c;
                    if(opToOutletsMap.containsKey(opId)){
                        opToOutletsMap.get(opId).add(outlet.Id);
                    }else{
                        opToOutletsMap.put(opId,new List<Id>{outlet.Id});
                    }
                }
                for(Id operatorId : opToOutletsMap.keySet()){
                    List<Id> outletRecIds = opToOutletsMap.get(operatorId);
                    Id perRespId = operatorToPerResMap.get(operatorId);
                    String profileName = personResIdToProfName.get(perRespId);
                    if(perRespId != null && profileName != null && !profileName.equalsIgnoreCase('System Administrator') && !profileName.equalsIgnoreCase('Master Data Manager')){
                        populateAccTmMember(acctIdToTeamMemberIds,outletRecIds, perRespId, accTeamToBeAdded);
                    }
                }
            }else{//Operator
                for(Id operatorId : operatorToBeUpdatedIds){
                    Id perRespId = operatorToPerResMap.get(operatorId);
                    String profileName = personResIdToProfName.get(perRespId);
                    Id perRespManagerId = personResToPerResManagerMap.get(perRespId);//ECM-5675
                    if(perRespId != null && profileName != null && !profileName.equalsIgnoreCase('System Administrator') && !profileName.equalsIgnoreCase('Master Data Manager')){
                        populateAccTmMember(acctIdToTeamMemberIds,new List<Id>{operatorId}, perRespId, accTeamToBeAdded);
                        if(perRespManagerId != null){ //ES20-13107
                            populateAccTmMemberManager(acctIdToTeamMemberIds,new List<Id>{operatorId}, perRespManagerId, accTeamToBeAdded);//ECM-5675
                        }
                    }
                }
            }
        }
    }
    
    /**
* @Description  : populateAccTmMember
* @Purpose : This method creates Account Team records List from Ground up for all the outlets under an operator
* @Parameters : Map<Id, Set<Id>> acctIdToTeamMemberIds, List<Id> outletIds, Id perRespId, List<AccountTeamMember> accTeamToBeAdded
*/
    private static void populateAccTmMember(Map<Id, Set<Id>> acctIdToTeamMemberIds, List<Id> outletIds, Id perRespId, List<AccountTeamMember> accTeamToBeAdded){
        
        if(outletIds != null && outletIds.size() > 0){
            for(Id outletId : outletIds){
                if(outletId != null){
                    Set<Id> teamMemIds;
                    if(acctIdToTeamMemberIds != null && acctIdToTeamMemberIds.size() > 0){
                        teamMemIds = acctIdToTeamMemberIds.get(outletId);
                    }
                    if((teamMemIds == null) || (teamMemIds != null && !teamMemIds.contains(perRespId))){// No account team member record exists for the same user on the same account
                        AccountTeamMember accnTMToBeAdded = new AccountTeamMember();
                        accnTMToBeAdded.AccountId = outletId;
                        accnTMToBeAdded.UserId = perRespId;
                        accnTMToBeAdded.AccountAccessLevel = 'Edit'; //ES20-12027/12028
                        accnTMToBeAdded.ContactAccessLevel = 'Edit'; //ES20-12027/12028
                        accnTMToBeAdded.TeamMemberRole = 'Person Responsible';
                        accTeamToBeAdded.add(accnTMToBeAdded); 
                    }
                }              
            }   
        }          
    }
    
 //ECM-5675-Start
      /**
* @Description  : populateAccTmMemberManager
* @Purpose : This method creates Account Team records List from Ground up for all the outlets under an operator
* @Parameters : Map<Id, Set<Id>> acctIdToTeamMemberIds, List<Id> outletIds, Id perRespManagerId, List<AccountTeamMember> accTeamToBeAdded
*/
    private static void populateAccTmMemberManager(Map<Id, Set<Id>> acctIdToTeamMemberIds, List<Id> outletIds, Id perRespManagerId, List<AccountTeamMember> accTeamToBeAdded){
        
        if(outletIds != null && outletIds.size() > 0){
            for(Id outletId : outletIds){
                if(outletId != null){
                    Set<Id> teamMemIds;
                    if(acctIdToTeamMemberIds != null && acctIdToTeamMemberIds.size() > 0){
                        teamMemIds = acctIdToTeamMemberIds.get(outletId);
                    }
                    if((teamMemIds == null) || (teamMemIds != null && !teamMemIds.contains(perRespManagerId))){// No account team member record exists for the same user on the same account
                        AccountTeamMember accnTMToBeAdded = new AccountTeamMember();
                        accnTMToBeAdded.AccountId = outletId;
                        accnTMToBeAdded.UserId = perRespManagerId;
                        accnTMToBeAdded.AccountAccessLevel = 'Edit'; //ES20-12027/12028
                        accnTMToBeAdded.ContactAccessLevel = 'Edit'; //ES20-12027/12028
                        accnTMToBeAdded.TeamMemberRole = 'Sales Manager';
                        accTeamToBeAdded.add(accnTMToBeAdded); 
                    }
                }              
            }   
        }          
    }
 //ECM-5675-End
    
    /**
* @Description  : deleteInactiveDistSRSMFromAccountTeamAndGroup : ES20-10310
* @Purpose : Deletes the inactive Distributor Sales User from AccountTeamMember and Groups. 
It is called from the EDGE_UserTriggerHelper.fetchInactiveDistSRSMFromAccount()
* @Parameters : Set<Id> userIds
*/
    public static void deleteInactiveDistSRSMFromAccountTeamAndGroup(Set<Id> userIds)
    {
        Map<id, List<id>> acctUserIdMap = new Map<id, List<id>>();
        if(userIds != null && userIds.size()>0)
        {
            Map<Id, List<Id> > accToAtmUsersMap = new Map<Id, List<Id> >();
            List<AccountTeamMember> atmToDeleteList = new List<AccountTeamMember>();
            
            for(AccountTeamMember accTeamMember : [SELECT User.IsActive, User.Name, UserId, TeamMemberRole, 
                                                   Account.Name, AccountId 
                                                   FROM AccountTeamMember
                                                   WHERE User.IsActive = FALSE AND UserId IN :userIds])
            {
                
                if(accToAtmUsersMap.containsKey(accTeamMember.AccountId))
                    accToAtmUsersMap.get(accTeamMember.AccountId).add(accTeamMember.UserId); 
                else
                    accToAtmUsersMap.put(accTeamMember.AccountId, new List<Id> {accTeamMember.UserId});
                
                atmToDeleteList.add(accTeamMember);
            }
            
            // deleting the inactive user from AccountTeamMember and Group
            if(atmToDeleteList != null && atmToDeleteList.size() > 0)
                System.enqueueJob(new EDGE_DistSRSMAccountTeamMemberDelete(atmToDeleteList));  
            
            if(accToAtmUsersMap != null && accToAtmUsersMap.keySet().size() > 0)
                System.enqueueJob(new EDGE_DistributorGroupMemberDelete(accToAtmUsersMap)); 
        }
    }
}