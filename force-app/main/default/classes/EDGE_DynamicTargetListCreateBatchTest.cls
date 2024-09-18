/**********************************************************************
Name: EDGE_DynamicTargetListCreateBatchTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Dipanjan Das     28/02/2019      Test Class for EDGE_DynamicTargetListCreateBatch apex class.
2.0         Joshraj Sen      08/04/2024      152305 SCA Fix

***********************************************************************/
@isTest
public class EDGE_DynamicTargetListCreateBatchTest{
    
    @isTest
    public static void testDynamicTargetListCreateBatch(){
        Test.startTest();  
        createData(); 
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_DynamicTargetListCreateBatch'
                                                  AND Country_Code__c = 'AU' LIMIT 1];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        //Database.executeBatch(new EDGE_DynamicTargetListCreateBatch(), 1);
        Test.stopTest();
        Target_List__c targetLst = [SELECT Id, Total_Number_of_Outlets__c FROM Target_List__c LIMIT 1];
        system.assertEquals(targetLst.Total_Number_of_Outlets__c, 1,'Match');
    }
    
    
    public static void createData(){        
        Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        Target_List__c targetLst =  EDGE_UtilityTestClass.getTargetList(geographyID);
        targetLst.recordTypeId = [SELECT Id FROM RecordType WHERE DeveloperName = 'Dynamic_Target_List' LIMIT 1].Id;
        targetLst.Dynamic_Query__c = 'SELECT ID, Name, Status__c, Ref__c, Country__c, Country__r.Name FROM Account Order by Name limit 1';
        //targetLst.Active__c = True;
        insert targetLst;
        
        system.debug(LoggingLevel.Debug,'targetLstId++ ' + targetLst);
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        Batch_Job_Current_Region__c objBatch = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        insert objBatch;
        
        Target_List_Member__c  targetLstmem = EDGE_UtilityTestClass.getTargetMemList(outlet.Id, targetLst.Id);
        targetLstmem.Assignment_Status__c = 'Active';
        insert targetLstmem;        
    }
}