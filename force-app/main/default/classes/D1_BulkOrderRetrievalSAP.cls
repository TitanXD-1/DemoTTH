/*
 * @name : D1_BulkOrderRetrievalSAP
 * @description : WSDL Class for retrieving Sales Order in Bulk [I00246]
 * @history                                                                                                                     
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Srutadeba Chanda  30/12/2020        Initial Development (NCP-1360)
 * 2.0			Saurav Paul		  22/03/2021		Modified for NCP-2611
 **/
global class D1_BulkOrderRetrievalSAP {
    public D1_BulkOrderRetrievalSAP() {
        System.debug(LoggingLevel.INFO, 'EmptyBlock');
    }
    /*
    * @name : findOrderItemsBySalesArea
    * @descritpion Called by SAP/PI. Returns list of Sales Order along with Items based on Sales Area where Sales Order field Status is set to "New"
    * @param String SAP Sales Area external Id 
    * @return List<OrderItemSummaryWrapper>
    */ 
    webservice static List<OrderItemSummaryWrapper> findOrderItemsBySalesArea(String sAPSalesArea, Integer iLimit) {
        if(sAPSalesArea!=null&&sAPSalesArea!=''){
            
            List<OrderItemSummaryWrapper> orderItems = new  List<OrderItemSummaryWrapper>();
            for(Sales_Order__c salesOrderList : [SELECT id,Name,Order_Status__c,Order_Summary__r.Delivery_Instructions__c,Order_Summary__r.Sales_Area__r.Name,
                                                 Order_Summary__r.Sales_Area__r.Sales_Organisation_Code__c,Order_Summary__r.Sales_Area__r.Distribution_Channel_Code__c,
                                                 Order_Summary__r.Sales_Area__r.Division_Code__c,SAP_Order_Number__c,Purchase_Order_Number__c,
                                                 Order_Summary__r.Shipto_Party__c, Order_Summary__r.Soldto_Party__c,
                                                 Order_Summary__r.Sales_Area__r.Sales_Area_ID__c,Order_Summary__r.Account.Name,
                                                 Order_Summary__r.Account.KUNNR__c,Delivery_Date__c,Contact_email__c,
                                                 CreatedDate,Order_Summary__r.Customer_Service_Instruction__c ,
                                                 (SELECT Id, 
                                                  Name,
                                                  Plant__c,
                                                  Quantity,
                                                  Unit_of_Measure__c,
                                                  Product2.SAP_Material_Id__c,
                                                  Product2.Name,
                                                  CreatedDate,
                                                  LastModifiedDate,
                                                  Discount_Surcharge__c,
                                                  Item_Position__c,
                                                  Portfolio_Item__r.Ordering_UoM_Override__c,
                                                  LineNumber FROM Order_Product_Summaries__r ORDER BY Sales_Order__c,LineNumber)
                                                 FROM Sales_Order__c WHERE Order_Status__c='New' AND Order_Summary__r.Sales_Area__r.Sales_Area_ID__c =:sAPSalesArea
                                                 LIMIT :iLimit])
            {                                         
                
                for(OrderItemSummary ordItmVal : salesOrderList.Order_Product_Summaries__r){
                    OrderItemSummaryWrapper orderItemObj = new OrderItemSummaryWrapper();
                    orderItemObj.orderId = salesOrderList.id;
                    orderItemObj.orderNumber=salesOrderList.Name;
                    orderItemObj.poNumber=salesOrderList.Purchase_Order_Number__c;
                    orderItemObj.deliveryDate=salesOrderList.Delivery_Date__c;
                    orderItemObj.createdDate=salesOrderList.CreatedDate;                
                    orderItemObj.shipTo=salesOrderList.Order_Summary__r.Shipto_Party__c;
                    orderItemObj.soldTo=salesOrderList.Order_Summary__r.Soldto_Party__c;
                    orderItemObj.contactEmail=salesOrderList.Contact_email__c;
                    orderItemObj.deliveryInstruction=salesOrderList.Order_Summary__r.Delivery_Instructions__c;
                    orderItemObj.internalInstruction=salesOrderList.Order_Summary__r.Customer_Service_Instruction__c;
                    orderItemObj.salesAreaName=salesOrderList.Order_Summary__r.Sales_Area__r.Name;
                    orderItemObj.salesOrgCode=salesOrderList.Order_Summary__r.Sales_Area__r.Sales_Organisation_Code__c;
                    orderItemObj.distributionChannelCode=salesOrderList.Order_Summary__r.Sales_Area__r.Distribution_Channel_Code__c;
                    orderItemObj.divisionCode=salesOrderList.Order_Summary__r.Sales_Area__r.Division_Code__c;
                    orderItemObj.accountName=salesOrderList.Order_Summary__r.Account.Name;
                    orderItemObj.kunnr= salesOrderList.Order_Summary__r.Account.KUNNR__c;  
                    // Order Items                                 
                    orderItemObj.orderItemId=ordItmVal.Id;
                    orderItemObj.orderItemName= ordItmVal.Product2.Name;
                    orderItemObj.itemCount=string.valueOf(ordItmVal.LineNumber);
                    orderItemObj.plant=ordItmVal.Plant__c;
                    orderItemObj.qtyOrdered=ordItmVal.Quantity;
                    //Modified for NCP-2611
                    if(String.isNotBlank(ordItmVal.Portfolio_Item__r.Ordering_UoM_Override__c)){
                        orderItemObj.unitOfMeasure = ordItmVal.Portfolio_Item__r.Ordering_UoM_Override__c;
                    }else{
                        orderItemObj.unitOfMeasure = ordItmVal.Unit_of_Measure__c;
                    }
                    orderItemObj.unitOfMeasure=ordItmVal.Unit_of_Measure__c;
                    orderItemObj.materialId=ordItmVal.Product2.SAP_Material_Id__c;
                    if(ordItmVal.Discount_Surcharge__c != null){
                        orderItemObj.discountSurcharge=ordItmVal.Discount_Surcharge__c;
                    }else{
                        orderItemObj.discountSurcharge=0.0;
                    }
                    orderItems.add(orderItemObj);  
                }   
            }

            return orderItems;
        }else{
            return null;
        }
    }
    
    global class OrderItemSummaryWrapper {
        webservice string orderId {get;set;}
        webservice string orderNumber {get;set;}
        webservice String poNumber {get; set;}
        webservice DateTime deliveryDate {get; set;}
        webservice DateTime createdDate {get; set;}        
        webservice String shipTo {get; set;}
        webservice String soldTo {get; set;}
        webservice String contactEmail {get; set;} 
        webservice String contactName {get; set;}
        webservice String deliveryInstruction {get; set;}
        webservice String internalInstruction {get; set;}
        webservice String salesAreaName {get;set;}
        webservice String salesOrgCode {get; set;}
        webservice String distributionChannelCode {get; set;} 
        webservice String divisionCode {get; set;}
        webservice String accountName {get;set;}
        webservice String kunnr {get;set;}
        webservice String orderItemId {get;set;}
        webservice String orderItemName {get;set;}
        webservice String itemCount {get;set;}
        webservice String plant {get; set;}
        webservice Decimal qtyOrdered {get; set;}
        webservice String unitOfMeasure {get; set;}
        webservice String materialId {get; set;}
        webservice Double discountSurcharge {get;set;}
    }
}