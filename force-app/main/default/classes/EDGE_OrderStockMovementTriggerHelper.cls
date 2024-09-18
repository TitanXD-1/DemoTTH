/**


* @name EDGE_OrderStockMovementTriggerHelper

* @description: Trigger Helper Class for Stock Movement Order

* @history                                                            



* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Monalisa Halder   30/09/2019        ES20-4602
*  2.0       Manikant p        03/10/2019        ES20-4499
*  3.0       Dipanjan Das      30/09/2019        ES20-4500
*  4.0       Amar Deep         15/11/2019        ES20-5546
*  5.0       Manikant Prasad   20/05/2021        ES20-10254 Modified Existing method (shedStockOperations)
*  5.1       Manikant Prasad   20/05/2021        ES20-10254 Added  checkShedStockForMarketAssortment ,createNewShedStock Methods 
*  6.0       Monalisa Halder   25/06/2021        ES20-10481 stockMovementOrdStatusUpdate 
*  7.0       Anamika Shukla    16/08/2021        ES20-10488 Modified Existing method shedStockOperations,checkShedStockForMarketAssortmentMvt,createNewShedStockForMvt methods

*  8.0       Monalisa Haldar   06/06/2021        ES20-11020 Modified Existing method shedStockOperations
*  8.1       Mayukh S Roy      26/04/2022        US-2876871 Shed Stock Adjustment Bug
*  8.2       Anamika Shukla    09/05/2024        366446 EDGE_Global: Allow Only Trusted Cross-Org Redirections
 
*/
public without sharing class EDGE_OrderStockMovementTriggerHelper {
    
    /*Global Map*/
    private static Map<Id, Order__c> mapNewOrder = new Map<Id, Order__c>(); //Used to contains all submitted order
    private static Map<Id, Id> mapChildOrderToParent = new Map<Id,Id>(); //Used to contains mapping of Child Stock Movement Order id to Parent Group Stock Movement order id
    private static Map<Id, List<Id>> mapParentToChildOrder = new Map<Id,List<Id>>(); //Mapping of Parent Group Stock Movement order id and List child order
    private static Map<Id, Stock__c> mapLineItemToStock = new Map<Id, Stock__c>(); //Mapping between Order line item and stock
    private static Map<Id, Stock__c> mapLineItemToInvalidStock = new Map<Id, Stock__c>(); //Mapping between Order line item and stock
    private static Map<Id,Order_Item__c> mapProductIdOrderItem = new Map<Id,Order_Item__c>(); //Map of Product Id and  Order Item
    private static Map<Id, List<Order_Item__c>> mapProductIdOrderItemlst = new Map<Id,List<Order_Item__c>>(); //Map of Product Id and List of Order Item
    private static Map<Id, List<Id>> mapOrderToLineItem = new Map<Id, List<Id>>(); //Order and all line Item
    private static Map<Id, Order_Item__c> mapOrderLineItem = new Map<Id, Order_Item__c>();
    private static Map<Id, Id> mapLineItemToOrderId = new Map<Id, Id>(); //Mapping of Line Item to Order 
    
    /*Global String*/
    private static String stockMovementRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
    private static String stockMovementGroupRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement Group').getRecordTypeId();
    private static String stockAdjRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
    private static String shedRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
    private static String freeGoodTerrBudgetRecordTypeId = Territory_Budget__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Good').getRecordTypeId();
   	private static String salesTerritoryRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    
    /*Global List*/
    private static List<Messaging.SingleEmailMessage> lstAllSingleEmail = new List<Messaging.SingleEmailMessage>();
    private static List<Id> lstUpdateOrder = new List<Id>(); //Order List Id for which validation fails
    private static List<Stock__c> lstUpdatedStock = new List<Stock__c>();
    private static List<Order__c> lstReadyForOrder = new List<Order__c>();
    private static List<Order__c> lstAllUpdatedOrder = new List<Order__c>();
    private static List<Id> lstOrderCreatedByUser = new List<Id>();
    public static List<Order_Item__c> lstUpdateOrderLineItem = new List<Order_Item__c>();
    
    /*Global Set*/
    public static Set<String> setCountryCode = new Set<String>();
    public static Set<String> setArea = new Set<String>();  
    
    
    /**


* @method   validateLineItemQuantity
* @description This method is used to check whether Order Line Item quantity
*  is valid or not. First it will check with Product and then with 
*  Stock. -US 4602
*  @return void
*  @param Map


*/
    public static void validateShedLineItemQuantity(Map<Id,SObject> newItems){
        String shedItemRecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
        String orderSubmmitted = EDGE_Constant.ORDER_SUBMITTED;
        Set<Id> setStockMovementGroupOrder = new Set<Id>();
        Set<Id> setStockMovementOrder = new Set<Id>();
        Map<Id,Order__c> newOrderMap;
        
        Map<Order_Item__c, String> mapLineItemValidation = new Map<Order_Item__c, String>();
        
        if(newItems != null){
            newOrderMap = (Map<Id,Order__c>)newItems;
        } 
        
        
        if(newOrderMap != null && !EDGE_UtilityClass.stopSecondTriggerToRun){
            EDGE_UtilityClass.stopSecondTriggerToRun = true; //Used to stop recursion
            
            for(Order__c newOrder : newOrderMap.values()){
                //Depending upon Record Type create 2 different set, that can be used to get the child POS Order record
                if(newOrder.Status__c == orderSubmmitted  && newOrder.RecordTypeId == stockMovementGroupRecordTypeId){
                    setStockMovementGroupOrder.add(newOrder.Id);
                    mapNewOrder.put(newOrder.Id, newOrder);
                    
                } else if(newOrder.Status__c == orderSubmmitted && newOrder.RecordTypeId == stockMovementRecordTypeId){
                    setStockMovementOrder.add(newOrder.Id);
                    mapNewOrder.put(newOrder.Id, newOrder);
                    
                }
            }
            
            //Fetch all child record of record type POS Order
            if(setStockMovementGroupOrder != null && setStockMovementGroupOrder.size()>0){
                for(Order__c stockMovementOrder : [SELECT Id, Order_Group__c FROM Order__c WHERE Order_Group__c IN :setStockMovementGroupOrder and RecordTypeId = :stockMovementRecordTypeId]){
                    mapChildOrderToParent.put(stockMovementOrder.Id, stockMovementOrder.Order_Group__c);
                    setStockMovementOrder.add(stockMovementOrder.Id);
                    if(mapParentToChildOrder.containsKey(stockMovementOrder.Order_Group__c)){
                        mapParentToChildOrder.get(stockMovementOrder.Order_Group__c).add(stockMovementOrder.Id);
                    } else {
                        mapParentToChildOrder.put(stockMovementOrder.Order_Group__c, new List<Id> {stockMovementOrder.Id});
                    }
                }
                setStockMovementGroupOrder.clear();
            }
            
            //Fetch all the line item irrespective of Type of Order and Order Line Item
            if(setStockMovementOrder != null && setStockMovementOrder.size()>0 && Schema.SObjectType.Order_Item__c.isAccessible()){
                
                for(Order_Item__c orderItemRec : [SELECT Id, Order__c, Order__r.Sales_Representative__c, Status__c, Product__c, Order__r.Account__c, Order__r.Account__r.Name, 
                                                  CreatedById, CreatedBy.Email, CreatedBy.FirstName, Product__r.Limit_Per_Order__c, 
                                                  Product__r.Name, Quantity__c, Type__c, Order__r.Order_Group__c, Product_Variant__c,
                                                  Product__r.Product_Type__c, Product__r.Product_Type__r.Type__c
                                                  FROM Order_Item__c 
                                                  WHERE Order__c IN :setStockMovementOrder 
                                                  AND RecordTypeId =:shedItemRecordTypeId])
                {
                    lstOrderCreatedByUser.add(orderItemRec.CreatedById);
                    mapOrderLineItem.put(orderItemRec.Id, orderItemRec);
                    
                    //To populate the Line Item per Order
                    mapLineItemToOrderId.put(orderItemRec.Id, orderItemRec.Order__c);
                    if(mapOrderToLineItem.containsKey(orderItemRec.Order__c)){
                        mapOrderToLineItem.get(orderItemRec.Order__c).add(orderItemRec.Id);
                    } else {
                        mapOrderToLineItem.put(orderItemRec.Order__c, new List<Id>{orderItemRec.Id});
                    }
                    
                    //To populate product id and order itemlist
                    mapProductIdOrderItem.put(orderItemRec.Product__c,orderItemRec);
                    if(mapProductIdOrderItemlst.containsKey(orderItemRec.Product__c)){
                        mapProductIdOrderItemlst.get(orderItemRec.Product__c).add(orderItemRec);
                    } else {
                        mapProductIdOrderItemlst.put(orderItemRec.Product__c, new List<Order_Item__c> {orderItemRec});
                    } 
                    
                    setStockMovementOrder.clear();
                }
            }
            //Validate  Stock Quantity
            if(mapProductIdOrderItemlst != null && mapProductIdOrderItemlst.size()>0){
                mapLineItemValidation.putAll(validateStockQuantity(null, null));
            }
            
            Map<Id,Order__c> mapVerifyAPOrder = createStockMovementOrderList(mapLineItemValidation);
            //Query and Update the Status of Order to Order held if Quantity check exceed
            if(lstUpdateOrder != null && lstUpdateOrder.size()>0){
                Map<Id,Order__c> mapUniqueOrder = new Map<Id,Order__c>();
                Map<Id, Messaging.SingleEmailMessage> mapMail = new Map<Id, Messaging.SingleEmailMessage>();
                
                for(Order__c updateOrder : [SELECT ID, Status__c,RecordTypeId FROM Order__c WHERE ID IN :lstUpdateOrder and Status__c =: orderSubmmitted]){
                    updateOrder.Status__c = 'Order Held';
                    mapUniqueOrder.put(updateOrder.Id,updateOrder); 
                    
                    //Used to create the Email template for Order with Status Held
                    if(!mapMail.containskey(updateOrder.Id)){
                        if(mapNewOrder.containsKey(updateOrder.Id) && updateOrder.RecordTypeId == stockMovementRecordTypeId){
                            mapMail.put(updateOrder.Id, createOrderHeldTemplate(updateOrder.Id));
                        } else if(!mapNewOrder.containsKey(updateOrder.Id) && mapChildOrderToParent.containsKey(updateOrder.Id)){
                            mapMail.put(mapChildOrderToParent.get(updateOrder.Id), createOrderHeldTemplate(updateOrder.Id));
                        }
                    }
                }
                
                lstAllUpdatedOrder.addAll(mapUniqueOrder.values());
                
                if(mapMail != null && mapMail.size()>0){
                    lstAllSingleEmail.addAll(mapMail.values());
                }
            }
            
            performAllDML(); 
        }
    }
    
    /**


* @method   validateStockQuantity
* @decsription : Depending upon the Product selected in the Order Line Item
* it will retrieve the corresponding stock of Allocation type.
* And then compares the quantity - US 4602
* @return Map
* @param Map, Map


*/
    public static Map<Order_Item__c, String> validateStockQuantity(Map<Order_Item__c,Id> orderItemMap, Map<Order_Item__c,Id> salesRepItemMap){
        List<Id> lstUserId = new List<Id>();
        Set<Order_Item__c> setOrderItem = new Set<Order_Item__c>();  
        Map<Id, Id> mapTerritoryDetails = new Map<Id, Id>(); 
        Map<Order_Item__c, String> mapLineItemValidation = new Map<Order_Item__c, String>();
        
        String recordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        String createdById;
        
        if(orderItemMap != null){
            for(Order_Item__c orderItemRec : orderItemMap.keySet()){
                mapProductIdOrderItem.put(orderItemRec.Product__c,orderItemRec);
                if(mapProductIdOrderItemlst.containsKey(orderItemRec.Product__c)){
                    mapProductIdOrderItemlst.get(orderItemRec.Product__c).add(orderItemRec);
                } else {
                    mapProductIdOrderItemlst.put(orderItemRec.Product__c, new List<Order_Item__c> {orderItemRec});
                }
            }            
        }
        
        
        //Need to check whether the method called from API or Trigger as the API does not have order item id
        if(orderItemMap != null && orderItemMap.size()>0){//Service scenario
            lstUserId.addAll(orderItemMap.values());
        } else if(lstOrderCreatedByUser != null && lstOrderCreatedByUser.size()>0){ //Trigger scenario               
            lstUserId.addAll(lstOrderCreatedByUser);
        }
        
        if(lstUserId != null && lstUserId.size()>0){
            //Retrieve the Primary Territory Member of the Sales Rep who is creating the order
            for(Territory_Member__c terrMem : [Select Id, Territory__c, Type__c, User__c, Territory__r.Country__c, Territory__r.Country__r.Code__c from Territory_Member__c
                                               where Type__c = 'Primary' and Start_Date__c <= Today and (End_Date__c = null OR End_Date__c >= Today) 
                                               and User__c IN: lstUserId]){
                                                   mapTerritoryDetails.put(terrMem.User__c,terrMem.Territory__c);  
                                                   setCountryCode.add(terrMem.Territory__r.Country__r.Code__c);
                                               }
            
        }
        
        //Retrieve all the Stock with Record Type Allocation of respective Product selected on Order Line Item 
        if(Schema.SObjectType.Stock__c.isAccessible() && Schema.SObjectType.Market_Setting__c.isAccessible()){
            List<Market_Setting__c> lstWarehouseLevel = [SELECT ID, Geography__c, Geography__r.Code__c, Warehouse_Level__c FROM Market_Setting__c WHERE Geography__r.Code__c IN :setCountryCode LIMIT 1];
            List<Stock__c> lstStock = new List<Stock__c>();
            
            if(lstWarehouseLevel != null && lstWarehouseLevel.size()>0){
                if(lstWarehouseLevel[0].Warehouse_Level__c){
                    for(Outlet_Territory__c outletTerritory : [SELECT Outlet__c, Outlet__r.Area__c FROM Outlet_Territory__c WHERE Outlet__r.Status__c='Active' AND Outlet__r.Country__r.Code__c IN :setCountryCode AND Territory__c IN :mapTerritoryDetails.values()]){
                        setArea.add(outletTerritory.Outlet__r.Area__c);                        
                    } 
                    lstStock = [SELECT Name, Allocated_Available__c, RecordTypeId, RecordType.Name, Product__c, 
                                Territory__c, Stock_Available__c,Country__c, Type__c, Consumed_Stock__c
                                FROM Stock__c 
                                WHERE Type__c = 'Territory/Rep' AND Product__c IN :mapProductIdOrderItem.keySet() AND RecordTypeId =:recordTypeId AND 
                                Area__c IN :setArea
                               ];
                    
                } else {
                    lstStock = [SELECT Name, Allocated_Available__c, RecordTypeId, RecordType.Name, Product__c, 
                                Territory__c, Stock_Available__c,Country__c, Type__c, Consumed_Stock__c
                                FROM Stock__c 
                                WHERE Type__c = 'Territory/Rep' AND Product__c IN :mapProductIdOrderItem.keySet() AND RecordTypeId =:recordTypeId AND 
                                Country__r.Code__c IN :setCountryCode
                               ]; 
                }                
            }
            
            //Create a mapping of LineItem and Outlet
            if(lstStock != null && lstStock.size()>0){                
                for(Stock__c existStock : lstStock){
                    if(mapProductIdOrderItemlst.containsKey(existStock.Product__c)){
                        for(Order_Item__c orderItem : mapProductIdOrderItemlst.get(existStock.Product__c)){
                            if(orderItemMap != null && orderItemMap.size()>0){//Service scenario
                                createdById = salesRepItemMap.get(orderItem);
                            }else{
                                createdById = orderItem.CreatedById;  
                            }
                            //Depending on the Stock Type it will execute different if else block. 
                            if(existStock.Territory__c != null && 
                               ((createdById != null && mapTerritoryDetails.containsKey(createdById) &&   
                                 mapTerritoryDetails.get(createdById) != null && 
                                 mapTerritoryDetails.get(createdById) == existStock.Territory__c) )                                     
                              ){
                                  setOrderItem.add(orderItem);
                                  if(orderItem.Quantity__c > existStock.Allocated_Available__c){
                                      mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                      mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                  } else {
                                      mapLineItemToStock.put(orderItem.Id, existStock);
                                      mapLineItemValidation.remove(orderItem);
                                      
                                  }                                       
                              } else if(!setOrderItem.contains(orderItem)){
                                  mapLineItemValidation.put(orderItem, 'No Stock Record Found');
                              }
                        } 
                    }
                }
            }else {
                if(orderItemMap != null && orderItemMap.size()>0){
                    for(Order_Item__c orderItem : orderItemMap.KeySet()){
                        mapLineItemValidation.put(orderItem,'No Stock Record Found');                    
                    }                    
                }                                        
            }
        }
        return mapLineItemValidation;
    }
    /**


* @method   createStockMovementOrderList
* @description : If Order pass product and stock validation create the List of Order 
* This will update the Warehouse Allocated Quantity related to order product(ES20-4499)
* @return Map
* @param map


*/
    public static Map<Id,Order__c> createStockMovementOrderList(Map<Order_Item__c, String> mapLineItemValidation){
        Map<Id,Order__c> mapParentOrder= new Map<Id,Order__c>();
        Set<Id> setAllLineItem = new Set<Id>();
        
        
        //Create the List of all order held line item
        if(mapLineItemValidation != null && mapLineItemValidation.size()>0){
            for(Order_Item__c orderItem : mapLineItemValidation.keySet()){
                if(mapLineItemToOrderId.containsKey(orderItem.Id)){
                    String orderId = mapLineItemToOrderId.get(orderItem.Id);                    
                    setAllLineItem.addAll(mapOrderToLineItem.get(orderId));  
                    
                    if(mapChildOrderToParent.containsKey(orderId)){
                        Id parentId = mapChildOrderToParent.get(orderId);
                        lstUpdateOrder.add(parentId); //Added Parent record
                        
                        //Get all the child whose parent is in Order Held status
                        
                        lstUpdateOrder.addAll(mapParentToChildOrder.get(parentId));
                        if(lstUpdateOrder != null && lstUpdateOrder.size()>0){
                            for(Id childOrderId : mapParentToChildOrder.get(parentId)){
                                setAllLineItem.addAll(mapOrderToLineItem.get(childOrderId));
                            }
                        }
                        
                    } else {
                        lstUpdateOrder.add(orderId);
                    }                    
                }
            }
        }
        List<Id> newLstUpdateOrder = new List<Id>(new Set<Id>(lstUpdateOrder));
        lstUpdateOrder.clear();
        lstUpdateOrder = newLstUpdateOrder ;
        
        
        //Attach Stock and update the Consumed Stock in the stock (ES20-4499) and pass the date to next method
        if(mapLineItemToStock != null && mapLineItemToStock.size() > 0){
            for(String orderItemId : mapLineItemToStock.keySet()){
                if(!(setAllLineItem.contains(orderItemId) || 
                     (mapLineItemToOrderId.containsKey(orderItemId) && lstUpdateOrder.contains(mapLineItemToOrderId.get(orderItemId)))
                    )){                      
                        Stock__c stock = mapLineItemToStock.get(orderItemId);
                        Order_Item__c orderItem = mapOrderLineItem.get(orderItemId);
                        stock.Consumed_Stock__c = stock.Consumed_Stock__c != null ? (stock.Consumed_Stock__c+orderItem.Quantity__c) : orderItem.Quantity__c;
                        orderItem.Stock__c = mapLineItemToStock.get(orderItem.Id).Id;
                        lstUpdatedStock.add(stock);
                        
                        
                        //Update the stock in line item
                        orderItem.Stock__c = stock.Id;
                        orderItem.Status__c = 'Ready for Order'; 
                        lstUpdateOrderLineItem.add(orderItem);
                        
                        Order__c order = mapNewOrder.get(orderItem.Order__c);
                        Order__c newOrderObj= new Order__c(id=order.id);
                        newOrderObj.status__c='Ready for Order';
                        lstAllUpdatedOrder.add(newOrderObj);
                        
                        if(mapLineItemToOrderId.containsKey(orderItemId) && mapNewOrder.containsKey(mapLineItemToOrderId.get(orderItemId))){
                            Id orderId = mapLineItemToOrderId.get(orderItemId);
                            mapParentOrder.put(orderId, mapNewOrder.get(orderId));
                        } else if(mapLineItemToOrderId.containsKey(orderItemId) && !mapNewOrder.containsKey(mapLineItemToOrderId.get(orderItemId)) && 
                                  mapChildOrderToParent.containsKey(mapLineItemToOrderId.get(orderItemId)) && 
                                  mapNewOrder.containsKey(mapChildOrderToParent.get(mapLineItemToOrderId.get(orderItemId)))
                                 ){
                                     Id orderId = mapChildOrderToParent.get(mapLineItemToOrderId.get(orderItemId));
                                     mapParentOrder.put(orderId, mapNewOrder.get(orderId));                            
                                 }
                    }
            }
            List<Order_Item__c> newLstReadyforOrderItem = new List<Order_Item__c>(new Set<Order_Item__c>(lstUpdateOrderLineItem));
            lstUpdateOrderLineItem.clear();
            lstUpdateOrderLineItem = newLstReadyforOrderItem ;
            
            List<Order__c> newLstReadyforOrder = new List<Order__c>(new Set<Order__c>(lstAllUpdatedOrder));
            lstAllUpdatedOrder.clear();
            lstAllUpdatedOrder = newLstReadyforOrder ;
            
        }
        
        
        return mapParentOrder;
    }
    
  /**


* @method   createOrderHeldTemplate
* @description  To create Template for the Status OrderHeld
* @param string
* @return messaging


*/
    public static Messaging.SingleEmailMessage createOrderHeldTemplate(String orderId){
        Order__c order;
        Stock__c stock;
        Stock__c invalidStock;
        
        List<Id> lstOrderItemId = mapOrderToLineItem.get(orderId); 
        if(mapNewOrder.containsKey(orderId)){
            order = mapNewOrder.get(orderId);            
        } else if(mapChildOrderToParent.containsKey(orderId)){
            order = mapNewOrder.get(mapChildOrderToParent.get(orderId));
        }
        
        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
        
        mail.setSubject(Label.Email_Subject);
        String body = Label.Order_Held_Date+': ' + order.CreatedDate + '<br/>';
        body += Label.Order_Held_Name+': '+ order.Name + '<br/>';
        if(lstOrderItemId != null && lstOrderItemId.size()>0){
            body += Label.Order_Held_Outlet+': '+ (mapOrderLineItem.get(lstOrderItemId[0])).Order__r.Account__r.Name +'<br/>';
            if(mapLineItemToStock.size() > 0 || mapLineItemToInvalidStock.size() > 0 ){
                body += Label.Body_Header;
            }else{
                body += Label.EDGE_LimitPerOrderHeader;
            }
            if(mapLineItemToStock.size() > 0 || mapLineItemToInvalidStock.size() > 0 ){
                body += '<table style="width:100%"> <tr style="border:1px solid black"> <th style="border:1px solid black">'+Label.Order_Held_Product+'</th> <th style="border:1px solid black">'+Label.Order_Held_QtyOrd+'</th> <th style="border:1px solid black">'+Label.Order_Held_StockAvalble+'</th> </tr>';  
            }else{
                body += '<table style="width:100%"> <tr style="border:1px solid black"> <th style="border:1px solid black">'+Label.Order_Held_Product+'</th> <th style="border:1px solid black">'+Label.Order_Held_QtyOrd+'</th> <th style="border:1px solid black">'+Label.Order_Held_LimitPerOrder+'</th> </tr>';
            }
            
            mail.setToAddresses(new List<String> {(mapOrderLineItem.get(lstOrderItemId[0])).CreatedBy.Email});
            for(Id orderItemId : lstOrderItemId){
                if(mapLineItemToStock.containsKey(orderItemId)){
                    stock = mapLineItemToStock.get(orderItemId);
                }
                if(mapLineItemToInvalidStock.containsKey(orderItemId)){
                    invalidStock = mapLineItemToInvalidStock.get(orderItemId); 
                }
                Order_Item__c orderItem = mapOrderLineItem.get(orderItemId);
                body += '<tr style="border:1px solid black">';
                body += '<td style="border:1px solid black">'+orderItem.Product__r.Name+'</td>';
                body += '<td style="border:1px solid black">'+orderItem.Quantity__c+'</td>';
                if(stock != null ){
                    body += '<td style="border:1px solid black">'+stock.Stock_Available__c+'</td>';
                } else if(invalidStock != null){
                    body += '<td style="border:1px solid black">'+invalidStock.Stock_Available__c+'</td>';
                } else{
                    body += '<td style="border:1px solid black">'+orderItem.Product__r.Limit_Per_Order__c+'</td>';
                }                
                body += '</tr>';
            } 
            body += '</table>';
        }
        
        
        //body += Label.Order_Held_Email_Body_Footer+'<a href='+Label.EmailTemplateURL+order.Id+'>Link</a>';
        body += Label.Order_Held_Email_Body_Footer+'<a href='+URL.getOrgDomainURL().toExternalForm()+'/'+order.Id+'>Link</a>';//366446
        mail.setHtmlBody(body);        
        return mail;
    }
    
    /**

* @method   performAllDML
* @description : This will be used to perform all DML and send Email

*/
    public static void performAllDML(){
        
        if(lstUpdateOrderLineItem != null && lstUpdateOrderLineItem.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
            Database.update(lstUpdateOrderLineItem);
        }
        
        //Update the Order Status
        if(lstAllUpdatedOrder != null && lstAllUpdatedOrder.size()>0 && Schema.sObjectType.Order__c.isUpdateable()){
            Database.update(lstAllUpdatedOrder);  
        }  
        
        //Update the Stock consumed quantity
        if(lstUpdatedStock != null && lstUpdatedStock.size()>0 && Schema.sObjectType.Stock__c.isUpdateable()){
            Database.update(lstUpdatedStock);
        } 
        
        //Send Email in case A&P Validation Fails
        if(lstAllSingleEmail.size()>0){
            Messaging.sendEmail(lstAllSingleEmail, false);
        } 
    }
    
    
    public static Decimal checkForNull(Decimal kpiValue){
        return EDGE_UtilityClass.checkForNull(kpiValue);
    } 
    
    
    /**

* @Method   shedQuantityForStockMovement
* @description  To update shed quantity when status is receivd

*/ 
    /*public static void shedQuantityForStockMovement(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){ 
        
        Set<Id> orderIdSet = new Set<Id>();
        List<Stock__c> stockListToUpdate = new List<Stock__c>();
        Map<Id,Order__c> oldOrderMap = new Map<Id,Order__c>(); 
        Map<Id,Order__c> newOrderMap = new Map<Id,Order__c>(); 
        Map<Id, Map<Id, Decimal>> shedWithDelQtyMap = new Map<Id, Map<Id, Decimal>>();
       
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order__c>)oldItems;
        } 
        newOrderMap = (Map<Id,Order__c>)newItems;
        for(Id ordId : newOrderMap.keySet()){
            if(newOrderMap.get(ordId).recordTypeId == stockMovementRecordTypeId && oldOrderMap.get(ordId).Status__c!= 'Delivered to Shed' && newOrderMap.get(ordId).Status__c == 'Delivered to Shed'){
                orderIdSet.add(ordId);
            }
        }
        
        if(orderIdSet != null && orderIdSet.size()>0){ //Added by Preyanka If condition
            for(Order_Item__c ordItem : [SELECT Id,Product__c,Order__r.Account__c,Delivered_Quantity__c FROM Order_Item__c WHERE Order__c IN: OrderIdSet]){
                Id shedId = ordItem.Order__r.Account__c;
                Id productId = ordItem.Product__c;
                if(shedWithDelQtyMap.containsKey(shedId)){
                    shedWithDelQtyMap.get(shedId).put(productId,ordItem.Delivered_Quantity__c);
                }
                else{
                    shedWithDelQtyMap.put(shedId, new Map<Id,Decimal> {productId => ordItem.Delivered_Quantity__c});
                }
            }            
        }
        
        if(shedWithDelQtyMap != null && shedWithDelQtyMap.size()>0){ //Added by Preyanka If condition
            for(Stock__c stock : [SELECT Id,Product__c,Original_Stock__c,Shed__c FROM Stock__c WHERE Shed__c IN: shedWithDelQtyMap.keySet() AND recordTypeId = :shedRecordTypeId ]){
                if(shedWithDelQtyMap.get(stock.Shed__c).containsKey(stock.Product__c)){
                    Decimal originalStock = stock.Original_Stock__c + shedWithDelQtyMap.get(stock.Shed__c).get(stock.Product__c);
                    stock.Original_Stock__c = originalStock;
                    stockListToUpdate.add(stock);                  
                }
            }            
        }
        
        
        if(stockListToUpdate.size()>0 && Schema.sObjectType.Stock__c.isUpdateable()){
            update stockListToUpdate;
        }
    }*/
    
    
    /**


* @ethod   shedStockOperations
* @description  To the stocks for order products
* @param map, map
* @return null


*/ 
    public static void shedStockOperations(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){ 
        
        Set<Id> adjOrderIds = new Set<Id>();
        //Anamika ES20-10488
        Set<Id> stckmvtOrderIdSet = new Set<Id>();
        List<Stock__c> stockListToUpdate = new List<Stock__c>();
        Map<Id,Order__c> oldOrderMap = new Map<Id,Order__c>(); 
        Map<Id,Order__c> newOrderMap = new Map<Id,Order__c>(); 
        Map<Id, Map<Id, Decimal>> shedProdQtyMap = new Map<Id, Map<Id, Decimal>>();// Map of Shed id , product Id , and quantity
        Map<Id, Map<Id, Decimal>>shedMrktProdQtyMap = new Map<Id, Map<Id, Decimal>>();// Map of shed Id , Market Assrtment Id and quantity
        set<String> countryCodeSet = new  set<String>();
         Map<Id,Id> shedSalesRepIdMap = new Map<Id,Id>();// New Map Defect -
        Id  countryId ;
        
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order__c>)oldItems;
        }
        newOrderMap = (Map<Id,Order__c>)newItems;
        
        for(Id orderId : newOrderMap.keySet()){
            if(newOrderMap.get(orderId).recordTypeId == stockAdjRecordTypeId && oldOrderMap.get(orderId).Status__c != 'Delivered to Shed' && newOrderMap.get(orderId).Status__c == 'Delivered to Shed'){
                adjOrderIds.add(orderId);
            }
            //ES20-10488
           if(newOrderMap.get(orderId).recordTypeId == stockMovementRecordTypeId && oldOrderMap.get(orderId).Status__c != 'Delivered to Shed' && newOrderMap.get(orderId).Status__c == 'Delivered to Shed'){
                stckmvtOrderIdSet.add(orderId);
            }
                countryCodeSet.add(newOrderMap.get(orderId).Country_Code__c);
                Id shedId = newOrderMap.get(orderId).Account__c;
                
                if(!shedSalesRepIdMap.containsKey(shedId)){
                    Id SalesRepId = newOrderMap.get(orderId).Sales_Representative__c != null ? newOrderMap.get(orderId).Sales_Representative__c : UserInfo.getUserId();
                    shedSalesRepIdMap.put(shedId,SalesRepId);
                }
            }
        
        if(countryCodeSet != null && countryCodeSet.Size()>0){
            countryId = [Select Id from Geography__c where code__c =:countryCodeSet Limit 1].Id;    
        }
        //ES20-10488
        if((adjOrderIds != null && adjOrderIds.size()>0)||(stckmvtOrderIdSet!= null && stckmvtOrderIdSet.size()>0)){//Added by Preyanka If condition
            
            for(Order_Item__c orderItem : [SELECT Id,Product_Record_Type__c, Status__c,Product__c, Quantity__c,Delivered_Quantity__c, Order__r.Account__c FROM Order_Item__c WHERE Order__c IN :adjOrderIds OR Order__c IN :stckmvtOrderIdSet]){

                Id shedId = orderItem.Order__r.Account__c;
                Id productId = orderItem.Product__c;
               	
                //ES20-11020
                // Checking first conddition if the product record type is not pos , then creating MAp to check with Market Assortment product 
                if(adjOrderIds != null && adjOrderIds.size()>0){
                if(orderItem.Product_Record_Type__c != 'POS'){
                    if(shedMrktProdQtyMap.containsKey(shedId)){
                        //Added for Quantity Mismatch incase of Similar Order Products -  US-2876871
                        
                        if(shedMrktProdQtyMap.get(shedId).containsKey(orderItem.Product__c)){
                            shedMrktProdQtyMap.get(shedId).put(orderItem.Product__c, orderItem.Quantity__c + shedMrktProdQtyMap.get(shedId).get(orderItem.Product__c));
                        }
                        else{
                            shedMrktProdQtyMap.get(shedId).put(orderItem.Product__c, orderItem.Quantity__c);
                        }


                    }else{
                        shedMrktProdQtyMap.put(shedId, new Map<Id, Decimal> { orderItem.Product__c => orderItem.Quantity__c });
                    } 
                }
                // Checking second conddition if the product record type is pos , then creating Map to check with product 
                else {
                    if(shedProdQtyMap.containsKey(shedId)){
                        shedProdQtyMap.get(shedId).put(orderItem.Product__c, orderItem.Quantity__c);
                    }else{
                        shedProdQtyMap.put(shedId, new Map<Id, Decimal> { orderItem.Product__c => orderItem.Quantity__c });
                    }    
                }
                
            }            
                if(stckmvtOrderIdSet!= null && stckmvtOrderIdSet.size()>0){
                    Decimal deliveredQty = 0;
                    if(orderItem.Delivered_Quantity__c != null && orderItem.Delivered_Quantity__c > 0){
                        deliveredQty = orderItem.Delivered_Quantity__c;
                    }
                    if(orderItem.Product_Record_Type__c != 'POS'){
                        if(shedMrktProdQtyMap.containsKey(shedId)){
                            shedMrktProdQtyMap.get(shedId).put(orderItem.Product__c, deliveredQty);
                        }else{
                            shedMrktProdQtyMap.put(shedId, new Map<Id, Decimal> { orderItem.Product__c => deliveredQty });
                        }
        			}

                    // Checking second conddition if the product record type is pos , then creating Map to check with product 
                    else {
                        if(shedProdQtyMap.containsKey(shedId)){
                            shedProdQtyMap.get(shedId).put(orderItem.Product__c,deliveredQty);
                        }else{
                            shedProdQtyMap.put(shedId, new Map<Id, Decimal> { orderItem.Product__c => deliveredQty});
                        }
                    }
                    
                }
                
            }            
        }

      
        // Handling when we have the Map of Product for POS record types 
        if(shedProdQtyMap != null && shedProdQtyMap.size()>0){ //Added by Preyanka If condition
            //ES20-10488
            for(Stock__c stockRec : [SELECT Id, Product__c, Original_Stock__c, Shed__c FROM Stock__c WHERE recordTypeId = :shedRecordTypeId AND Shed__c IN :shedProdQtyMap.keySet()]){
                if(shedProdQtyMap.get(stockRec.Shed__c) != null && shedProdQtyMap.get(stockRec.Shed__c).containsKey(stockRec.Product__c)){
                    Decimal originalStock = checkForNull(stockRec.Original_Stock__c) + shedProdQtyMap.get(stockRec.Shed__c).get(stockRec.Product__c);            
                    if(originalStock >= 0){
                        stockRec.Original_Stock__c = originalStock;
                    }else{
                        stockRec.Original_Stock__c = 0.00;
                    }
                    stockListToUpdate.add(stockRec);   
                    // remove processed keys for those orders  which have matching shed => Manikant 
                    
                    shedProdQtyMap.get(stockRec.Shed__c).remove(stockRec.Product__c);          
                }   
            }            
        }
       
        // Updating those stocks which we modified in the above loop
        if(stockListToUpdate != null && stockListToUpdate.size() >0 && Schema.sObjectType.Stock__c.isUpdateable()){
            update stockListToUpdate;
        }
     
        // Create New shed stock for those orders for which stock was not found
        if(shedProdQtyMap != null && shedProdQtyMap.size() > 0){
            Boolean isProduct = True; // this boolean value to make sure that we are calling createNewShedStock method for  products
            createNewShedStock(shedProdQtyMap,countryId ,isProduct,shedSalesRepIdMap);
        }
      
        // Check/Create stocks for those which had map of Market Assortment product(i.e NON POS products)
        if(shedMrktProdQtyMap != null && shedMrktProdQtyMap.size() >0 ){
            checkShedStockForMarketAssortment(shedMrktProdQtyMap,countryId,shedSalesRepIdMap);
        }
     
    }
    /**


* @Author  Manikant 
* @Method  checkShedStockForMarketAssortment 
* @description  This Method will check if there is existing stock having the combination of Shed and Market Assortment Product 
* @param map,id, map
* @return null
**/


    
    Public static void checkShedStockForMarketAssortment( Map<Id, Map<Id, Decimal>> shedProdQtyMap ,Id countryId, Map<Id,Id> shedSalesRepIdMap){
        Map<Id,Id> ProductShedIdMap = new Map<Id,Id>(); // Map of Product id and shed Id       
        Map<Id, Map<Id, Decimal>> shedMarketAsstQntyMap = new Map<Id, Map<Id, Decimal>>(); // map of shed id , Market assortment Id and Quantity Id 
        List<Stock__c> stockListToUpdate = new List<Stock__c>();// Map of stock to update
        for(Id shedId : shedProdQtyMap.keySet()){
            Map<Id,Decimal> productQuantityMap = shedProdQtyMap.get(shedId);
            for(ID productId : productQuantityMap.keySet()){
                ProductShedIdMap.put(productId,shedId) ;
            }
        } 
        
        
        if(ProductShedIdMap.size() > 0 ){
            for(Market_Assortment_Product__c mapRec : [Select Id , Name , Product__c  FROM Market_Assortment_Product__c where Product__c IN : ProductShedIdMap.keySet() AND Market_Assortment__c =:countryId ]){
                // Creating a Map with shed , Market Assortment and Qunatity
                if(shedMarketAsstQntyMap.containsKey(ProductShedIdMap.get(mapRec.Product__c))){
                    shedMarketAsstQntyMap.get(ProductShedIdMap.get(mapRec.Product__c)).put(mapRec.Id, shedProdQtyMap.get(ProductShedIdMap.get(mapRec.Product__c)).get(mapRec.Product__c));
                }else{
                    shedMarketAsstQntyMap.put(ProductShedIdMap.get(mapRec.Product__c) , new Map<Id,Decimal>{mapRec.Id =>shedProdQtyMap.get(ProductShedIdMap.get(mapRec.Product__c)).get(mapRec.Product__c) });
                }
            } 
        }
        System.debug('shedMarketAsstQntyMap:::'+shedMarketAsstQntyMap);
        System.debug('shedProdQtyMap:::'+shedProdQtyMap);
        
        // Checking if there is existing stock for the combination of Shed and Market assortment product 
        if(shedMarketAsstQntyMap != null && shedMarketAsstQntyMap.size() > 0 ){
            for(Stock__c stockRec : [SELECT Id, Product__c, Original_Stock__c,Market_Assortment_Product__c, Shed__c FROM Stock__c WHERE recordTypeId = :shedRecordTypeId AND Shed__c IN :shedMarketAsstQntyMap.keySet()]){
                if(shedMarketAsstQntyMap.get(stockRec.Shed__c).containsKey(stockRec.Market_Assortment_Product__c)){
                    Decimal originalStock = checkForNull(stockRec.Original_Stock__c) + shedMarketAsstQntyMap.get(stockRec.Shed__c).get(stockRec.Market_Assortment_Product__c);   
                    if(originalStock >= 0){
                        stockRec.Original_Stock__c = originalStock;
                    }else{
                        stockRec.Original_Stock__c = 0.00;
                    }
                    stockListToUpdate.add(stockRec);
                    // Removing processes key for which we already have stocks 
                    shedMarketAsstQntyMap.get(stockRec.Shed__c).remove(stockRec.Market_Assortment_Product__c);
                }
            }
        }
        
        // Updating the stocks for which there was matching combination of stocks
        if(stockListToUpdate != null && stockListToUpdate.size() >0 && Schema.sObjectType.Stock__c.isUpdateable()){
            update stockListToUpdate;
        }
        // If existing stock was not found for those shed then creating new stocks 
        if(shedMarketAsstQntyMap != null && shedMarketAsstQntyMap.size() > 0){
            Boolean isProduct = False; // this boolean value to make sure that we are calling createNewShedStock method for Market Assortment products
            createNewShedStock(shedMarketAsstQntyMap, countryId ,isProduct,shedSalesRepIdMap);   
        }
    }
    
  /**


* @author  Manikant 
* @method  createNewShedStock
* @description  for those order which there was no matching stocks we are creating new stocks here
* @param map,Id, boolean, map
* @return void
 **/


    
    public static void createNewShedStock(Map<Id, Map<Id, Decimal>> shedProdQtyMap , Id countryId , Boolean isProduct ,Map<Id,Id> shedSalesRepIdMap){
        
        List<Stock__c> stockListToCreate = new List<Stock__c>();// list to create  stocks
        if(shedProdQtyMap != null && shedProdQtyMap.Size() >0 ){
            for(Id shedId : shedProdQtyMap.keySet()){
                Map<Id,Decimal> productQuntyMap = shedProdQtyMap.get(shedId);
                for(Id productId : productQuntyMap.keySet()){		//US-2876871
                    Stock__c stockRec = new Stock__c();
                    stockRec.Shed__c = shedId;
                    stockRec.RecordTypeId = shedRecordTypeId;
                    stockRec.Country__c  = countryId ;
                    stockRec.Sales_Rep__c = shedSalesRepIdMap.get(shedId);
             	 	// for(Id productId : productQuntyMap.keySet()){     //US-2876871
                    stockRec.Original_Stock__c = productQuntyMap.get(productId);
                    // If method was called for product combination
                    if(isProduct){
                        stockRec.Product__c = productId;
                    }
                    // If method was called for Market Assortment product combination
                    else{
                        stockRec.Market_Assortment_Product__c = productId;  
                    }
                    stockListToCreate.add(stockRec);
                }
                //stockListToCreate.add(stockRec); //US-2876871
            }  
        }
        // Trying to crrate new stocks
        try{
            Database.insert(stockListToCreate,False); 
        }catch(Exception ex){
            system.debug('ex-- '+ex.getLineNumber()+' '+ex.getMessage()+' '+ex.getCause());
        }
        
    }



/**
* @method  stockMovementOrdStatusUpdate - ES20-10481
* @description  To update the stockMovement Order status to Ready for Order or Order Held based on Territory 
*            Budget check.
* @param map, map
* @return void


    */
    public static void stockMovementOrdStatusUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        Map<Id, Order__c> oldOrderMap;
        Map<Id,Id> orderSalesRepIdMap = new Map<Id,Id>();
        Map<Id, Id> salesRepTerritoryIdMap = new Map<Id, Id>();
        Map<Id, Territory_Budget__c> terrBudgetMap = new Map<Id,Territory_Budget__c>();
        List<Order__c> updateOrderList = new List<Order__c>();
        List<Territory_Budget__c> updateTerrBudgetList = new List<Territory_Budget__c>();
        List<Order__c> stockMovementOrderList = new List<Order__c>();
        Date todayDate = Date.today();
        List<Order__c> orderStatusDelPart = new List<Order__c>();
        Map<Id,Order__c> orderTobeMailedMap = new Map<Id,Order__c>(); 
        
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order__c>)oldItems;
        }
        for(sObject obj : newItems.values()){
            Order__c newOrder = (Order__c)obj;
            if(newOrder.RecordTypeId == stockMovementRecordTypeId && newOrder.Status__c == EDGE_Constant.ORDER_SUBMITTED 
               && newOrder.Status__c != oldOrderMap.get(newOrder.Id).Status__c){
                   stockMovementOrderList.add(newOrder);
                   orderSalesRepIdMap.put(newOrder.Id,newOrder.Sales_Representative__c );   
               }
        }
        if(orderSalesRepIdMap.size()>0){
            for(Territory_Member__c  terrMem : [SELECT Id,Territory__c, Territory__r.RecordTypeId,User__c, Start_Date__c,End_Date__c, Type__c  from
                                                Territory_Member__c where ((Start_Date__c <=: todayDate ) AND 
                                                ((End_Date__c != null AND End_Date__c >=: todayDate) OR End_Date__c = null))
                                                AND Territory__r.RecordTypeId =:salesTerritoryRecordTypeId 
                                                AND Type__c = 'Primary' AND User__c IN : orderSalesRepIdMap.values()]){
             salesRepTerritoryIdMap.put(terrMem.User__c, terrMem.Territory__c);   
            }
        }
        //Get Territory Budget and create a map of Territory Id and Territory Budget
        if(salesRepTerritoryIdMap.size()>0){//orderIdTerritoryIdMap.size()>0
            for(Territory_Budget__c terrBudg : [SELECT Id, Name, Territory__c ,Spent_Amount__c, Amount_Availlable__c, Initial_Amount__c,
                                                Start_Date__c, End_Date__c FROM Territory_Budget__c WHERE RecordTypeId =:freeGoodTerrBudgetRecordTypeId
                                                AND (Start_Date__c <=: todayDate AND End_Date__c >=: todayDate)  AND Territory__c  IN :salesRepTerritoryIdMap.values()])//AND Territory__c  IN :accountTerritoryIdMap.values()]) //AND Territory__c  IN :orderIdTerritoryIdMap.values()])
            {
                terrBudgetMap.put(terrBudg.Territory__c, terrBudg);
            }
        }
        //Validate & Process Stock Movement Order
        if(stockMovementOrderList.size()>0){
            for(Order__c orderObj : stockMovementOrderList){    
                Order__c updateOrder = new Order__c(Id = orderObj.id);
                Id terrRecId;
                Territory_Budget__c terrBudget;
                Id salesRepId = orderSalesRepIdMap.get(updateOrder.Id);
                if(salesRepId != null){
                    terrRecId = salesRepTerritoryIdMap.get(salesRepId);
                }
                if(terrRecId != null){
                    terrBudget = terrBudgetMap.get(terrRecId)!=null ? terrBudgetMap.get(terrRecId) : null;
                }
                Decimal orderCost = EDGE_UtilityClass.checkForNull(orderObj.Total_A_P_Cost__c);
                Decimal terrBudgetAmt = terrBudget!=null ? EDGE_UtilityClass.checkForNull(terrBudget.Amount_Availlable__c) : 0;
                //Check Order Amount w/ Territory Budget Amount
                if(terrBudget != null && orderCost <= terrBudgetAmt){
                    updateOrder.Status__c = 'Ready For Order';
                    updateOrderList.add(updateOrder);
                    orderTobeMailedMap.put(updateOrder.Id, updateOrder);
                    //Update Territory Budget 
                    terrBudget.Spent_Amount__c = EDGE_UtilityClass.checkForNull(terrBudget.Spent_Amount__c) + orderCost;
                    updateTerrBudgetList.add(terrBudget);
                }else{
                    updateOrder.Status__c = 'Order Held';
                    updateOrderList.add(updateOrder);
                }   
            }  
            if(Schema.sObjectType.Order__c.isUpdateable() && updateOrderList.size()>0){                
                update updateOrderList;
            }
            if(orderTobeMailedMap != null && !orderTobeMailedMap.isEmpty()){
                EDGE_StockMovementOrderMailHandler.getOrderDetails(orderTobeMailedMap);
            }
            if(updateTerrBudgetList.size()>0 && Schema.sObjectType.Territory_Budget__c.isUpdateable()){
                update updateTerrBudgetList;
            }           
        }
    }
}