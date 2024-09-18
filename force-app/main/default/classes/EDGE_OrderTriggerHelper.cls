/*
@Name: EDGE_OrderTriggerHelper
@Purpose: Trigger Helper Class for OrderTriggerHandler
@History:                                                            

@VERSION   AUTHOR              DATE              DETAIL
1.0       Dipanjan Das        26/06/2019        ES20-2247, ES20-2248
2.0       Preyanka Ghosh      27/06/2019        ES20-2249, ES20-2250
3.0       Sagar Barman        02/07/2019        ES20-2246(syncOrderStatus method)       
4.0       Monalisa Halder     02/07/2019        ES20-2261,2263
5.0       Srutadeba Chanda    08/07/2019        ES20-2253
6.0       Preyanka Ghosh      27/06/2019        ES20-3003, ES20-3004
7.0       Anuja Chattopadhyay 07/10/2019        ES20-4606(modification done in sendEmailToDelPart method)
8.0       Sagar Barman        04/11/2019        ES20-4636(sendEmailForOrderSubmtd method)  
9.0       Preyanka Ghosh      11/12/2019        ES20-4649
10.0      Juned Khan          21/12/2019        ESP-362 
11.0      Ankit Das           27/01/2020        ES20-6910 (Introduction of two DateTime fields in sendEmailToDelPart())
12.0      Sandip Ghosh        12/06/2020        ES20-8150(updateWholesalerAccNum)
13.0      Bhargav S           09/07/2020 .      US-0013670 - Validation skip for 0$ cost orders
14.0      Divya Bansal        24/02/2021        ES20-9289
15.0	  Kapil Baliyan       15/03/2021        NCP-2091 (orderValidation)
16.0      Amar Deep           11/05/2021        NCP-2677
17.0      Praveen M           24/11/2021        NCP-5088
18.0      Supriya             10/05/2022        ES20-12621
19.0      Rajarshi Lahiri     12/15/2022        ES20-12641
20.0      Anand U             13/05/2022        ES20-12619(sendPOSOrderPushNotification) 
21.0      Aparajita           22/06/2022		ES20-12674(Added block for Other delivery location for POS orders)
22.0      Rajarshi Lahiri     18/07/2022		ES20-12957(added method rollUpPromoUsed)
23.0      Monalisa Halder     05/08/2022        ES20-13180(Separate CSV Mails for Delivery Partners)
24.0      Rajarshi Lahiri     24/08/2022        ES20-13259
25.0      Rajarshi Lahiri     31/08/2022        ES20-13264
26.0      Rajarshi Lahiri     05/09/2022        ES20-13283
27.0      Prasanth T          15/11/2022        ES20-13081
28.0      Sandeep Bhowmik     11/12/2023        147120 (validateStockQuantity, productOrderItemRange)
29.0      Kapil Baliyan       28/01/2024        150478
30.0      Anamika Shukla      09/05/2024        366446 EDGE_Global: Allow Only Trusted Cross-Org Redirections
*/
public without sharing class EDGE_OrderTriggerHelper {
    
    /*Global Map*/
    private static Map<Id, Order__c> mapNewOrder = new Map<Id, Order__c>(); //Used to contains all submitted data of Record type POS or POS Group
    private static Map<Id, Id> mapChildOrderToParent = new Map<Id,Id>(); //Used to contains mapping of Child POS Order id to Parent Group POS order id
    private static Map<Id, List<Id>> mapParentToChildOrder = new Map<Id,List<Id>>(); //Mapping of Parent Group POS order id and List child order
    private static Map<Id, Id> mapLineItemToOrderId = new Map<Id, Id>(); //Mapping of Line Item to Order 
    private static Map<Id, List<Id>> mapOrderToLineItem = new Map<Id, List<Id>>(); //Order and all line Item
    private static Map<Id, Stock__c> mapLineItemToStock = new Map<Id, Stock__c>(); //Mapping between Order line item and stock
    private static Map<Id, Stock__c> mapLineItemToInvalidStock = new Map<Id, Stock__c>(); //Mapping between Order line item and stock
    private static Map<Id, Order_Item__c> mapOrderLineItem = new Map<Id, Order_Item__c>();
    private static Map<String, Order_Validation_Per_Country__mdt> mapOrderValidation = new Map<String, Order_Validation_Per_Country__mdt>();
    
    public static Map<String, List<Order_Item__c>> mapProductOrderItemShed = new Map<String,List<Order_Item__c>>(); //Mapping of Product and LI of Shed Type
    public static Map<String, List<Order_Item__c>> mapProductOrderItemWare = new Map<String,List<Order_Item__c>>(); //Mapping of Product and LI of Warehouse Type
    
    /*Global String*/
    private static String posRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
    private static String posGroupRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order Group').getRecordTypeId();
    private static String stockMovementRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
    private static String stockMovementGroupRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement Group').getRecordTypeId();
    private static String stockAdjRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
    private static String freeGoodsRecordTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
    private static String shedRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
    private static String posOrderItemRecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Item').getRecordTypeId();
    private static String transferOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
    
    /*Global List*/
    private static List<Messaging.SingleEmailMessage> lstAllSingleEmail = new List<Messaging.SingleEmailMessage>();
    private static List<Order_Item__c> lstUpdateOrderLineItem = new List<Order_Item__c>();
    private static List<Order__c> lstAllUpdatedOrder = new List<Order__c>();
    private static List<Id> lstOrderAccountId = new List<Id>();
    private static List<Id> lstUpdateOrder = new List<Id>(); //Order List Id for which validation fails
    private static List<Stock__c> lstUpdatedStock = new List<Stock__c>();
    public static List<Id> lstSalesRep = new List<Id>();
    public static List<Contract> updatedContractList = new List<Contract>();
    public static String orderSubmmitted = EDGE_Constant.ORDER_SUBMITTED;
    public static String diageoOne = 'Diageo One';  //NCP-2091
    
    /*Global Set*/
    public static Set<String> setCountryCode = new Set<String>();
    public static Set<String> setArea = new Set<String>();  
    
    /*
Method  : orderValidation
Purpose : 
*/
    public static void orderValidation(Map<Id, sObject> newItems){
        //Validation wise Order Map
        Map<Id, Order__c> mapAvailableAPOrder = new Map<Id, Order__c>();
        Map<Id, Order__c> mapStockOrder = new Map<Id, Order__c>();
        Map<Id, Order__c> mapAPAvailableOrder = new Map<Id, Order__c>();
        Map<Id, Order__c> mapValidateLineItemQuantity;        
        
        if(!EDGE_UtilityClass.stopTriggerToRun){
            EDGE_UtilityClass.stopTriggerToRun = true; //Used to stop recursion
            
            for(sObject newItem : newItems.values()){ 
                Order__c order = (Order__c) newItem;
                if(order.Status__c == orderSubmmitted && (order.RecordTypeId == posRecordTypeId || order.RecordTypeId == posGroupRecordTypeId)){
                    mapNewOrder.put(order.Id, order);
                    setCountryCode.add(order.Country_Code__c);
                    setArea.add(order.Area__c);
                }
            }
            
            //Get the Country Code
            if(setCountryCode != null && setCountryCode.size()>0){ 
                //Get the Metadata            
                for(Order_Validation_Per_Country__mdt orderMetadata : [SELECT ID, AP_Threshold_Check__c, Available_AP_Cost_Validation__c, Country_Code__c,
                                                                       Object_API_Name__c, Person_Operator_Check__c, Product_Limit_Per_Order__c, Stock_Validation__c, Type_of_Order__c,
                                                                       D1_Product_Limit_Per_Order__c, D1_Stock_Validation__c
                                                                       FROM Order_Validation_Per_Country__mdt WHERE Country_Code__c IN :setCountryCode
                                                                       AND Object_API_Name__c = 'Order__c' AND Type_of_Order__c = 'POS'
                                                                      ])
                {                       
                    mapOrderValidation.put(orderMetadata.Country_Code__c, orderMetadata);                       
                }
                
                //Create Map for different validation
                for(Order__c order : mapNewOrder.values()){
                    if(mapOrderValidation.containsKey(order.Country_Code__c)){
                        //A&P Validation
                        if(mapOrderValidation.get(order.Country_Code__c).Available_AP_Cost_Validation__c && order.Source_Application__c != diageoOne){
                            mapAvailableAPOrder.put(order.Id, order);       
                        }
                        
                        //Stock Validation
                        if(((mapOrderValidation.get(order.Country_Code__c).Stock_Validation__c && order.Source_Application__c != diageoOne) || (mapOrderValidation.get(order.Country_Code__c).D1_Stock_Validation__c && order.Source_Application__c == diageoOne)) 
                           && !mapAvailableAPOrder.containsKey(order.Id))
                        {
                            mapStockOrder.put(order.Id, order);
                        }
                        
                        //A&P Threshold Check
                        if(mapOrderValidation.get(order.Country_Code__c).AP_Threshold_Check__c && !(mapAvailableAPOrder.containsKey(order.Id) || mapStockOrder.containsKey(order.Id)) && order.Source_Application__c != diageoOne){
                            mapAPAvailableOrder.put(order.Id, order);                            
                        }                                         
                    }                                        
                }
                
                //Call Different method
                //A&P Validation
                if(mapAvailableAPOrder != null && mapAvailableAPOrder.size()>0){
                    mapValidateLineItemQuantity = verifyAPCost(mapAvailableAPOrder);                    
                }
                
                //Stock Validation
                if((mapStockOrder != null && mapStockOrder.size()>0) || (mapValidateLineItemQuantity != null && mapValidateLineItemQuantity.size()>0)){
                    if(mapValidateLineItemQuantity != null){
                        mapStockOrder.putAll(mapValidateLineItemQuantity);
                        mapValidateLineItemQuantity.clear();                        
                    }
                    mapValidateLineItemQuantity = validateLineItemQuantity(mapStockOrder);
                }
                
                if((mapAPAvailableOrder != null && mapAPAvailableOrder.size()>0) || (mapValidateLineItemQuantity != null && mapValidateLineItemQuantity.size()>0)){
                    if(mapValidateLineItemQuantity != null){
                        mapAPAvailableOrder.putAll(mapValidateLineItemQuantity);
                        mapValidateLineItemQuantity.clear();                        
                    }
                    verifyAPThreshold(mapAPAvailableOrder.values());
                }                
                
                performAllDML();
            }
        }
    }
    
    /*
Method  : verifyAPCost for POS Order
Purpose : 
*/
    public static Map<Id, Order__c> verifyAPCost(Map<Id, Order__c> mapOrder){
        Map<Id, Decimal> mapContractAP = new Map<Id, Decimal>();
        Map<Id, Order__c> mapValidateLineItemQuantity = new Map<Id, Order__c>();
        Set<Id> contractIds = new set<Id>();
        Set<Id> orderIdsToHeld = new Set<Id>();
        
        try{
            if(mapOrder != null && Schema.sObjectType.EmailTemplate.isAccessible()){
                EmailTemplate templateRec = [Select Id from EmailTemplate where developerName = 'A_P_funds_not_sufficient'];
                
                //Create Contract Id Set
                for(Order__c orderRec : mapOrder.values()){
                    if(orderRec.Contract__c != null){
                        contractIds.add(orderRec.Contract__c);
                    }                    
                }
                
                //Create Contract A&P Spend Map
                if(contractIds.size()>0){
                    for(Contract contractRec : [SELECT Id, Available_AP_Spend__c FROM Contract WHERE Id IN :contractIds]){
                        mapContractAP.put(contractRec.Id, contractRec.Available_AP_Spend__c);
                    }
                }
                
                //Validate Whether A&P Fund is available or not. If not send email and change order status to Order Held
                for(Id orderId : mapOrder.keySet()){
                    Order__c orderRec = mapOrder.get(orderId); 
                    //New clause in the existing if condition to skip 0$ cost orders - US-0013670
                    if(orderRec.Total_A_P_Cost__c != 0 && orderRec.Status__c == orderSubmmitted && orderRec.Contract__c != null && mapContractAP != null && mapContractAP.containsKey(orderRec.Contract__c) && orderRec.Total_A_P_Cost__c > mapContractAP.get(orderRec.Contract__c)){
                        Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                        mail.setTargetObjectId(orderRec.Sales_Representative__c);
                        mail.setTemplateID(templateRec.Id);
                        mail.setWhatId(orderRec.Id);
                        mail.setSaveAsActivity(false);
                        lstAllSingleEmail.add(mail);
                        orderIdsToHeld.add(orderRec.Id);
                    } else{
                        mapValidateLineItemQuantity.put(orderId, orderRec);
                    }
                }
                
                //Update Order Status to Order Held where A&P
                for(Id orderId : orderIdsToHeld){
                    order__c orderRec = new Order__c(Id = orderId);
                    orderRec.Status__c = 'Order Held';
                    lstAllUpdatedOrder.add(orderRec);
                }
            }
        } catch(Exception orderException){
            List<Order__c> lstNewOrder = mapOrder.values();
            new EDGE_GenericException(orderException, lstNewOrder[0]);
        }
        
        return mapValidateLineItemQuantity;        
    }
    
    /*
Method  : validateLineItemQuantity
Purpose : This methos is used to check whether Order Line Item quantity
is valid or not. First it will check with Product and then with 
Stock.
*/
    public static Map<Id,Order__c> validateLineItemQuantity(Map<Id,Order__c> newItems){
        String posItemRecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Item').getRecordTypeId();
        Set<Id> setPOSGroupOrder = new Set<Id>();
        Set<Id> setPOSOrder = new Set<Id>();
        Map<Order_Item__c, String> mapLineItemValidation = new Map<Order_Item__c, String>();
        Map<Id,Order__c> mapVerifyAPOrder;
        if(newItems != null && newItems.size()>0){
            for(Order__c newOrder : mapNewOrder.values()){
                //Depending upon Record Type create 2 different set, that can be used to get the child POS Order record
                if(newOrder.RecordTypeId == posGroupRecordTypeId){
                    setPOSGroupOrder.add(newOrder.Id);
                } else if(newOrder.RecordTypeId == posRecordTypeId){
                    setPOSOrder.add(newOrder.Id);
                }
            }
            //Fetch all child record of record type POS Order
            if(setPOSGroupOrder != null && setPOSGroupOrder.size()>0){
                for(Order__c posOrder : [SELECT Id, Order_Group__c FROM Order__c WHERE Order_Group__c IN :setPOSGroupOrder and RecordTypeId = :posRecordTypeId]){
                    mapChildOrderToParent.put(posOrder.Id, posOrder.Order_Group__c);
                    setPOSOrder.add(posOrder.Id);
                    
                    if(mapParentToChildOrder.containsKey(posOrder.Order_Group__c)){
                        mapParentToChildOrder.get(posOrder.Order_Group__c).add(posOrder.Id);
                    } else {
                        mapParentToChildOrder.put(posOrder.Order_Group__c, new List<Id> {posOrder.Id});
                    }
                }
                setPOSGroupOrder.clear();
            }
            //Fetch all the line item irrespective of Type of Order and Order Line Item
            if(setPOSOrder != null && setPOSOrder.size()>0 && Schema.SObjectType.Order_Item__c.isAccessible()){
                List<Order_Item__c> lstOrderItem = [SELECT Id, Order__c, Order_Item_Outlet__c, Order__r.Sales_Representative__c, Status__c, Product__c, Order__r.Account__c, Order__r.Account__r.Name, 
                                                    CreatedById, CreatedBy.Email, CreatedBy.FirstName, Product__r.Limit_Per_Order__c, 
                                                    Product__r.Name, Quantity__c, Type__c, Order__r.Order_Group__c, Product_Variant__c,
                                                    Product__r.Product_Type__c, Product__r.Product_Type__r.Type__c,
                                                    Product__r.Country__r.Code__c, Order__r.Source_Application__c
                                                    FROM Order_Item__c 
                                                    WHERE Order__c IN :setPOSOrder 
                                                    AND RecordTypeId =:posItemRecordTypeId];
                setPOSOrder.clear();
                if(lstOrderItem != null && lstOrderItem.size()>0){
                    mapVerifyAPOrder = getLineItemPerType(lstOrderItem); //It will create a map depend on Type of Order Line Item
                }
            }
            //Validate Shed Stock Quantity
            if(mapProductOrderItemShed != null && mapProductOrderItemShed.size()>0){
                mapLineItemValidation.putAll(validateShedStockQuantity(null));
            }
            
            //Validate Shed Stock Quantity
            if(mapProductOrderItemWare != null && mapProductOrderItemWare.size()>0){
                mapLineItemValidation.putAll(validateProductQuantity());
                mapLineItemValidation.putAll(validateStockQuantity(null));
            }
            
            Map<Id,Order__c> mapOrderValidation = createOrderList(mapLineItemValidation);
            
            if(mapOrderValidation != null && mapOrderValidation.size()>0){
                mapVerifyAPOrder.putAll(mapOrderValidation);                
            }
            //Query and Update the Status of Order to Order held if Quantity check exceed
            if(lstUpdateOrder != null && lstUpdateOrder.size()>0){
                Map<Id,Order__c> mapUniqueOrder = new Map<Id,Order__c>();
                Map<Id, Messaging.SingleEmailMessage> mapMail = new Map<Id, Messaging.SingleEmailMessage>();
                for(Order__c updateOrder : [SELECT ID, Status__c,RecordTypeId FROM Order__c WHERE ID IN :lstUpdateOrder]){
                    updateOrder.Status__c = 'Order Held';
                    mapUniqueOrder.put(updateOrder.Id,updateOrder); 
                    
                    //Used to create the Email template for Order with Status Held
                    if(!mapMail.containskey(updateOrder.Id)){
                        if(mapNewOrder.containsKey(updateOrder.Id) && updateOrder.RecordTypeId == posRecordTypeId){
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
        }
        return mapVerifyAPOrder;        
    }
    
    /*
Method  : getLineItemPerType
Purpose : Depending on the Type selected it will setup a Map
*/
    public static Map<Id,Order__c> getLineItemPerType(List<Order_Item__c> lstOrderItem){
        Map<Id,Order__c> mapVerifyAPOrder = new Map<Id,Order__c>();
        
        if(lstOrderItem != null && lstOrderItem.size()>0){
            String warehouse = EDGE_Constant.ORDER_WAREHOUSE;
            String shed = EDGE_Constant.ORDER_SHED;
            for(Order_Item__c orderItem : lstOrderItem){
                mapLineItemToOrderId.put(orderItem.Id, orderItem.Order__c);
                mapOrderLineItem.put(orderItem.Id,orderItem);                    
                //To populate the Line Item per Order
                if(mapOrderToLineItem.containsKey(orderItem.Order__c)){
                    mapOrderToLineItem.get(orderItem.Order__c).add(orderItem.Id);
                } else {
                    mapOrderToLineItem.put(orderItem.Order__c, new List<Id>{orderItem.Id});
                }
                //If Block For ES20-5073 PTO order to ignore stock validation
                if(orderItem.Product_Variant__c != null && orderItem.Product__c != null && orderItem.Product__r.Product_Type__c != null 
                   && String.isNotBlank(orderItem.Product__r.Product_Type__r.Type__c) && (orderItem.Product__r.Product_Type__r.Type__c).equalsIgnoreCase('Product Type'))
                {
                    
                    if(mapNewOrder.containsKey(orderItem.Order__c)){
                        mapVerifyAPOrder.put(orderItem.Order__c, mapNewOrder.get(orderItem.Order__c));   
                    } else if(mapNewOrder.containsKey(orderItem.Order__r.Order_Group__c)) {
                        mapVerifyAPOrder.put(orderItem.Order__r.Order_Group__c, mapNewOrder.get(orderItem.Order__r.Order_Group__c));   
                    }                 
                } else {
                    
                    if(orderItem.Type__c == warehouse){
                        /**Commented because when this method call via API we dont have Order Details but we do have Account details. We also have Account field on Order Item so changing this to refer Order Item Outlet Field*/
                        //lstOrderAccountId.add(orderItem.Order__r.Account__c);
                        lstOrderAccountId.add(orderItem.Order_Item_Outlet__c); //150478
                        if(mapProductOrderItemWare.containsKey(orderItem.Product__c)){
                            mapProductOrderItemWare.get(orderItem.Product__c).add(orderItem);
                        } else {
                            mapProductOrderItemWare.put(orderItem.Product__c, new List<Order_Item__c>{orderItem});
                        }                    
                    } else if(orderItem.Type__c == shed){
                        
                        if(orderItem.CreatedById != null){
                            lstSalesRep.add(orderItem.CreatedById);
                        }
                        
                        if(mapProductOrderItemShed.containsKey(orderItem.Product__c)){
                            mapProductOrderItemShed.get(orderItem.Product__c).add(orderItem);
                        } else {
                            mapProductOrderItemShed.put(orderItem.Product__c, new List<Order_Item__c>{orderItem});
                        }
                    }
                }
            }          
        }
        
        return mapVerifyAPOrder;
    }
    
    /*
Method  : validateShedStockQuantity
Purpose : 
*/
    public static Map<Order_Item__c, String> validateShedStockQuantity(Map<Order_Item__c,Id> salesRepItemMap){
        Map<Order_Item__c, String> mapLineItemValidation = new Map<Order_Item__c, String>();
        String recordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        String accounRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        Set<Id> setAccountId = new Set<Id>();
        Map<Id, List<Id>> mapUserAccount = new Map<Id, List<Id>>();
        Id accountId; 
        
        //Commented out as part of ES20-4653
        if(lstSalesRep!=null && lstSalesRep.size()<1){
            lstSalesRep = salesRepItemMap.values();
        }
        //Get the Shed Account for that Sales Rep
        for(AccountShare accountTeamMem : [SELECT AccountId, UserOrGroupId FROM AccountShare WHERE UserOrGroupId IN :lstSalesRep AND Account.RecordTypeId =:accounRecordTypeId]){
            setAccountId.add(accountTeamMem.AccountId);            
            if(mapUserAccount.containsKey(accountTeamMem.UserOrGroupId)){
                mapUserAccount.get(accountTeamMem.UserOrGroupId).add(accountTeamMem.AccountId);
            } else {
                mapUserAccount.put(accountTeamMem.UserOrGroupId, new List<Id> {accountTeamMem.AccountId});
            }
        }
        
        if(Schema.SObjectType.Stock__c.isAccessible()){
            List<Stock__c> lstStock = [SELECT Name, Stock_Available__c, Consumed_Stock__c, RecordTypeId, RecordType.Name, Product__c, Shed__c
                                       FROM Stock__c 
                                       WHERE Product__c IN :mapProductOrderItemShed.keySet() AND RecordTypeId =:recordTypeId AND Shed__c IN :setAccountId 
                                       AND Product__r.IsActive__c = True
                                      ];
            
            if(lstStock != null && lstStock.size()>0){
                for(Stock__c existStock : lstStock){
                    if(mapProductOrderItemShed.containsKey(existStock.Product__c)){
                        for(Order_Item__c orderItem : mapProductOrderItemShed.get(existStock.Product__c)){
                            if(mapUserAccount.containsKey(orderItem.CreatedById)){
                                List<Id> lstAccount = mapUserAccount.get(orderItem.CreatedById);
                                if(lstAccount.contains(existStock.Shed__c) && orderItem.Quantity__c > existStock.Stock_Available__c){
                                    mapLineItemValidation.put(orderItem,'Quantity exceed than Stock');
                                } else if(lstAccount.contains(existStock.Shed__c) && orderItem.Quantity__c <= existStock.Stock_Available__c){
                                    mapLineItemToStock.put(orderItem.Id, existStock);
                                }  else {
                                    mapLineItemValidation.put(orderItem,'No Stock Record Found');
                                }
                            }                 
                        }
                    }
                }                
            } else {
                for(String productId : mapProductOrderItemShed.KeySet()){
                    for(Order_Item__c orderItem : mapProductOrderItemShed.get(productId)){
                        mapLineItemValidation.put(orderItem,'No Stock Record Found');                    
                    }
                }                               
            }
        }
        
        return mapLineItemValidation;
    }
    
    /*
Method  : validateProductQuantity
Purpose : Depending upon the Product selected on Order Line item it 
will check the quantity of Product and Order Line Item
*/
    public static Map<Order_Item__c, String> validateProductQuantity(){
        final String D1_SOURCE = 'Diageo One';
        Map<Order_Item__c, String> mapLineItemValidation = new Map<Order_Item__c, String>();
        Map<String, List<Order_Item__c>> mapProductValidationPass = new Map<String,List<Order_Item__c>>();
        if(mapProductOrderItemWare != null && mapProductOrderItemWare.size()>0){
            for(String productId : mapProductOrderItemWare.keySet()){
                for(Order_Item__c orderItem : mapProductOrderItemWare.get(productId)){
                    if((orderItem.Quantity__c > orderItem.Product__r.Limit_Per_Order__c)
                       &&( orderItem.Order__r.Source_Application__c !=  D1_SOURCE
                          || (orderItem.Order__r.Source_Application__c == D1_SOURCE
                              && mapOrderValidation.get(orderItem.Product__r.Country__r.Code__c)?.D1_Product_Limit_Per_Order__c == true
                             )
                         )
                      ){
                          mapLineItemValidation.put(orderItem, 'Quantity exceed Product Limit'); //Validation failed i.e order quantity is greater that Limit
                      } else {
                          if(mapProductValidationPass.containskey(productId)){
                              mapProductValidationPass.get(productId).add(orderItem);
                          } else {
                              mapProductValidationPass.put(productId, new List<Order_Item__c>{orderItem});
                          }
                      }
                }
            }
            
            //Assign only those Order Item which pass validation
            mapProductOrderItemWare.clear();
            if(mapProductValidationPass != null && mapProductValidationPass.size()>0){
                mapProductOrderItemWare = mapProductValidationPass;
            }
        }
        
        return mapLineItemValidation;        
    }
    
    /*
Method  : validateStockQuantity
Purpose : Depending upon the Product selected in the Order Line Item
it will retrieve the corresponding stock of Allocation type.
And then compares the quantity
*/
    public static Map<Order_Item__c, String> validateStockQuantity(Map<Order_Item__c,Id> orderItemMap){ 
        Map<Order_Item__c, String> mapLineItemValidation = new Map<Order_Item__c, String>();
        List<Id> lstAccountId = new List<Id>();
        List<Id> lstTargetList = new List<Id>();
        Set<Order_Item__c> setOrderItem = new Set<Order_Item__c>();
        Map<Id,List<Id>> mapTargetListMember = new Map<Id,List<Id>>();
        Map<Id, Account> mapAccountDetails;
        String recordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        DateTime minStartDate ; //147120
        DateTime maxEndDate ; //147120
        Map<String, List<Order_Item__c>> mapProductOrderItemAll = new Map<String,List<Order_Item__c>>(); //147120
        
        //If the method is called from EDGE_OrderItemsValidationService populate setCountryCode, setArea otherwise they will be set from main method orderValidation
        if(orderItemMap != null && orderItemMap.size()>0){
            for(Account acc : [SELECT ID, Country__r.Code__c, Area__c  FROM Account WHERE ID IN : orderItemMap.values()]){
                setCountryCode.add(acc.Country__r.Code__c);
                setArea.add(acc.Area__c);                
            }            
        }
        
        //Retrieve all the Stock with Record Type Allocation of respective Product selected on Order Line Item 
        if(Schema.SObjectType.Stock__c.isAccessible() && Schema.SObjectType.Geography__c.isAccessible() 
           && Schema.SObjectType.Account.isAccessible() && Schema.SObjectType.Product__c.isAccessible() && Schema.SObjectType.Pick_Up_Options__c.isAccessible() 
          )//&& Schema.SObjectType.Territory__c.isAccessible() && Schema.SObjectType.Market_Setting__c.isAccessible()
        {   
            /* POS_Time_Based_Allocation__c field Added for - 147120 */
            List<Market_Setting__c> lstWarehouseLevel = [SELECT ID, Geography__c, Geography__r.Code__c, Warehouse_Level__c,POS_Time_Based_Allocation__c FROM Market_Setting__c WHERE Geography__r.Code__c IN :setCountryCode LIMIT 1];
            List<Stock__c> lstStock;
            
            //Get Stocks Data
            if(lstWarehouseLevel != null && lstWarehouseLevel.size()>0){
                if(lstWarehouseLevel[0].Warehouse_Level__c){
                    /* 147120 -- POS Time Based Allocattion */
                    if(lstWarehouseLevel[0].POS_Time_Based_Allocation__c){
                        /* Start_Date__c, End_Date__c field Added for - 147120 */
                        lstStock = [SELECT Name, Allocated_Available__c, RecordTypeId, RecordType.Name, Product__c, 
                                    State__c, State__r.Name, Target_List__c, Territory__c, Local_Outlet_Segment_2__c, Stock_Available__c,
                                    Local_Outlet_Segment1__c, Global_Segment__c, Country__c, Type__c, Consumed_Stock__c, Area__c, Outlet__c, Start_Date__c, End_Date__c
                                    FROM Stock__c 
                                    WHERE Product__c IN :mapProductOrderItemWare.keySet() AND Product__r.IsActive__c = True AND RecordTypeId =:recordTypeId AND 
                                    Area__c IN :setArea AND Start_Date__c <= TODAY AND End_Date__c >= TODAY ];
                    }else{
                        /* Start_Date__c, End_Date__c field Added for - 147120 */
                        lstStock = [SELECT Name, Allocated_Available__c, RecordTypeId, RecordType.Name, Product__c, 
                                    State__c, State__r.Name, Target_List__c, Territory__c, Local_Outlet_Segment_2__c, Stock_Available__c,
                                    Local_Outlet_Segment1__c, Global_Segment__c, Country__c, Type__c, Consumed_Stock__c, Area__c, Outlet__c, Start_Date__c, End_Date__c
                                    FROM Stock__c 
                                    WHERE Product__c IN :mapProductOrderItemWare.keySet() AND Product__r.IsActive__c = True AND RecordTypeId =:recordTypeId AND 
                                    Area__c IN :setArea];
                    }
                } else {
                    if(lstWarehouseLevel[0].POS_Time_Based_Allocation__c){
                        /* Start_Date__c, End_Date__c field Added for - 147120 */
                        lstStock = [SELECT Name, Allocated_Available__c, RecordTypeId, RecordType.Name, Product__c, 
                                    State__c, State__r.Name, Target_List__c, Territory__c, Local_Outlet_Segment_2__c, Stock_Available__c,
                                    Local_Outlet_Segment1__c, Global_Segment__c, Country__c, Type__c, Consumed_Stock__c, Outlet__c, Start_Date__c, End_Date__c
                                    FROM Stock__c 
                                    WHERE Product__c IN :mapProductOrderItemWare.keySet() AND Product__r.IsActive__c = True AND RecordTypeId =:recordTypeId AND 
                                    Country__r.Code__c IN :setCountryCode AND Start_Date__c <= TODAY AND End_Date__c >= TODAY]; 
                    }else{
                        /* Start_Date__c, End_Date__c field Added for - 147120 */
                        lstStock = [SELECT Name, Allocated_Available__c, RecordTypeId, RecordType.Name, Product__c, 
                                    State__c, State__r.Name, Target_List__c, Territory__c, Local_Outlet_Segment_2__c, Stock_Available__c,
                                    Local_Outlet_Segment1__c, Global_Segment__c, Country__c, Type__c, Consumed_Stock__c, Outlet__c, Start_Date__c, End_Date__c
                                    FROM Stock__c 
                                    WHERE Product__c IN :mapProductOrderItemWare.keySet() AND Product__r.IsActive__c = True AND RecordTypeId =:recordTypeId AND 
                                    Country__r.Code__c IN :setCountryCode]; 
                    }
                }                
            }
            
            //Create a mapping of LineItem and Outlet
            if(lstStock != null && lstStock.size()>0){
                //If any Stock Present with Type Target List then store the target list id in List which will be 
                //used later to retrieve the data from Target Member Object
                for(Stock__c objStock : lstStock){
                    if(objStock.Type__c == 'Outlet (Target List)' && objStock.Target_List__c != null){
                        lstTargetList.add(objStock.Target_List__c);
                    }
                    
                    /* To get the minimum start date and maximum end date when POS Time Check is true - 147120 */
                    if(lstWarehouseLevel[0].POS_Time_Based_Allocation__c && objStock.Start_Date__c != null && objStock.End_Date__c != null){
                        if(minStartDate == null){
                            minStartDate = objStock.Start_Date__c;
                        }else if(minStartDate != null && objStock.Start_Date__c < minStartDate){
                            minStartDate = objStock.Start_Date__c;
                        }
                        if(maxEndDate == null){
                            maxEndDate = objStock.End_Date__c;
                        }else if(objStock.End_Date__c > maxEndDate){
                            maxEndDate = objStock.End_Date__c;
                        }
                    }
                }
                
                /* To get all the Order Items between min Start Date and Max End Date, when POS Time Check is true - 147120 */
                if(minStartDate != null && maxEndDate != null && lstWarehouseLevel[0].POS_Time_Based_Allocation__c){
                    //mapProductOrderItemAll contains key as outletid_productid and value as List<OrderItem>
                    mapProductOrderItemAll = productOrderItemRange(mapProductOrderItemWare.keySet(), minStartDate, maxEndDate, lstOrderAccountId);
                }
                
                //Need to check whether the method called from API or Trigger as the API does not have order item id
                if(orderItemMap != null && orderItemMap.size()>0){
                    lstAccountId.addAll(orderItemMap.values());
                } else if(lstOrderAccountId != null && lstOrderAccountId.size()>0){                
                    lstAccountId.addAll(lstOrderAccountId);
                }
                
                if(lstAccountId != null && lstAccountId.size()>0){
                    //Retrieve the Account details of Order
                    mapAccountDetails = new Map<Id,Account>([SELECT Id, BillingState, Primary_Sales_Territory__c, Global_Segment__c, 
                                                             Local_Segment1__c, Local_Segment2__c, Country__c 
                                                             FROM ACCOUNT 
                                                             WHERE ID IN :lstAccountId
                                                            ]);                    
                    if(lstTargetList != null && lstTargetList.size()>0){
                        //Retrieve the TargetList details of Order Account and create a mapping between Outlet and TargetList
                        for(Target_List_Member__c targetListMember : [SELECT Id, Outlet__c,Target_List__c FROM Target_List_Member__c WHERE Target_List__c IN :lstTargetList AND Outlet__c IN :lstAccountId AND Assignment_Status__c = 'Active']){
                            if(mapTargetListMember.containskey(targetListMember.Outlet__c)){
                                mapTargetListMember.get(targetListMember.Outlet__c).add(targetListMember.Target_List__c);
                            } else {
                                mapTargetListMember.put(targetListMember.Outlet__c, new List<Id>{targetListMember.Target_List__c});
                            }               
                        }
                    }
                }
                
                for(Stock__c existStock : lstStock){
                    if(mapProductOrderItemWare.containsKey(existStock.Product__c)){
                        /* Create date range for Stock start and end date */
                        List<String> datesBetweenStartEnd = new List<String>();
                        if(lstWarehouseLevel[0].POS_Time_Based_Allocation__c){
                            DateTime startDate = existStock.Start_Date__c;
                            DateTime endDate = existStock.End_Date__c;
                            datesBetweenStartEnd.add(startDate.format('yyyy-MM-dd'));
                            while(startDate < endDate) {
                                datesBetweenStartEnd.add(startDate.addDays(1).format('yyyy-MM-dd'));
                                startDate = startDate.addDays(1);
                            }
                        }
                        
                        for(Order_Item__c orderItem : mapProductOrderItemWare.get(existStock.Product__c)){ 
                            /* Get List of Order Items for the specific Account and Product and get the total quantity - 147120 */
                            Integer orderedQuantity = 0;
                            if(lstWarehouseLevel[0].POS_Time_Based_Allocation__c){
                                //String key = orderItem.Order__r.Account__c + '_' + existStock.Product__c;
                                String key = orderItem.Order_Item_Outlet__c + '_' + existStock.Product__c;//150478
                                if(mapProductOrderItemAll.containsKey(key)){//Added for US:147123,147120
                                    List<Order_Item__c> orderItems = mapProductOrderItemAll.get(key);
                                    for(Order_Item__c item : orderItems){
                                        String createdDateInDateFormat = item.CreatedDate.format('yyyy-MM-dd');
                                        if(datesBetweenStartEnd.indexOf(createdDateInDateFormat)>=0){
                                            orderedQuantity = orderedQuantity + (Integer) item.Quantity__c;
                                        }
                                    }
                                    
                                    //Add the ordered quantity if this method calls via API because at that time we just have a reference to Order Item
                                    if(orderItemMap != null && orderItemMap.size()>0){
                                        orderedQuantity = orderedQuantity + (Integer)orderItem.Quantity__c;
                                    }
                                }
                            }
                            
                            //Depending on the Stock Type it will execute different if else block. 
                            //For eg: If the Type is Territory it will check whether the Order Account Primary territory field match with
                            //the territory selected in Stock record. If matched then it will check the quantity of Stock and line Item  
                            //150478 : Changed Order__r.Account__c to Order_Item_Outlet__c                       
                            if(existStock.Type__c == 'State' && existStock.State__c != null && 
                               ((orderItem.Order_Item_Outlet__c != null && mapAccountDetails.containsKey(orderItem.Order_Item_Outlet__c) && 
                                 mapAccountDetails.get(orderItem.Order_Item_Outlet__c).BillingState != null && 
                                 mapAccountDetails.get(orderItem.Order_Item_Outlet__c).BillingState == existStock.State__r.Name) ||
                                (orderItemMap != null && orderItemMap.containskey(orderItem) && mapAccountDetails.containskey(orderItemMap.get(orderItem)) && 
                                 mapAccountDetails.get(orderItemMap.get(orderItem)).BillingState != null && 
                                 mapAccountDetails.get(orderItemMap.get(orderItem)).BillingState == existStock.State__r.Name
                                )))
                            {
                                setOrderItem.add(orderItem);                               
                                if(orderItem.Quantity__c > existStock.Allocated_Available__c || 
                                   (lstWarehouseLevel[0].POS_Time_Based_Allocation__c && orderedQuantity > orderItem.Product__r.Limit_Per_Order__c)){ // Condition for Time based allocation - 147120
                                       mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                   } else {
                                       mapLineItemToStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.remove(orderItem);
                                   }
                            } else if(existStock.Type__c == 'Territory/Rep' && existStock.Territory__c != null && 
                                      ((orderItem.Order_Item_Outlet__c != null && mapAccountDetails.containsKey(orderItem.Order_Item_Outlet__c) &&   
                                        mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Primary_Sales_Territory__c != null && 
                                        mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Primary_Sales_Territory__c == existStock.Territory__c) || 
                                       (orderItemMap != null && orderItemMap.containskey(orderItem) && mapAccountDetails.containskey(orderItemMap.get(orderItem)) && 
                                        mapAccountDetails.get(orderItemMap.get(orderItem)).Primary_Sales_Territory__c != null && 
                                        mapAccountDetails.get(orderItemMap.get(orderItem)).Primary_Sales_Territory__c == existStock.Territory__c
                                       )))
                            {
                                setOrderItem.add(orderItem);  
                                if(orderItem.Quantity__c > existStock.Allocated_Available__c ||
                                   (lstWarehouseLevel[0].POS_Time_Based_Allocation__c && orderedQuantity > orderItem.Product__r.Limit_Per_Order__c)){ // Condition for Time based allocation - 147120
                                       mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                   } else {
                                       mapLineItemToStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.remove(orderItem);
                                   }
                            } else if(existStock.Type__c == 'Segment' && 
                                      (existStock.Global_Segment__c != null || existStock.Local_Outlet_Segment1__c != null || existStock.Local_Outlet_Segment_2__c != null) && 
                                      ((orderItem.Order_Item_Outlet__c != null && mapAccountDetails.containsKey(orderItem.Order_Item_Outlet__c) && 
                                        ((mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Global_Segment__c != null && 
                                          mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Global_Segment__c == existStock.Global_Segment__c) || 
                                         (mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment1__c != null && 
                                          mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment1__c == existStock.Local_Outlet_Segment1__c) || 
                                         (mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment2__c != null && 
                                          mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment2__c == existStock.Local_Outlet_Segment_2__c))) || 
                                       (orderItemMap != null && orderItemMap.containskey(orderItem) && mapAccountDetails.containskey(orderItemMap.get(orderItem)) && 
                                        ((mapAccountDetails.get(orderItemMap.get(orderItem)).Global_Segment__c != null && 
                                          mapAccountDetails.get(orderItemMap.get(orderItem)).Global_Segment__c == existStock.Global_Segment__c) || 
                                         (mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment1__c != null && 
                                          mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment1__c == existStock.Local_Outlet_Segment1__c) || 
                                         (mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment2__c != null && 
                                          mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment2__c == existStock.Local_Outlet_Segment_2__c))
                                       )))
                            {
                                setOrderItem.add(orderItem);  
                                if(orderItem.Quantity__c > existStock.Allocated_Available__c ||
                                   (lstWarehouseLevel[0].POS_Time_Based_Allocation__c && orderedQuantity > orderItem.Product__r.Limit_Per_Order__c)){ // Condition for Time based allocation - 147120
                                       mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                   } else {
                                       mapLineItemToStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.remove(orderItem);
                                   }
                            } else if(existStock.Type__c == 'Outlet (Target List)' && 
                                      (( existStock.Target_List__c != null && orderItem.Order_Item_Outlet__c != null && 
                                        mapTargetListMember.containskey(orderItem.Order_Item_Outlet__c) && 
                                        (mapTargetListMember.get(orderItem.Order_Item_Outlet__c).contains(existStock.Target_List__c))) || 
                                       (orderItemMap != null && existStock.Target_List__c != null && orderItemMap.get(orderItem) != null && 
                                        mapTargetListMember.containskey(orderItemMap.get(orderItem)) && 
                                        (mapTargetListMember.get(orderItemMap.get(orderItem)).contains(existStock.Target_List__c)))))
                            {
                                setOrderItem.add(orderItem);
                                if(orderItem.Quantity__c > existStock.Allocated_Available__c ||
                                   (lstWarehouseLevel[0].POS_Time_Based_Allocation__c && orderedQuantity > orderItem.Product__r.Limit_Per_Order__c)){ // Condition for Time based allocation - 147120
                                       mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                   } else {
                                       mapLineItemToStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.remove(orderItem);
                                   }                                                         
                            } else if(existStock.Type__c == 'State+Segment' && existStock.State__c != null && 
                                      (existStock.Global_Segment__c != null || existStock.Local_Outlet_Segment1__c != null || existStock.Local_Outlet_Segment_2__c != null) && 
                                      ((orderItem.Order_Item_Outlet__c != null && mapAccountDetails.containsKey(orderItem.Order_Item_Outlet__c) && 
                                        mapAccountDetails.get(orderItem.Order_Item_Outlet__c).BillingState != null && 
                                        mapAccountDetails.get(orderItem.Order_Item_Outlet__c).BillingState == existStock.State__r.Name && 
                                        ((mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Global_Segment__c != null && 
                                          mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Global_Segment__c == existStock.Global_Segment__c) || 
                                         (mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment1__c != null && 
                                          mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment1__c == existStock.Local_Outlet_Segment1__c) || 
                                         (mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment2__c != null && 
                                          mapAccountDetails.get(orderItem.Order_Item_Outlet__c).Local_Segment2__c == existStock.Local_Outlet_Segment_2__c))) ||
                                       (orderItemMap != null && orderItemMap.containskey(orderItem) && mapAccountDetails.containskey(orderItemMap.get(orderItem)) && 
                                        mapAccountDetails.get(orderItemMap.get(orderItem)).BillingState != null && 
                                        mapAccountDetails.get(orderItemMap.get(orderItem)).BillingState == existStock.State__r.Name && 
                                        ((mapAccountDetails.get(orderItemMap.get(orderItem)).Global_Segment__c != null && 
                                          mapAccountDetails.get(orderItemMap.get(orderItem)).Global_Segment__c == existStock.Global_Segment__c) || 
                                         (mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment1__c != null && 
                                          mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment1__c == existStock.Local_Outlet_Segment1__c) || 
                                         (mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment2__c != null && 
                                          mapAccountDetails.get(orderItemMap.get(orderItem)).Local_Segment2__c == existStock.Local_Outlet_Segment_2__c)))))
                            {
                                setOrderItem.add(orderItem);  
                                if(orderItem.Quantity__c > existStock.Allocated_Available__c ||
                                   (lstWarehouseLevel[0].POS_Time_Based_Allocation__c && orderedQuantity > orderItem.Product__r.Limit_Per_Order__c)){ // Condition for Time based allocation - 147120
                                       mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                   } else {
                                       mapLineItemToStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.remove(orderItem);
                                   }
                                
                            }else if(existStock.Type__c == 'Outlet' && 
                                     ((existStock.Outlet__c != null && orderItemMap != null && 
                                       orderItemMap.get(orderItem) != null && mapAccountDetails.containsKey(orderItemMap.get(orderItem)) && 
                                       orderItemMap.get(orderItem) == existStock.Outlet__c) || 
                                      (existStock.Outlet__c != null && orderItem.Order_Item_Outlet__c != null && 
                                       mapAccountDetails.containsKey(orderItem.Order_Item_Outlet__c) && orderItem.Order_Item_Outlet__c == existStock.Outlet__c)))
                            {
                                setOrderItem.add(orderItem);
                                if(orderItem.Quantity__c > existStock.Allocated_Available__c ||
                                   (lstWarehouseLevel[0].POS_Time_Based_Allocation__c && orderedQuantity > orderItem.Product__r.Limit_Per_Order__c)){ // Condition for Time based allocation - 147120
                                       mapLineItemToInvalidStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.put(orderItem, 'Quantity exceed Stock Allocation');
                                   } else {
                                       mapLineItemToStock.put(orderItem.Id, existStock);
                                       mapLineItemValidation.remove(orderItem);
                                   }                                       
                            }else if(!setOrderItem.contains(orderItem)){
                                mapLineItemValidation.put(orderItem, 'No Stock Record Found');
                            }
                        }
                    }
                }
            } else {
                for(String productId : mapProductOrderItemWare.KeySet()){
                    for(Order_Item__c orderItem : mapProductOrderItemWare.get(productId)){
                        mapLineItemValidation.put(orderItem,'No Stock Record Found');                    
                    }
                }                               
            }
        }    
        return mapLineItemValidation; 
    }
    
    /*
Method  : createOrderList
Purpose : If Order pass product and stock validation create the List of Order 
*/
    public static Map<Id,Order__c> createOrderList(Map<Order_Item__c, String> mapLineItemValidation){
        Map<Id,Order__c> mapParentOrder= new Map<Id,Order__c>();
        Set<Id> setAllLineItem = new Set<Id>();
        
        //Create the List of all order held line item
        if(mapLineItemValidation != null && mapLineItemValidation.size()>0){
            for(Order_Item__c orderItem : mapLineItemValidation.keySet()){
                
                /* ADDING ORDER ITEM ERROR DESRIPCTION FOR FAILED ORDERS  -- 147120 */
                orderItem.Error_Description__c = mapLineItemValidation.get(orderItem);
                lstUpdateOrderLineItem.add(orderItem);
                
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
        
        //Attach Stock and pass the date to next method
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
                        lstUpdateOrderLineItem.add(orderItem);
                        
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
        }
        return mapParentOrder;
    }
    
    /*
Method  : createOrderHeldTemplate
Purpose : 
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
        
        
        // body += Label.Order_Held_Email_Body_Footer+'<a href='+Label.EmailTemplateURL+order.Id+'>Link</a>';
        body += Label.Order_Held_Email_Body_Footer+'<a href='+URL.getOrgDomainURL().toExternalForm()+'/'+order.Id+'>Link</a>'; //366446 
        mail.setHtmlBody(body);        
        return mail;
    }
    
    /*
Method  : verifyAPThreshold
Purpose : 1. If Order cost exceeds country threshold  then order status will be Approval In Progress
2. Add Order Total Cost into Contract A&P Spend
*/    
    public static void verifyAPThreshold(List<Order__c> newItems){
        EDGE_UtilityClass.stopTriggerToRun = true;
        set<Id> countryIdset = new set<Id>();
        set<Id> contractIdset = new Set<Id>();
        set<Id> outletIdset = new Set<Id>();
        Map<Id, Market_Setting__c> countryThresholdMap = new Map<Id, Market_Setting__c>();
        Map<Id,Outlet_Contract__c> outletContractMap = new Map<Id,Outlet_Contract__c>();
        Map<Id,Contract> contractMap = new Map<Id,Contract>();
        Map<Id,Id> outletMap = new Map<Id,Id>();
        
        Map<Id,boolean> mapOrderIdApproval = new Map<Id,boolean>();//NCP-5088
        List<Order__c> d1OrdersList = new List<Order__c>();
        List<Order__c> pushNotifyOrderList = new List<Order__c>();// ES20-12619 
        
        for(Order__c orderObj: newItems){
            outletIdset.add(orderObj.Account__c);
            if(orderObj.Contract__c != null ){ // Added as part of ES20-4786
                contractIdset.add(orderObj.Contract__c);                
            }
            if(orderObj.Source_Application__c == diageoOne){
                d1OrdersList.add(orderObj);
            }
        }
        if(d1OrdersList.size()>0)
            mapOrderIdApproval = getD1Setting(d1OrdersList);
        //Get the Geography Id : Added as part of ES20-4786
        if(outletIdset != null && outletIdset.size()>0){
            for(Account account : [SELECT ID, Country__c FROM ACCOUNT WHERE ID IN :outletIdset]){
                countryIdset.add(account.Country__c);  
                outletMap.put(account.Id, account.Country__c);
            }            
        }
        //Get the market settings
        if(countryIdset != null && countryIdset.size()>0){
            for (Market_Setting__c marketSettings :[select A_P_Threshold__c, Threshold_Format__c, Manager_Threshold__c, Geography__c from Market_Setting__c where Geography__c in :countryIdset ]){
                countryThresholdMap.put(marketSettings.Geography__c, marketSettings);
            }            
        }
        //Get OutletContract
        if(contractIdset != null && contractIdset.size()>0){
            for(Outlet_Contract__c outletContact: [select Outlet__r.Country__c, Outlet__c, Contract__c, Contract__r.Available_AP_Spend__c, Contract__r.AP_Spent__c from Outlet_Contract__c  where Outlet__c in:outletIdset and Contract__c IN :contractIdset and Status__c='Active']){
                outletContractMap.put(outletContact.Outlet__c, outletContact);
                contractMap.put(outletContact.Contract__c, outletContact.Contract__r);
            }            
        }
        
        for(Order__c orderObj: newItems){
            Decimal thresholdAmount;
            //Added as part of ES20-4786
            if(outletMap.containsKey(orderObj.Account__c) && outletMap.get(orderObj.Account__c) != null && countryThresholdMap.containsKey(outletMap.get(orderObj.Account__c))){
                Market_Setting__c marketSettings = countryThresholdMap.get(outletMap.get(orderObj.Account__c));                
                if(marketSettings.Threshold_Format__c == 'Percent' && outletContractMap != null && outletContractMap.size()>0 && outletContractMap.get(orderObj.Account__c) != null){
                    thresholdAmount = (contractMap.get(outletContractMap.get(orderObj.Account__c).Contract__c).Available_AP_Spend__c*marketSettings.A_P_Threshold__c)/100; 
                } else if(marketSettings.Threshold_Format__c == 'Fixed Number'){
                    thresholdAmount = marketSettings.Manager_Threshold__c;  
                }                
            }
            if(orderObj.Total_A_P_Cost__c > thresholdAmount){
                Order__C newOrderObj = new Order__c(id=orderObj.id);
                newOrderObj.Threshold_Exceeded__c = true;
                lstAllUpdatedOrder.add(newOrderObj);
            } else if( mapOrderValidation.containskey(orderObj.Country_Code__c) && 
                      ((orderObj.Total_A_P_Cost__c == 0 && thresholdAmount == null) ||
                       (thresholdAmount != null  && mapOrderValidation.get(orderObj.Country_Code__c).Person_Operator_Check__c && orderObj.SalesRepOperatorPersonCheck__c == false) || 
                       !(mapOrderValidation.get(orderObj.Country_Code__c).Person_Operator_Check__c)
                      ))
            {
                Order__c newOrderObj= new Order__c(id=orderObj.id);
                if(orderObj.Source_Application__c == diageoOne && !mapOrderIdApproval.isEmpty()){
                    if(mapOrderIdApproval.get(orderObj.id) == true)//NCP-5088
                        newOrderObj.status__c='Awaiting Approval';
                    if(mapOrderIdApproval.get(orderObj.id) == false){
                        newOrderObj.status__c='Approved';
                    }
                    
                }else{
                    newOrderObj.status__c='Ready for Order';
                }
                shedOrderPlace(newOrderObj);
                lstAllUpdatedOrder.add(newOrderObj);   
            }
            
            if(outletContractMap != null && outletContractMap.size()>0 && outletContractMap.get(orderObj.Account__c)!=null){
                //Update Contract A&P Spent
                updatedContractList.add(updateContract(orderObj, (contractMap.get(outletContractMap.get(orderObj.Account__c).Contract__c).AP_Spent__c)));                
            }
        }
        //performAllDML();
    }
    
    /*
Method  : changeOrderStatus
Purpose : 
*/
    public static void changeOrderStatus(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        Map<Id, Order__c> mapOldOrder;
        lstAllUpdatedOrder.clear();
        lstUpdateOrderLineItem.clear();
        if(oldItems != null){
            mapOldOrder = (Map<Id, Order__c>) oldItems;            
        }
        String posItemRecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Item').getRecordTypeId(); 
        String shedItemRecordTypeId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId(); 
        
        for(sObject order : newItems.values()){
            Order__c newOrder = (Order__c) order;
            if(newOrder.RecordTypeId == posRecordTypeId && mapOldOrder.containsKey(newOrder.Id) && 
               mapOldOrder.get(newOrder.Id).Status__c == 'Approval In Progress' &&
               newOrder.Status__c == 'Ready for Order' && newOrder.Order_Type__c == EDGE_Constant.ORDER_SHED && 
               newOrder.Delivery_Partner__c == null){
                   Order__c updateOrder = new Order__c(Id = newOrder.id);
                   updateOrder.Status__c = 'Delivered to Shed';
                   //updateOrder.Status__c = 'Order Placed';
                   lstAllUpdatedOrder.add(updateOrder);
               }
        }
        
        if(lstAllUpdatedOrder != null && lstAllUpdatedOrder.size()>0){
            for(Order_Item__c orderItem : [SELECT Id, Status__c FROM Order_Item__c WHERE Order__c IN :lstAllUpdatedOrder AND (RecordTypeId =:posItemRecordTypeId OR RecordTypeId =:shedItemRecordTypeId )]){
                orderItem.Status__c = 'Delivered to Shed';
                //orderItem.Status__c = 'Order Placed';
                lstUpdateOrderLineItem.add(orderItem);                
            }
            performAllDML();
        }
    }
    
    /*
Method  : shedOrderPlace
Purpose : This method is used to skip the Order Place Status and changed the 
status directly to 'Delivered to Shed'
*/    
    public static void shedOrderPlace(Order__c newOrder){
        if(mapNewOrder.containsKey(newOrder.Id)){
            Order__c order = mapNewOrder.get(newOrder.Id);
            if(order.RecordTypeId == posRecordTypeId && newOrder.Status__c == 'Ready for Order' && order.Order_Type__c == EDGE_Constant.ORDER_SHED && order.Delivery_Partner__c == null){
                newOrder.Status__c = 'Delivered to Shed';
                if(mapOrderToLineItem.containsKey(order.Id)){
                    List<Id> lstOrderItemId = mapOrderToLineItem.get(order.Id);
                    for(String orderItemId : lstOrderItemId){
                        Order_Item__c orderItem = mapOrderLineItem.get(orderItemId);
                        orderItem.Status__c = 'Delivered to Shed';
                        if(lstUpdateOrderLineItem.contains(orderItem)){
                            List<Order_Item__c> lstUniqueOrderLineItem = new List<Order_Item__c>();
                            for(Order_Item__c existingOrderItem : lstUpdateOrderLineItem){
                                if(existingOrderItem.Id == orderItem.Id){
                                    lstUniqueOrderLineItem.add(orderItem);                                    
                                } else {
                                    lstUniqueOrderLineItem.add(existingOrderItem);
                                }
                            }
                            lstUpdateOrderLineItem.clear();
                            lstUpdateOrderLineItem.addAll(lstUniqueOrderLineItem);
                        } else {
                            lstUpdateOrderLineItem.add(orderItem);
                        }
                    }                    
                }                               
            }            
        }        
    }
    
    /*
Method  : updateContract
Purpose : 
*/
    public static Contract updateContract(Order__c orderObj, Decimal apSpent){
        Decimal totalAPCost = 0;
        if(orderObj.Total_A_P_Cost__c != null){
            totalAPCost = orderObj.Total_A_P_Cost__c;
        }
        Contract con = new Contract();
        con.Id = orderObj.Contract__c;
        con.AP_Spent__c = apSpent != null ? (apSpent + totalAPCost) : totalAPCost;
        return con;
    }
    
    /*
Method  : performAllDML
Purpose : This will be used to perform all DML and send Email
*/
    public static void performAllDML(){
        //Update the status(Order Held) or stock refernce of Line Order
        if(lstUpdateOrderLineItem != null && lstUpdateOrderLineItem.size()>0){
            Database.update(lstUpdateOrderLineItem);
        }
        
        //Update Contract     
        if(updatedContractList != null && updatedContractList.size()>0){
            Database.update(updatedContractList);
        }
        
        //Update the Order Status
        if(lstAllUpdatedOrder != null && lstAllUpdatedOrder.size()>0){
            Database.update(lstAllUpdatedOrder);  
        } 
        
        //Update the Stock consumed quantity
        if(lstUpdatedStock != null && lstUpdatedStock.size()>0){
            Database.update(lstUpdatedStock);
        }
        
        //Send Email in case A&P Validation Fails
        if(lstAllSingleEmail.size()>0){
            Messaging.sendEmail(lstAllSingleEmail, false);
        }
    }
    
    /*
Method  : syncOrderStatus
Purpose : Sync Order status : update child Order status from Parent Pos Order Group
*/
    public static void syncOrderStatus(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> parentOrderSet = new Set<Id>();
        Map<Id,String> parentOrderMap = new Map<Id,String>();
        List<String> eligibleStatus = System.Label.EDGE_Order_Statuses_for_Sync.split(',');
        for(SObject sObj : newItems.values()){
            Order__c newOrder = (Order__c)sObj;
            Order__c oldOrder;            
            if(oldItems!= null && oldItems.containsKey(newOrder.Id)){
                oldOrder = (Order__c)oldItems.get(newOrder.Id);
            }
            if((newOrder.Status__c != oldOrder.Status__c) && (eligibleStatus.contains(newOrder.Status__c)) 
               &&((newOrder.RecordTypeId == posGroupRecordTypeId)
                  || (newOrder.RecordTypeId == posRecordTypeId)
                  || (newOrder.RecordTypeId == stockMovementGroupRecordTypeId)
                  || (newOrder.RecordTypeId == stockMovementRecordTypeId)
                  || (newOrder.RecordTypeId == freeGoodsRecordTypeId)
                  || (newOrder.RecordTypeId == stockAdjRecordTypeId)))
            {
                parentOrderSet.add(newOrder.Id);
                parentOrderMap.put(newOrder.Id,newOrder.Status__c);
            }
        }
        
        //get the child orders
        if(Schema.sObjectType.Order__c.isAccessible()){
            List<Order__c> childOrderList = [SELECT Id,Status__c,Order_Group__c,Order_Group__r.RecordTypeId,Order_Group__r.Status__c From Order__c WHERE Order_Group__c IN : parentOrderSet];
            List<Order_Item__c> childOrderProductList = [SELECT Id, Status__c,Order__c,Order__r.RecordTypeId From Order_Item__c WHERE Order__c IN : parentOrderSet]; 
            
            for(Order__c ord : childOrderList){
                if(null != parentOrderMap.get(ord.Order_Group__c) && !(ord.Status__c =='Order Placed' || ord.Status__c =='Ready For Order' || ord.Status__c == 'Delivered To Shed')){
                    ord.Status__c = parentOrderMap.get(ord.Order_Group__c);
                }
            }
            
            if(Schema.sObjectType.Order__c.isUpdateable() && childOrderList.size()>0){
                update childOrderList;
            }        
            for(Order_Item__c objOrderProduct : childOrderProductList){
                //added condition objOrderProduct.Status__c == 'Order Held' to fix 150579
                if(null != parentOrderMap.get(objOrderProduct.Order__c) 
                   && ((objOrderProduct.Order__r.RecordTypeId !=  stockMovementRecordTypeId && !(objOrderProduct.Status__c =='Order Placed' || objOrderProduct.Status__c =='Ready For Order' || objOrderProduct.Status__c =='Delivered To Shed' || objOrderProduct.Status__c =='Awaiting Approval' || objOrderProduct.Status__c == 'Order Held')) || 
                       (objOrderProduct.Order__r.RecordTypeId ==  stockMovementRecordTypeId && !(objOrderProduct.Status__c =='Ready For Order' || objOrderProduct.Status__c =='Delivered To Shed' || objOrderProduct.Status__c =='Awaiting Approval' || objOrderProduct.Status__c == 'Order Held'))))
                {
                    //if(null != parentOrderMap.get(objOrderProduct.Order__c) && !(objOrderProduct.Status__c =='Ready For Order' || objOrderProduct.Status__c =='Delivered To Shed' || objOrderProduct.Status__c =='Awaiting Approval')){
                    
                    objOrderProduct.Status__c = parentOrderMap.get(objOrderProduct.Order__c);   
                }
            }
            
            if(Schema.sObjectType.Order_Item__c.isUpdateable() && childOrderProductList.size()>0){
                update childOrderProductList;
            }
        }
    }
    
    /*
Method  : orderStatusHeldCancelled
Purpose : If the order status is changed from 'Approval In Progress' to 'Order Held'
or 'Ready for Order' to 'Cancelled' :
1.the Total A&P Cost of the order , will be deducted from the Contract A&P Spent
2.the quantity from Order Items of the same order , will be deducted from the same 
Product's consumed stock
New method for ES20-2261,2263, 3006
*/
    public static void orderStatusHeldCancelled(Map<Id,sObject> mapNewItems, Map<Id,sObject> mapOldItems){
        Map<Id,Order__c> newItems = (Map<Id,Order__c>) mapNewItems;
        Map<Id,Order__c> oldItems;
        if(mapOldItems != null){
            oldItems = (Map<Id,Order__c>)mapOldItems;
        }
        String posRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        List<Order__c> lstPOSOrder = new List<Order__c>();
        Map<Id,Double> mapContractIdOrderCost = new Map<Id,Double>();
        List<Id> contractIdList = new List<Id>();
        List<Contract> contractsToUpdateList = new List<Contract>();
        List<Stock__c> stocksToUpdateList = new List<Stock__c>();
        Double deductedSpent;
        String priorStatusValue = Label.Order_Status_Prior_Cancellation; 
        
        try{
            if(newItems != null && newItems.size()>0){
                for(Order__c newOrder : newItems.values()){
                    //Putting all the orders in a list where status changed from from 'Approval In Progress' to 'Order Held' or 'Ready for Order' to 'Cancelled'
                    if((newOrder.Status__c == 'Order Held' && oldItems.get(newOrder.id).Status__c == 'Approval In Progress' && newOrder.RecordTypeId == posRecordTypeId) || 
                       (newOrder.Status__c == 'Cancelled' && priorStatusValue.contains(oldItems.get(newOrder.id).Status__c )&& newOrder.RecordTypeId == posRecordTypeId) ||
                       (newOrder.Status__c == 'Rejected' && newOrder.Source_Application__c == diageoOne && newOrder.RecordTypeId == posRecordTypeId))
                    {
                        lstPOSOrder.add(newOrder);
                    }
                }
                //Putting all the related contract in a list, contract and the total cost to be deducted from Contract in a Map
                if(lstPOSOrder != null && lstPOSOrder.size()>0){
                    for(Order__c orderRecord :lstPOSOrder){
                        if(mapContractIdOrderCost.containsKey(orderRecord.Contract__c)){
                            deductedSpent = mapContractIdOrderCost.get(orderRecord.Contract__c);
                            deductedSpent += orderRecord.Total_A_P_Cost__c; 
                            mapContractIdOrderCost.put(orderRecord.Contract__c,deductedSpent);
                        }else{
                            mapContractIdOrderCost.put(orderRecord.Contract__c,orderRecord.Total_A_P_Cost__c);
                        }
                        contractIdList.add(orderRecord.Contract__c);
                    }
                    // Deducting the order total A&P cost from the related contract's Contract A&P Spent and updating the  contract records
                    for(Contract contract: [Select Id,AP_Spent__c from Contract where Id IN :contractIdList]){
                        if(mapContractIdOrderCost.containsKey(contract.id)){
                            if(contract.AP_Spent__c != null ){
                                contract.AP_Spent__c = contract.AP_Spent__c - mapContractIdOrderCost.get(contract.id);
                                contractsToUpdateList.add(contract);
                            }
                        }
                    }
                    if(contractsToUpdateList != null && Schema.sObjectType.Contract.isUpdateable() && contractsToUpdateList.size()>0){
                        update contractsToUpdateList;
                    }
                    
                    for(Order_Item__c orderItem : [SELECT Delivered_Quantity__c,Type__c, Product_Variant__c, Product__c, Product__r.Name, Product__r.Product_Type__c, Product__r.Product_Type__r.Type__c, Quantity__c, Status__c,Stock__c,Stock__r.Consumed_Stock__c, Order__c FROM Order_Item__c WHERE Order__c IN :lstPOSOrder ]){
                        if(!(orderItem.Product_Variant__c != null && orderItem.Product__c != null && orderItem.Product__r.Product_Type__c != null && String.isNotBlank(orderItem.Product__r.Product_Type__r.Type__c) && (orderItem.Product__r.Product_Type__r.Type__c).equalsIgnoreCase('Product Type'))){
                            Stock__c stock = orderItem.Stock__r;                            
                            stock.Consumed_Stock__c = stock.Consumed_Stock__c - orderItem.Quantity__c;
                            stocksToUpdateList.add(stock);                            
                        }
                    }
                    
                    if(stocksToUpdateList != null && Schema.sObjectType.Stock__c.isUpdateable() && stocksToUpdateList.size()>0){
                        update stocksToUpdateList;
                    }
                    
                }
            }
            
        }catch (Exception orderException){
            new EDGE_GenericException(orderException, newItems.values()[0]);
        }        
    }
    
    /*
Method  : syncOrderDeliveryStatus
Purpose : 
*/
    public static void syncOrderDeliveryStatus(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> parentGroupOrderSet = new Set<Id>();        
        List<String> eligibleStatus = System.Label.EDGE_ChildOrderFinalStatuses.split(',');
        List<Order__c> childOrderList = new List<Order__c>();
        Map<Id,List<Order__c>> groupOrderWithChildMap = new Map<Id,List<Order__c>>();
        Map<Id,Boolean> orderDeliveredMap = new Map<Id,Boolean>();
        List<Order__c> lstOrderToUpdate = new List<Order__c>();
        Id posOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        
        for(SObject sObj : newItems.values()){
            Order__c newOrder = (Order__c)sObj;
            Order__c oldOrder;            
            if(oldItems!= null && oldItems.containsKey(newOrder.Id)){
                oldOrder = (Order__c)oldItems.get(newOrder.Id);
            }
            if((newOrder.Status__c != oldOrder.Status__c) && (eligibleStatus.contains(newOrder.Status__c) && newOrder.RecordTypeId == posOrderRecTypeId)               
              ){
                  //orderItemSet.add(newOrderItem.Id);
                  parentGroupOrderSet.add(newOrder.Order_Group__c);                  
              }
        }
        
        Map<Id,Order__c> parentOrderGroupMap;
        if(parentGroupOrderSet != null && parentGroupOrderSet.size()>0){
            parentOrderGroupMap = new Map<Id,Order__c>([SELECT Id,Delivery_Location__c,Status__c,Order_Group__c FROM Order__c WHERE Id  IN: parentGroupOrderSet]);
            
            //get child orders 
            childOrderList = [SELECT Id,Status__c,Order_Group__c FROM Order__c WHERE Order_Group__c IN : parentOrderGroupMap.keySet()];            
        }
        //populate groupOrderWithChildMap
        if(childOrderList != null && !childOrderList.isEmpty()){
            for(Order__c ord : childOrderList){
                if(groupOrderWithChildMap.containsKey(ord.Order_Group__c)){
                    groupOrderWithChildMap.get(ord.Order_Group__c).add(ord);                        
                }
                else{
                    groupOrderWithChildMap.put(ord.Order_Group__c, new List<Order__c>{ord});
                }
            }
        }
        //populate map of Orders not delivered
        if(groupOrderWithChildMap != null && !groupOrderWithChildMap.isEmpty()){
            for(Id ordId : groupOrderWithChildMap.keySet()){
                Boolean statusMisMatch = false;
                for(Order__c ord : groupOrderWithChildMap.get(ordId)){
                    if(!eligibleStatus.contains(ord.Status__c)){
                        statusMisMatch = true;  
                    } 
                }
                orderDeliveredMap.put(ordId,statusMisMatch);
            }
            
            for(Id ordId : groupOrderWithChildMap.keySet()){
                if(orderDeliveredMap.get(ordId) == false){
                    if(parentOrderGroupMap.get(ordId).Delivery_Location__c == 'Shed'){
                        parentOrderGroupMap.get(ordId).Status__c = 'Shed to Customer';                        
                    }else if(parentOrderGroupMap.get(ordId).Delivery_Location__c == 'Outlet' || parentOrderGroupMap.get(ordId).Delivery_Location__c == 'Other'){//ES20-12674
                        parentOrderGroupMap.get(ordId).Status__c = 'Delivered to Customer';   
                    }
                    lstOrderToUpdate.add(parentOrderGroupMap.get(ordId));
                }      
            }    
        }
        
        if(Schema.sObjectType.Order__c.isUpdateable()){
            update lstOrderToUpdate;  
        }   
    }
    
    /*
Method  : updateOrderStatus
Purpose : To update order status to order placed
*/ 
    public static void updateStatusToPlaced(Map<Id, SObject> newItems, Map<Id, SObject> mapOldItems){      
        Set<Id> delivryPartnrSet = new Set<Id>();
        Map<Id, Delivery_Partner__c> deliveryPartnerNotifyMap = new Map<Id, Delivery_Partner__c>(); 
        Map<Id,Order__c> newOrderMap;
        List<Order__c> orderGroupList = new List<Order__c>();
        Map<Id,List<Order__c>> orderListOrderGrpMap = new Map<Id,List<Order__c>>();
        List<Order__c> lstOrderPlaced = new list<Order__c>();        
        String posOrderRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        String posOrderGrpRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS Order Group').getRecordTypeId();
        //
        Map<Id,Set<Id>> orderGroupOrderIdMap = new Map<Id,Set<Id>>();
        Map<Id,List<Order__c>> orderGroupChildOrdersMap = new Map<Id,List<Order__c>>();
        
        if(newItems != null){
            newOrderMap = (Map<Id,Order__c>)newItems;
        } 
        for(Order__c orderRec : newOrderMap.values()){
            if(orderRec.Status__c == 'Ready for Order'){
                if((orderRec.RecordTypeId == posOrderRecordTypeId || orderRec.RecordTypeId == stockMovementRecordTypeId)&& orderRec.Delivery_Partner__c!=null){
                    delivryPartnrSet.add(orderRec.Delivery_Partner__c); 
                }    
            }
            //Batch Scenario to sync group order to status ORDER PLACED if all the child orders are ORDER PLACED
            if(orderRec.Status__c == 'Order Placed' && (orderRec.RecordTypeId == posOrderRecordTypeId || orderRec.RecordTypeId == stockMovementRecordTypeId) && orderRec.Order_Group__c != null){
                if(orderGroupOrderIdMap.containsKey(orderRec.Order_Group__c) && orderRec.Status__c == 'Order Placed'){
                    orderGroupOrderIdMap.get(orderRec.Order_Group__c).add(orderRec.Id);
                }else{
                    orderGroupOrderIdMap.put(orderRec.Order_Group__c, new Set<Id> {orderRec.Id});
                }
            } 
        }   
        if(delivryPartnrSet != null && delivryPartnrSet.size()>0 && Schema.sObjectType.Delivery_Partner__c.isAccessible()){
            for(Delivery_Partner__c deliverPartner : [SELECT Id, Batch_Notification__c,CreatedById FROM Delivery_Partner__c WHERE Id IN: delivryPartnrSet]){
                deliveryPartnerNotifyMap.put(deliverPartner.Id, deliverPartner);
            }            
        }
        
        
        for(Order__c orderRec : newOrderMap.values()){
            if((orderRec.RecordTypeId == posOrderRecordTypeId  || orderRec.RecordTypeId == stockMovementRecordTypeId) && orderRec.Status__c == 'Ready for Order' && orderRec.Delivery_Partner__c!=null && !deliveryPartnerNotifyMap.get(orderRec.Delivery_Partner__c).Batch_Notification__c ){
                Order__c order = new Order__c(Id=orderRec.Id);
                order.Status__c = 'Order Placed';
                order.Order_Placed_Date__c =  Date.today();
                //ES20-13081
                order.Order_Group__c = orderRec.Order_Group__c;
                order.RecordTypeId = orderRec.RecordTypeId;
                
                lstOrderPlaced.add(order);
            }
        }
        //ES20-13081
        if(lstOrderPlaced != null && lstOrderPlaced.size()>0){
            for(Order__c childOrderObj : lstOrderPlaced){
                if(childOrderObj.Order_Group__c != null){
                    if(orderGroupOrderIdMap.containsKey(childOrderObj.Order_Group__c) && childOrderObj.Status__c == 'Order Placed'){
                        orderGroupOrderIdMap.get(childOrderObj.Order_Group__c).add(childOrderObj.Id);
                    }else{
                        orderGroupOrderIdMap.put(childOrderObj.Order_Group__c, new Set<Id> {childOrderObj.Id});
                    }
                }
            }
        }
        //Fetching Existing child orders status and grouping it to Order Group as key
        if(orderGroupOrderIdMap != null && orderGroupOrderIdMap.size()>0){
            for(Order__c existingOrderObj : [SELECT Id, RecordtypeId,Name, Status__c, Order_Group__c,Order_Group__r.Status__c,Order_Group__r.RecordTypeId FROM Order__c WHERE Order_Group__c IN : orderGroupOrderIdMap.keySet()]){
                if(orderGroupChildOrdersMap.containskey(existingOrderObj.Order_Group__c)){
                    orderGroupChildOrdersMap.get(existingOrderObj.Order_Group__c).add(existingOrderObj);
                }
                else{
                    orderGroupChildOrdersMap.put(existingOrderObj.Order_Group__c,new List<Order__c> {existingOrderObj});
                }            
            }
        }
        
        if(orderGroupOrderIdMap != null && orderGroupOrderIdMap.size()>0){
            List<Order__c> existingOrdersList = new List<Order__c> ();
            Set<Id> ordersChildOrderPlacedSet = new Set<Id> ();
            for(Id orderGroupId : orderGroupOrderIdMap.keyset()){
                //existing child orders List of a group
                if(orderGroupChildOrdersMap.get(orderGroupId) != null){
                    existingOrdersList = orderGroupChildOrdersMap.get(orderGroupId);
                }
                //Set of new order ids under same group with status of Order Placed
                if(orderGroupChildOrdersMap.get(orderGroupId) != null){
                    ordersChildOrderPlacedSet = orderGroupOrderIdMap.get(orderGroupId);
                }
                Integer countOfOrderPlaced = 0;
                
                for(Order__c ordersStatusobj : existingOrdersList){
                    //first part - if child order under one group has status order placed adding 1
                    //or
                    //second part - if child order status under one group is not order placed then checking if new child order is getting updated as order placed then adding 1
                    if(ordersStatusobj.Status__c == 'Order Placed' || ordersChildOrderPlacedSet.contains(ordersStatusobj.Id)){
                        countOfOrderPlaced++;
                    } 
                }
                //Comparing existing child order status with new child order status as Order Placed under one group,
                //if the size of existing child orders status is equal to new countOfOrderPlaced then Group is updated to status order placed
                if(existingOrdersList.size() == countOfOrderPlaced){
                    Order__c order = new Order__c(Id= orderGroupId);
                    order.Status__c = 'Order Placed';
                    lstOrderPlaced.add(order);
                }
            }
        }        
        if(lstOrderPlaced != null && lstOrderPlaced.size()>0){
            Database.update(lstOrderPlaced);
        }
    }
    
    /*
Method  : sendEmailToDelPart
Purpose : To update order Items' status to order placed and send email
*/ 
    public static void sendEmailToDelPart(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        
        
        List<Order__c> orderList = new List<Order__c>();
        Map<Id,String> delivryPartnrEmailMap = new Map<Id,String>();
        List<Order_Item__c> orderItemToUpdate = new List<Order_Item__c>();
        Map<Id, Order__c> mapOldOrder;
        Set<Id> newOrderIdSet = new Set<Id>();
        Map<Id,Set<Order__c>> delivryPartnrOrderIdsMap = new Map<Id,Set<Order__c>>();
        Map<String , Market_Setting__c> mslIdToMSLMap = new Map<String , Market_Setting__c>();
        String emailAttachmentFormat = '';
        STring languageName = '';
        
        for(Market_Setting__c mslRec : [select language__c,Geography__r.Code__c,Attachment_Format__c from Market_Setting__c]){
            mslIdToMSLMap.put(mslRec.Geography__r.Code__c, mslRec);
        }
        
        if(oldItems != null){
            mapOldOrder = (Map<Id, Order__c>) oldItems;            
        }
        
        for(sObject orderRec : newItems.values()){
            Order__c newOrder = (Order__c) orderRec;
            if(newOrder.Delivery_Partner__c != null && newOrder.Status__c== 'Ready For Order' && mapOldOrder.get(newOrder.Id).Status__c!='Ready For Order' && ((newOrder.RecordTypeId ==posRecordTypeId) ||(newOrder.RecordTypeId ==stockMovementRecordTypeId))){
                newOrderIdSet.add(newOrder.Id);
            }  
        }
        if(newOrderIdSet != null && newOrderIdSet.size() > 0){
            orderList = EDGE_POSStockMvmtEmailHelper.getOrderList(newOrderIdSet, false, null);  
        }
        
        if(newOrderIdSet != null && newOrderIdSet.size() > 0){
            Id orderId = new List<Id>(newOrderIdSet).get(0); //Taking only one order as all of them should be part of the same country
            if(orderId != null){
                Order__c order = (Order__c)newItems.get(orderId);
                Market_Setting__c mrktSettingRec = mslIdToMSLMap.get(order.Country_Code__c);
                
                if(mrktSettingRec != null){
                    if(mrktSettingRec.Attachment_Format__c != null){
                        emailAttachmentFormat = mrktSettingRec.Attachment_Format__c;
                    }
                    if(mrktSettingRec.language__c != null){
                        languageName = mrktSettingRec.language__c;
                    }
                }               
            }
        }
        if(orderList != null && orderList.size()>0){
            for(Order_Item__c orderItem : [SELECT Id,Status__c, Order__r.Id,Product__c,Product__r.Product_Code__c,Order__c,Quantity__c,Note__c,Text_to_Print__c
                                           ,Product_Variant__r.Size__c,Product_Variant__r.Paper_Finish__c,toLabel(Product_Variant__r.Colour__c),
                                           Product_Variant__r.Gender__c FROM Order_Item__c WHERE Order__c IN : orderList
                                           AND Status__c!= 'Order Placed']){
                                               
                                               orderItem.Status__c = 'Order Placed';
                                               orderItemToUpdate.add(orderItem);           
                                           }            
        }
        
        delivryPartnrOrderIdsMap = EDGE_POSStockMvmtEmailHelper.getDlvryPartnerOrderMap(orderList, delivryPartnrEmailMap);
        
        for(Id delPartnerId : delivryPartnrOrderIdsMap.keySet()){
            Set<Order__c> orderIdSet=delivryPartnrOrderIdsMap.get(delPartnerId);//ES20-13180  
            String emailAdd = delivryPartnrEmailMap.get(delPartnerId);     //ES20-13180 
            if(orderIdSet != null && orderIdSet.size() > 0){  //ES20-13180              
                List<Order__c> ordersForDeliveryPartnerList=new List<Order__c>(orderIdSet);//ES20-13180 
                Map<Id,Order__c> ordersForDeliveryPartnerMap=new Map<Id,Order__c>(ordersForDeliveryPartnerList);//ES20-13180        
                if(emailAttachmentFormat.equalsIgnoreCase('CSV')){//ES20-13180  
                    EDGE_POSStockMvmtEmailHelper.sendCsvAttachment(ordersForDeliveryPartnerList, new List<String>{emailAdd}, null, null);//ES20-13180  
                }else if(emailAttachmentFormat.equalsIgnoreCase('Excel')){//ES20-13180  
                    //if(orderIdSet != null && orderIdSet.size() > 0){//ES20-13180  
                    EDGE_POSStockMvmtEmailHelper.sendEmailAsync(ordersForDeliveryPartnerMap.keySet(), new List<String>{emailAdd}, languageName);//ES20-13180 
                    //} 
                }
            }
        }
        
        if(orderItemToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){// Performing the DML here since DML operations cannot be performed within VF page constructor
            update orderItemToUpdate;
        }
    }
    /*
Method  : sendEmailForOrderSubmtd
Purpose : To update order Items' status to order placed and send email
*/ 
    public static void sendEmailForOrderSubmtd(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        //variables
        List<Messaging.SingleEmailMessage> orderEmail = new List<Messaging.SingleEmailMessage>();
        List<Order__c> orderList = new List<Order__c>();
        Map<String,List<Order_Item__c>> orderListOrderMap = new Map<String,List<Order_Item__c>>();
        List<Order_Item__c> orderItemToUpdate = new List<Order_Item__c>();
        List<Order__c> orderToUpdate = new List<Order__c>();
        List<Order__c> orderToUpdateBatch = new List<Order__c>();
        List<Order__c> pushNotifyOrderList = new List<Order__c>();
        List<String> emailLst = new List<String>();
        Set<Id> newOrderIdSet = new Set<Id>();
        Set<Id> newSetOrder = new Set<Id>();
        String languageName = '';
        String ordrAccnt = '';
        Boolean flag = false;
        String trnsferOrdRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        Set<Id> newSetOrderCountryIds = new Set<Id>();
        Map<Id, Market_Setting__c> orderIdToMSMap = new Map<Id, Market_Setting__c>();
        Map<String,Boolean> countryMArketMap = new Map<String,Boolean>();
        if(!EDGE_UtilityClass.stopThirdTriggerToRun){
            EDGE_UtilityClass.stopThirdTriggerToRun = true; //Used to stop recursion
            
            //ES20-4636 Transfer Order Business logic - Start
            
            if( newItems != null && !newItems.isEmpty()){
                Map<String , Market_Setting__c> mslIdToMSLMap = new Map<String , Market_Setting__c>();
                Map<Id, Order__c> orderIdToOrderMap = (Map<Id, Order__c>) newItems;
                
                for(Market_Setting__c mslRec : [select Id,Name,Geography__c,Geography__r.Code__c,Language__c,Transfer_Order_Email_Batch_Settings__c, 
                                                Display_Transfer_Order_Comments__c from Market_Setting__c]){
                                                    mslIdToMSLMap.put(mslRec.Geography__r.Code__c, mslRec);
                                                    countryMArketMap.put(mslRec.Geography__r.Code__c , mslRec.Display_Transfer_Order_Comments__c);// Added by Manikant
                                                }
                
                
                
                for(Order__c  newOrder : orderIdToOrderMap.values()){
                    if(newOrder.Account__c != null && newOrder.Sales_Representative__c != null && newOrder.Wholesaler__c != null && newOrder.Status__c== 'Submitted' && newOrder.RecordTypeId ==trnsferOrdRecordTypeId){
                        Market_Setting__c msl = mslIdToMSLMap.get(newOrder.Country_Code__c);
                        
                        if(newOrder.Source_Application__c == diageoOne){ //ES20-12621
                            pushNotifyOrderList.add(newOrder);
                            
                        }
                        if(msl != null){
                            if(msl.Transfer_Order_Email_Batch_Settings__c == false){
                                newOrderIdSet.add(newOrder.Id);
                                newSetOrder.add(newOrder.Id);
                                for(Id ordNew : newSetOrder){
                                    order__c ordrec = new Order__c(Id = ordNew);
                                    ordrec.Status__c = 'Order Placed';
                                    orderToUpdate.add(ordrec);
                                }
                            }else{
                                newOrderIdSet.add(newOrder.Id);
                                newSetOrder.add(newOrder.Id);
                                for(Id ordNew : newSetOrder){  
                                    order__c ordrec = new Order__c(Id = ordNew);
                                    ordrec.Status__c = 'Ready for Order';
                                    orderToUpdateBatch.add(ordrec);
                                    flag = true;
                                }
                            }
                        }
                        
                    }       
                }
                if(pushNotifyOrderList != null && pushNotifyOrderList.size() > 0){ //ES20-12621
                    EDGE_OrderPushNotifHelper.populateOutMemDetails(pushNotifyOrderList,false); 
                }
            }
            
            if(newOrderIdSet != null && newOrderIdSet.size()>0){
                orderList = [SELECT Id,Name,Status__c,RecordTypeId,Wholesaler_Account_Number__c,Contact__c,Comments__c,Contact__r.Email,Account__c, Account__r.RecordTypeId,Preferred_Delivery_Date__c,Order_Placed_Date__c,
                             Account__r.name,Sales_Representative__r.name,Sales_Representative__r.Email,Sales_Representative__r.Mobile_Number__c,Wholesaler__r.Name,Wholesaler__r.Outlet_Email_Address__c,Account__r.Outlet_Email_Address__c,
                             Account__r.BillingStreet,Account__r.BillingState,Account__r.BillingCity,Account__r.BillingCountry,Account__r.BillingPostalCode,Account__r.Country__c,Account__r.Country__r.Name, Next_Delivery_Date__c, 
                             Source_Application__c,Contact__r.MobilePrefix__c,Contact__r.Mobile__c,Country_Code__c,Is_Promo_Transfer_Order__c from Order__c 
                             WHERE Id IN:newOrderIdSet AND RecordType.Name='Transfer Order']; //Updated by Divya for ES20-9289
                // updated NCP-2677 Source_Application__c,Contact__r.MobilePrefix__c,Contact__r.Mobile__c
            }
            Set<Id> orderIdToPass = new Set<Id>();
            for(order__c ordRec :orderList ){
                orderIdToPass.add(ordRec.id); 
            }
            if((orderList!=null && orderList.size()>0)){
                for(Order__c orderRec : orderList){
                    ordrAccnt = orderRec.Account__r.Name;
                    // ESP-362 added null pointer check since it was blocking email notification to Sales Rep and Wholesaler even if outlet email address was not present.
                    if(orderRec.Account__r.Outlet_Email_Address__c !=null){
                        emailLst.add(orderRec.Account__r.Outlet_Email_Address__c);   
                    }
                    if(orderRec.Contact__c != null && orderRec.Contact__r.Email != null){ // added for ES20-6524
                        emailLst.add(orderRec.Contact__r.Email);   
                    } 
                    if(orderRec.Sales_Representative__r.Email !=null){
                        emailLst.add(orderRec.Sales_Representative__r.Email);
                    }
                    
                    if(!flag && orderRec.Wholesaler__r.Outlet_Email_Address__c !=null){//non-batch mode
                        emailLst.add(orderRec.Wholesaler__r.Outlet_Email_Address__c); 
                    }
                    
                }      
            }
            
            if(orderToUpdate != null && orderToUpdate.size()>0){
                //Added Product Name of MAP and Customer Facing Description as part of ES20-12641
                for(Order_Item__c orderItem : [SELECT Id,Status__c, Order__r.Id,RecordTypeId,Product__c,Product__r.Name,Product__r.Long_Description__c,Product__r.Product_Code__c,Order__c,Quantity__c,Selected_UoM__c,Market_Assortment_Product__r.Product__r.Name,Market_Assortment_Product__r.D1_Product_Name__c,Product__r.SAP_SKU_Code__c
                                               FROM Order_Item__c WHERE Order__c IN : orderToUpdate AND RecordType.Name='Transfer Order Item']){
                                                   
                                                   orderItem.Status__c = 'Order Placed';
                                                   orderItemToUpdate.add(orderItem);
                                                   String orderId = orderItem.Order__r.Id;
                                                   if(orderListOrderMap.containsKey(orderId)){
                                                       orderListOrderMap.get(orderId).add(orderItem);
                                                   }else{
                                                       orderListOrderMap.put(orderId, new List<Order_Item__c> { orderItem });
                                                   }            
                                               }
            }
            if(orderToUpdateBatch != null && orderToUpdateBatch.size()>0){
                for(Order_Item__c orderItem : [SELECT Id,Status__c, Order__r.Id,RecordTypeId,Product__c,Product__r.Name,Product__r.Long_Description__c,Product__r.Product_Code__c,Order__c,Quantity__c,Selected_UoM__c,Promotion_Product__c,Promotion_Product__r.Promotion__c,Promotion_Product__r.Promotion__r.Name,Promotion_Product__r.Product__r.Product_Full_Name__c,Promotion_Product__r.Promotion__r.Discount_for_promotion__c,Promotion_Product__r.Product__r.SAP_SKU_Code__c,Promotion_Product__r.Promo_Transfer_Order_Used_UOM__c,Promotion_Product__r.RecordTypeId,Promotion_Product__r.Promotion__r.RecordType.Name
                                               FROM Order_Item__c WHERE Order__c IN : orderToUpdateBatch AND RecordType.Name='Transfer Order Item']){
                                                   
                                                   orderItem.Status__c = 'Ready for Order';
                                                   orderItemToUpdate.add(orderItem); 
                                                   String orderId = orderItem.Order__r.Id;
                                                   if(orderListOrderMap.containsKey(orderId)){
                                                       orderListOrderMap.get(orderId).add(orderItem);
                                                   }else{
                                                       orderListOrderMap.put(orderId, new List<Order_Item__c> { orderItem });
                                                   }
                                                   
                                               }            
            }
            
            if(orderItemToUpdate.size()>0)
            {	
                EDGE_TransferOrderStatusHelper.sendPDFAsyc(orderIdToPass,false,emailLst,ordrAccnt);
                
            }
            if(orderToUpdate.size()>0 && Schema.sObjectType.Order__c.isUpdateable()){
                update orderToUpdate;
            }
            if(orderToUpdateBatch.size()>0 && Schema.sObjectType.Order__c.isUpdateable()){
                update orderToUpdateBatch;
            } 
            if(orderItemToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
                update orderItemToUpdate;
            }                
            //ES20-4636 Transfer Order Business logic - End
        }
    }
    
    /*
Method : updateWholesalerAccNum 
Purpose : This will populate Wholesaler Account number in order records, based on the condition of wholesaler and outlet from 
supplier outlet object.
*/
    public static void updateWholesalerAccNum(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        Map<Id, Order__c> newOrderMap;
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> outletIdSet = new Set<Id>();
        Set<Id> wholesalerIdSet = new Set<Id>();
        List<Order__c> orderToUpdateList = new List<Order__c>();
        String uniqueKey = '';
        Map<String,String> accNumbUniqKeyMap = new Map<String,String>();
        Map<String,String> orderUniqeKeyMap = new Map<String,String>();
        String trnsferOrdRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        
        if(newItems != null){
            newOrderMap = (Map<Id,Order__c>)newItems;
        } 
        if(newOrderMap.values() != null){
            for(Order__c orderRec : newOrderMap.values()){
                if(orderRec.RecordTypeId == trnsferOrdRecordTypeId){
                    orderIdSet.add(orderRec.id);
                    outletIdSet.add(orderRec.Account__c);
                    wholesalerIdSet.add(orderRec.Wholesaler__c);                
                }
            }  
        }
        // To  filter out Wholesaler Account Number based on the outlet and Wholesaler from obtained from Order record.  
        if(outletIdSet != null && outletIdSet.size()>0 && wholesalerIdSet != null && wholesalerIdSet.size()>0 && Schema.sObjectType.Supplier_Outlet__c.isAccessible() ){
            for(Supplier_Outlet__c suppOut : [SELECT Distributor_Wholesaler__c,Outlet__c,Wholesaler_Account_Number__c  FROM Supplier_Outlet__c
                                              where Distributor_Wholesaler__c IN : wholesalerIdSet AND Outlet__c IN : outletIdSet]){
                                                  uniqueKey =    suppOut.Distributor_Wholesaler__c+'_'+ suppOut.Outlet__c;          
                                                  accNumbUniqKeyMap.put(uniqueKey,suppOut.Wholesaler_Account_Number__c);                 
                                              }
        }
        // to create a map of order record and unique key of wholesaler and account , this map will be used to filter unique records of supplier outlet records
        for(order__c ordRec : newOrderMap.values()){
            uniqueKey =   ordRec.Wholesaler__c+'_'+ ordRec.Account__c;
            orderUniqeKeyMap.put(ordRec.Id,uniqueKey);
        }
        // This will populate wholesaler account number in order object after comparing the records from supplier outlet maps.
        for(order__c ordRec : newOrderMap.values()){
            if(orderUniqeKeyMap.get(ordRec.Id) != null && AccNumbUniqKeyMap.get(orderUniqeKeyMap.get(ordRec.Id)) != null && ordRec.Wholesaler_Account_Number__c == null){
                Order__c order = new Order__c(Id=ordRec.Id);
                order.Wholesaler_Account_Number__c = AccNumbUniqKeyMap.get(orderUniqeKeyMap.get(ordRec.Id));
                orderToUpdateList.add(order);
            }
        }        
        if(Schema.sObjectType.Order__c.isUpdateable() && orderToUpdateList.size() > 0){
            update orderToUpdateList;
        }
    }
    
    //This method used to get the d1 setting record from d1 orders info
    public static Map<Id,boolean> getD1Setting(List<Order__c> orders){
        Map<Id,boolean> mapOrderIdApproval = new Map<Id,boolean>();
        Map<Id,Id> mapContIdsOrderIds = new Map<Id,Id>();
        for(Order__c o: orders){
            mapContIdsOrderIds.put(o.Contact__c,o.Id);
        }
        for(Contact c: [SELECT Id, D1_Setting__r.pos_approval__c FROM Contact WHERE Id=:mapContIdsOrderIds.keyset()]){
            if(c.D1_Setting__c!=null && c.D1_Setting__r.pos_approval__c != null)
                mapOrderIdApproval.put(mapContIdsOrderIds.get(c.Id),c.D1_Setting__r.pos_approval__c);
        }
        return mapOrderIdApproval;                 
    }
    /**
* @Method : sendPOSOrderPushNotification 
* @Purpose : This will collect the orders of POS type if the status is changed from Awaiting Approval to Approved .
* @Return : Void
*/
    public static void sendPOSOrderPushNotification(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        Map<Id, Order__c> mapOldOrder;
        Map<Id, Order__c> newOrderMap;
        List<Order__c> pushNotiOrderList = new List<Order__c>();
        
        if(oldItems != null && oldItems.size()>0){
            mapOldOrder = (Map<Id, Order__c>) oldItems;            
        }
        for(sObject orderRec : newItems.values()){
            Order__c newOrder = (Order__c) orderRec;
            if(((newOrder.Status__c== 'Approved' && mapOldOrder.get(newOrder.Id).Status__c =='Awaiting Approval')||(newOrder.Status__c== 'Approved' && mapOldOrder.get(newOrder.Id).Status__c =='Submitted')) && newOrder.RecordTypeId ==posRecordTypeId){
                pushNotiOrderList.add(newOrder);
            }  
        }
        if(pushNotiOrderList!= null && pushNotiOrderList.size()>0){
            EDGE_OrderPushNotifHelper.populateOutMemDetails(pushNotiOrderList,true);
        }
        
    }
    /**
Method  : rollUpPromoUsed
Purpose : To increase the ‚Promotion Used‚ field of corresponding ‚Outlet Promotion‚ Record by 1 when Promo Transfer Order is submitted
also increase the associated ‚Promotion Used‚ field of 'Territory Promotion' Record by 1.
*/ 
    public static void rollUpPromoUsed(List<SObject> newItems,Map<Id, SObject> oldItems){
        
        Map<Id, Order__c> mapOldOrder;
        Map<Id, Order__c> newOrderMap;
        List<Id> OrderList = new List<Id>();
        Set<Id> orderAccSet=new Set<Id>();
        Map<Id,Set<Id>> accOrderMap= new Map<Id,Set<Id>>();
        Map<Id,Outlet_Promotion__c> mapOutletPromo=new Map<Id,Outlet_Promotion__c>();
        Map<Id,Decimal> mapOldPromoUsed=new Map<Id,Decimal>();
        Set<Id> orderWithSalesRepSet=new Set<Id>();
        Map<Id,Set<Id>> accToTerrMap=new Map<Id,Set<Id>>();
        Set<Id> accSet=new Set<Id>();
        Set<Id> promoSet=new Set<Id>();
        Set<Id> terrSet=new Set<Id>();
        String SalesRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
        List<Outlet_Promotion__c> outPromoToUpdate=new List<Outlet_Promotion__c>();
        Map<Territory_Promotion__c,Set<Outlet_Promotion__c>> terrPromToOutPromMap=new Map<Territory_Promotion__c,Set<Outlet_Promotion__c>>();
        Map<Id,Set<Outlet_Promotion__c>> promoToOPMap=new Map<Id,Set<Outlet_Promotion__c>>();
        List<Territory_Promotion__c> terrPromoToUpdate=new List<Territory_Promotion__c>();
        List<Id> orderListSR=new List<Id>();
        Set<String> outPromokeySet=new Set<String>();
        Map<Id,String> orderToStatus=new Map<Id,String>();
        
        if(oldItems != null){
            mapOldOrder = (Map<Id, Order__c>) oldItems;            
        }
        
        //ES20-13283
        for(Order__c ord:[Select Id,Status__c from Order__c WHERE Id IN:oldItems.keySet() ] ){
            orderToStatus.put(ord.Id,ord.Status__c);
        }
        for(sObject orderRec : newItems){
            Order__c newOrder = (Order__c) orderRec;
            if(orderToStatus.get(orderRec.id)== 'Submitted' && mapOldOrder.get(orderRec.id).Status__c== 'Draft' && newOrder.RecordTypeId == transferOrderRecordTypeId 
               && newOrder.Sales_Representative__c!=null && newOrder.Is_Promo_Transfer_Order__c)
            {
                OrderList.add(newOrder.Id);
                orderAccSet.add(newOrder.Account__c);
                if(accOrderMap.containsKey(newOrder.Account__c)){
                    accOrderMap.get(newOrder.Account__c).add(newOrder.Id);
                }else{
                    accOrderMap.put(newOrder.Account__c,new Set<Id>{newOrder.Id});
                }                
            }  
        }
        
        if(!accOrderMap.isEmpty()){
            //Filter order placed by Sales_Representative field User Profile 
            for(Order__c ord: [Select id from Order__c where id in :OrderList 
                               and Sales_Representative__r.Profile.Name in ('Sales Representative',
                                                                            'Distributor Sales Representative')])// AND Id IN :OrderList])
            {
                orderWithSalesRepSet.add(ord.Id); 
            }
            
            //Only keep the Orders placed by Sales Representatives
            for(Id accId : accOrderMap.keySet()){
                if(accOrderMap.get(accId) != null){
                    accOrderMap.get(accId).retainAll(orderWithSalesRepSet);
                    orderListSR.addAll(accOrderMap.get(accId));
                }
            }
            //ES20-13259
            //Get Order Items that have Promotion Products
            List<Order_Item__c> orderItemList = [Select Id,Order__r.Account__c, Promotion_Product__c,Promotion_Product__r.Promotion__c
                                                 from Order_Item__c where Order__c IN :orderListSR AND Promotion_Product__c!=null];
            
            for(Order_Item__c ordItm:orderItemList){
                String key=ordItm.Order__r.Account__c+'_'+ordItm.Promotion_Product__r.Promotion__c;
                outPromokeySet.add(key);
            }
            
            //Loop over Outlet Promotions to set Promo Used field and keep old value of Promo Used for rollup to Territory Promotion later
            for(Outlet_Promotion__c outPromo :[SELECT Id,Outlet__c, Promotion__c, Promotion_Limit__c, Promotion_Used__c 
                                               FROM Outlet_Promotion__c WHERE Outlet__c IN :accOrderMap.keySet() AND Status__c='Active'])
            {
                Id outletId = outPromo.Outlet__c;
                Set<Id> orderSet = accOrderMap.get(outletId);
                String outPromoKey=outPromo.Outlet__c+'_'+outPromo.Promotion__c;
                if(outPromokeySet.contains(outPromoKey)){
                    //Outlet_Promotion__c outPromo= op;
                    mapOldPromoUsed.put(outPromo.Id,outPromo.Promotion_Used__c);
                    //Increase Outlet Promotion Promo Used
                    if(outPromo.Promotion_Used__c!=null){
                        outPromo.Promotion_Used__c+=1;
                    }else{
                        outPromo.Promotion_Used__c=1;//set default
                    }
                    outPromoToUpdate.add(outPromo);
                    mapOutletPromo.put(outPromo.Id,outPromo);
                }
                else{
                    continue;
                }
            }
            
            if(!outPromoToUpdate.isEmpty()){ //&& outPromoToUpdate.size()>0){
                List<Database.SaveResult> orderPromoSrList = Database.update(outPromoToUpdate,false);
                
                for (Database.SaveResult sr : orderPromoSrList) {
                    if (!sr.isSuccess()) {
                        // Operation failed, so get all errors 
                        System.debug(LoggingLevel.ERROR, sr.getErrors());
                    }
                }
            }
            
            //Map<TP,Set<OP>>
            if(mapOutletPromo != null){
                for(sObject op : mapOutletPromo.values()){
                    Outlet_Promotion__c opNew=(Outlet_Promotion__c)op;
                    if(opNew.Promotion_Used__c!=null){
                        if(promoToOPMap.containsKey(opNew.Promotion__c)){
                            promoToOPMap.get(opNew.Promotion__c).add(opNew);
                        }
                        else{
                            promoToOPMap.put(opNew.Promotion__c,new Set<Outlet_Promotion__c>{opNew});
                        }
                        
                        accSet.add(opNew.Outlet__c);
                        promoSet.add(opNew.Promotion__c);
                    }
                }
                
                
                //Get Territory Promotion based on Outlet Territory and Promotion Set
                for(Territory_Promotion__c terrProm:[SELECT Id, Promotion__c, Promotion_Limit__c, Promotion_Used__c 
                                                     FROM Territory_Promotion__c WHERE Territory__c IN 
                                                     (SELECT Territory__c FROM Outlet_Territory__c WHERE Outlet__c 
                                                      IN :accSet AND Territory__r.RecordTypeId =:SalesRecordTypeId) 
                                                     AND Promotion__c IN :promoSet])
                {
                    if(promoToOPMap.get(terrProm.Promotion__c) != null){
                        terrPromToOutPromMap.put(terrProm, promoToOPMap.get(terrProm.Promotion__c));
                    }
                }
                
                for(Territory_Promotion__c terrPromo : terrPromToOutPromMap.keySet()){
                    
                    if(terrPromToOutPromMap.get(terrPromo) != null){
                        for(Outlet_Promotion__c outPromo : terrPromToOutPromMap.get(terrPromo)){
                            //Checking if previous value of Outlet Promotion was null
                            if(mapOldPromoUsed.get(outPromo.Id)==null){
                                if(terrPromo.Promotion_Used__c==null){
                                    terrPromo.Promotion_Used__c=outPromo.Promotion_Used__c;
                                }
                                else{
                                    terrPromo.Promotion_Used__c=terrPromo.Promotion_Used__c+outPromo.Promotion_Used__c;
                                }
                            }
                            else{
                                if(terrPromo.Promotion_Used__c==null){
                                    terrPromo.Promotion_Used__c=outPromo.Promotion_Used__c;
                                }
                                else{
                                    terrPromo.Promotion_Used__c=terrPromo.Promotion_Used__c-mapOldPromoUsed.get(outPromo.Id)+outPromo.Promotion_Used__c;//subtracting old value of Outlet Promotion to calculate Promo Used
                                }
                            }
                            
                        }
                        terrPromoToUpdate.add(terrPromo);
                    }
                    
                }
                
                
                if(!terrPromoToUpdate.isEmpty()){ //&& terrPromoToUpdate.size()>0){
                    List<Database.SaveResult> srList = Database.update(terrPromoToUpdate,false);
                    
                    // Iterate through each returned result
                    for (Database.SaveResult sr : srList) {
                        if (!sr.isSuccess()) {
                            // Operation failed, so get all errors 
                            System.debug(LoggingLevel.ERROR, sr.getErrors());
                        }
                    }
                }
            }
        }
    }
    
    /**
Method  : validateTransferOrder
Purpose : To validate Promo Transfer Orders submitted from Mobile.If invalid then it is set to Cancelled.
*/ 
    //ES20-13264
    public static void validatePromoTransferOrder(List<SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id, Order__c> mapOldOrder;
        List<Id> OrderList = new List<Id>();
        //Map<Id,Set<Id>> accOrderMap= new Map<Id,Set<Id>>();
        //Map<Id,Set<Id>> accToTerrMap=new Map<Id,Set<Id>>();
        //Set<Id> accSet=new Set<Id>();
        Set<Id> orderWithSalesRepSet=new Set<Id>();
        List<Order__c> ordToCancelList=new List<Order__c>();
        Map<Id,Order__c> OrderIdMap=new Map<Id,Order__c>();
        Map<Id,List<Id>> OrdertoPromoMap=new Map<Id,List<Id>>();
        Map<Id,List<Order_Item__c>> orderToOrderItemMap=new Map<Id,List<Order_Item__c>>();
        List<Order_Item__c> ordItemToUpdate= new List<Order_Item__c>();
        
        Map<Id,String> salesRepTerritoryTypeMap = new Map<Id,String>();
        Set<Id> salesRepIds = new Set<Id>();
        Set<Id> outletIds = new Set<Id>();
        Set<Id> promotionSet = new Set<Id>();
        Map<String, Outlet_Promotion__c> allOutletPromoMap = new Map<String, Outlet_Promotion__c>();
        Map<String, Territory_Promotion__c> allTerrPromoMap = new Map<String, Territory_Promotion__c>();
        Map<Id, Id> allOutletToTerrMap = new Map<Id, Id>();
        
        if(oldItems != null){
            mapOldOrder = (Map<Id, Order__c>) oldItems;            
        }         
        for(sObject orderRec : newItems){
            Order__c newOrder = (Order__c) orderRec;
            if(newOrder.RecordTypeId == transferOrderRecordTypeId && newOrder.Status__c== 'Submitted' 
               && mapOldOrder.get(orderRec.id).Status__c== 'Draft'  
               && newOrder.Sales_Representative__c!=null && newOrder.Is_Promo_Transfer_Order__c)
            {
                OrderList.add(newOrder.Id);
                OrderIdMap.put(newOrder.Id,newOrder);
                salesRepIds.add(newOrder.Sales_Representative__c);
                outletIds.add(newOrder.Account__c);
            }  
        }
        
        if(!OrderIdMap.isEmpty()){
            //Filter order placed by Sales_Representative field User Profile 
            for(Order__c ord: [Select id from Order__c where id in :OrderList 
                               and Sales_Representative__r.Profile.Name in ('Sales Representative',
                                                                            'Distributor Sales Representative')])// AND Id IN :OrderList])
            {
                orderWithSalesRepSet.add(ord.Id); 
            }
            
            
            for(Order_Item__c ordItm : [Select Id,Order__c,Order__r.Account__c,Status__c, Promotion_Product__c,Promotion_Product__r.Promotion__c
                                        from Order_Item__c where Order__c IN :orderWithSalesRepSet])
            {
                //Order with Order Item
                if(orderToOrderItemMap.containsKey(ordItm.Order__c)){
                    orderToOrderItemMap.get(ordItm.Order__c).add(ordItm);
                }else{
                    orderToOrderItemMap.put(ordItm.Order__c,new List<Order_Item__c>{ordItm});
                }
                //Order with Promotion List
                if(ordItm.Promotion_Product__c!=null){
                    Id promotionId = ordItm.Promotion_Product__r.Promotion__c;
                    if(OrdertoPromoMap.containsKey(ordItm.Order__c)){
                        OrdertoPromoMap.get(ordItm.Order__c).add(promotionId);
                    }else{
                        OrdertoPromoMap.put(ordItm.Order__c,new List<Id>{promotionId});
                    }
                    promotionSet.add(promotionId);
                }
            }
            for(User usr : [SELECT Id, Profile.Name, IsActive FROM User WHERE Id in :salesRepIds]){
                if(usr.Profile.Name.Contains(Label.EDGE_SalesRep)){//To accomodate SR and DSR
                    salesRepTerritoryTypeMap.put(usr.Id, 'Sales Territory');
                }
            }
            
            for(Outlet_Promotion__c outletPromo : [SELECT Id,Outlet__c, Promotion__c, Promotion_Limit__c, Promotion_Used__c 
                                                   FROM Outlet_Promotion__c WHERE  Status__c  = 'Active' 
                                                   AND Outlet__c IN :outletIds AND 
                                                   Promotion__c IN :promotionSet])
            {
                allOutletPromoMap.put(outletPromo.Outlet__c+'_'+outletPromo.Promotion__c, outletPromo);
            }
            
            for(Outlet_Territory__c outTerr : [SELECT Outlet__c, Territory__c FROM Outlet_Territory__c
                                               WHERE Outlet__c IN :outletIds 
                                               /*AND Territory__r.Primary_Sales_rep__c in :salesRepIds*/
                                               AND Territory__r.RecordType.Name = 'Sales Territory'])
            {
                allOutletToTerrMap.put(outTerr.Outlet__c,outTerr.Territory__c);
            }
            
            for(Territory_Promotion__c terrPromo:[SELECT Id, Territory__c,Promotion__c, Promotion_Limit__c, 
                                                  Promotion_Used__c FROM Territory_Promotion__c 
                                                  WHERE Status__c  = 'Active'
                                                  AND Territory__r.RecordType.Name = 'Sales Territory'
                                                  AND Territory__c IN (SELECT Territory__c FROM Outlet_Territory__c WHERE Outlet__c IN :outletIds) 
                                                  AND Territory__c IN (SELECT Territory__c FROM Territory_Member__c WHERE User__c IN :salesRepTerritoryTypeMap.KeySet() AND Start_Date__c <= Today AND (End_Date__c = null OR End_Date__c >= Today))
                                                  AND Promotion__c IN :promotionSet])
            {
                allTerrPromoMap.put(terrPromo.Territory__c+'_'+terrPromo.Promotion__c, terrPromo);
            }
            
            for(Id ord : OrdertoPromoMap.keySet()){
                Order__c order=OrderIdMap.get(ord);
                //Check if order is valid
                Boolean allowOrdering = EDGE_PromoOrderValidationController.isPromoOrderValid(order.Account__c,
                                                                                              order.Sales_Representative__c,
                                                                                              OrdertoPromoMap.get(ord),
                                                                                              salesRepTerritoryTypeMap,
                                                                                              allOutletPromoMap,
                                                                                              allTerrPromoMap,
                                                                                              allOutletToTerrMap
                                                                                             );
                if(!allowOrdering){
                    Order__c orderRec=new Order__c(Id=order.Id);
                    orderRec.Status__c='Cancelled';
                    ordToCancelList.add(orderRec);
                    List<Order_Item__c> orderItmList = orderToOrderItemMap.get(orderRec.Id);
                    for(Order_Item__c ordItm : orderItmList){
                        Order_Item__c ordItmRec=new Order_Item__c(Id=ordItm.Id);
                        ordItmRec.Status__c='Cancelled';
                        ordItemToUpdate.add(ordItmRec);
                    }
                }
            }
            //Update status of order
            if(!ordToCancelList.isEmpty()){
                Database.update(ordToCancelList,false);
            }
            if(!ordItemToUpdate.isEmpty()){
                Database.update(ordItemToUpdate,false);
            }
            
        }
    }
    
    /**
* productOrderItemRange
* @param productStockMap 
* @param startDate 
* @param endDate 
* @param itemOutletIds
* @return  `Map<String, List<Order_Item__c>>`
* @description: Introduced Pos time based check to collect order Items and validate quantity.
* @userStory : 147120
*/
    public static Map<String, List<Order_Item__c>> productOrderItemRange(Set<String> prodIds, DateTime startDate, DateTime endDate, List<Id> itemOutletId){
        Id posItemRecordTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByDeveloperName().get('POS_Item').getRecordTypeId();
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();   
        Map<String, List<Order_Item__c>> mapProductOrderItemAll = new Map<String,List<Order_Item__c>>();
        orderItemList = [SELECT Id, Product__c, Quantity__c, CreatedDate, Order_Item_Outlet__c FROM Order_Item__c 
                         WHERE Order_Item_Outlet__c IN :itemOutletId AND Order__r.Status__c NOT IN ('Rejected', 'Order Held') AND Product__c IN :prodIds 
                         AND RecordTypeId =: posItemRecordTypeId AND CreatedDate >= :startDate AND CreatedDate <= :endDate ORDER BY CreatedDate];
        
        for(Order_Item__c item : orderItemList){
            string key = item.Order_Item_Outlet__c + '_' + item.Product__c;
            if(mapProductOrderItemAll.containsKey(key)){
                mapProductOrderItemAll.get(key).add(item);
            } else {
                mapProductOrderItemAll.put(key, new List<Order_Item__c>{item});
            }  
        }
        return mapProductOrderItemAll;
    }
}