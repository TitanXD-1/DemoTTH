@isTest
global class B2BSearchControllerMock implements HTTPCalloutMock{
	global HTTPResponse respond(HTTPRequest request) {
        HTTPResponse response = new HTTPResponse();
        // Setting the response body
        response.setBody('{"inputs" : [ {"orderSummaryID" : "abc" }]}');
        // Setting the response header
        response.setHeader('Content-Type', 'application/json');
        // Setting the response code
        response.setStatusCode(200);
        // Returning the response
        return response;
    }
}