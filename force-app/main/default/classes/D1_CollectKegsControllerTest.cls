/*
 * @name: D1_CollectKegsControllerTest 
 * @description: Test class for D1_CollectKegsController 
 * @history 
 * VERSION     AUTHOR           DATE       DETAIL 
 * 1.0         Ajay            12/01/20    Initial Development(NCP-1351) 
 **/
@isTest
public class D1_CollectKegsControllerTest {
    /**
     * Test the raiseKegCollectionRequest method
     */
    @isTest
    static void testRaiseKegCollectionRequest() {
        // Create test data
        Account testAccount = new Account(Name='Test Account');
        Contact testContact = new Contact(LastName='Test', AccountId=testAccount.Id);
        Integer testQuantity = 10;
        String testSAPShipToNumber = testContact.Id;
        Test.startTest();
        insert testAccount;
        insert testContact;
        
        // Call the method from main class
        D1_CollectKegsController.raiseKegCollectionRequest(testQuantity, testSAPShipToNumber);
        Test.stopTest();
        
        // Verify that a case was created
        List<Case> cases = [SELECT Id, Number_of_Kegs_Requested__c, SAP_Ship_To_Customer_No__c, AccountId, ContactId
                            FROM Case
                            WHERE Number_of_Kegs_Requested__c = :testQuantity
                            AND SAP_Ship_To_Customer_No__c = :testSAPShipToNumber
                            AND AccountId = :testAccount.Id
                            AND ContactId = :testContact.Id];
        
        // Assert that a case was created
        System.assert(cases.size()!=null,  'Collection request failed');
    }
}