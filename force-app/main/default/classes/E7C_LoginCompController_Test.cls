@isTest
public class E7C_LoginCompController_Test {
    
    @isTest static void testMethod1(){
        
        Test.startTest();
        Account a = new Account(
        Name = 'Test Acc');
        insert a;
        Contact con = new Contact(
        LastName = 'Testln',
        FirstName = 'Testfn',
        AccountId = a.Id
        );
        insert con;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'E7C_Community User'].Id,
            LastName = 'last',
            Email = 'testUser@test7c.com',
            Username = 'testUser@test7c.com.7Cs',
            CompanyName = 'TEST',
            Title = 'title',
            Alias = 'alias',
            TimeZoneSidKey = 'America/Los_Angeles',
            EmailEncodingKey = 'UTF-8',
            LanguageLocaleKey = 'en_US',
            LocaleSidKey = 'en_US',
            IsActive = true,
            ContactId = con.Id
        );
        insert u;
        
        try{
            E7C_LoginCompController.validateUserLogin('testUser@test7c.com', '');
            E7C_LoginCompController.validateUserLogin('testUser@invalid.com', '');
            
        }catch(Exception e){
            
        }
        
        String result = E7C_LoginCompController.getLoginURLfromSSO();
        E7C_LoginCompController.fetchUserType();
        
        Test.stopTest();
        
        //E7C_LoginCompController.validateUserLogin('test@7c.com', 'testpwd');
    }
}