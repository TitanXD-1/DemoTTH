/**********************************************************************
Name: EDGE_UserTerritoryKPIService
=======================================================================
Req: The requirement is to build Custom API for mobile to get KPI data for a 
particular Sales Rep  
User Story : ES20-636
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0      Sagar Barman      25/03/2019       Initial Development
***********************************************************************/
@RestResource(urlMapping='/UserTerritoryKPIService/*')
global class EDGE_UserTerritoryKPIService {
    
    @HttpGet
    global static List<EDGE_UserTerritoryKPIWrapper> doGet() {
        Id userId = RestContext.request.params.get('userid');
        
        //call EDGE_PrimaryTerritoryKPICalculation
        List<EDGE_UserTerritoryKPIWrapper> userTerritoryWrapperList = new List<EDGE_UserTerritoryKPIWrapper>();
        if(userId != null){
            userTerritoryWrapperList = EDGE_UserTerritoryKPICalculation.calculateTerritoryKPIs(userId);
        }
        return userTerritoryWrapperList;
    }
}