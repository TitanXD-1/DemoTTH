@isTest
public class D1_DeliveryControllerTest {
	
    @testSetup
    public static void setup(){
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        PNR_Partner_Function__c shipToPF = D1_TestDataUtility.getPartnerFunction(directCustomer,'Ship-To');
        insert shipToPF;
        
    }
    
    @isTest
    public static void testGetDeliveredTo(){
        
        List<User> users = [select id, AccountId,Effective_Account_Id__c,Available_Countries__c,D1_User_Type_Id__c from User where Profile.name ='DiageoOne External User' AND IsActive = true AND Email='testclassextuser1@testdomain.com' limit 1];
        if(users.isEmpty()){
            return;
        }
        
        User currentUser = users[0];    
        Account acc = new Account();
        acc = D1_DeliveryController.getAccountInfo(currentUser.Effective_Account_Id__c);
        System.assert(acc != NULL, 'Account info not found');
        D1_DeliveryController.getDeliveredTo(currentUser.Id);
        D1_DeliveryController.getD1Setting(currentUser.Id);
    } 

    
    
}