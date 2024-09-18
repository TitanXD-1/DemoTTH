/**********************************************************************
Name: EDGE_OpportunityClosedService
======================================================================================
Req: The requirement is to build Custom API for mobile to get Closed Opportunity Data
User Story : ES20-927
=======================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                DATE              DETAIL
1.0       Monalisa Halder       17/04/2019           
***********************************************************************/

@RestResource(urlMapping='/OpportunityClosedService/*')
global with sharing class EDGE_OpportunityClosedService{

    @HttpGet
    global static List<EDGE_BriefcaseWrapper> doGet() {
        Id userId = RestContext.request.params.get('userid');
        
        List<EDGE_BriefcaseWrapper> briefCaseWrapList = new List<EDGE_BriefcaseWrapper>();
        if(userId != null){
            briefCaseWrapList = EDGE_BriefcaseController.getOpportunitiesClosed(userId);
        }  
        return briefCaseWrapList;
    }
    
    
}