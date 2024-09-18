/*
*   @Name: EDGE_CoachingSurveyResponseTest

*   @History                                                            
                                                          
*   VERSION   AUTHOR            DATE              DETAIL
    1.0       Amar Deep         20/09/2019        ES20-4407
*/
@isTest
public class EDGE_CoachingSurveyResponseTest {
    @isTest
    public static void coachingSurveyResponseTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Coaching_Report__c coachReport = new Coaching_Report__c();
        coachReport.Status__c = 'Draft';
        insert coachReport;
        system.assert(coachReport.Id != null,'coachReport should not be null');
        Coaching_Survey__c coachSurvey = new Coaching_Survey__c();
        coachSurvey.Coaching_Report__c= coachReport.Id;
        insert coachSurvey;
        Coaching_Survey_Response__c coachSurveyResp = new Coaching_Survey_Response__c();
        coachSurveyResp.Coaching_Survey__c = coachSurvey.Id;
        insert coachSurveyResp;
        coachSurveyResp.Response__c = 'Done';
        update coachSurveyResp;
        delete coachSurveyResp;
        undelete coachSurveyResp;
       
    }
}