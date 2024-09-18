/*
* @Name: EDGE_OrderItemCompliantBatchTest
* @Req: This is the test class for EDGE_OrderItemCompliantBatch
* @History                                                            

* VERSION       AUTHOR                  DATE              DETAIL
* 1.0		    Swaraj Samanta		  10/11/2022 		ES20-12600
*/
@isTest
public class EDGE_OrderItemComplaintBatchTest {
    @testSetup
    static void setup() {
        //Map<String, List<Call__c>> callUniqueIdMap = new Map<String, List<Call__c>>();
        //Map<Id, Call__c> callMapToUpdate = new Map<Id, Call__c>();
        //Set<String> uniqueIdSet=new Set<String>();
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Southern Europe';
        hub.Code__c = 'SEH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Spain';
        cluster.Code__c = 'SPC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Spain';
        country.Code__c ='ES';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Spain Canaries';
        area.Code__c = 'ESC';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'CANARIAS';
        region.Code__c = 'ES1';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        Id userKPIRecordTypeId;
        userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        List<Pick_Up_Options__c> pickUpOptions=new List<Pick_Up_Options__c>();
        Map<String,Schema.RecordTypeInfo> pickUpRtMapByDevName = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOptions.add(pickupOption);
        Id outletPrioritizationRt = pickUpRtMapByDevName.get('Outlet_Prioritization').getRecordTypeId();
        Pick_Up_Options__c outPrior = new Pick_Up_Options__c(RecordTypeId=outletPrioritizationRt,Name='TEST [TS]',Geography__c=market.Id,Type__c='Outlet Visit Prioritization',Status__c='Active');
        pickUpOptions.add(outPrior);
        insert pickUpOptions;
        
        //Insert Test Market Setting record
        Market_Setting__c ms = new Market_Setting__c(Name='Test Market Setting',Geography__c=countryId,Default_Outlet_Visit_Prioritisation__c=outPrior.Id);
        insert ms;
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        terriHierBU.Geography__c=geoMap.get('Country');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        terriHierSA.Geography__c=geoMap.get('Country');
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Geography__c=geoMap.get('Country');
        insert terriHier;
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Region__c =terriHier.Id;
        territory.Country__c=geoMap.get('Country');
        insert territory;
        
        List<Account> outlets=new List<Account>();
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        outlet.Status__c='Active';
        outlets.add(outlet);
        Account outlet1 =EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Name='Tes juan classs';
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet1.Country__c = geoMap.get('Country');
        outlet1.Hub__c = geoMap.get('Hub');
        outlet1.Region__c=geoMap.get('Region');
        outlet1.Area__c=geoMap.get('Area');
        outlet1.Market__c = geoMap.get('Market');
        outlet1.Cluster__c= geoMap.get('Cluster');
        outlet1.Status__c='Active';
        outlets.add(outlet1);
        insert outlets;
        List<Outlet_Territory__c> ots=new List<Outlet_Territory__c>();
        Outlet_Territory__c  outletTerritory3  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        outletTerritory3.Active__c = 'Active';
        ots.add(outletTerritory3);
        Outlet_Territory__c  outletTerritory4  =  EDGE_UtilityTestClass.getOutltTerritory(outlet1.Id, territory.Id);
        outletTerritory4.Active__c = 'Active';
        ots.add(outletTerritory4);
        insert ots;
        User srep = EDGE_UtilityTestClass.runAsUser('Sales Rep','Sales Representative');
        srep.Available_Countries__c = 'ES';
        srep.Email='sales.rep@testemail.com';
        srep.Username='sales.rep@testemail.com';
        insert srep;   
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.Delivery_Partner_Email_For_Complaints__c='delivery.partner@testemail.com';
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
        Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, objProduct.Id, srep.Id);
        stock.RecordTypeId = Stock__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stock.State__c = geoMap.get('State');
        insert stock;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        List<Order__c> orders=new List<Order__c>();
        Order__c posOrder2 = EDGE_UtilityTestClass.getPOSOrder(srep.Id, outlet.Id, objContract.Id);
        posOrder2.Total_A_P_Cost__c = 20;
        posOrder2.Status__c = 'Approval In Progress';
        posOrder2.Delivery_Partner__c=deliveryPartner.Id;
        orders.add(posOrder2);
        Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(srep.Id, outlet.Id, objContract.Id);
        posOrder3.Total_A_P_Cost__c = 20;
        posOrder3.Status__c = 'Approval In Progress';
        posOrder3.Delivery_Partner__c=deliveryPartner.Id;
        orders.add(posOrder3);
        Order__c posOrder4 = EDGE_UtilityTestClass.getPOSOrder(srep.Id, outlet1.Id, objContract.Id);
        posOrder4.Total_A_P_Cost__c = 20;
        posOrder4.Status__c = 'Approval In Progress';
        posOrder4.Delivery_Partner__c=deliveryPartner.Id;
        orders.add(posOrder4);
        Order__c posOrder5 = EDGE_UtilityTestClass.getPOSOrder(srep.Id, outlet1.Id, objContract.Id);
        posOrder5.Total_A_P_Cost__c = 20;
        posOrder5.Status__c = 'Approval In Progress';
        posOrder5.Delivery_Partner__c=deliveryPartner.Id;
        orders.add(posOrder5);
        insert orders;
        List<Order_Item__c> orderItems=new List<Order_Item__c>();
        Order_Item__c orderItem = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder2.Id);
        orderItem.Status__c='Item Missing';
        orderItems.add(orderItem);
        Order_Item__c orderItem1 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder2.Id);
        orderItem1.Status__c='Item Missing';
        orderItems.add(orderItem1);
        Order_Item__c orderItem2 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder3.Id);
        orderItem2.Status__c='Item Missing';
        orderItems.add(orderItem2);
        Order_Item__c orderItem3 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder3.Id);
        orderItem3.Status__c='Item Missing';
        orderItems.add(orderItem3);
        Order_Item__c orderItem4 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder4.Id);
        orderItem4.Status__c='Item Missing';
        orderItems.add(orderItem4);
        Order_Item__c orderItem5 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder4.Id);
        orderItem5.Status__c='Item Missing';
        orderItems.add(orderItem5);
        Order_Item__c orderItem7 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder5.Id);
        orderItem7.Status__c='Item Missing';
        orderItems.add(orderItem7);
        Order_Item__c orderItem6 = EDGE_UtilityTestClass.getOrderItem(objProduct.Id, posOrder5.Id);
        orderItem6.Status__c='Item Missing';
        orderItems.add(orderItem6);
        insert orderItems;
        Territory_Member__c terrMember=new Territory_Member__c();
        terrMember.User__c=srep.Id;
        terrMember.Territory__c=territory.Id;
        terrMember.Type__c='Primary';
        terrMember.Start_Date__c=System.today().addDays(10);
        insert terrMember;
        
        
        
        
        
        
    }
    @isTest 
    static void testOrderItemComplaintBatch(){
        
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OrderItemComplaintBatch'
                                                  and Country_Code__c ='ES' Limit 1];
        system.assert(batchSetting.Id != null,'batchSetting Id should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
        Test.stopTest();      
    }
    @isTest 
    static void testOrderItemComplaintBatch2() {
        
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OrderItemComplaintBatch'
                                                  and Country_Code__c ='ES' Limit 1];
        system.assert(batchSetting.Id != null,'batch Setting Id should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        List<Market_Setting__c> ms=[Select Id,language__c from Market_Setting__c limit 1];
        ms[0].Language__c='en_US';
        update ms;
        Test.startTest();
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();      
    }
    
}