/**
 * @name D1_SendSalesOrderToSAP
 * @purpose This class is used to send Sales Order Data to SAP I00261
 * @history                                                                                                                        
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Saurav Paul       23/12/2020        NCP-1361
 * 2.0         Mukesh Kanth      26/12/2023        US-148575: Pass Payment Term to SAP on Ordering
**/

@SuppressWarnings('PMD.PropertyNamingConventions')
global class D1_SendSalesOrderToSAP {

    /**
     * @description This method will send Order data to SAP
     * @param salesOrderId 
     * @return  `List<SalesOrderWrapper>`
     */    
    webservice static List<SalesOrderWrapper> sendSalesOrder(String salesOrderId) {
        List<SalesOrderWrapper> orderList = new List<SalesOrderWrapper>();
        if(String.isNotBlank(salesOrderId)){
            String sfInstance = [SELECT SF_Instance__c FROM D1_Commerce_SAP_Setting__mdt 
                                WHERE Developername='Instance_Value'].SF_Instance__c;

            for(Sales_Order__c salesOdrData : [SELECT Id,Name,Delivery_Date__c,Purchase_Order_Number__c,
                                                   Contact_email__c,CreatedDate,Booking_Indicator__c,
                                                   Order_Summary__r.Shipto_Party__c,Order_Summary__r.Soldto_Party__c,
                                                   Order_Summary__r.Sales_Area__r.Sales_Organisation_Code__c,
                                                   Order_Summary__r.Sales_Area__r.Division_Code__c,Order_Summary__r.Sales_Area__r.Distribution_Channel_Code__c,
                                                   Order_Summary__r.Account.Name,Order_Summary__r.Delivery_Instructions__c,Order_Summary__r.Customer_Service_Instruction__c,Order_Summary__r.Payment_Term_Code__c,	//Added Order_Summary__r.Payment_Term_Code__c for US-148575
                                                    (SELECT Id,Plant__c,Unit_of_Measure__c,Discount_Surcharge__c,
                                                     StockKeepingUnit,Quantity,linenumber,Portfolio_Item__r.Ordering_UoM_Override__c
                                                    FROM Order_Product_Summaries__r)
                                                FROM Sales_Order__c
                                                WHERE Id =: salesOrderId]){
                List<OrderItemSummaryWrapper> orderSumItemsList = new List<OrderItemSummaryWrapper>();                                       
                SalesOrderWrapper orderVal = new SalesOrderWrapper(); 
                orderVal.IdVal = salesOdrData.Id;
                orderVal.OrderNumber = salesOdrData.Name;
                orderVal.DeliveryDate  = salesOdrData.Delivery_Date__c;
                orderVal.CreatedDate  = salesOdrData.CreatedDate;
                orderVal.ShipTo = salesOdrData.Order_Summary__r.Shipto_Party__c;
                orderVal.SoldTo = salesOdrData.Order_Summary__r.Soldto_Party__c;
                orderVal.DeliveryInstruction = salesOdrData.Order_Summary__r.Delivery_Instructions__c;
                orderVal.SalesOrgCode = salesOdrData.Order_Summary__r.Sales_Area__r.Sales_Organisation_Code__c;
                orderVal.DistributionChannelCode = salesOdrData.Order_Summary__r.Sales_Area__r.Distribution_Channel_Code__c;
                orderVal.DivisionCode = salesOdrData.Order_Summary__r.Sales_Area__r.Division_Code__c;
                orderVal.CustomerReference = salesOdrData.Purchase_Order_Number__c;
                orderVal.ContactEmail = salesOdrData.Contact_email__c;
                orderVal.ContactName = salesOdrData.Order_Summary__r.Account.Name;//Account Name
                orderVal.IdSystem = sfInstance;
                orderVal.InternalInstruction = salesOdrData.Order_Summary__r.Customer_Service_Instruction__c;
                orderVal.DeliveryType = salesOdrData.Booking_Indicator__c;
                orderVal.PaymentTermCode = salesOdrData.Order_Summary__r.Payment_Term_Code__c!=null?salesOdrData.Order_Summary__r.Payment_Term_Code__c:'';	//Added for US-148575
                orderVal.BillingNote = '';
                orderVal.SAPSalesRepId =  '';
                for(OrderItemSummary ordItmVal : salesOdrData.Order_Product_Summaries__r){
                    OrderItemSummaryWrapper summaryObj =  new OrderItemSummaryWrapper();   
                    summaryObj.QtyOrdered  = ordItmVal.Quantity;
                    summaryObj.ItemCount  = ordItmVal.linenumber;
                    summaryObj.Plant = ordItmVal.Plant__c;
                    summaryObj.SelectedMaterial  = ordItmVal.StockKeepingUnit;
                    summaryObj.IdVal = ordItmVal.Id;
                    //Modified for NCP-2611
                    if(String.isNotBlank(ordItmVal.Portfolio_Item__r.Ordering_UoM_Override__c)){
                        summaryObj.UnitOfMeasure = ordItmVal.Portfolio_Item__r.Ordering_UoM_Override__c;
                    }else{
                        summaryObj.UnitOfMeasure = ordItmVal.Unit_of_Measure__c;
                    }
                    if(ordItmVal.Discount_Surcharge__c != null) {
                        summaryObj.DiscountSurcharge = ordItmVal.Discount_Surcharge__c;
                    }
                    else {
                        summaryObj.DiscountSurcharge = 0.0;
                    }
                    orderSumItemsList.add(summaryObj);
                        
                } 
                orderVal.Items =  orderSumItemsList;                               
                orderList.add(orderVal);    
            }
        }
        return orderList ;
    }
    /**
      * @description Wrapper class to send Sales Order
	  **/  
    global class SalesOrderWrapper {
        webservice String   IdVal  {get; set;} 
        webservice String   OrderNumber {get; set;} 
        webservice DateTime DeliveryDate {get; set;} 
        webservice DateTime CreatedDate {get; set;} 
        webservice String   ShipTo {get; set;} 
        webservice String   SoldTo {get; set;} 
        webservice String   DeliveryInstruction {get; set;} 
        webservice String   SalesOrgCode {get; set;} 
        webservice String   DistributionChannelCode {get; set;} 
        webservice String   DivisionCode {get; set;} 
        webservice String   CustomerReference {get; set;} 
        webservice String   ContactEmail {get; set;} 
        webservice String   ContactName {get; set;} 
        webservice String   IdSystem {get; set;}
        webservice String   InternalInstruction {get; set;}
        webservice String   DeliveryType {get; set;}
        webservice String   PaymentTermCode {get;set;}
        webservice String   BillingNote {get;set;}
        webservice String   SAPSalesRepId {get;set;}
        webservice List<OrderItemSummaryWrapper> Items {get; set;} 
    }
    /**
      * @description Wrapper class to send Sales Order Items
	  **/
    global class OrderItemSummaryWrapper {
        webservice Decimal  QtyOrdered { get; set;} 
        webservice Decimal  ItemCount { get; set;} 
        webservice String   Plant { get; set;} 
        webservice String   SelectedMaterial { get; set;} 
        webservice String   IdVal { get; set;} 
        webservice String   UnitOfMeasure { get; set;}
        webservice Double  DiscountSurcharge {get;set;}
    }
}