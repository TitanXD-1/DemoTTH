/**
 * @name: D1_OrdersTriggerHelper
 * @description: Order Trigger Helper
 * @history
 * VERSION     AUTHOR         DATE          DETAIL
 * 1.0     Kapil,Sai Kumar    2021-10-12    NCP-3363
 * 
 **/
public with sharing class D1_OrdersTriggerHelper {

    public static void validateNumberOfOrders(List<SObject> newItems){
        Set<Id> accIdSet = new Set<Id>();
        Map<String, D1_Setting__c> mapD1Setting = new Map<String, D1_Setting__c>();
        List<Order> newOrders = (List<Order>)newItems;

        //Create accIdSet
        for(Order orderNewObj : newOrders){
            if(orderNewObj.AccountId != null){
                accIdSet.add(orderNewObj.AccountId);
            }
        }
        
        if(accIdSet.size()>0){
            //Get D1 settings info
            for(D1_Setting__c settingRec : [SELECT Id, Order_Limit_Per_Day__c, Order_Limit_Per_Day_Message__c, Market__r.Code__c FROM D1_Setting__c WHERE Default__c = true]){
                mapD1setting.put(settingRec.Market__r.Code__c,settingRec);
            }

            Map<Id, Integer> mapAccIdCount = new Map<Id, Integer>();
            Map<Id,Account> mapAccIdAccount = new Map<Id,Account>([SELECT Id, Country__r.Code__c FROM Account WHERE Id IN :accIdSet]);

            //Get Count of Order which are created in last 24 hours
            for(AggregateResult orderRecCount : [SELECT COUNT(Id)noOfOrders, AccountId accId FROM Order WHERE AccountId IN :accIdSet AND DAY_ONLY(CreatedDate) =:Date.today() Group By AccountId]){
                mapAccIdCount.put((Id)orderRecCount.get('accId'), (Integer)orderRecCount.get('noOfOrders'));
            }
            for(Order orderNewObj : newOrders){
                if(mapAccIdCount.containsKey(orderNewObj.AccountId) && mapAccIdAccount.containsKey(orderNewObj.AccountId)){
                    string countryCode = mapAccIdAccount.get(orderNewObj.AccountId).Country__r.Code__c;
                    Integer orderCount = mapAccIdCount.get(orderNewObj.AccountId);
                    if(mapD1setting.containsKey(countryCode) && mapD1setting.get(countryCode).Order_Limit_Per_Day__c != null && orderCount >= mapD1setting.get(countryCode).Order_Limit_Per_Day__c){
                        orderNewObj.addError(mapD1setting.get(countryCode).Order_Limit_Per_Day_Message__c);
                    }

                    /*Increment Order Count to restrict not to process order above allowed limit
                    * Ex: Whilst querying we get count of orders which are stored in db so increasing count of orders 
                    */
                    orderCount++;
                    mapAccIdCount.put(orderNewObj.AccountId, orderCount);
                }else{
                    mapAccIdCount.put(orderNewObj.AccountId, 1);
                }
            }
        }
    }
}