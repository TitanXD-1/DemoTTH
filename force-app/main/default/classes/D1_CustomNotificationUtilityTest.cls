/*
 * @name: D1_CustomNotificationUtilityTest
 * @description: Test Class for D1_CustomNotificationUtility
 * @history                                                            
 *                                                             
 * VERSION     AUTHOR              DATE            DETAIL
 * 1.0         Kapil Baliyan       25/07/2021      Initial Development(NCP-3829)
 **/
@isTest
public with sharing class D1_CustomNotificationUtilityTest {
    /**
     * @description 
     */    
    @testSetup
    public static void testSetup(){
        Account dc = D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(dc, 'Direct Buyer');
    }
    /**
     * @description 
     */    
    @isTest
    public static void testCustomNotificationUtility() {
        Contact contact = [SELECT Id FROM Contact WHERE Email = 'testclassextuser1@testdomain.com']; 
        Set<String> contactIds = new Set<String>();
        contactIds.add(contact.Id);
        
        Test.startTest();
  			D1_CustomNotificationUtility.notifyUsers(contactIds,'D1_Nozzle_and_Glassware_Status_Update','D1_POS_Order_Title','D1_Glassware_Body',contact.Id,'my-orders',null,null);
        	Integer invocations = Limits.getFutureCalls();
        Test.stopTest();
        system.assertEquals(1, invocations, 'Notification should be sent');
    }
}