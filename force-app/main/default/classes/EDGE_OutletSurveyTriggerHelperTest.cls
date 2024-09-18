/**********************************************************************
Name: EDGE_OutletSurveyTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR               DATE            DETAIL
1.0         Moanlisa Halder     04/04/2019     Test Class for EDGE_OutletSurveyTriggerHelper
2.0         Swaraj Samanta      05/09/2022     Test Class Correction due to Failure(ES20-13284)
3.0         Sakshi Shah         21/05/2024     PMD Fix
***********************************************************************/
@isTest
public class EDGE_OutletSurveyTriggerHelperTest{
    
    @isTest
    public static void testcreateOutletSurveyWithResponse(){
     EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId, 'Outlet Visit Prioritization');
        insert pOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        insert outlet;
        Test.startTest();
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(geographyId);
        survey.Global_Equivalent_Business_Roles__c = 'Sales Rep';
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
        
        Outlet_Survey__c otSurvey1 = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outlet.Id);
        insert otSurvey1;
        delete otSurvey1;
        system.assertEquals(otSurvey.Id, otSurveyRes.Outlet_Survey__c,'Outlet Survey Id and Outlet Survey Response are not equal.');
        Test.stopTest();
    }
}