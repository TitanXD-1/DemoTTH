/**********************************************************************
Name: ScheduleJobAPACTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Dipanjan Das     25/03/2019      Test Class for ScheduleJobAPAC

***********************************************************************/
@isTest
public class ScheduleJobAPACTest{
    
    @isTest
    public static void testScheduleJob() {
        Test.StartTest();   
        Batch_Job_Current_Region__c batchjob = EDGE_UtilityTestClass.getBatchJobCurrentRegion();
        insert batchjob;
        EDGE_UtilityTestClass.setupCountry('AU');
        ScheduleJobAPAC sh1 = new ScheduleJobAPAC();
        String sch = '0 0 23 * * ?';
        system.schedule('TestScheduleJobAPAC', sch, sh1);
        
        system.assertEquals(batchjob.Name, 'Current Region');
        Test.StopTest();
    }   
    
}