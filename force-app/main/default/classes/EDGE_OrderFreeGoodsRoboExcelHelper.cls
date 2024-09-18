/*
* Class Name: EDGE_OrderFreeGoodsRoboExcelHelper
* Test Class: EDGE_FreeGoodsOrderBatchTest
* Author: 
* Brief Description: 
* Created Date: 20/05/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
*1.0			Saurav Prasad			07/07/2024			Initial Development: 152719 - SFDC Data mapping in Free Goods CSV for Robot Upload.
*2.0			Suvendu Roy				11/07/2024			Made Changes for PMD Issues.
*2.1			Saurav Prasad			24/07/2024			155471 - Fastrack_Add Vat Code in Robot CSV Template for Free Good Orders placed in EDGE
*/ 

public with sharing class EDGE_OrderFreeGoodsRoboExcelHelper {
    /**
* @ADO Number : 152719
* @Name : getOrderItems
* @description : This method used for quering & mapping of global veriables.
*/
    public static EDGE_SObjectMapWrapperMain getOrderItems(set<Id>orderIds){
        Map<Id,Order__c> orderMap = new Map<Id,Order__c>();
        Map<Id,List<Order_Item__c>> orderLineItemsMap = new Map<Id,List<Order_Item__c>>();
        Map<Id,Account> accountMap = new Map<Id,Account>();
        Map<Id,User> userMap = new Map<Id,User>();
        Map<Id,Product__c> productMap = new Map<Id,Product__c>();
        Map<Id,ECM_Internal_Order__c> internalOrderMap = new Map<Id,ECM_Internal_Order__c>();
        set<Id> countryIds = new set<Id>();
        Map<Id,Id> countryMap = new Map<Id,Id>();
        
        List<Order_Item__c> orderItemList = [SELECT Id, Name, Order__c, Order__r.Account__c, Order__r.Account__r.Sales_Org__c, Order__r.Account__r.Name,
                                             Order__r.Account__r.BillingStreet, Order__r.Account__r.BillingCity, Order__r.Account__r.BillingPostalCode,
                                             Order__r.Account__r.Country_Code__c, Order__r.Account__r.Country__c, Order__r.Delivery_Shed_Account__c, 
                                             Order__r.Delivery_Shed_Account__r.Name, Order__r.Delivery_Shed_Account__r.BillingStreet, 
                                             Order__r.Delivery_Shed_Account__r.BillingCity, Order__r.Delivery_Shed_Account__r.BillingPostalCode,
                                             Order__r.Sales_Representative__c,Order__r.Sales_Representative__r.Name, Order__r.Preferred_Delivery_Date__c,
                                             Order__r.Delivery_Partner__c, Order__r.Delivery_Partner__r.SAP_Sold_To__c,Order__r.Delivery_Partner__r.SAP_Ship_To__c,
                                             Order__r.Delivery_instructions__c,Order__r.Total_A_P_Cost__c, Order__r.Delivery_Location__c,
                                             Product__c, Product__r.Product_Full_Name__c,Product__r.SAP_SKU_Code__c,Quantity__c,Selected_UoM__c,
                                             Reason_Code__c,Reason_Code__r.Internal_Order__c,Reason_Code__r.Internal_Order__r.Name
                                             FROM Order_Item__c 
                                             WHERE Order__c IN: orderIds
                                             WITH SECURITY_ENFORCED
                                             ORDER BY Order__c
                                            ];
        EDGE_SObjectMapWrapperMain mainWrapper = getWrapper(orderItemList);
        for(Order_Item__c orderItem: orderItemList){
            //user data
            if(orderItem.Order__r.Sales_Representative__c!=null && !userMap.containsKey(orderItem.Order__r.Sales_Representative__c)){
                userMap.put(orderItem.Order__r.Sales_Representative__c,orderItem.Order__r.Sales_Representative__r);
            }
            //internal Order 
            if(orderItem.Reason_Code__c != null && orderItem.Reason_Code__r.Internal_Order__c!=null){
                internalOrderMap.put(orderItem.Reason_Code__r.Internal_Order__c,orderItem.Reason_Code__r.Internal_Order__r);
            }
            //add product
            productMap.put(orderItem.Product__c,orderItem.Product__r);
            //add country ids
            countryIds.add(orderItem.Order__r.Account__r.Country__c);
            
            //Country Map - storynumber : 155471 
            if(!countryMap.containsKey(orderItem.Order__c)){
                countryMap.put(orderItem.Order__c,orderItem.Order__r.Account__r.Country__c);
            }
            
            //Order Map
            orderMap.put(orderItem.Order__c,orderItem.Order__r);
            //Order Items Map
            if(orderLineItemsMap.containsKey(orderItem.Order__c)){
                orderLineItemsMap.get(orderItem.Order__c).add(orderItem);
            }else{
                orderLineItemsMap.put(orderItem.Order__c,new List<Order_Item__c>{orderItem});
            }
            
            //Account Map
            accountMap.put(orderItem.Order__r.Account__c,orderItem.Order__r.Account__r);
        }
        mainWrapper.userMap = userMap;
        mainWrapper.internalOrderMap = internalOrderMap;
        mainWrapper.productMap = productMap;
        mainWrapper.countryIds = countryIds;
        mainWrapper.countryMap = countryMap;
        mainWrapper.orderMap = orderMap;
        mainWrapper.orderLineItemsMap = orderLineItemsMap;
        mainWrapper.accountMap = accountMap;
        return mainWrapper;
    }
    /**
* @ADO Number : 152719
* @Name : getWrapper
* @description : This method returns EDGE_SObjectMapWrapperMain deliveryShedAccMap & deliveryPartnerMap.
*/
    public static EDGE_SObjectMapWrapperMain getWrapper(List<Order_Item__c> orderItemList){
        EDGE_SObjectMapWrapperMain mainWrapper = new EDGE_SObjectMapWrapperMain();
        Map<Id,Account> deliveryShedAccMap = new Map<Id,Account>();
        Map<Id,Delivery_Partner__c> deliveryPartnerMap = new Map<Id,Delivery_Partner__c>();
        for(Order_Item__c orderItem: orderItemList){
            //delivery shed Account Map
            if(orderItem.Order__r.Delivery_Shed_Account__c!=null && !deliveryShedAccMap.containsKey(orderItem.Order__r.Delivery_Shed_Account__c)){
                deliveryShedAccMap.put(orderItem.Order__r.Delivery_Shed_Account__c,orderItem.Order__r.Delivery_Shed_Account__r);
            }
            
            //delivery partner
            if(orderItem.Order__r.Delivery_Partner__c!=null && !deliveryPartnerMap.containsKey(orderItem.Order__r.Delivery_Partner__c) ){
                deliveryPartnerMap.put(orderItem.Order__r.Delivery_Partner__c,orderItem.Order__r.Delivery_Partner__r);
            }
        }
        mainWrapper.deliveryShedAccMap = deliveryShedAccMap;
        mainWrapper.deliveryPartnerMap = deliveryPartnerMap;
        return mainWrapper;
    }
    /**
* @ADO Number : 152719
* @Name : switchCalculationWhenOrderProduct
* @description : This method get values for Order Product fields values.
*/
    public static String switchCalculationWhenOrderProduct(Free_Goods_Order_Robo_CSV__mdt mdt, EDGE_OrderFreeGoodsRoboExcelController.EDGE_SObjectMapWrapper sobjWrapper,Integer i){
        String dynamicValue = '';
        switch on mdt.Object__c {
            when 'Order_Item__c' {
                dynamicValue = nullCheck(sobjWrapper.orderItem,mdt.Value__c) ? parseToString(sobjWrapper.orderItem,mdt.Value__c):'';
            }
            when 'ECM_Internal_Order__c' {
                dynamicValue = nullCheck(sobjWrapper.internalOrder,mdt.Value__c) ? parseToString(sobjWrapper.internalOrder,mdt.Value__c):'';
            }
            when 'Product__c' {
                dynamicValue = nullCheck(sobjWrapper.productItem,mdt.Value__c) ? parseToString(sobjWrapper.productItem,mdt.Value__c):'';
            }
            when else {
                Integer count = Integer.valueOf(mdt.Value__c) + i;
                dynamicValue = String.valueOf(count);
            }
        }
        return dynamicValue;
    }
    
    /**
* @ADO Number : 152719
* @Name : getMarketSetting
* @description : This method returns Map of Market Settings, Country Id as key.
*/
    public static Map<Id,Market_Setting__c> getMarketSetting(set<Id> countryIds){
        Map<Id,Market_Setting__c> marketMap = new Map<Id,Market_Setting__c>();
        //155471 - added Vat_Code__c in query
        for(Market_Setting__c marketSet : 
            [SELECT Id,Name,Free_Goods_Robot_Email_Address__c,Geography__c,
             Vat_Code__c
             FROM Market_Setting__c
             WHERE Geography__c IN: countryIds
             WITH SECURITY_ENFORCED]){
                 marketMap.put(marketSet.Geography__c,marketSet);
             }
        
        return marketMap;
    }
    
    /**
* @ADO Number : 152719
* @Name : getCustomLabel
* @description : This method returns customlabel values
*/
    public static String getCustomLabel(String value){
        String str = '';
        try{
            str = System.label.get('',value);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Exception :'+ex);
        }
        return str;
    }
    
    /**
* @ADO Number : 152719
* @Name : nullCheck
* @description : This method used for null check
*/
    public static Boolean nullCheck(SObject obj, String value){        
        return (obj!=null && obj.get(value)!=null);
        
    }
    /**
* @ADO Number : 152719
* @Name : parseToString
* @description : This method returns string value of sObject.
*/
    public static String parseToString(SObject value, String key){
        return String.valueOf(value.get(key));
        
    }
    /**
* @ADO Number : 152719
* @Name : parseToDate
* @description : This method returns formated date value eg: 20.07.2024
*/
    public static String parseToDate(SObject value, String key){
        Date d = Date.valueOf(parseToString(value,key));
        DateTime dt = DateTime.newInstance(d.year(),d.month(),d.day());
        return dt.format('dd.MM.yyyy');
    }
    /**
* @ADO Number : 152719
* @Name : nullCheck
* @description : This method used for null check
*/
    public static String nullCheck(String str){
        return String.isBlank(str)?'':str;
    }
    /**
* @ADO Number : 152719
* @Name : dateFormatter
* @description : This method returns formated date value eg: 20.07.2024
*/
    public static String dateFormatter(Date dt){
        DateTime dtTime = DateTime.newInstance(dt.year(), dt.month(),dt.day());
        return dtTime.format('dd.MM.yyyy');
    }
    
    /**
     * @ADO Number	:	152719
     * @Name		:	truncateValue
     * @description	:	this method will truncate value for name(40) & BillingStreet(60)
     * */
    public static String truncateValue(SObject obj, String value){
        
        String str = '';
        List<String> truncateFields = System.Label.EDGE_RoboExcel_TruncateFields.split(';');
        List<String> nameField = truncateFields[0].split(':');
        List<String> billingField = truncateFields[1].split(':');
        
        if(nameField.contains(value) || billingField.contains(value)){
            
            str = nameField.contains(value) ? parseToString(obj,value).left(Integer.valueOf(nameField[1])):
            billingField.contains(value) ? parseToString(obj,value).left(Integer.valueOf(billingField[1])): '';
            
        }else{
            str = parseToString(obj,value);
        }
        return str;
    }
    
    public class EDGE_SObjectMapWrapperMain{
        /**
* @description Order Map
* @return Map<Id,Order__c>
*/
        public Map<Id,Order__c> orderMap{get;set;}
        /**
* @description Map of Order Products list with Order id
* @return Map<Id,List<Order_Item__c>> 
*/
        public Map<Id,List<Order_Item__c>> orderLineItemsMap{get;set;}
        /**
* @description Account Map
* @return Map<Id,Account> 
*/
        public Map<Id,Account> accountMap{get;set;}
        /**
* @description Delivery Shed Account Map
* @return Map<Id,Account>
*/
        public Map<Id,Account> deliveryShedAccMap{get;set;}
        /**
* @description Delivery Partner Map
* @return Map<Id,Delivery_Partner__c>
*/
        public Map<Id,Delivery_Partner__c> deliveryPartnerMap{get;set;}
        /**
* @description SR map
* @return Map<Id,User> 
*/
        public Map<Id,User> userMap{get;set;}
        /**
* @description Products map
* @return Map<Id,Product__c>
*/
        public Map<Id,Product__c> productMap{get;set;}
        /**
* @description Internal Order Map
* @return Map<Id,ECM_Internal_Order__c>
*/
        public Map<Id,ECM_Internal_Order__c> internalOrderMap{get;set;}
        /**
* @description Country Ids
* @return set<Id>
*/
        public set<Id> countryIds{get;set;}
        
        /*
* 155471
* @description countryMap 
* @reture Map<Id,Id>
*/
        public Map<Id,Id> countryMap{get;set;}

    }
}