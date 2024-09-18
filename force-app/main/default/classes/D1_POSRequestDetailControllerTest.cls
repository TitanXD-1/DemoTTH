@isTest
public class D1_POSRequestDetailControllerTest
{
    
    @isTest
    public static void testgetOrderItems()
    {
        Id countryId = D1_TestDataUtility.setupCountry('ES');
        Geography__c country = new Geography__c(Id= countryId);
        country.isDiageoOneEnabled__c	= True;
        upsert country;  
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'ES';
        insert salesManager;  
        System.assert(salesManager.Id!=null, 'sales manager not found');
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'ES';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        System.assert(salesRep.Id!=null, 'sales representative not found');
        
        Account outlet = D1_TestDataUtility.getD1Customer();
        outlet.D1_EDGE_Customer__c =true;
        insert outlet;
        
        Account shed = EDGE_UtilityTestClass.getShedRecord();
        insert shed;
        
        
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
        
        Product__c objProduct = EDGE_UtilityTestClass.getProd();
        objProduct.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        objProduct.Supplier_Partner__c = deliveryPartner.Id;
        objProduct.Start_Date__c = system.today();
        
        insert objProduct;
        
        Order__c posOrder = EDGE_UtilityTestClass.getPOSOrder(salesRep.Id, outlet.Id, objContract.Id);
        posOrder.Order_Group__c = posOrderGroup.Id;        
        posOrder.Status__c = 'Ready for Order';
        posOrder.Delivery_Partner__c = deliveryPartner.Id;
        insert posOrder;
        
        Order_Item__c orderItem = new Order_Item__c();
        orderItem.Product__c = objProduct.id;
        orderItem.Order__c = posOrder.id;
        orderItem.Quantity__c = 1500 ;
        orderItem.Type__c = 'Warehouse' ;
        orderItem.GUID__c = 'abs6353';
        insert orderItem;
        System.assert( orderItem.id != null, 'order item not found');
        
        List<Order_Item__c> testresp = new List<Order_Item__c>();
        testresp = D1_POSRequestDetailController.getOrderItems(posOrder.id);
        //  User testAdminUser ;
        User testAdminUser ;
        User thisUser =  [ select Id from User where Id = :UserInfo.getUserId() ];
        
        
        D1_User_Type__c d1UserType;
        D1_Setting__c d1setting;
        Pick_Up_Options__c pickupOption ;
        
        System.runAs(thisUser){            
            UserRole ur   =     [Select Id From UserRole Where Name = 'Global' Limit 1];
            testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');        
            testAdminUser.userRoleId = ur.id;
            testAdminUser.Available_Countries__c='ES';
            testAdminUser.LanguageLocaleKey='es';
            insert testAdminUser;  
            
            pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[ES]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            
            d1setting = new D1_Setting__c();
            d1setting.Name = 'ES setting';
            d1setting.Unique_ID__c = 'test ES';
            d1setting.Language__c = 'es';
            d1setting.Market__c = country.id;
            insert d1setting;
            
            d1UserType = new D1_User_Type__c();
            d1UserType.Name = 'Outlet Owner';
            d1UserType.D1_Setting__c = d1setting.Id;
            d1UserType.User_Type__c = D1_User_Type__c.User_Type__c.getDescribe().getPicklistValues()[0].getValue();
            insert d1UserType;            
        }   
        
        System.runAs(testAdminUser){
            
            D1_POSRequestDetailController.getD1Setting();
        }     
    }
}