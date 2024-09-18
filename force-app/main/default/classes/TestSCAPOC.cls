/*
* @Name: EDGE_OrderFreeGoodsRoboExcelController
* @description: This class is used to fetch data necessary for csv file - robo excel
* @History                                                            

VERSION			AUTHOR					DATE					DETAIL
1.0			Saurav Prasad			07/07/2024				Initial Development: 152719 - SFDC Data mapping in Free Goods CSV for Robot Upload

*/
public without sharing class TestSCAPOC {
    
    public static List<Free_Goods_Order_Robo_CSV__mdt> roboMetadata = new List<Free_Goods_Order_Robo_CSV__mdt>();    
    public static Map<Id,Market_Setting__c> marketSettingMap = new Map<Id,Market_Setting__c>();
    public static Map<Id,Order__c> orderMap = new Map<Id,Order__c>();
    public static Map<Id,List<Order_Item__c>> orderLineItemsMap = new Map<Id,List<Order_Item__c>>();
    public static Map<Id,Account> accountMap = new Map<Id,Account>();
    public static Map<Id,Account> deliveryShedAccMap = new Map<Id,Account>();
    public static Map<Id,Delivery_Partner__c> deliveryPartnerMap = new Map<Id,Delivery_Partner__c>();
    public static Map<Id,User> userMap = new Map<Id,User>();
    public static Map<Id,Product__c> productMap = new Map<Id,Product__c>();
    public static Map<Id,ECM_Internal_Order__c> internalOrderMap = new Map<Id,ECM_Internal_Order__c>();
    
    public static Map<Id,String> processOrders(set<Id> orderIds){
        
        Map<Id,List<EDGE_CSVFileGenerator.CellData>> mapcellData = new Map<Id,List<EDGE_CSVFileGenerator.CellData>>();
        Map<Id,String> returnMap = new Map<Id,String>();
        
        set<Id> countryIds = new set<Id>();
        roboMetadata = getAllMetaData(roboMetadata);
        System.debug(LoggingLevel.Debug,'roboMetadata @'+roboMetadata);
        getOrderItems(orderIds, countryIds);
        marketSettingMap = getMarketSetting(countryIds);
        System.debug(LoggingLevel.Debug,'countryIds @'+countryIds);
        
        if(!orderMap.values().isEmpty()){
            mapcellData = processCSVData();
        }
        
        for(Id orderId : mapcellData.keySet()){
            List<EDGE_CSVFileGenerator.CellData> cellDataList = new List<EDGE_CSVFileGenerator.CellData>();
            cellDataList = mapcellData.get(orderId);
            String str = EDGE_CSVFileGenerator.generateCSV(cellDataList);
            returnMap.put(orderId,str);
        }
        
        return returnMap;
        
    }
    
    private static Map<Id,List<EDGE_CSVFileGenerator.CellData>> processCSVData(){
        Map<Id,List<EDGE_CSVFileGenerator.CellData>> mapcellData = new Map<Id,List<EDGE_CSVFileGenerator.CellData>>();
        
        for(Order__c order : orderMap.values()){
            List<EDGE_CSVFileGenerator.CellData> cellDataList = new List<EDGE_CSVFileGenerator.CellData>();
            cellDataList = processCsvMetadata(order);
            mapcellData.put(order.Id,cellDataList);
        }
        
        return mapcellData;
        
        
    }
    
    private static List<EDGE_CSVFileGenerator.CellData>  processCsvMetadata(Order__c order){
        List<EDGE_CSVFileGenerator.CellData> cellDataList = new List<EDGE_CSVFileGenerator.CellData>();
        
        System.debug(LoggingLevel.Debug,'orderMap @'+orderMap);
        System.debug(LoggingLevel.Debug,'orderLineItemsMap @'+orderLineItemsMap);
        System.debug(LoggingLevel.Debug,'accountMap @'+accountMap);
        System.debug(LoggingLevel.Debug,'deliveryShedAccMap @'+deliveryShedAccMap);
        System.debug(LoggingLevel.Debug,'deliveryPartnerMap @'+deliveryPartnerMap);
        
        for(Free_Goods_Order_Robo_CSV__mdt mdt: roboMetadata){
            System.debug(LoggingLevel.Debug,'mdt @'+mdt);
            switch on mdt.Type__c {
                when 'Static' {		
                    cellDataList.add(new EDGE_CSVFileGenerator.CellData(Integer.valueOf(mdt.Row_Number__c), Integer.valueOf(mdt.Column_Number__c), getCustomLabel(mdt.Value__c)));
                }	
                when 'Dynamic' {
                    String dynamicValue = '';
                    switch on mdt.Object__c {
                        
                        when 'Order__c' {
                            SObject orderObject = orderMap.containsKey(order.Id) ? orderMap.get(order.Id): null;
                            
                            switch on mdt.DeveloperName {
                                when 'PO_Reference_Value' {
                                    list<String> splitString = mdt.Value__c.split(';');
                                    SObject salesUser = userMap.containsKey(order.Sales_Representative__c) ? userMap.get(order.Sales_Representative__c):null;
                                    String salesRep = nullCheck(salesUser, splitString[0])? parseToString(salesUser,splitString[0]):'';
                                    String deliveryDate = nullCheck(orderObject, splitString[2])? parseToDate(orderObject,splitString[2]):'';
                                    dynamicValue = salesRep+splitString[1]+deliveryDate;
                                    
                                }
                                when 'Required_Delivery_date_Value'{
                                    dynamicValue = nullCheck(orderObject, mdt.Value__c) ? parseToDate(orderObject,mdt.Value__c):'';
                                }
                                when else {
                                    dynamicValue = nullCheck(orderObject, mdt.Value__c) ? parseToString(orderObject,mdt.Value__c):'';
                                }
                            }
                        }
                        when 'Account' {
                            SObject accountObject = accountMap.containsKey(order.Account__c) ? accountMap.get(order.Account__c):null;
                            SObject shedAccount = deliveryShedAccMap.containsKey(order.Delivery_Shed_Account__c) ? deliveryShedAccMap.get(order.Delivery_Shed_Account__c): null;
                            switch on mdt.Value__c { 
                                when 'Name', 'BillingStreet', 'BillingCity', 'BillingPostalCode' {
                                    
                                    switch on order.Delivery_Location__c {
                                        when 'Outlet' {
                                            dynamicValue = nullCheck(accountObject, mdt.Value__c) ? parseToString(accountObject,mdt.Value__c):'';
                                        }
                                        when 'Shed' {
                                            dynamicValue = nullCheck(shedAccount, mdt.Value__c) ? parseToString(shedAccount,mdt.Value__c):'';
                                        }
                                        when else{
                                            System.debug(LoggingLevel.WARN ,'Location out of scope');
                                        }
                                    }
                                }
                                when else {
                                    dynamicValue = nullCheck(accountObject, mdt.Value__c) ? parseToString(accountObject,mdt.Value__c):'';
                                }
                            }
                            
                        }
                        when 'Delivery_Partner__c' {
                            SObject deliveryPartner = deliveryPartnerMap.containsKey(order.Delivery_Partner__c) ? deliveryPartnerMap.get(order.Delivery_Partner__c):null;
                            dynamicValue = nullCheck(deliveryPartner, mdt.Value__c) ? parseToString(deliveryPartner,mdt.Value__c):'';
                            
                        }
                        when else {
                            System.debug(LoggingLevel.WARN ,'Object out of scope');
                        }
                    }
                    cellDataList.add(new EDGE_CSVFileGenerator.CellData(Integer.valueOf(mdt.Row_Number__c), Integer.valueOf(mdt.Column_Number__c),dynamicValue));
                }
                when 'Table Row'{
                    
                    cellDataList.addAll(processTableRow(mdt,order.Id));
                    
                }
                when else {
                    cellDataList.add(new EDGE_CSVFileGenerator.CellData(Integer.valueOf(mdt.Row_Number__c), Integer.valueOf(mdt.Column_Number__c),mdt.Value__c));
                    System.debug(LoggingLevel.WARN ,'Type out of scope');
                }
            }
        }
        return cellDataList;
        
    }
    
        private static List<EDGE_CSVFileGenerator.CellData> processTableRow(Free_Goods_Order_Robo_CSV__mdt mdt,Id orderId){
        List<EDGE_CSVFileGenerator.CellData> tableRows = new List<EDGE_CSVFileGenerator.CellData>();
        Integer orderItemSize = orderLineItemsMap.containsKey(orderId)? orderLineItemsMap.get(orderId).size():0;
        
        for(Integer i=0; i<20; i++){
           String dynamicValue = getTest(i,orderId,mdt);
            System.debug('dynamicValue @'+dynamicValue);
            tableRows.add(new EDGE_CSVFileGenerator.CellData((Integer.valueOf(mdt.Row_Number__c) + i), Integer.valueOf(mdt.Column_Number__c),dynamicValue));
        }
            system.debug('table rowss'+ tableRows);
        return tableRows;
    }
    private static String getTest(integer i,Id OrderId,Free_Goods_Order_Robo_CSV__mdt mdt){ 
        Integer orderItemSize = orderLineItemsMap.containsKey(OrderId)? orderLineItemsMap.get(OrderId).size():0;
        sObject orderItem = i<orderItemSize ? orderLineItemsMap.get(OrderId)[i]: null;       
            sObject productItem = i<orderItemSize && productMap.containsKey(orderLineItemsMap.get(OrderId)[i].Product__c)? 
                productMap.get(orderLineItemsMap.get(OrderId)[i].Product__c): null;
            
            sObject internalOrder = i<orderItemSize && internalOrderMap.containsKey(orderLineItemsMap.get(OrderId)[i].Reason_Code__r.Internal_Order__c) ? 
                internalOrderMap.get(orderLineItemsMap.get(OrderId)[i].Reason_Code__r.Internal_Order__c):null;
            
            String dynamicValue = '';
       
               switch on mdt.Object__c {
                when 'Order_Item__c' {
                    dynamicValue = nullCheck(orderItem,mdt.Value__c) ? parseToString(orderItem,mdt.Value__c):'';
                }
                when 'ECM_Internal_Order__c' {
                    dynamicValue = nullCheck(internalOrder,mdt.Value__c) ? parseToString(internalOrder,mdt.Value__c):'';
                }
                when 'Product__c' {
                    dynamicValue = nullCheck(productItem,mdt.Value__c) ? parseToString(productItem,mdt.Value__c):'';
                }
                when else {
                    Integer count = Integer.valueOf(mdt.Value__c) + i;
                    dynamicValue = String.valueOf(count);
                }
            }
        return dynamicValue;
    }
    
    private static void getOrderItems(set<Id>orderIds, set<Id>countryIds){
        
        for(Order_Item__c orderItem:
            [SELECT Id, Name, Order__c, Order__r.Account__c, Order__r.Account__r.Sales_Org__c, Order__r.Account__r.Name,
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
            ]){
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
                
                //delivery shed Account Map
                if(orderItem.Order__r.Delivery_Shed_Account__c!=null && !deliveryShedAccMap.containsKey(orderItem.Order__r.Delivery_Shed_Account__c)){
                    deliveryShedAccMap.put(orderItem.Order__r.Delivery_Shed_Account__c,orderItem.Order__r.Delivery_Shed_Account__r);
                }
                
                //delivery partner
                if(orderItem.Order__r.Delivery_Partner__c!=null && !deliveryPartnerMap.containsKey(orderItem.Order__r.Delivery_Partner__c) ){
                    deliveryPartnerMap.put(orderItem.Order__r.Delivery_Partner__c,orderItem.Order__r.Delivery_Partner__r);
                }
            }
        
        
    }
    
    private static Map<Id,Market_Setting__c> getMarketSetting(set<Id> countryIds){
        Map<Id,Market_Setting__c> marketMap = new Map<Id,Market_Setting__c>();
        
        for(Market_Setting__c marketSet : 
            [SELECT Id,Name,Free_Goods_Robot_Email_Address__c,Geography__c
             FROM Market_Setting__c
             WHERE Geography__c IN: countryIds
             WITH SECURITY_ENFORCED]){
                 marketMap.put(marketSet.Geography__c,marketSet);
             }
        
        return marketMap;
    }
    
    private static List<Free_Goods_Order_Robo_CSV__mdt> getAllMetaData(List<Free_Goods_Order_Robo_CSV__mdt> sortedMetadata){
        //Declaration of variables
        String sequenceField = System.Label.EDGE_RoboExcelSort_FieldName;
        List<Free_Goods_Order_Robo_CSV__mdt> allMetadata = new List<Free_Goods_Order_Robo_CSV__mdt>();
        
        //Loop to get metadata records
        for(Free_Goods_Order_Robo_CSV__mdt mdt: Free_Goods_Order_Robo_CSV__mdt.getAll().values()){
            allMetadata.add(mdt);
        }
        
        //Sort Records
        ECM_SortUtil.SortOrderWrap wrapper = new ECM_SortUtil.SortOrderWrap();
        wrapper.records = allMetadata;
        wrapper.fieldName = sequenceField;
        ECM_SortUtil.sortRecords(wrapper, ECM_SortUtil.SortOrder.ASCENDING, ECM_SortUtil.Type.TYPE_INTEGER);
        
        //Add to sorted List
        sortedMetadata = wrapper.records;
        return sortedMetadata;
    }
    
    private static Boolean nullCheck(SObject obj, String value){        
        return (obj!=null && obj.get(value)!=null);
        
    }
    
    private static String parseToString(SObject value, String key){
        return String.valueOf(value.get(key));
        
    }
    
    private static String parseToDate(SObject value, String key){
        Date d = Date.valueOf(parseToString(value,key));
        DateTime dt = DateTime.newInstance(d.year(),d.month(),d.day());
        return dt.format('dd.MM.YYYY');
    }
    
    private static String nullCheck(String str){
        return String.isBlank(str)?'':str;
    }
    
    private static String dateFormatter(Date dt){
        DateTime dtTime = DateTime.newInstance(dt.year(), dt.month(),dt.day());
        return dtTime.format('DD.MM.YYYY');
    }
    
    private static String getCustomLabel(String value){
        String str = '';
        try{
            str = System.label.get('',value);
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, 'Exception :'+ex);
        }
        return str;
    }
    
}