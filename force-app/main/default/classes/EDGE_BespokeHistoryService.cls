/**********************************************************************
Name: EDGE_BespokeHistoryService
=======================================================================
Req: The requirement is to build Custom API for mobile to get Bespoke History Data
User Story : ES20-4063
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR        DATE              DETAIL
1.0      Amar Deep      03/09/2019        Custom API for mobile to get Bespoke History Data
2.0      Preyanka Ghosh	 03/12/2019		 ES20-6298 
***********************************************************************/
@RestResource(urlMapping='/BespokeHistoryService/*')
global with sharing class EDGE_BespokeHistoryService {
    
    @HttpGet
    global static List<EDGE_BespokeWrapper> doGet(){
        Id userId = Restcontext.request.params.get('userid');
        System.debug('@@userId' +userId);
        
        List<EDGE_BespokeWrapper> bespokeDetailsList = new List<EDGE_BespokeWrapper>();
        if(userId != null){
            bespokeDetailsList = EDGE_BespokeHistoryController.getBespokeOrderDetails(userId);
        }
        
        return bespokeDetailsList;
    }
}