/**
* @name D1_SalesOrderTriggerHelper
* @description Helper class for SalesOrderTriggerHandler
* @history                                                                                                                      
* VERSION   AUTHOR            DATE              DETAIL
* 1.0       Saurav Paul       23/12/2020      Initial Development
* 2.0       Ajay              06/12/2021      SAP Order update validation(NCP-5366)
* 3.0       Rubeena           13/05/2022      updateFirstOrderEmailCheck(NCP-6705)
**/

public with sharing class D1_SalesOrderTriggerHelper {

    /**
     * @description update Sales Order Status from Queued to New
     * @param newItems 
     */   
    public static void updateSalesOrderStatus(List<SObject> newItems){
        for(SObject objVal : newItems){
            Sales_Order__c salesOdrObj  = (Sales_Order__c)objVal;
            if(salesOdrObj.Order_Status__c == 'Queued' && salesOdrObj.Status_Queued_Action__c == 'Fire Trigger' ){
                salesOdrObj.Order_Status__c = 'New';
            }   
            salesOdrObj.Status_Queued_Action__c = 'None';
        }
    }  

    /**
     * @description update Sales Order Number with Name value
     * @param salesOdrIdList 
     */    
    @future
    public static void updateOrderNumber(Set<Id> salesOdrIdList){
        List<Sales_Order__c> salesOdrUpdtList = new List<Sales_Order__c>();
        for(Sales_Order__c salesOdrObj : [SELECT Id,Name,Order_Number__c FROM Sales_Order__c
                                         WHERE Id IN : salesOdrIdList]){
            
            salesOdrObj.Order_Number__c = salesOdrObj.Name;
            salesOdrUpdtList.add(salesOdrObj);
        }
        if(!salesOdrUpdtList.isEmpty()){
            update salesOdrUpdtList;
        }
    }

    /**
     * @description validate SAP order update on Sales order object(SAP_Order_Number__c field update)
     * @param  listNewSalesOrderObj    listNewSalesOrderObj SAP_Order_Number__c new values
     * @param  mapOldIdToSalesOrderObj mapOldIdToSalesOrderObj SAP_Order_Number__c old values
     * @userStory NCP-5366
     */
    public static void validateSAPOrderUpdate(List<sObject> listNewSalesOrderObj, Map<Id,sObject> mapOldIdToSalesOrderObj){
        List<Sales_Order__c> listNewSalesOrder = (List<Sales_Order__c>) listNewSalesOrderObj;
        Map<Id, Sales_Order__c> mapOldIdToSalesOrder = (Map<Id, Sales_Order__c>) mapOldIdToSalesOrderObj;
        
        for(Sales_Order__c newSalesOrder: listNewSalesOrder){
            Sales_Order__c oldSalesOrder = mapOldIdToSalesOrder.get(newSalesOrder.Id);

            //Validate sales order update
            if( newSalesOrder.Sales_Area__c != oldSalesOrder.Sales_Area__c
                || newSalesOrder.Shipto_Party__c != oldSalesOrder.Shipto_Party__c
                || newSalesOrder.Soldto_Party__c != oldSalesOrder.Soldto_Party__c
            ){
                //Rejected
                newSalesOrder.addError('Update Failed, New sales order values(Sales Area, Shipto Party or Soldto Party) doesn\'t match with existing values.');
            }
        }

    }

    /**
     * @description : Method to update D1 First order email check on contact 
     * @userStory : NCP-6705
     * @param newIdToSalesOrderObj 
     */
    public static void updateFirstOrderEmailCheck(Map<Id,sObject> newIdToSalesOrderObj){
        Map<Id, Sales_Order__c> newSalesOrderMap = (Map<Id, Sales_Order__c>) newIdToSalesOrderObj;

        Set<Id> contactIdSet = new Set<Id>();
        Set<Id> userIdSet = new Set<Id>();
        List<Contact> toUpdateContact = new List<Contact>();

        for(Sales_Order__c salesOrder : newSalesOrderMap.values()){
            userIdSet.add(salesOrder.CreatedById);
        }

        if(!userIdSet.isEmpty()){
            for(User user : [Select Id, ContactId FROM User WHERE Id IN : userIdSet])			{
                contactIdSet.add(user.ContactId);
            }

        }

        if(!contactIdSet.isEmpty()){
            for(Contact con : [Select Id, D1_First_order_email_required__c FROM Contact WHERE Id IN : contactIdSet AND D1_First_order_email_required__c = TRUE]){
                con.D1_First_order_email_required__c = FALSE;
                toUpdateContact.add(con);
            }
        }
        
        if(!toUpdateContact.isEmpty()){
            update toUpdateContact;
        }

    }
    
}