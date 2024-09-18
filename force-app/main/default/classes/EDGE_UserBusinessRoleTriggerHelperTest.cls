/*
* @Name: EDGE_UserBusinessRoleTriggerHelperTest
* @Req: This is the test class for the  EDGE_UserBusinessRoleTriggerHelper class. 
		It also covers UserTriggerHandler class.

* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*	1.0   	Sandeep Sahoo     26/02/2019      Initial Development
*	1.1		Pradeep Kumar	  25/11/2020	  ECM-3346
*	1.2 	Pradeep Kumar 	  07/12/2020	  User Story ECM-3432 - Validation for Update Functionality
*   1.3		Supriya			  11/04/2022      US ES20-12426
*/
@isTest
public class EDGE_UserBusinessRoleTriggerHelperTest{
    
    @isTest
    public static void testUserBusinessRoleUpdate(){             
        
        //create System Admin User
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        
        User testSalesManagerUser = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            insert testSalesManagerUser;
        
        //run as MDM user and update Sales Rep user
        System.runAs(testadminUser) {
           
            //Create Sales Rep
            User salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');  
            salesRepUser.ManagerId = testadminUser.id;
            salesRepUser.Available_Countries__c = 'AU; ES';
            salesRepUser.Default_Country__c = 'AU';
            insert salesRepUser;
            
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.Country__c = EDGE_UtilityTestClass.setupCountry('AU');
             brtest.Global_Equivalent__c = 'Dispense Manager';
            insert brtest;
            
            Business_Role__c brtest2 = EDGE_UtilityTestClass.getBusinessRole();
            brtest2.Country__c = EDGE_UtilityTestClass.setupCountrySpain('ES');
             brtest2.Global_Equivalent__c = 'Dispense Manager';
            insert brtest2;
             EDGE_UtilityTestClass.createOrgSettings();
            //Insert User Business Role
            User_Business_Role__c ubrtest = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
            insert ubrtest;
            ubrtest.Business_Role__c = brtest2.Id;
            update ubrtest;
            delete ubrtest;
            undelete ubrtest;
            User dummyuser = [Select Id, Business_Role__c from User where Id =:salesRepUser.Id];
            
            System.assertEquals(dummyuser.Business_Role__c, 'Test Role','Test Role should match');  
        }
    }
    
    @isTest
    public static void testcheckBusinessRoleInsert(){             
        
        //create System Admin User
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        
        System.runAs(testadminUser) {
            EDGE_UtilityTestClass.createOrgSettings();
            
            //Create Sales Rep
            User salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative'); 
            salesRepUser.ManagerId = testadminUser.id;
            insert salesRepUser;
            
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;	New_Product_Distribution__c;OPPS OPEN;OPPS CLOSED';
            brtest.Country__c = EDGE_UtilityTestClass.setupCountry('IND');
             brtest.Global_Equivalent__c = 'Dispense Manager';
            insert brtest;
            delete brtest;
            undelete brtest;
            
            //Insert User Business Role
            try{
                User_Business_Role__c ubrtest = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
                insert ubrtest;
            }catch(Exception ex){
                System.assertNotEquals(ex.getMessage(), Label.BusinessRoleCountry,'Label.BusinessRoleCountry should match');
            }
        }
    }    
    
   
	@isTest
    public static void testcheckBusinessRoleUpdate(){
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        System.runAs(testadminUser) {
            User salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative'); 
            salesRepUser.ManagerId = testadminUser.id;
            salesRepUser.Available_Countries__c = 'GB';
            insert salesRepUser;
            system.assert(salesRepUser.Id != null,'salesRepUser should not be null');
            
            User salesRepUser2 = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative'); 
            salesRepUser2.ManagerId = testadminUser.id;
            salesRepUser2.Available_Countries__c = 'GB';
            insert salesRepUser2;
            
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;	New_Product_Distribution__c;OPPS OPEN;OPPS CLOSED';
            brtest.Country__c = EDGE_UtilityTestClass.setupCountry('GB');
             brtest.Global_Equivalent__c = 'Dispense Manager';
            insert brtest;
            delete brtest;
            undelete brtest;
            
            Business_Role__c brtest2 = EDGE_UtilityTestClass.getBusinessRole();
            brtest2.Country__c = EDGE_UtilityTestClass.setupCountrySpain('AU');
            insert brtest2;
            
            EDGE_UtilityTestClass.createOrgSettings();
            try{
                User_Business_Role__c ubrtest2 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
                insert ubrtest2;
                ubrtest2.User__c = salesRepUser2.Id;
                ubrtest2.Business_Role__c =brtest2.id;
                update ubrtest2;
                ubrtest2.User__c = salesRepUser.Id;
                ubrtest2.Business_Role__c =brtest.id;
                update ubrtest2;
                
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
                //System.assertNotEquals(ex.getMessage(), Label.BusinessRoleCountry);
            }
        }
        
    }
     @isTest
    public static void testcheckBusinessRoleInsert2(){             
        
        //create System Admin User
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
         test.startTest();
        System.runAs(testadminUser) {
            EDGE_UtilityTestClass.createOrgSettings();
            
            //Create Sales Rep
            User salesRepUser = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative'); 
            salesRepUser.ManagerId = testadminUser.id;
            salesRepUser.Available_Countries__c = 'AU; ES';
            salesRepUser.Assigned_Clusters__c = 'AUSC';
            salesRepUser.Assigned_Hubs__c = 'AUSH';
             salesRepUser.Default_Country__c = 'AU';
            salesRepUser.Assigned_Markets__c = 'APAC';
            insert salesRepUser;
            
            User salesRepUser2 = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative'); 
            salesRepUser2.ManagerId = testadminUser.id;
            salesRepUser2.Available_Countries__c = 'AU; ES';
             salesRepUser2.Default_Country__c = 'AU';
            salesRepUser2.Assigned_Clusters__c = 'AUSC';
            salesRepUser2.Assigned_Hubs__c = 'AUSH';
             salesRepUser2.Assigned_Markets__c = 'APAC';
            insert salesRepUser2;
            
            //insert Business Role
            Business_Role__c brtest = EDGE_UtilityTestClass.getBusinessRole();
            brtest.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;	New_Product_Distribution__c;OPPS OPEN;OPPS CLOSED';
            brtest.Country__c = EDGE_UtilityTestClass.setupCountry('AU');
            brtest.Global_Equivalent__c = 'Dispense Manager';
            insert brtest;
            test.stopTest();
            delete brtest;
            undelete brtest;
            try{
                User_Business_Role__c ubrtest1 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
                insert ubrtest1;
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
                //System.assertNotEquals(ex.getMessage(), Label.BusinessRoleCountry);
            }
            //Insert User Business Role
            try{
                User_Business_Role__c ubrtest = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
                insert ubrtest;
                //system.debug('get queries'+getQueries());
            }catch(Exception ex){
                System.assertNotEquals(ex.getMessage(), Label.BusinessRoleCountry,'ex.getMessage() should match');
            }
            
            try{
                User_Business_Role__c ubrtest2 = EDGE_UtilityTestClass.getuserBusinessRole(salesRepUser, brtest);
                insert ubrtest2;
                ubrtest2.User__c = salesRepUser.Id;
                update ubrtest2;
                
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
                //System.assertNotEquals(ex.getMessage(), Label.BusinessRoleCountry);
            }
        }
    }
    
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
            System.assert(ownerAccount != null,'ownerAccount should not be null');
            
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
        system.assert(testAdminUser.Id != null,'testAdminUser should not be null');

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
            outletAccount.Country__c= geographyId;
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
           // List<UserTerritory2Association> utaList = [SELECT Id,UserId,Territory2Id FROM UserTerritory2Association WHERE UserId =: runSalesRepUser.id];          
            
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
    
   
}