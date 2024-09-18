/*Req: The requirement is to build Service for D1 to fetch Master Bundle Information, Bundle Data for the Outletand Asset data by bundle
User Story : ES20-13610,ES20-13612,ES20-13611,ES20-13697,ES20-13696,ES20-13945
History                                                            
                                                            
VERSION   AUTHOR                  DATE              DETAIL
1.0      Joshraj Sen           04/12/2022        ES20-13610
2.0		 Rajarshi Lahiri	   05/12/2022		 ES20-13612
3.0		 Swaraj Samanta		   05/12/2022		 ES20-13611
4.0      Monalisa Halder       06/01/2023        ES20-13697 
5.0      Monalisa Halder       06/01/2023        ES20-13696 
6.0		 Rajarshi Lahiri	   31/03/2023		 ES20-13945
7.0      Wribhu Bose           25/05/2023        GT-26 in method getAssetRecords
*/

public with sharing class EDGE_QualityEquipmentUtility {

    /**
    @method-   getMasterBundlebyCountry
    @description- when the Input - Country Code is provided (Ex - GB ,IE)
					Then the Output should be list of all Active Master Bundles of the Market 
					Information to be displayed - Master bundle Name ,Description 
    @return- List<EDGE_MasterBundleWrapper>
    @param CountryCode
    */
    
    @AuraEnabled
    public static List<EDGE_MasterBundleWrapper> getMasterBundlebyCountry(String countryCode){
        List<EDGE_MasterBundleWrapper> mbList=new List<EDGE_MasterBundleWrapper>();
        if(countryCode!=null)
         {
             for(Master_Bundle__c masterBundle :getMasterBundleRecords(countryCode)){
                 EDGE_MasterBundleWrapper mbwrap=new EDGE_MasterBundleWrapper();
                 mbwrap.recordId=masterBundle.Id;
                 mbwrap.masterBundleName=EDGE_UtilityClass.checkForNull(masterBundle.Name);
                 mbwrap.description=EDGE_UtilityClass.checkForNull(masterBundle.Description__c);
                 mbwrap.prereqforInstallation=EDGE_UtilityClass.checkForNull(masterBundle.Pre_requisites_for_Installation__c);
               	 mbList.add(mbwrap);
             }
             
         } 
         System.debug(logginglevel.DEBUG, '@@@ List '+mbList);
        return mbList;
    }
    
    /**
    @method-   getAssetbyBundle
    @description- when the Input Bundle Salesforce record Id provided
				  Then the Output should be list of all asset records associated to the Bundle
					Information provided - Asset Name ,Quantity, Install Date
    @return- List<EDGE_BundleAssetWrapper>
    @param bundleId
    */
    @AuraEnabled
     public static List<EDGE_BundleAssetWrapper> getAssetbyBundle(String bundleId){
        /* ES20-13697 - start*/
        List<EDGE_BundleAssetWrapper> bundleAssetWrapperList = new List<EDGE_BundleAssetWrapper>(); 
        List<EDGE_AssetWrapper> assetList=new List<EDGE_AssetWrapper>();
        EDGE_OutletBundleWrapper bundleDataWrapper =new EDGE_OutletBundleWrapper();
        EDGE_BundleAssetWrapper bundleAssetWrapper = new EDGE_BundleAssetWrapper();
        if(bundleId!=null)
         {
             for(Bundle__c bundle :getBundleRecords(bundleId,null)){
                 bundleDataWrapper=setOutletBundleWrap(bundleDataWrapper,bundle);
             }
             
             for(Asset asset :getAssetRecords(bundleId)){
                 EDGE_AssetWrapper assetWrapper=new EDGE_AssetWrapper();
                 assetWrapper.recordId=asset.Id;
                 assetWrapper.assetName=EDGE_UtilityClass.checkForNull(asset.Name);
                 assetWrapper.installDate=asset.InstallDate;
                 assetWrapper.quantity=asset.Quantity!=null?asset.Quantity:0.0;
               	 assetList.add(assetWrapper);
             }
             bundleAssetWrapper.bundleWrapper = bundleDataWrapper;
             bundleAssetWrapper.assetWrapperList = assetList;
             bundleAssetWrapperList.add(bundleAssetWrapper);
             
         }
         System.debug(LoggingLevel.DEBUG, '@@@ List '+bundleAssetWrapperList);
        return bundleAssetWrapperList;
        /* ES20-13697 - end*/ 
    }
    
        /**
    @method-  doGetBundlesForOutlet
    @description- when the Input - Outlet Id is provided
					Then the Output should be list of all Bundles of the Outlet
					Information to be displayed - Name ,Description ,Installation Date ,Content Document id ,Content version  id ,Location 
    @return- List<EDGE_OutletBundleWrapper>
    @param  outletId
    */
    @AuraEnabled
    public static List<EDGE_OutletBundleWrapper> doGetBundlesForOutlet(String outletId){
        
        List<EDGE_OutletBundleWrapper> bundleDetailsList = new List<EDGE_OutletBundleWrapper>();
        if(outletId != null){
            
            for(Bundle__c bundle :getBundleRecords(null,outletId)){
                
                 EDGE_OutletBundleWrapper bundleDataWrapper =new EDGE_OutletBundleWrapper();
                 bundleDataWrapper=setOutletBundleWrap(bundleDataWrapper,bundle);
                 bundleDetailsList.add(bundleDataWrapper);
               
             }
 
        }
        System.debug(LoggingLevel.DEBUG, '@@@ List '+bundleDetailsList);
        return bundleDetailsList;
    }
    
            /**
    @method-  setOutletBundleWrap
    @description- when the EDGE_OutletBundleWrapper instance and Bundle is passed the instance properties are populated and returned
    @return- EDGE_OutletBundleWrapper
    @param  EDGE_OutletBundleWrapper bundleDataWrapper,Bundle__c bundle
    */
    @AuraEnabled
    public static EDGE_OutletBundleWrapper setOutletBundleWrap(EDGE_OutletBundleWrapper bundleDataWrapper,Bundle__c bundle) {
        bundleDataWrapper.recordId=bundle.Id;
        bundleDataWrapper.name=EDGE_UtilityClass.checkForNull(bundle.Name);
        bundleDataWrapper.description=EDGE_UtilityClass.checkForNull(bundle.Description__c);
        bundleDataWrapper.installationDate=bundle.Installation_Date__c;
        bundleDataWrapper.contentDocumentId=EDGE_UtilityClass.checkForNull(bundle.Content_Document_ID__c);
        bundleDataWrapper.contentVersionId=EDGE_UtilityClass.checkForNull(bundle.Content_Version_Id__c);
        bundleDataWrapper.location=EDGE_UtilityClass.checkForNull(bundle.Bundle_Location__c);  
        /*ES20-13696 - start*/
        bundleDataWrapper.masterBundleId=EDGE_UtilityClass.checkForNull(bundle.Master_Bundle__c);
        bundleDataWrapper.outletId=EDGE_UtilityClass.checkForNull(bundle.Account__c);
        /*ES20-13696 - end*/
        bundleDataWrapper.faultFixer=EDGE_UtilityClass.checkForNull(bundle.Master_Bundle__r.Fault_Fixer__c);//ES20-13945
        return bundleDataWrapper;
    }
    
    //ES20-13945
     /**
    @method-  getAssetRecords
    @description- when the bundleId is passed Asset records are fetched by creating a dynamic query using fieldset
    @return- List<Asset>
    @param  String bundleId
    */
    @AuraEnabled
    public static List<Asset> getAssetRecords(String bundleId){
        
        String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();// GT-26

        String query = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.Asset.FieldSets.QualityEquipment_FieldSet.getFields()) {        
            query += field.getFieldPath() + ', ';
        }
        query=query.substring(0, query.lastIndexOf(','));
        query += ' FROM Asset WHERE RecordtypeId =: qualityAssetRecordTypeId'; //GT-26
		if(bundleId!=null){
            query+=' AND Bundle__c =: bundleId';
        }
        return Database.query(String.escapeSingleQuotes(query));
    }
    //ES20-13945
	/**
    @method-  getMasterBundleRecords
    @description- when the countryCode is passed Master Bundle records are fetched by creating a dynamic query using fieldset
    @return- List<Master_Bundle__c>
    @param  String countryCode
    */
    @AuraEnabled
    public static List<Master_Bundle__c> getMasterBundleRecords(String countryCode){
        
        String query = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.Master_Bundle__c.FieldSets.QualityEquipment_FieldSet.getFields()) {        
            query += field.getFieldPath() + ', ';
        }
        query=query.substring(0, query.lastIndexOf(','));
        query += ' FROM Master_Bundle__c';
        if(countryCode!=null){
            query+=' WHERE Country__r.Code__c =:countryCode AND Active__c =TRUE';
        }
        return Database.query(String.escapeSingleQuotes(query));
    }
    //ES20-13945
   	/**
    @method-  getBundleRecords
    @description- when either the bundleId or outletId is passed Bundle records are fetched by creating a dynamic query using fieldset
    @return- List<Bundle__c>
    @param  String bundleId,String outletId
    */
    @AuraEnabled
    public static List<Bundle__c> getBundleRecords(String bundleId,String outletId){
        
        String query = 'SELECT ';
        for(Schema.FieldSetMember field : SObjectType.Bundle__c.FieldSets.QualityEquipment_FieldSet.getFields()) {        
            query += field.getFieldPath() + ', ';
        }
        
        query += 'Master_Bundle__r.Fault_Fixer__c FROM Bundle__c';
        if(outletId!=null){
            query+=' WHERE Account__c =:outletId';
        }
        else{
            query+=' WHERE Id =:bundleId';
        }
        return Database.query(String.escapeSingleQuotes(query));
    }
}