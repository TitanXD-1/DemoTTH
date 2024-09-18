/**********************************************************************
Name: SurveyQuestionTrggerHandlerTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Saurav Paul		 16/04/2019		 Test Class for SurveyQuestionTriggerHandler
***********************************************************************/
@isTest
public class SurveyQuestionTrggerHandlerTest {
    
    @isTest
    public static void testSurveyquestion(){
        Boolean guidNotNull = false;
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        
        Survey__c survey= EDGE_UtilityTestClass.getSurvey(countryId);
        insert survey;
        
        Survey_Question__c sq = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        test.startTest();
        
        insert sq;
        Survey_Question__c sq1 = [SELECT Id,GUID__c FROM Survey_Question__c WHERE ID =: sq.Id];
        if(sq1.GUID__c != Null){
            guidNotNull = true;
        }
        system.assert(guidNotNull, TRUE);
        
        sq.Order_Number__c= 10.2;
        // update survey question
        update sq;
        // delete survey question
        delete sq;
        // undelete survey question
        undelete sq;
        
        test.stopTest();
    }
    
}