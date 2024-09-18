/**********************************************************************
Name: EDGE_OrderFreeGoodsTmpControllerTest
=======================================================================
Req: This is the test class for EDGE_CallNotesController class.
User Story : ES20-623
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
   1.0    Sandip Ghosh     06/02/2020      Initial Development
   1.1    Prasanth T       23/09/2022      Test Class Correction Due to Failure(ES20-13324)      
***********************************************************************/
@isTest
public class EDGE_OrderFreeGoodsTmpControllerTest {
	
    public static Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    public static Id outletpriorRecTypeId = mapPickupoptionRecordTypes.get('Outlet Prioritization').getRecordTypeId();
    public static Id freeGoodsRecTypeId = mapPickupoptionRecordTypes.get('Free Goods Reason Codes').getRecordTypeId();
    
    /*******************************************************************
    Purpose: Creates all the required test data                                                        
    ********************************************************************/
    @istest
    public static void createData(){  
        
        List<Pick_Up_Options__c> pickUpOptions =new List<Pick_Up_Options__c>();
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');      
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.RecordTypeId = outletpriorRecTypeId;
        pickupOption.Name = 'Gold[AUT]';
        pickUpOptions.add(pickupOption);
        Pick_Up_Options__c pickupOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Reason Code');
        pickupOption1.RecordTypeId = freeGoodsRecTypeId;
        pickupOption1.Name = 'Gold1[AUT]';
        pickUpOptions.add(pickupOption1);
        insert pickUpOptions;
        List<Account> accounts=new List<Account>();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        outlet.Start_Date__c = Date.today();
        accounts.add(outlet);        
        Account wholesaler = EDGE_UtilityTestClass.getDistriAccRec();
        accounts.add(wholesaler);
        insert accounts;
        Test.startTest();
        Delivery_Partner__c delPart = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert delPart;
       
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null,'sales Manager Id should not be null');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null,'sales Rep Id should not be null');
        String freeGoodsOrderId = Order__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Goods').getRecordTypeId();
        
        Order__c freeGoodsOrder = new Order__c();
        freeGoodsOrder.RecordTypeId = freeGoodsOrderId;
        freeGoodsOrder.Account__c = outlet.Id;
        freeGoodsOrder.Wholesaler__c =wholesaler.id;
        //freeGoodsOrder.ReasonCode_pickup__c = pickupOption1.id;
        freeGoodsOrder.Status__c = 'Ready For Order';
        freeGoodsOrder.Sales_Representative__c = salesRep.Id;
        freeGoodsOrder.Preferred_Delivery_Date__c = Date.today();
        freeGoodsOrder.Delivery_instructions__c= 'Careful';
        insert freeGoodsOrder;
        
        EDGE_OrderFreeGoodsTmpController ordFreeGoodsTmpCntrler = new EDGE_OrderFreeGoodsTmpController();
        ordFreeGoodsTmpCntrler.recordId = freeGoodsOrder.Id;
        ordFreeGoodsTmpCntrler.getOrderItems();
    }
    
    
}