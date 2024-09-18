/*
 * @name: D1_ContentController
 * @description : D1_ContentController Class for HomePage HeroImage section in d1HeroImageCustomBanner LWC component
 * @History
 * VERSION      AUTHOR           DATE       DETAIL
 * 1.0          Sudipta Nandi    08/29/20   Fetch CMS Content details based on "contentId", "contentType", and "language" 
 * 2.0          Prasanth T       09/10/23   Update PMD Fixes(146281)
 **/

public with sharing class D1_ContentController {
    
    /**
     * @description Fecthing Content Details from d1HeroImageCustomBanner
     * @param contentId 
     * @param contentType
     * @param language 
     * @return D1_ContentWrapperClass
     **/
    @AuraEnabled(cacheable=true)
    public static D1_ContentWrapperClass getContentDetails(String contentId, 
                                                           String contentType, 
                                                           String language, 
                                                           String communityId) {
        String userType = getUserType();
        
        D1_ContentWrapperClass wrapperContext = new D1_ContentWrapperClass();
        Map<String, ConnectApi.ManagedContentNodeValue> results= new Map<String, ConnectApi.ManagedContentNodeValue>();                                                
        if(communityId == null && String.isEmpty(communityId)){
            communityId = Network.getNetworkId();
        }
        List<String> contentIdsWithKey = new List<String>();
        List<String> contentIdsWithOutKey = new List<String>();
        if(contentId != NULL && contentId.startsWith('20Y')) {
            contentIdsWithOutKey.add(contentId);
        } else {
            contentIdsWithKey.add(contentId);
        }
        try{
            ConnectApi.ManagedContentVersionCollection contentList;
            if(contentIdsWithOutKey != NULL && contentIdsWithOutKey.size()>0) {
                contentList = ConnectApi.ManagedContent.getManagedContentByIds(communityId, contentIdsWithOutKey, 0, 25, language, contentType);
            } else if(contentIdsWithKey != NULL && contentIdsWithKey.size()>0) {
                contentList = ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentIdsWithKey, 0, 25, language, contentType,true);
            }
            string contentURL;
            string contentKey;
            if(contentList.items != null && !contentList.items.isEmpty()){
                results = contentList.items[0].contentNodes;contentURL = contentList.items[0].contentUrlName;contentKey = contentList.items[0].contentKey; 
            }
            Map<String, object> objVal  = (Map<String, object>)json.deserializeUntyped(json.serialize(results));
            
            wrapperContext = processResult(objVal,contentURL,contentKey,userType);
        }
        catch(ConnectApi.ConnectApiException e){
            wrapperContext = new D1_ContentWrapperClass(); 
            wrapperContext.headerValue = ''; 
            wrapperContext.subHeaderValue = ''; 
            wrapperContext.imageUrl = ''; 
            wrapperContext.bodyText = ''; 
            wrapperContext.excerptText = ''; 
            wrapperContext.errorMessage = e.getMessage();
        } 
        return wrapperContext;
    }
    
    public static D1_ContentWrapperClass processResult(Map<String, object> objVal,
                                                       String contentURL,
                                                       String contentKey,
                                                       String userType){
        D1_ContentWrapperClass wrapperContext = new D1_ContentWrapperClass();
        
        for(String key : objVal.keySet()){
            Map<String, Object> elementsObjMap = (Map<String, Object>)objVal.get(key);
            
            if(elementsObjMap.containsKey('value')){
                if(key == 'Title'){ wrapperContext.headerValue = String.valueOf(elementsObjMap.get('value'));}                    
                if(key == 'Subtitle' || key == 'SubHeading'){ wrapperContext.subHeaderValue = String.valueOf(elementsObjMap.get('value'));}                    
                if(key == 'Body'){ wrapperContext.bodyText = String.valueOf(elementsObjMap.get('value'));}                    
                if(key == 'Excerpt') {wrapperContext.excerptText = (String)elementsObjMap.get('value');}                    
                if(key == 'SignUpURL') {wrapperContext.signUpUrl = String.valueOf(elementsObjMap.get('value'));}

                //if(userType=='Direct Buyer'){
                    if(userType=='Direct Buyer' && key == 'DirectCustomer1stCTALabel'){wrapperContext.DirectCustomer1stCTALabel = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Direct Buyer' && key == 'DirectCustomers1stCTAURL'){ wrapperContext.DirectCustomers1stCTAURL = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Direct Buyer' && key == 'DirectCustomer2ndCTALabel'){ wrapperContext.DirectCustomer2ndCTALabel = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Direct Buyer' && key == 'DirectCustomers2ndCTAURL'){ wrapperContext.DirectCustomers2ndCTAURL = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Direct Buyer' && key == 'DirectCustomerCTALabel'){ wrapperContext.DirectCustomerCTALabel = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Direct Buyer' && key == 'DirectCustomersCTAURL'){wrapperContext.DirectCustomersCTAURL = String.valueOf(elementsObjMap.get('value'));}
                //}
                //else if(userType=='Outlet/Retailers'){
                    else if(userType=='Outlet/Retailers' && key == 'IndirectCustomers1stCTALabel'){ wrapperContext.IndirectCustomers1stCTALabel = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Outlet/Retailers' && key == 'IndirectCustomers1stCTAURL'){ wrapperContext.IndirectCustomers1stCTAURL = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Outlet/Retailers' && key == 'IndirectCustomers2ndCTALabel'){ wrapperContext.IndirectCustomers2ndCTALabel = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Outlet/Retailers' && key == 'IndirectCustomers2ndCTAURL'){ wrapperContext.IndirectCustomers2ndCTAURL = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Outlet/Retailers' && key == 'IndirectCustomersCTALabel'){ wrapperContext.IndirectCustomersCTALabel = String.valueOf(elementsObjMap.get('value'));}
                    else if(userType=='Outlet/Retailers' && key == 'IndirectCustomersCTAURL'){ wrapperContext.IndirectCustomersCTAURL = String.valueOf(elementsObjMap.get('value'));}
                //}
            }
            if(elementsObjMap.containsKey('url')){
                wrapperContext.imageUrl = String.valueOf(elementsObjMap.get('url'));
            }
            wrapperContext.contentSlugText = contentURL;
            wrapperContext.contentkeyText = contentKey; 
        }
        return wrapperContext;
    }
    
    /**
     * @description Get content from Connectapi and return just required nodes in resposne
     * @param communityId 
     * @param contentIds 
     * @param pageNumber 
     * @param pageSize 
     * @param language 
     * @param contentType 
     * @param nodesToCollect 
     * @return  `Map<String,Object>`
     */    
    public static Map<String,Object> getManagedContentInfoByIds( String communityId, 
                                                                List<String> contentIds, 
                                                                Integer pageNumber, 
                                                                Integer pageSize, 
                                                                String language, 
                                                                String contentType, 
                                                                Set<String> nodesToCollect ){
        Map<String,Object> contentMap = new Map<String,Object>();
        
        try{
            final String defaultContentType = 'DiageoOneContent';
            
            if(communityId == null && String.isEmpty(communityId)){
                communityId = Network.getNetworkId();
            }
            
            language = String.isBlank(language) ? UserInfo.getLanguage() : language;
            contentType = String.isBlank(contentType) ?
            defaultContentType : contentType;
            
            ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getManagedContentByIds(communityId,
                                                                                                                     contentIds,
                                                                                                                     pageNumber,
                                                                                                                     pageSize,
                                                                                                                     language,
                                                                                                                     contentType
                                                                                                                    );
            
            if(collection == null || collection.items == null || collection.items.isEmpty() ){
                return contentMap;
            }
            
            Map<Id, ConnectApi.ManagedContentVersion> mapOfContentIdItem = new Map<Id, ConnectApi.ManagedContentVersion>();
            for (ConnectApi.ManagedContentVersion item : collection.items) { 
                mapOfContentIdItem.put(item.managedContentId, item);
            }
            
            for (Id contentId: contentIds) { 
                ConnectApi.ManagedContentVersion item = mapOfContentIdItem.get(contentId); 
                if(item == null){ 
                    continue; 
                }
                
                Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = item.contentNodes;
                Map<String, Object> nodeNameDataMap = new Map<String, Object>();
                for( String nodeName : nodesToCollect ){ 
                    ConnectApi.ManagedContentNodeValue nodeValue = contentNodes.get(nodeName);
                    if(nodeValue == null){
                        continue;
                    } 
                    nodeNameDataMap.put(nodeName, nodeValue);
                }
                contentMap.put(contentId, nodeNameDataMap);
            }
        }catch( Exception e ){
            System.debug(LoggingLevel.ERROR, e.getMessage()+' : '+e.getStackTraceString());
        }
        
        return contentMap;
    }
    
    /**
     * @userstory : NCP- 3541
     * @description 
     * @param contentIds 
     * @param language 
     * @param communityId 
     * @return  `List<D1_ContentWrapperClass>`
     */    
    @AuraEnabled(cacheable=true)
    public static List<D1_ContentWrapperClass> getContents(List<String> contentIds, 
                                                           String language, 
                                                           String communityId) {
        List<D1_ContentWrapperClass> wrapperContextList = new List<D1_ContentWrapperClass>();
        Map<String, ConnectApi.ManagedContentNodeValue> results= new Map<String, ConnectApi.ManagedContentNodeValue>();
        if(communityId == null && String.isEmpty(communityId)){
            communityId = Network.getNetworkId();
        }
        List<String> contentIdsWithKey = new List<String>();
        List<String> contentIdsWithOutKey = new List<String>();
        
        for(string contentId : contentIds){
            if(contentId != NULL && contentId.startsWith('20Y')) {
                contentIdsWithOutKey.add(contentId);
            } else {
                contentIdsWithKey.add(contentId);
            }   
        }
        
        try{
            ConnectApi.ManagedContentVersionCollection contentList;
            if(contentIdsWithOutKey != NULL && contentIdsWithOutKey.size()>0) {
                contentList = ConnectApi.ManagedContent.getManagedContentByIds(communityId, contentIdsWithOutKey, 0, 25, language, null);
            } else if(contentIdsWithKey != NULL && contentIdsWithKey.size()>0) { 
                contentList = ConnectApi.ManagedContent.getManagedContentByContentKeys(communityId, contentIdsWithKey, 0, 25, language, null,false);
            }         
            string contentURL;
            string contentKey; 
            
            Map<Id, ConnectApi.ManagedContentVersion> mapOfContentIdItem = new Map<Id, ConnectApi.ManagedContentVersion>();
            for (ConnectApi.ManagedContentVersion item : contentList.items) {
                mapOfContentIdItem.put(item.managedContentId, item);
            }
            for(string contentId : contentIds){                                  
                D1_ContentWrapperClass wrapperContext = new D1_ContentWrapperClass();
                wrapperContext.isExternalUrl = false;
                ConnectApi.ManagedContentVersion item = mapOfContentIdItem.get(contentId);
                if(item == null){
                    continue;
                }
                results = item.contentNodes; contentURL = item.contentUrlName; contentKey = item.contentKey; 
                
                Map<String, object> objVal  = (Map<String, object>)json.deserializeUntyped(json.serialize(results));
                
                for(String key : objVal.keySet())
                {
                    Map<String, Object> elementsObjMap = (Map<String, Object>)objVal.get(key);
                    
                    if(elementsObjMap.containsKey('value'))
                    {
                        if(key == 'Title'){ wrapperContext.headerValue = String.valueOf(elementsObjMap.get('value'));}
                        if(key == 'Subtitle' || key == 'SubHeading'){ wrapperContext.subHeaderValue = String.valueOf(elementsObjMap.get('value'));}
                        if(key == 'Body'){ wrapperContext.bodyText = String.valueOf(elementsObjMap.get('value')); }
                        if(key == 'Excerpt'){ wrapperContext.excerptText = (String)elementsObjMap.get('value');}
                        if(key == 'SignUpURL'){ wrapperContext.signUpUrl = String.valueOf(elementsObjMap.get('value'));}
                        if(key == 'Content_URL'){ wrapperContext.content_URL = String.valueOf(elementsObjMap.get('value'));wrapperContext.isExternalUrl = true; }
                    }
                    if(elementsObjMap.containsKey('url')) {
                        wrapperContext.imageUrl = String.valueOf(elementsObjMap.get('url'));
                        wrapperContext.contentSlugText = contentURL;
                        wrapperContext.contentkeyText = contentKey;
                        wrapperContext.contentType = item.type;
                    }
                } 
                wrapperContextList.add(wrapperContext);
            }
        }
        catch(ConnectApi.ConnectApiException e){
            wrapperContextList = new List<D1_ContentWrapperClass>();
        }
        return wrapperContextList;
    } 

    public static string getUserType(){
        User usr = [SELECT Id, D1_User_Type__c FROM User WHERE Id =:UserInfo.getUserId()];
        
        return usr != null ? usr.D1_User_Type__c : '';
    }
}