/**
 * @name : D1_DCHController
 * @description : Controller Class to do callout to DCH to Get Assets
 * @history :
 * VERSION          AUTHOR                  DATE            DETAIL
 * 1.0              Kapil Baliyan           01/09/2022      Initial Development (NCP-5611)
 * 2.0				Naresh Goud				10/05/2024		ADO-152971
 */
public with sharing class D1_DCHController {

    /**
     * Request Body
     * {
        "defaults": "DCHIntegrationsSearchConfiguration",
        "culture": "en-US",
        "skip": 0,
        "take": 1,
        "query": "",
        "filters": [{
                "name": "AvailableTo",
                "operator": "AnyOf",
                "type": "1",
                "values": ["Diageo One"]
            },
            {
                "name": "CreatedForMarket",
                "operator": "AnyOf",
                "type": "1",
                "values": ["GB"]
            },
            {
                "name": "Diageo.Category",
                "operator": "AnyOf",
                "type": "1",
                "values": ["Ciroc", "Smirnoff"]
            },{
                "name": "OccasionOrSeason",
                "operator": "AnyOf",
                "type": "1",
                "values": ["Celebrations"]
            },
            {
                "name": "M.AssetType",
                "operator": "AnyOf",
                "type": "1",
                "values": ["Logos and Icons"]
            },
            {
                "name": "MIMEType",
                "operator": "AnyOf",
                "type": "1",
                "values": ["image/jpeg", "video/mp4"]
            }
        ],
        "fulltext": ["70cl"],
        "view": "grid",
        "sorting": {
            "field": "modifiedon",
            "asc": false
        }
    }
     */

    public static final String MULESOFT_DETAILS_NAMED_CREDENTIAL = 'D1_MuleSoftDetails';
    public static final Integer PAGE_SIZE = 21;
    public static final String REPLACE_STRING = ';';

    
    @AuraEnabled(cacheable=true)
    public static DCHResponseWrapper getAssets(String contentId, Integer pageNumber, List<String> filter, String searchTerm){
        try {
            Id brandRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Brand').getRecordTypeId();
            Id eventRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
            String displayName = System.Label.D1_Assets;
            String sobjectName = '';
            List<String> mimeTypes = new List<String>();
            List<FilterWrapper> filterWrapperList = new List<FilterWrapper>();
            Map<String, String> mimeFileTypeMap = new Map<String, String>();
            Map<String, List<String>> assetSearchInput = new Map<String, List<String>>();

            //Get Logged In User Details
            User u = [SELECT Id, LanguageLocaleKey, Available_Countries__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
            //Get Country Name
            List<String> marketNames = getMarketNames(u.Available_Countries__c);
            List<String> availableCountry = u.Available_Countries__c.split(';');
            List<D1_Setting__c> d1Settings = [SELECT Market__c, Language__c, DCH_AvailableTo_Override_Value__c FROM D1_Setting__c 
                                                WHERE Market__r.Code__c IN :availableCountry AND Language__c =:u.LanguageLocaleKey]; //152971
            
            //1. Add AvailableTo to search input
            if(d1Settings != null && d1Settings.size()>0 && d1Settings.get(0).DCH_AvailableTo_Override_Value__c != NULL){ 
                assetSearchInput.put('AvailableTo', new List<String>{d1Settings.get(0).DCH_AvailableTo_Override_Value__c});//152971
            }else{
                assetSearchInput.put('AvailableTo', new List<String>{'Diageo One'});
            }
            
            //2. Add Country to search input
            if(!marketNames.isEmpty()){
                assetSearchInput.put('CreatedForMarket', marketNames);
            }
            
            //Get Custom Metadata for Filter
            for(D1_DCH_File_Type__mdt dchFileType : [SELECT Id, MasterLabel, File_Type__c, MIME_Type__c, Asset_Tile_Label__c FROM D1_DCH_File_Type__mdt WHERE D1_User_Locale_Setting__r.Country_Code__c = :availableCountry AND D1_User_Locale_Setting__r.LanguageLocaleKey__c = :u.LanguageLocaleKey ORDER BY Order_Number__c ASC]){
                //Create Filter Wrapper
                FilterWrapper fWrapper = new FilterWrapper();
                fWrapper.label = dchFileType.MasterLabel;
                fWrapper.value = dchFileType.File_Type__c;
                fWrapper.isChecked = filter.size()>0 && filter.contains(dchFileType.File_Type__c) ? true : false;
                
                filterWrapperList.add(fWrapper);
                
                if(String.isNotBlank(dchFileType.MIME_Type__c) && (filter.size()>0 && filter.contains(dchFileType.File_Type__c) || filter.isEmpty())){
                    //Add MIME Types to mimeTypes List
                    List<String> tempMIMETypes = (dchFileType.MIME_Type__c).split(REPLACE_STRING);
                    mimeTypes.addAll(tempMIMETypes);
                    
                    //Create MIME Type w/ File Type Map
                    for(String mimeType : tempMIMETypes){
                        mimeFileTypeMap.put(mimeType, dchFileType.Asset_Tile_Label__c);
                    }
                }
            }
            
            //3. Add MIME Type to search input
            if(!mimeTypes.isEmpty()){
                assetSearchInput.put('MIMEType', mimeTypes);
            }
            
            //Get sObjectName
            if(String.isNotBlank(contentId)){
                Schema.SObjectType sobjectType = Id.valueOf(contentId).getSObjectType();
                sobjectName = sobjectType.getDescribe().getName();
            }
            
            
            switch on sobjectName{
                when 'D1_Content_Assignment__c' {
                    List<D1_Content_Assignment__c> dContentAssignmentList = [SELECT Id, DCH_Asset_Tags__c, D1_Brand__c, D1_Brand__r.Name, D1_Event__c, D1_Event__r.Name, RecordTypeId FROM D1_Content_Assignment__c WHERE Id =:contentId];
                    
                    if(!dContentAssignmentList.isEmpty()){
                        D1_Content_Assignment__c dContentAssignment = dContentAssignmentList.get(0);
                        
                        //4. Add Brand to search input
                        if(dContentAssignment.RecordTypeId == brandRecordTypeId){
                            if(String.isNotBlank(dContentAssignment.DCH_Asset_Tags__c)){
                                List<String> brands = (dContentAssignment.DCH_Asset_Tags__c).split(REPLACE_STRING);
                                assetSearchInput.put('Diageo.Category', brands);
                            }

                            //Set Display Name
                            displayName = dContentAssignment.D1_Brand__r.Name;
                        }

                        //5. Add Occasion to search input
                        if(dContentAssignment.RecordTypeId == eventRecordTypeId){
                            if(String.isNotBlank(dContentAssignment.DCH_Asset_Tags__c)){
                                List<String> occasions = (dContentAssignment.DCH_Asset_Tags__c).split(REPLACE_STRING);
                                assetSearchInput.put('OccasionOrSeason', occasions);
                            }
                            
                            //Set Display Name
                            displayName = dContentAssignment.D1_Event__r.Name;
                        }
                    }
                }
                when 'D1_Download_Folder_Item__c' {
                    List<D1_Download_Folder_Item__c> dFItemList = [SELECT Id, toLabel(Type__c), DCH_Asset_Tags__c, D1_Content_Assignment__c, D1_Content_Assignment__r.D1_Brand__c, D1_Content_Assignment__r.D1_Brand__r.Name, 
                                                                    D1_Content_Assignment__r.D1_Event__c, D1_Content_Assignment__r.D1_Event__r.Name, D1_Content_Assignment__r.RecordTypeId, D1_Content_Assignment__r.DCH_Asset_Tags__c 
                                                                    FROM D1_Download_Folder_Item__c WHERE Id =:contentId];

                    if(!dFItemList.isEmpty()){
                        D1_Download_Folder_Item__c dFItem = dFItemList.get(0);

                        //4. Add Brand to search input
                        if(dFItem.D1_Content_Assignment__r.RecordTypeId == brandRecordTypeId){
                            if(String.isNotBlank(dFItem.D1_Content_Assignment__r.DCH_Asset_Tags__c)){
                                List<String> brands = (dFItem.D1_Content_Assignment__r.DCH_Asset_Tags__c).split(REPLACE_STRING);
                                assetSearchInput.put('Diageo.Category', brands);
                            }
                            displayName = dFItem.D1_Content_Assignment__r.D1_Brand__r.Name + ' ';
                        }

                        //5. Add Occasion to search input
                        if(dFItem.D1_Content_Assignment__r.RecordTypeId == eventRecordTypeId){
                            if(String.isNotBlank(dFItem.D1_Content_Assignment__r.DCH_Asset_Tags__c)){
                                List<String> occasions = (dFItem.D1_Content_Assignment__r.DCH_Asset_Tags__c).split(REPLACE_STRING);
                                assetSearchInput.put('OccasionOrSeason', occasions);
                            }
                            displayName = dFItem.D1_Content_Assignment__r.D1_Event__r.Name + ' ';
                        }

                        //6. Add Asset Type to search input
                        if(String.isNotBlank(dFItem.DCH_Asset_Tags__c)){
                            List<String> assetTypes = (dFItem.DCH_Asset_Tags__c).split(REPLACE_STRING);
                            assetSearchInput.put('M.AssetType', assetTypes);
                        }

                        //Set DisplayName
                        displayName += dFItem.Type__c;
                    }
                }
            }

            //Callout to DCH System
            DCHResponseWrapper dchResponseWrapper = getDCHAssets(assetSearchInput, pageNumber, mimeFileTypeMap, searchTerm);
            dchResponseWrapper.displayName = displayName;
            dchResponseWrapper.pageNumber = pageNumber;
            dchResponseWrapper.filterWrapperList = filterWrapperList;

            return dchResponseWrapper;
        } catch (Exception e) {
            System.debug(LoggingLevel.ERROR, + e.getStackTraceString());
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static List<String> getMarketNames(String countryCode){
        List<String> marketNames = new List<String>();
        List<String> availableCountry = countryCode.split(';');

        //Get Market Names from Geography
        for(Geography__c geo : [SELECT Id, Name, Code__c FROM Geography__c WHERE Code__c =:availableCountry]){
            if(geo.Code__c == 'GB'){
                marketNames.add(geo.Code__c);
            }else if(geo.Code__c == 'IE'){
                marketNames.add('Ireland');
            }else{
                marketNames.add(geo.Name);
            }
        }

        return marketNames;
    }

    @AuraEnabled
    public static DCHResponseWrapper getDCHAssets(Map<String, List<String>> assetSearchInput, Integer pageNumber, Map<String, String> mimeFileTypeMap, String searchTerm){
        try {
            //Create Request Body
            DCHRequestWrapper dchRequestWrapper = createRequest(assetSearchInput, pageNumber, searchTerm);

            //Do Callout
            HttpResponse httpResponse = doCallout(dchRequestWrapper);

            //Parse Response
            DCHResponseWrapper dchResponseWrapper = parseResponse(httpResponse, mimeFileTypeMap);

            return dchResponseWrapper;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }

    public static DCHRequestWrapper createRequest(Map<String, List<String>> assetSearchInput, Integer pageNumber, String searchTerm){
        String searchTermm = searchTerm;
        //If searchTerm contains whitespace append "" so that DCH treats it as a single string
        if(String.isNotBlank(searchTermm) && searchTermm.containsWhitespace()){
            searchTermm = '"' + searchTerm + '"';
            //searchTermm = searchTermm.escapeJava();
        }

        DCHRequestWrapper dchRequestWrapper = new DCHRequestWrapper();
        dchRequestWrapper.defaults = 'DCHIntegrationsSearchConfiguration';
        dchRequestWrapper.culture = 'en-US';
        dchRequestWrapper.skip = (pageNumber - 1) * PAGE_SIZE;
        dchRequestWrapper.take = PAGE_SIZE;
        dchRequestWrapper.query = '';
        dchRequestWrapper.filters = getFilters(assetSearchInput);
        dchRequestWrapper.fulltext = String.isNotBlank(searchTermm) ? new List<String>{searchTermm} : new List<String>();
        dchRequestWrapper.view = 'grid';
        dchRequestWrapper.sorting = getSorting();

        return dchRequestWrapper;
    }

    public static List<Filters> getFilters(Map<String, List<String>> assetSearchInput){
        List<Filters> filters = new List<Filters>();

        for(String key : assetSearchInput.keySet()){
            filters.add(createFilter(key, assetSearchInput.get(key)));
        }

        return filters;
    }

    public static Filters createFilter(String filterName, List<String> filterValue){
        Filters filter = new Filters();
        filter.name = filterName;
        filter.operator = 'AnyOf';
        filter.type = '1';
        filter.values = filterValue;

        return filter;
    }

    public static Sorting getSorting(){
        Sorting sorting = new Sorting();
        sorting.field = 'modifiedon';
        sorting.asc_Z = false;

        return sorting;
    }

    public static HttpResponse doCallout(DCHRequestWrapper dchRequestWrapper){
        HttpRequest httpRequest;
        HttpResponse httpResponse;

        try{
            //Get Custom Metadata Records
            Map<String, D1_Commerce_SAP_Setting__mdt> commerceSettingMap = D1_Commerce_SAP_Setting__mdt.getAll();

            String dchRequestWrapperStr = (JSON.serialize(dchRequestWrapper)).replace('asc_Z', 'asc');

            //Create Request
            httpRequest = new HttpRequest();
            httpRequest.setMethod('POST');
            httpRequest.setHeader('Content-Type','application/json');
            httpRequest.setEndpoint('callout:' + MULESOFT_DETAILS_NAMED_CREDENTIAL + '/' + commerceSettingMap.get('DCH_Asset').Value__c);
            httpRequest.setHeader('client_id',commerceSettingMap.get('DCH_Client_Id').Value__c);
            httpRequest.setHeader('client_secret',commerceSettingMap.get('DCH_Client_Secret').Value__c);
            httpRequest.setBody(dchRequestWrapperStr);
            httpRequest.setTimeout(120000);

            Http http = new Http();
            httpResponse = http.send(httpRequest);
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }

        return httpResponse;
    }

    public static DCHResponseWrapper parseResponse(HttpResponse httpResponse, Map<String, String> mimeFileTypeMap){
        DCHResponseWrapper dchResponseWrapper = new DCHResponseWrapper();
        List<AssetWrapper> assetWrapperList = new List<AssetWrapper>();
        Integer statusCode = httpResponse.getStatusCode();
        String responseBody = httpResponse.getBody();

        if (statusCode == 200) {
            D1_DCHResponse response = D1_DCHResponse.parse(responseBody);

            //Convert response into AssetWrapper
            if(response.items != null){
                for(D1_DCHResponse.Items item : response.items){
                    if(item.id != null && item.renditions != null){
                        assetWrapperList.add(createResponse(item, mimeFileTypeMap));
                    }
                }
            }

            //Create DCH Response Wrapper
            dchResponseWrapper.totalItemCount = response.totalItemCount;
            dchResponseWrapper.returnedItemCount = response.returnedItemCount;
            dchResponseWrapper.pageSize = PAGE_SIZE;
            dchResponseWrapper.assetWrapperList = assetWrapperList;
        }else{
            //Create DCH Response Wrapper
            dchResponseWrapper.totalItemCount = 0;
            dchResponseWrapper.returnedItemCount = 0;
            dchResponseWrapper.pageSize = PAGE_SIZE;
            dchResponseWrapper.assetWrapperList = assetWrapperList;
        }

        return dchResponseWrapper;
    }

    public static AssetWrapper createResponse(D1_DCHResponse.Items item, Map<String, String> mimeFileTypeMap){
        AssetWrapper assetWrapper = new AssetWrapper();
        assetWrapper.id = item.id;
        assetWrapper.fileName = item.properties.FileName;
        assetWrapper.title = item.properties.Title;
        assetWrapper.description = item.properties.Title;
        assetWrapper.fileType = mimeFileTypeMap.size()>0 && mimeFileTypeMap.containsKey(item.properties.MIMEType) ? mimeFileTypeMap.get(item.properties.MIMEType) : item.properties.MIMEType;
        assetWrapper.mimeType = item.properties.MIMEType;
        assetWrapper.createdDate = item.created_on;
        assetWrapper.thumbnail = item.renditions.thumbnail != null ? getURL(item.renditions.thumbnail) : '';
        assetWrapper.downloadPreview = item.renditions.downloadPreview != null ? getURL(item.renditions.downloadPreview) : '';
        assetWrapper.downloadOriginal = item.renditions.downloadOriginal != null ? getURL(item.renditions.downloadOriginal) : '';

        return assetWrapper;
    }

    public static string getURL(List<D1_DCHResponse.Self> urlList){
        return urlList[0].href;
    }
    
    /**Wrapper Class */
    public class DCHRequestWrapper{
        public String defaults{get;set;}
        public String culture{get;set;}
        public Integer skip{get;set;}
        public Integer take{get;set;}
        public String query{get;set;}
		public List<Filters> filters{get;set;}
		public List<String> fulltext{get;set;}
		public String view{get;set;}
		public Sorting sorting{get;set;}
    }

	public class Sorting{
        public String field{get;set;}
		public Boolean asc_Z{get;set;}
	}
	public class Filters{
        public String name{get;set;}
        public String operator{get;set;}
		public String type{get;set;}
		public list<String> values{get;set;}
	}

    public class DCHResponseWrapper{
        @AuraEnabled public String displayName {get;set;}
        @AuraEnabled public Integer totalItemCount {get;set;}
        @AuraEnabled public Integer returnedItemCount {get;set;}
        @AuraEnabled public Integer pageSize {get;set;}
        @AuraEnabled public Integer pageNumber {get;set;}
        @AuraEnabled public List<FilterWrapper> filterWrapperList {get;set;}
        @AuraEnabled public List<AssetWrapper> assetWrapperList {get;set;}
    }

    public class AssetWrapper {
        @AuraEnabled public String id {get;set;}
        @AuraEnabled public String fileName {get;set;}
        @AuraEnabled public String title {get;set;}
        @AuraEnabled public String description {get;set;}
        @AuraEnabled public String fileType {get;set;}
        @AuraEnabled public String mimeType {get;set;}
        @AuraEnabled public string createdDate {get;set;}
        @AuraEnabled public String thumbnail {get;set;}
        @AuraEnabled public String downloadPreview {get;set;}
        @AuraEnabled public String downloadOriginal {get;set;}
    }

    public class FilterWrapper {
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public Boolean isChecked {get;set;}
    }

}