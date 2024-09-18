/**
* @name: D1_LoginFormControllerTest
* @discription: D1_LoginFormController Test Class
* @History
* VERSION     AUTHOR         DATE               DETAIL
* 1.0         Ajay        	   -                  -
* 2.0		 Rubeena	   29/06/2021   Test Class Refractor [NCP-3781]
**/
@isTest
public class D1_LoginFormControllerTest {
    /**
    * @name : dataSetup
    * @description : This method is used to create test data
    */
    @testSetup
    public static void dataSetup(){
        Account account = D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        
        Contact con = D1_TestDataUtility.getContact(account.id, 'Secondary');
		insert con;   

        AccountContactRelation acr= [SELECT Id FROM AccountContactRelation LIMIT 1];
        acr.D1_Active__c = true;
        update acr;  
    }
    
    /**
    * @name : loginTest
    * @description : This method is used to test login() for different scenarios and failureLoginActions()
    */
    @isTest
    public static void loginTest(){        
        User externalUser1 = [SELECT Id,Username,isActive FROM User WHERE username ='testclassextuser1@testdomain.com' LIMIT 1];
        System.setPassword(externalUser1.id, 'Diageo@12345');
        String loginRes;
        Exception exc ;
        
        Test.startTest();
        	//Case 1 - Log in for active user
            D1_LoginFormController.login('testclassextuser1@testdomain.com', 'Diageo@1234Test', '','GB','en_GB');        
            
        	//Case 2 - Log in for active user in lockedout period
        	try{
                D1_LoginFormController.isPasswordLockedStatus = true;
                D1_LoginFormController.login('testclassextuser1@testdomain.com', 'password', 'startUrl','GB','en_GB');
                D1_LoginFormController.failureLoginActions(externalUser1, 10, 30, exc, 'en_GB');
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        	
        	//Case 3 - Log in for InActive User
        	externalUser1.IsActive = false;
        	update externalUser1;
        	D1_LoginFormController.login('testclassextuser1@testdomain.com', 'Diageo@1234Test', '','GB','en_GB');
        	
        	//Case 4 - Log in for User with invalid credentials
        	loginRes = D1_LoginFormController.login('Test2@d', 'password', 'startUrl','GB','en_GB');
        Test.stopTest();
        
        System.assert(loginRes != null, 'LOG IN WORKED FOR INVALID USER');
        Assert.isNotNull(loginRes, 'LOG IN WORKED FOR INVALID USER');
    }
    
    /**
    * @name : testGenericMethods
    * @description : This method is used to test generic AuraEnabled methods of the main class
    */
    @isTest
    public static void testGenericMethods(){
        User externalUser = [SELECT Id,Username FROM User WHERE username ='testclassextuser1@testdomain.com' LIMIT 1];
        Contact con = [SELECT Id,D1_Contact_Last_Login_Date__c,MD_SubscriptionDate__c FROM contact LIMIT 1];
        Test.startTest();
            D1_LoginFormController.getIsSelfRegistrationEnabled();
            D1_LoginFormController.getIsUsernamePasswordEnabled();
            D1_LoginFormController.setExperienceId('expId');
            D1_LoginFormController.getD1Setting('GB','en_GB');
        
            system.runAs(externalUser){
                D1_LoginFormController.updatelastlogin();
            }
        
            con.D1_Contact_Last_Login_Date__c = system.today();
            con.MD_SubscriptionDate__c = system.today().addMonths(-1);
        	con.D1_Login_Counter__c = null;
            update con;
        
			D1_LoginFormController.updatelastlogin(con.Id);
        
        	//As we cannot update NumberOfFailedLogins in test class hence calling below methods manually for left scenarios
        	D1_LoginFormController.setLoginStatus(new D1_LoginFormController.LoginUserWrapper(),D1_LoginFormController.LOGIN_STATUS.SUCCESS);
            D1_LoginFormController.setLoginStatus(new D1_LoginFormController.LoginUserWrapper(),D1_LoginFormController.LOGIN_STATUS.LOCKED);
            D1_LoginFormController.setLoginStatus(new D1_LoginFormController.LoginUserWrapper(),D1_LoginFormController.LOGIN_STATUS.INVALID_PASSWORD);
            D1_LoginFormController.LoginUserWrapper result = D1_LoginFormController.setLoginStatus(new D1_LoginFormController.LoginUserWrapper(),D1_LoginFormController.LOGIN_STATUS.INVALID);
        Test.stopTest();
        
        System.Assert(result != Null, 'INVALID STATUS NOT DEFINED');
        Assert.isNotNull(result, 'INVALID STATUS NOT DEFINED');
        
        Contact updatedCon = [SELECT D1_Login_Reminder_Status__c FROM contact WHERE Id =: con.Id LIMIT 1];
        System.Assert(updatedCon.D1_Login_Reminder_Status__c == 'Compliant', 'LASTLOGIN NOT UPDATED');
        Assert.areEqual(updatedCon.D1_Login_Reminder_Status__c, 'Compliant', 'LASTLOGIN NOT UPDATED' );
    }
}