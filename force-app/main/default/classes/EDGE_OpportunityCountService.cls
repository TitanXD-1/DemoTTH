/**********************************************************************
Name: EDGE_OpportunityCountService
=======================================================================
Req: The requirement is to build Custom API for mobile to get Opportunity count Data
User Story : ES20-9158
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR        DATE              DETAIL
1.0      Amar Deep      18/12/2020        Custom API for mobile to get opportunity count
***********************************************************************/
@RestResource(urlMapping='/OpportunityCountService/*')
global with sharing class EDGE_OpportunityCountService {
    @HttpGet
    global static List<EDGE_OpportunityCountWrapper> doGet(){
        
        Id userId = Restcontext.request.params.get('userid');
        System.debug('@@userId' +userId);
        
        List<EDGE_OpportunityCountWrapper> OpportunityCountWrapperList = new List<EDGE_OpportunityCountWrapper>();
        if(userId != null){
            OpportunityCountWrapperList = EDGE_OpportunityCountController.getOpportunityCount(userId);
        }
        
        return OpportunityCountWrapperList;
    }
    
}