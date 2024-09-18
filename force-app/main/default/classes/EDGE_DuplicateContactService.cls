/**********************************************************************
Name: EDGE_DuplicateContactService
=======================================================================
Purpose: This class is needed to build Custom API for mobile to 
validate contacts for duplicates
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandip Ghosh      12/11/2019        ES20-6244

***********************************************************************/
@RestResource(urlMapping='/ContactDupCheckService/*')
global without sharing class EDGE_DuplicateContactService {
    
    @HttpPost
    global static EDGE_DuplicateContactServiceWrapper doPost(){
        
        EDGE_DuplicateContactServiceWrapper conOuterWrapper = new EDGE_DuplicateContactServiceWrapper();
        RestRequest req;
        String requestBody;
        List<Map<String,Object>> finalDeserializedList = new List<Map<String,Object>>();
        
        if(RestContext.request != null){
            req = RestContext.request;
            if(req != null){
                requestBody = req.requestBody.toString();
                System.debug('requestBody = '+ requestBody);
            }
        }
        
        if(requestBody != null){
            List<Object> deserializedList = (List<Object>)JSON.deserializeUntyped(requestBody);
            
            if(deserializedList != null && deserializedList.size()>0){
                for(Object listEntry : deserializedList){
                    Map<String,Object> listEntryItm = (Map<String,Object>)listEntry;
                    finalDeserializedList.add(listEntryItm);
                }
            }
            
            if(finalDeserializedList != null && finalDeserializedList.size() > 0){
                conOuterWrapper = EDGE_DuplicateContactServiceHelper.validateContacts(finalDeserializedList);    
            }            
        }        
        return conOuterWrapper;
    }
}