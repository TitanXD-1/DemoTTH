/*
 * @name: D1_CheckoutFlow_CreateSalesOrder
 * @description : Utility Class for creating Sales Order view Checkout Flow
 * @history                                                                                                                   
 * VERSION     AUTHOR              DATE            DETAIL
 * 1.0         Dipanjan Das        01/08/2021      Initial Development(NCP-)
 * 2.0         Ajay                22/11/2021      Sales order new fields (NCP-4500)
 **/
public without sharing class D1_CheckoutFlow_CreateSalesOrder {
	/**
	 * @description 
	 * @param orderSummaryList 
	 */	
    @InvocableMethod(label='Create Sales Order' description='')
    public static void createSalesOrder(List<OrderSummary> orderSummaryList){
        List<Sales_Order__c> salesOrdersToInsert = new List<Sales_Order__c>();
        List<OrderItemSummary> oItemItemSummariesToUpdate = new List<OrderItemSummary>();
        Map<Id, Id> splitWithSalesOrderMap = new Map<Id, Id>();
        List<Sales_Order__c> salesOrderList = [SELECT Id FROM Sales_Order__c WHERE Order_Summary__c = :orderSummaryList[0].Id];

		//Create Sales Order based on Order Split
		if(salesOrderList.isEmpty()){
			if(orderSummaryList[0].Order_Split_1__c != null){
				Sales_Order__c salesOrderSplit1 = new Sales_Order__c();
				salesOrderSplit1.CurrencyIsoCode = orderSummaryList[0].CurrencyIsoCode;
				salesOrderSplit1.Order_Status__c = 'Draft';
				salesOrderSplit1.Order_Summary__c = orderSummaryList[0].Id;
				salesOrderSplit1.Purchase_Order_Number__c = orderSummaryList[0].Split_1_PO_Number__c;
				salesOrderSplit1.Delivery_Date__c = orderSummaryList[0].Split_1_Delivery_date__c;
				salesOrderSplit1.Contact_email__c = orderSummaryList[0].BillingEmailAddress;
				salesOrderSplit1.Order_Split__c = orderSummaryList[0].Order_Split_1__c;
				salesOrderSplit1.Amount__c = 0.00;
				salesOrderSplit1.Tax__c = 0.00;

                //Added NCP-4500
                salesOrderSplit1.Sales_Area__c = orderSummaryList[0].Sales_Area__c;
                salesOrderSplit1.Soldto_Party__c = orderSummaryList[0].Soldto_Party__c;
                salesOrderSplit1.Shipto_Party__c = orderSummaryList[0].Shipto_Party__c;
                
				salesOrdersToInsert.add(salesOrderSplit1);
			}
			if(orderSummaryList[0].Order_Split_2__c != null){           
				Sales_Order__c salesOrderSplit2 = new Sales_Order__c();
				salesOrderSplit2.CurrencyIsoCode = orderSummaryList[0].CurrencyIsoCode;
				salesOrderSplit2.Order_Status__c = 'Draft';
				salesOrderSplit2.Order_Summary__c = orderSummaryList[0].Id;
				salesOrderSplit2.Purchase_Order_Number__c = orderSummaryList[0].Split_2_PO_Number__c;
				salesOrderSplit2.Delivery_Date__c = orderSummaryList[0].Split_2_Delivery_date__c;
				salesOrderSplit2.Contact_email__c = orderSummaryList[0].BillingEmailAddress;
				salesOrderSplit2.Order_Split__c = orderSummaryList[0].Order_Split_2__c;
				salesOrderSplit2.Amount__c = 0.00;
				salesOrderSplit2.Tax__c = 0.00;

                //Added NCP-4500
                salesOrderSplit2.Sales_Area__c = orderSummaryList[0].Sales_Area__c;
                salesOrderSplit2.Soldto_Party__c = orderSummaryList[0].Soldto_Party__c;
                salesOrderSplit2.Shipto_Party__c = orderSummaryList[0].Shipto_Party__c;

				salesOrdersToInsert.add(salesOrderSplit2);
			}

			if (!salesOrdersToInsert.isEmpty()) {
				insert salesOrdersToInsert;
			}

			Map<Id,Sales_Order__c> salesOrdersMapToUpdate = new Map<Id,Sales_Order__c>([SELECT Id, Order_Split__c, Order_Status__c, Amount__c,Tax__c FROM Sales_Order__c WHERE Order_Summary__c = :orderSummaryList[0].Id]);
			
			//Update Status = Queued
			for(Id salesOrdId : salesOrdersMapToUpdate.keySet()){
				splitWithSalesOrderMap.put(salesOrdersMapToUpdate.get(salesOrdId).Order_Split__c, salesOrdId);
				salesOrdersMapToUpdate.get(salesOrdId).Order_Status__c = 'Queued';
			}
				
			//Update Sales Order into OrderItemSummary & Ammount/Tax into Sales Order
			for(OrderItemSummary oItemSummary : [SELECT Id, OrderSplit_Type__c, Portfolio_Item__c, TotalLineAmount, TotalTaxAmount  
													FROM OrderItemSummary WHERE OrderSummaryId = :orderSummaryList[0].Id])
			{
				oItemSummary.Sales_Order__c = splitWithSalesOrderMap.containsKey(oItemSummary.OrderSplit_Type__c) ? splitWithSalesOrderMap.get(oItemSummary.OrderSplit_Type__c) : null;
				
				oItemItemSummariesToUpdate.add(oItemSummary);
				
				Sales_Order__c salesOrd = salesOrdersMapToUpdate.get(oItemSummary.Sales_Order__c);
                if (salesOrd!= null){
                salesOrd.Amount__c += (oItemSummary.TotalLineAmount != null ? oItemSummary.TotalLineAmount : 0.00);
				salesOrd.Tax__c += (oItemSummary.TotalTaxAmount != null ? oItemSummary.TotalTaxAmount : 0.00);
                salesOrdersMapToUpdate.put(oItemSummary.Sales_Order__c, salesOrd);			
                }
				
					
			}

			//Update OrderItemSummary
			if (!oItemItemSummariesToUpdate.isEmpty()) {
				update oItemItemSummariesToUpdate;
			}

			//Update Sales Order
			if (!salesOrdersMapToUpdate.isEmpty()) {
				update salesOrdersMapToUpdate.values();
			}
        }
    }
}