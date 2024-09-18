/**********************************************************************
	Name: EDGE_DepentdentPicklistFetchWrapper
================================================================================
    Req: This wrapper is used to send data in DependentPicklistFetchService
================================================================================
    History                                                            
    -------                                                            
    VERSION   AUTHOR                   DATE              DETAIL
    1.0       Anuja Chattopadhyay      23/04/2019        Wrapper class used for DependentPicklistFetchService   
***********************************************************************/
global inherited sharing class EDGE_DepentdentPicklistFetchWrapper {
    public string parentValue {get;set;}
    public string childValue {get;set;}
    //Constructor
    global EDGE_DepentdentPicklistFetchWrapper(String parentValue,String childValue){
        this.parentValue = parentValue;
        this.childValue = childValue;
    }

}