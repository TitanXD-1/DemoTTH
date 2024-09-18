/*
* @Description: EDGE_TransferOrderStatusUpdateBatchTest

* @Purpose: Test class of EDGE_TransferOrderStatusUpdateBatch

* @History:                                                         

* @VERSION   	AUTHOR                DATE              DETAIL
*	1.0       Monalisa Halder    	04/11/2019    	Initial Development 
*   1.1       Aparajita				20/01/2022		ES20-11954
**/

@isTest
public class EDGE_TransferOrderStatusUpdateBatchTest {
    static Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
    
    @istest
    public static void testTransferOrderBatch(){
        //Test.startTest(); 
        createtestData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_TransferOrderStatusUpdateBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null,'batch Setting Id should not be null');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(6));
        //Test.stopTest();
    }
    
    public static void createtestData(){ 
        //Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Test.startTest();
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Language__c = 'en_US';
        marketSettings.Display_Transfer_Order_Comments__c = True;
        insert marketSettings;
        
        EDGE_UtilityTestClass.createOrgSettings();
       
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        List<Account> accList = new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Country__c = countryId;
        outlet.BillingState = 'Tasmania';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.ShippingCountry='Australia';
        accList.add(outlet);
        System.debug(LoggingLevel.Debug,'AccntLst'+outlet.Country_Code__c);
        Account shed = EDGE_UtilityTestClass.getShedRecord();
        shed.BillingStreet = '20 Asian Ridge 105';
        accList.add(shed);
        
        Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
        wholesaler.Country__c = countryId;
        wholesaler.BillingState = 'Tasmania';
        wholesaler.Outlet_Email_Address__c = 'monal.halder@diageo.com';
        wholesaler.ShippingCountry='Australia';
        wholesaler.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
     	
        accList.add(wholesaler);
        insert accList;
        
        AccountTeamMember accShare = new AccountTeamMember();
        accShare.AccountId = shed.Id;
        accShare.AccountAccessLevel = 'All';
        accShare.OpportunityAccessLevel = 'Read';
        accShare.CaseAccessLevel = 'Read';
        accShare.ContactAccessLevel = 'Edit';
        accShare.UserId = UserInfo.getUserId();
        accShare.TeamMemberRole = 'Sales Rep';
        insert accShare;
        
        
        
        String transferOrderId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order').getRecordTypeId();
        
        List<Order__c> orderListToInsert = new List<Order__c>();

        Order__c transferOrder1 = new Order__c();
        transferOrder1.RecordTypeId = transferOrderId;
        transferOrder1.Account__c = outlet.Id;
        transferOrder1.Sales_Representative__c = UserInfo.getUserId();
        transferOrder1.Wholesaler__c = wholesaler.Id;
        transferOrder1.Status__c = 'Ready for Order';
        transferOrder1.Preferred_Delivery_Date__c = system.today().addDays(2);
        transferOrder1.Comments__c = 'hello1';
        orderListToInsert.add(transferOrder1);
        
        Order__c transferOrder2 = new Order__c();
        transferOrder2.RecordTypeId = transferOrderId;
        transferOrder2.Account__c = outlet.Id;
        transferOrder2.Sales_Representative__c = UserInfo.getUserId();
        transferOrder2.Wholesaler__c = wholesaler.Id;
        transferOrder2.Status__c = 'Ready for Order';
        transferOrder2.Preferred_Delivery_Date__c = system.today().addDays(2);
        transferOrder2.Comments__c = 'hello2';
        orderListToInsert.add(transferOrder2); 
        
        Order__c transferOrder3 = new Order__c();
        transferOrder3.RecordTypeId = transferOrderId;
        transferOrder3.Account__c = outlet.Id;
        transferOrder3.Sales_Representative__c = UserInfo.getUserId();
        transferOrder3.Wholesaler__c = wholesaler.Id;
        transferOrder3.Status__c = 'Ready for Order';
        transferOrder3.Preferred_Delivery_Date__c = system.today().addDays(2);
        transferOrder3.Comments__c = 'hello3';
        orderListToInsert.add(transferOrder3); 
        
        Order__c transferOrder4 = new Order__c();
        transferOrder4.RecordTypeId = transferOrderId;
        transferOrder4.Account__c = outlet.Id;
        transferOrder4.Sales_Representative__c = UserInfo.getUserId();
        transferOrder4.Wholesaler__c = wholesaler.Id;
        transferOrder4.Status__c = 'Ready for Order';
        transferOrder4.Preferred_Delivery_Date__c = system.today().addDays(2);
        transferOrder4.Comments__c = 'hello4';
        orderListToInsert.add(transferOrder4); 
        
        Order__c transferOrder5 = new Order__c();
        transferOrder5.RecordTypeId = transferOrderId;
        transferOrder5.Account__c = outlet.Id;
        transferOrder5.Sales_Representative__c = UserInfo.getUserId();
        transferOrder5.Wholesaler__c = wholesaler.Id;
        transferOrder5.Status__c = 'Ready for Order';
        transferOrder5.Preferred_Delivery_Date__c = system.today().addDays(2);
        transferOrder5.Comments__c = 'hello5';
        orderListToInsert.add(transferOrder5); 
        
       	Order__c transferOrder6 = new Order__c();
        transferOrder6.RecordTypeId = transferOrderId;
        transferOrder6.Account__c = outlet.Id;
        transferOrder6.Sales_Representative__c = UserInfo.getUserId();
        transferOrder6.Wholesaler__c = wholesaler.Id;
        transferOrder6.Status__c = 'Ready for Order';
        transferOrder6.Preferred_Delivery_Date__c = system.today().addDays(2);
        transferOrder6.Comments__c = 'hello6';
        orderListToInsert.add(transferOrder6);   
        
        insert orderListToInsert;
        Test.stopTest();
        
        Product__c skuProduct = EDGE_UtilityTestClass.getProd();
        skuProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        skuProduct.Start_Date__c = system.today();
        insert skuProduct;
        
        Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=skuProduct.Id);
        insert testMAP;
        
        String transferOrderItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Transfer Order Item').getRecordTypeId();
        
        List<Order_Item__c> ordItemList = new List<Order_Item__c>();
        
        Order_Item__c transferOrderItem21 = new Order_Item__c();
        transferOrderItem21.Product__c = skuProduct.id;
        transferOrderItem21.Order__c = transferOrder1.id;
        transferOrderItem21.Quantity__c = 2 ;
        //transferOrderItem21.Selected_UoM__c = 'BHY' ;
        transferOrderItem21.GUID__c = '111';
        transferOrderItem21.Status__c = 'Ready for Order';
        transferOrderItem21.RecordTypeId = transferOrderItemId;
        ordItemList.add(transferOrderItem21);

        Order_Item__c transferOrderItem22 = new Order_Item__c();
        transferOrderItem22.Product__c = skuProduct.id;
        transferOrderItem22.Order__c = transferOrder2.id;
        transferOrderItem22.Quantity__c = 2 ;
        //transferOrderItem22.Selected_UoM__c = 'BHY' ;
        transferOrderItem22.GUID__c = '222';
        transferOrderItem22.Status__c = 'Ready for Order';
        transferOrderItem22.RecordTypeId = transferOrderItemId;
        ordItemList.add(transferOrderItem22);

        Order_Item__c transferOrderItem23 = new Order_Item__c();
        transferOrderItem23.Product__c = skuProduct.id;
        transferOrderItem23.Order__c = transferOrder3.id;
        transferOrderItem23.Quantity__c = 2 ;
        //transferOrderItem23.Selected_UoM__c = 'BHY' ;
        transferOrderItem23.GUID__c = '333';
        transferOrderItem23.Status__c = 'Ready for Order';
        transferOrderItem23.RecordTypeId = transferOrderItemId;
        ordItemList.add(transferOrderItem23);

        Order_Item__c transferOrderItem24 = new Order_Item__c();
        transferOrderItem24.Product__c = skuProduct.id;
        transferOrderItem24.Order__c = transferOrder4.id;
        transferOrderItem24.Quantity__c = 2 ;
        //transferOrderItem24.Selected_UoM__c = 'BHY' ;
        transferOrderItem24.GUID__c = '444';
        transferOrderItem24.Status__c = 'Ready for Order';
        transferOrderItem24.RecordTypeId = transferOrderItemId;
	    ordItemList.add(transferOrderItem24);

        Order_Item__c transferOrderItem25 = new Order_Item__c();
        transferOrderItem25.Product__c = skuProduct.id;
        transferOrderItem25.Order__c = transferOrder5.id;
        transferOrderItem25.Quantity__c = 2 ;
        //transferOrderItem25.Selected_UoM__c = 'BHY' ;
        transferOrderItem25.GUID__c = '555';
        transferOrderItem25.Status__c = 'Ready for Order';
		transferOrderItem25.RecordTypeId = transferOrderItemId;
		ordItemList.add(transferOrderItem25);
         
        Order_Item__c transferOrderItem26 = new Order_Item__c();
        transferOrderItem26.Product__c = skuProduct.id;
        transferOrderItem26.Order__c = transferOrder6.id;
        transferOrderItem26.Quantity__c = 2 ;
        //transferOrderItem26.Selected_UoM__c = 'BHY' ;
        transferOrderItem26.GUID__c = '666';
        transferOrderItem26.Status__c = 'Ready for Order';
		transferOrderItem26.RecordTypeId = transferOrderItemId;
		ordItemList.add(transferOrderItem26);

		insert ordItemList;
       
        //Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_AccountName', 'EDGE_AccountAdress', 'EDGE_EmailBody', 'EDGE_PrefOderDate','EGDE_ProductName','EDGE_ProductQuantity','EDGE_UOM','EDGE_OrderedProducts','EDGE_SubjectTO','EDGE_Sales_Rep_Name','EDGE_MobileNumber','EDGE_Email','EDGE_Order_Number','EDGE_OverallComment'}, 'en_US');
    }
}