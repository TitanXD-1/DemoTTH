/**
* @Name: EDGE_StockMovementOrderMailHandler

* @Purpose: To Send Email to Delivery Partner with Order and Order Item details.

* @History                                                            
                                                           
* @VERSION   AUTHOR                    DATE              DETAIL
*  1.0       Uppalapati Anand          13/08/2021        ES20-10486
*/


public class EDGE_StockMovementOrderMailHandler {
    
    public static void getOrderDetails(Map<Id,Order__c> orderTobeMailedMap){
        
        String stockMovementRecId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        String shedItemRecId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
        String productPOSRecId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        List<Order__c> ordertoUpdateList = new  List<Order__c>();
        List<Order_Item__c> orderItemToUpdate = new  List<Order_Item__c>();
        List<Product__c> products = new List<Product__c>();
        List<Order_Item__c> orderItemList = new  List<Order_Item__c>();
        Set<Order__c> orderId=new Set<Order__c>();
        List<Messaging.SingleEmailMessage> orderEmail = new List<Messaging.SingleEmailMessage>();
        Map<String,List<Order_Item__c>> orderListOrderItemMap = new Map<String,List<Order_Item__c>>();
        Map<Id,Order__c> ordersToBeSentMap = new Map<Id,Order__c>();
        Map<Id,Order__c> ordersMap = new Map<Id,Order__c>();
        List<Delivery_Partner__c> delPartLst=new List<Delivery_Partner__c>();
        
        if(orderTobeMailedMap != null && !orderTobeMailedMap.isEmpty()){

        for(Order__c Ords:[select id,Name,Delivery_Partner__c,Account__c,Delivery_Partner__r.Email__c,Delivery_Location__c,Sales_Representative__r.Name ,Sales_Representative__r.Email,
        Sales_Representative__r.MobilePhone,Order_Type__c,account__r.BillingCity,account__r.BillingCountry,account__r.BillingPostalCode,account__r.BillingStreet  from order__c where id IN:orderTobeMailedMap.keyset()]){

            ordersMap.put(Ords.id,Ords);
        }
        }
        if(orderTobeMailedMap != null && !orderTobeMailedMap.isEmpty()){
            orderItemList = [Select Id,Product__c,Product__r.Product_Code__c,Product__r.Record_Type_Name__c,Product__r.Description__c,
                             Reason_Code__c,Reason__c,RecordTypeId,Product__r.Name,Product__r.Long_Description__c,Order__c,Order__r.Delivery_Partner__c,Quantity__c,Selected_UoM__c
                             from Order_Item__c where status__c = 'Ready for Order' AND RecordTypeId=:shedItemRecId AND Order__c IN :orderTobeMailedMap.keySet()];//:orderList];
        }
        if(orderItemList!=null && orderItemList.size()>0){
            for(Order_Item__c ordItem:orderItemList){
                if(ordItem.Product__r.Record_Type_Name__c !='POS'){
                    if(!ordersToBeSentMap.containsKey(ordItem.Order__c)){
                        ordersToBeSentMap.put(ordItem.Order__c, orderTobeMailedMap.get(ordItem.Order__c));
                    }
                }
            }    
        }
        if(ordersToBeSentMap != null && !ordersToBeSentMap.isEmpty()){
            
            for(Order_Item__c ordItem : orderItemList){
                if(ordersToBeSentMap.containsKey(ordItem.Order__c)){
                    if(orderListOrderItemMap.containsKey(ordItem.Order__c)){
                        orderListOrderItemMap.get(ordItem.Order__c).add(ordItem);
                    }else{
                        orderListOrderItemMap.put(ordItem.Order__c,new List<Order_Item__c> {ordItem});
                    }
                }
            }
            for(Order__c ord : ordersMap.values() ){
                String email='';	
                list<Order__c> orList = new List<Order__c> {ord};
                   
                if(ord.Delivery_Partner__c != null){
                        email = ord.Delivery_Partner__r.Email__c;
                        Messaging.SingleEmailMessage delPartMail = new Messaging.SingleEmailMessage(); 
                        String body = EDGE_StockMovementOrderEmailHelper.getStockMovementMailTemplate(orList, orderListOrderItemMap); 
                        delPartMail=EDGE_UtilityClass.setEmailBody(null,null,null,body);
                        delPartMail.setToAddresses(new String[] {email});
                        orderEmail.add(delPartMail);
                }
                
            }
            
            if(orderEmail != null && orderEmail.size() > 0){
                Messaging.sendEmail(orderEmail, false);
                for(Order__c ordRec : ordersToBeSentMap.values()){
                    ordRec.status__c='Order Placed';
                    ordertoUpdateList.add(ordRec);
                }
                
                for(List<Order_Item__c> tempOrdItemList : orderListOrderItemMap.values()){
                    for(Order_Item__c orderItem : tempOrdItemList){
                        orderItem.Status__c = 'Order Placed';
                        orderItemToUpdate.add(orderItem);
                    }
                }
                
                if(ordertoUpdateList.size()>0 && Schema.sObjectType.Order__c.isUpdateable()){
                    update ordertoUpdateList;
                }
                if(orderItemToUpdate.size()>0 && Schema.sObjectType.Order_Item__c.isUpdateable()){
                    update orderItemToUpdate;
                }
            }
            
        }
        
    }
}