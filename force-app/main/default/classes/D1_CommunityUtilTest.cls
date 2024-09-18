/*


 * @name: D1_CommunityUtilTest
 * @discription : Utility Test Class for Diageo One Community
 * @History
 * VERSION     AUTHOR      DATE            DETAIL
 * 1.0         -              -            Initial Development
 * 2.0         Abhishek    20/07/21       (Test Class Refactoring)
 **/


@isTest
public with sharing class D1_CommunityUtilTest {
    /**
     * @description 
     */    
    @isTest
    public static void testAssignPermission() {
       
        account acc= D1_TestDataUtility.getD1Customer();

        
        //Setup External User
        D1_TestDataUtility.setUpExternalUser(acc,'Direct Buyer');
        
        //Update ACR
        account testoutlet = [select id from account where BillingCity = 'Birmingham'];
        contact primcon1= [Select id from contact where Contact_Type__c='Primary'];
        AccountContactRelation acr= D1_TestDataUtility.returnACR(testoutlet.id,primcon1.id);
        acr.D1_Roles__c = 'Ordering;Financial Documents;';
        update acr;

        //Create ContactPointAddress
        List<ContactPointAddress> cpaList = new List<ContactPointAddress>();
        ContactPointAddress cpaBilling = D1_TestDataUtility.insertContactPointAddress();
        cpaBilling.AddressType = 'Billing';
        cpaBilling.ParentId = testoutlet.id;
        cpaBilling.Source__c  = 'Diageo One';
        cpaList.add(cpaBilling);

        ContactPointAddress cpaShipping = D1_TestDataUtility.insertContactPointAddress();
        cpaShipping.ParentId = testoutlet.id;
        cpaShipping.Source__c  = 'Diageo One';
        cpaList.add(cpaShipping);

        insert cpaList;
     

        User userObj = [SELECT Id,AccountId,Account.Name 
                        FROM User 
                        WHERE Profile.Name = 'DiageoOne External User' 
                        AND Isactive = true 
                        ORDER BY lastModifieddate desc LIMIT 1]; 
        
        //assign permission test
        System.runAs(userObj) {
            Test.startTest();
            Map<String,Object> mapFinancial=D1_CommunityUtil.assignPermission(null,null); 
            System.assertEquals(mapFinancial.get('Financial Documents'), True, 'financial document not found');
            Map<String,Object> assignPermission = D1_CommunityUtil.assignPermission(testoutlet.id,null);
            system.assertEquals(assignPermission.get('B2B Commerce User'), True, 'permission set not assigned');
            Boolean isMyContractPermissionExist= D1_CommunityUtil.isMyContractPermissionExist();
            system.assert(isMyContractPermissionExist!=true,'Contract Permission do not exist');
            D1_CommunityUtil.getMyAccountCards();
            system.assert(D1_CommunityUtil.getMyAccountCards()!=null,'getMyAccountCards not found');
            Test.stopTest();
        }
        
        
    }
}