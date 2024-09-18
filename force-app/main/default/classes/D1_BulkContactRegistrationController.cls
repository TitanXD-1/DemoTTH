/**
 * @name D_1BulkContactRegistrationController
 * @description D1_BulkContactRegistrationController Class for validating user's registration request for direct customer
 * @history
 * VERSION     AUTHOR         DATE            DETAIL
 * 1.0        Sudipta Nandi    11/10/2020        
 **/
global with sharing Class D1_BulkContactRegistrationController{
    /**
     * @description 
     * @param requestList 
     * @return  `List<Response>`
     */    
    @InvocableMethod
    Public static List<Response> createD1User(List<Requests> requestList){
        Response res= new Response();
        res.success = true;
        System.enqueueJob(new D1_AsyncDirectCustRegister(requestList[0].contactId));
        List<Response> responseWrapper= new List<Response>();
        responseWrapper.add(res);
        return responseWrapper;
    }
    
    
    global class Requests {
        @InvocableVariable(label='contactId')
        global List<String> contactId;
    }
    global class Response {
        @InvocableVariable(label='success')
        global Boolean success;
    }
}