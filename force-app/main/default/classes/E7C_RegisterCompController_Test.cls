@isTest 
public class E7C_RegisterCompController_Test {
    
    @isTest static void testmethod1(){
        
        Id recTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        
        Geography__c geo = new Geography__c();
        geo.Name = 'Ireland';
        geo.Code__c = 'IR';
        geo.RecordTypeId = recTypeId;
        insert geo;
        User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
            IsActive = true
            
        );
        insert u;
        Test.startTest();
        System.runAs(u){
            Survey__c surveyRec = new Survey__c();            
            //surveyRec.IsActive__c = true;
            surveyRec.Country__c = geo.Id;
            surveyRec.E7Cs_Persona__c = 'Mystery Shopper';
            surveyRec.Start_Date__c = system.today().addDays(-10);
            surveyRec.End_Date__c = system.today().addDays(10);
            insert surveyRec;     
            Account acc = new Account();
            acc.Name = 'Guinness 7Cs';
            insert acc;
            
            User userObj = new User();
            userObj.Email = 'testuser@7c.com';
            
            User userObj2 = new User();
            userObj2.Email = 'testAdmin@diageo.com';
            
            try{
                E7C_RegisterCompController.registerUser(userObj, 'Mystery Shopper', 'Guinness@7cs');                  
            }catch(Exception e){
                system.debug(e.getMessage());
            }
            
            try{
                E7C_RegisterCompController.registerUser(userObj2, 'Mystery Shopper', 'Guinness@7cs'); 
            }catch(Exception e){
                
            }  
            
            E7C_RegisterCompController.getValidPersonas('Ireland');
            
            E7C_RegisterCompController.getValidPersonas('test');
            
        }
        
        Test.stopTest();    
    }
}