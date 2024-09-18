/**

* @description :  EDGE_TerritoryMemberTriggerHelperTest

* @purpose : This is the test class for EDGE_TerritoryMemberTriggerHelper

* @history :

* Version   Developer         Date         User Story	        Purpose

*  1.1     Monalisa Halder  22/02/2019   Initial Development   Initial Development
*  1.2	   Supriya Galinde	10/03/2022	 ES20-12212			 Validations for Activation Territory record type in Territory_SFDC_Activation Specialist Enhancements

*/

@isTest
public class EDGE_TerritoryMemberTriggerHelperTest{
    
        final static String SalesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    final static String ActivationTerritoryRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();

    
    @isTest
    public static void testcheckTerritoryMemberCountryInsert(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        EDGE_UtilityTestClass.createOrgSettings();
        
        //create System Admin User
        System.runAs(testadminUser) {
            
            //create Sales Representative User
            User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
            usr.Business_Role__c = 'Sales Manager';
            usr.ManagerId = testadminUser.Id;
            insert usr;  
            
            //create Sales Representative User ES
            User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
            usr1.Business_Role__c = 'Sales Manager';
            usr1.Available_Countries__c = 'ES';
            insert usr1;  
            
            usr = [Select Id,Available_Countries__c from User where Id = :usr.Id];
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHierRegion.Parent_BU__c = terriHierSA.Id;
            insert terriHierRegion;
            
            // create Territory 
            Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
            territory.Country__c = countryId;
            territory.Sales_Area__c = terriHierSA.Id;
        	territory.Region__c = terriHierRegion.Id;
            territory.RecordTypeId = SalesRecordTypeId;
            territory.Territory_Type__c = 'Sales';
            insert territory;
            territory.Status__c = 'Active';
            update territory;
            
            
            territory = [SELECT Id,Country__c,Status__c,Country__r.Code__c FROM Territory__c  WHERE Id = :territory.Id];
            
            
            //create Business Role
            
            Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
            businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c; Minimum_Product_Assortment__c; 	WPA__c; Minimum_Activation_Standards__c; Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED';
            businessRoleObj.Country__c = countryId;
            insert businessRoleObj;
            
            //create User Business Role
			User_Business_Role__c userBusinessObj = EDGE_UtilityTestClass.getuserBusinessRole( usr ,businessRoleObj);
            insert userBusinessObj;
            
            test.startTest();
            // create Territory Member
            Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember.User__c = usr.Id;
            terrMember.Territory__c = territory.Id;
            insert terrMember;  
            terrMember.End_Date__c = system.today().AddDays(20);
            //terrMember.Type__c = 'Primary';
            update terrMember;
            
            terrMember = [SELECT Id,User__c,Type__c,User__r.Available_Countries__c,Territory__c,Territory__r.Country__r.Code__c FROM Territory_Member__c  WHERE Id = :terrMember.Id];
            
            system.assertEquals( terrMember.territory__r.Country__r.Code__c,usr.Available_Countries__c);
            
            delete terrMember;
            test.stopTest();
            
            
            
        }
        
    }
    
    @isTest
    public static void testcheckTerritoryMemberValidation(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        EDGE_UtilityTestClass.createOrgSettings();
        
        //create System Admin User
        System.runAs(testadminUser) {
            
            //create Sales Representative User
            User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
            usr.Business_Role__c = 'Sales Manager';
            usr.ManagerId = testadminUser.Id;
            insert usr; 
            
            User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep1', 'Sales Representative');
            usr1.Business_Role__c = 'Sales Manager';
            usr1.ManagerId = testadminUser.Id;
            insert usr1;
            
            
            usr = [Select Id,Available_Countries__c from User where Id = :usr.Id];
            usr1 = [Select Id,Available_Countries__c from User where Id = :usr1.Id];
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHierRegion.Parent_BU__c = terriHierSA.Id;
            insert terriHierRegion;
            
            // create Territory 
            Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
            territory.Country__c = countryId;
            territory.Sales_Area__c = terriHierSA.Id;
        	territory.Region__c = terriHierRegion.Id;
            territory.RecordTypeId = SalesRecordTypeId;
            territory.Territory_Type__c = 'Sales';
            insert territory;
            territory.Status__c = 'Active';
            update territory;
            
            Territory__c territory1 =  EDGE_UtilityTestClass.getTerritoryRec();
            territory1.Country__c = countryId;
            territory1.Sales_Area__c = terriHierSA.Id;
        	territory1.Region__c = terriHierRegion.Id;
            territory1.Territory_Type__c = 'Sales';
            territory1.RecordTypeId = SalesRecordTypeId;
            insert territory1;
            territory1.Status__c = 'Active';
            update territory1;
            
           
            
            territory = [SELECT Id,Country__c,Status__c,Country__r.Code__c FROM Territory__c  WHERE Id = :territory.Id];
            territory1 = [SELECT Id,Country__c,Status__c,Country__r.Code__c FROM Territory__c  WHERE Id = :territory1.Id];
             // create Territory Member
            Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember.User__c = usr.Id;
            terrMember.Territory__c = territory.Id;
            terrMember.Type__c = 'Primary';
            insert terrMember;  
            terrMember.End_Date__c = system.today().AddDays(20);
            update terrMember;
            
            
            terrMember = [SELECT Id,User__c,Type__c,User__r.Available_Countries__c,Territory__c,Territory__r.Country__r.Code__c FROM Territory_Member__c  WHERE Id = :terrMember.Id];
            
            system.assertEquals( terrMember.territory__r.Country__r.Code__c,usr.Available_Countries__c);
            
            Territory_Member__c  terrMember2 = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember2.User__c = usr.Id;
            terrMember2.Territory__c = territory.Id;
            terrMember2.Start_Date__c = system.today().AddDays(5);
            terrMember2.End_Date__c = system.today().AddDays(10);
            terrMember2.Type__c = 'Secondary' ;
            
            try {
                insert terrMember2; 
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.DuplicateUserInSameTerritory) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            } 
            
            
            Territory_Member__c  terrMember1 = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember1.User__c = usr1.Id;
            terrMember1.Territory__c = territory.Id;
            terrMember1.Start_Date__c = system.today().AddDays(5);
            terrMember1.End_Date__c = system.today().AddDays(10);
            terrMember1.Type__c = 'Primary' ;
            
            try {
                insert terrMember1; 
                
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.DuplicatePrimaryMember) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            } 
            
            
            Territory_Member__c  terrMember4 = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember4.User__c = usr.Id;
            terrMember4.Territory__c = territory1.Id;
            terrMember4.Start_Date__c = system.today().AddDays(5);
            terrMember4.End_Date__c = system.today().AddDays(10);
            terrMember4.Type__c = 'Primary' ;
            
            try {
                insert terrMember4; 
                
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.SameUserDuplicatePrimaryMember) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            } 
          
            
        }
        
    }
    @isTest
    public static void testCheckActivationTerrMemValidation(){
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        EDGE_UtilityTestClass.createOrgSettings();
        
        //create System Admin User
        System.runAs(testadminUser) {
            
            //create Activation Territory User
            
            User usr2 = EDGE_UtilityTestClass.runAsUser('TestActivationUser', 'Activation Specialist');
            usr2.Business_Role__c = 'On Trade Activation Specialist GB';
            usr2.Available_Countries__c='GB';
            usr2.ManagerId = testadminUser.Id;
            insert usr2;
            
			User usr1 = EDGE_UtilityTestClass.runAsUser('TestActivationUser', 'Activation Specialist');
            usr1.Business_Role__c = 'On Trade Activation Specialist GB';
            usr1.Available_Countries__c='GB';
            usr1.ManagerId = testadminUser.Id;
            insert usr1;
            
            User usr3 = EDGE_UtilityTestClass.runAsUser('TestActivationUser3', 'Activation Specialist');
            usr3.Business_Role__c = 'On Trade Activation Specialist GB';
            usr3.Available_Countries__c='GB';
            usr3.ManagerId = testadminUser.Id;
            insert usr3;
            
            usr2 = [Select Id,Available_Countries__c from User where Id = :usr2.Id];
            usr1 = [Select Id,Available_Countries__c from User where Id = :usr1.Id];
            
            // create Territory 
            Territory__c territory1 =  EDGE_UtilityTestClass.getTerritoryRec();
            territory1.Country__c = countryId;
            territory1.Territory_Type__c = 'Activation Territory';
            territory1.RecordTypeId = ActivationTerritoryRecordTypeId;
            insert territory1;
            
            Territory__c territory2 =  EDGE_UtilityTestClass.getTerritoryRec();
            territory2.Country__c = countryId;
            territory2.Territory_Type__c = 'Activation Territory';
            territory2.RecordTypeId = ActivationTerritoryRecordTypeId;
            insert territory2;
            
            // create activation Territory Member
            Territory_Member__c  actTerrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
            actTerrMember.User__c = usr2.Id;
            actTerrMember.Territory__c = territory2.Id;
            actTerrMember.Type__c = 'Primary';
            insert actTerrMember;  
            actTerrMember.End_Date__c = system.today().AddDays(20);
            update actTerrMember;
            
            actTerrMember = [SELECT Id,User__c,Type__c,User__r.Available_Countries__c,Territory__c,Territory__r.Country__r.Code__c FROM Territory_Member__c  WHERE Id = :actTerrMember.Id];
            
            system.assertEquals( actTerrMember.territory__r.Country__r.Code__c,usr2.Available_Countries__c);
            
            Territory_Member__c  actTerrMember1 = EDGE_UtilityTestClass.getTerrMemberRec();  
            actTerrMember1.User__c = usr2.Id;
            actTerrMember1.Territory__c = territory1.Id;
            actTerrMember1.Start_Date__c = system.today().AddDays(5);
            actTerrMember1.End_Date__c = system.today().AddDays(10);
            actTerrMember1.Type__c = 'Primary' ;

             Territory_Member__c  actTerrMember2 = EDGE_UtilityTestClass.getTerrMemberRec();  
            actTerrMember2.User__c = usr2.Id;
            actTerrMember2.Territory__c = territory2.Id;
            actTerrMember2.Start_Date__c = system.today().AddDays(5);
            actTerrMember2.End_Date__c = system.today().AddDays(10);
            actTerrMember2.Type__c = 'Primary' ;
            
            Territory_Member__c  actTerrMember3 = EDGE_UtilityTestClass.getTerrMemberRec();  
            actTerrMember3.User__c = usr1.Id;
            actTerrMember3.Territory__c = territory1.Id;
            actTerrMember3.Start_Date__c = system.today().AddDays(5);
            actTerrMember3.End_Date__c = system.today().AddDays(10);
            actTerrMember3.Type__c = 'Primary' ;
            
            try {
                insert actTerrMember2; 
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.DuplicateUserInSameTerritory) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
            
            try {
                insert actTerrMember1; 
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.SameUserDuplicatePrimaryMember) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
            
            try {
                insert actTerrMember3; 
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.DuplicatePrimaryMember) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            }
            
    }
    }
    @isTest
    public static void testcheckBulkInsertTerritoryMemberValidation(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        EDGE_UtilityTestClass.createOrgSettings();
        
        //create System Admin User
        System.runAs(testadminUser) {
            
            //create Sales Representative User
            User usr = EDGE_UtilityTestClass.runAsUser('TestSalesRep', 'Sales Representative');
            usr.Business_Role__c = 'Sales Manager';
            usr.ManagerId = testadminUser.Id;
            insert usr; 
            
            User usr1 = EDGE_UtilityTestClass.runAsUser('TestSalesRep1', 'Sales Representative');
            usr1.Business_Role__c = 'Sales Manager';
            usr1.ManagerId = testadminUser.Id;
            insert usr1;
            
            usr = [Select Id,Available_Countries__c from User where Id = :usr.Id];
            usr1 = [Select Id,Available_Countries__c from User where Id = :usr1.Id];
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHierRegion.Parent_BU__c = terriHierSA.Id;
            insert terriHierRegion;
            
            // create Territory 
            Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
            territory.Country__c = countryId;
            territory.Sales_Area__c = terriHierSA.Id;
        	territory.Region__c = terriHierRegion.Id;
            territory.RecordTypeId = SalesRecordTypeId;
            territory.Territory_Type__c = 'Sales';
            insert territory;
            territory.Status__c = 'Active';
            update territory;
            
            Territory__c territory1 =  EDGE_UtilityTestClass.getTerritoryRec();
            territory1.Country__c = countryId;
            territory1.Sales_Area__c = terriHierSA.Id;
        	territory1.Region__c = terriHierRegion.Id;
            territory1.Territory_Type__c = 'Sales';
            insert territory1;
            territory1.Status__c = 'Active';
            update territory1;
            
            territory = [SELECT Id,Country__c,Status__c,Country__r.Code__c FROM Territory__c  WHERE Id = :territory.Id];
            territory1 = [SELECT Id,Country__c,Status__c,Country__r.Code__c FROM Territory__c  WHERE Id = :territory1.Id];
            
            List<Territory_Member__c> tmList = new List<Territory_Member__c>();
            // create Territory Member
            Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember.User__c = usr.Id;
            terrMember.Territory__c = territory.Id;
            terrMember.Type__c = 'Primary';
			terrMember.End_Date__c = system.today().AddDays(20);
            tmList.add(terrMember);
              
            
            Territory_Member__c  terrMember4 = EDGE_UtilityTestClass.getTerrMemberRec();  
            terrMember4.User__c = usr.Id;
            terrMember4.Territory__c = territory1.Id;
            terrMember4.Start_Date__c = system.today().AddDays(5);
            terrMember4.End_Date__c = system.today().AddDays(10);
            terrMember4.Type__c = 'Primary' ;
            tmList.add(terrMember4);
            
            try {
				insert tmList;
                
            }
            catch(Exception ex) {
                Boolean expectedExceptionThrown =  ex.getMessage().contains(label.SameUserDuplicatePrimaryMember) ? true : false;
                System.assertEquals(expectedExceptionThrown, true);
            } 
          
            
        }
        
    }
    
    
}