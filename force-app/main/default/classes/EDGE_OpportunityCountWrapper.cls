/**********************************************************************
Name: EDGE_OpportunityCountWrapper
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Amar Deep			    18/12/2020		  ES20-9158 
***********************************************************************/
global inherited sharing class EDGE_OpportunityCountWrapper {
    
    public String outletId {get;set;}
    public Integer openOppsCount {get;set;}
    public Integer closedOppsCount {get;set;}
    
}