/*
Name: EDGE_CallHistoryService
Req: The requirement is to build Custom API for mobile to get Call History Data
User Story : ES20-927
History                                                                                                                        
VERSION   AUTHOR                DATE              DETAIL
1.0       Monalisa Halder       17/04/2019           
*/

@RestResource(urlMapping='/CallHistoryService/*')
global with sharing class EDGE_CallHistoryService{

    @HttpGet
    global static List<EDGE_BriefcaseWrapper> doGet() {
        Id userId = RestContext.request.params.get('userid');
        System.debug(LoggingLevel.Debug,'userId:::'+userId);
        
        List<EDGE_BriefcaseWrapper> briefCaseWrapList = new List<EDGE_BriefcaseWrapper>();
        if(userId != null){
            briefCaseWrapList = EDGE_BriefcaseController.getCallHistory(userId);
        }  
        return briefCaseWrapList;
    }
    
    
}