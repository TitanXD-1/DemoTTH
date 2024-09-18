/*
 * @name: D1_CustomLoggingUtility 
 * @discription: Create Custom Logs for exeptions 
 * @History 
 * VERSION     AUTHOR           DATE       DETAIL 
 * 1.0         Gaurav Singh    30/06/21    Initial Development(NCP-3577) 
 **/
public class D1_CustomLoggingUtility {

    /**
    * Create Custom Log Records
    * @author Gaurav Singh
    * @story NCP-3577
    * @param  {String} className : class name where log is created
    * @param  {String} methodName : method name where log is created
    * @param  {String} message : error message
    * @param  {String} stackTrace : error stack trace
    * @param  {String} type : type of error (DML,Null pointer)
    * @returns void
    */
    public static void logMessage(String className, String methodName, String message, String stackTrace, String type){ 
        logMessage(className, methodName, message, stackTrace, type, null, null);
    }

    /**
    * Create Custom Log Records
    * @author Gaurav Singh
    * @story NCP-3577
    * @param  {String} className : class name where log is created
    * @param  {String} methodName : method name where log is created
    * @param  {String} message : error message
    * @param  {String} stackTrace : error stack trace
    * @param  {String} type : type of error (DML,Null pointer)
    * @param  {String} request : API request JSON
    * @param  {String} response : API response JSON
    * @returns void
    */
    public static void logMessage(String className, String methodName, String message, String stackTrace, String type, String request, String response){ 
        Custom_Log__c newLogMessage = new Custom_Log__c( 
            Class_Name__c = className, 
            Method_Name__c = methodName, 
            Error_Message__c = message, 
            Stack_Trace__c = stackTrace, 
            Type__c = Type,
            API_Request__c = request,
            API_Response__c = response
        );
        
        try{ 
            Database.insert(newLogMessage); 
        }catch(Exception exLog){
            System.debug(LoggingLevel.ERROR, exLog.getMessage());
        } 
    }
    
    /**
    * Create Custom Log Records
    * @author Gaurav Singh
    * @story NCP-3577
    * @param  {String} className : class name where log is created
    * @param  {String} methodName : method name where log is created
    * @param  {Exception} ex : exception to log
    * @returns void
    */
    public static void logMessage(String className, String methodName, Exception ex){ 
        logMessage(className, methodName, (ex != NULL?ex.getMessage():null), (ex != NULL?ex.getStackTraceString():null), (ex != NULL?ex.getTypeName():null));
    }

    /**
    * Create Custom Log Records
    * @author Gaurav Singh
    * @story NCP-3577
    * @param  {String} className : class name where log is created
    * @param  {String} methodName : method name where log is created
    * @param  {Exception} ex : exception to log
    * @param  {String} request : API request JSON
    * @param  {String} response : API response JSON
    * @returns void
    */
    public static void logMessage(String className, String methodName, Exception ex, String request, String response){ 
        logMessage(className, methodName, (ex != NULL?ex.getMessage():null), (ex != NULL?ex.getStackTraceString():null), (ex != NULL?ex.getTypeName():null), request, response);
    }

    /**
    * Create Custom Log Records Future
    * @author Gaurav Singh
    * @story NCP-3577
    * @param  {String} className : class name where log is created
    * @param  {String} methodName : method name where log is created
    * @param  {String} message : error message
    * @param  {String} stackTrace : error stack trace
    * @param  {String} type : type of error (DML,Null pointer)
    * @param  {String} request : API request JSON
    * @param  {String} response : API response JSON
    * @returns void
    */
    @future
    public static void logMessageFuture(String className, String methodName, String message, String stackTrace, String type, String request, String response){ 
        logMessage(className, methodName, message, stackTrace, type, request, response);
    }
}