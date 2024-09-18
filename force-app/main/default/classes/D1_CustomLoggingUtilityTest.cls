/**
 * @name : D1_CustomLoggingUtilityTest
 * @description : Test class for D1_CustomLoggingUtility
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0         D1 DEV Team      	
**/
@isTest
public class D1_CustomLoggingUtilityTest {
    /**
    * @name : logMessageTest
    * @description : This method is used to test the logMessage() method on positive scenario
    */
    @isTest
    public static void logMessageTest(){
        Test.startTest();
            D1_CustomLoggingUtility.logMessage('className', 'methodName', 'message', 'stackTrace', 'type', 'API_Request', 'API_Response');
        Test.stopTest();
        List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        system.assertEquals(1, logs.size(), 'log message failed');
    }

    /**
    * @name : logMessageExeptionTest
    * @description : This method is used to test the logMessage() method on negative scenario
    */
    @isTest
    public static void logMessageExeptionTest(){
        Test.startTest();
            D1_CustomLoggingUtility.logMessage('className', 'methodName', new TestException());
        Test.stopTest();
        List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        system.assertEquals(1, logs.size(), 'log message exception failed');
    }

    /**
    * @name : logMessageExeptionAPITest
    * @description : This method is used to test the logMessage() method on API call
    */
    @isTest
    public static void logMessageExeptionAPITest(){
        Test.startTest();
            D1_CustomLoggingUtility.logMessage('className', 'methodName', new TestException(), 'API_Request', 'API_Response');
        Test.stopTest();
        List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        system.assertEquals(1, logs.size(), 'log message exception failed');
    }
    
    /**
    * @name : logMessageExeptionAPIFutureTest
    * @description : This method is used to test the logMessage() method on future call
    */
    @isTest
    public static void logMessageExeptionAPIFutureTest(){
        Test.startTest();
            D1_CustomLoggingUtility.logMessageFuture('className', 'methodName', 'message', 'stackTrace', 'type', 'API_Request', 'API_Response');
        Test.stopTest();
        List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        system.assertEquals(1, logs.size(), 'log message exception failed');
    }

    public class TestException extends Exception{}
}