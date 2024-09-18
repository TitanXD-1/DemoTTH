/**********************************************************************
Name: EDGE_CallNotesWrapper
=======================================================================
Req: 
ES20-623
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Preyanka Ghosh     23/04/2019      Initial Development
***********************************************************************/
public class EDGE_CallNotesWrapper {
    @AuraEnabled
    public String feedId {get;set;}
    @AuraEnabled
    public String feedBody {get;set;}
    @AuraEnabled
    public String feedType {get;set;}
    @AuraEnabled
    public String feedParentId {get;set;}
    @AuraEnabled
    public String feedParentName {get;set;}
    @AuraEnabled
    public String feedCreatedById {get;set;}
    @AuraEnabled
    public String feedCreatedByName {get;set;}
    @AuraEnabled
    public String feedCreatedByFirstName {get;set;}
    @AuraEnabled
    public String feedCreatedByLastName {get;set;}
    @AuraEnabled
    public DateTime feedCreatedDate {get;set;}    
    @AuraEnabled
    public String feedContentVerId {get;set;}    
    @AuraEnabled
    public List<ContentVersion> lstContentVersion{get;set;}    
}