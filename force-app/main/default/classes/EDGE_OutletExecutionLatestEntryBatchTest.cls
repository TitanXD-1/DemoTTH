/**
Class Name: EDGE_OutletExecutionLatestEntryBatchTest 

Author              Version       Date           Detail
Dinesh Sharma        V1.0        16/02/2021     [ES20-9278]
Joshraj Sen          V2.0        09/11/2022     [ES20-13508]
Joshraj Sen          V3.0        06/12/2022     [ES20-13625]
*/

@isTest
public class EDGE_OutletExecutionLatestEntryBatchTest {
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id defaulttypeRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();
    public static String productRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product').getRecordTypeId();
    public static String outletExecutionMASRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation').getRecordTypeId();
    
    
    @isTest
    public static void markLatestOutletExecution(){
        
        createData();
        
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletExecutionMarkLatestEntryBatch' AND Country_Code__c ='AU'];
        String className = batchSetting.Batch_Class__c;
        system.assertNotEquals(batchSetting,null,'BatchSetting is Null');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    
    public static void createData(){
        
        list<Outlet_Execution__c> oeList = new List<Outlet_Execution__c>();
        // create Geography record  
        Id countryID = EDGE_UtilityTestClass.setupCountry('AU'); 
        EDGE_UtilityTestClass.createOrgSettings();   
        
        Geography__c country = [SELECT Id, Code__c FROM Geography__c WHERE ID =:countryID LIMIT 1];
        
        //insert pickup option
        Pick_Up_Options__c pickUpVisit1 = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        pickUpVisit1.Name = 'Gold[AU]';
        insert pickUpVisit1;
        System.debug(LoggingLevel.DEBUG,'limita '+limits.getQueries());
        Pick_Up_Options__c pickUpVisit = new Pick_Up_Options__c();
        pickUpVisit.Name = 'Activation[AU]';
        pickUpVisit.Geography__c = country.Id;  
        pickUpVisit.RecordTypeId = defaulttypeRecTypeId;
        pickUpVisit.Type__c = 'MAS';
        pickUpVisit.Status__c ='Active'; 
        insert pickUpVisit;
        
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Country__c = country.Id;
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =pickUpVisit1.Id;
        outletAccount.Latest_Date_Of_Execution_Product__c=Date.today().addDays(10);
        outletAccount.Latest_Date_Of_Execution_Activation__c=Date.today().addDays(10);
        outletAccount.Updated_Activation_Date_of_Execution__c=Date.today().addDays(10);
        outletAccount.Updated_Activation_Date_of_Execution__c=Date.today().addDays(10);
        insert outletAccount;
        Test.startTest();
        //create Product             
        Product__c testProd = EDGE_UtilityTestClass.getProd();
        testProd.Description__c='Johnny Walker';
        testProd.Type__c = 'Diageo Product';
        insert testProd;
        Outlet_Execution__c testOe = new Outlet_Execution__c();
        testOe.Product__c = testProd.id;
        testOe.Outlet__c = outletAccount.id;
        testOe.Date_of_Execution__c=Date.today().addDays(10);//Date.newInstance(2021, 02,15);
        testOe.RecordTypeId = productRecordTypeId;
        testOe.Latest_Entry__c=true;
        oeList.add(testOe);
        System.debug(LoggingLevel.DEBUG,'limitd '+limits.getQueries());
        Outlet_Execution__c testOe1 = new Outlet_Execution__c();
        testOe1.Product__c = testProd.id;
        testOe1.Outlet__c = outletAccount.id;
        testOe1.Date_of_Execution__c=Date.today();//Date.newInstance(2021, 02,16);
        testOe1.RecordTypeId = productRecordTypeId;
        testOe1.Latest_Entry__c=true;
        oeList.add(testOe1);
        Outlet_Execution__c testOe2 = new Outlet_Execution__c();
        testOe2.Activation_Reference__c = pickUpVisit.Name.substringBefore('[');
        testOe2.Outlet__c = outletAccount.id;
        testOe2.Date_of_Execution__c=Date.today().addDays(10);//Date.newInstance(2021, 02,15);
        testOe2.RecordTypeId = outletExecutionMASRecordTypeId;
        oeList.add(testOe2);
        Outlet_Execution__c testOe3 = new Outlet_Execution__c();
        testOe3.Activation_Reference__c = pickUpVisit.Name.substringBefore('[');
        testOe3.Outlet__c = outletAccount.id;
        testOe3.Date_of_Execution__c=Date.today();//Date.newInstance(2021, 02,16);
        testOe3.RecordTypeId = outletExecutionMASRecordTypeId;
        oeList.add(testOe3);             
        insert oeList;
        Test.stopTest(); 
        
    }
    
}