/*
* @Name: EventsLog_UtilityTest
* @Discription: This is the test class for EventsLog_Utility 
* @History                                                            
                                                            
* @VERSION          AUTHOR               DATE              DETAIL
*  1.0        Abhishek Shudhalwar     07/11/2022      Initial Development
*  
*/
@isTest
public class EventsLog_UtilityTest {

    @isTest
    public static void createLogTest(){
        
        Test.startTest();
        EventsLog_Utility.createLog(EventsLog_Utility.LOG_STATUS_SUCCESS, 'className',  'methodName',  EventsLog_Utility.LOG_TYPE_APEX,  'errorMessage',  'errorType', 
                                  'request',  'response',  'stackTrace',  'typeOfObject',  'interfaceName');
        Test.stopTest();
        
        //List<EventBusSubscriber> eventBus = [SELECT id FROM EventBusSubscriber WHERE Topic='Error_Log_Event__e'];
        //system.assertEquals(1, eventBus.size(),  'Event creation failed');
        //List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        //system.assertEquals(1, logs.size(), 'Custom Logs creation failed');
    }

    @isTest
    public static void createLogsTest(){
        
        list<Error_Log_Event__e> listLogs = new list<Error_Log_Event__e>();
        for(integer i =0 ;i<2;i++){
        	Error_Log_Event__e log = new Error_Log_Event__e();
            log.Status__c = EventsLog_Utility.LOG_STATUS_SUCCESS;
            log.Class_Name__c  = 'className';
            log.Method_Name__c = 'methodName';
            log.Log_Type__c = EventsLog_Utility.LOG_TYPE_APEX;
            log.Error_Message__c = 'errorMessage';
            log.Error_Type__c  = 'errorType'; 
            log.Request__c   = 'request';
            log.Response__c  = 'response';
            log.Stack_Trace__c  = 'stackTrace'; 
            log.Type_of_Object__c = 'typeOfObject';
            log.Interface_Name__c = 'interfaceName';
            listLogs.add(log);
        }
        Test.startTest();
        EventsLog_Utility.createLog(listLogs);
        Test.stopTest();
        
        //List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        //system.assertEquals(2, logs.size(), 'Custom Logs creation failed');
    }
    
    @isTest
    public static void createIntegrationLogTest(){
        
        Test.startTest();
        EventsLog_Utility.createIntegrationLog('Fail', 'className', 'methodName', 'errorMessage', 0, 'errorType', 'request',   'response', 'stackTrace',  'typeOfObject',  'interfaceName');
        Test.stopTest();
        
        //List<EventBusSubscriber> eventBus = [SELECT id FROM EventBusSubscriber WHERE Topic='Error_Log_Event__e'];
        //system.assertEquals(1, eventBus.size(), 'Event creation failed');
        //List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        //system.assertEquals(1, logs.size(), 'Custom Logs creation failed');
    }
    
    @isTest
    public static void createBatchLogTest(){

        
        Test.startTest();
        EventsLog_Utility.createBatchLog('className', 'methodName', 'errorMessage',  0,  'errorType', 'stackTrace',  'typeOfObject');
        Test.stopTest();
            
        //List<EventBusSubscriber> eventBus = [SELECT id FROM EventBusSubscriber WHERE Topic='Error_Log_Event__e'];
        //system.assertEquals(1, eventBus.size(), 'Event creation failed');
        //List<Custom_Log__c> logs = [Select id from Custom_Log__c];
        //system.assertEquals(1, logs.size(), 'Custom Logs creation failed');
    }
    
}