/*
* @name D1_CustomLoggingCleanupBatchTest
* @description Test class for D1_CustomLoggingCleanupBatch Class
* @history
* VERSION     AUTHOR              DATE              DETAIL
* 1.0		  D1 DEV Team
* */ 
@isTest
public class D1_CustomLoggingCleanupBatchTest {
    
    @isTest
    public static void customLoggingCleanupBatchTest(){
        Date logClearDate = system.today().addMonths(Integer.valueOf(Label.D1_CustomLoggingCleanupIntervalMonths)*-1).addDays(-1);

        Custom_Log__c newLogMessage = new Custom_Log__c( 
            Class_Name__c = 'className', 
            Method_Name__c = 'methodName', 
            Error_Message__c = 'message', 
            Stack_Trace__c = 'stackTrace',
            Type__c = 'Type'
        );
        insert newLogMessage;

        Test.setCreatedDate(newLogMessage.Id, logClearDate.addDays(-1));  

        Test.startTest();
        D1_CustomLoggingCleanupBatch cleanup = new D1_CustomLoggingCleanupBatch();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, cleanup); 
        
        D1_CustomLoggingCleanupBatch logCloanup = new D1_CustomLoggingCleanupBatch();
        Database.executeBatch(logCloanup);
        Test.stopTest();

        List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        system.assertEquals(0, logs.size(), 'log size greater than zero');
    }
}