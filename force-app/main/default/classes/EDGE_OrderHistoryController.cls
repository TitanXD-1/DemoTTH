/*
Name: EDGE_OrderHistoryController
Req: 
* ES20-2981

History                                                                                                                        
VERSION   AUTHOR              DATE            DETAIL
1.0    Anuja Chattopadhyay    22/07/2019      Initial Development 
2.0    Manohar Burkala        28/10/2019      ES20-5234 - Functionality added for Transfer Order
3.0    Preyanka Ghosh		  27/11/2019      ES20-6298 - Add User Id in custom API
4.0    Amar Deep              28/11/2019      ES20-5769 - Functionality added for Free Goods Order
5.0    Amar Deep              23/12/2019      ES20-6409 - Free Goods Order with status “Order Placed”should be displayed as per the number set in market settings
6.0    Wribhu Bose			  09/05/2022	  ES20-12657 - Added MAP ID to query for Order Items
7.0    Prasanth T			  12/05/2022	  ES20-12628 - Added Sales Rep Name in Transfer order and Free Goods order.
8.0    Anand U                23/05/2022      ES20-12787 - Included statuses Approved , Rejected for POS order, Ready for Order for Transfer Order
9.0	   Swaraj Samanta		  26/08/2022	  ES20-10280 - Existing Custom Service to send Order History along with Promotion Product detailsto Mobile
10.0   Joshraj Sen            11/10/2022      ES20-12883 - Include the fields Reported Quantity from Order Item, Parent Order Id and Replacement Order Placed from Order  
11.0   Joshraj Sen            30/11/2022      ES20-13599 - Include POSGroup Orders in the Service ES20-13617 Include Parent Order Id and Replacement Order Placed from Order for POS Orders which are part of a POS Group Order
*/
public inherited sharing class EDGE_OrderHistoryController {
    
    static List<EDGE_OrderHistoryWrapper> orderHistoryWrapperList = new List<EDGE_OrderHistoryWrapper>();
    
    /*
Purpose: To fetch Order Details for the user passed from mobile                                                       
*/    
    public static List<EDGE_OrderHistoryWrapper> getOrderDetails(Id userId, string orderType){
        
        //Variables
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> parentOrderIdSet = new Set<Id>(); 
        List<Order__c> nonSplitOrderList = new List<Order__c>(); 
        List<Order__c> splitChildorderList = new List<Order__c>();
        List<Order__c> posGroupOrders=new List<Order__c>();//ES20-13599
        List<Order__c> allOrderList = new List<Order__c>();
        Map<String,List<Order_Item__c>> orderItemOrderMap = new Map<String,List<Order_Item__c>>();
        Map<String,List<Order_Item__c>> orderItemPromotionMap = new Map<String,List<Order_Item__c>>();
        Map<Order__c,Order__c> orderMap = new Map<Order__c,Order__c>(); 
        List<Account> accountList = new List<Account>();
        Integer recordLimit = 0;
        Integer transferorderrecordlimit = 0;//Create New Variable for transfer order.
        Integer freeGoodsOrderRecordLimit = 0 ;//Create New Variable for Free Goods Order.
        String countryCode = '';
        List<Market_Setting__c> marketSetting;
        String posOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        String posOrderGroupRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order Group').getRecordTypeId();
        String transferorderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        String freeGoodsRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        if(userId!=null){
            //Fetching all the outlets of the user by querying outlet members
            for(Outlet_Member__c outletMemObj : [Select Id, Outlet__c, Outlet__r.Country_Code__c 
                                                 from Outlet_Member__c where User__c =:userid])
            {
                accountIdSet.add(outletMemObj.Outlet__c);
                countryCode = outletMemObj.Outlet__r.Country_Code__c;
            }
        }
                
        if(String.isNotBlank(countryCode) && Schema.SObjectType.Market_Setting__c.isAccessible() &&  Schema.SObjectType.Geography__c.isAccessible()){
            marketSetting = [Select Id,Transfer_Order_History_Number__c,Order_History_Number__c,Free_Goods_History_Number__c,Geography__r.Code__c 
                             from Market_Setting__c where Geography__r.Code__c =:countryCode and 
                             (Order_History_Number__c != null OR Transfer_Order_History_Number__c != null OR Free_Goods_History_Number__c != null ) Limit 1]; 
            
            System.debug('marketSetting = '+ marketSetting);
            if(marketSetting!=null && marketSetting.size()>0 && marketSetting[0].Order_History_Number__c!=null){
                recordLimit = (Integer)marketSetting[0].Order_History_Number__c;
               // System.debug('@@RecoredList' +recordLimit);
            }
            if(marketSetting!=null && marketSetting.size()>0 && marketSetting[0].Transfer_Order_History_Number__c!=null){
                transferorderrecordlimit = (Integer)marketSetting[0].Transfer_Order_History_Number__c;
               // System.debug('@@Recordlimit1' +transferorderrecordlimit);
            }
            if(marketSetting!=null && marketSetting.size()>0 && marketSetting[0].Free_Goods_History_Number__c!=null){
                freeGoodsOrderRecordLimit = (Integer)marketSetting[0].Free_Goods_History_Number__c;
               // System.debug('@@Recordlimit1free' +freeGoodsOrderRecordLimit);
            }
            
        }
        System.debug('@@Account ID Set: '+accountIdSet);
        System.debug('@@Order type: '+orderType);
        //Fetching all the orders where Order Group is not present 
        if(accountIdSet!=null && accountIdSet.size()>0){
            if(orderType!=null && orderType == 'POS'){
                if(recordLimit!=null && Schema.SObjectType.Order__c.isAccessible() && Schema.SObjectType.Account.isAccessible() && Schema.SObjectType.Delivery_Partner__c.isAccessible()){
                    accountList = [Select Id, (Select Id,Name,Account__c,Replacement_Order_Placed__c,Parent_Order__c, Order_Group__c, Order_Group__r.Status__c, Delivery_Partner__c, Delivery_Partner__r.name,CreatedDate,
                                               Delivery_Location__c, Status__c, LastModifiedDate, RecordTypeId,Total_A_P_Cost__c,Order_Placed_Date__c,Order_Header_Notes__c,Sales_Representative__r.Name  
                                               
                                               FROM Orders__r WHERE Status__c IN ('Shed to Customer','Delivered to Shed','Delivered to Customer','Approved','Rejected') //ES20-12787 /*ES20-12883 Include fields Replacement_Order_Placed__c and Parent_Order__c*/
                                               
                                               AND Order_Group__c = NULL
                                               AND (RecordTypeId =:posOrderGroupRecordTypeId OR RecordTypeId =:posOrderRecordTypeId)
                                               Order by LastModifiedDate Desc limit :recordLimit) 
                                   from Account WHERE Id in :accountIdSet ];
                }
            }
            else if(orderType!=null && orderType == 'Transfer Order' ){
                if(transferorderrecordlimit!=null && Schema.SObjectType.Order__c.isAccessible() && Schema.SObjectType.Account.isAccessible()){
                    accountList = [Select Id, (Select Id,Name,Account__c,Replacement_Order_Placed__c,Parent_Order__c, Status__c, LastModifiedDate, RecordTypeId,Total_Freight_Cost__c,Wholesaler__c,CreatedDate,Preferred_Delivery_Date__c
                                               ,Sales_Representative__r.Name,Is_Promo_Transfer_Order__c
                                               FROM Orders__r WHERE Status__c IN ('Order Placed','Ready for Order','Cancelled') //ES20-12787,ES20-10280 /*ES20-12883 Include fields Replacement_Order_Placed__c and Parent_Order__c*/ 
                                               
                                               AND (RecordTypeId =:transferorderRecordTypeId)
                                               Order by LastModifiedDate Desc limit :transferorderrecordlimit) 
                                   from Account WHERE Id in :accountIdSet ];
                } 
            }
            else if(orderType!=null && orderType == 'Free Goods' && Schema.SObjectType.Account.isAccessible()){
                if(freeGoodsOrderRecordLimit!=null && Schema.SObjectType.Order__c.isAccessible()){
                    accountList = [Select Id, (Select Id,Name,Account__c,Replacement_Order_Placed__c,Parent_Order__c, Status__c, LastModifiedDate, RecordTypeId,Total_Freight_Cost__c,Wholesaler__c,CreatedDate,Preferred_Delivery_Date__c,Sales_Representative__r.Name
                                               FROM Orders__r WHERE Status__c IN ('Order Placed') 
                                               AND (RecordTypeId =:freeGoodsRecordTypeId)
                                               Order by LastModifiedDate Desc limit :freeGoodsOrderRecordLimit) 
                                   from Account WHERE Id in :accountIdSet ];/*ES20-12883 Include fields Replacement_Order_Placed__c and Parent_Order__c*/
                } 
            }
        }
        System.debug('@@accountList' +accountList);
        if(accountList!=null && accountList.size()>0){
            for(Account acctObj : accountList){
                System.debug('@@orders_R: '+acctObj.Orders__r);
                if(acctObj.Orders__r !=null && acctObj.Orders__r.size()>0){
                    List<Order__c> orderList = acctObj.Orders__r;
                    for(Order__c ordObj : orderList){
                        if(ordObj.RecordTypeId == posOrderGroupRecordTypeId){
                            posGroupOrders.add(ordObj);//ES20-13599
                            parentOrderIdSet.add(ordObj.Id);
                        }
                        else{
                            nonSplitOrderList.add(ordObj);
                        }
                    }
                }
            }
        }
        //Fetching splitchild orders
        if(parentOrderIdSet != null && Schema.SObjectType.Order__c.isAccessible() && parentOrderIdSet.size() > 0){
            
            splitChildorderList = [Select Id,Name,Account__c, Order_Group__c,Replacement_Order_Placed__c,Parent_Order__c,Order_Group__r.Name,Order_Group__r.Status__c,Order_Group__r.Delivery_Partner__c,
                                   Order_Group__r.Account__c,Order_Group__r.RecordTypeId,Order_Group__r.Delivery_Partner__r.name,Delivery_Partner__c, Delivery_Partner__r.name,
                                   Delivery_Location__c, Status__c, LastModifiedDate, RecordTypeId,Total_A_P_Cost__c,Order_Placed_Date__c from Order__c 
                                   where Order_Group__c IN :parentOrderIdSet and RecordTypeId = :posOrderRecordTypeId]; //ES20-13617 
            
        }
        //Parent Child Relationship Built For Split Orders
        for(Order__c childOrdObj : splitChildorderList){
            Order__c ordObj = new Order__c(Id= childOrdObj.Order_Group__c);
            {
                orderMap.put(childOrdObj, ordObj);
            }
        }
        
        
        //Adding all split and non split orders to the list to send them to mobile
        if(nonSplitOrderList !=null){
            allOrderList.addAll(nonSplitOrderList);
        }
        if(splitChildorderList !=null){
            allOrderList.addAll(splitChildorderList);
        }
        if(posGroupOrders!=null){//ES20-13599
            allOrderList.addAll(posGroupOrders);//ES20-13599
        }//ES20-13599
            
        
        
        if(allOrderList!=null && allOrderList.size()>0){
            // ES20-12657 - added MAP ID in query
            // ES20-10280 - added promotions field in query
            for(Order_Item__c childOrdItemObj : [Select Id,Pending_Quantity__c,Status__c,Quantity__c, Order__c, Product__c, Product__r.Name,Product__r.Units_per_POS__c,Product__r.Type__c,
                                                 Product__r.Product_Image__c,Order__r.Order_Group__c,Selected_UoM__c,Market_Assortment_Product__c,Order__r.Is_Promo_Transfer_Order__c,
                                                 Promotion_Product__r.Promo_Transfer_Order_Used_UOM__c ,Promotion_Product__r.RecordType.Name,Promotion_Product__r.Promotion__r.Name,
                                                 Promotion_Product__r.Promotion__c,Promotion_Product__r.Promotion__r.RecordType.Name,Promotion_Product__c from Order_Item__c where Order__c IN : allOrderList]){
                                                     if (childOrdItemObj.Promotion_Product__c != null){//ES20-10280 - to create separate Map for promotion //ES20-12883 To Include Pending_Quantity__c field  
                                                         
                                                         if(orderItemPromotionMap.containsKey(childOrdItemObj.Order__c)) {
                                                             List<Order_Item__c> ordItemList = orderItemPromotionMap.get(childOrdItemObj.Order__c);
                                                             ordItemList.add(childOrdItemObj);
                                                             orderItemPromotionMap.put(childOrdItemObj.Order__c, ordItemList);
                                                         } else {
                                                             orderItemPromotionMap.put(childOrdItemObj.Order__c, new List<Order_Item__c> {childOrdItemObj });
                                                         }
                                                     }else{
                                                         if(orderItemOrderMap.containsKey(childOrdItemObj.Order__c)) {
                                                             List<Order_Item__c> ordItemList = orderItemOrderMap.get(childOrdItemObj.Order__c);
                                                             ordItemList.add(childOrdItemObj);
                                                             orderItemOrderMap.put(childOrdItemObj.Order__c, ordItemList);
                                                         } else {
                                                             orderItemOrderMap.put(childOrdItemObj.Order__c, new List<Order_Item__c> {childOrdItemObj });
                                                         } 
                                                     }
                                                     
                                                 }
        }
        createWrapper(userId,allOrderList,orderItemOrderMap,orderItemPromotionMap);
        return orderHistoryWrapperList;   
    }
    
    /*
@Description: To create the wrapper   
@return :void
**/
    public static void createWrapper(String userId,List<Order__c> allOrderList, Map<String,List<Order_Item__c>> orderItemOrderMap,Map<String,List<Order_Item__c>> orderItemPromotionMap){
        String posOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        String posOrderGroupRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order Group').getRecordTypeId();
        String transferorderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        String freeGoodsRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        
        for(Order__c ordObj : allOrderList ){
            EDGE_OrderHistoryWrapper ordHistryWrapper = new EDGE_OrderHistoryWrapper();
            ordHistryWrapper.userId=userId;
            
            if (ordObj.RecordTypeId == transferorderRecordTypeId && ordObj.Is_Promo_Transfer_Order__c == true ){
                
                ordHistryWrapper.childOrder = ordObj;
                if(orderItemOrderMap!=null && orderItemOrderMap.containskey(ordObj.Id) && (orderItemOrderMap.get(ordObj.Id) != null) ){
                        ordHistryWrapper.orderItemList = orderItemOrderMap.get(ordObj.Id);
                }
                //applicable for promotion transfer order only 
                if(orderItemPromotionMap!=null && orderItemPromotionMap.containskey(ordObj.Id) && (orderItemPromotionMap.get(ordObj.Id) != null)){
                    ordHistryWrapper.promotionList = createWrapperForPromotion(ordObj,orderItemPromotionMap.get(ordObj.Id)) ;
                }
                
            }//applicable for simple transfer order ,pos,free goods
            else if(ordObj.RecordTypeId == posOrderRecordTypeId || ordObj.RecordTypeId == freeGoodsRecordTypeId || ordObj.RecordTypeId == transferorderRecordTypeId || ordObj.RecordTypeId==posOrderGroupRecordTypeId){  //ES20-13599
                ordHistryWrapper.childOrder = ordObj;
                if(orderItemOrderMap!=null && orderItemOrderMap.containskey(ordObj.Id) && (orderItemOrderMap.get(ordObj.Id) != null)){
                        ordHistryWrapper.orderItemList = orderItemOrderMap.get(ordObj.Id);
                }
            }
            orderHistoryWrapperList.add(ordHistryWrapper);   
        }
    }
    
    /*
@description: To create the promotion wrapper along with promotion product wrapper list - ES20-10280 
@return :List<EDGE_OrderHistoryPromotionWrapper>
**/
    public static List<EDGE_OrderHistoryPromotionWrapper> createWrapperForPromotion(Order__c orderData,List<Order_Item__c> orderItemPromotionList){
        Map<Id,EDGE_OrderHistoryPromotionWrapper> promotionListMap = new Map<Id,EDGE_OrderHistoryPromotionWrapper>(); //To store promotion details outer layer
        Map<Id,List<EDGE_OrderHistoryPromotionProductWrapper>> promoProductMap = new Map<Id,List<EDGE_OrderHistoryPromotionProductWrapper>>();//To store promotion product details inner List layer
        
        for(Order_Item__c promoitem : orderItemPromotionList){
            
            //Creation of inner List Layer of promtion product 
            EDGE_OrderHistoryPromotionProductWrapper promoProductDetails = new EDGE_OrderHistoryPromotionProductWrapper();
            promoProductDetails.Id = promoitem.id;
            if (promoitem.Product__c != null){
                 promoProductDetails.productName = promoitem.Product__r.Name;
            }
            promoProductDetails.promoProductType = promoitem.Promotion_Product__r.RecordType.Name;
            promoProductDetails.promoProductUOM = promoitem.Promotion_Product__r.Promo_Transfer_Order_Used_UOM__c;
            promoProductDetails.quantity = promoitem.Quantity__c ;
            
            //to store all promotion product against promotion id in a map
            if(promoProductMap.containsKey(promoitem.Promotion_Product__r.promotion__c)) {
                List<EDGE_OrderHistoryPromotionProductWrapper> promoItemList = promoProductMap.get(promoitem.Promotion_Product__r.promotion__c);
                promoItemList.add(promoProductDetails);
                promoProductMap.put(promoitem.Promotion_Product__r.promotion__c, promoItemList);
            } else {
                promoProductMap.put(promoitem.Promotion_Product__r.promotion__c, new List<EDGE_OrderHistoryPromotionProductWrapper> {promoProductDetails });
            }
            
            //Creation of outer Layer of promotion details 
            EDGE_OrderHistoryPromotionWrapper promotiondetails = new EDGE_OrderHistoryPromotionWrapper();
            promotiondetails.promotionId = promoitem.Promotion_Product__r.promotion__c;
            promotiondetails.promotionName = promoitem.Promotion_Product__r.Promotion__r.Name;
            promotiondetails.promotiontype = promoitem.Promotion_Product__r.Promotion__r.RecordType.Name;
            promotiondetails.promotionItemsList = promoProductMap.get(promoitem.Promotion_Product__r.promotion__c);
            promotionListMap.put(promoitem.Promotion_Product__r.promotion__c, promotiondetails);
        }
        return promotionListMap.values();
        
    }
}