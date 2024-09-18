@isTest
public class E7C_SurveyArchiveController_Test {
    
    @isTest static void testMethod1(){
        Id recTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        
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
        insert surveyRec;     
            User u = new User(
            ProfileId = [SELECT Id FROM Profile WHERE Name = 'System Administrator'].Id,
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
            IsActive = true
            
        );
        insert u;
        System.runAs(u){
            E7C_Survey_Response__c surRes = new E7C_Survey_Response__c();
            surRes.E7C_Status__c = 'Completed';
            surRes.Survey__c = surveyRec.Id;
            surRes.E7C_Survey_Outlet__c = 'test, test';
            surRes.E7C_Survey_Response_Date__c = system.today().addDays(-5);
            insert surRes;
            
            E7C_Survey_Response__c surRes1 = new E7C_Survey_Response__c();
            surRes1.E7C_Status__c = 'Submitted';
            surRes1.Survey__c = surveyRec.Id;
            surRes1.E7C_Survey_Outlet__c = 'test, test1';
            surRes1.E7C_Survey_Response_Date__c = system.today().addDays(-5);
            surRes1.E7C_Survey_Result__c = 'Pass';
            insert surRes1;
            
            Test.startTest();
            
            E7C_SurveyArchiveController.getAllSurveyResponse('', null, '');
            
            E7C_SurveyArchiveController.getAllSurveyResponse('', String.valueOf(system.today().addDays(-5)), '');
            
            E7C_SurveyArchiveController.getAllSurveyResponse('test', null, '');
            
            E7C_SurveyArchiveController.getAllSurveyResponse('test', null, 'Pass');
            
            Test.stopTest();
        }
    }
}