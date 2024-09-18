/*
* @Name: EDGE_OrderStatusUpdateBatchTest
* @Req: This is the test class for EDGE_OrderStatusUpdateBatch
* @History                                                            
                                                            
* VERSION       AUTHOR                  DATE              DETAIL
* 1.0           Anuja Chattopadhyay     11/07/2019      Initial Development
* 2.0			  Swaraj Samanta		  12/05/2022		ES20-12606- later it got cancelled so commenting the code
* 3.0           Shameer Shaik           16/06/2022        ES20-12722
* 4.0			Rajarshi Lahiri	  		22/06/2022	      Added test data for ES20-12606
* 5.0.          Wribhu Bose             09/11/2022      Added test data for ES20-13023
* 6.0           Joshraj Sen             08/04/2024      152305 SCA Fix
*/
@isTest
public class EDGE_OrderStatusUpdateBatchTest {
    public static List<Account> accntLst = new List<Account>();
    public static List<Order__C> ordList=new List<Order__c> (); 
    @isTest
    public static void testOrderStatusUpdateBatch(){
        
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OrderStatusUpdateBatch'
                                                  and Country_Code__c ='AU' ];
        System.assert(batchSetting!=null,'Batch is Added');

        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
    }
    
    public static void createData(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.A_P_Threshold__c = 100;
        market.Language__c = 'en_US';
        market.Attachment_Format__c = 'CSV';
        insert market;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager; 
        System.assert(salesManager.Id!=null,'Sales Manager is Added');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales rep is added');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Pending_For_Batch__c = true;
        insert terriHier;
        system.assert(terriHier.Id != null,'Region is Added'); 
        
        Territory__c territory = new Territory__c();
        territory.Name = 'TAS BDM NORTH';
        territory.Status__c = 'Active';
        territory.Country__c = countryId;
        territory.Territory_Type__c = 'Sales';
        territory.Region__c = terriHier.Id;
        insert territory;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Country__c = countryId;
        outlet.BillingState = 'Tasmania';
        outlet.ShippingCountry = 'Australia';
        outlet.ShippingState = 'Tasmania';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Primary_Sales_Territory__c = territory.Id;
        outlet.Legacy_Front_Office_Account_No__c='1234';
        outlet.SAP_Ship_To__c='123456';
        accntLst.add(outlet);
        
        Account shed = EDGE_UtilityTestClass.getShedRecord();
        shed.ShippingCountry = 'Australia';
        shed.Name = 'Test Shed1';
        accntLst.add(shed);
        
        insert accntLst;
        test.startTest();
        System.debug(LoggingLevel.Debug,'accntLst'+accntLst);
        Contact usrcnt = new Contact();
        usrcnt.FirstName = 'Test';
        usrcnt.LastName = 'Test';
        usrcnt.Email = 'test1222@test.com';
        usrcnt.PhonePrefix__c = '+44';
        usrcnt.Phone__c = '1234567890';
        usrcnt.AccountId = outlet.id;
        insert usrcnt;
        
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        insert objContract;
        
        Order__c posOrderGroup = EDGE_UtilityTestClass.getPOSOrderGroup(salesRep.Id, outlet.Id, objContract.Id);
        posOrderGroup.Status__c = 'Ready for Order';
        insert posOrderGroup;
        
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        deliveryPartner.RecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        deliveryPartner.Batch_Notification__c = True;
        insert deliveryPartner;
        
        ContactPointAddress conPointAdd=new ContactPointAddress();
        conPointAdd.Name='Test';
        conPointAdd.Country='Australia';
        conPointAdd.City='Brisbane';
        conPointAdd.Street='Test Street';
        conPointAdd.State='New South Wales';
        conPointAdd.PostalCode='123456';
        conPointAdd.Source__c='EDGE 365';
        insert conPointAdd;
        
        Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
        posOrder.Order_Group__c = posOrderGroup.Id;        
        posOrder.Status__c = 'Ready for Order';
        posOrder.Delivery_Partner__c = deliveryPartner.Id;
        posOrder.Contact__c = usrcnt.id;
        ordList.add(posOrder);
                
        Order__c posOrder1 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
        posOrder1.Order_Group__c = posOrderGroup.Id;        
        posOrder1.Status__c = 'Ready for Order';
        posOrder1.Delivery_Partner__c = deliveryPartner.Id;
        posOrder1.Delivery_Location__c = 'shed';
        posOrder1.Contact__c = usrcnt.id;
         ordList.add(posOrder1);
		Order__c posOrder2 = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shed.Id);
        posOrder2.Status__c = 'Ready for Order';
        posOrder2.Source_Application__c='EDGE 365';
        posOrder2.Delivery_Partner__c = deliveryPartner.Id;
        posOrder2.Delivery_Location__c ='Sales Rep';
        posOrder2.Contact__c = usrcnt.id;
        ordList.add(posOrder2);
        Order__c posOrder3 = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
        posOrder3.Order_Group__c = posOrderGroup.Id;        
        posOrder3.Status__c = 'Ready for Order';
        posOrder3.Alternate_Delivery_Address__c=conPointAdd.Id;
        posOrder3.Delivery_Partner__c = deliveryPartner.Id;
        posOrder3.Delivery_Location__c = 'Other';
        posOrder3.Contact__c = usrcnt.id;
        ordList.add(posOrder3);
        //ES20-13023 - start
        Order__c posOrder4 = EDGE_UtilityTestClass.getStockMovementOrder(salesRep.Id, shed.Id);
        posOrder4.Status__c = 'Ready for Order';
        posOrder4.Source_Application__c='EDGE 365';
        posOrder4.Delivery_Partner__c = deliveryPartner.Id;
        posOrder4.Delivery_Location__c ='Sales Rep';
        posOrder4.Contact__c = usrcnt.id;
        posOrder4.Parent_Order__c = posOrder2.Id;
        ordList.add(posOrder4);
        //ES20-13023 - end
        insert ordList;
        
        Set<Id> ordersetid = new Set<Id>();
        ordersetid.add(posOrder.Id);
        ordersetid.add(posOrder1.Id);
        ordersetid.add(posOrder2.Id);
        
        EDGE_POSStockMvmtEmailHelper.getOrderList(ordersetid,true,deliveryPartner.Id);
              
        system.debug(LoggingLevel.Debug,'deliveryPartner' +deliveryPartner);
        system.debug(LoggingLevel.Debug,'posOrder '+posOrder);
        system.debug(LoggingLevel.Debug,'posOrder1 '+posOrder1);
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        objProduct.Start_Date__c = system.today();
        
        insert objProduct;
        
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.Product__c = objProduct.id;
        orderItem.Order__c = posOrder.id;
        orderItem.Quantity__c = 1500 ;
        orderItem.Type__c = 'Warehouse' ;
        orderItem.GUID__c = 'abs6353';
        insert orderItem;
        System.assert( orderItem.id != null,'Order Item is Added');
        
        ContentVersion conVerRecPDF1 = EDGE_UtilityTestClass.gerConVerRec('Product12345.JPEG');
        conVerRecPDF1.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Order Product').getRecordTypeId();
        conVerRecPDF1.Content_Type__c = 'Order Product Image';
        conVerRecPDF1.Title = 'OutletRes.pdf';
        insert conVerRecPDF1;
        
        ContentVersion testContent = [SELECT id, ContentDocumentId FROM ContentVersion where Id = :conVerRecPDF1.Id];
        
        ContentDocumentLink contentlink=new ContentDocumentLink();
        contentlink.LinkedEntityId= orderItem.id;
        contentlink.ShareType= 'V';
        contentlink.ContentDocumentId=testcontent.ContentDocumentId;
        contentlink.Visibility = 'AllUsers';
        insert contentlink;
        
        List<Order__c> ord1 = new List<Order__c>();
        List<Order_Item__c> ordItem1 = new List<Order_Item__c>();
        Map< String, List<Order_Item__c>> mapofLineitem = new Map< String, List<Order_Item__c>>();
        ord1.add(posOrder);
        ordItem1.add(orderItem);
        mapofLineitem.put(posOrder.Id, ordItem1); 
        Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(new List<String>{'EDGE_ClientCode', 'EDGE_OutletID','EDGE_OutletName','EDGE_SalesRepName','EDGE_SalesRepMobile','EDGE_SalesRepEmail','EDGE_ToDelivery',
            'EDGE_Address','EDGE_City','EDGE_State','EDGE_PostalCode','EDGE_Country','EDGE_OrderNumber','EDGE_ProductCode','EDGE_Quantity','EDGE_Notes',
            'EDGE_TextToPrint','EDGE_Size','EDGE_Gender','EDGE_Colour','EDGE_PaperFinish','EDGE_DeliveryStartDate','EDGE_DeliveryEndDate'}, 'en_US');
        EDGE_UtilityClass.getTableBody(ord1,mapofLineitem,'en_US',labelToTranslatedStrMap);
 
         test.stopTest();
    }
    
    @isTest
    public static void testOrderStatusUpdateBatch1(){
        
        createData1();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OrderStatusUpdateBatch'
                                                  and Country_Code__c ='AU' ];
        System.assert(batchSetting!=null,'Batch is Added');
        
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        
    }
     
    
     @isTest
    public static void createData1(){
        
        createData();
        Market_Setting__c mktSetting =[SELECT Id,Name,Attachment_Format__c from Market_Setting__c where Name='Market Setting' LIMIT 1];
        mktSetting.Threshold_Format__c='Percent';
        mktSetting.A_P_Threshold__c = 100;
        mktSetting.Language__c = 'en_US';
        mktSetting.Attachment_Format__c = 'Excel';
        update mktSetting;
        System.assert(mktSetting!=null,'Market Setting is Added');
    }
    
}