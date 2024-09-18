/**
* @description EDGE_ReturnBeerTagBulkRetryHandler class for ReturnBeerTag Bulk Retry
* @history
1.0        Sudipta Nandi     08/16/20201       Initial Development

*/

global with sharing Class EDGE_ReturnBeerTagBulkRetryHandler{
    
    @InvocableMethod
    Public static List<Response> RetryRecordtoSAP(List<Requests> requestList){
        Response res= new Response();
        res.success = true;
        System.enqueueJob(new EDGE_AsyncReturnBeerProcess(requestList[0].retrunBeerTagId));
        List<Response> responseWrapper= new List<Response>();
        responseWrapper.add(res);
        return responseWrapper;
    }
    global class Requests {
        @InvocableVariable(label='retrunBeerTagId')
        global List<String> retrunBeerTagId;
    }
    global class Response {
        @InvocableVariable(label='success')
        global Boolean success;
    }
}