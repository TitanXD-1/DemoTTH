@isTest
public class E7C_SurveyStoreSearchCompController_Test {

    @isTest static void testMethod1(){
        Test.startTest();
        
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
        surveyRec.E7Cs_Persona__c = 'Mystery Shopper';
        insert surveyRec;       
        
        
        E7C_Survey_Response__c srRec = new E7C_Survey_Response__c();
        srRec.E7C_Survey_Response_Date__c = system.today().addDays(-5);
        srRec.E7C_Status__c = 'Draft';
        srRec.OwnerId = UserInfo.getUserId();
        srRec.Survey__c = surveyRec.Id;
        insert srRec;
        
        E7C_SurveyStoreSearchCompController.createOrUpdateSurvey('Ireland', 'test outlet, address', 'test outlet', 'test address', '13.5678', '80.434563');
        
        srRec.E7C_Status__c = 'Completed';
        update srRec;
        
        E7C_SurveyStoreSearchCompController.createOrUpdateSurvey('Ireland', 'test outlet', 'test outlet', 'test address', '13.5678', '80.434563');
        
        E7C_SurveyStoreSearchCompController.getNearbyLocations('13.20095', '77.70851');
        
        E7C_SurveyStoreSearchCompController.searchOutlets('Byg brewsky');
        
        Test.stopTest();

    }
}