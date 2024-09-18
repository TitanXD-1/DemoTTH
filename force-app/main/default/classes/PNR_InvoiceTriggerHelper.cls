/**********************************************************************
    Name: PNR_InvoiceTriggerHelper
=======================================================================
    Purpose: Trigger Helper Class for Invoice
=======================================================================
    History                                                            
    -------                                                            
    VERSION     AUTHOR            DATE              DETAIL
       1.0     Saurav Paul     	  04/09/2019        Initial Development     
***********************************************************************/
public with sharing class PNR_InvoiceTriggerHelper {
    //This method will populate Order Look up filed value based on Order Number
    public static void populateOrder(List<Invoice__c> newList,Map<Id, SObject> OldItems, Boolean isUpdate){
        //Variables
        Map<Id,String> invIdOrderMap = new Map<Id,String>();
        Map<String,Id> orderMap = new Map<String,Id>();
        List<Invoice__c> invList = new List<Invoice__c>();
        //Variables
        Map<Id,Invoice__c>oldMap;
        if(newList!= null){
            oldMap = (Map<Id,Invoice__c>)OldItems;
        }
        Id dirInvRecId = Schema.SObjectType.Invoice__c.getRecordTypeInfosByName().get('Direct Invoice').getRecordTypeId();
        for(Invoice__c invObj : newList){
            if(invObj.RecordTypeId == dirInvRecId && 
               ((isUpdate && oldMap!= null && oldMap.containsKey(invObj.Id) && oldMap.get(invObj.Id).SAP_Order_Number__c != invObj.SAP_Order_Number__c)
                ||(String.isNotBlank(invObj.SAP_Order_Number__c)))){
                invIdOrderMap.put(invObj.Id,invObj.SAP_Order_Number__c);
                invList.add(invObj);
            }
        }
        if(!invIdOrderMap.isEmpty()){
            List<Order__c> orderList =  new List<Order__c>();
            orderList = [SELECT Id,SAP_Order_Number__c 
                         FROM Order__c
                        WHERE SAP_Order_Number__c IN : invIdOrderMap.values()];
            if(!orderList.isEmpty()){
                for(Order__c orderObj : orderList){
                    orderMap.put(orderObj.SAP_Order_Number__c,orderObj.Id);
                }
            }
            for(Invoice__c invObj : invList){
                if(String.isBlank(invObj.SAP_Order_Number__c)){
                    invObj.Order__c = null;
                }else if(orderMap!= null && orderMap.containsKey(invObj.SAP_Order_Number__c)){
                    invObj.Order__c = orderMap.get(invObj.SAP_Order_Number__c);
                }
            }
        }
        
    }
}