/**
* Class Name: EDGE_OutletSurveyRespWrapper

*  Version      Developer       Date           Detail
*    1.0       Rajarshi Lahiri 12/01/2023    [ES20-13499]Initial Development to create Wrapper
*/

public class EDGE_OutletSurveyRespWrapper {
    
    public Id outletid{get;set;}
    public Territory__c terr{get;set;}
    public Decimal totalNoofOutlets{get;set;}
    public Id question{get;set;}
    public String response{get;set;}
    public Pick_Up_Options__c surActkpi{get;set;}
    public Id survey{get;set;}

}