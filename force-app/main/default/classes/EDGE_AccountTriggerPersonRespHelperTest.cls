/*
* @description: EDGE_AccountTriggerPersonRespHelperTest

* @purpose: Test class to cover EDGE_AccountTriggerPersonRespHelper class.   

* @history:                                                            

* @VERSION    AUTHOR               DATE           DETAIL

*	1.0      					24/05/2021        Initial Development
*   2.0                         21/03/2024        Fixed SCA 151701
*   3.0                         22/08/2024        PMD Fix
*/

@isTest
public class EDGE_AccountTriggerPersonRespHelperTest {
    
    static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    static String operatorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
    static String distributorRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId();
    
    @isTest
    public static void testShareOutletsToPersonResp(){
        
        List<User> users = new List<User>();
        List<Account> accounts = new List<Account>();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null,'Sales Manager has been added');
        
        //Creating Sales Rep 1
        User salesRep1 = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.Available_Countries__c = 'AU';
        salesRep1.ManagerId = salesManager.Id;
        users.add(salesRep1);        
        
        //Creating Sales Rep 2
        User salesRep2 = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep2.Available_Countries__c = 'AU';
        salesRep2.ManagerId = salesManager.Id;
        users.add(salesRep2);
        
        //Creating Sales Rep 3
        User salesRep3 = EDGE_UtilityTestClass.runAsUser('salesRep3','Sales Representative');
        salesRep3.Available_Countries__c = 'AU';
        salesRep3.ManagerId = salesManager.Id;
        users.add(salesRep3);
        
        Database.insert(users);
        System.assert(salesRep1.Id!=null,'Sales Rep has been added');
        System.assert(salesRep2.Id!=null,'Sales Rep has been added');
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Account operator1 = EDGE_UtilityTestClass.getOutletRecord(); 
        operator1.Name = 'test operator 001';
        operator1.RecordTypeId = operatorRecordTypeId;
        operator1.IsOperator__c = true;
        operator1.Person_Responsible__c = salesRep1.Id;
        operator1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        operator1.Global_Channel__c = 'Off Trade';
        operator1.Global_Sub_Channel__c ='Retailer';
        operator1.Global_Segment__c = 'Discounter';
        operator1.Global_Sub_Segment__c = 'Modern Discounter';
        accounts.add(operator1);
        
        Account operator2 = EDGE_UtilityTestClass.getOutletRecord(); 
        operator2.Name = 'test operator 002';
        operator2.RecordTypeId = operatorRecordTypeId;
        operator2.IsOperator__c = true;
        operator2.Person_Responsible__c = salesRep2.Id;
        operator2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        operator2.Global_Channel__c = 'Off Trade';
        operator2.Global_Sub_Channel__c ='Retailer';
        operator2.Global_Segment__c = 'Discounter';
        operator2.Global_Sub_Segment__c = 'Modern Discounter';
        accounts.add(operator2);
        Database.insert(accounts);
        
        
        //Scenario 1 : Insert an outlet with Operator
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Operator__c = operator1.Id;
        outlet.Independent_of_Operator__c = false;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';
        accounts.add(outlet);
        insert outlet;
        
        //Scenario 3: Change Person Responsible on an operator
        operator1.Person_Responsible__c = salesRep3.Id;
        Database.update(operator1);
        
        
        //Scenario 5: Assign Sales Rep 1 back to Person Responsible field
        operator1.Person_Responsible__c = salesRep1.Id;
        Database.update(operator1);
        
        //Scenario 2: Change Operator on an outlet
        outlet.Operator__c = operator2.Id;
        Database.update(outlet);
        Test.stopTest();
        //Scenario 6: Remove Operator from an outlet
        outlet.Operator__c = null;
        outlet.Independent_of_Operator__c = Boolean.valueOf('True');
        Database.update(outlet);
    }
    
    @isTest
    public static void testShareDistToPersonResp(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User newUser = EDGE_UtilityTestClass.runAsUser('TestUser', 'Distributor Data Manager');
        insert newUser;
        User newUser2 = EDGE_UtilityTestClass.runAsUser('TestUser2', 'Distributor Data Manager');
        insert newUser2;
        User newUser3 = EDGE_UtilityTestClass.runAsUser('TestUser3', 'Distributor Data Manager');
        insert newUser3;
        User newUser4 = EDGE_UtilityTestClass.runAsUser('TestUser4', 'Distributor Data Manager');
        insert newUser4;
        User newUser5 = EDGE_UtilityTestClass.runAsUser('TestUser5', 'Distributor Data Manager');
        insert newUser5;
        User newUser6 = EDGE_UtilityTestClass.runAsUser('TestUser6', 'Distributor Data Manager');
        insert newUser6;
        User newUser7 = EDGE_UtilityTestClass.runAsUser('TestUser7', 'Distributor Sales Manager');
        insert newUser7;
        User newUser8 = EDGE_UtilityTestClass.runAsUser('TestUser8', 'Distributor Sales Representative');
        newUser8.ManagerId=newUser7.Id;
        insert newUser8;
        Map<String,Id> geoMap = null;
        geoMap = EDGE_UtilityTestClass.geoMap;
        Test.startTest();
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold [AU]';
        insert pickOp;
        EDGE_UtilityTestClass.createOrgSettings();
        System.assert(pickOp.Name!=null,'Pickup Option has been added');
        Account distAcc = EDGE_UtilityTestClass.getDistriAccRec();
        // insert distAcc;
        distAcc.Person_Responsible__c = newUser4.Id;
        distAcc.Person_Responsible_2__c = newUser5.id;
        distAcc.Person_Responsible_3__c = newUser6.id;
        distAcc.Pending_for_Distributor_Batch__c = true;
        insert distAcc;
        distAcc.Person_Responsible__c = newUser.Id;
        distAcc.Person_Responsible_2__c = newUser2.id;
        distAcc.Person_Responsible_3__c = newUser3.id;
        distAcc.Pending_for_Distributor_Batch__c = true;
        upsert distAcc;
        System.debug(LoggingLevel.DEBUG,'distAcc'+distAcc);
        
        Group groupName=new Group();
        groupName.Name='Read_Write_0013N00000fPpgSQAA';
        insert groupName;
        Group groupName1=new Group();
        groupName1.Name='Read_Only_0013N00000fPpgSQBB';
        insert groupName1;
        Group groupName2=new Group();
        groupName2.Name='Read_Write_0013N00000fPpgSQNN';
        insert groupName2;
        String distAccId ='0013N00000fPpgSQBB' ;
        String distAccId1 ='0013N00000fPpgSQAA' ;
        Map<Id, Set<Id>> distIdToPersonRepIds = new Map<Id, Set<Id>>();
        distIdToPersonRepIds.put(distAccId, new Set<Id>{distAcc.Person_Responsible__c});
        distIdToPersonRepIds.put(distAccId1, new Set<Id>{distAcc.Person_Responsible__c});
        System.debug(LoggingLevel.DEBUG,'distIdToPersonRepIds--'+distIdToPersonRepIds);
        Set<String> groupNames = new Set<String>();
        
        groupNames.add(groupName.Name);
        groupNames.add(groupName1.Name);
        groupNames.add(groupName2.Name);
        System.runAs(new User(Id=UserInfo.getUserId())){
            GroupMember gm=new GroupMember(GroupId=groupName.id,UserOrGroupId=newUser.id);
            insert gm;
        }  
        System.runAs(new User(Id=UserInfo.getUserId())){
            GroupMember gm1=new GroupMember(GroupId=groupName1.id,UserOrGroupId=newUser8.id);
            insert gm1;
        }
        System.enqueueJob(new EDGE_DistributorGroupUserShare(distIdToPersonRepIds,groupNames));
        Test.stopTest();
    }
    
    @isTest
    public static void testDeleteUserSharing(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User newUser = EDGE_UtilityTestClass.runAsUser('TestUser', 'Distributor Data Manager');
        insert newUser;
        User newUser2 = EDGE_UtilityTestClass.runAsUser('TestUser2', 'Distributor Data Manager');
        insert newUser2;
        User newUser3 = EDGE_UtilityTestClass.runAsUser('TestUser3', 'Distributor Data Manager');
        insert newUser3;
        User newUser4 = EDGE_UtilityTestClass.runAsUser('TestUser4', 'Distributor Data Manager');
        insert newUser4;
        User newUser5 = EDGE_UtilityTestClass.runAsUser('TestUser5', 'Distributor Data Manager');
        insert newUser5;
        User newUser6 = EDGE_UtilityTestClass.runAsUser('TestUser6', 'Distributor Data Manager');
        insert newUser6;
        User newUser7 = EDGE_UtilityTestClass.runAsUser('TestUser7', 'Distributor Sales Manager');
        insert newUser7;
        User newUser8 = EDGE_UtilityTestClass.runAsUser('TestUser8', 'Distributor Sales Representative');
        newUser8.ManagerId=newUser7.Id;
        insert newUser8;
        Map<String,Id> geoMap = null;
        geoMap = EDGE_UtilityTestClass.geoMap;
        Test.startTest();
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold [AU]';
        insert pickOp;
        EDGE_UtilityTestClass.createOrgSettings();
        System.assert(pickOp.Name!=null,'Pickup Option has been added');
        Account distAcc = EDGE_UtilityTestClass.getDistriAccRec();
        // insert distAcc;
        distAcc.Person_Responsible__c = newUser4.Id;
        distAcc.Person_Responsible_2__c = newUser5.id;
        distAcc.Person_Responsible_3__c = newUser6.id;
        distAcc.Pending_for_Distributor_Batch__c = true;
        insert distAcc;
        distAcc.Person_Responsible__c = newUser.Id;
        distAcc.Person_Responsible_2__c = newUser2.id;
        distAcc.Person_Responsible_3__c = newUser3.id;
        distAcc.Pending_for_Distributor_Batch__c = true;
        upsert distAcc;
        System.debug(LoggingLevel.DEBUG,'distAcc'+distAcc);
        List<ID> distUserIdList = null;
        distUserIdList = new List<ID>();
        
        Map<id, List<id>> acctUserIdMap= new Map<id, List<id>>();
        acctUserIdMap.put(distAcc.id, new List<Id>{distAcc.Person_Responsible__c});
        List<ID> userIdList = new List<ID>();
        
        userIdList.add(distAcc.Person_Responsible__c);
        List<String> groupNames = new List<String>();
        Group groupName=new Group();
        groupName.Name='Read_Write_0013N00000fPpgSQAA';
        insert groupName;
        groupNames.add(groupName.Name);
        //<----------ES20-10310-starts-------------------->
        List<String> groupNames1 = new List<String>();
        Group groupName1=new Group();
        groupName1.Name='Read_Only_0013N00000fPpgSQAA';
        insert groupName1;
        groupNames1.add(groupName1.Name);
        
        Set<Id> userIds = new Set<Id>();
        List<Id> userList = new List<Id>();
        Map<id, List<id>> acctUserIdMap1= null;
        acctUserIdMap1 = new Map<id, List<id>>();
        System.runAs(newUser)
        {
            User newUser9 = EDGE_UtilityTestClass.runAsUser('TestUser9', 'Distributor Sales Representative');
            insert newUser9;
            userList.add(newUser9.id);
            newUser9.IsActive = false;
            userIds.add(newUser9.Id);
            EDGE_AccountTriggerPersonRespHelper.deleteInactiveDistSRSMFromAccountTeamAndGroup(userIds);
            
            List<AccountTeamMember> atmToDeleteList = [SELECT User.IsActive, User.Name, UserId, TeamMemberRole, Account.Name, AccountId 
                                                       FROM AccountTeamMember WHERE User.IsActive=false AND UserId IN : userIds];
            System.debug(LoggingLevel.DEBUG,'@@@'+atmToDeleteList.size());
            System.enqueueJob(new EDGE_DistSRSMAccountTeamMemberDelete(atmToDeleteList));
            List<GroupMember> gMemList1 = null;
            gMemList1 =  [SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMember WHERE GroupId=:groupNames1 
                                           AND UserOrGroupid IN : userIds];
        }
        List<GroupMember> gMemList = [SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMember where GroupId=:groupNames 
                                      AND UserOrGroupid=:userIdList];
        delete gMemList;
        EDGE_AccountTriggerPersonRespHelper.deleteGroupMem(acctUserIdMap);
        
        
        System.enqueueJob(new EDGE_DistributorRemoveUserSharing(userIdList,groupNames));
        Test.stopTest();
    }
    @isTest
    public static void testdeleteGroupMem()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'Country Fetched');
        Test.startTest();
        User ddmUser = EDGE_UtilityTestClass.runAsUser('ddmUser', 'Distributor Data Manager');
        insert ddmUser;
        Map<String,Id> geoMap = null;
        geoMap = EDGE_UtilityTestClass.geoMap;
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold [AU]';
        insert pickOp;
        EDGE_UtilityTestClass.createOrgSettings();
        Account distAcc = EDGE_UtilityTestClass.getDistriAccRec();
        distAcc.Person_Responsible__c = ddmUser.Id;
        insert distAcc;
        Map<id, List<id>> acctUserIdMap = new Map<id, List<id>>();
        List<id> distSRList = new List<id>();
        List<String> groupNameList = new List<String>();

        System.runAs(ddmUser)
        {
            User distSR = EDGE_UtilityTestClass.runAsUser('distSR', 'Distributor Sales Representative');
            insert distSR;
            distSRList.add(distSR.id);
            acctUserIdMap.put(distAcc.id,distSRList);
            distSR.IsActive = false;
        }
        EDGE_AccountTriggerPersonRespHelper.deleteGroupMem(acctUserIdMap);
        String groupNameReadOnly = 'Read_Only_'+String.valueOf(distAcc.Id);
        String groupNameReadWrite = 'Read_Write_'+String.valueOf(distAcc.Id);
        groupNameList.add(groupNameReadOnly);
        groupNameList.add(groupNameReadWrite);
        List<GroupMember> gMemList = [SELECT GroupId,Id,SystemModstamp,UserOrGroupId FROM GroupMember where Group.DeveloperName =: groupNameReadOnly
                                      AND UserOrGroupId IN :distSRList];
        delete gMemList;
        System.enqueueJob(new EDGE_DistributorRemoveUserSharing(distSRList,groupNameList));
        Test.stopTest();
    }
}