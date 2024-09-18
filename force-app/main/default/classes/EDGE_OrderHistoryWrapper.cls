/*
Name: EDGE_OrderHistoryWrapper

History                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Anuja Chattopadhyay     19/07/2019        Wrapper Class used in EDGE_OrderHistoryService against ES20-2981
2.0    		Preyanka Ghosh		  	27/11/2019        ES20-6298 - Add User Id in custom API
3.0         Swaraj Samanta          26/08/2022        Wrapper Class used in EDGE_OrderHistoryService against ES20-10280
*/
global inherited sharing class EDGE_OrderHistoryWrapper {
   
    //public Order__c posParentOrder{get;set;}
    public Order__c childOrder{get;set;}
    public List<Order_Item__c> orderItemList{get;set;}
    public string userId {get;set;}  
    public List<EDGE_OrderHistoryPromotionWrapper> promotionList{get;set;}
}