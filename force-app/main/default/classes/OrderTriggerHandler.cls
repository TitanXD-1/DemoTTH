/**
@name OrderTriggerHandler

@description Trigger Handler Class for Order__c

@history                                                            
                                                            
VERSION     AUTHOR             DATE              DETAIL
1.0         Preyanka Ghosh    20/06/2019        ES20-2249
2.0         Monalisa Halder   01/07/2019        ES20-2261,2263 
3.0         Monalisa Halder   25/06/2021        ES20-10481 stockMovementOrdStatusUpdate 
4.0         Anand U           15/05/2022         ES20-12619 (sendPOSOrderPushNotification)
5.0         Rubeena           14/06/2022         NCP-6835
6.0 		Rajarshi Lahiri	  17/07/2022		ES20-12957
7.0         Rajarshi Lahiri	  30/08/2022       ES20-13264
8.0			Saurav Prasad	  31/10/2023		147473 - Salesforce Attribute mapping with corresponding Mulesoft Attribute in JSON file for sending Free Goods Order to SAP
**/
public with sharing class OrderTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'OrderTrigger';
    
    //¬†Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){   
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    public void beforeInsert(List<SObject> newItems){
        EDGE_UtilityClass.populateGUID(newItems);
        EDGE_OrderFreeGoodsTriggerHelper.updateUserFields(newItems);
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
       
    }
    
    //Before Delete Trigsger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        //EDGE_OrderTriggerHelper.rollUpPromoUsed(newItems.values(),null);//ES20-12957
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems) {
        EDGE_OrderTriggerHelper.orderValidation(newItems);
        EDGE_OrderTriggerHelper.validatePromoTransferOrder(newItems.values(),oldItems);//ES20-13264
        EDGE_OrderTriggerHelper.rollUpPromoUsed(newItems.values(),oldItems);//ES20-12957
        EDGE_OrderStockMovementTriggerHelper.validateShedLineItemQuantity(newItems);
        EDGE_OrderTriggerHelper.orderStatusHeldCancelled(newItems,oldItems);
        EDGE_OrderTriggerHelper.changeOrderStatus(newItems, oldItems); 
        EDGE_OrderTriggerHelper.syncOrderStatus(newItems,oldItems);
        EDGE_OrderTriggerHelper.syncOrderDeliveryStatus(newItems,oldItems);
        EDGE_OrderTriggerHelper.sendEmailToDelPart(newItems,oldItems);
        EDGE_OrderTriggerHelper.updateStatusToPlaced(newItems, OldItems);
        EDGE_OrderStockMovementTriggerHelper.shedStockOperations(newItems,oldItems);
        //EDGE_OrderStockMovementTriggerHelper.shedQuantityForStockMovement(newItems , oldItems); //ES20-12747
        EDGE_OrderTriggerHelper.updateWholesalerAccNum(newItems, oldItems);
        EDGE_OrderTriggerHelper.sendEmailForOrderSubmtd(newItems , oldItems);
        EDGE_OrderFreeGoodsTriggerHelper.freeGoodOrdStatusUpdate(newItems, oldItems);
        EDGE_OrderFreeGoodsTriggerHelper.revertAPBudget(newItems, oldItems);
        
        //147473
        EDGE_OrderFreeGoodsTriggerHelper.checkSAPCallout(newItems, oldItems);
        
        //ES20-10481 -stockMovementOrdStatusUpdate 
        EDGE_OrderStockMovementTriggerHelper.stockMovementOrdStatusUpdate(newItems, oldItems);


        D1_OrderTriggerHelper.posOrderNotification(newItems, oldItems);
        EDGE_OrderTriggerHelper.sendPOSOrderPushNotification(newItems, oldItems); //ES20-12619
        


    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) { 
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}