/**
 * @name: D1_AccountSwitchControllerTest
 * @description D1_AccountSwitchController Test class
 * @History
 * VERSION     AUTHOR         DATE               DETAIL
 * 1.0         Ajay           25/03/2021         Initial Development (NCP-2183)
 * 2.0			Rubeena		   25/06/2021		  Test Class Refractor [NCP-3781]
 **/
@isTest
public class D1_AccountSwitchControllerTest {
    /**
     * @description 
     */    
    @testSetup
    public static void dataSetup(){
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        System.assert(directCustomer != null, 'direct customer not found');
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        List<AccountContactRelation> relations = [Select id,D1_Active__c, AccountId from AccountContactRelation];
        for(AccountContactRelation acr: relations){
            acr.D1_Roles__c = 'Ordering;Financial Documents;';
            acr.D1_Active__c = true;

            //Create ContactPointAddress
            ContactPointAddress cpaBilling = D1_TestDataUtility.insertContactPointAddress();
            cpaBilling.AddressType = 'Billing';
            cpaBilling.ParentId = acr.AccountId;
            cpaList.add(cpaBilling);

            //Create ContactPointAddress
            ContactPointAddress cpaShipping = D1_TestDataUtility.insertContactPointAddress();
            cpaShipping.ParentId = acr.AccountId;
            cpaList.add(cpaShipping);
        }
        update relations;

        //Insert ContactPointAddress
        insert cpaList;
    }
    /**
     * @description 
     */    
    @isTest
    public static void testSwitch(){
               
        User user = [select id,accountId from User where profile.name ='DiageoOne External User' and username ='testclassextuser1@testdomain.com' limit 1];
        System.assert(user != null, 'user not found');
        Test.startTest();
        D1_AccountSwitchController.getRelatedAccounts(user.id);
        D1_AccountSwitchController.updateEffectiveAccountId(user.AccountId, user.id);
        D1_AccountSwitchController.getAccountPermissionData();
        Test.stopTest();
    }
}