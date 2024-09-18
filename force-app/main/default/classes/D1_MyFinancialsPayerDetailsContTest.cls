/**
* @name: D1_MyFinancialsPayerDetailsController
* @discription: Test class for MyFinancialsPlayerDetails 
* @history
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Gaurav          12/03/21    NCP-1475
* 2.0         Narayana        06/07/21    NCP-3805(Refactor)
*/
@isTest
public class D1_MyFinancialsPayerDetailsContTest {
	@testSetup
    public static void setup(){

        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        System.assert(directCustomer != null, 'direct customer not found ');
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');

        Contact testcontact = [Select id from Contact limit 1];
        
        AccountContactRelation acr = [Select id,D1_Roles__c from AccountContactRelation where AccountId = :directCustomer.Id AND ContactId = :testcontact.Id];
        acr.D1_Roles__c = 'Account Balances';
        acr.D1_Active__c = true;
        update acr;
        System.assert(acr != null, 'account contact relation not found');

        PNR_Partner_Function__c test=D1_TestDataUtility.getPartnerFunction(directCustomer,'Payer');
        insert test;
        
        D1_Setting__c d1Setting = [Select id from D1_Setting__c limit 1];
        d1Setting.Display_Last_Payment_Received__c = true;
        update d1Setting;
        
        System.assert(d1Setting != null, 'd1 settings not found');
        
    }
    
    @isTest
    public static void testGetPayerFinancialInfo(){
        User usr = [Select id,D1_User_Type__c,D1_User_Type_Id__c,Available_Countries__c,LanguageLocaleKey from User where Profile.Name = 'DiageoOne External User' and UserName = 'testclassextuser1@testdomain.com' limit 1];
        D1_Setting__c d1Setting = [Select id from D1_Setting__c limit 1];

        
        System.assert(usr != null, 'user details not found');
        System.assert(d1Setting != null, 'd1 settings details not found');
            
        Test.setMock(HttpCalloutMock.class, new D1_PayerFinancialDetailsTest.D1_PayerFinancialDetailsCalloutMock(true));
        Test.startTest();
        system.runAs(usr){
        	D1_MyFinancialsPayerDetailsController.getPayerFinancialInfo(usr.Id);
            
            //test negative scenario
            try{
            	D1_MyFinancialsPayerDetailsController.getPayerFinancialInfo(d1Setting.Id);
            }catch( Exception e ){
                System.assertEquals('Script-thrown exception', e.getMessage(), 'assertion failed');
            }
            
            try{
                D1_MyFinancialsPayerDetailsController.getPayerFinancialInfo(null);
            }catch( Exception e ){
                System.assertEquals('Script-thrown exception', e.getMessage(), 'assertion failed');
            }
        }
        Test.stopTest();
    }
}