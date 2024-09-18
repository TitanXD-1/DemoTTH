/**

* @Description : EDGE_UserTriggerHelperTest 

* @Purpose : Req: This is the test class for the  EDGE_UserTriggerHelper class and UserTriggerHandler class(ES20-219)

* @History:

* @Version       Developer         Date            User Story	        

*  1.0          Sagar Barman     13/02/2019    Initial Development
*  1.1   		Aparajita		 24/05/2021	   ES20-10074/ES20-10193(Method:testDistributorUserAssgnmentInTerritory,testDistributorUserAsyncLogic)
*  1.2   		Aparajita        29/12/2021	   ES20-11673/ES20-11674(Method:testUserSharing)
*  1.3          Saikiran         14/02/2023    CUS-42
*  1.4          Suvendu          14/07/2023    CUS-439
*/

@isTest
public class EDGE_UserTriggerHelperTest{
    
    @isTest
    public static void testDistributorUserAssgnmentInTerritory()
    {   
        User testAdminUserCO = EDGE_UtilityTestClass.runAsUser('AdminuserCO','System Administrator');
        testAdminUserCO.Available_Countries__c = 'CO';
        insert testAdminUserCO;
        ID geographyIdCO = EDGE_UtilityTestClass.setupCountryCO('CO');
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        System.runAs(testAdminUserCO) {
                             
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyIdCO,'Outlet Visit Prioritization');
            pickupOption.Name = 'GOLD[CO]';
            insert pickupOption;
            
            Account ownerAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            ownerAccount.Global_Channel__c = 'Off Trade';
            ownerAccount.Global_Sub_Channel__c ='Retailer';
            ownerAccount.Global_Segment__c = 'Discounter';
            ownerAccount.Global_Sub_Segment__c = 'Modern Discounter';
            ownerAccount.Person_Responsible__c = testAdminUserCO.id;
            ownerAccount.IsOwner__c = true;
            insert ownerAccount; 
            System.assert(ownerAccount != null);
            
            Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            operator.IsOperator__c = true;
            operator.Person_Responsible__c = testAdminUserCO.id;
            insert operator;   
            
            Account owner = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            owner.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            owner.IsOwner__c = true;
            owner.Person_Responsible__c = testAdminUserCO.id;
            insert owner;
            
            Test.startTest();
            
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outletAccount.Global_Channel__c = 'Off Trade';
            outletAccount.Global_Sub_Channel__c ='Retailer';
            outletAccount.Global_Segment__c = 'Discounter';
            outletAccount.Global_Sub_Segment__c = 'Modern Discounter'; 
            outletAccount.Independent_of_Operator__c = false;
            outletAccount.Independent_of_Owner__c = false;
            outletAccount.Operator__c = operator.Id;
            outletAccount.ParentId = owner.Id;
            insert outletAccount;                
            
            User testDistrSalesMgrCO = EDGE_UtilityTestClass.runAsUser('DistrSalesMgr','Distributor Sales Manager');
            testDistrSalesMgrCO.Available_Countries__c = 'CO';
            insert testDistrSalesMgrCO;
 
            User testDistrSalesRepCO = EDGE_UtilityTestClass.runAsUser('DistrSalesRep','Distributor Sales Representative');
            testDistrSalesRepCO.Available_Countries__c = 'CO';

            testDistrSalesRepCO.ManagerId =  testDistrSalesMgrCO.Id;  
            insert testDistrSalesRepCO;        
            
            User testDDM = EDGE_UtilityTestClass.runAsUser('testDDM','Distributor Data Manager');
            testDDM.Available_Countries__c = 'CO';
            insert testDDM;

            Test.stopTest();
        
        }
    }     
    
    @isTest
    public static void testUserAssgnmentInTerritory(){             
        
        //create MDM User
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('Adminuser','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;

        //Insert Geography
        ID geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        //EDGE_UtilityTestClass.createOrgSettings(); 
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        //run as MDM user and update Sales Rep user
        System.runAs(testAdminUser) {
            
            //Create Pick up Option Records
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
            pickupOption.Name = 'GOLD[AU]';
            insert pickupOption;
            
            Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            operator.IsOperator__c = true;
            operator.Person_Responsible__c = testAdminUser.id;
            insert operator;   
            
            Account owner = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            owner.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            owner.IsOwner__c = true;
            owner.Person_Responsible__c = testAdminUser.id;
            insert owner;

            //create outlet record 
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outletAccount.Global_Channel__c = 'Off Trade';
            outletAccount.Global_Sub_Channel__c ='Retailer';
            outletAccount.Global_Segment__c = 'Discounter';
            outletAccount.Global_Sub_Segment__c = 'Modern Discounter'; 
            outletAccount.Independent_of_Operator__c = false;
            outletAccount.Independent_of_Owner__c = false;
            outletAccount.Operator__c = operator.Id;
            outletAccount.ParentId = owner.Id;
            insert outletAccount;                
            
            User testSalesManagerUser = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            insert testSalesManagerUser;

            Test.startTest();
            
            //create Sales Rep user
            User runSalesRepUser = EDGE_UtilityTestClass.runAsUser('salesrepuser','Sales Representative');
            runSalesRepUser.ManagerId =  testSalesManagerUser.Id;  
            runSalesRepUser.Trax_User__c=true;
            runSalesRepUser.Calls_Per_Day__c = 1;
            insert runSalesRepUser;

            EDGE_UtilityClass.printGovLimits(88); 

            //check if any UserTerritory2Association record created. 
            List<UserTerritory2Association> utaList = [SELECT Id,UserId,Territory2Id FROM UserTerritory2Association WHERE UserId =: runSalesRepUser.id]; 
            Integer territoryListSize = utaList.size();           
            
            List<User> userList = new List<User>();
            User testMDMUser2 = EDGE_UtilityTestClass.runAsUser('testMDMUser2','Master Data Manager'); 
            testMDMUser2.Assigned_Clusters__c = 'AUSC';
            testMDMUser2.Trax_User__c=true;     
            userList.add(testMDMUser2);

            User testMDMUser3 = EDGE_UtilityTestClass.runAsUser('testMDMUser3','Master Data Manager'); 
            testMDMUser3.Assigned_Hubs__c = 'AUSH';
            testMDMUser3.Trax_User__c = true;
            userList.add(testMDMUser3); 
            
            User testMDMUser4 = EDGE_UtilityTestClass.runAsUser('testMDMUser4','Master Data Manager'); 
            testMDMUser4.Assigned_Markets__c = 'APAC';
            testMDMUser4.Trax_User__c=true;     
            userList.add(testMDMUser4); 
            
            User testMDMUser5 = EDGE_UtilityTestClass.runAsUser('testMDMUser5','Master Data Manager'); 
            testMDMUser5.Available_Countries__c = 'AU';
            testMDMUser5.Trax_User__c=true;     
            userList.add(testMDMUser5);
            
            User testDDMUser4 = EDGE_UtilityTestClass.runAsUser('testDDMUser4','Distributor Data Manager'); 
            testDDMUser4.Assigned_Markets__c = 'APAC';
            userList.add(testDDMUser4);
			
            insert userList;
						
            List<User> userListToUpd = new List<User>();
            for(User userObj : userList) {
                userObj.Trax_User__c = false;
                userObj.Available_Countries__c = 'AU';
                userObj.Assigned_Markets__c = 'APAC';
                userListToUpd.add(userObj); 
            }
            
            update userListToUpd;

            EDGE_UtilityClass.printGovLimits(135); 
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            insert terriHier;  
            
            Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
            terr.Territory_Type__c = 'Sales';
            terr.Region__c = terriHier.Id;
            terr.Sales_Area__c = terriHierSA.Id;
            terr.Business_Unit__c = terriHierBU.Id;
            terr.Country__c = geographyId;
            insert terr; 
            
            EDGE_UtilityClass.printGovLimits(155);
            
            Outlet_Territory__c outletTerr = new Outlet_Territory__c();
            outletTerr.Territory__c = terr.Id;
            outletTerr.Outlet__c = outletAccount.Id;
            insert outletTerr;
            
            Territory_Hierarchy_member__c terrHierMem2 = new Territory_Hierarchy_member__c();
            terrHierMem2.Territory_Hierarchy__c = terriHier.Id;
            terrHierMem2.User__c= testSalesManagerUser.Id;
            terrHierMem2.Start_Date__c = system.today();
            terrHierMem2.End_Date__c = system.today().addDays(25);
            insert terrHierMem2;
		
            runSalesRepUser.Calls_Per_Day__c = 2;

            update runSalesRepUser;
            
			Test.stopTest();       
        } 
    } 
    
    @isTest
    public static void testUserAsyncLogic()
    {
        ID geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        
        User testSalesManagerUser = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
        insert testSalesManagerUser;

        //create Sales Rep user
        User runSalesRepUser = EDGE_UtilityTestClass.runAsUser('salesrepuser','Sales Representative'); 
        runSalesRepUser.ManagerId =  testSalesManagerUser.Id;  
        runSalesRepUser.Trax_User__c=true;
        runSalesRepUser.Calls_Per_Day__c = 1;
        insert runSalesRepUser;
                
        Map<Id, User> newItemsMap = new Map<Id, User>();
        newItemsMap.put(runSalesRepUser.Id, runSalesRepUser);

        Test.startTest(); //Added By Kapil
        
        System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItemsMap,'After Insert','AssignTerritoryGroup'));
        
        Test.stopTest(); //Added By Kapil
    }
    
    @isTest
    public static void testDistributorUserAsyncLogic()
    {
        ID geographyIdCO = EDGE_UtilityTestClass.setupCountry('CO');
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
        //CUS-42 change -> Start
        User testMDM = EDGE_UtilityTestClass.runAsUser('testMDM','Master Data Manager');
        testMDM.Available_Countries__c = 'IE';
        testMDM.C360_Customer_360_User__c = true;
        
       
        system.runAs(new User(Id = UserInfo.getUserId())){
        insert testMDM;
        PermissionSet ps = new PermissionSet(Label = 'mockPs', Name = 'mockPs');
  		insert ps;
        
        SetupEntityAccess sea = new SetupEntityAccess(
            ParentId = ps.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission
            WHERE DeveloperName = 'C360_Permission_Set_Group_Custom_Permission'][0].Id
        );
        insert sea;
        
        PermissionSetAssignment psa = new PermissionSetAssignment(
            AssigneeId = testMDM.Id,
            PermissionSetId = ps.Id
          );
          insert psa;
        }
		//CUS-42 Change -> End
		//CUS-439 change -> Start
        User testLogistic = EDGE_UtilityTestClass.runAsUser('testLogistic','Case Management Minimum Access');
        testLogistic.Available_Countries__c = 'IE';
        testLogistic.C360_Customer_360_User__c = true;
        
        system.runAs(new User(Id = UserInfo.getUserId())){
            insert testLogistic;
            PermissionSet psForLogisticRep = new PermissionSet(Label = 'mockPs1', Name = 'mockPs1');
  		    insert psForLogisticRep;
            
            SetupEntityAccess setUpEnAcc = new SetupEntityAccess(
            ParentId = psForLogisticRep.Id,
            SetupEntityId = [SELECT Id FROM CustomPermission
            WHERE DeveloperName = 'C360_Permission_Set_Group_Custom_Permission'][0].Id
             );
            insert setUpEnAcc;
            PermissionSetAssignment perSetAssign = new PermissionSetAssignment(
            AssigneeId = testLogistic.Id,
            PermissionSetId = psForLogisticRep.Id
            );
            insert perSetAssign;
        }
		//CUS-439 Change -> End        
        
        User testDistrSalesMgrCO = EDGE_UtilityTestClass.runAsUser('DistrSalesMgr','Distributor Sales Manager');
        testDistrSalesMgrCO.Available_Countries__c = 'CO';
        insert testDistrSalesMgrCO;
        
        User testDistrSalesRepCO = EDGE_UtilityTestClass.runAsUser('DistrSalesRep','Distributor Sales Representative');
        testDistrSalesRepCO.Available_Countries__c = 'CO';
        testDistrSalesRepCO.ManagerId =  testDistrSalesMgrCO.Id;  
        insert testDistrSalesRepCO;        
        
        User testDDM = EDGE_UtilityTestClass.runAsUser('testDDM','Distributor Data Manager');
        testDDM.Available_Countries__c = 'CO';
        insert testDDM;
        
        Test.startTest(); //Added By Kapil
        Map<Id, User> newItemsMap = new Map<Id, User>();
        newItemsMap.put(testDistrSalesRepCO.id, testDistrSalesRepCO);
        System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItemsMap,'After Insert','AssignTerritoryGroup'));
        
        Map<Id, User> newItemsMapDDM = new Map<Id, User>();
        newItemsMapDDM.put(testDDM.id, testDDM);
        System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItemsMapDDM,'After Insert','AssignTerritoryGroup'));
        //CUS-42 change -> Start
        Map<Id, User> newItemsMapMDM = new Map<Id, User>();
        newItemsMapMDM.put(testMDM.id, testMDM);
        System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItemsMapMDM,'After Insert','AssignTerritoryGroup'));
        //CUS-42 change -> end
        Map<Id, User> newItemsMapLogistic = new Map<Id, User>();
        newItemsMapLogistic.put(testLogistic.id, testLogistic);
        System.enqueueJob(new D1_UserTriggerHelperQueueable(null,newItemsMapLogistic,'After Insert','AssignTerritoryGroup'));
        Test.stopTest(); //Added By Kapil
    }
    
    @isTest
    public static void testUserSharing(){
        
        //Assignment
        List<User> newItems = new List<User>(); 
		Map<Id,User> oldItems  = new Map<Id,User>();

        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
		Geography__c country = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:countryId];
        Id clusterId = country.Parent_Geography__c;
        Geography__c cluster = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:clusterId];
        Id hubId = cluster.Parent_Geography__c;
        Geography__c hub = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:hubId];
        Id marketId = hub.Parent_Geography__c;
        Geography__c market = [Select Id,Code__c,Parent_Geography__r.Code__c from Geography__c where Id=:marketId];

        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = false;
        insert orgSetting;
                
        User testSalesRepAU = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        testSalesRepAU.Available_Countries__c = country.Code__c;
        testSalesRepAU.Assigned_Clusters__c = cluster.Code__c;
        testSalesRepAU.Assigned_Hubs__c = hub.Code__c;
        testSalesRepAU.Assigned_Markets__c = market.Code__c;
        insert testSalesRepAU;
        
        Test.startTest();
        
        //INSERT -> ES20-11673
        newItems.add(testSalesRepAU);
		EDGE_UserTriggerHelper.checkAndGenerateSharing(newItems);   
        newItems.clear();
        
        //UPDATE -> ES20-11674/11675
        oldItems.put(testSalesRepAU.Id,testSalesRepAU);
        testSalesRepAU.Assigned_Markets__c = null;
		update testSalesRepAU;
        newItems.add(testSalesRepAU);
        EDGE_UserTriggerHelper.validateAndReGenerateSharing(newItems,oldItems);    
        
        Test.stopTest();
    }
}