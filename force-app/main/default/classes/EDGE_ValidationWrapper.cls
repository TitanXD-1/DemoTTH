/**********************************************************************
Name: EDGE_ValidationWrapper
=======================================================================
Req: Utility Class
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Monalisa Halder    01/02/2020        ES20-9212 

***********************************************************************/


// ES20-9212 : Field-Approval Flow Change in Field Permission_SFDC_Tech_Debt
public class EDGE_ValidationWrapper {
    
    public Map<Id, SObject> newItems {get; set;}
    public Map<Id, SObject> oldItems {get; set;}
    public Id outletRecordtypeId {get; set;}
    public Map<Id, Market_Setting__c> countryIdToMrkStngMap {get; set;}
    public String readOnlyErrorStr {get; set;} 
    public String mandatoryErrorStr {get; set;}
    public String relatedObjectName {get; set;}
    public Schema.DescribeSObjectResult sObjectDescReslt{get; set;} 
    public Map<Id, Id> childRecIdToCountryIdMap {get; set;}
    public Map<Id, Id> childRecIdToAccRecTypeIdMap {get; set;}
    public Map<String,String> metaDataReqdMap{get; set;}
    public Map<String, String> fieldAPINameToLabelMap{get; set;}
    
    //ES20-9212 : Field-Approval Flow Change in Field Permission_SFDC_Tech_Debt
    public Map<String,Field_Permission__c> fieldPermissionOutletMap;
    public Map<String,Field_Permission__c> fieldPermissionProspectMap;
    public Map<String,Field_Permission__c> fieldPermissionOtherMap;
    public Map<String,String> mapParentFieldsReturned;
    public Map<String,List<String>> mapDependentFieldsReturned;
   
    
}