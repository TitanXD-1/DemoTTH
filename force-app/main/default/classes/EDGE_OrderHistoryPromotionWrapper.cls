/*
Name: EDGE_OrderHistoryPromotionWrapper

History                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Swaraj Samanta    26/08/2022        Wrapper Class used in EDGE_OrderHistoryService against ES20-10280

*/
global inherited sharing class EDGE_OrderHistoryPromotionWrapper {
    
    public string promotionId{get;set;}
    public string promotionName{get;set;}
    public string promotiontype{get;set;}
    public List<EDGE_OrderHistoryPromotionProductWrapper> promotionItemsList{get;set;}
    
}