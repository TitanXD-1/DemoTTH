/*
Name: EDGE_OrderFreeGoodsTmpController

Purpose: Controller Class for EDGE_OrderItemsComp VF component.

History                                                            
VERSION    AUTHOR              DATE              DETAIL
1.0        Sandip Ghosh     04/02/2020       ES20-4762 (EDGE_OrderFreeGoodsTmpController),(getOrderItems)

*/
public class EDGE_OrderFreeGoodsTmpController {
    
    public Id recordId{get;set;}
    public String baseURLStr{get;set;}
    List<Order_Item__c> orderItems{get;set;}
    
    public EDGE_OrderFreeGoodsTmpController(){
    }
    
    public List<Order_Item__c> getOrderItems() {
        
        URL baseURL = URL.getSalesforceBaseUrl();
        if(baseURL != null){
          baseURLStr = baseURL.toExternalForm();  
        }
        
        System.debug('baseURLStr = '+ baseURLStr);
        orderItems = new List<Order_Item__c>();
        if(recordId != null){
        	orderItems = [SELECT Id, Order__c,Product__r.Name,Quantity__c , Selected_UoM__c FROM Order_Item__c where Order__c = :recordId]; 
        }
        return orderItems;
    }
}