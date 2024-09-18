/**
@name EDGE_OrderStockMovementTriggerHelperTest
@purpose Test Class for Stock Movement Order
**/




@istest
public class EDGE_OrderStockMovementTriggerHelperTest {
    
    
    @isTest
    public static void testValidateLineItemQuantity(){
        //System.debug('Quantity Test Method '+'testValidateLineItemQuantity');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');  
        System.assert(countryId!=null,'Country is Added');
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','System Administrator');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Business_Role__c = 'Test Business Role';
        
        List<User> uList = new List<User>();
        uList.add(testAdminUser);
        uList.add(salesManager);
        uList.add(salesRep);
        insert uList;
        
        System.runAs(testAdminUser)
        {
            
            Market_Setting__c mars = EDGE_UtilityTestClass.getMarketSetting(countryId);
            mars.Warehouse_Level__c = False;
            mars.Threshold_Format__c = 'Percent';
            insert mars;
            
            EDGE_UtilityTestClass.createOrgSettings();
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert shedAccount;
            Outlet_Member__c  outletMember = EDGE_UtilityTestClass.getOutletMemberRecord(shedAccount.Id, salesRep.Id, 'Primary' );
            insert outletMember;
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = shedAccount.Id ;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.TeamMemberRole = 'Sales Rep';
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert  newAccTeamMember;    
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Service';
            insert territory;
            
            Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
            orgSetting.Run_Validation_Rules__c = false;
            update orgSetting;
            Territory_Member__c territoryMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRep.Id,territory.Id);
            territoryMember.Start_Date__c = system.today();
            insert territoryMember;
            
            Order__c stockMovementOrderGroup = EDGE_UtilityTestClass.getStockMovementOrderGroup(salesRep.Id, shedAccount.Id);
            insert stockMovementOrderGroup;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            //System.debug('@@@'+limits.getQueries());
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Country__c =  countryId;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            test.startTest();
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=objProduct.Id);
            insert testMAP;
            Stock__c stock = EDGE_UtilityTestClass.getAllocationStock(countryId, objProduct.Id, salesRep.Id, territory.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            //stock.Area__c = area1.id;
            insert stock;
            System.runAs(salesRep){
                Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
                stockMovementOrder.Order_Group__c = stockMovementOrderGroup.Id;
                insert stockMovementOrder;
                
                Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
                String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem.RecordTypeId = shedItemId;
                orderItem.Type__c = 'Shed'; 
                insert orderItem;
                
                stockMovementOrder.Status__c = 'Submitted';    
                update stockMovementOrder;
            }
            //stockMovementOrderGroup.Status__c = 'Submitted';
            //update stockMovementOrderGroup;
            
            test.stopTest();
        }  
    }
    @isTest
    public static void testValidateLineItemQuantityHierarchy(){
        //System.debug('Quantity Test Method '+'testValidateLineItemQuantity');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(countryId!=null,'Country is Added'); 
        //System.debug('Condition 1 '+Limits.getQueries());
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','System Administrator');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Business_Role__c = 'Test Business Role';
        
        List<User> uList = new List<User>();
        uList.add(testAdminUser);
        uList.add(salesManager);
        uList.add(salesRep);
        insert uList;
        //System.debug('Condition 2 '+Limits.getQueries());
        System.runAs(testAdminUser)
        {
            
            Market_Setting__c mars = EDGE_UtilityTestClass.getMarketSetting(countryId);
            mars.Warehouse_Level__c = False;
            mars.Threshold_Format__c = 'Percent';
            insert mars;
            //System.debug('Condition 3 '+Limits.getQueries());
            
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            //System.debug('Condition 4 '+Limits.getQueries());
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert shedAccount;
            //System.debug('Condition 5 '+Limits.getQueries());
            Outlet_Member__c  outletMember = EDGE_UtilityTestClass.getOutletMemberRecord(shedAccount.Id, salesRep.Id, 'Primary' );
            insert outletMember;
            //System.debug('Condition 6 '+Limits.getQueries());
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = shedAccount.Id ;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.TeamMemberRole = 'Sales Rep';
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert  newAccTeamMember; 
            //System.debug('Condition 7 '+Limits.getQueries());
            
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Service';
            insert territory;
            //System.debug('Condition 8 '+Limits.getQueries());
            //System.debug('Condition 9 '+Limits.getQueries());
            Territory_Member__c territoryMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRep.Id,territory.Id);
            territoryMember.Start_Date__c = system.today();
            insert territoryMember;
            
            /*
System.debug('Condition 11 '+Limits.getQueries());*/
            
            
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            //System.debug('@@@'+limits.getQueries());
            //System.debug('Condition 12 '+Limits.getQueries());
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Country__c =  countryId;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            //System.debug('Condition 13 '+Limits.getQueries());
            /*Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id,stockMovementOrderGroup.Id);
String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
orderItem.RecordTypeId = shedItemId;
orderItem.Type__c = 'Shed'; 
insert orderItem;*/
            //System.debug('Condition 14 '+Limits.getQueries());
            
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=objProduct.Id);
            insert testMAP;
            //System.debug('Condition 15 '+Limits.getQueries());
            
            Stock__c stock = EDGE_UtilityTestClass.getAllocationStock(countryId, objProduct.Id, salesRep.Id, territory.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            //stock.Area__c = area1.id;
            insert stock;
            EDGE_UtilityTestClass.createOrgSettings();
            //System.debug('Condition 16 '+Limits.getQueries());
            Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
            orgSetting.Run_Validation_Rules__c = false;
            update orgSetting;
            System.runAs(salesRep){
                Order__c stockMovementOrderGroup = EDGE_UtilityTestClass.getStockMovementOrderGroup(salesRep.Id, shedAccount.Id);
                insert stockMovementOrderGroup;
                Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
                stockMovementOrder.Order_Group__c = stockMovementOrderGroup.Id;
                insert stockMovementOrder;
                //System.debug('Condition 17 '+Limits.getQueries());
                List<Order_Item__c>orderItems=new List<Order_Item__c>();
                Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrderGroup.Id);
                String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem1.RecordTypeId = shedItemId;
                orderItem1.Type__c = 'Shed'; 
                orderItems.add(orderItem1);
                Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
                //String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem2.RecordTypeId = shedItemId;
                orderItem2.Type__c = 'Shed'; 
                orderItems.add(orderItem2);
                Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrderGroup.Id);
                //String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem3.RecordTypeId = shedItemId;
                orderItem3.Type__c = 'Shed'; 
                orderItems.add(orderItem3);
                Order_Item__c orderItem4 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
                //String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem4.RecordTypeId = shedItemId;
                orderItem4.Type__c = 'Shed'; 
                orderItems.add(orderItem4);
                
                insert orderItems;
                test.startTest();
                //System.debug('Condition 18 '+Limits.getQueries());
                stockMovementOrderGroup.Status__c = 'Submitted';    
                update stockMovementOrderGroup;
                //System.debug('Condition 19 '+Limits.getQueries());
            }
            //stockMovementOrderGroup.Status__c = 'Submitted';
            //update stockMovementOrderGroup;
            
            test.stopTest();
        }  
    }
    
    @isTest
    public static void testValidateLineItemQuantityStockAvl(){
        //System.debug('Quantity Test Method '+'testValidateLineItemQuantityStockAvl');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(countryId!=null,'Country is Added');
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        
        System.runAs(testAdminUser){
            Market_Setting__c mars = EDGE_UtilityTestClass.getMarketSetting(countryId);
            mars.Warehouse_Level__c = False;
            mars.Threshold_Format__c = 'Percent';
            insert mars;
            List<User> usrlist = new  List<User> ();
            User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
            salesManager.Available_Countries__c = 'AU';
            usrlist.add(salesManager);
            // insert salesManager;  
            //        System.assert(salesManager.Id!=null);
            
            User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','System Administrator');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = salesManager.id;
            salesRep.Business_Role__c = 'Test Business Role';
            //insert salesRep; 
            //     System.assert(salesRep.Id!=null);
            usrlist.add(salesRep);
            insert usrlist;
            
            EDGE_UtilityTestClass.createOrgSettings();
            /* 
Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
pickupOption.Name = 'Gold[AU]';
insert pickupOption;
*/
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            // shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert shedAccount;
            
            Outlet_Member__c  outletMember = EDGE_UtilityTestClass.getOutletMemberRecord(shedAccount.Id, salesRep.Id, 'Primary' );
            insert outletMember;
            /*
AccountTeamMember newAccTeamMember = new AccountTeamMember();
newAccTeamMember.AccountId = shedAccount.Id ;
newAccTeamMember.UserId = salesRep.Id;
newAccTeamMember.TeamMemberRole = 'Sales Rep';
newAccTeamMember.AccountAccessLevel = 'Edit';
newAccTeamMember.OpportunityAccessLevel = 'Edit';
newAccTeamMember.ContactAccessLevel = 'Edit';
insert  newAccTeamMember;    */
            
            Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
            territory.Territory_Type__c = 'Service';
            insert territory;
            
            Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
            orgSetting.Run_Validation_Rules__c = false;
            update orgSetting;
            
            /*
Territory_Member__c territoryMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRep.Id,territory.Id);
territoryMember.Start_Date__c = system.today();
insert territoryMember;*/
            
            Order__c stockMovementOrderGroup = EDGE_UtilityTestClass.getStockMovementOrderGroup(salesRep.Id, shedAccount.Id);
            insert stockMovementOrderGroup;
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Country__c =  countryId;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            test.startTest();
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=objProduct.Id);
            insert testMAP;
            Stock__c stock = EDGE_UtilityTestClass.getAllocationStock(countryId, objProduct.Id, salesRep.Id, territory.Id);
            stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
            stock.Original_Stock__c = 2000;
            stock.Allocated__c = 100000;
            stock.Consumed_Stock__c = 1;
            //
            insert stock;
            System.runAs(salesRep){
                List<Order__c> orders=new List<Order__c>();
                Order__c stockMovementOrderGroupToBeSubmitted=EDGE_UtilityTestClass.getStockMovementOrderGroup(salesRep.Id, shedAccount.Id);
                orders.add(stockMovementOrderGroupToBeSubmitted);
                Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
                orders.add(stockMovementOrder);
                insert orders;
                
                List<Order_Item__c> orderItems=new List<Order_Item__c>();
                Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrderGroupToBeSubmitted.Id);
                String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem2.RecordTypeId = shedItemId;
                orderItem2.Type__c = 'Shed'; 
                orderItem2.Quantity__c = 1;
                orderItem2.Stock__c=stock.Id;
                orderItem2.Product__c=objProduct.Id;
                orderItems.add(orderItem2);
                Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
                //String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
                orderItem.RecordTypeId = shedItemId;
                orderItem.Type__c = 'Shed'; 
                orderItem.Quantity__c = 1;
                orderItem.Stock__c=stock.Id;
                orderItem.Product__c=objProduct.Id;
                orderItems.add(orderItem);
                insert orderItems;
                stockMovementOrderGroupToBeSubmitted.Status__c='Submitted';
                stockMovementOrder.Status__c = 'Submitted';    
                update orders; 
                Map<Order_Item__c,Id> orderItemMap=new Map<Order_Item__c,Id>();
                orderItemMap.put(orderItem,salesRep.Id);
                orderItemMap.put(orderItem2,salesRep.Id);
                EDGE_OrderStockMovementTriggerHelper.validateStockQuantity(orderItemMap,orderItemMap);
                
            }
            
            test.stopTest();
        }
    }
    
    /* @isTest
public static void testValidateLineItemQuantityStockAvl(){

Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 

User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
testAdminUser.Available_Countries__c = 'AU';

User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
salesManager.Available_Countries__c = 'AU';

User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','System Administrator');
salesRep.Available_Countries__c = 'AU';
salesRep.ManagerId = salesManager.id;
salesRep.Business_Role__c = 'Test Business Role';

List<User> uList = new List<User>();
uList.add(testAdminUser);
uList.add(salesManager);
uList.add(salesRep);
insert uList;

System.runAs(testAdminUser){
Market_Setting__c mars = EDGE_UtilityTestClass.getMarketSetting(countryId);
mars.Warehouse_Level__c = False;
mars.Threshold_Format__c = 'Percent';
insert mars;

EDGE_UtilityTestClass.createOrgSettings();

Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
pickupOption.Name = 'Gold[AU]';
insert pickupOption;

Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
insert shedAccount;

Outlet_Member__c  outletMember = EDGE_UtilityTestClass.getOutletMemberRecord(shedAccount.Id, salesRep.Id, 'Primary' );
insert outletMember;

AccountTeamMember newAccTeamMember = new AccountTeamMember();
newAccTeamMember.AccountId = shedAccount.Id ;
newAccTeamMember.UserId = salesRep.Id;
newAccTeamMember.TeamMemberRole = 'Sales Rep';
newAccTeamMember.AccountAccessLevel = 'Edit';
newAccTeamMember.OpportunityAccessLevel = 'Edit';
newAccTeamMember.ContactAccessLevel = 'Edit';
insert  newAccTeamMember;    

Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
territory.Territory_Type__c = 'Service';
insert territory;

Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
orgSetting.Run_Validation_Rules__c = false;
update orgSetting;


Territory_Member__c territoryMember = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(salesRep.Id,territory.Id);
territoryMember.Start_Date__c = system.today();
insert territoryMember;

Order__c stockMovementOrderGroup = EDGE_UtilityTestClass.getStockMovementOrderGroup(salesRep.Id, shedAccount.Id);
insert stockMovementOrderGroup;
Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
insert deliveryPartner;

Product__c objProduct = EDGE_UtilityTestClass.getProd();
objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
objProduct.Supplier_Partner__c = deliveryPartner.Id;
objProduct.Pricing_Type__c = 'By Unit';
objProduct.Country__c =  countryId;
objProduct.Units_per_POS__c = 10.0;
objProduct.Diageo_Cost__c = 40;
objProduct.Outlet_Cost__c = 50;
objProduct.Start_Date__c = Date.Today();
objProduct.POS_Item_Short_Description__c = 'Good';
insert objProduct;

Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=countryId,Product__c=objProduct.Id);
insert testMAP;
Stock__c stock = EDGE_UtilityTestClass.getAllocationStock(countryId, objProduct.Id, salesRep.Id, territory.Id);
stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
stock.Original_Stock__c = 200;
stock.Allocated__c = 100;
stock.Consumed_Stock__c = 15;
insert stock;

System.debug('@@@'+limits.getQueries());
test.startTest();
System.runAs(salesRep){
Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
insert stockMovementOrder;


Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
orderItem.RecordTypeId = shedItemId;
orderItem.Type__c = 'Shed'; 
orderItem.Quantity__c = 1;
insert orderItem;

stockMovementOrder.Status__c = 'Submitted';    
update stockMovementOrder; 

}
System.debug('@@@'+limits.getQueries());
test.stopTest();
}
}*/
    
    @isTest
    public static void testShedQuantityForStockMovement(){
        //System.debug('Quantity Test Method '+'testShedQuantityForStockMovement');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'Added a User');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Business_Role__c = 'Test Business Role';
        insert salesRep; 
        System.assert(salesRep.Id!=null,'Added a User');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            
            insert shedAccount;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            insert objProduct;
            
            Stock__c stock = new Stock__c();
            String shedRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
            stock.Shed__c = shedAccount.Id;
            stock.RecordTypeId = shedRecordTypeId;
            stock.Country__c = countryId;
            stock.Product__c = objProduct.Id;
            stock.Original_Stock__c = 100;
            insert stock;
            
            //System.debug('@@@'+limits.getQueries());
            test.startTest(); 
            Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
            stockMovementOrder.Delivery_Partner__c = deliveryPartner.Id;
            insert stockMovementOrder;
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
            String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
            orderItem.RecordTypeId = shedItemId;
            orderItem.Stock__c= stock.Id;
            orderItem.Delivered_Quantity__c = 5;
            orderItem.Type__c = 'Shed'; 
            insert orderItem;
            
            stockMovementOrder.Status__c = 'Delivered to Shed';
            update stockMovementOrder;
            test.stopTest(); 
        }
    }
    
    // Method added by Manikant 
    // Purpose :
    @isTest
    public static void shedStockOperationTest(){
        //System.debug('Quantity Test Method '+'shedStockOperationTest');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId!=null,'Country is Added');          
        String stockAdjRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        String shedRecordTypeId = Order_item__C.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
        String shedStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            
            //Insert PickUp option record
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            //Insert shed Account record 
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert shedAccount;
            // Insert shed Adjustment Order
            Order__c stockAdjOrder = new Order__C();
            stockAdjOrder.RecordTypeId = stockAdjRecordTypeId;
            stockAdjOrder.Status__c = 'Draft';
            stockAdjOrder.Order_Type__c = 'Shed';
            stockAdjOrder.Source_Application__c = 'EDGE 365';
            stockAdjOrder.Account__c = shedAccount.id;
            stockAdjOrder.Sales_Representative__c = UserInfo.getUserId();        
            insert stockAdjOrder;
            // Insert Delivery partner
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            List<Product__c> prodList = new List<Product__c>();
            
            //Insert POS Product
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Country__c =  countryId;
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            prodList.add(objProduct);
            
            //Insert POS Product
            Product__c objProduct1 = EDGE_UtilityTestClass.getProd();
            objProduct1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct1.Supplier_Partner__c = deliveryPartner.Id;
            objProduct1.Pricing_Type__c = 'By Unit';
            objProduct1.Product_Full_Name__c = 'New Product1';
            objProduct1.Product_Code__c = 'Test1212';   
            objProduct1.Country__c =  countryId;
            objProduct1.Units_per_POS__c = 10.0;
            objProduct1.Diageo_Cost__c = 40;
            objProduct1.Outlet_Cost__c = 50;
            objProduct1.Start_Date__c = Date.Today();
            objProduct1.Unique_Key__c = '12ewrwew';
            objProduct1.Name = 'Hello Mani';
            objProduct1.UPIID__c = 'dddcdc';
            objProduct1.POS_Item_Short_Description__c = 'Very Bad';
            prodList.add(objProduct1);
            
            insert prodList;
            
            //System.debug('@@@'+limits.getQueries());
            test.startTest();
            
            // Insert shed type Order Item 
            Order_Item__c ordItemPosRec = new Order_Item__c();
            ordItemPosRec.RecordTypeId = shedRecordTypeId;
            ordItemPosRec.Product__c = objProduct.id;
            ordItemPosRec.Status__c = 'Submitted';
            ordItemPosRec.Quantity__c = 20;
            ordItemPosRec.Order__c = stockAdjOrder.id;
            insert ordItemPosRec;
            // Change the status of parent order
            stockAdjOrder.Status__c = 'Delivered to Shed';
            update stockAdjOrder;  
            
            // Insert shed stock
            Stock__c shedStock = new Stock__c();
            shedStock.recordTypeId =  shedStockRecordTypeId;
            shedStock.Country__c = countryId;
            shedStock.Product__c = objProduct1.id;
            shedStock.Shed__c = shedAccount.id;
            
            insert shedStock ;
            
            //Insert stock adjustmet order
            Order__c stockAdjOrder1 = new Order__C();
            stockAdjOrder1.RecordTypeId = stockAdjRecordTypeId;
            stockAdjOrder1.Status__c = 'Draft';
            stockAdjOrder1.Order_Type__c = 'Shed';
            stockAdjOrder1.Source_Application__c = 'EDGE 365';
            stockAdjOrder1.Account__c = shedAccount.id;
            stockAdjOrder1.Sales_Representative__c = UserInfo.getUserId();        
            insert stockAdjOrder1;        
            
            stockAdjOrder1.Status__c = 'Delivered to Shed';
            update stockAdjOrder1;
            //insert shed type order item
            Order_Item__c ordItemPosRec1 = new Order_Item__c();
            ordItemPosRec1.RecordTypeId = shedRecordTypeId;
            ordItemPosRec1.Product__c = objProduct1.id;
            ordItemPosRec1.Status__c = 'Submitted';
            ordItemPosRec1.Quantity__c = 20;
            ordItemPosRec1.Order__c = stockAdjOrder1.id;
            insert ordItemPosRec1;
            Test.stopTest();
        }
    }
    
    @isTest
    public static void testShedAndStockCreation(){
        //System.debug('Quantity Test Method '+'testShedAndStockCreation');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');  
        System.assert(countryId!=null,'Country is Added');
        String stockAdjRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Adjustment').getRecordTypeId();
        String shedRecordTypeId = Order_item__C.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
        String shedStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            
            //Insert PickUp option record
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            //Insert shed Account record 
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert shedAccount;
            
            Test.startTest();
            
            
            // Insert non pos product
            Product__c brandvariantproduct = new Product__c();
            brandvariantproduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
            brandvariantproduct.Name = 'Test Brand Variant';
            brandvariantproduct.Product_Full_Name__c = 'Test';
            insert brandvariantproduct ;
            
            // Insert Market assortment product record
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c();
            testMAP.Market_Assortment__c = countryId;
            testMAP.Product__c = brandvariantproduct.Id;
            insert testMAP;
            
            //Insert stock shed record 
            Stock__c shedStock1 = new Stock__c();
            shedStock1.recordTypeId =  shedStockRecordTypeId;
            shedStock1.Country__c = countryId;
            shedStock1.Market_Assortment_Product__c = testMAP.id;
            shedStock1.Shed__c = shedAccount.id;
            insert shedStock1 ;
            
            Order__c stockAdjOrder2 = new Order__C();
            stockAdjOrder2.RecordTypeId = stockAdjRecordTypeId;
            stockAdjOrder2.Status__c = 'Draft';
            stockAdjOrder2.Order_Type__c = 'Shed';
            stockAdjOrder2.Source_Application__c = 'EDGE 365';
            stockAdjOrder2.Account__c = shedAccount.id;
            stockAdjOrder2.Sales_Representative__c = UserInfo.getUserId();        
            insert stockAdjOrder2;
            
            
            //Insert order item record 
            Order_Item__c ordItemPosRec2 = new Order_Item__c();
            ordItemPosRec2.RecordTypeId = shedRecordTypeId;
            ordItemPosRec2.Product__c = brandvariantproduct.id;
            ordItemPosRec2.Status__c = 'Submitted';
            ordItemPosRec2.Quantity__c = 20;
            ordItemPosRec2.Order__c = stockAdjOrder2.id;
            insert ordItemPosRec2;
            
            stockAdjOrder2.Status__c = 'Delivered to Shed';
            update stockAdjOrder2;
            Test.stopTest();
            Map<Id, Map<Id, Decimal>>shedMrktProdAdjQtyMap = new Map<Id, Map<Id, Decimal>>();
            Map<Id,Id> shedSalesRepIdMap = new Map<Id,Id>();
            shedSalesRepIdMap.put(shedAccount.id,userInfo.getUserId());
            shedMrktProdAdjQtyMap.put(shedAccount.id,new Map<Id, Decimal> { brandvariantproduct.id => 10.0 });
            EDGE_OrderStockMovementTriggerHelper.checkShedStockForMarketAssortment(shedMrktProdAdjQtyMap, countryId, shedSalesRepIdMap);
        }
    }
    
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
    
    @isTest
    public static void testStockMovementOrdStatusUpdate(){
        //System.debug('Quantity Test Method '+'testStockMovementOrdStatusUpdate');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Business_Role__c = 'Test Business Role';
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        
        List<User> uList = new List<User>();
        uList.add(testAdminUser);
        uList.add(salesManager);
        uList.add(salesRep);
        insert uList;
        //System.debug('@@@'+limits.getQueries());
        System.assert(salesManager.Id!=null,'Added a User');
        System.assert(salesRep.Id!=null,'Added a User');
        
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            //System.debug('@@@'+limits.getQueries());
            //Territory hierarchy List insert
            string buRecType = 'Business Unit';
            string saRecType = 'Sales Area';
            string rRecType = 'Region';
            Territory_Hierarchy__c buHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
            buHierarchy.Name = 'Australia BU Territory Hierarchy';
            Insert buHierarchy;
            //System.debug('@@@'+limits.getQueries());
            
            Territory_Hierarchy__c saHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
            saHierarchy.Name = 'Australia Sales Area Territory Hierarchy';
            saHierarchy.Parent_BU__c = buHierarchy.id;
            Insert saHierarchy;
            //System.debug('@@@'+limits.getQueries());
            
            Territory_Hierarchy__c rHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, rRecType);
            rHierarchy.Name = 'Australia Region Territory Hierarchy';
            rHierarchy.Parent_BU__c = saHierarchy.id;
            Insert rHierarchy;
            //System.debug('@@@'+limits.getQueries());
            
            //String salesTerritoryRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
            //Territory insert
            Territory__c salesTerritory = EDGE_UtilityTestClass.getTerritoryRec();
            salesTerritory.Territory_Type__c = 'Sales';
            salesTerritory.Region__c =rHierarchy.Id;
            //salesTerritory.RecordTypeId = salesTerritoryRecordTypeId;
            insert salesTerritory;
            
            //System.debug('@@@'+limits.getQueries());
            
            
            //System.debug('@@@'+limits.getQueries());
            Org_Setting__c orgSetting = Org_Setting__c.getOrgDefaults();
            orgSetting.Run_Validation_Rules__c =false;
            update orgSetting;
            Territory_Member__c terrMember = new Territory_Member__c();
            terrMember.User__c = salesRep.Id ;
            terrMember.Type__c = 'Primary' ;
            terrMember.Territory__c  = salesTerritory.Id ;
            terrMember.Start_Date__c = system.today().AddDays(-1);
            insert terrMember;
            //System.debug('@@@'+limits.getQueries());
            
            Territory_Budget__c salesBudget = new Territory_Budget__c();
            Id freeGoodId = Schema.SObjectType.Territory_Budget__c.getRecordTypeInfosByName().get('Free Good').getRecordTypeId();
            salesBudget.Territory__c = salesTerritory.id;
            salesBudget.ECM_Territory_Hierarchy__c = rHierarchy.id;
            salesBudget.Start_Date__c = date.Today().adddays(-10);
            salesBudget.End_Date__c =date.Today().adddays(20);
            salesBudget.Initial_Amount__c = 1000;
            salesBudget.RecordTypeId=freeGoodId;
            Insert salesBudget;
            //System.debug('@@@'+limits.getQueries());
            
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            shedAccount.Primary_Sales_Territory__c=salesTerritory.id;
            insert shedAccount;
            //System.debug('@@@'+limits.getQueries());
            Test.startTest();
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            //System.debug('@@@'+limits.getQueries());
            
            Product__c objProduct = EDGE_UtilityTestClass.getProd();
            objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
            objProduct.Supplier_Partner__c = deliveryPartner.Id;
            objProduct.Pricing_Type__c = 'By Unit';
            objProduct.Units_per_POS__c = 10.0;
            objProduct.Diageo_Cost__c = 40;
            objProduct.Outlet_Cost__c = 50;
            objProduct.Start_Date__c = Date.Today();
            objProduct.POS_Item_Short_Description__c = 'Good';
            
            insert objProduct;
            //System.debug('@@@'+limits.getQueries());
            
            Stock__c stock = new Stock__c();
            String shedRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
            stock.Shed__c = shedAccount.Id;
            stock.RecordTypeId = shedRecordTypeId;
            stock.Country__c = countryId;
            stock.Product__c = objProduct.Id;
            stock.Original_Stock__c = 100;
            insert stock;
            //System.debug('@@@'+limits.getQueries());
            
            Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
            stockMovementOrder.Delivery_Partner__c = deliveryPartner.Id;
            insert stockMovementOrder;
            //System.debug('@@@'+limits.getQueries());
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, stockMovementOrder.Id);
            String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
            orderItem.RecordTypeId = shedItemId;
            orderItem.Stock__c= stock.Id;
            orderItem.Delivered_Quantity__c = 5;
            orderItem.Type__c = 'Shed'; 
            insert orderItem;
            //System.debug('@@@'+limits.getQueries());
            
            stockMovementOrder.Status__c = 'Submitted';
            update stockMovementOrder;
            //System.debug('@@@'+limits.getQueries());
            test.stopTest(); 
            //System.debug('@@@'+limits.getQueries());
        }
    }
    
    @isTest
    public static void testShedAndStockCreationForStockMovement(){
        //System.debug('Quantity Test Method '+'testShedAndStockCreationForStockMovement');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(countryId!=null,'Country is Added');         
        String stockMvtRecordTypeId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Stock Movement').getRecordTypeId();
        String shedRecordTypeId = Order_item__C.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
        String shedStockRecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed').getRecordTypeId();
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            //Insert PickUp option record
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            //Insert shed Account record 
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert shedAccount;
            
            Test.startTest();
            
            
            // Insert non pos product
            Product__c brandvariantproduct = new Product__c();
            brandvariantproduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
            brandvariantproduct.Name = 'Test Brand Variant';
            brandvariantproduct.Product_Full_Name__c = 'Test';
            insert brandvariantproduct ;
            
            // Insert Market assortment product record
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c();
            testMAP.Market_Assortment__c = countryId;
            testMAP.Product__c = brandvariantproduct.Id;
            insert testMAP;
            
            //Insert stock shed record 
            Stock__c shedStock1 = new Stock__c();
            shedStock1.recordTypeId =  shedStockRecordTypeId;
            shedStock1.Country__c = countryId;
            shedStock1.Market_Assortment_Product__c = testMAP.id;
            shedStock1.Shed__c = shedAccount.id;
            insert shedStock1 ;
            
            Order__c stockMvtOrder2 = new Order__C();
            stockMvtOrder2.RecordTypeId = stockMvtRecordTypeId;
            stockMvtOrder2.Status__c = 'Draft';
            stockMvtOrder2.Order_Type__c = 'Shed';
            stockMvtOrder2.Source_Application__c = 'EDGE 365';
            stockMvtOrder2.Account__c = shedAccount.id;
            stockMvtOrder2.Sales_Representative__c = UserInfo.getUserId();        
            insert stockMvtOrder2;
            
            
            //Insert order item record 
            Order_Item__c ordItemPosRec2 = new Order_Item__c();
            ordItemPosRec2.RecordTypeId = shedRecordTypeId;
            ordItemPosRec2.Product__c = brandvariantproduct.id;
            ordItemPosRec2.Status__c = 'Submitted';
            ordItemPosRec2.Quantity__c = 20;
            
            
            ordItemPosRec2.Delivered_Quantity__c = 15;
            
            
            ordItemPosRec2.Order__c = stockMvtOrder2.id;
            insert ordItemPosRec2;
            
            stockMvtOrder2.Status__c = 'Delivered to Shed';
            update stockMvtOrder2;
            Test.stopTest();
            Map<Id, Map<Id, Decimal>>shedMrktProdMvtQtyMap = new Map<Id, Map<Id, Decimal>>();
            Map<Id,Id> shedSalesRepIdMap = new Map<Id,Id>();
            shedSalesRepIdMap.put(shedAccount.id,userInfo.getUserId());
            shedMrktProdMvtQtyMap.put(shedAccount.id,new Map<Id, Decimal> { brandvariantproduct.id => 10.0 });
            EDGE_OrderStockMovementTriggerHelper.checkShedStockForMarketAssortment(shedMrktProdMvtQtyMap, countryId, shedSalesRepIdMap);
        }
    }
    
    
    
    
    @isTest
    public static void testDBSCMail(){
        //System.debug('Quantity Test Method '+'testDBSCMail');
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU'); 
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'Added a User');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Business_Role__c = 'Test Business Role';
        insert salesRep; 
        System.assert(salesRep.Id!=null,'Added a User');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[AU]';
            insert pickupOption;
            
            //Territory hierarchy List insert
            string buRecType = 'Business Unit';
            string saRecType = 'Sales Area';
            string rRecType = 'Region';
            Territory_Hierarchy__c buHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
            buHierarchy.Name = 'Australia BU Territory Hierarchy';
            Insert buHierarchy;
            Territory_Hierarchy__c saHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
            saHierarchy.Name = 'Australia Sales Area Territory Hierarchy';
            saHierarchy.Parent_BU__c = buHierarchy.id;
            Insert saHierarchy;
            Territory_Hierarchy__c rHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, rRecType);
            rHierarchy.Name = 'Australia Region Territory Hierarchy';
            rHierarchy.Parent_BU__c = saHierarchy.id;
            Insert rHierarchy;
            
            //String salesTerritoryRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
            //Territory insert
            Territory__c salesTerritory = EDGE_UtilityTestClass.getTerritoryRec();
            salesTerritory.Territory_Type__c = 'Sales';
            salesTerritory.Region__c =rHierarchy.Id;
            //salesTerritory.RecordTypeId = salesTerritoryRecordTypeId;
            insert salesTerritory;
            
            Test.startTest();
            
            Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
            orgSetting.Run_Validation_Rules__c = false;
            update orgSetting;
            
            Territory_Member__c terrMember = new Territory_Member__c();
            terrMember.User__c = salesRep.Id ;
            terrMember.Type__c = 'Primary' ;
            terrMember.Territory__c  = salesTerritory.Id ;
            terrMember.Start_Date__c = system.today().AddDays(-1);
            insert terrMember;
            
            Territory_Budget__c salesBudget = new Territory_Budget__c();
            Id freeGoodId = Schema.SObjectType.Territory_Budget__c.getRecordTypeInfosByName().get('Free Good').getRecordTypeId();
            salesBudget.Territory__c = salesTerritory.id;
            salesBudget.ECM_Territory_Hierarchy__c = rHierarchy.id;
            salesBudget.Start_Date__c = date.Today().adddays(-10);
            salesBudget.End_Date__c =date.Today().adddays(20);
            salesBudget.Initial_Amount__c = 1000;
            salesBudget.RecordTypeId=freeGoodId;
            Insert salesBudget;
            
            Account shedAccount = EDGE_UtilityTestClass.getShedRecord();
            shedAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            shedAccount.Primary_Sales_Territory__c=salesTerritory.id;
            insert shedAccount;
            
            Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
            deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
            insert deliveryPartner;
            
            
            Product__c brandvariantproduct = new Product__c();
            brandvariantproduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
            brandvariantproduct.Name = 'Test Brand Variant';
            brandvariantproduct.Product_Full_Name__c = 'Test';
            insert brandvariantproduct ;
            
            Order__c stockMovementOrder = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shedAccount.Id);
            stockMovementOrder.Delivery_Partner__c = deliveryPartner.Id;
            insert stockMovementOrder;
            
            Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(brandvariantproduct.Id, stockMovementOrder.Id);
            String shedItemId = Order_Item__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Shed Item').getRecordTypeId();
            orderItem.RecordTypeId = shedItemId;
            orderItem.Delivered_Quantity__c = 5;
            orderItem.Type__c = 'Shed'; 
            orderItem.product__c = brandvariantproduct.Id;
            insert orderItem;
            
            stockMovementOrder.Status__c = 'Submitted';
            update stockMovementOrder;
            test.stopTest();   
        }
    }
    
    
    
    
    
    
    public static Geography__c createGeo(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
}