/**********************************************************************
Name: EDGE_BriefcaseWrapper
=======================================================================
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder        17/04/2019        
2.0         Monalisa Halder        02/05/2019         ES20-1208 
3.0         Monalisa Halder        23/04/2021      ES20-10062- removed the survey history vaiables
***********************************************************************/

global inherited sharing class EDGE_BriefcaseWrapper{
    public string callId {get;set;}
    public string callType {get;set;}
    public datetime callClosedDate {get;set;}
    public string callSalesRepName {get;set;}
    public string callSalesRepId {get;set;}
    public string opportunityId {get;set;}
    public string opportunityName {get;set;}
    public date oppClosedDate {get;set;}
    public string conDocumentId {get;set;}
    public string conVersionId {get;set;}
    public string outletId {get;set;}
    public string userId {get;set;}
    
    //Notes Variable
    public String noteId {get;set;}
    public String noteBody {get;set;}
    public String noteCreatedBy {get;set;}
    public String noteCreatedById {get;set;}
    public DateTime noteCreatedDate {get;set;}
    public DateTime noteLastModDate {get;set;}    
    public String noteParentId {get;set;}
    
    
    public EDGE_BriefcaseWrapper(){
    }
    
    
}