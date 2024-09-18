/*
* @name: D1_legalConsentControllerTest
* @discription: test class for D1_legalConsentController 
* @history
* VERSION     AUTHOR           DATE          DETAIL
* 1.0         Manikant         18/11/2020    Initial Development
* 2.0			Divya			 1/7/2021	   Refactoring[NCP-3784]
*/

@isTest
public class D1_legalConsentControllerTest {
    
    @testSetup
    public static void dataSetup(){
        Account account = D1_TestDataUtility.getDirectCustomer();
        system.assert(account!=null, 'account not found');
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer'); 
    }
    
    @isTest
    public static void testSubscriptionStatus(){
        Test.startTest();
        User externalUser1 = [SELECT Id FROM User where email = 'testclassextuser1@testdomain.com' limit 1];
        Contact testContact = new Contact(FirstName='Test', LastName='Contact', Email='testcontact@test.com',
                              MD_ContactSubscriptions__c='', MD_SubscriptionDate__c=null);
        insert testContact;
        String allSubscriptionString = 'Email;Phone';
        
        system.runAs(externalUser1){
            try{		
                    D1_legalConsentController.getSubscriptionStatus();
                    D1_legalConsentController.setSubscription(allSubscriptionString);	
                    Contact updatedContact = [SELECT MD_ContactSubscriptions__c, MD_SubscriptionDate__c FROM Contact WHERE Id = :testContact.Id];
        Test.stopTest();
                
                System.assertEquals(allSubscriptionString, updatedContact.MD_ContactSubscriptions__c, 'subscription is not updated');
                System.assertNotEquals(null, updatedContact.MD_SubscriptionDate__c, 'Subscription should not be null');
                System.assert(D1_legalConsentController.getSubscriptionStatus() != null, 'subscription status not found');
                
            }
            catch (Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            
        }
    }
}