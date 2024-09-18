/*
*Name: EDGE_OrderFreeGoodsTriggerHelperTest

*Purpose: This test class is used to cover the Trigger Helper Class for Free goods order.

*History                                                            
                                                            
VERSION    AUTHOR              DATE              DETAIL
1.0                        20/01/2020       ES20-4759,ES20-4483
*/
@isTest
public class EDGE_OrderFreeGoodsTriggerHelperTest {
    @isTest
    public static void freeGoodOrdStatusUpdtTest(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
        marketSetting.Threshold_Format__c = 'Percent';
        insert marketSetting;
        
        
        
        //Insert salesManager
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager; 
        
        //Insert SalesRep
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1', 'Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesRep.Id;
        insert salesRep;
        System.assert(salesRep.Id!=null,'salesRep should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        //Insert Pick_Up_Options__c
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        Test.startTest();
        
        //Insert Account (outlet)
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        outlet.Primary_Sales_Rep__c = salesRep.Id;
        insert outlet;
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
            
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
            
        Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHierRegion.Parent_BU__c = terriHierSA.Id;
        insert terriHierRegion;
        
        //Insert Territory
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'service';
        territory.Business_Unit__c=terriHierBU.Id;
        Insert territory;
        
        //Insert Territory Budget
        Territory_Budget__c territoryBudget = new Territory_Budget__c();
        territoryBudget.Territory__c = territory.Id;
        territoryBudget.Start_Date__c = Date.newInstance(2020, 01, 01);
        territoryBudget.End_Date__c = Date.newInstance(2020, 01, 22);
        territoryBudget.Initial_Amount__c = 100;
        territoryBudget.Spent_Amount__c = 10;
        territoryBudget.ECM_Territory_Hierarchy__c=terriHierBU.Id;
        insert territoryBudget;
        
        
        //Insert Order__c
        String orderRecordtype = Order__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c order = new Order__c();
        order.Account__c = outlet.Id;
        order.Budget_ID__c = territoryBudget.Id;
        order.Sales_Representative__c = salesRep.Id;
        order.RecordTypeId = orderRecordtype;
        order.Delivery_Start_Date__c = date.newInstance(2020, 01, 30);
        order.Free_Goods_A_P_Cost__c = 10;
        order.Total_A_P_Cost__c = 22; 
        order.Status__c = 'Draft';
        insert order;
        Test.stopTest();
        order.Status__c = 'Submitted';
        update order;
        order__c order1 = [Select Status__c From Order__c where Id =: order.Id Limit 1];
        system.assertEquals('Ready for Order', order1.Status__c,'Ready for order should match');
        order.Total_A_P_Cost__c = 110;
        update order;
        
    }
    
    @isTest
    public static void compareThresholdValueTest(){
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AUT');
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Market__c = true;
        marketSetting.Threshold_Free_Goods_A_P__c = 40;
        insert marketSetting;
        
         EDGE_UtilityTestClass.createOrgSettings();
        
         //Insert Pick_Up_Options__c
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AUT]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        Test.startTest();
        
         //Insert Account (outlet)
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        insert outlet;
        
        //Insert Contract
         Contract contract = new Contract();
        contract.Name = 'ObjContract';
        contract.AccountId = outlet.Id;
        contract.Status = 'Draft';
        contract.StartDate = system.today();
        contract.Contract_End_Date__c = system.today().addDays(10);
        contract.UOS_Target__c  = 8000;
        contract.UOS_AP_Rate__c = 5;
        contract.UOS_Rebate_Rate__c = 2;
        contract.AP_Spent__c = 80;
        contract.UOS_Earnt__c = 4000;
        contract.Opening_AP_Balance__c = 100;
        //contract.Available_AP_Spend__c = 50.00;
        insert contract;
        
       
        //List<Order__c> orderList = new List<Order__c>();
        //Insert Order__c
        String orderRecordtype = Order__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c order = new Order__c();
        order.Account__c = outlet.Id;
        order.RecordTypeId = orderRecordtype;
        order.Delivery_Start_Date__c = date.newInstance(2020, 01, 30);
        order.Total_A_P_Cost__c = 22; 
        //order.Free_Goods_A_P_Cost__c = 1;
        order.Status__c = 'Draft';
		order.Contract__c = contract.Id;
        insert order;
        system.assert(order.Id!=null,'order Id should not be null');
        order.Status__c = 'Submitted';
		order.Free_Goods_A_P_Cost__c = 50;
        update order;
        /*order.Free_Goods_A_P_Cost__c = 50;
        update order;*/
        test.stopTest();
    }
    
    @isTest
    public static void testRevertAPBudget(){
        
        Id countryId= EDGE_UtilityTestClass.setupCountry('AUT');
        Market_Setting__c marketSetting = EDGE_UtilityTestClass.getMarketSetting(countryId);       
        marketSetting.Threshold_Format__c = 'Percent';
        marketSetting.A_P_Market__c = true;
        marketSetting.Threshold_Free_Goods_A_P__c = 40;
        marketSetting.Free_Goods_SAP_Automation__c = 'Direct to SAP';
        insert marketSetting;
        System.assert(marketSetting.name!=null,'marketSetting name should not be null'); //Added by Divya 
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        //Insert Pick_Up_Options__c
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AUT]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        Test.startTest();
        
        //Insert Account (outlet)
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        insert outlet;
        
        //Insert Contract
        Contract contract = new Contract();
        contract.Name = 'ObjContract';
        contract.AccountId = outlet.Id;
        contract.Status = 'Draft';
        contract.StartDate = system.today();
        contract.Contract_End_Date__c = system.today().addDays(10);
        contract.UOS_Target__c  = 8000;
        contract.UOS_AP_Rate__c = 5;
        contract.UOS_Rebate_Rate__c = 2;
        contract.AP_Spent__c = 80;
        contract.UOS_Earnt__c = 4000;
        contract.Opening_AP_Balance__c = 1000;
        //contract.Available_AP_Spend__c = 50.00;
        insert contract;
        
        system.debug(LoggingLevel.Debug,'$$$$ Available_AP_Spend__c'+contract.Available_AP_Spend__c);
        
        //List<Order__c> orderList = new List<Order__c>();
        //Insert Order__c
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        deliveryPartner.Batch_Notification__c = true;
        deliveryPartner.Allow_Free_Goods_Order_to_SAP__c = true;
        insert deliveryPartner;        
        
        String orderRecordtype = Order__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        Order__c order = new Order__c();
        order.Account__c = outlet.Id;
        order.RecordTypeId = orderRecordtype;
        order.Delivery_Partner__c = deliveryPartner.Id;
        order.Delivery_Start_Date__c = date.newInstance(2020, 01, 30);
        order.Total_A_P_Cost__c = 22; 
        //order.Free_Goods_A_P_Cost__c = 1;
        order.Status__c = 'Draft';
        order.Contract__c = contract.Id;
        insert order;
        /*order.Status__c = 'Submitted';
        update order;
        order.Status__c = 'Approval In Progress';
        order.Free_Goods_A_P_Cost__c = 50;
        update order;*/
        System.debug(LoggingLevel.Debug,'1. order_Contract__c = '+ order.Contract__c);
        order.Status__c = 'Ready for Order';
        update order;        
        System.debug(LoggingLevel.Debug,'2. order = '+ order);
        test.stopTest();
        
    }
}