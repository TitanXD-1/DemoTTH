/**********************************************************************
Name: EDGE_DynamicTragetListRemovalBatchTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Dipanjan Das     28/02/2019      Test Class for EDGE_DynamicTragetListRemovalBatch apex class.

***********************************************************************/
@isTest
public class EDGE_DynamicTargetListRemovalBatchTest{
    
    @isTest
    public static void dynamicTragetListRemovalBatch(){
        Test.startTest(); 
        createData();  
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_DynamicTargetListRemovalBatch'
                                                  AND Country_Code__c = 'AU' LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null);
        
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //Database.executeBatch(new EDGE_DynamicTargetListRemovalBatch(), 1);
        
        Test.stopTest();
        
        Target_List__c targetLst = [SELECT Id FROM Target_List__c LIMIT 1];
        List<Target_List_Member__c> targetLstmemList = [SELECT Id FROM Target_List_Member__c WHERE Target_List__c = :targetLst.Id];
        
        system.assertEquals(targetLstmemList.size(),1);
    }
    
    public static void createData(){
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        Target_List__c targetLst =  EDGE_UtilityTestClass.getTargetList(geographyID);
        targetLst.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        targetLst.Dynamic_Query__c = 'SELECT ID, Name, Status__c, Ref__c, Country__c, Country__r.Name FROM Account Order by Name limit 1';
        insert targetLst;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        Batch_Job_Current_Region__c objBatch = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        insert objBatch;
        
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetLst.Id);
        targetLstmem.Assignment_Status__c = 'Active';
        targetLstmem.Batch_Run_Date__c = system.now().addDays(-1);
        insert targetLstmem;
    }
}