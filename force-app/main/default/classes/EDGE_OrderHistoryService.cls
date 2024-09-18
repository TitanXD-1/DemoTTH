/*
Name: EDGE_OrderHistoryService
Req: The requirement is to build Custom API for mobile to get Order History Data
User Story : ES20-2981
History                                                            
                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0      Anuja Chattopadhyay      18/07/2019        Custom API for mobile to get Order History Data
*/
@RestResource(urlMapping='/OrderHistoryService/*')
global with sharing class EDGE_OrderHistoryService {
    
    @HttpGet
    global static List<EDGE_OrderHistoryWrapper> doGet(){
        Id userId = Restcontext.request.params.get('userid');
        String orderType = Restcontext.request.params.get('ordertype');
        System.debug('@@userId' +userId);
         System.debug('@@OrderType' +orderType);
        
        List<EDGE_OrderHistoryWrapper> orderDetailsList = new List<EDGE_OrderHistoryWrapper>();
        if(userId != null){
            orderDetailsList = EDGE_OrderHistoryController.getOrderDetails(userId,orderType);
 
        }
        
        return orderDetailsList;
    }
}