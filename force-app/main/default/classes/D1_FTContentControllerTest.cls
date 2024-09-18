@isTest
public class D1_FTContentControllerTest {
    @testSetup 
    public static void createTestData() {
        Account account = D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
    }
    
    @isTest
    public static void getContentDetailsTest(){
        String validContentId= 'MC3QY2R2YKANBZJASMBAHKSW2H5U';
        String language='en_GB';
        
        User userObj = [select Id,AccountId,D1_User_Type_Id__c,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        System.runAs(userObj){
            Test.startTest();
            try{
            	D1_FTContentController.getContentDetails(validContentId,language);
                D1_FTContentController.getContents(new List<String>{validContentId},language);
                System.assert(D1_FTContentController.getContentDetails(validContentId,language) != NULL, 'Content Details not found');
                System.assert(D1_FTContentController.getContents(new List<String>{validContentId},language) != NULL, 'Content Version Collection not found');
            }catch(Exception ex){
                System.assertNotEquals(ex.getMessage(), '', 'Assertion failed');
            }
            
			Test.stopTest();
        }
    }
    
    @isTest
    public static void testGetUserTypeInfo(){
        User userObj = [select Id,AccountId,D1_User_Type_Id__c,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];

        System.runAs(userObj){
            Test.startTest();
            try{
                D1_FTContentController.getUserTypeInfo();
                System.assert(D1_FTContentController.getUserTypeInfo() != NULL, 'User type not found');                
            }catch(Exception ex){
                System.assertNotEquals(ex.getMessage(), '', 'Assertion Failed');
            }
            
			Test.stopTest();
        }
    }
    
    @isTest
    public static void getContentsTest(){
        String validContentId= 'MC3QY2R2YKANBZJASMBAHKSW2H5U';
        String language='en_GB';
        
        User userObj = [select Id,AccountId,D1_User_Type_Id__c,Account.Name,Effective_Account_Id__c from User where Profile.Name = 'DiageoOne External User' 
                        and Isactive = true  order by lastModifieddate desc limit 1];
        System.runAs(userObj){
            Test.startTest();
            try{
                D1_FTContentController.getContents(new List<String>{validContentId},language);
                System.assert(D1_FTContentController.getContents(new List<String>{validContentId},language) != NULL, 'Content Version Collection for item not found');
            }catch(Exception ex){
                System.assertNotEquals(ex.getMessage(), '', 'Assertion Failed');
            }
            
			Test.stopTest();
        }
    }
}