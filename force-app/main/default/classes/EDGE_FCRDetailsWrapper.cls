/**
* @description EDGE_FCRDetailsWrapper
* @Purpose Wrapper Class for Field Change Request
* @history
                    
VERSION     AUTHOR            DATE              DETAIL
1.0.	Swaraj Samanta		27/09/2022		ES20-12995
**/
global with sharing class EDGE_FCRDetailsWrapper {
 	public string outletId {get;set;}
    public string outletName {get;set;}
    public string status {get;set;}
    public string createdById {get;set;}
    public string fieldName {get;set;} 
     public string id {get;set;} 
}