@isTest
public class PNR_DeleteStaffCustomerSchedularTest {
    
    static testmethod void testScheduledJob() {
        String cronExpr = '0 0 6 * * ?';
        // Create Test Data
        Test.startTest();
        // Schedule the test job
        String jobId = System.schedule('Delete Staff Customer',cronExpr,new PNR_DeleteStaffCustomerSchedular());
        // Key thing to Note: Stopping the test will run the job synchronously
        Test.stopTest();
        
    }
}