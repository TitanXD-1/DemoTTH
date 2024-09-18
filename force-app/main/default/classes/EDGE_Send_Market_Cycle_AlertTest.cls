/**

* @description   EDGE_Send_Market_Cycle_AlertTest

* @purpose  This is the test class for EDGE_Send_Market_Cycle_Alert

* @history :

*/

@isTest
public class EDGE_Send_Market_Cycle_AlertTest {
    /** 
* @description  Create Market Cycle
**/
    @isTest
    public static void marketcycletest1(){
        Test.startTest();  
        createData1();
        EDGE_Send_Market_Cycle_Alert batch = new EDGE_Send_Market_Cycle_Alert();
        Database.executeBatch(batch, 1);
        System.assert(batch!=null,'Batch should not be null');
        Test.stopTest();        
    }
        /** 
* @description  Create Market Cycle
**/
    @isTest
    public static void marketcycletest2(){
        Test.startTest();  
        createData2();
        EDGE_Send_Market_Cycle_Alert batch = new EDGE_Send_Market_Cycle_Alert();
        Database.executeBatch(batch, 1);
        System.assert(batch!=null,'Batch should not be null');
        Test.stopTest();        
    }
    
    static void createData1(){
        List<User> users = new List<User>();
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('BE');
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'BE';
        adminUser1.Available_Countries__c = 'BE';
        users.add(adminUser1);
        Market_Cycle__c marCycle1 = new Market_Cycle__c();
        marCycle1.Name = 'BE 1';
        marCycle1.Geography__c = countryId;
        marCycle1.Start_Date__c = Date.today()-90;
        marCycle1.End_Date__c = Date.today().adddays(1);
        insert marCycle1;
        system.assert(marCycle1.Id != null,'marCycle1 should not be null');
        
        Market_Cycle__c marCycle2 = new Market_Cycle__c();
        marCycle1.Name = 'BE 2';
        marCycle2.Geography__c = countryId;
        marCycle2.Start_Date__c = Date.today().adddays(2);
        marCycle2.End_Date__c = Date.today().adddays(30);
        insert marCycle2;
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'BE_MDM', Type = 'Queue');
            insert grp;        
            //insert mappingObject;
        }
        }
        /** 
* @description  Create Data
**/
    static void createData2(){
        List<User> users = new List<User>();
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        users.add(adminUser1);
        Market_Cycle__c marCycle1 = new Market_Cycle__c();
        marCycle1.Name = 'AU 1';
        marCycle1.Geography__c = countryId;
        marCycle1.Start_Date__c = Date.today()-90;
        marCycle1.End_Date__c = Date.today().adddays(1);
        insert marCycle1;
        
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'BE_MDM', Type = 'Queue');
            insert grp;        
            //insert mappingObject;
        }
        }

}