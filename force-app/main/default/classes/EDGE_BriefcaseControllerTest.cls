/**
*@ Name: EDGE_BriefcaseControllerTest

*@ History                                                            
                                                      
*@ VERSION     AUTHOR               DATE            DETAIL
*@1.0         Dipanjan Das         19/04/2019      Test Class for EDGE_BriefcaseController apex class.

**/
@isTest
public class EDGE_BriefcaseControllerTest{
    
    
    public static User userRec;
    public static Account outlet;
    @isTest
    public static void testdoget(){
        Test.startTest();
        createData();
        EDGE_BriefcaseController.getVisitDetails(userRec.Id, 'Notes');
        EDGE_BriefcaseController.getVisitDetails(userRec.Id, 'Call');
        EDGE_BriefcaseController.getVisitDetails(userRec.Id, 'Survey');
        EDGE_BriefcaseController.getNotesHistory(userRec.Id);
        EDGE_BriefcaseController.getLastSurveys(userRec.Id);
        EDGE_BriefcaseController.getCallHistory(userRec.Id);
        EDGE_BriefcaseController.getOpportunitiesClosed(userRec.Id);
        system.assert(outlet.Id != null,'Outlet should not be null');
        Test.stopTest();
        
    }   
    
    public static void createData(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');       
        
        userRec = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert userRec;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        Call__c callRec = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        insert callRec;
        System.assert(callRec.Id != null,'callRec should not be null');
        
        ContentVersion conVerRec = EDGE_UtilityTestClass.gerConVerRec('Test.pdf');
        conVerRec.Content_Type__c = 'Other';
        insert conVerRec;
        System.assert(conVerRec.Id != null,'conVerRec should not be null');
        
        FeedItem feed = EDGE_UtilityTestClass.getFeedItem('feed post 1', 'textPost', outlet.Id);
        insert feed;
        
        FeedItem secFeed = EDGE_UtilityTestClass.getFeedItem('feed post 2', 'contentPost', callRec.Id);
        secFeed.RelatedRecordId = conVerRec.Id;
        insert secFeed;
        
        FeedItem thirdFeed = EDGE_UtilityTestClass.getFeedItem('feed post 3', 'textPost', callRec.Id);
        insert thirdFeed;
        
        FeedItem forthFeed = EDGE_UtilityTestClass.getFeedItem('feed post 4', 'contentPost', outlet.Id);
        forthFeed.RelatedRecordId = conVerRec.Id;
        insert forthFeed;
        
        insert EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id,userRec.Id,'Primary'); 
        
        Market_Setting__c marketSettingRec = EDGE_UtilityTestClass.getMarketSetting(countryId);     
        marketSettingRec.Notes_History_Last_Visits__c = 10;
        marketSettingRec.Call_History_Last_Visits__c = 20;
        insert marketSettingRec;
        
        Survey__c surveyRec = EDGE_UtilityTestClass.getSurvey(countryId);
        insert surveyRec;
        
        Outlet_Survey__c outletSurvey =  EDGE_UtilityTestClass.getOutletSurvey(surveyRec.Id, outlet.Id);
        outletSurvey.Call__c = callRec.Id;
        outletSurvey.Achievement_status__c = 'Complete';
        outletSurvey.Completion_Date__c = System.today();
        insert outletSurvey;
        
        Survey_Question__c surveyQuestion = EDGE_UtilityTestClass.getSurveyQuestion(surveyRec.Id);
        insert surveyQuestion;
        
        Outlet_Survey_Response__c outletSurveyResponse = EDGE_UtilityTestClass.getOutletSurveyRes(outletSurvey.Id, surveyQuestion.Id);
        insert outletSurveyResponse;
        
        
        Opportunity oppRec =  EDGE_UtilityTestClass.getOpportunity(outlet.Id);
        insert oppRec;
        
        
    }
}