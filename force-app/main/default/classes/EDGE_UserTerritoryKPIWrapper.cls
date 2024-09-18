/**********************************************************************
Name: EDGE_UserTerritoryKPIWrapper 
=======================================================================
Req: 
ES20-633, ES20-634 - Metric Calculation at Territory Level 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
2.0       Dipanjan Das      25/03/2019        Wrapper Class to Store User Level KPIs for Outlet   

***********************************************************************/
global with sharing class EDGE_UserTerritoryKPIWrapper {
    
    public string kpiName {get;set;}
    public Decimal kpiValue {get;set;}
    public String userId{get;set;}
    
    public EDGE_UserTerritoryKPIWrapper(){
        
    }
}