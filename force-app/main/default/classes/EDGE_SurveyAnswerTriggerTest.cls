/**********************************************************************
Name: EDGE_SurveyAnswerTriggerTest
=======================================================================
Purpose: This is the test class for SurveyAnswerTriggerHandler
SurveyAnswerTrigger
EDGE_SurveyAnswerTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -    Saurav Paul      08/04/2019      Initial Development
***********************************************************************/
@isTest
public class EDGE_SurveyAnswerTriggerTest{  
    //Insert Test
    @isTest
    
    public static void validateAddOptionsValInsert(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        //surveyObj.Grouping__c = 'Group_1';
        insert surveyObj;
        //insert Survey Question Record
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'CheckBox' ;
        insert surveyQuesObj;
        //insert Survey Answer Record
        Survey_Answer__c surveyAnsrObj = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id); 
        Test.startTest();
        insert surveyAnsrObj;
        Test.stopTest();
        Survey_Question__c quesObjAftrUpdt = [SELECT Id,Answer_Option__c FROM Survey_Question__c WHERE Id =: surveyQuesObj.Id];
        System.assert(quesObjAftrUpdt.Answer_Option__c != null);
    }
    //Update test
    @isTest
    public static void validateAddOptionsValUpdt(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        //surveyObj.Grouping__c = 'Group_1';
        insert surveyObj;
        //insert Survey Question Record
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'Picklist' ;
        insert surveyQuesObj;
        //insert Survey Answer Record
        Survey_Answer__c surveyAnsrObj = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id);
        insert surveyAnsrObj;
        surveyAnsrObj.Option_Value__c = 'Updated Optn';
        Test.startTest();
        update surveyAnsrObj;
        Test.stopTest();
        Survey_Question__c quesObjAftrUpdt = [SELECT Id,Answer_Option__c FROM Survey_Question__c WHERE Id =: surveyQuesObj.Id];
        System.assertEquals(quesObjAftrUpdt.Answer_Option__c,'Updated Optn');
    }
    @isTest
    public static void deleteSurveyAnsr(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        //surveyObj.Grouping__c = 'Group_1';
        insert surveyObj;
        System.assert(surveyObj.id!= null);
        //insert Survey Question Record
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'Picklist' ;
        insert surveyQuesObj;
        System.assert(surveyQuesObj.id!= null);
        //insert Survey Answer Record
        Survey_Answer__c surveyAnsrObj = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id);
        insert surveyAnsrObj;
        System.assert(surveyAnsrObj.id!= null);
        Survey_Answer__c surveyAnsrObj1 = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id);
        insert surveyAnsrObj1;
        System.assert(surveyAnsrObj1.id!= null);
        Test.startTest();
        delete surveyAnsrObj;
        Test.stopTest();
    }
    @isTest
    public static void unDeleteSurveyAnsr(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUS');
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        //surveyObj.Grouping__c = 'Group_1';
        insert surveyObj;
        System.assert(surveyObj.id!= null);
        //insert Survey Question Record
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'Picklist' ;
        insert surveyQuesObj;
        System.assert(surveyQuesObj.id!= null);
        //insert Survey Answer Record
        Survey_Answer__c surveyAnsrObj = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id);
        insert surveyAnsrObj;
        System.assert(surveyAnsrObj.id!= null);
        Survey_Answer__c surveyAnsrObj1 = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id);
        insert surveyAnsrObj1;
        System.assert(surveyAnsrObj1.id!= null);
        delete surveyAnsrObj;
        Test.startTest();
        undelete surveyAnsrObj;
        Test.stopTest();
    }
}