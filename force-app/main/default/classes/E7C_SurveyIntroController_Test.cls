@isTest
public class E7C_SurveyIntroController_Test {
    
    @isTest
    public static void testSurveyIntroController(){
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
        
        E7C_Survey_Response__c surRes = new E7C_Survey_Response__c();
        surRes.E7C_Status__c = 'Draft';
        surRes.Survey__c = surveyRec.Id;
        surRes.OwnerId = UserInfo.getUserId();
        insert surRes;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Guinness',
            PathOnClient = 'G1.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = surRes.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        ContentDocument document = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument][0];
        
        test.startTest();
        
        E7C_SurveyIntroController.getSurveyResId('Ireland');
        E7C_SurveyIntroController.deletePhotoApex(document.id);
        
        E7C_SurveyIntroController.updateConVersion(String.valueOf(document.id), 'EMPTY');
        
        test.stopTest();
    }
    
    /*@isTest
public static void testSurveyIntroControllerException(){
test.startTest();
E7C_SurveyIntroController.getSurveyResId('Ireland');
test.stopTest();
}*/
    
    
}