/**
* @Name: D1_HomePageCompsController
* History                                                                                                                     
* VERSION	AUTHOR            		DATE            DETAIL
* 1.0		Pratap				 06/06/2023		Initial Development (NCP-8225)
**/
public without sharing class D1_HomePageCompsController {
    @AuraEnabled(cacheable = true)
    public static SalesOrdertWrapper getSalesOrders(){
        try {
            Map<String,List<Sales_Order__c>> salesOrderMap = new Map<String,List<Sales_Order__c>>();
            List<Sales_Order__c> tempList = new List<Sales_Order__c>();
            
            Id userId = UserInfo.getUserId();
            String accId = [SELECT Effective_Account_Id__c FROM User WHERE Id =: userId LIMIT 1].Effective_Account_Id__c;
            String cpaId = [SELECT Id FROM ContactPointAddress WHERE ParentId =: accId AND AddressType = 'Shipping' LIMIT 1].Id;

            for(Sales_Order__c sO : [SELECT Id, SAP_Order_Number__c, Delivery_Date__c, Order_Summary__c ,
                                    Purchase_Order_Number__c, CreatedDate , Order_Summary__r.Sales_Area__r.Max_Order_Line_Items__c,
                                    Order_Summary__r.Order_Product_Count__c
                                    FROM Sales_Order__c 
                                    WHERE Order_Summary__r.AccountId =: accId AND Order_Summary__c != NULL
                                    ORDER BY Order_Summary__r.OrderNumber DESC, CreatedDate 
                                    LIMIT 5])
            {
                tempList = salesOrderMap.containsKey(sO.Order_Summary__c) ? salesOrderMap.get(sO.Order_Summary__c) : new List<Sales_Order__c>();
                tempList.add(sO);
                salesOrderMap.put(sO.Order_Summary__c, tempList);
            }
            
            SalesOrdertWrapper wrpReturn = new SalesOrdertWrapper();
            wrpReturn.salesOrderMap = salesOrderMap;
            wrpReturn.cpaId = cpaId;
            return wrpReturn;

        } catch (Exception e) {
            throw new AuraHandledException('error '+e.getMessage());
        }
    }

    /*Wrapper to return*/
    public class SalesOrdertWrapper{
        @AuraEnabled public String cpaId;
        @AuraEnabled public Map<String,List<Sales_Order__c>> salesOrderMap;
    }

}