/*
 * @name: D1_DelegatedAccountTriggerHelperTest 
 * @Description: D1_DelegatedAccountTriggerHelper Test Class 
 * @History 
 * VERSION     AUTHOR         DATE               DETAIL 
 * 1.0         Rubeena        	-                    - 
 * 2.0			Rubeena		   25/06/2021		  Test Class Refractor [NCP-3781] 
 **/

@isTest
public class D1_DelegatedAccountTriggerHelperTest {
   /**
    * @description 
    */   
   @testSetup
   public static void dataSetup(){
 
       Account testAcc1 = D1_TestDataUtility.getDirectCustomer();
       Account testAcc2 = D1_TestDataUtility.getDirectCustomer();
       testAcc2.Name = 'Test Direct Account2';
       testAcc2.KUNNR__c = '54546';
       insert testAcc2;
       D1_TestDataUtility.setUpExternalUser(testAcc1,'Direct Buyer');
   	
   }    
    /**
     * @description 
     */    
    @isTest
    public static void testAccountShare(){   
        
        D1_TestDataUtility.createOrgSettings();
        
        Account testAccount = [Select Id FROM Account WHERE Name = 'Test Direct Account2'];
        Contact priContact = [Select Id FROM Contact];

		Test.startTest();        
        
        AccountContactRelation acrInsert = new AccountContactRelation(ContactId=priContact.Id,AccountId=testAccount.Id,Contact_Type__c='Secondary',D1_Active__c=true);   
        insert acrInsert;
        System.assert(acrInsert.Id != null,'Account Contact Relation not created properly.');
        
        DelegatedAccount da = [SELECT Id FROM DelegatedAccount limit 1 ];
        update da;
        delete da;
        new DelegatedAccountTriggerHandler().afterUndelete(null);
        
        Test.stopTest();
        
        
    }
   
}