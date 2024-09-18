/*
*Name: EDGE_SurveyQuestionTriggerTest
*Purpose: This is the test class for SurveyQuestionTriggerHandler
*SurveyQuestionTrigger
*EDGE_SurveyQuestionTriggerHelper
*History                                                            
                                                          
VERSION		AUTHOR			DATE			DETAIL
1.0			Preyanka Ghosh	10/01/2020		Initial Development
1.1			Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/
@isTest
public class EDGE_SurveyQuestionTriggerTest {
    
    /*
Method  : checkDupSurveyKPITest
Purpose : This methods used will check whether same KPI type of 2 
different Survey question can be added for a single survey or not
*/
    @isTest
    public static void checkDupSurveyKPITest() {
        List<Pick_Up_Options__c> lstPickUpOpt = new List<Pick_Up_Options__c>();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Test.startTest();
        
        Id defaultId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c pickUpOpt = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpOpt.RecordTypeId = defaultId;
        lstPickUpOpt.add(pickUpOpt);
        
        Pick_Up_Options__c pickUpBeer = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpBeer.RecordTypeId = defaultId;
        pickUpBeer.Name = 'Beer[AUT]';
        lstPickUpOpt.add(pickUpBeer);        
        insert lstPickUpOpt;
        
        //Insert Survey
        Id outletSurveyId = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Outlet Survey').getRecordTypeId();
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        surveyObj.RecordTypeId = outletSurveyId;
        surveyObj.Start_Date__c  = System.today();
        insert surveyObj;
        System.assert(surveyObj != null,'surveyObj should not be null ');
        
        //Insert Survey Question Record
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'RadioButton' ;
        surveyQuesObj.Survey_KPI__c = pickUpOpt.Id;
        surveyQuesObj.Active__c = True;
        insert surveyQuesObj;
        
        Survey_Question__c surveyQues1 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQues1.Response_Type__c = 'RadioButton' ;
        surveyQues1.Survey_KPI__c = pickUpBeer.Id;
        surveyQues1.Active__c = True;
        insert surveyQues1;
        
        Survey_Question__c surveyQues2 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQues2.Response_Type__c = 'RadioButton' ;
        surveyQues2.Survey_KPI__c = pickUpBeer.Id;
        surveyQues2.Active__c = True;
        try{
            insert surveyQues2;            
        } catch(Exception ex) {
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
            
        }       
        
        Test.stopTest();
        
    }
    
    /*
Method  : checkDupSurveyKPITest
Purpose : This methods used will check whether same KPI type of 2 
different Survey question can be added for a single survey or not 
in same transaction
*/
    @isTest
    public static void checkDupKPITest() {
        List<Pick_Up_Options__c> lstPickUpOpt = new List<Pick_Up_Options__c>();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Test.startTest();
        
        Id defaultId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c pickUpBeer = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpBeer.RecordTypeId = defaultId;
        pickUpBeer.Name = 'Beer[AUT]';
        lstPickUpOpt.add(pickUpBeer);        
        
        Pick_Up_Options__c pickUpBeer1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpBeer1.RecordTypeId = defaultId;
        pickUpBeer1.Name = 'Rum[AUT]';
        lstPickUpOpt.add(pickUpBeer1);    
        
        
        Pick_Up_Options__c pickUpBeer2 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpBeer2.RecordTypeId = defaultId;
        pickUpBeer2.Name = 'Rum1[AUT]';
        lstPickUpOpt.add(pickUpBeer2);    
        insert lstPickUpOpt;
        
        //Insert Survey
        Id outletSurveyId = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Outlet Survey').getRecordTypeId();
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        surveyObj.RecordTypeId = outletSurveyId;
        surveyObj.Start_Date__c  = System.today();
        insert surveyObj;
        System.assert(surveyObj != null,'surveyObj should not be null');
        
        //Insert Survey Question Record
        List<Survey_Question__c> lstSurveyQus = new List<Survey_Question__c>();
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'RadioButton' ;
        surveyQuesObj.Survey_KPI__c = pickUpBeer.Id;
        surveyQuesObj.Active__c = True;
        lstSurveyQus.add(surveyQuesObj);
        insert surveyQuesObj;
        
        
        /*Survey_Question__c surveyQuesObjs = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObjs.Response_Type__c = 'RadioButton' ;
        surveyQuesObjs.Survey_KPI__c = pickUpBeer.Id;
        surveyQuesObjs.Active__c = True;
        lstSurveyQus.add(surveyQuesObjs);
        insert surveyQuesObjs;*/
     
        Survey_Question__c surveyQuesObj2 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj2.Response_Type__c = 'RadioButton' ;
        surveyQuesObj2.Survey_KPI__c = pickUpBeer1.Id;
        surveyQuesObj2.Active__c = True;
        //lstSurveyQus.add(surveyQuesObj);
        insert surveyQuesObj2;
        
        Survey_Question__c surveyQues1 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQues1.Response_Type__c = 'RadioButton' ;
        surveyQues1.Survey_KPI__c = pickUpBeer2.Id;
        surveyQues1.Parent_Question__c = surveyQuesObj.Id;
        surveyQues1.Parent_Answer_Option__c = 'Yes';
        surveyQues1.Active__c = True;
        //lstSurveyQus.add(surveyQues1);
        insert surveyQues1;
        surveyQues1.Parent_Question__c = surveyQuesObj2.Id;
        surveyQues1.Parent_Answer_Option__c = 'No';
        update surveyQues1;
        delete surveyQues1;
        Undelete surveyQues1;
        
        
        //Insert Survey Answer Record
        List<Survey_Answer__c> lstSurveyAns = new List<Survey_Answer__c>();
        Survey_Answer__c surveyAnsObj = EDGE_UtilityTestClass.getSurveyAnsr(surveyQuesObj.Id);
        lstSurveyAns.add(surveyAnsObj);
        
        Survey_Answer__c surveyAnsObj1 = EDGE_UtilityTestClass.getSurveyAnsr(surveyQues1.Id);
        lstSurveyAns.add(surveyAnsObj1);
        
        try{
            //insert lstSurveyQus;
            insert lstSurveyAns;
        } catch(Exception ex) {
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
            
        }
        Test.stopTest();
    }
    
    /*
Method  : checkDupSurveyKPITest
Purpose : This methods used will check whether update KPI with same works
*/
    @isTest
    public static void updateSurveyKPITest() {
        List<Pick_Up_Options__c> lstPickUpOpt = new List<Pick_Up_Options__c>();
        Id countryID = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        Test.startTest();
        
        Id defaultId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c pickUpOpt = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpOpt.RecordTypeId = defaultId;
        lstPickUpOpt.add(pickUpOpt);
        
        Pick_Up_Options__c pickUpBeer = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpBeer.RecordTypeId = defaultId;
        pickUpBeer.Name = 'Beer[AUT]';
        lstPickUpOpt.add(pickUpBeer);
        
        Pick_Up_Options__c pickUpWhisky = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpWhisky.RecordTypeId = defaultId;
        pickUpWhisky.Name = 'Whisky[AUT]';
        lstPickUpOpt.add(pickUpWhisky);        
        insert lstPickUpOpt;
        
        //Insert Survey
        Id outletSurveyId = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Outlet Survey').getRecordTypeId();
        Survey__c surveyObj = EDGE_UtilityTestClass.getSurvey(countryID);
        surveyObj.RecordTypeId = outletSurveyId;
        surveyObj.Start_Date__c  = System.today();
        insert surveyObj;
        System.assert(surveyObj != null,'surveyObj should not be null');
        
        //Insert Survey Question Record
        List<Survey_Question__c> lstSurveyQus = new List<Survey_Question__c>();
        Survey_Question__c surveyQuesObj = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQuesObj.Response_Type__c = 'RadioButton' ;
        surveyQuesObj.Survey_KPI__c = pickUpBeer.Id;
        surveyQuesObj.Active__c = True;
        lstSurveyQus.add(surveyQuesObj);
        
        Survey_Question__c surveyQues1 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQues1.Response_Type__c = 'RadioButton' ;
        surveyQues1.Survey_KPI__c = pickUpOpt.Id;
        surveyQues1.Active__c = True;
        lstSurveyQus.add(surveyQues1); 
        insert lstSurveyQus; 
        surveyQues1.Survey_KPI__c = pickUpWhisky.Id;
        update surveyQues1;
        
        Survey_Question__c surveyQues2 = EDGE_UtilityTestClass.getSurveyQuestion(surveyObj.Id);
        surveyQues2.Response_Type__c = 'RadioButton' ;
        surveyQues2.Survey_KPI__c = pickUpOpt.Id;
        surveyQues2.Active__c = True;
        insert surveyQues2;
        
        surveyQues1.Survey_KPI__c = pickUpBeer.Id;
        
        try{
            update surveyQues1;          
        } catch(Exception ex) {
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
            
        }
        Test.stopTest();
    }
}