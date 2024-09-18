/**********************************************************************
Name: EDGE_TransferOrderMailWrapper

=======================================================================
Req: 
ES20-9974 : 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Monalisa Halder     17/06/2021       ES20-9974 
2.0     Manikant Prasad     17/06/2021       ES20-9976
3.0		Rajarshi Lahiri		13/05/2022		 ES20-12728
4.0.    Swaraj Samanta		12/08/2022		 ES20-9300
***********************************************************************/

public class EDGE_TransferOrderMailWrapper {
    
    public headerWrapper headerWrapperValue;
    public List<orderDetailsWrapper> orderDetailsWrapperValue;
   
    public class headerWrapper {
        public String TableBody {get; set;}
        public String accountName {get; set;}
        public String recordType {get; set;}
        public String accountAddress {get; set;}
        public String PreferredOrderDate {get; set;}
        public String wholesalerName {get; set;}
        public String wholesalerAccountNumber {get; set;}
        public String salesRepName {get; set;}
        public String mobileNumber {get; set;}
        public String email {get; set;}
        public String orderNumber {get; set;}
        public String prodName {get; set;}
        public String prodQuant {get; set;}
        public String UOM {get; set;}
        public String overallComment {get; set;}
        public Boolean showWholesaler{get;set;}
        public Boolean showComment{get;set;}
        public String productSKUID {get; set;} //ES20-12728
        public String promotionName {get; set;}
        public String promotionType {get; set;}
        public String discountForPromotion {get; set;}
        public String freeProdforPromo {get; set;}//ES20-9300 - for column header
    }
    public class orderDetailsWrapper{
        public string accountName{get;set;}
        public List<orderObj> orderList{get;set;}
    }
    public class orderObj{
        public String accountAddress {get;set;}
        public String OrderedDate{get;set;}
        public String wholesalerName{get;set;}
        public String WholesalerAccountNumber{get;set;}
        public String salesRepName{get;set;}
        public String  MobileNumber{get;set;}
        public String  Email{get;set;}
        public String OrderNumber{get;set;}
        public String OverAllComment {get;set;}
        public Boolean showImage{get;set;}
        public Boolean showText{get;set;}
        public String imageValue{get;set;}
        public Boolean showImageSection{get;set;}
        public Boolean isOrderItemPresent{get;set;}
        public Boolean isPromoOrder{get;set;}
        public List<orderItemObj> ordItemList{get;set;}
        public List<promotionDetailsObj> promotionDetailsList{get;set;} //ES20-9300
        
    }
    public class orderItemObj{
        public String productName {get; set;}
        public Decimal productQuantity {get; set;}
        public String productUOM {get; set;}
        public String productSKUId {get; set;}
    }
    public class promotionDetailsObj{//ES20-9300
        public String promotionName {get; set;}
        public String promotionType {get; set;}
        public Decimal discountForPromotion {get; set;}
        public Boolean isFreePromotion {get; set;}
        public List<promotionItemsObj> promotionItemsObj{get;set;}
    }
    public class promotionItemsObj{//ES20-9300
        public String productName {get; set;}
        public Decimal productQuantity {get; set;}
        public String productUOM {get; set;}
        public String productSKUId {get; set;}
        public String isFreeProduct {get; set;}//Yes/No
    }
}