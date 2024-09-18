/**********************************************************************
	Name: EDGE_DependentPicklistFetchService
================================================================================
    Req: The requirement is to build Custom API for mobile to get sObjects' dependent picklist Data
    User Story : ES20-1191
================================================================================
	History                                                            
-------                                                            
    VERSION   AUTHOR                   DATE              DETAIL
    1.0       Anuja Chattopadhyay      23/04/2019      Custom API for mobile to get sObjects' dependent picklist Data     
***********************************************************************/
@RestResource(urlMapping='/DependentPicklistFetchService/*')
global with sharing class EDGE_DependentPicklistFetchService {
    //Method Name : doGet
    //Description : this is used to fetch dependent picklist values
    @HttpGet
    global static list<EDGE_DepentdentPicklistFetchWrapper> doGet(){
        List<EDGE_DepentdentPicklistFetchWrapper> acctList = new List<EDGE_DepentdentPicklistFetchWrapper>();
        try{
            String objType = RestContext.request.params.get('objType');
            String parentField = RestContext.request.params.get('parentField');
            String chlField = RestContext.request.params.get('chlField');
            sObject obj = Schema.getGlobalDescribe().get(objType).newSObject();
            if(String.isNotBlank(objType) && String.isNotBlank(parentField) && String.isNotBlank(chlField)){
                Map<String,List<String>> dependentVal = EDGE_DependentPicklistFetchHelper.getDependentMap(obj,parentField,chlField);
                if(dependentVal!= null && !dependentVal.isEmpty()){ 
                    for(String parVal : dependentVal.keySet()){
                        if(dependentVal.values()!=null && !dependentVal.values().isEmpty()){
                            for(String chlVal : dependentVal.get(parVal)){  
                                EDGE_DepentdentPicklistFetchWrapper wrapObj = new EDGE_DepentdentPicklistFetchWrapper(parVal,chlVal);  
                                acctList.add(wrapObj);
                            }
                        }
                    } 
                    return acctList;
                } 
            }
            return null;     
            
        }Catch(Exception ex) {
            System.debug('===Exception in DependentPicklistFetchService=='+ex);
        }
        return null;    
    }   
}