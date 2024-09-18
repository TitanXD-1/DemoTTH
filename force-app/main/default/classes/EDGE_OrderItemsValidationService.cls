/**
 * @name : EDGE_OrderItemsValidationService
 * @description : Rest API Service to validate order item
 * @history
 * VERSION          AUTHOR                      DATE                DETAIL
 * 1.0              Sagar Barman                09/07/2019          ES20-3002
 * 2.0              Preyanka Ghosh              26/07/2019          Change to Simplify
 * 3.0              Monalisa Halder             01/10/2019          ES20-4602
 * 4.0              Kapil Baliyan               25/01/2024          150478
 */
@RestResource(urlMapping='/OrderItemsValidationService/*')
global with sharing class EDGE_OrderItemsValidationService {
    
    @HttpPost    
    global static OrderResultModel validateOrderItems(List<EDGE_OrderProductWrapper> orderItemList){ 
        List<Order_Item__c> lstOrderItem = new List<Order_Item__c>();
        Map<Order_Item__c,Id> salesRepItemMap = new Map<Order_Item__c,Id>(); 
        Map<Id,Order_Item__c> mapProductOrder = new Map<Id,Order_Item__c>();
        Map<Order_Item__c,Id> mapOrderItemAccount = new Map<Order_Item__c,Id>();
        // Change for ES20-4602 Start
        Map<Order_Item__c,Id> mapShedOrderItemAccount = new Map<Order_Item__c,Id>();
        OrderResultModel orderResult = new OrderResultModel();
        Set<Id> listAccountsIds = new Set<Id>(); 
        
        for(EDGE_OrderProductWrapper productWrapper : orderItemList){
            Order_Item__c orderItem = new Order_Item__c();
            orderItem.Product__c = productWrapper.product;
            orderItem.Quantity__c = productWrapper.quantity;
            orderItem.Type__c = productWrapper.orderType;
            orderItem.GUID__c = productWrapper.guid;
            orderItem.RecordTypeId =  Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(productWrapper.recordTypeName).getRecordTypeId();
            orderItem.Order_Item_Outlet__c = productWrapper.accountId; //150478
            orderItem.Product__r = new Product__c(Id=productWrapper.product, Limit_Per_Order__c = null); //150478

            //Create Sales Rep Map
            salesRepItemMap.put(orderItem,productWrapper.salesRep);
            
            //Create Product Map is Type is Warehouse
            if((productWrapper.orderType == 'Warehouse' || productWrapper.orderType == 'Shed') && productWrapper.recordTypeName != 'Shed Item'){
                lstOrderItem.add(orderItem);
                mapProductOrder.put(orderItem.Product__c,orderItem); 
                mapOrderItemAccount.put(orderItem,productWrapper.accountId);
            }else if(productWrapper.recordTypeName == 'Shed Item'){
                // Change for ES20-4602 Start
                mapShedOrderItemAccount.put(orderItem,productWrapper.salesRep);
                listAccountsIds.add(productWrapper.accountId);
            }
        }
        
        //Process Warehouse POS Order
        if(lstOrderItem != null && lstOrderItem.size()>0){
            //Call Edge_OrderTrigger to create Map depending upon type
            EDGE_OrderTriggerHelper.getLineItemPerType(lstOrderItem);
            
            //This will work for Shed Type of Order item
            if(EDGE_OrderTriggerHelper.mapProductOrderItemShed != null && (EDGE_OrderTriggerHelper.mapProductOrderItemShed).size()>0){
                Map<Order_Item__c, String> mapShedValidation = EDGE_OrderTriggerHelper.validateShedStockQuantity(salesRepItemMap);            
                if(mapShedValidation != null && mapShedValidation.size()>0){
                    for(Order_Item__c orderItem : mapShedValidation.keySet()){
                        orderResult.resultMessage = 'Failed';
                        EDGE_OrderValidationWrapper ovWrapper = new EDGE_OrderValidationWrapper();
                        ovWrapper.guid = orderItem.GUID__c;
                        ovWrapper.reason = mapShedValidation.get(orderItem);                       
                        orderResult.orderWrapperList.add(ovWrapper); 
                    }                
                } else {
                    if(orderResult.resultMessage != 'Failed'){ //already failed in previous validation check
                        orderResult.resultMessage = 'Success';     
                    } 
                }            
            }
            
            //This will work for Warehouse Type of Order item
            if(mapProductOrder != null && mapProductOrder.size()>0){
                Map<Id,Decimal> mapProductLimit = new Map<Id,Decimal>(); 
                
                for(Product__c product : [Select Id, Limit_Per_Order__c from Product__c where Id IN :mapProductOrder.keySet()]){
                    for(Order_Item__c orderItem : lstOrderItem){
                        if(orderItem.Type__c == 'Warehouse' && mapProductOrder.containsKey(product.Id) && orderItem == mapProductOrder.get(product.Id)){
                            orderItem.Product__r.Limit_Per_Order__c = product.Limit_Per_Order__c; //150478 : Added because this is used in ValidateStockQuantity Method
                            if(orderItem.Quantity__c > product.Limit_Per_Order__c){                        
                                orderResult.resultMessage = 'Failed';
                                
                                EDGE_OrderValidationWrapper ovWrapper = new EDGE_OrderValidationWrapper();
                                ovWrapper.guid = orderItem.GUID__c;
                                ovWrapper.reason = 'Quantity in Order Item exceeded Limit Per Order Of Product';
                                orderResult.orderWrapperList.add(ovWrapper);
                            } else {                         
                                if(EDGE_OrderTriggerHelper.mapProductOrderItemWare.containsKey(product.Id)){
                                    EDGE_OrderTriggerHelper.mapProductOrderItemWare.get(product.Id).add(orderItem);
                                } else {
                                    EDGE_OrderTriggerHelper.mapProductOrderItemWare.put(product.Id, new List<Order_Item__c>{orderItem});
                                }
                            }                        
                        }
                    }
                }            
                
                Map<Order_Item__c, String> mapWareValidation = EDGE_OrderTriggerHelper.validateStockQuantity(mapOrderItemAccount);

                if(mapWareValidation != null && mapWareValidation.size()>0){
                    for(Order_Item__c orderItem : mapWareValidation.keySet()){
                        orderResult.resultMessage = 'Failed';
                        EDGE_OrderValidationWrapper ovWrapper = new EDGE_OrderValidationWrapper();
                        ovWrapper.guid = orderItem.GUID__c;
                        ovWrapper.reason = mapWareValidation.get(orderItem);                       
                        orderResult.orderWrapperList.add(ovWrapper); 
                    }                
                } else {
                    if(orderResult.resultMessage != 'Failed'){ //already failed in previous validation check
                        orderResult.resultMessage = 'Success';     
                    } 
                }
            }            
        }
        
        // Change for ES20-4602 Start
        if(mapShedOrderItemAccount != null && mapShedOrderItemAccount.size()>0){
            Map<Order_Item__c, String> mapShedItemValidation = EDGE_OrderStockMovementTriggerHelper.validateStockQuantity(mapShedOrderItemAccount, salesRepItemMap);

            if(mapShedItemValidation != null && mapShedItemValidation.size()>0){
                for(Order_Item__c orderItem : mapShedItemValidation.keySet()){
                    orderResult.resultMessage = 'Failed';
                    EDGE_OrderValidationWrapper ovWrapper = new EDGE_OrderValidationWrapper();                    
                    ovWrapper.guid = orderItem.GUID__c;
                    ovWrapper.reason = mapShedItemValidation.get(orderItem);                       
                    orderResult.orderWrapperList.add(ovWrapper);
                }                
            } else {
                if(orderResult.resultMessage != 'Failed'){ 
                    orderResult.resultMessage = 'Success';
                } 
            } 
        }
        
        // Change for ES20-4602 End
        System.debug(LoggingLevel.INFO, orderResult);
        return orderResult;
    }
    
    //wrapper class for mobile response
    global class OrderResultModel{
        public String resultMessage = '';
        public List<EDGE_OrderValidationWrapper> orderWrapperList;
        
        public OrderResultModel(){
            orderWrapperList = new List<EDGE_OrderValidationWrapper>(); 
        }
        
    }
}