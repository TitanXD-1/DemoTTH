@isTest 
public without sharing class E7C_Utility_Test {
    
    @isTest static void testMethod1(){
        Test.startTest();
        Id recTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
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
        
        System.runAs(u){
        Geography__c geo = new Geography__c();
        geo.Name = 'Ireland';
        geo.Code__c = 'IR';
        geo.RecordTypeId = recTypeId;
        insert geo;
        
        Survey__c surveyRec = new Survey__c();            
        //surveyRec.IsActive__c = true;
        surveyRec.Country__c = geo.Id;
        surveyRec.Start_Date__c = system.today().addDays(-10);
        surveyRec.End_Date__c = system.today().addDays(10);
        surveyRec.E7Cs_Persona__c = 'Mystery Shopper';
        insert surveyRec;
        
        
        E7C_Survey_Response__c srRec = new E7C_Survey_Response__c();
        srRec.E7C_Survey_Response_Date__c = system.today().addDays(-5);
        srRec.E7C_Status__c = 'Draft';
        //srRec.OwnerId = UserInfo.getUserId();
        srRec.Survey__c = surveyRec.Id;
        insert srRec;
        
        
        Id surveyId = E7C_Utility.getSurveyId('Ireland');
        Id surveyResId = E7C_Utility.getSurveyResponseId(surveyId);
        
        E7C_Utility.createSurveyResponseRecord(surveyId, 'test outlet, test address', 'Draft', '', 'test outlet', 'test address', '13.56774', '79.746345');
        
        E7C_Utility.updateSurveyResponseRecord(surveyResId, surveyId, 'test outlet, test address', 'Draft', '', 'test outlet', 'test address', '13.56774', '79.746345');
        
        srRec.E7C_Status__c = 'Completed';
        update srRec;
        
        Id surveyResId1 = E7C_Utility.getSurveyResponseId(surveyId);
        
        surveyResId1 = E7C_Utility.getCompletedSurveyResponseId(surveyId);
        }
        Test.stopTest();
    }
    
}