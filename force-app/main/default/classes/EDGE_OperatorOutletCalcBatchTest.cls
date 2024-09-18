/*
* @description: EDGE_OperatorOutletCalcBatchTest

* @purpose: Test class to cover EDGE_OperatorOutletCalcBatch class.   

* @history:                                                            

* @VERSION    AUTHOR               DATE           DETAIL
 * V1.0       Sandip Ghosh         15/10/2020     [ES20-8498]
 * V2.0       Anand Uppalapati     08/03/2022     [ES20-12266]
 * V3.0       Sakshi Shah          22/08/2024     PMD Fix
*/
@isTest
public class EDGE_OperatorOutletCalcBatchTest {
    
    @isTest
    public static void testOperatorOutletCalcBatch(){
        //create Admin User
        User testSysAdminUser = EDGE_UtilityTestClass.runAsUser('SystemAdmin','System Administrator');
        testSysAdminUser.Available_Countries__c = 'AU';
        insert testSysAdminUser;
        System.assert(testSysAdminUser.id !=null,'Test System Admin User Id should not be null.');
        
        System.runAs(testSysAdminUser){
            
            createData();
            Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                      from Market_Batch_Setting__mdt 
                                                      where Batch_Class__c = 'EDGE_OperatorOutletCalcBatch'
                                                      and Country_Code__c ='CO'];
            system.assert(batchSetting.Id != null,'Batch Setting Id should not be null.');
            String className = batchSetting.Batch_Class__c;         
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c)); 
        }
    }
    @isTest
    public static void createData(){
        List<Account> accountListNew = new List<Account>();
        EDGE_UtilityTestClass.createOrgSettings();
         // added setupCountryCO by Anamika
        Id countryId = EDGE_UtilityTestClass.setupCountryCO('CO');
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[CO]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;
        
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Outlet_Execution_Score__c = 'Binary';
        marketSettings.Minimum_Activation_Standards__c = 'Binary';
        marketSettings.Minimum_Product_Assortment__c = 'Binary';
        marketSettings.Share_Of_Space__c = 'Binary';
        marketSettings.Distribution__c = 'Progressive';
        marketSettings.New_Product_Distribution__c = 'Binary';
        marketSettings.Threshold_Format__c = 'Percent';
        marketSettings.A_P_Threshold__c = 90;
        insert marketSettings;
        
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Person_Responsible__c = UserInfo.getUserId();
        operator.IsOperator__c = true;
        
        Test.startTest();
        insert operator;
        
        for(Integer count = 1; count <= 3; count++){ 
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.Independent_of_Operator__c = false;
            testoutlet.Operator__c = operator.Id;
            testoutlet.Name = 'Outlet-00' + count;
            testoutlet.MobilePrefix__c ='+61';
            testoutlet.Mobile__c = '512 123 123';
            testoutlet.PhonePrefix__c = '+61';
            testoutlet.Phone__c = '1 2222 3333';
            testoutlet.Distribution_Numerator__c = 25;
            testoutlet.Distribution_Denominator__c = 30;
            accountListNew.add(testoutlet);
        }
        
        Database.insert(accountListNew); 
         Test.stopTest();
    }
}