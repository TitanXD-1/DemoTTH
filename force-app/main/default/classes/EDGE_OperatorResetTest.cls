/**
* @Description: EDGE_OperatorResetTest
* @Purpose : Test Class for EDGE_OperatorResetBatch
* @History:
* @VERSION   AUTHOR              DATE            STORY/DETAIL
* 1.0       Monalisa Halder     22/09/2020      ES20-8499,8602,8500Reseting Operator JSON fields
*/

@isTest
public class EDGE_OperatorResetTest {
    @testSetup
    public static void createTestData(){

        List<User> users = new List<User>();
        
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'CO';
        insert salesManager;
        System.assert(salesManager.Id!=null,'SalesManager should not be null');
        
        //Creating Sales Rep 1
        User salesRep1 = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.FirstName = 'SalesRep001';
        salesRep1.Available_Countries__c = 'CO';
        salesRep1.ManagerId = salesManager.Id;
        users.add(salesRep1);
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'CO';
        testAdminUser.FirstName = 'SalesAdmin001';
        //insert testAdminUser;
        users.add(testAdminUser);
        
        Database.insert(users);
        
        EDGE_UtilityTestClass.createOrgSettings();
         // added setupCountryCO by Anamika
       Id countryId;
       countryId= EDGE_UtilityTestClass.setupCountryCO('CO');
       
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Person_Responsible__c = salesRep1.Id;
        operator.IsOperator__c = true;
        insert operator;
        Test.startTest();
        
        EDGE_UtilityClass.printGovLimits(98);
        System.runAs(testAdminUser){
        	testOperatorReset();
            
        }
        
        EDGE_UtilityClass.printGovLimits(113);
        Test.stopTest();
    }
    
    @isTest
    public static void testOperatorReset(){
       
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OperatorResetBatch'
                                                  and Country_Code__c ='CO'];
        system.assert(batchSetting.Id != null,'batchSetting Id should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //Database.executeBatch((Database.Batchable<SObject>)job,10000);
        
    }
    
    
    

}