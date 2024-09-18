@isTest
public class E7C_SurveyQuestionController_Test {
    @testSetup static void setup() {
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
        
        E7C_Survey_Response__c surRes = new E7C_Survey_Response__c();
        surRes.E7C_Status__c = 'Draft';
        surRes.Survey__c = surveyRec.Id;
        surRes.E7C_Survey_Outlet__c = 'test, test';
		insert surRes;
        
		Survey_Question__c surQues = new Survey_Question__c();
        surQues.Question__c = 'What is the actual temperature of the pint?';
        surQues.E7Cs_Category__c = 'Clean Lines';
        surQues.E7Cs_Criteria__c = 'C3';
        surQues.Response_Type__c = 'CheckBox';
        surQues.Survey__c = surveyRec.Id;
        surQues.Order_Number__c = 1;
        surQues.Expected_Response__c = '2°C';
        surQues.E7Cs_Description__c = 'TO DELIVER GREAT LOOKING GREAT TASTING GUINNESS DRAUGHT, YOU SHOULD SERVE IT AT 5-7° C.';
        insert surQues;
        
        Survey_Answer__c surAns = new Survey_Answer__c();
        surAns.Option_Value__c = 'A';
        //surAns.E7C_Answer_Type__c = 'Text Input';
        surAns.Survey_Question__c = surQues.Id;
        insert surAns;
        
        E7C_Survey_Question_Response__c surQuRes = new E7C_Survey_Question_Response__c();
        surQuRes.E7C_Question__c = surQues.Id;
        surQuRes.E7C_Answer__c = '2°C';
        surQuRes.E7C_Survey_Response__c = surRes.Id;
        insert surQuRes;
        
        ContentVersion contentVersion = new ContentVersion(
            Title = 'Guinness',
            PathOnClient = 'G1.jpg',
            VersionData = Blob.valueOf('Test Content'),
            IsMajorVersion = true,
			E7C_Pint_Type__c = 'Full'
        );
        insert contentVersion;    
        List<ContentDocument> documents = [SELECT Id, Title, LatestPublishedVersionId FROM ContentDocument];
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = surRes.id;
        cdl.ContentDocumentId = documents[0].Id;
        cdl.shareType = 'V';
        insert cdl;
        
    }
    
    @isTest
    public static void testSurveyQuestionController(){
        Id surQuesId = [SELECT Id from Survey_Question__c][0].Id;
        Id surResId = [SELECT Id from E7C_Survey_Response__c][0].Id;
        String needImproveJSON = '[{"priority":"C7","activities":[{"category":"Crafted Presentation","question":"Did the outlet use a Guinness gravity glass?"}]}]';
        List<E7C_Survey_Question_Response__c> surQRList= [SELECT Id, E7C_Question__c, E7C_Answer__c, E7C_Survey_Response__c FROM E7C_Survey_Question_Response__c];
        String location = 'Ireland';
        test.startTest();
        E7C_SurveyQuestionController.getquestionMap();
        E7C_SurveyQuestionController.getParentQuestion(surQuesId);
        E7C_SurveyQuestionController.getChosenAnswers(surResId);
        E7C_SurveyQuestionController.getSurveyResId(location);
        
        E7C_SurveyQuestionController.getSurveyQuestions(location);
        
        E7C_SurveyQuestionController.saveResponsesCaptured(surQRList, surResId);
        E7C_SurveyQuestionController.submitSurveytoServer('Test Notes',location);
        E7C_SurveyQuestionController.sendReportEmail(location, needImproveJSON, surResId);
        test.stopTest();
    }

}