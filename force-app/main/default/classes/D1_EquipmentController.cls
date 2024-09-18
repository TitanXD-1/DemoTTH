/**
 * @name : D1_EquipmentController
 * @description : Controller for Equipment Related Pages
 * @history
 * VERSION     	AUTHOR         	   DATE            DETAIL
 * 1.0          Pratap Sen       23/12/202       NCP-7727 & NCP-7728
**/
public without sharing class D1_EquipmentController {

    private static final String EQUIPMENTISSUE = 'Equipment Issue';
    private static final Id EQUIPMENTRECTYPEID = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName().get('Equipment_Issue').getRecordTypeId();

	/**
    * @description : NCP-7728 - Get List of Master Bundles for current User country
    * @return      : List<EDGE_MasterBundleWrapper>
    */
    @AuraEnabled(cacheable=true)
    public static List<EDGE_MasterBundleWrapper> getMasterBundlebyCountry(){
        List<EDGE_MasterBundleWrapper> masterBundleList = new List<EDGE_MasterBundleWrapper>();
        try{
            Id userId = UserInfo.getUserId();
            String countryCode = [SELECT Available_Countries__c FROM User WHERE Id =:userId LIMIT 1].Available_Countries__c;
            masterBundleList = EDGE_QualityEquipmentUtility.getMasterBundlebyCountry(countryCode);
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }
        return masterBundleList;
       
    }
    
    /**
    * @description : Get list of Assets agaisnt Bundle ID
    * @param       : bundleId (String)
    * @return      : List<EDGE_BundleAssetWrapper>
    */
    @AuraEnabled
    public static List<EDGE_BundleAssetWrapper> getAssetbyBundle(String bundleId){
        List<EDGE_BundleAssetWrapper> assetList = new List<EDGE_BundleAssetWrapper>();
        try{
            assetList = EDGE_QualityEquipmentUtility.getAssetbyBundle(bundleId);
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }
        return assetList;
    }
    
    /**
    * @description : Get list of Bundles agaisnt Account ID
    * @param       : outletId (String)
    * @return      : List<EDGE_OutletBundleWrapper>
    */
    @AuraEnabled(cacheable=true)
    public static List<EDGE_OutletBundleWrapper> getBundlesbyOutlet(String outletId){
        List<EDGE_OutletBundleWrapper> bundlesForOutlet = new List<EDGE_OutletBundleWrapper>();
        try{
            if(String.isEmpty(outletId)){
                Id userId = UserInfo.getUserId();
                outletId = [SELECT Effective_Account_Id__c FROM User WHERE Id =: userId LIMIT 1].Effective_Account_Id__c;
            } 
            bundlesForOutlet = EDGE_QualityEquipmentUtility.doGetBundlesForOutlet(outletId);
        } catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }
        return bundlesForOutlet;
    }
    
    /**
    * @description : NCP-7727 - Get List of PickUp Options of 'Equipment Issue' record type against context user geography
    * @param       : userId {String}
    * @return      : List<Pick_Up_Options__c>
    */
    @AuraEnabled(cacheable=true)
    public static List<Pick_Up_Options__c> getEquipmentIssues(string countryCode){
        List<Pick_Up_Options__c> eqpIssues = new List<Pick_Up_Options__c>();
        try{
            //Check if country code is blank, refetch it from user again
            if(String.isBlank(countryCode)){
                User usr = [SELECT Id, Available_Countries__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
                countryCode = String.isNotBlank(usr.Available_Countries__c) ? usr.Available_Countries__c : '';
            }

            //Query PickUp Option records available
            for(Pick_Up_Options__c opts :  [SELECT Id, Name FROM Pick_Up_Options__c 
                                            WHERE Status__c = 'Active' 
                                            AND RecordTypeId =: EQUIPMENTRECTYPEID AND Type__c =: EQUIPMENTISSUE AND Geography__r.Code__c =: countryCode ORDER BY Name ASC])
            {
                opts.Name = opts.Name.substringBefore('[').trim();
                eqpIssues.add(opts);
            }
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage() + 'line Number '+ex.getLineNumber());
        }
        return eqpIssues;
    }
}