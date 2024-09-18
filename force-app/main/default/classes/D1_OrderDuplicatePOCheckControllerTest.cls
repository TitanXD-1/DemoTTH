/**
 * @name : D1_OrderDuplicatePOCheckControllerTest
 * @description : Test Class for D1_OrderDuplicatePOCheckControllerTest
 * @history                                                                                                                    
 * VERSION     AUTHOR            DATE              DETAIL
 * 1.0         Saurav Paul       18/02/2021        Initial Development
 * 2.0			Abhishek Jethi	  01/07/2021		Refactoring
 **/
@isTest
public class D1_OrderDuplicatePOCheckControllerTest {
    //create Diageo One External User
    @testSetup static void createTestData() {
        account acc= D1_TestDataUtility.getDirectCustomer();
       
        D1_TestDataUtility.setUpExternalUser(acc,'Direct Buyer');
        
        D1_TestDataUtility.insertCartAndCartItems(acc);
        
    }
    @isTest
    public static void checkCart(){
        
        User userObj = [SELECT Id,AccountId,Account.Name 
                        FROM User 
                        WHERE Profile.Name = 'DiageoOne External User' 
                        AND Isactive = true 
                        ORDER BY lastModifieddate desc LIMIT 1];
        D1_TestDataUtility.b2bCommercePermissionSet(userObj);
        
        system.runAs(userObj) {
          
            
            //fake response
            Test.setMock(WebServiceMock.class, new D1_DuplicatePOWSDLMockTest());
            Test.startTest();
            List<String> poList = new List<String>{'Po1'};
            D1_OrderDuplicatePOCheckController.DuplicatePOWrapper duplicatePO = new D1_OrderDuplicatePOCheckController.DuplicatePOWrapper();
            duplicatePO = D1_OrderDuplicatePOCheckController.getDuplicatePO(poList, '389201');
            System.assert(duplicatePO != NULL, 'duplicate po exists');
            Test.stopTest();
        }
    }
    @isTest
    public static void checkCartError(){
        User userObj = [SELECT Id,AccountId,Account.Name 
                        FROM User 
                        WHERE Profile.Name = 'DiageoOne External User' 
                        AND Isactive = true 
                        ORDER BY lastModifieddate desc LIMIT 1];
        D1_TestDataUtility.b2bCommercePermissionSet(userObj);
        system.runAs(userObj) {
           
            
            
            Test.startTest();
            List<String> poList = new List<String>{'Po1'};
            D1_OrderDuplicatePOCheckController.DuplicatePOWrapper cartError = new D1_OrderDuplicatePOCheckController.DuplicatePOWrapper();
            cartError = D1_OrderDuplicatePOCheckController.getDuplicatePO(poList, '389201');
            System.assert(cartError != NULL, 'error in cart value');
            Test.stopTest();
        }
    }
}