/**********************************************************************
Name: EDGE_ChatterFeedService
================================================================================
Req: The requirement is to build Custom API for mobile to get  Chatter notes based on the market setting.
User Story : ES20-9721
================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                DATE              DETAIL
1.0       Juned khan	       05/02/2021           
***********************************************************************/

@RestResource(urlMapping='/ChatterFeedService/*')
global with sharing  class EDGE_ChatterFeedService{
    
    @HttpGet
    global static EDGE_ChatterFeedWrapper doGet() {
       	String timestamp = RestContext.request.params.get('timestamp');
        Id outletId = Restcontext.request.params.get('outletid');
        EDGE_ChatterFeedWrapper chatterFeedWrap = new EDGE_ChatterFeedWrapper();
        if(outletId!=null){ 
            chatterFeedWrap = EDGE_ChatterFeedController.getChatterNote(outletId,timestamp); 
        }  
        return chatterFeedWrap;
    }
    
    
}