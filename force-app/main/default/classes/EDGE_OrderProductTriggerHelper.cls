/**
 
*@ description :EDGE_OrderProductTriggerHelper - Trigger Helper Class for OrderProductTriggerHandler
*@ History :
1.0         Sagar Kumar Barman 26/06/2019        
2.0         Manikant           ES20-10166        Modified the existing method(updateParentOrderStatus)
3.0         Manikant 		   ES20-10229        updateStockAllocation ,  decreaseStockQuantity,  increaseStockQuantity  
4.0         Dinesh Sharma      ES20-10902        decreaseStockQuantity updated to reduce stock when free Good order is placed
5.0         Monalisa Halder    ES20-10812        updateStockAllocation (“Stock Adjustment Reported” and Quantity, I will reduce the stock available.)
6.0			Aparajita          ES20-12674        Added block for Other delivery location for POS orders

**/
public with sharing class EDGE_OrderProductTriggerHelper {
    
    //the below method updates the parent Order status to Delivered To Customer or Delivery To shed
    public static void updateParentOrderStatus(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){	
        Set<Id> orderItemSet = new Set<Id>();
        Set<Id> parentOrderSet = new Set<Id>();        
        List<String> eligibleStatus = System.Label.EDGE_OrderLineItemStatus.split(','); 
        List<Order_Item__c> orderLineItemList = new List<Order_Item__c>();
        Map<Id,List<Order_Item__c>> orderWithLineItemMap = new Map<Id,List<Order_Item__c>>();
        Map<Id,Boolean> orderDeliveredMap = new Map<Id,Boolean>();
        List<Order__c> lstOrderToUpdate = new List<Order__c>();
        Id posOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('POS Order').getRecordTypeId();
        Id stockMvmntRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        for(SObject sObj : newItems.values()){
            Order_Item__c newOrderItem = (Order_Item__c)sObj;
            Order_Item__c oldOrderItem;            
            if(oldItems!= null && oldItems.containsKey(newOrderItem.Id)){
                oldOrderItem = (Order_Item__c)oldItems.get(newOrderItem.Id);
            }
            if((newOrderItem.Status__c != oldOrderItem.Status__c) && (eligibleStatus.contains(newOrderItem.Status__c))               
              ){
                  orderItemSet.add(newOrderItem.Id);
                  parentOrderSet.add(newOrderItem.Order__c);                  
              }
        }  
        
        if(Schema.sObjectType.Order__c.isAccessible() && Schema.sObjectType.Order_Item__c.isAccessible()){
            Map<Id,Order__c> parentOrderMap = new Map<Id,Order__c>([SELECT Id,Delivery_Location__c,RecordTypeId,Status__c FROM Order__c WHERE Id  IN: parentOrderSet
                                                                    AND( RecordTypeId =: posOrderRecTypeId OR  RecordTypeId =: stockMvmntRecTypeId )]);
            
            //get order line items
            orderLineItemList = [SELECT Id,Order__c,Status__c FROM Order_Item__c WHERE Order__c IN : parentOrderMap.keySet()];
            //populate orderWithLineItemMap
            if(orderLineItemList != null && !orderLineItemList.isEmpty()){
                for(Order_Item__c ordItem : orderLineItemList){
                    if(orderWithLineItemMap.containsKey(ordItem.Order__c)){
                        orderWithLineItemMap.get(ordItem.Order__c).add(ordItem);                        
                    }
                    else{
                        orderWithLineItemMap.put(ordItem.Order__c, new List<Order_Item__c>{ordItem});
                    }
                }
            }        
            //populate map of Orders whose Line items not delivered
            if(orderWithLineItemMap != null && !orderWithLineItemMap.isEmpty()){
                for(Id ordId : orderWithLineItemMap.keySet()){
                    Boolean statusMisMatch = false;
                    for(Order_Item__c ordItem : orderWithLineItemMap.get(ordId)){
                        if(!eligibleStatus.contains(ordItem.Status__c)){
                            statusMisMatch = true;	
                        } 
                    }
                    orderDeliveredMap.put(ordId,statusMisMatch);
                }                        
                for(Id ordId : orderWithLineItemMap.keySet()){
                    if(orderDeliveredMap.get(ordId) == false){
                        if(parentOrderMap.get(ordId).Delivery_Location__c == 'Shed' && parentOrderMap.get(ordId).RecordTypeId == posOrderRecTypeId){
                            parentOrderMap.get(ordId).Status__c = 'Shed to Customer';                        
                        }else if((parentOrderMap.get(ordId).Delivery_Location__c == 'Outlet' || parentOrderMap.get(ordId).Delivery_Location__c == 'Other') && parentOrderMap.get(ordId).RecordTypeId == posOrderRecTypeId){//ES20-12674
                            parentOrderMap.get(ordId).Status__c = 'Delivered to Customer';   
                        }else if(parentOrderMap.get(ordId).Delivery_Location__c == 'Shed' && parentOrderMap.get(ordId).RecordTypeId == stockMvmntRecTypeId){
                            parentOrderMap.get(ordId).Status__c = 'Delivered To Shed';
                        }
                        lstOrderToUpdate.add(parentOrderMap.get(ordId));
                    }	    
                }    
            }                   
            if(Schema.sObjectType.Order__c.isUpdateable()){
                update lstOrderToUpdate;  
            }    
        } 
    }
    /** 
    *@  Method : updateStockAllocation  



    *@  Req :  ES20-10229,ES20-10812,ES20-10902
    *@  This will populate stock in the order product record based on the unique key combination of shed and product record 
    **/




    public static void updateStockAllocation(List<SObject> newItems, Map<Id, SObject> oldItems){
        //Variables
        Id freeGoodOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Id freeGoodOrderItemTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Id stockAdjOrderRecTypeId = Schema.SObjectType.Order__c.getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        Id stockAdjOrderItemTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        Set<Id> productIdSet = new Set<Id>();
        Set<Id> orderIdSet = new Set<Id>();
        Set<Id> shedIdSet = new Set<Id>();
        List<Order__c> orderListToUpdate = new List<Order__c>();
        List<Order_Item__c> orderItemList = new List<Order_Item__c>();
        Map<Id,List<Order_Item__c>> orderWithItemMap = new Map<Id,List<Order_Item__c>>();
        Map<Id,Order__c> orderMap;
        Map<String,Stock__c> stockMap = new Map<String,Stock__c> ();
        List<ID>orderItemListSet = new List<Id>();
        List<Order_Item__c> orderItemToUpdate = new List<Order_Item__c>();
        

        Map<Id, Order_Item__c> oldOrderMap;
        
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order_Item__c>)oldItems;
        }

        
        for(SObject sObj :newItems ){
            Order_Item__c newOrderItem = (Order_Item__c)sObj;
            if(String.isNotBlank(newOrderItem.Order__c) && String.isNotBlank(newOrderItem.Product__c)

               && ((oldOrderMap.get(newOrderItem.Id).Status__c != 'Delivered to Customer' && newOrderItem.Status__c == 'Delivered to Customer' && newOrderItem.RecordTypeId == freeGoodOrderItemTypeId)
              || (oldOrderMap.get(newOrderItem.Id).Status__c != 'Stock Adjustment Reported' && newOrderItem.Status__c == 'Stock Adjustment Reported' && newOrderItem.RecordTypeId == stockAdjOrderItemTypeId))){


                   orderIdSet.add(newOrderItem.Order__c);
                   productIdSet.add(newOrderItem.Product__c);
                   orderItemList.add(newOrderItem);
                   if(orderWithItemMap!= null && orderWithItemMap.containsKey(newOrderItem.Order__c)){
                       orderWithItemMap.get(newOrderItem.Order__c).add(newOrderItem);
                   }else{
                       orderWithItemMap.put(newOrderItem.Order__c, new List<Order_Item__c>{newOrderItem});
                   }
               }
        }
        
        if(!orderIdSet.isEmpty()){
            orderMap = new Map<Id,Order__c>([SELECT Id,Account__c,Shed__c,RecordTypeId FROM Order__c 
                                             WHERE Id IN :orderIdSet 
                                             AND ((Status__c = 'Delivered to Customer' AND RecordTypeId =:freeGoodOrderRecTypeId)
                                             OR (Status__c = 'Stock Adjustment Reported' AND RecordTypeId =:stockAdjOrderRecTypeId))
                                             AND Order_Type__c = 'Shed']);//add free good order recordtype check
           
            if(!orderMap.isEmpty()){
                for(Order__c ordrObj : orderMap.values()){
                    if(ordrObj.RecordTypeId == freeGoodOrderRecTypeId){
                    shedIdSet.add(ordrObj.Shed__c);
                    }else if(ordrObj.RecordTypeId == stockAdjOrderRecTypeId){
                        shedIdSet.add(ordrObj.Account__c);
                    }
                    
                }
                if(!shedIdSet.isEmpty() && !productIdSet.isEmpty()){
                    list<Stock__c> stkList = new list<Stock__c>();
                    stkList = [SELECT Id,Shed__c,Market_Assortment_Product__r.Product__c FROM Stock__c  WHERE Shed__c IN : shedIdSet AND Market_Assortment_Product__r.Product__c IN : productIdSet];
                    for(Stock__c stkObj :stkList ){
                                               String cmpKey = stkObj.Shed__c+'_'+stkObj.Market_Assortment_Product__r.Product__c;
                                               stockMap.put(cmpKey,stkObj);
                                           }
                }
                
                for(Id odrId : orderWithItemMap.keySet()){
                    if(orderMap!= null && orderMap.containsKey(odrId)){
                        for(Order_Item__c odrItemObj : orderWithItemMap.get(odrId)){
                            String itmCmpkey = '';
                            if(odrItemObj.RecordTypeId == freeGoodOrderItemTypeId){
                            	itmCmpkey = orderMap.get(odrId).Shed__c+'_'+odrItemObj.Product__c;    
                            }else if(odrItemObj.RecordTypeId == stockAdjOrderItemTypeId){
                                itmCmpkey = orderMap.get(odrId).Account__c+'_'+odrItemObj.Product__c;
                            }
                            if(stockMap!= null && stockMap.containsKey(itmCmpkey)){
                                odrItemObj.Stock__c = stockMap.get(itmCmpkey).Id;
                                orderItemListSet.add(odrItemObj.id);
                                orderItemToUpdate.add(odrItemObj);
                            }
                        }        
                    }
                }
            }
        }
        
        if(orderItemListSet.size() > 0){
             decreaseStockQuantity(orderItemListSet);
        }
      


    }
      
    



    /** Method : decreaseStockQuantity  
	  *@ Req :  ES20-10229
 	  *@ This will increase / decrease stock quantity in stock record , if the status will be changed to order placed / Cancelled 
    **/
    @future
    public static void decreaseStockQuantity(List<ID> newItems){
        Id freeGoodOrderRecTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Id stockAdjOrderItemTypeId = Schema.SObjectType.Order_Item__c.getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        set<Id> stockSetIds = new set<Id>();
        List<Stock__c> updateStockList = new List<Stock__c>();
        Map<Id, Decimal> orderProductQuantityMap = new Map<Id, Decimal>();

        Map<Id, Decimal> orderProductStockAdjQuantityMap = new Map<Id, Decimal>();
        Decimal quantity = 0.0;
        for(Order_Item__c newOrderItem : [Select id ,RecordTypeId,Stock__c, Status__c,Quantity__c,Delivered_Quantity__c from Order_Item__c where id =:newItems]){
            if(newOrderItem.Status__c == 'Delivered to Customer' && newOrderItem.RecordTypeId == freeGoodOrderRecTypeId){

                if(orderProductQuantityMap.containsKey(newOrderItem.Stock__c)){
                    quantity = orderProductQuantityMap.get(newOrderItem.Stock__c) + newOrderItem.Quantity__c;
                    orderProductQuantityMap.put(newOrderItem.Stock__c,quantity); 
                }else{
                    orderProductQuantityMap.put(newOrderItem.Stock__c,newOrderItem.Quantity__c);
                }



                
            }  
            if(newOrderItem.Status__c == 'Stock Adjustment Reported' && newOrderItem.RecordTypeId == stockAdjOrderItemTypeId){
               if(orderProductStockAdjQuantityMap.containsKey(newOrderItem.Stock__c)){
                    quantity = orderProductStockAdjQuantityMap.get(newOrderItem.Stock__c) + newOrderItem.Quantity__c;
                    orderProductStockAdjQuantityMap.put(newOrderItem.Stock__c,quantity); 
                }else{
                    orderProductStockAdjQuantityMap.put(newOrderItem.Stock__c,newOrderItem.Quantity__c);
        }
    }
    

        }
        if(orderProductQuantityMap != null || orderProductStockAdjQuantityMap != null){
            for(Stock__c stockRecd : [ SELECT Id,Consumed_Stock__c,Original_Stock__c  FROM Stock__c WHERE Id IN : orderProductQuantityMap.keyset() OR Id IN : orderProductStockAdjQuantityMap.keyset()]){            
                if(orderProductQuantityMap != null && orderProductQuantityMap.size()>0){
                   stockRecd.Consumed_Stock__c = stockRecd.Consumed_Stock__c + orderProductQuantityMap.get(stockRecd.Id); 
                }
                if(orderProductStockAdjQuantityMap != null && orderProductStockAdjQuantityMap.size()>0){
                    stockRecd.Original_Stock__c = stockRecd.Original_Stock__c + orderProductStockAdjQuantityMap.get(stockRecd.Id); 
                }
                updateStockList.add(stockRecd);
                
            }  
        }
        DataBase.update (updateStockList,False);
    }
   

}