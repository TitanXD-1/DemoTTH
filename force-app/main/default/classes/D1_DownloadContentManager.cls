/*
 * @name: D1_DownloadContentManager
 * @Discription: D1_DownloadContentManager Class for populating User details.
 * @history
 * VERSION      AUTHOR              DATE        DETAIL
 * 1.0          Sudipta nandi       07/10/2020  Initial Development
 * 2.0          Kapil Baliyan       23/08/2022  NCP- 
 **/
public without sharing class D1_DownloadContentManager {
    public static String contentDownloadUrl = System.Label.D1_CommunityPrefix.replace('/s','') + System.Label.D1_ContentDownloadURL;
    
    //This wrapper haas been used to get d1Tiles Image,Des,title
    public class HeaderContentWrapper{
        @AuraEnabled public String itemCategroy;
        @AuraEnabled public DownloadItemContentWrapper[] downloadItems;
    }
    
    public class DownloadItemContentWrapper{
        @AuraEnabled public String id;
        @AuraEnabled public String itemImageUrl;
        @AuraEnabled public String itemName;
        @AuraEnabled public String itemCategroy;
        @AuraEnabled public String itemFolderLink;
        @AuraEnabled public String folderItemDescription;
        @AuraEnabled public double countDFI;
        @AuraEnabled public String dchTags;
        @AuraEnabled public String assetType;
    }
    
    //This wrapper haas been used to get d1banner Image,Des,title
    public class DownloadBannerContentWrapper{
        @AuraEnabled public String itemImageUrl;
        @AuraEnabled public String itemTitle;
        @AuraEnabled public String itemDescription;
    }

    /**
     * @userstory: NCP-767
     * @description get Download Contents for Asset download landing page tiles (Based on Loggedin User typr and Locale)
     * @return  `Object`
     */    
    @AuraEnabled(cacheable=true)
    public static Object getDownloadContents(){
        try{
            String userId = System.UserInfo.getUserId();
            List<User> loggedInUser = [SELECT Id, LanguageLocaleKey, Available_Countries__c, D1_User_Type__c FROM User WHERE Id =:userId];
            String [] availableCountry = loggedInUser[0].Available_Countries__c.split(';');

            //Get D1 Setting
            D1_Setting__c d1Setting = getD1Setting();
            
            //Get Brand Count
            Integer brandCount = getContentCount('BRAND', availableCountry);

            //Get Occasion Count
            Integer occasionCount = getContentCount('OCCASION', availableCountry);

            //Get All Asset Count
            Integer allAssetCount = getContentCount('ALL ASSETS', availableCountry);

            //Create Map of Response
            return new Map<String, Object>{
                'd1Setting' => d1Setting,
                'brandCount' => brandCount,
                'occasionCount' => occasionCount,
                'allAssetCount' => allAssetCount
            };
        }catch(Exception e){
            throw new AuraHandledException(e.getMessage());
        }
    }

    //Get Content Count
    public static Integer getContentCount(string contentType, List<String> availableCountry){
        Integer count = 0;
        Id brandRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Brand').getRecordTypeId();
        Id eventRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        Id allAssetRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('All Asset').getRecordTypeId();

        if(contentType == 'BRAND'){
            List<AggregateResult> brandGroupedResults =  [SELECT count(Id) FROM D1_Content_Assignment__c WHERE Geography__r.Code__c IN :availableCountry AND Active__c = TRUE AND RecordTypeId =:brandRecordTypeId];
            if(!brandGroupedResults.isEmpty()){
                count = Integer.valueOf(brandGroupedResults.get(0).get('expr0'));
            }
        }else if(contentType == 'OCCASION'){
            List<AggregateResult> occassionGroupedResults =  [SELECT count(Id) FROM D1_Content_Assignment__c WHERE Geography__r.Code__c IN :availableCountry AND Active__c = TRUE AND RecordTypeId =:eventRecordTypeId];
            if(!occassionGroupedResults.isEmpty()){
                count = Integer.valueOf(occassionGroupedResults.get(0).get('expr0'));
            }
        }else if(contentType == 'ALL ASSETS'){
            List<AggregateResult> allAssetGroupedResults =  [SELECT count(Id) FROM D1_Download_Folder_Item__c WHERE D1_Content_Assignment__r.Geography__r.Code__c IN :availableCountry AND Active__c = TRUE AND D1_Content_Assignment__r.RecordTypeId =:allAssetRecordTypeId AND D1_Content_Assignment__r.Active__c = TRUE];
            if(!allAssetGroupedResults.isEmpty()){
                count = Integer.valueOf(allAssetGroupedResults.get(0).get('expr0'));
            }
        }

        return count;
    }

    /**
     * @description get Download Brand/Occasion Contents for d1Tiles from all three page
     * @param isPopularBrandFetch 
     * @param downLoadByName 
     * @param itemId 
     * @return  `List<HeaderContentWrapper>`
     */    
    @AuraEnabled(cacheable=true)
    public static List<HeaderContentWrapper> getDownloadItemContents(Boolean isPopularBrandFetch, String downLoadByName, String itemId){
        //itemId is not empty when calling from Asset Info page (when clicking on view Download link from tiles)
        List<HeaderContentWrapper> recordCol = new List<HeaderContentWrapper>();
        if(itemId != '' || downLoadByName == 'ALL ASSETS'){
            recordCol = fetchContentSpecificItems(itemId, downLoadByName);
        }
        else{
            recordCol = fetchGenericItems(isPopularBrandFetch,downLoadByName);
        }
        return recordCol;
    }

    /**
     * @userstory: NCP-767
     * @description get Banner Image Contents for Asset download page
     * @param downLoadByName 
     * @param itemId 
     * @return  `DownloadBannerContentWrapper`
     */    
    @AuraEnabled(cacheable=true)
    public static DownloadBannerContentWrapper getBannerImageData(String downLoadByName, String itemId){
        //Object Initialization Section
        DownloadBannerContentWrapper contentwrp = new DownloadBannerContentWrapper();
        List<D1_Content_Assignment__c> folderItemsCol = new List<D1_Content_Assignment__c>();
       
        if(itemId == ''){
            D1_Setting__c settingObj = getD1Setting();
                
            if(settingObj != null){
                if(downLoadByName == 'BRAND'){
                    //Section for Brand
                    contentwrp.itemImageUrl = contentDownloadUrl + settingObj.Brand_Content_version_Id__c;
                    contentwrp.itemTitle = System.Label.D1_AssetBrandSubLandingtitle;
                    contentwrp.itemDescription = System.Label.D1_AssetBrandSubLandingDes;
                }
                else if(downLoadByName == 'OCCASION'){
                    //Section for Occasion
                    contentwrp.itemImageUrl = contentDownloadUrl + settingObj.Occasion_Content_version_Id__c;
                    contentwrp.itemTitle = System.Label.D1_AssetOccasionSubLandingTitle;
                    contentwrp.itemDescription = System.Label.D1_AssetOccasionSubLandingDes;
                }
                else{//NCP-5611
                    //Section for All Asset Types
                    contentwrp.itemImageUrl = contentDownloadUrl + settingObj.Asset_Type_Content_version_Id__c;
                    contentwrp.itemTitle = System.Label.D1_AllAssetTypeTitle;
                    contentwrp.itemDescription = System.Label.D1_AllAssetDescription;
                }
            }
        }
        else{
            folderItemsCol = [SELECT Id, Name, Description__c, Active__c, D1_Brand__r.Name, D1_Event__r.Name, Folder_Content_version_Id__c
                                FROM D1_Content_Assignment__c
                                WHERE Id =:itemId];
          	
            if(folderItemsCol != null && !folderItemsCol.isEmpty() ){
                contentwrp.itemImageUrl = contentDownloadUrl + folderItemsCol[0].Folder_Content_version_Id__c;
                if(downLoadByName == 'BRAND'){
                    //section for Brand
                    List<String> params = new List<String>{folderItemsCol[0].D1_Brand__r.Name}; 
                       
                    contentwrp.itemTitle = folderItemsCol[0].D1_Brand__r.Name.toUppercase();
                    contentwrp.itemDescription = String.format(System.Label.D1_AssetBrandDetailBannerDes,params);
                }
                else{
                    //Section for Occasion 
                    List<String> params = new List<String>{folderItemsCol[0].D1_Event__r.Name};
                    contentwrp.itemTitle = folderItemsCol[0].D1_Event__r.Name.toUppercase();
                    contentwrp.itemDescription = String.format(System.Label.D1_AssetOccasionDetailBannerDes,params); 
                }
            }
        }
        return contentwrp;
    }

    //Private Method Section 
    /**
     * @description fetchGenericItems
     * @param isPopularBrandFetch 
     * @param downLoadByName 
     * @return  `List<HeaderContentWrapper>`
     */  
    private static List<HeaderContentWrapper> fetchGenericItems(Boolean isPopularBrandFetch, String downLoadByName){
        Id brandRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Brand').getRecordTypeId();
        Id eventRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('Event').getRecordTypeId();
        Id allAssetRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('All Asset').getRecordTypeId();
		
        //Variable Declaretion section
        String userId = System.userinfo.getuserid();
        String queryToQuery = 'SELECT Id, Name, Popular_Brand__c, Geography__r.Code__c, Count_Download_Folder_Items__c, '+
            'toLabel(D1_Brand__r.Category__c), D1_Brand__r.Name, D1_Event__r.Category__c, ' +
            'Description__c, Folder_Link__c, Active__c, Folder_Content_Document_Id__c, Folder_Content_version_Id__c, ' + 
            'D1_Event__r.Name, D1_Brand__c, D1_Event__c, DCH_Asset_Tags__c, RecordTypeId FROM D1_Content_Assignment__c WHERE Geography__r.Code__c  IN :availableCountry AND Active__c = True';
        
        //Object Initialtialzation section
        Map<String, HeaderContentWrapper> headerContentMap = new Map<String, HeaderContentWrapper>();
        List<D1_Content_Assignment__c> folderItemsCol = new List<D1_Content_Assignment__c>();
        List<User> loggedInUser = [SELECT Id, Name, LanguageLocaleKey, Available_Countries__c, D1_User_Type__c 
                                   FROM User 
                                   WHERE Id =:userId];
        String [] availableCountry = loggedInUser[0].Available_Countries__c.split(';'); //NOPMD
        

        if(loggedInUser!= null && !loggedInUser.isEmpty()){
            //Popular Brand fetch
           
            
            if(isPopularBrandFetch){
                queryToQuery+= ' AND Popular_Brand__c = True ORDER BY LastModifiedDate';
            }
            //All category Brand fetch
            else{
                if(downLoadByName == 'BRAND'){
                    queryToQuery+= ' AND RecordTypeId =:brandRecordTypeId ORDER BY D1_Brand__r.Name';
                }
                else if(downLoadByName == 'OCCASION'){
                    queryToQuery+= ' AND RecordTypeId =:eventRecordTypeId ORDER BY D1_Event__r.Name';
                }
            }
           
            folderItemsCol = D1_TranslationsUtility.updateTranslationsInRecords(Database.query(queryToQuery));

            if(folderItemsCol != null && !folderItemsCol.isEmpty()){
                for(D1_Content_Assignment__c folItem: folderItemsCol){
                    //update the rest wrapper valiables which is not initialize by D1 Brand object like Image,Des
                    if(folItem.RecordTypeId == brandRecordTypeId){
                        downLoadByName = 'BRAND';
                    }else if(folItem.RecordTypeId == eventRecordTypeId){
                        downLoadByName = 'OCCASION';
                    }else if(folItem.RecordTypeId == allAssetRecordTypeId){
                        downLoadByName = 'ALL ASSETS';
                    }
                    DownloadItemContentWrapper item = createDownloadItem(folItem, downLoadByName, isPopularBrandFetch);
                    
                    if(headerContentMap.containsKey(item.itemCategroy)){
                        HeaderContentWrapper contentHeaderwrp = headerContentMap.get(item.itemCategroy);
                        contentHeaderwrp.downloadItems.add(item);
                        headerContentMap.put(item.itemCategroy, contentHeaderwrp);
                    }else{
                        HeaderContentWrapper contentHeaderwrp = createDownloadHeaderItem(item.itemCategroy);
                        contentHeaderwrp.downloadItems.add(item);
                        headerContentMap.put(item.itemCategroy, contentHeaderwrp);
                    }
                }
            }
        }

        return headerContentMap.values();
    }

    /**
     * @description 
     * @param itemId 
     * @return  `List<HeaderContentWrapper>`
     */   
    private static List<HeaderContentWrapper> fetchContentSpecificItems(String itemId, String downLoadByName){
        //fetch Brand specific Asset Details Information Specific 
        List<HeaderContentWrapper> objCol = new List<HeaderContentWrapper>();
        List<DownloadItemContentWrapper> listItemContent = new List<DownloadItemContentWrapper>();
        List<D1_Download_Folder_Item__c> folderItemsCol = new List<D1_Download_Folder_Item__c>();
        Id allAssetRecordTypeId = Schema.SObjectType.D1_Content_Assignment__c.getRecordTypeInfosByName().get('All Asset').getRecordTypeId();//NOPMD

        //Query String
        String queryStr = 'SELECT Id, Name, Description__c, Folder_Link__c, Active__c, toLabel(Type__c), ' +
                           'FolderItem_Content_Document_Id__c, FolderItem_Content_version_Id__c, DCH_Asset_Tags__c FROM D1_Download_Folder_Item__c '+
                           'WHERE Active__c = true';
        
        if(String.isNotBlank(itemId)){
            queryStr += ' AND D1_Content_Assignment__c =:itemId';
        }else{
            String userId = System.userinfo.getuserid();
            List<User> loggedInUser = [SELECT Id, Name, LanguageLocaleKey, Available_Countries__c, D1_User_Type__c FROM User WHERE Id =:userId];
            String [] availableCountry = loggedInUser[0].Available_Countries__c.split(';');//NOPMD

            queryStr += ' AND D1_Content_Assignment__r.Geography__r.Code__c IN :availableCountry AND D1_Content_Assignment__r.RecordTypeId =:allAssetRecordTypeId AND D1_Content_Assignment__r.Active__c = TRUE';
        }

        queryStr += ' ORDER BY Type__c';

        //Get Folder Item Data
        folderItemsCol  = D1_TranslationsUtility.updateTranslationsInRecords(Database.query(queryStr));
        
        if(folderItemsCol != null && !folderItemsCol.isEmpty() ){
            for(D1_Download_Folder_Item__c folItem: folderItemsCol){
                DownloadItemContentWrapper contentItemwrp = new DownloadItemContentWrapper();
                contentItemwrp.id = folItem.Id;
                contentItemwrp.itemImageUrl = contentDownloadUrl + folItem.FolderItem_Content_version_Id__c;
                contentItemwrp.itemName = folItem.Type__c;
                contentItemwrp.itemCategroy = folItem.Type__c;
                contentItemwrp.itemFolderLink = folItem.Folder_Link__c;
                contentItemwrp.folderItemDescription = folItem.Description__c;
                contentItemwrp.countDFI = 0;
                contentItemwrp.dchTags = folItem.DCH_Asset_Tags__c;
                contentItemwrp.assetType = downLoadByName;
                //Adding the single asset item into collection
                listItemContent.add(contentItemwrp);
            }
        }

        // Adding all brand specfic items as a submenu of the Header Menu. and the Header categor name will be "All Asset Type"
        HeaderContentWrapper contentHeaderwrp = new HeaderContentWrapper();
        contentHeaderwrp.itemCategroy = System.Label.D1_AllAssetTypeText;
        contentHeaderwrp.downloadItems =  listItemContent;
        
        objCol.add(contentHeaderwrp);
        
        return objCol;
    }

    /**
     * @description 
     * @param mItem 
     * @param downLoadByName 
     * @return  `DownloadItemContentWrapper`
     */    
    @TestVisible
    private static DownloadItemContentWrapper createDownloadItem( D1_Content_Assignment__c mItem, String downLoadByName, Boolean isPopularBrandFetch){
        DownloadItemContentWrapper contentItemwrp = new DownloadItemContentWrapper();
        contentItemwrp.id = mItem.Id;
        contentItemwrp.itemImageUrl = contentDownloadUrl + mItem.Folder_Content_version_Id__c;
        contentItemwrp.itemName = (mItem.D1_Brand__c != null) ? mItem.D1_Brand__r.Name : ((mItem.D1_Event__c != null) ? mItem.D1_Event__r.Name : System.Label.D1_AllAssetTypeTitle);
        contentItemwrp.itemCategroy = isPopularBrandFetch ? System.Label.D1_DownloadPopularBrandText : (downLoadByName == 'BRAND') ? mItem.D1_Brand__r.Category__c : System.Label.D1_AssetOccasionCategory;
        contentItemwrp.itemFolderLink = mItem.Folder_Link__c;
        contentItemwrp.folderItemDescription = mItem.Description__c;
        contentItemwrp.countDFI = mItem.Count_Download_Folder_Items__c;
        contentItemwrp.dchTags = mItem.DCH_Asset_Tags__c;
        contentItemwrp.assetType = downLoadByName;
        
        return contentItemwrp;
    }

    /**
     * @description 
     * @param categoryName 
     * @return  `HeaderContentWrapper`
     */    
    @TestVisible
    private static HeaderContentWrapper createDownloadHeaderItem(String categoryName){
        HeaderContentWrapper contentwrp = new HeaderContentWrapper();
        contentwrp.itemCategroy =  categoryName;
        contentwrp.downloadItems = new List<DownloadItemContentWrapper>() ;
        return contentwrp;
    }

    //Get D1 Setting Data
    @AuraEnabled(cacheable=true)
    public static D1_Setting__c getD1Setting(){
        try {
            String userId = System.UserInfo.getUserId();
            List<D1_Setting__c> d1Setting = new List<D1_Setting__c>();
            List<User> loggedInUser = [SELECT Id, LanguageLocaleKey, Available_Countries__c, D1_User_Type__c FROM User WHERE Id =:userId];

            String [] availableCountry = loggedInUser[0].Available_Countries__c.split(';');

            //Get D1 Setting
            d1Setting = [SELECT Id, Language__c, Brand_Card_Description__c, Brand_Content_Document_Id__c,
                        Brand_Content_version_Id__c, Occasion_Card_Description__c, Occasion_Content_Document_Id__c,
                        Occasion_Content_version_Id__c, Asset_Type_Card_Description__c, Asset_Type_Content_Document_Id__c,
                        Asset_Type_Content_version_Id__c, D1_Enable_DCH__c, Code_of_Conduct_Link__c,Partner_Plus_Terms_Condition_Link__c,
                        D1_Enable_CSV_Ordering__c, CSV_Ordering_FAQ_Link__c
                        FROM D1_Setting__c 
                        WHERE Language__c =:loggedInUser[0].LanguageLocaleKey 
                        AND Market__r.Code__c IN :availableCountry];
            
            return d1Setting.size()>0 ? d1Setting.get(0) : null;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
}