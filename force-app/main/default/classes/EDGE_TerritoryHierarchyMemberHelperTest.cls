/**

* @description :  EDGE_TerritoryHierarchyMemberHelperTest

* @purpose : This is the test class for EDGE_TerritoryHierarchyMemberHelper

* @history :

* Version   Developer         Date         User Story	        Purpose

*  1.1     Shahbaz Khan      26/07/2019   Initial Development   Initial Development
*  1.2	   Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/

@isTest
public class EDGE_TerritoryHierarchyMemberHelperTest {
    
    final static String QUALITYHIERARCHYRECORDTYPEID = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
    final static String ACTIVATIONHIERARCHYRECORDTYPEID = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();     
    final static String BUSINESSUNITHIERARCHYRECORDTYPEID= Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();     
    final static String REGIONHIERARCHYRECORDTYPEID = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();     
    final static String SALESAREAHIERARCHYRECORDTYPEID = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
    
    @isTest
    public static void checkOverlappingTerritoryHierarchyMemberTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        User testadminUser = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');    
        insert testadminUser;
        System.assert(testadminUser.id!=null,'userList should not be null');
        EDGE_UtilityTestClass.createOrgSettings();
        System.runAs(testadminUser){
            list<User> userList = new List<User>();
            User testSalesManagerUser = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager'); 
            userList.add(testSalesManagerUser);
            User testSalesManagerUser1 = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager'); 
            userList.add(testSalesManagerUser1);
            User testSalesManagerUser2 = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            userList.add(testSalesManagerUser2);
            User testSalesManagerUser3 = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            userList.add(testSalesManagerUser3);
            User testSalesManagerUser4 = EDGE_UtilityTestClass.runAsUser('SalesManager','Sales Manager');    
            userList.add(testSalesManagerUser4);
            insert userList;
            User testUser = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
            testUser.ManagerId = testSalesManagerUser.Id;
            
            insert testUser;
            //  EDGE_UtilityTestClass.createOrgSettings();
            
            //create Business Role
           
            Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
            businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c ;OPPS OPEN;OPPS CLOSED';
            businessRoleObj.Country__c = countryId;
            businessRoleObj.Global_Equivalent__c = 'Dispense Manager';
            insert businessRoleObj;

            //create User Business Role
            User_Business_Role__c userBusinessObj = new User_Business_Role__c();
            userBusinessObj.Business_Role__c = businessRoleObj.id;
            userBusinessObj.User__c = testSalesManagerUser.id;
            insert userBusinessObj;
            
            //create User Business Role
            User_Business_Role__c userBusinessObj1 = new User_Business_Role__c();
            userBusinessObj1.Business_Role__c = businessRoleObj.id;
            userBusinessObj1.User__c = testSalesManagerUser1.id;
            insert userBusinessObj1;
            test.startTest();
            
            Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
            
            insert terriHierBU;
            
            Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
            terriHierSA.Parent_BU__c = terriHierBU.Id;
            insert terriHierSA;
            
            list<Territory_Hierarchy__c> terrHierarchyList = new List<Territory_Hierarchy__c>();
            
            Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier.Parent_BU__c = terriHierSA.Id;
            terrHierarchyList.add(terriHier);
            // system.assert(terriHier.Id!= null);
            
            Territory_Hierarchy__c terriHier1 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier1.Parent_BU__c = terriHierSA.Id;
            terriHier1.RecordTypeId = QUALITYHIERARCHYRECORDTYPEID;  
            terriHier1.Territory_Hierarchy_Type__c = 'Dispense Manager';
            terrHierarchyList.add(terriHier1);
            // system.assert(terriHier1.Id!= null);
            
            Territory_Hierarchy__c terriHier2 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
            terriHier2.Parent_BU__c = terriHierSA.Id;
            terriHier2.RecordTypeId = QUALITYHIERARCHYRECORDTYPEID;  
            terriHier2.Territory_Hierarchy_Type__c = 'Dispense Manager';
            terrHierarchyList.add(terriHier2);
            //   system.assert(terriHier2.Id!= null); 
            insert terrHierarchyList;
            
            //list<Territory_Hierarchy_member__c> TerrHierList = new list<Territory_Hierarchy_member__c>();
            Territory_Hierarchy_member__c terrHierMem = new Territory_Hierarchy_member__c();
            terrHierMem.Territory_Hierarchy__c = terriHier.Id;
            terrHierMem.User__c= testSalesManagerUser.Id;
            terrHierMem.Start_Date__c = Date.today()+2;
            terrHierMem.End_Date__c = Date.today()+20;
            insert terrHierMem;
            
            Territory_Hierarchy_member__c terrHierMem2 = new Territory_Hierarchy_member__c();
            terrHierMem2.Territory_Hierarchy__c = terriHier.Id;
            terrHierMem2.User__c= testSalesManagerUser.Id;
            terrHierMem2.Start_Date__c = Date.today()+21;
            terrHierMem2.End_Date__c = Date.today()+25;
            
            
            Territory_Hierarchy_member__c terrHierMem3 = new Territory_Hierarchy_member__c();
            terrHierMem3.Territory_Hierarchy__c = terriHier1.Id;
            terrHierMem3.User__c= testSalesManagerUser1.Id;
            terrHierMem3.Start_Date__c = Date.today()+2;
            terrHierMem3.End_Date__c = Date.today()+20;
            //insert terrHierMem3;
            
            Territory_Hierarchy_member__c terrHierMem4 = new Territory_Hierarchy_member__c();
            terrHierMem4.Territory_Hierarchy__c = terriHier1.Id;
            terrHierMem4.User__c= testSalesManagerUser.Id;
            terrHierMem4.Start_Date__c = Date.today()+21;
            terrHierMem4.End_Date__c = Date.today()+25;
            
            
            Territory_Hierarchy_member__c terrHierMem5 = new Territory_Hierarchy_member__c();
            terrHierMem5.Territory_Hierarchy__c = terriHier2.Id;
            terrHierMem5.User__c= testSalesManagerUser2.Id;
            terrHierMem5.Start_Date__c = Date.today()+2;
            terrHierMem5.End_Date__c = Date.today()+20;
            insert terrHierMem5;
            
            Territory_Hierarchy_member__c terrHierMem6 = new Territory_Hierarchy_member__c();
            terrHierMem6.Territory_Hierarchy__c = terriHier2.Id;
            terrHierMem6.User__c= testSalesManagerUser3.Id;
            terrHierMem6.Start_Date__c = Date.today()+21;
            terrHierMem6.End_Date__c = Date.today()+25;
           
            try{
                // insert TerrHierList;
                insert terrHierMem2;
                insert terrHierMem4;
                insert terrHierMem6;
                
                terrHierMem2.Start_Date__c = Date.today()+15;
                terrHierMem4.Start_Date__c = Date.today()+15;
                terrHierMem6.Start_Date__c = Date.today()+15;
                update terrHierMem2;
                update terrHierMem4;
                update terrHierMem6;
              //  update terrHierMem6;
                
                
            }
            catch(Exception e){
                System.debug(LoggingLevel.Debug,'excption::::'+e.getMessage());
            }
            test.stopTest();
            // delete terrHierMem2;
            // undelete terrHierMem2;
          
        }
    }
}