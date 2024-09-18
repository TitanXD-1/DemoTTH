/*
Name: EDGE_OrderHistoryPromotionProductWrapper

History                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Swaraj Samanta    26/08/2022        Wrapper Class used in EDGE_OrderHistoryService against ES20-10280

*/
global inherited sharing class EDGE_OrderHistoryPromotionProductWrapper {

    public string Id{get;set;}
    public string productName{get;set;}
    public string promoProductType{get;set;}
    public string promoProductUOM{get;set;}
    public Double quantity{get;set;}
}