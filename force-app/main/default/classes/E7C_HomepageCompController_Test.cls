@isTest
public class E7C_HomepageCompController_Test {
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
        
        E7C_HomepageCompController.getActiveSurveyLocations();
    }
}