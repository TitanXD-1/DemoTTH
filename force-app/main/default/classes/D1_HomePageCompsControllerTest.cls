/**
* @Name: D1_HomePageCompsControllerTest
* Purpose: Test class for D1_HomePageCompsControllerTest
* History                                                                                                                      
* VERSION	AUTHOR            		DATE            DETAIL
* 1.0		
**/
@isTest
public class D1_HomePageCompsControllerTest {
    /**
    * @Name : testHomePageMethod
	* @description : This method is used to test the getSalesOrders()
	*/
    // See ALl data is required because we are calling here connectApi method 
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @IsTest(seeAllData = true)
    public static void testHomePageMethod(){
        createData();
        //Test.startTest();
        D1_HomePageCompsController.SalesOrdertWrapper salesOrdrWrp = new D1_HomePageCompsController.SalesOrdertWrapper();                    
            User externalUsr = [SELECT Id FROM User WHERE Email='testclassextuser1@testdomain.com' LIMIT 1];
            System.runAs(externalUsr){
                salesOrdrWrp = D1_HomePageCompsController.getSalesOrders();
            }
       // Test.stopTest();
        System.Assert(salesOrdrWrp != NULL, 'FAILED');
        Assert.isTrue(salesOrdrWrp != NULL, 'FAILED');
    }
    /**
    * @name : createData
    * @description : This method is used to create test data
    */
    public static void createData(){
        /*Setup Country : To handle validation error against multiple 'Global' Geography records when opening up access to org data in test class*/
        
        List<Geography__c> geoList = new List<Geography__c>();
        Id countryId;
        Boolean isOrgData = true;
        
        geoList = [SELECT Id FROM Geography__c WHERE Code__c = 'GB' AND RecordType.Name = 'Country'];
        if(geoList.isEmpty()){
            countryId = D1_TestDataUtility.setupCountry('GB');
            isOrgData = false;
        }
        else{
            countryId = geoList[0].Id;
        }     
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id =: countryId];
        
        //Setup D1 Settings
        D1_Setting__c d1Setting = D1_TestDataUtility.createD1Settings(country);
        d1Setting.Language__c = 'es';
        insert d1Setting;      
        
        Test.startTest();
        //Setup Visit Prioritization
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','TestGold[GB]');
        insert pickupOption;
        
        //Setup Outlet
        Account testoutlet = D1_TestDataUtility.getDirectCustomer();
        if(isOrgData){
            Geography__c hub = [SELECT Id FROM Geography__c WHERE RecordType.name = 'Hub' and name ='Great Britain' limit 1];
            Geography__c region = [SELECT Id FROM Geography__c WHERE RecordType.name='Region'and name ='London' limit 1];
            Geography__c area = [SELECT Id FROM Geography__c WHERE RecordType.name='Area' and name ='Great Britain' limit 1];
            Geography__c market = [SELECT Id FROM Geography__c WHERE RecordType.name='Market' and name ='Europe and Turkey' limit 1];
            Geography__c cluster = [SELECT Id FROM Geography__c WHERE RecordType.name='Cluster' and name ='Great Britain' limit 1];
            testoutlet.Country__c = countryId;
            testoutlet.Hub__c = hub.Id;
            testoutlet.Region__c = region.Id;
            testoutlet.Area__c = area.Id;
            testoutlet.Market__c = market.Id;
            testoutlet.Cluster__c = cluster.Id;
        }
        testoutlet.D1_EDGE_Customer__c = true;
        testoutlet.Name = 'testcart Outlet';
        testoutlet.Salesforce_Delivery_Days_Packaged_Good__c = '1;2;3;4;5;6;7';
        testoutlet.Salesforce_Delivery_Days_Keg__c = '1;2;3;4;5;6;7';
        testoutlet.Delivery_Pattern__c = '0';
        testoutlet.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id;
        testoutlet.KUNNR__c ='970361';
        insert testoutlet;
        
        //Setup Primary Contact
        Contact primaryContact = D1_TestDataUtility.getContact(testOutlet.Id, 'Primary');
        insert primaryContact;
        
        //Setup Account-Contact Relationship
        List<AccountContactRelation> relations = [SELECT id,D1_Active__c FROM AccountContactRelation WHERE ContactId =: primaryContact.Id LIMIT 1];
        for(AccountContactRelation acr: relations){
            acr.D1_Active__c = true;
        }
        update relations;
        
        //Setup D1 User Type
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType('Outlet Owner', 'Direct Buyer', d1Setting.Id);
        insert d1UserType;
        
        //Set Up Contact Point Address
        ContactPointAddress cpaRec = new ContactPointAddress(Name = 'Test Outlet', Source__c = 'Diageo One');
        cpaRec.parentId = testoutlet.Id;
        cpaRec.AddressType = 'Shipping';
        cpaRec.Account_Number__c ='970361';
        insert cpaRec;
        
        //Setup External User
        User externalUser1 = D1_TestDataUtility.runAsUser('extuser1','DiageoOne External User');
        externalUser1.Username = 'testclassextuser1@testdomain.com';
        externalUser1.Email='testclassextuser1@testdomain.com';
        externalUser1.CommunityNickname = 'Mania.Test1';
        externalUser1.Available_Countries__c = 'GB';
        externalUser1.ContactId = primaryContact.Id;
        externalUser1.Effective_Account_Id__c = testOutlet.Id;
        externalUser1.isActive = true;
        externalUser1.D1_User_Type_Id__c = d1UserType.Id;
        externalUser1.LanguageLocaleKey ='en_GB';
        insert externalUser1;
        
        Order orderRec = new Order();
        orderRec.Status = 'Draft';
        orderRec.AccountId = testoutlet.id;
        orderRec.OrderedDate = System.now();
        orderRec.EffectiveDate = System.today();
        insert orderRec;
        
        Product2 testProd = D1_TestDataUtility.getProduct();
        insert testProd;
        
        OrderDeliveryMethod orderDeliveryMethodRec = new OrderDeliveryMethod();
        orderDeliveryMethodRec.Name = 'test Order Delivery Method';
        orderDeliveryMethodRec.ProductId = testProd.Id;
        insert orderDeliveryMethodRec;
        
        
        OrderDeliveryGroup orderDeliveryGroupRec = new OrderDeliveryGroup();
        orderDeliveryGroupRec.DeliverToName = 'Test Delivery Group';
        orderDeliveryGroupRec.OrderDeliveryMethodId = orderDeliveryMethodRec.Id;
        orderDeliveryGroupRec.OrderId = orderRec.Id;
        insert orderDeliveryGroupRec;
        
        OrderItem orderItemRec = new OrderItem();
        orderItemRec.Product2Id = testProd.Id;
        orderItemRec.OrderId = orderRec.Id;
        orderItemRec.OrderDeliveryGroupId = orderDeliveryGroupRec.Id;
        orderItemRec.Type = 'Order Product';
        orderItemRec.ListPrice = 1;
        orderItemRec.UnitPrice = 1;
        orderItemRec.TotalLineAmount = 1;
        orderItemRec.Quantity  = 1;
        insert orderItemRec;
        
        
        orderRec.Status = 'Activated';
        update orderRec;
        
        ConnectApi.OrderSummaryInputRepresentation osir = new ConnectApi.OrderSummaryInputRepresentation();
        osir.orderId=orderRec.Id;
        osir.orderLifeCycleType='UNMANAGED';
        ConnectApi.OrderSummaryOutputRepresentation osor = ConnectApi.OrderSummaryCreation.createOrderSummary(osir);
        
        OrderSummary orderSummaryRec = [SELECT Id FROM OrderSummary WHERE 	OriginalOrderId =: orderRec.Id LIMIT 1];
        Sales_Order__c sO = D1_TestDataUtility.getSalesOrder();
        sO.Order_Summary__c = orderSummaryRec.Id;
        insert sO;
        Test.stopTest();
    }
}