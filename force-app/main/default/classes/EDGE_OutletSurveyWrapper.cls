/**********************************************************************
Name: EDGE_OutletSurveyWrapper
=======================================================================
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE              DETAIL
1.0         Dipanjan Das        2/04/2019        
2.0         Manikant Prasad	    09/12/2019       ES20-6133 
***********************************************************************/

global with sharing class EDGE_OutletSurveyWrapper{
    public string outletId {get;set;}
    public string surveyId {get;set;}
    public Date surveyStartDate {get;set;}
    public Date surveyEndDate {get;set;}
    
    public EDGE_OutletSurveyWrapper(){
    }
}