/*

*   @Name: EDGE_CoachingSurveyTriggerTest

*   @History                                                            
                                                         
*   VERSION   AUTHOR            DATE              DETAIL
    1.0       Shahbaz Khan   20 /09/2019        ES20-4406
*/
@isTest
public class EDGE_CoachingSurveyTriggerTest {
    @isTest
    public static void coachingSurveyTriggerTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Coaching_Report__c coachReport = new Coaching_Report__c();
        coachReport.Status__c = 'Draft';
        insert coachReport;
        Coaching_Survey__c coachSurvey = new Coaching_Survey__c();
        coachSurvey.Coaching_Report__c= coachReport.Id;
        insert coachSurvey;
        system.assert(coachSurvey.Id != null,'coachSurvey should not be null');
        coachSurvey.Status__c = 'Report Generated';
        update coachSurvey;
        delete coachSurvey;
        undelete coachSurvey;
       
    }
}