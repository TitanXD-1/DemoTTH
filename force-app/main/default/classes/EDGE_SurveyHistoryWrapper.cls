/**********************************************************************
Name: EDGE_SurveyHistoryWrapper
=======================================================================
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder        22/04/2021        ES20-10062

***********************************************************************/


global inherited sharing class EDGE_SurveyHistoryWrapper{
    public string outletSurveyId {get;set;}
    public string outletSurveyName {get;set;}
    public string surveyRecordTypeName {get;set;}
    public string surveyId {get;set;}
    public string callPerformedByName {get;set;}
    public date oSurveyCompDate {get;set;}
    public string outletId {get;set;}
}