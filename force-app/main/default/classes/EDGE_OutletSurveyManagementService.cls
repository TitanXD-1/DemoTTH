/**********************************************************************
Name: EDGE_OutletSurveyManagementService
=======================================================================
Req: The requirement is to build Custom API for mobile to get Outlet Survey Data
User Story : ES20-700
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Dipanjan Das      3/04/2019           
***********************************************************************/

@RestResource(urlMapping='/OutletSurveyManagementService/*')
global class EDGE_OutletSurveyManagementService{

    @HttpGet
    global static List<EDGE_OutletSurveyWrapper> doGet() {
        Id userId = RestContext.request.params.get('userid');
        
        List<EDGE_OutletSurveyWrapper> outletSurveyWrapList = new List<EDGE_OutletSurveyWrapper>();
        if(userId != null){
            outletSurveyWrapList  = EDGE_OutletSurveyManagementController.getOutletSurveys(userId);
        }  
        return outletSurveyWrapList;
    }
    
    
}