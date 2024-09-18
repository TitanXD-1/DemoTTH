@isTest
public class E7C_FogotPasswordCompController_Test {
    @isTest static void testmethod1(){
        
        Test.startTest();
        
        Account ac = new Account(name ='Guinness 7Cs') ;
        insert ac; 
        
        Contact con = new Contact(LastName ='testCon', AccountId = ac.Id); 
        insert con;  
        
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'E7C_Community User'].Id,
            LastName = 'last',
            Email = 'testUser@test7c.com',
            Username = 'testAdmin@test7c.com.7Cs',
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
        
        E7C_FogotPasswordCompController.resetPassword('testUser@test7c.com');
        try{
            E7C_FogotPasswordCompController.resetPassword(null);
        }catch(Exception e){
            
        }
        
        Test.stopTest();
    }
}