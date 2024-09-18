/*
* @Name: EDGE_OrderFreeGoodsRoboExcelController
* @description: This class is used to fetch data necessary for csv file - robo excel
* @History                                                            

VERSION			AUTHOR					DATE					DETAIL
1.0			Saurav Prasad			07/07/2024				Initial Development: 152719 - SFDC Data mapping in Free Goods CSV for Robot Upload
1.1			Saurav Prasad			24/07/2024				155471 - Fastrack_Add Vat Code in Robot CSV Template for Free Good Orders placed in EDGE

*/
public with sharing class EDGE_OrderFreeGoodsRoboExcelController {
    
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
    public static Map<Id,Id> countryMap = new Map<Id,Id>();
    /**
     * @ADO Number : 152719
     * @Name : processOrders
	 * @description : This start method to return Map of OrderId as key and CSV_Data as Sting Values.
	 */
    public static Map<Id,String> processOrders(set<Id> orderIds){
        
        Map<Id,List<EDGE_CSVFileGenerator.CellData>> mapcellData = new Map<Id,List<EDGE_CSVFileGenerator.CellData>>();
        Map<Id,String> returnMap = new Map<Id,String>();
        
        set<Id> countryIds = new set<Id>();
        roboMetadata = getAllMetaData(roboMetadata);
        System.debug(LoggingLevel.Debug,'roboMetadata @'+roboMetadata);
        EDGE_OrderFreeGoodsRoboExcelHelper.EDGE_SObjectMapWrapperMain mainWrapper = EDGE_OrderFreeGoodsRoboExcelHelper.getOrderItems(orderIds);
        userMap = mainWrapper.userMap;
        internalOrderMap = mainWrapper.internalOrderMap;
        productMap = mainWrapper.productMap;
        countryIds = mainWrapper.countryIds;
        orderMap = mainWrapper.orderMap;
        orderLineItemsMap = mainWrapper.orderLineItemsMap;
        accountMap = mainWrapper.accountMap;
        deliveryShedAccMap = mainWrapper.deliveryShedAccMap;
        deliveryPartnerMap = mainWrapper.deliveryPartnerMap;
        //155471
        countryMap = mainWrapper.countryMap;
        
        marketSettingMap = EDGE_OrderFreeGoodsRoboExcelHelper.getMarketSetting(countryIds);
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
    /**
     * @ADO Number : 152719
     * @Name : processCSVData
	 * @description : This method to return Map of OrderId as key and CSV_CellData values as List.
	 */
    private static Map<Id,List<EDGE_CSVFileGenerator.CellData>> processCSVData(){
        Map<Id,List<EDGE_CSVFileGenerator.CellData>> mapcellData = new Map<Id,List<EDGE_CSVFileGenerator.CellData>>();
        
        for(Order__c order : orderMap.values()){
            List<EDGE_CSVFileGenerator.CellData> cellDataList = new List<EDGE_CSVFileGenerator.CellData>();
            cellDataList = processCsvMetadata(order);
            mapcellData.put(order.Id,cellDataList);
        }
        
        return mapcellData;
        
        
    }
    /**
     * @ADO Number : 152719
     * @Name : processCsvMetadata
	 * @description : This method to return List of CSV_CellData for Account, Order & Static cells.
	 */
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
                    cellDataList.add(new EDGE_CSVFileGenerator.CellData(Integer.valueOf(mdt.Row_Number__c), Integer.valueOf(mdt.Column_Number__c), EDGE_OrderFreeGoodsRoboExcelHelper.getCustomLabel(mdt.Value__c)));
                }	
                when 'Dynamic' {
                    String dynamicValue = switchCalculationWhenDynamic(mdt,order);
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
    /**
     * @ADO Number : 152719
     * @Name : switchCalculationWhenDynamic
	 * @description : This method use to map CSVCellData for Dynamic Values.
	 */
    private static String switchCalculationWhenDynamic(Free_Goods_Order_Robo_CSV__mdt mdt, Order__c order){
        String dynamicValue = '';
        switch on mdt.Object__c {
                        
            when 'Order__c' {
                dynamicValue = switchCalculationWhenOrder(mdt,order);
            }
            when 'Account' {
                dynamicValue = switchCalculationWhenAccount(mdt,order);
            }
            when 'Delivery_Partner__c' {
                dynamicValue = switchCalculationWhenDeliveyPartner(mdt,order);
            }
            when 'Market_Setting__c' {
                dynamicValue = switchCalculationWhenMarketSetting(mdt,order);
            }
            when else {
                System.debug(LoggingLevel.WARN ,'Object out of scope');
            }
        }
        //System.debug(LoggingLevel.Debug,'dynamicValue-1-'+dynamicValue);
        return dynamicValue;
    }
    /**
     * @ADO Number : 152719
     * @Name : switchCalculationWhenOrder
	 * @description : This method get values for Order fields values.
	 */
    private static String switchCalculationWhenOrder(Free_Goods_Order_Robo_CSV__mdt mdt, Order__c order){
        String dynamicValue = '';
        SObject orderObject = orderMap.containsKey(order.Id) ? orderMap.get(order.Id): null;
        switch on mdt.DeveloperName {
            when 'PO_Reference_Value' {
                list<String> splitString = mdt.Value__c.split(';');
                SObject salesUser = userMap.containsKey(order.Sales_Representative__c) ? userMap.get(order.Sales_Representative__c):null;
                String salesRep = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(salesUser, splitString[0])? EDGE_OrderFreeGoodsRoboExcelHelper.parseToString(salesUser,splitString[0]):'';
                String deliveryDate = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(orderObject, splitString[2])?EDGE_OrderFreeGoodsRoboExcelHelper.parseToDate(orderObject,splitString[2]):'';
                dynamicValue = salesRep+splitString[1]+deliveryDate;
                
            }
            when 'Required_Delivery_date_Value'{
                dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(orderObject, mdt.Value__c) ? EDGE_OrderFreeGoodsRoboExcelHelper.parseToDate(orderObject,mdt.Value__c):'';
            }
            when else {
                dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(orderObject, mdt.Value__c) ? EDGE_OrderFreeGoodsRoboExcelHelper.parseToString(orderObject,mdt.Value__c):'';
            }
        }
        //System.debug(LoggingLevel.Debug,'dynamicValue-21-'+dynamicValue);
        return dynamicValue;
    }

    /**
     * @ADO Number : 155471
     * @Name : switchCalculationWhenDeliveyPartner
	 * @description : This method get values for delievery partner fields values.
	 */
    private static String switchCalculationWhenDeliveyPartner(Free_Goods_Order_Robo_CSV__mdt mdt, Order__c order){
        String dynamicValue = '';
        SObject deliveryPartner = deliveryPartnerMap.containsKey(order.Delivery_Partner__c) ? deliveryPartnerMap.get(order.Delivery_Partner__c):null;
        dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(deliveryPartner, mdt.Value__c) ? EDGE_OrderFreeGoodsRoboExcelHelper.parseToString(deliveryPartner,mdt.Value__c):'';
        return dynamicValue;
    }
    
    /**
     * @ADO Number : 155471
     * @Name : switchCalculationWhenMarketSetting
	 * @description : This method get values for Market Setting fields values.
	 */
    private static String switchCalculationWhenMarketSetting(Free_Goods_Order_Robo_CSV__mdt mdt, Order__c order){
        String dynamicValue = '';
        SObject marSetObject = countryMap.containsKey(order.Id) ? marketSettingMap.containsKey(countryMap.get(order.Id)) ? marketSettingMap.get(countryMap.get(order.Id)):null:null;
        dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(marSetObject,mdt.value__c)?EDGE_OrderFreeGoodsRoboExcelHelper.parseToString(marSetObject,mdt.value__c):'';
        return dynamicValue;
    }
    
    /**
     * @ADO Number : 152719
     * @Name : switchCalculationWhenAccount
	 * @description : This method get values for Account fields values.
	 */
    private static String switchCalculationWhenAccount(Free_Goods_Order_Robo_CSV__mdt mdt, Order__c order){
        String dynamicValue = '';
        SObject accountObject = accountMap.containsKey(order.Account__c) ? accountMap.get(order.Account__c):null;
        SObject shedAccount = deliveryShedAccMap.containsKey(order.Delivery_Shed_Account__c) ? deliveryShedAccMap.get(order.Delivery_Shed_Account__c): null;
        switch on mdt.Value__c { 
            when 'Name', 'BillingStreet', 'BillingCity', 'BillingPostalCode' {
                
                switch on order.Delivery_Location__c {
                    when 'Outlet' {
                        dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(accountObject, mdt.Value__c) ? EDGE_OrderFreeGoodsRoboExcelHelper.truncateValue(accountObject,mdt.Value__c):'';
                    }
                    when 'Shed' {
                        dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(shedAccount, mdt.Value__c) ? EDGE_OrderFreeGoodsRoboExcelHelper.truncateValue(shedAccount,mdt.Value__c):'';
                    }
                    when else{
                        System.debug(LoggingLevel.WARN ,'Location out of scope');
                    }
                }
            }
            when else {
                dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.nullCheck(accountObject, mdt.Value__c) ? EDGE_OrderFreeGoodsRoboExcelHelper.parseToString(accountObject,mdt.Value__c):'';
            }
        }
        //System.debug(LoggingLevel.Debug,'dynamicValue-22-'+dynamicValue);
        return dynamicValue;
    }
    /**
     * @ADO Number : 152719
     * @Name : processTableRow
	 * @description : This method to return List of CSV_CellData for Order Products.
	 */
    private static List<EDGE_CSVFileGenerator.CellData> processTableRow(Free_Goods_Order_Robo_CSV__mdt mdt,Id orderId){
        List<EDGE_CSVFileGenerator.CellData> tableRows = new List<EDGE_CSVFileGenerator.CellData>();
        Integer orderItemSize = orderLineItemsMap.containsKey(orderId)? orderLineItemsMap.get(orderId).size():0;
        
        for(Integer i=0; i<20; i++){
            sObject orderItem = i<orderItemSize ? orderLineItemsMap.get(orderId)[i]: null;
            
            sObject productItem = i<orderItemSize && productMap.containsKey(orderLineItemsMap.get(orderId)[i].Product__c)? 
                productMap.get(orderLineItemsMap.get(orderId)[i].Product__c): null;
            
            sObject internalOrder = i<orderItemSize && internalOrderMap.containsKey(orderLineItemsMap.get(orderId)[i].Reason_Code__r.Internal_Order__c) ? 
                internalOrderMap.get(orderLineItemsMap.get(orderId)[i].Reason_Code__r.Internal_Order__c):null;
            
            String dynamicValue = '';
            EDGE_SObjectMapWrapper sobjWrapper  = new EDGE_SObjectMapWrapper();
            sobjWrapper.orderItem = orderItem;
            sobjWrapper.productItem = productItem;
            sobjWrapper.internalOrder = internalOrder;
            dynamicValue = EDGE_OrderFreeGoodsRoboExcelHelper.switchCalculationWhenOrderProduct(mdt,sobjWrapper,i);
            System.debug(LoggingLevel.Debug,'dynamicValue @'+dynamicValue);
            tableRows.add(new EDGE_CSVFileGenerator.CellData((Integer.valueOf(mdt.Row_Number__c) + i), Integer.valueOf(mdt.Column_Number__c),dynamicValue));
        }
        return tableRows;
    }
    
    
    /**
     * @ADO Number : 152719
     * @Name : getAllMetaData
	 * @description : This method returns sorted List of Free_Goods_Order_Robo_CSV__mdt.
	 */
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
    
    
    /**
     * @ADO Number : 152719
     * @Name : EDGE_SObjectMapWrapper
	 * @description : This Wrapper class to send values to switchCalculationWhenOrderProduct method.
	 */
    public class EDGE_SObjectMapWrapper {
        /**
  * @description Order Products
  * @return sObject
  */
    public sObject orderItem{get;set;}
      /**
  * @description Products
  * @return sObject
  */
    public sObject productItem{get;set;}
      /**
  * @description Internal Orders
  * @return sObject
  */
    public sObject internalOrder{get;set;}
 }
}