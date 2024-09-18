/**
* @Name: EventsLog_Utility
* @Discription: Create Custom Logs for exeptions 
* @History                                                            
                                                            
* @VERSION          AUTHOR               DATE              DETAIL
*  1.0        Abhishek Shudhalwar     07/11/2022      Initial Development
*  
**/


public with sharing class EventsLog_Utility {
    
    /**Constant Strings**/
	public static final String LOG_TYPE_TRIGGER = 'TRIGGER';
    public static final String LOG_TYPE_BATCH = 'BATCH';
    public static final String LOG_TYPE_INTEGRATION = 'INTEGRATION';
    public static final String LOG_TYPE_APEX = 'APEX';
    
    public static final String LOG_STATUS_INPROGRESS = 'IN PROGRESS';
    public static final String LOG_STATUS_FAIL = 'FAIL';
    public static final String LOG_STATUS_SUCCESS = 'SUCCESS';
    
    
    
    
	/**
	* Create and publish log event
	* @param  {Error_Log_Event__e} log : Event Log Record to be publish
    * @returns void
	**/    
    public static void createLog(Error_Log_Event__e log) {
        EventBus.publish(log);
     }
    
    /**
	* Create and publish log event
* @param  {list<Error_Log_Event__e>} listLogs : List of Event Log Records to be publish
    * @returns void
	**/   
    public static void createLog(list<Error_Log_Event__e> listLogs) {
		EventBus.publish(listLogs);
     }
    
    /**
	* Create and publish log event
	* @param  {String} status : Success or Fail (use Constant)
    * @param  {String} className : Class name where log is created
	* @param  {String} methodName : method name where log is created
	* @param  {String} logtype : Batch Interface Apex or trigger (use Constant)
	* @param  {String} errorMessage : System error
    * @param  {String} errorType : Exception name (DML,Null pointer etc)
    * @param  {String} request : Request sent (only for integration Log)
    * @param  {String} response : Response received (only for integration Log)
    * @param  {String} stackTrace : StackTrance of the error if available 
	* @param  {String} typeOfObject : Object Related to the error or Process
    * @param  {String} interfaceName : Interface name (only for integration Log)
    * @returns void
	**/   
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void createLog(String status, String className, String methodName, String logtype, String errorMessage, String errorType, String request, String response, 
                                 String stackTrace, String typeOfObject, String interfaceName) {

        Error_Log_Event__e log = new Error_Log_Event__e();
        log.Status__c = status;
        log.Class_Name__c  = className;
        log.Method_Name__c = methodName;
        log.Log_Type__c = logtype;
     	log.Error_Message__c = errorMessage;
        log.Error_Type__c  = errorType; 
        log.Request__c   = request;
        log.Response__c  = response;
        log.Stack_Trace__c  = stackTrace; 
		log.Type_of_Object__c = typeOfObject;
		log.Interface_Name__c = interfaceName; 
                                     
        CreateLog(log);
     }
    
    /**
	* Create and publish log event
	* @param  {String} status : Success or Fail (use Constant)
	* @param  {String} errorMessage : System error
    * @param  {String} errorType : Exception name (DML,Null pointer etc)
    * @param  {String} request : Request sent (only for integration Log)
    * @param  {String} response : Response received (only for integration Log)
    * @param  {String} stackTrace : StackTrance of the error if available 
	* @param  {String} typeOfObject : Object Related to the error or Process
    * @param  {String} interfaceName : Interface name (only for integration Log)
    * @returns void
	**/  
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void createIntegrationLog(String status, String className, String methodName, String errorMessage, Integer errorCode, String errorType, String request, String response, 
                                            String stackTrace, String typeOfObject, String interfaceName) {
    
       /*public static void createIntegrationLog(ErrorLogWrapper errLog) { */
                                                
        Error_Log_Event__e log = new Error_Log_Event__e(); 
        log.Status__c = status;
        log.Class_Name__c  = className;
        log.Method_Name__c = methodName;
        log.Log_Type__c = LOG_TYPE_INTEGRATION;
     	log.Error_Message__c = errorMessage; 
        log.Error_Code__c = errorCode;
        log.Error_Type__c = errorType;
        log.Request__c   = request;
        log.Response__c  = response;
        log.Stack_Trace__c  = stackTrace; 
		log.Type_of_Object__c = typeOfObject;
		log.Interface_Name__c = interfaceName; 
                                     
        CreateLog(log);
     }
    
    /**
	* Create and publish log event
	* @param  {String} errorMessage : System error
    * @param  {String} errorType : Exception name (DML,Null pointer etc)
    * @param  {String} className : Class name where log is created
	* @param  {String} methodName : method name where log is created
    * @param  {String} stackTrace : StackTrance of the error if available 
	* @param  {String} typeOfObject : Object Related to the error or Process
    * @returns void
	**/  
    
    @SuppressWarnings('PMD.ExcessiveParameterList')
    public static void createBatchLog(String className, String methodName, String errorMessage, Integer errorCode, String errorType, String stackTrace, String typeOfObject) {

        Error_Log_Event__e log = new Error_Log_Event__e();
        log.Status__c = LOG_STATUS_FAIL;
        log.Class_Name__c  = className;
        log.Method_Name__c = methodName;
        log.Log_Type__c = LOG_TYPE_BATCH;
        log.Error_Message__c = errorMessage; 
        log.Error_Code__c = errorCode;
        log.Error_Type__c = errorType;
        log.Request__c   = null;
        log.Response__c  = null;
        log.Stack_Trace__c  = stackTrace; 
		log.Type_of_Object__c = typeOfObject;
		log.Interface_Name__c = null; 
                                     
        CreateLog(log);
     }
}