/**
@name D1_OrderSubmissionController
@description This class is controller class for getting Sales Order Product
@history
VERSION     AUTHOR         DATE            DETAIL
1.0       Manikant Prasad   15/02/2021      NCP-1400
2.0       Praveen           13/08/2021      NCP-3960
**/
public without sharing  class D1_OrderSubmissionController {
    @AuraEnabled
    public static  List<Sales_Order__c> getSalesOrderDetails(Id ordSumryID){
        List<Sales_Order__c> salesOrdList = new List<Sales_Order__c>();
        if(ordSumryID != Null){
            salesOrdList = [Select Id, Name,Purchase_Order_Number__c,Tax__c, Amount__c,Order_Split__c,CurrencyIsoCode,
                            (SELECT Id,Sales_Order__c,Quantity,Name,Product2.Name,Product2.Product_Card_Title__c,Product2.D1_Size__c,
                            Product2.D1_Type__c,Product2.D1_Category__c,Product2.D1_Brand__c,Product2.StockKeepingUnit, UnitPrice
                            FROM Order_Product_Summaries__r) 
                            From Sales_Order__c where Order_Summary__c =:ordSumryID];            
        }
        return salesOrdList;
    }
}