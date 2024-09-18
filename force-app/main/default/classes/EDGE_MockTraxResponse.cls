/**********************************************************************
Name: EDGE_MockTraxResponse
=======================================================================
Purpose: test class of Trax to gnerate mock response
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Preyanka Ghosh       04/06/2019        (ES20-1582,ES20-162)

***********************************************************************/
public class EDGE_MockTraxResponse implements HttpCalloutMock {
    
    public HTTPResponse respond(HTTPRequest req){
    
        HttpResponse res = new HttpResponse();
        res.setHeader('Content-Type', 'application/json');
        res.setBody('{"Job_Id":"123456789"}');
        res.setStatusCode(200);
        return res;
        
    }

}