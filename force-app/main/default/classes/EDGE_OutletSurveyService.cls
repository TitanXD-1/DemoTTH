/**********************************************************************
Name: EDGE_OutletSurveyService
======================================================================================
Req: The requirement is to build Custom API for mobile to get Closed Opportunity Data
User Story : ES20-927
=======================================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                DATE              DETAIL
1.0       Monalisa Halder       17/04/2019        ES20-927 
2.0       Monalisa Halder       23/04/2021        ES20-10062
***********************************************************************/

@RestResource(urlMapping='/OutletSurveyService/*')
global with sharing class EDGE_OutletSurveyService{

    @HttpGet
    global static List<EDGE_SurveyHistoryWrapper> doGet() {
        Id userId = RestContext.request.params.get('userid');
        
        List<EDGE_SurveyHistoryWrapper> surveyHistoryWrapperList = new List<EDGE_SurveyHistoryWrapper>();
        if(userId != null){
            surveyHistoryWrapperList = EDGE_BriefcaseController.getLastSurveys(userId);
        }  
        return surveyHistoryWrapperList;
    }
    
    
}