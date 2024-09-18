/**********************************************************************
Name: EDGE_SurveyQuestionListControllerTest
=======================================================================
Purpose: This is the test class for EDGE_SurveyQuestionListController
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -    Saurav Paul      08/04/2019      Initial Development
***********************************************************************/
@isTest
public with sharing class EDGE_SurveyQuestionListControllerTest {
    //test method for getSurvey method
    @isTest
    public static void valiadegetSurveyName(){
        //Variables
        Survey__c surveyName, surveyName1 ;
        //Variables
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryId);
        insert surveyObj;
        Test.startTest();
        surveyName = EDGE_SurveyQuestionListController.getSurveyName(surveyObj.Id);
        
        surveyName1 = EDGE_SurveyQuestionListController.getSurveyName(null);
        Test.stopTest();
        System.assert(surveyName!= null);
    }
    //test method for getSurveyQuestions method
    @isTest
    public static void validateGetSurveyQuestions() {
        //Variables
        List<Survey_Question__c> survyQstnList = new List<Survey_Question__c>();
        List<Survey_Question__c> survyQstnRetList = new List<Survey_Question__c>(); 
        //Variables
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryId);
        insert surveyObj;
        Survey_Question__c surveyQues1 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        survyQstnList.add(surveyQues1);
        Survey_Question__c surveyQues2 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        survyQstnList.add(surveyQues2);
        Survey_Question__c surveyQues3 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        survyQstnList.add(surveyQues3);
        insert survyQstnList;
        Test.startTest();
        survyQstnRetList = EDGE_SurveyQuestionListController.getSurveyQuestions(surveyObj.Id);
        Test.stopTest();
        System.assertEquals(survyQstnList.size(), survyQstnRetList.size());
    } 
    //test method for insertSurveyOptions method
    @isTest
    public static void validateInsertSurveyOptions(){
        //Variables
        List<Survey_Answer__c> survAnsrLst = new List<Survey_Answer__c>();
        List<Survey_Answer__c> survAnsrRetLst = new List<Survey_Answer__c>();
        //Variables
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryId);
        insert surveyObj;
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        insert surveyQuesObj;
        survAnsrLst.add(EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id));
        survAnsrLst.add(EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id));
        survAnsrLst.add(EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id));
        Test.startTest();
        EDGE_SurveyQuestionListController.insertSurveyOptions(surveyQuesObj.Id,survAnsrLst,true);
        
        EDGE_SurveyQuestionListController.insertSurveyOptions(surveyQuesObj.Id,survAnsrLst,false);
        Test.stopTest();
        survAnsrRetLst = [SELECT Id FROM Survey_Answer__c WHERE Survey_Question__c =: surveyQuesObj.Id];
        System.assertEquals(survAnsrLst.size(), survAnsrRetLst.size());
    }
    //test method for getSurvyAnsr method
    @isTest 
    public static void validateGetSurvyAnsr(){
        //Variables
        List<Survey_Answer__c> survAnsrLst = new List<Survey_Answer__c>();
        List<Survey_Answer__c> survAnsrRetLst = new List<Survey_Answer__c>();
        List<Survey_Question__c> surveyQuestionList = new List<Survey_Question__c>();
        //Variables
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        string gridSurveyRecTypeId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Grid Survey').getRecordTypeId();
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryId);
        surveyObj.RecordTypeId = gridSurveyRecTypeId;
        insert surveyObj;
        Survey_Grid__c surveyGrid = new Survey_Grid__c();	
        surveyGrid.Survey__c = surveyObj.Id;	
        insert surveyGrid;
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        
        surveyQuesObj.Image_Required__c = true;
        insert surveyQuesObj;
        
        Survey_Question__c surveyQuesObj1 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        
        surveyQuesObj1.Image_Required__c = true;
        insert surveyQuesObj1;
        
        survAnsrLst.add(EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id));
        survAnsrLst.add(EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id));
        survAnsrLst.add(EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id));
        insert survAnsrLst;
        Test.startTest();
        surveyQuestionList.add(surveyQuesObj);
        survAnsrRetLst = EDGE_SurveyQuestionListController.getSurvyAnsr(surveyQuesObj.Id);
        EDGE_SurveyQuestionListController.getSurveyQuestions(surveyObj.id); 
       	EDGE_SurveyQuestionListController.checkImageRequiredForGridSurvey(surveyObj.id,surveyGrid.id,surveyQuesObj1.Id);
        EDGE_SurveyQuestionListController.saveChildQuestion(surveyQuestionList,surveyQuesObj.id);
        EDGE_SurveyQuestionListController.getConditionalSurveyQuestion(surveyObj.id,surveyQuesObj.id);
        
        // calling wrper  EDGE_SurveyQuestionListController
        EDGE_SurveyQuestionListController.SurveyQuestionWrapper  wrap = new EDGE_SurveyQuestionListController.SurveyQuestionWrapper();
          wrap.isSelected = false ;
        wrap.questionId = surveyQuesObj.id;
        wrap.questionName = 'test';
        wrap.questionType = 'test';
        Test.stopTest();
        System.assertEquals(survAnsrLst.size(), survAnsrRetLst.size());
    }
    
   
}