/*
*@Name: EDGE_OrderFreeGoodsTriggerHelper
*
*@Purpose: Trigger Helper Class for Free goods Order.
*
*@History                                                            
*
* VERSION		AUTHOR				DATE				DETAIL
* 1.0		Manikant P			20/01/2020			ES20-4759,ES20-4483(freeGoodOrdStatusUpdt)
* 1.1		Manikant P			05/02/2020			ES20-6320,ES20-4985,ES20-4984,ES20-5012(freeGoodOrdStatusUpdt)
* 2.0		Shahbaz Khan		05/02/2020			ES20-6301 (updateUserFields),(compareThresholdValue)
* 3.0		Sandip Ghosh		05/02/2020			ES20-4992 (revertAPBudget)[SFDC_Ability to revert the A&P budget  if order is rejected]
* 3.1		Saurav Prasad		31/10/2023			147473 - Salesforce Attribute mapping with corresponding Mulesoft Attribute in JSON file for sending Free Goods Order to SAP
* 3.2       Dipanjan Das        15/07/2024          152728 - Added Method getCountryWithSAPMap and changed checkSAPCallout to Add Free Goods SAP Automation Condition
*/

public without sharing class EDGE_OrderFreeGoodsTriggerHelper {
    
    //Global Variables
    private static String freeGoodRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
    
    /*
    method :freeGoodOrdStatusUpdate
    Purpose : When A&P Market is unchecked in market setting then This method will update the status to 'ready for order' of free goods order if the total order cost is less than the 
              available amount of territory budget tagged in that order , else status will become 'Order Held'. 
              When A&P Market is checked in market setting then this method will check for threshold validation and order free goods 
              amount based on that it will trigger the approval process and will assign the order for approval to the respective user.
    */
    public static void freeGoodOrdStatusUpdate(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> contractIdSet = new Set<Id>();
        Set<Id> pickUpoptionIdSet = new Set<Id>();
        Set<Id> freeGoodOrderIdSet = new Set<Id>();
        
        Map<Id, Order__c> oldOrderMap;
        Map<Id, Id> ordTerBudgMap = new Map<Id, Id>();
        Map<Id, Id> outletGeoMap = new Map<Id, Id>();
        Map<Id, Contract> mapContractAP = new Map<Id,Contract>();
        Map<Id, Territory_Budget__c> terrBudgetMap = new Map<Id,Territory_Budget__c>();
        Map<Id, Market_Setting__c> countryAPcostMap = new Map<Id,Market_Setting__c>();
        
        List<Order__c> updateOrderList = new List<Order__c>();
        List<Territory_Budget__c> updateTerrBudgetList = new List<Territory_Budget__c>();
        List<Order__c> freeGoodOrderList = new List<Order__c>();
        List<Order__c> orderThresholdvalList = new List<Order__c>();
        List<Contract> updateContractList = new List<Contract>();
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order__c>)oldItems;
        }
        
        for(sObject obj : newItems.values()){
            Order__c newOrder = (Order__c)obj;
            if(newOrder.RecordTypeId == freeGoodRecordTypeId && newOrder.Status__c == EDGE_Constant.ORDER_SUBMITTED 
               && newOrder.Status__c != oldOrderMap.get(newOrder.Id).Status__c && newOrder.Order_Type__c != 'Shed')
            {
                freeGoodOrderList.add(newOrder);
                accountIdSet.add(newOrder.Account__c);
                if(neworder.Budget_ID__c != null){
                    ordTerBudgMap.put(newOrder.Id, newOrder.Budget_ID__c);
                }
                System.debug(LoggingLevel.Debug,'order_Contract__c = '+ newOrder.Contract__c);
                if(newOrder.Contract__c != null){
                    contractIdSet.add(newOrder.Contract__c); 
                }
            }
        }
        
        if(accountIdSet.size()>0){
            for(Account accRec : [SELECT Id, Country__c,Independent_of_Operator__c,Operator__c FROM Account WHERE Id IN :accountIdSet]){
                outletGeoMap.put(accRec.Id, accRec.Country__c);
            }
        }
        
        //Create Contract A&P Spend Map
        if(contractIdSet.size()>0){
            for(Contract contractRec : [SELECT Id, AP_Spent__c, Available_AP_Spend__c FROM Contract WHERE Id IN :contractIdSet]){
                mapContractAP.put(contractRec.Id, contractRec);
            }
        }
        
        //Get Territory Budget
        if(!ordTerBudgMap.isEmpty()){
            for(Territory_Budget__c terrBudg : [SELECT Id, Name, Spent_Amount__c, Amount_Availlable__c, Initial_Amount__c FROM Territory_Budget__c 
                                                WHERE Id IN :ordTerBudgMap.values()])
            {
                terrBudgetMap.put(terrBudg.Id, terrBudg);
            }
        }
        
        //Get Market Setting
        if(outletGeoMap.size()>0){
            for(Market_Setting__c marketSetting :  [SELECT Id,Threshold_Free_Goods_A_P__c, Geography__c, A_P_Market__c FROM Market_Setting__c WHERE Geography__c IN :outletGeoMap.values()]){
                countryAPcostMap.Put(marketSetting.Geography__c, marketSetting);  
            }
        }
        
        //Validate & Process Free Goods Order
        if(freeGoodOrderList.size()>0){
            for(Order__c orderObj : freeGoodOrderList){
                Market_Setting__c marketSettings = countryAPcostMap.get(outletGeoMap.get(orderObj.Account__c));
                Order__c updateOrder = new Order__c(Id = orderObj.id);
                if(!marketSettings.A_P_Market__c){
                    Territory_Budget__c terrBudget = ordTerBudgMap.get(orderObj.id)!=null ? terrBudgetMap.get(ordTerBudgMap.get(orderObj.id)) : null;
                    Decimal orderCost = EDGE_UtilityClass.checkForNull(orderObj.Total_A_P_Cost__c);
                    Decimal terrBudgetAmt = terrBudget!=null ? EDGE_UtilityClass.checkForNull(terrBudget.Amount_Availlable__c) : 0;
                    
                    //Check Order Amount w/ Territory Budget Amount
                    if(orderCost <= terrBudgetAmt && terrBudget != null){
                        updateOrder.Status__c = 'Ready For Order';
                        updateOrderList.add(updateOrder);
                        //Update Territory Budget 
                        terrBudget.Spent_Amount__c = EDGE_UtilityClass.checkForNull(terrBudget.Spent_Amount__c) + orderCost;
                        updateTerrBudgetList.add(terrBudget);
                    }else{
                        updateOrder.Status__c = 'Order Held';
                        updateOrderList.add(updateOrder);
                    }
                }
                else{
                    //For User Story 4985
                    if(orderObj.Free_Goods_A_P_Cost__c != null && orderObj.Free_Goods_A_P_Cost__c >=0 ){
                        Contract conntrctRec = mapContractAP.get(orderObj.Contract__c)!=null ? mapContractAP.get(orderObj.Contract__c):null;
                        system.debug(LoggingLevel.INFO,'@@@ '+conntrctRec);
                        Decimal orderCost = EDGE_UtilityClass.checkForNull(orderObj.Free_Goods_A_P_Cost__c);
                        Decimal apAmount = conntrctRec!=null ? EDGE_UtilityClass.checkForNull(conntrctRec.Available_AP_Spend__c) : 0;
                        if(orderCost <= apAmount){
                            if(conntrctRec!=null){
                                conntrctRec.AP_Spent__c = EDGE_UtilityClass.checkForNull(conntrctRec.AP_Spent__c) + orderCost;
                                updateContractList.add(conntrctRec);
                            }
                            
                            updateOrder.Threshold_Exceeded__c = compareThresholdValue(orderObj,outletGeoMap,countryAPcostMap); 
                            updateOrderList.add(updateOrder);
                            
                        }
                        else{
                            updateOrder.Status__c = 'Order Held';
                            updateOrderList.add(updateOrder);
                        }
                    }else{
                        //For User Story 6301.
                        updateOrder.Threshold_Exceeded__c = compareThresholdValue(orderObj,outletGeoMap,countryAPcostMap); 
                        updateOrderList.add(updateOrder); 
                    }
                }
            }  
            
            if(Schema.sObjectType.Order__c.isUpdateable() && updateOrderList.size()>0){                
                update updateOrderList;
            }
           
            if(updateTerrBudgetList.size()>0 && Schema.sObjectType.Territory_Budget__c.isUpdateable()){
                update updateTerrBudgetList;
            }
            if(updateContractList.size() >0 && Schema.sObjectType.Contract.isUpdateable()){
                update updateContractList;
            }           
        }
    }
    
     /*
    Method  : compareThresholdValue
    Purpose : This is used to compare the Threshold value with the Total A&P Cost
    */
    public static boolean compareThresholdValue(Order__c orderObj,Map<Id,Id> accountCountryMap, Map<Id,Market_Setting__c> marketSetCountryMap){
        boolean flag=false;
        if(orderObj!=null){
            if(accountCountryMap.containsKey(orderObj.Account__c)){
                Id countryId = accountCountryMap.get(orderObj.Account__c);
                if(marketSetCountryMap.containsKey(countryId)){
                    Decimal thresholdAP = EDGE_UtilityClass.checkForNull(marketSetCountryMap.get(countryId).Threshold_Free_Goods_A_P__c);
                    if(orderObj.Total_A_P_Cost__c > thresholdAP){
                        flag = true;
                    }
                }
            }
        }
        return flag;
    }
    
    /*
    Method  : updateUserFields
    Purpose : This is used to assign user from CFM Queue based on Market 
    */
    public static void updateUserFields(List<Order__c> newItems){
        List<Order__c> freeGoodOrderList = new List<Order__c>();
        Set<Id> accountIdSet = new Set<Id>();
        Set<Id> salesrepIdSet = new Set<Id>();
        Map<Id, Id> salesrepManagerMap = new Map<Id, Id>();
        Map<Id, String> accQueueMap = new Map<Id, String>();
        Set<String> queueStrSet = new Set<String>();
        Map<String, List<Id>> queueUserMap = new Map<String, List<Id>>();
        
        if(newItems!=null){
            for(Order__c orderRec : newItems){
                if(orderRec.RecordTypeId == freeGoodRecordTypeId){
                    freeGoodOrderList.add(orderRec);
                    accountIdSet.add(orderRec.Account__c);
                    salesrepIdSet.add(orderRec.Sales_Representative__c);
                }
            }
        }
        
        //Get Sales Rep Manager
        if(salesrepIdSet.size()>0){
            for(User usr :[SELECT Id, ManagerId FROM User WHERE Id IN :salesrepIdSet]){
                salesrepManagerMap.put(usr.Id, usr.ManagerId);
            }
        }
        
        //Create CFM Queue Name Set
        If(accountIdSet.size()>0){
            for(Account acc : [SELECT Id, Country__c, Country__r.CFM_Queue__c FROM Account WHERE Id IN :accountIdSet]){
                accQueueMap.put(acc.Id, acc.Country__r.CFM_Queue__c);
                queueStrSet.add(acc.Country__r.CFM_Queue__c);
            }
        }
        
        //Get Queue Members
        if(queueStrSet.size()>0 && Schema.SObjectType.GroupMember.isAccessible()){
            for(GroupMember grpmem : [SELECT Group.Name, Userorgroupid from GroupMember where Group.type='Queue' and Group.Name IN: queueStrSet]){
                if(queueUserMap.containsKey(grpmem.Group.Name)){
                    List<Id> tempList = queueUserMap.get(grpmem.Group.Name);
                    tempList.add(grpmem.Userorgroupid);
                    queueUserMap.put(grpmem.Group.Name, tempList);                   
                }else{
                    queueUserMap.put(grpmem.Group.Name, new List<Id>{grpmem.Userorgroupid});
                }    
            }
        }
        
        //Update Sales Manager & CFM Queue Member in Order
        if(freeGoodOrderList != null && freeGoodOrderList.size()>0){
            for(Order__c ord : freeGoodOrderList){
                string queueName = accQueueMap.get(ord.Account__c);
                //Update Sales Rep Manager
                if(salesrepManagerMap != null && salesrepManagerMap.containsKey(ord.Sales_Representative__c)){
                    ord.Sales_Manager__c = salesrepManagerMap.get(ord.Sales_Representative__c);
                }
                //Update CFM Queue Member
                if(queueUserMap != null && queueUserMap.containsKey(queueName)){
                    List<Id> userList = queueUserMap.get(queueName);
                    if(!userList.isEmpty()){
                        if(userList.size()>=3){                     
                            ord.CFM_Approver_1__c = userList[0];
                            ord.CFM_Approver_2__c = userList[1];
                            ord.CFM_Approver_3__c = userList[2]; 
                        }else if(userList.size()==2){
                            ord.CFM_Approver_1__c = userList[0];
                            ord.CFM_Approver_2__c = userList[1];
                            ord.CFM_Approver_3__c = userList[1]; 
                        }else if(userList.size()==1){
                            ord.CFM_Approver_1__c = userList[0];
                            ord.CFM_Approver_2__c = userList[0];
                            ord.CFM_Approver_3__c = userList[0];
                        }
                    }
                }
            }
        }
    }
    
    /*
    method :revertAPBudget
    Purpose : This method will revert back the budget in the associated Contract object
    if Order status is changed from 'Approval in Progress' to 'Order Held' for free goods order.  
    */
    public static void revertAPBudget(Map<Id, sObject> newItems, Map<Id, sObject> oldItems){
        
        Map<Id, Order__c> oldOrderMap;
        List<Order__c> freeGoodOrderList = new List<Order__c>();
        Set<Id> contractIdSet = new Set<Id>();
        Map<Id, Contract> mapContractAP = new Map<Id,Contract>();
        List<Contract> updateContractList = new List<Contract>();
        
        if(oldItems != null){
            oldOrderMap = (Map<Id,Order__c>)oldItems;
        }        
        //Adding only those Free Goods Orders whose status has changed from 'Approval in Progress' to 'Order Held' 
        //in the freeGoodOrderList
        for(sObject obj : newItems.values()){
            Order__c newOrder = (Order__c)obj;
            if(oldOrderMap.get(newOrder.Id) != null){
                String oldOrdStatus = oldOrderMap.get(newOrder.Id).Status__c;
                if(newOrder.RecordTypeId == freeGoodRecordTypeId && newOrder.Status__c == EDGE_Constant.ORDER_HELD 
                   && oldOrdStatus == EDGE_Constant.ORDER_APPRV_IN_PROGRESS){                  
                       freeGoodOrderList.add(newOrder);
                       if(newOrder.Contract__c != null){
                           contractIdSet.add(newOrder.Contract__c); 
                       }
                   }
            }
        }
        
        //Create Contract A&P Spend Map
        if(contractIdSet.size()>0){
            for(Contract contractRec : [SELECT Id,AP_Spent__c, Available_AP_Spend__c FROM Contract WHERE Id IN :contractIdSet]){
                mapContractAP.put(contractRec.Id, contractRec);
            }
        }
        
        //Process Free Goods Order & revert back contract budget
        if(freeGoodOrderList.size()>0){            
            for(Order__c orderObj : freeGoodOrderList){
                Decimal orderCost = EDGE_UtilityClass.checkForNull(orderObj.Free_Goods_A_P_Cost__c);
                
                if(orderCost != null && orderCost >=0 ){                   
                    Contract conntrctRec = mapContractAP.get(orderObj.Contract__c)!=null ? mapContractAP.get(orderObj.Contract__c):null;
                    if(conntrctRec != null){
                    	conntrctRec.AP_Spent__c = EDGE_UtilityClass.checkForNull(conntrctRec.AP_Spent__c) - orderCost;
                        updateContractList.add(conntrctRec);
                    }
                }
            }
        }
        
        if(updateContractList.size() > 0 && Schema.sObjectType.Contract.isUpdateable()){
            Database.update(updateContractList);
        }
    }
    
    /*
     * Method	:	checkSAPCallout
     * Purpose	:	This method is used to check and send the orders to SAP
     * Author	:	Saurav Prasad
     * Story	:	147473 - Salesforce Attribute mapping with corresponding Mulesoft Attribute in JSON file for sending Free Goods Order to SAP
     */
    
    public static void checkSAPCallout(Map<Id, SObject> newMap,Map<Id, SObject> oldMap){
        Map<Id,Order__c> newOrderMap = (Map<Id,Order__c>) newMap;
        Map<Id,Order__c> oldOrderMap = (Map<Id,Order__c>) oldMap;
        Set<Id> orderIds = new Set<Id>();
        Set<String> countryCodes = new Set<String>();
        Set<Id> directToSAPOrderIds = new Set<Id>();
        Map<Id,Order__c> ordersToSAP = new Map<Id,Order__c>();
        String orderStatus = System.Label.EDGE_FreeGoodsStatus_ForSAP;
        Map<String, String> countryWithSAPMap = new Map<String, String>();
        
        for(Order__c ordRec : newOrderMap.values()){
            if(freeGoodRecordTypeId == ordRec.RecordTypeId && ordRec.Delivery_Partner__c!=NULL
               && ordRec.Status__c != oldOrderMap.get(ordRec.Id).Status__c && ordRec.Status__c == orderStatus){
                   orderIds.add(ordRec.Id);
                   countryCodes.add(ordRec.Country_Code__c);
               }
        }

        countryWithSAPMap = getCountryWithSAPMap(countryCodes);

        
        if(!orderIds.isEmpty()){
            ordersToSAP = new Map<Id,Order__c>([SELECT Id, Country_Code__c FROM Order__c WHERE Id IN: orderIds AND Delivery_Partner__r.Allow_Free_Goods_Order_to_SAP__c = true WITH SECURITY_ENFORCED]);
        }    
        
        for(Id orderId : ordersToSAP.keySet()){
            if (countryWithSAPMap.get(ordersToSAP.get(orderId).Country_Code__c) == 'Direct to SAP') {
                directToSAPOrderIds.add(orderId);
            }
        }

        if (directToSAPOrderIds != null && !directToSAPOrderIds.isEmpty()) {
            EDGE_FreeGoodsOrderToSAPCallout.getOrder(directToSAPOrderIds);
        }
    }
    
    /*Get Country Code with Market Setting SAP Automation MAP/ */
    public static Map<String, String> getCountryWithSAPMap(Set<String> countryCodes){
        Map<String, String> countryWithSAPMap = new Map<String, String>();
        if (Schema.sObjectType.Market_Setting__c.isAccessible()){
            for(Market_Setting__c marketSetting : [SELECT Id, Geography__r.Code__c, Free_Goods_SAP_Automation__c 
                                                    FROM Market_Setting__c
                                                    WHERE Geography__r.Code__c IN :countryCodes]){
                countryWithSAPMap.put(marketSetting.Geography__r.Code__c, marketSetting.Free_Goods_SAP_Automation__c);
            }
        }
        return countryWithSAPMap;
    }
}