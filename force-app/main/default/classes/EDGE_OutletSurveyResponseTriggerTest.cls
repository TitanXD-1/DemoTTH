/**********************************************************************
Name: EDGE_OutletSurveyResponseTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR               DATE            DETAIL
1.0         Moanlisa Halder     04/04/2019     Test Class for EDGE_OutletSurveyResponseTriggerHelper

***********************************************************************/
@isTest
public class EDGE_OutletSurveyResponseTriggerTest{
    
    @isTest
    public static void testcreateOutletSurveyResponse(){
     EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
		Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
        insert pOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        insert outlet; 
        
        Test.startTest();
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(geographyId);
        insert survey;
        
        
        Survey_Question__c surveyQues = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        insert surveyQues;
        
        Outlet_Survey__c otSurvey = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outlet.Id);
        insert otSurvey;
       
        
        Outlet_Survey_Response__c otSurveyRes = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey.Id,surveyQues.Id);
        insert otSurveyRes; 
        otSurvey.Achievement_status__c = 'Complete';
        otSurvey.Completion_Date__c = system.today();
        update otSurvey;
        
        Outlet_Survey_Response__c otSurveyRes1 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey.Id,surveyQues.Id);
        insert otSurveyRes1;
        update otSurveyRes1;
        delete otSurveyRes1;
        system.assertEquals(otSurvey.Id, otSurveyRes.Outlet_Survey__c);
        Test.stopTest();
    }
}