/**********************************************************************
Name: EDGE_ContactShareService
=======================================================================
Purpose: This class is needed to build Custom API for mobile to 
share contacts with sales reps
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Sandip Ghosh      05/11/2020        ES20-7921

***********************************************************************/
@RestResource(urlMapping='/ContactShareService/*')
global class EDGE_ContactShareService {
    
    @HttpPost
    global static EDGE_ContactShareServiceWrapper doPost(){
        
        EDGE_ContactShareServiceWrapper conOuterWrapper = new EDGE_ContactShareServiceWrapper();
        RestRequest req;
        String requestBody;
        List<Map<String,Object>> finalDeserializedList = new List<Map<String,Object>>();
        Boolean isSuccess;
        
        try{
            if(RestContext.request != null){
                req = RestContext.request;
                if(req != null){
                    requestBody = req.requestBody.toString();
                }
            }
            System.debug('requestBody ='+ requestBody);
            if(requestBody != null){
                List<Object> deserializedList = (List<Object>)JSON.deserializeUntyped(requestBody);
                System.debug('deserializedList ='+ deserializedList);
                if(deserializedList != null && deserializedList.size()>0){
                    for(Object listEntry : deserializedList){
                        Map<String,Object> listEntryItm = (Map<String,Object>)listEntry;
                        finalDeserializedList.add(listEntryItm);
                    }
                }
                
                if(finalDeserializedList != null && finalDeserializedList.size() > 0){
                    conOuterWrapper = EDGE_ContactShareServiceHelper.shareContacts(finalDeserializedList);
                }
            }   
        }catch(Exception contShrException){
            System.debug('Exception details = '+ contShrException.getMessage());
            conOuterWrapper.isSuccess = false;
            if(contShrException.getMessage() != null){
                if(conOuterWrapper.errorMessage != null){
                    conOuterWrapper.errorMessage += contShrException.getMessage();
                }else{
                    conOuterWrapper.errorMessage = contShrException.getMessage();                
                }
            }
        }
        System.debug('conOuterWrapper = '+ conOuterWrapper);
        return conOuterWrapper;
    }
}