@isTest
public with sharing class D1_OrdersTriggerHelperTest {
    
    @testSetup static void createTestData(){
        D1_TestDataUtility.setupCountry('GB');
       
        //Create Account
        Account account = D1_TestDataUtility.getDirectCustomer();
        account.Country_ISO_Code__c = 'GB';

        //Setup Direct Customer
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
         
        //Setup Org Setting
        D1_TestDataUtility.createOrgSettings();

        //Query D1 Community User
        User userObj = [SELECT Id, AccountId, Effective_Account_Id__c FROM User WHERE Profile.Name = 'DiageoOne External User' 
                        AND IsActive = true  ORDER BY LastModifiedDate DESC LIMIT 1];

        //Get Account
        Account acc = [SELECT Id FROM Account LIMIT 1];

        system.runAs(userObj){
            //Assign B2B Commerce User Permission Set to access B2B Commerce
            D1_TestDataUtility.b2bCommercePermissionset(userObj);
        }

        //Create Order
        List<Order> orderList = new List<Order>();
        for(Integer i=0; i<4; i++){
            orderList.add(D1_TestDataUtility.getOrder(acc.Id));
        }
        insert orderList;
    }

    @isTest
    public static void testValidateNumberOfOrders(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c,'country code does not match');
            //Create Order
            List<Order> orderList = new List<Order>();
            for(Integer i=0; i<5; i++){
                orderList.add(D1_TestDataUtility.getOrder(acc.Id));
            }
            Test.startTest();
                insert orderList;
            Test.stopTest();
    
            List<Order> orderListt = [SELECT Id FROM Order WHERE AccountId =:acc.Id];
            System.assertEquals(5, orderListt.size(), 'order numbers does not match');
        }catch(Exception ex){
            Boolean exceptionThrown =  ex.getMessage().contains('You have reached maximum allowed order limit') ? true : false;
            System.assertEquals(exceptionThrown, true, 'assertion failed');
        }
        
    }
    @isTest
    public static void testUpdateOrder(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c, 'country code does not match');
            //Create Order
              List<Order> orderList = [SELECT Id FROM Order WHERE AccountId =:acc.Id];
          
            Test.startTest();
           	orderList[0].EffectiveDate= date.today()+1;
            update orderList;
            Test.stopTest();
            System.assertEquals(4, orderList.size(), 'order list size does not match');
        }catch(Exception ex){
            Boolean exceptionThrown =  ex.getMessage().contains('You have reached maximum allowed order limit') ? true : false;
            System.assertEquals(exceptionThrown, true, 'assertion failed');
        }
        
    }
    @isTest
    public static void testdeleteOrder(){
        try{
            //Get Account
            Account acc = [SELECT Id, Country__c, Country__r.Code__c FROM Account LIMIT 1];
            System.assertEquals('GB', acc.Country__r.Code__c, 'country code does not match');
            //Create Order
              List<Order> orderList = [SELECT Id FROM Order WHERE AccountId =:acc.Id];
          
            Test.startTest();
           	orderList[0].EffectiveDate= date.today()+1;
            delete orderList;
            Test.stopTest();
     	 List<Order> orderList2 = [SELECT Id FROM Order WHERE AccountId =:acc.Id];
            System.assertEquals(0, orderList2.size(), 'order list size does not match');
        }catch(Exception ex){
            Boolean exceptionThrown =  ex.getMessage().contains('You have reached maximum allowed order limit') ? true : false;
            System.assertEquals(exceptionThrown, true, 'assertion failed');
        }
        
    }
}