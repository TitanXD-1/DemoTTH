/*
Name: EDGE_BriefCaseServiceTest
Req: This is the test class for EDGE_NotesHistoryService,EDGE_OutletSurveyService,
	EDGE_CallHistoryService,EDGE_OpportunityClosedService
*/

@isTest
public class EDGE_BriefCaseServiceTest {

  @isTest
    public static void testNotesHistoryService(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String requri='services/apexrest/NotesHistoryService?userid=';
            requri = requri+ String.valueOf(u.Id);
            req.requestUri =requri;
            req.params.put('userid', u.Id);            
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;
            EDGE_NotesHistoryService.doGet();
            List<EDGE_BriefcaseWrapper> briefcaseWrapper = EDGE_NotesHistoryService.doGet();
            system.assert(briefcaseWrapper != null,'Brief Case Wrapper should not be null');
        Test.stopTest();     
    }
    @isTest
    public static void testCallHistoryService(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String requri='services/apexrest/CallHistoryService?userid=';
            requri = requri+ String.valueOf(u.Id);
            req.requestUri =requri;
            req.params.put('userid', u.Id);            
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;
            EDGE_CallHistoryService.doGet();
            List<EDGE_BriefcaseWrapper> briefcaseWrapper = EDGE_CallHistoryService.doGet();
            system.assert(briefcaseWrapper != null,'Brief Case Wrapper should not be null');
        Test.stopTest();     
    }
    @isTest
    public static void testOutletSurveyService(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String requri='services/apexrest/OutletSurveyService?userid=';
            requri = requri+ String.valueOf(u.Id);
            req.requestUri =requri;
            req.params.put('userid', u.Id);            
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;
            EDGE_OutletSurveyService.doGet();
            List<EDGE_SurveyHistoryWrapper> briefcaseWrapper = EDGE_OutletSurveyService.doGet();
            system.assert(briefcaseWrapper != null,'Brief Case Wrapper should not be null');
        Test.stopTest();     
    }
    @isTest
    public static void testOpportunityClosedService(){
        
        User u  = EDGE_UtilityTestClass.runAsUser('SalesRep','Sales Representative');
        insert u;
        Test.startTest();
            RestRequest req = new RestRequest(); 
            RestResponse res = new RestResponse();
            String requri='services/apexrest/OpportunityClosedService?userid=';
            requri = requri+ String.valueOf(u.Id);
            req.requestUri =requri;
            req.params.put('userid', u.Id);            
            req.httpMethod = 'GET';
            RestContext.request = req;
            RestContext.response = res;
            EDGE_OpportunityClosedService.doGet();
            List<EDGE_BriefcaseWrapper> briefcaseWrapper = EDGE_OpportunityClosedService.doGet();
            system.assert(briefcaseWrapper != null,'Brief Case Wrapper should not be null');
        Test.stopTest();     
    }
}