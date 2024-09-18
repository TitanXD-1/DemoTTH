/**
* @Name: GT_AssetVerificationTriggerHelper
* @Purpose: Helper for GT_AssetVerificationTriggerHandler
* @Test Class: GT_AssetVerificationTriggerHelperTest
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     26/07/2023  140748 : [GT-134] Asset Verification Automations
*/

public with sharing class GT_AssetVerificationTriggerHelper {
    
    final static string GT_ASSET_RECORDTYPE = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Global Travel Asset').getRecordTypeId();
	public static Map<Id,Asset> assetMap; // Map of assets for updating

    /**
     * @name: updateAssetOnInsertOrUpdate
     * @desc: Update Asset TAG fields if the Verification record's new TAG number is changed from the one in the Asset
     * @param: List<GT_Asset_Verification__c> assetVerList: list of new Verification records inserted or the records that are updated
     * @param: Map<Id,SObject> oldItems: map of previous Verification records, that got updated
     * @return: void
     */
    public static void updateAssetOnInsertOrUpdate(List<GT_Asset_Verification__c> assetVerList, Map<Id,SObject> oldItems) {

        Map<Id,Id> asstVerifToParentAsstMap = new Map<Id,Id>(); // Map of inserted/updated Verification records to their parent Assets
        
        Boolean isUpdate = (oldItems == null ? false : true);
        Map<Id,GT_Asset_Verification__c> oldAssetVerMap = oldItems != null ? (Map<Id,GT_Asset_Verification__c>)oldItems : null;

        // Create a map of Verification record ID to related Asset (master-detail)
        // For insert, we will do for all records
        // For update, we will do for those records where TAG number has changed
        if(assetVerList != null) {
            for(GT_Asset_Verification__c assetVer : assetVerList) {
                if(!isUpdate || (isUpdate && oldAssetVerMap.containsKey(assetVer.Id) && assetVer.GT_Asset_TAG_Number__c != oldAssetVerMap.get(assetVer.Id).GT_Asset_TAG_Number__c)) {
                    asstVerifToParentAsstMap.put(assetVer.Id,assetVer.GT_Asset_Name__c);
                }
            }
        }
        
        System.debug(Logginglevel.INFO, '@@asstVerifToParentAsstMap' + asstVerifToParentAsstMap);

        processVerifRecs(assetVerList,asstVerifToParentAsstMap,isUpdate);
    }

    /**
     * @name: processVerifRecs
     * @desc: Returns the latest Verification Record for the Asset ordered by Verification Date
     * @param: List<GT_Asset_Verification__c> assetVerList: list of new Verification records inserted or the records that are updated
     * @param: Map<Id,Id> asstVerifToParentAsstMap: map of inserted/updated Verification records to their parent Assets
     * @param: Boolean isUpdate: check for insert vs update scenario
     * @return: void
     */
    public static void processVerifRecs(List<GT_Asset_Verification__c> assetVerList, Map<Id,Id> asstVerifToParentAsstMap, Boolean isUpdate) {

        Map<Id,Id> latestAsstVerifToParentAsstMap = new Map<Id,Id>(); // Map of latest Verification record (by Verification Date) to parent Asset
        Map<Id,String> assetToTAGNumberMap = new Map<Id,String>(); // Map of Assets to their TAG numbers
        Map<Id,List<GT_Asset_Verification__c>> asstToAsstVerifsMap = new Map<Id,List<GT_Asset_Verification__c>>(); // Map of Assets to lists of all their Verification records

        assetMap = new Map<Id,Asset>();
        
        Map<Id,Id> verifsMapToPass = new Map<Id,Id>();
        
        if(!asstVerifToParentAsstMap.isEmpty()){
            if(isUpdate){
                // Create a map of Assets to lists of their Verification records
                asstToAsstVerifsMap = createAssetVerfMap(asstVerifToParentAsstMap.values());
            }
            
            // Fetch and create a map of Assets to their TAG numbers. These assets are fetched from the list of IDs created from the inserted Verification records
            for(Asset asst:[SELECT Id, GT_Verification_Date__c, GT_Asset_TAG_Number__c,GT_Asset_TAG_Changed__c,RecordTypeId
                            FROM Asset
                            WHERE Id IN :asstVerifToParentAsstMap.values()
                            AND RecordTypeId =: GT_ASSET_RECORDTYPE
                            WITH SECURITY_ENFORCED])
            {
                assetToTAGNumberMap.put(asst.Id,asst.GT_Asset_TAG_Number__c);
                assetMap.put(asst.Id,asst);

                latestAsstVerifToParentAsstMap = returnLatestVerifRec(asst,asstToAsstVerifsMap,asstVerifToParentAsstMap);
            }
        }
        
        System.debug(Logginglevel.INFO, '@@assetMap' + assetMap);
        System.debug(Logginglevel.INFO, '@@latestAsstVerifToParentAsstMap' + latestAsstVerifToParentAsstMap);
        System.debug(Logginglevel.INFO, '@@asstVerifToParentAsstMap' + asstVerifToParentAsstMap);

        verifsMapToPass = isUpdate == true ? latestAsstVerifToParentAsstMap : asstVerifToParentAsstMap;

        if(!verifsMapToPass.isEmpty()) {
            updateAssetFields(assetVerList,assetToTAGNumberMap,verifsMapToPass);
        }
    }

    /**
     * @name: returnLatestVerifRec
     * @desc: Returns the latest Verification Record for the Asset ordered by Verification Date
     * @param: Asset asst: current Asset being iterated over
     * @param: Map<Id,List<GT_Asset_Verification__c>> asstToAsstVerifsMap: map of Assets to lists of all their Verification records
     * @param: Map<Id,Id> asstVerifToParentAsstMap: map of inserted/updated Verification records to their parent Assets
     * @return: Map<Id,Id>
     */
    public static Map<Id,Id> returnLatestVerifRec(Asset asst, Map<Id,List<GT_Asset_Verification__c>> asstToAsstVerifsMap, Map<Id,Id> asstVerifToParentAsstMap) {

        Map<Id,Id> latestAsstVerifToParentAsstMap = new Map<Id,Id>();

        if(!asstToAsstVerifsMap.isEmpty()) {
            GT_Asset_Verification__c assetVerObj = (asstToAsstVerifsMap.get(asst.Id))[0];
            if(asstVerifToParentAsstMap.containsKey(assetVerObj.Id)) {
                latestAsstVerifToParentAsstMap.put(assetVerObj.Id,asst.Id);
            }
        }

        return latestAsstVerifToParentAsstMap;
    }

    /**
     * @name: updateAssetFields
     * @desc: Cycle over verification records and update necessary Assets
     * @param: List<GT_Asset_Verification__c> assetVerList: list of Verification records to cycle over
     * @param: Map<Id,String> assetToTAGNumberMap: map of Assets to their TAG numbers
     * @param: Map<Id,Id> assetVerifToAssetMap: map of Verification record ID to related Asset ID
     * @return: void
     */
    public static void updateAssetFields(List<GT_Asset_Verification__c> assetVerList, Map<Id,String> assetToTAGNumberMap, Map<Id,Id> assetVerifToAssetMap) {
        
        List<Asset> assetListToBeUpdated = new List<Asset>();
        
        // For each Verification record, check the record's TAG number against the map of Assets to TAG numbers,
        // where the key is taken from the map of Verification record to Asset, passing the Verification record's ID.
        // If they don't match, we assign for updation of fields
        if(!assetMap.isEmpty()){
            for(GT_Asset_Verification__c assetVer : assetVerList){
                if(assetMap.containsKey(assetVerifToAssetMap.get(assetVer.Id))
                   && assetVer.GT_Asset_TAG_Number__c != assetToTAGNumberMap.get(assetVerifToAssetMap.get(assetVer.Id))) {
                
                    Asset assetObj = assetMap.get(assetVerifToAssetMap.get(assetVer.Id));
                    assetObj.GT_Asset_TAG_Number__c = assetVer.GT_Asset_TAG_Number__c;
                    assetObj.GT_Asset_TAG_Changed__c = assetVer.GT_Asset_TAG_Changed__c;
                    assetListToBeUpdated.add(assetObj);
                   }
            }
        }
        
        System.debug(Logginglevel.INFO, '@@GT_AssetVerificationTriggerHelper assetListToBeUpdated:'+assetListToBeUpdated);

        if(!assetListToBeUpdated.isEmpty() && Schema.sObjectType.Asset.isUpdateable()) {
            update assetListToBeUpdated;
        }
    }

    /**
     * @name: createAssetVerfMap
     * @desc: Create a map of Assets to lists of their Verification records
     * @param: List<Id> assetNames: list of Assets
     * @return: Map<Id,List<GT_Asset_Verification__c>>
     */
    public static Map<Id,List<GT_Asset_Verification__c>> createAssetVerfMap(List<Id> assetNames) {

        Map<Id,List<GT_Asset_Verification__c>> asstToAsstVerifsMap = new Map<Id,List<GT_Asset_Verification__c>>();

        for(GT_Asset_Verification__c assetVer : [SELECT Id, GT_Verification_Date__c, GT_Asset_Name__c
                                                 FROM GT_Asset_Verification__c
                                                 WHERE GT_Asset_Name__c IN :assetNames
                                                 WITH SECURITY_ENFORCED
                                                 ORDER BY GT_Verification_Date__c DESC])
        {
            if(asstToAsstVerifsMap.containsKey(assetVer.GT_Asset_Name__c)) {
                List<GT_Asset_Verification__c> assetVerfcList = asstToAsstVerifsMap.get(assetVer.GT_Asset_Name__c);
                assetVerfcList.add(assetVer);
                asstToAsstVerifsMap.put(assetVer.GT_Asset_Name__c,assetVerfcList);
            } else {
                List<GT_Asset_Verification__c> assetVerfcList = new List<GT_Asset_Verification__c>();
                assetVerfcList.add(assetVer);
                asstToAsstVerifsMap.put(assetVer.GT_Asset_Name__c,assetVerfcList);                    
            }                                                 
        }
        
        return asstToAsstVerifsMap;
    }
}