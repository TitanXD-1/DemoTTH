/**
********************
* @Name: GT_AccountTriggerHelper
* @Created: 26 June 2023
* @Description: Helper for AccountTriggerHandler, for Global Travel related functions
* @Test Class: GT_AccountTriggerHelperTest
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     26/06/2023  140680 (GT-57) - Update GT Project and Asset fields when operator of linked outlet changes; methods updateGTObjectFields, processProjects, processAssets, updateObjects
********************
*/

public with sharing class GT_AccountTriggerHelper {
    final static string OUTLET_RECORDTYPE = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    final static string GT_ASSET_RECORDTYPE = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Global Travel Asset').getRecordTypeId();
    final static List<String> EXCLUDED_PHASES = Label.GT_ProjectExcludedPhases.split(',');
    final static string GT_HUB_CODE = Label.Global_Travel_Hub_Code;
    
    /**
* @name: updateGTObjectFields
* @description: Typecasts context variables and calls methods to filter records
* @param: Map<Id,SObject> newItemsMap, Map<Id,SObject> oldItemsMap
* @return: void
*/
    public static void updateGTObjectFields(Map<Id,SObject> newItemsMap, Map<Id,SObject> oldItemsMap){                   
        Map<Id,Account> newItems = newItemsMap != null ? (Map<Id,Account>)newItemsMap : null;
        Map<Id,Account> oldItems = oldItemsMap != null ? (Map<Id,Account>)oldItemsMap : null;
        Map<Id,Account> toFilterItems = new Map<Id,Account>();

        if(oldItems != null && newItems != null){
            for(Account accountRec : newItems.values()){
                if(oldItems.containsKey(accountRec.Id) 
                && accountRec.Operator__c != oldItems.get(accountRec.Id).Operator__c){
                    toFilterItems.put(accountRec.Id,accountRec);
                }
            }
        }
        filterAcctRecs(toFilterItems);       
    }

       /**
* @name: filterAcctRecs
* @description: Creates a filter of list of outlets to process and calls methods to update projects and assets
* @param: Map<Id,Account> toFilterItems
* @return: void
*/
    public static void filterAcctRecs(Map<Id,Account> toFilterItems){     
        Map<Id,Id> outletsToProcess = new Map<Id,Id>(); // Map of Account ID to Operator ID
        if(toFilterItems!=null){
            for(Account accountRec : toFilterItems.values()){ 
                if(accountRec.RecordTypeId == OUTLET_RECORDTYPE && accountRec.Hub_Code__c == GT_HUB_CODE ){
                    outletsToProcess.put(accountRec.Id,accountRec.Operator__c); 
                }               
            }
        }
        
        if(outletsToProcess != null && !outletsToProcess.isEmpty()) {
            System.debug(Logginglevel.INFO, '@@GTAccTrigHelper Outlets to Process: (count=' + outletsToProcess.size() + ') ' + outletsToProcess);
            processProjects(outletsToProcess);
            processAssets(outletsToProcess);
        }
    }
    
    /**
* @name: processProjects
* @description: Updates fields in GT Project when field in linked outlet is changed
* @param: Map<Id,Id> outletsToProcess
* @return: void
*/
    public static void processProjects(Map<Id,Id> outletsToProcess) {
        
        List<GT_Project__c> projectsToUpdate = new List<GT_Project__c>();
        
        for(GT_Project__c projectRec: [SELECT Id, GT_Phase__c, GT_Customer__c, GT_Outlet__c
                                       FROM GT_Project__c
                                       WHERE GT_Outlet__c IN :outletsToProcess.keySet()
                                       AND GT_Phase__c NOT IN :EXCLUDED_PHASES
                                       WITH SECURITY_ENFORCED])
        {
            if(outletsToProcess.containsKey(projectRec.GT_Outlet__c) && projectRec.GT_Customer__c != outletsToProcess.get(projectRec.GT_Outlet__c)) {
                projectRec.GT_Customer__c = outletsToProcess.get(projectRec.GT_Outlet__c);
                projectsToUpdate.add(projectRec);
            }
        }
        
        if(!projectsToUpdate.isEmpty()){
            updateObjects(projectsToUpdate,null);
        }
    }
    
    /**
* @name: processAssets
* @description: Updates fields in Asset (Global Travel RT) when field in linked outlet is changed
* @param: Map<Id,Id> outletsToProcess
* @return: void
*/
    public static void processAssets(Map<Id,Id> outletsToProcess) {
        
        List<Asset> assetsToUpdate = new List<Asset>();

        for(Asset assetRec: [SELECT Id, Asset_Used_By__c, RecordTypeId, AccountId
                             FROM Asset
                             WHERE RecordTypeId =: GT_ASSET_RECORDTYPE
                             AND AccountId IN :outletsToProcess.keySet()
                             WITH SECURITY_ENFORCED])
        {
            if(outletsToProcess.containsKey(assetRec.AccountId) && assetRec.Asset_Used_By__c != outletsToProcess.get(assetRec.AccountId)) {
                assetRec.Asset_Used_By__c = outletsToProcess.get(assetRec.AccountId);
                assetsToUpdate.add(assetRec);
            } 
        }
        
        if(!assetsToUpdate.isEmpty()){
            updateObjects(null,assetsToUpdate); 
        }
    }
    
    /**
* @name: updateObjects
* @description: Performs DML operation to update
* @param: List<GT_Project__c> projects, List<Asset> assets
* @return: void
*/
    public static void updateObjects(List<GT_Project__c> projects, List<Asset> assets) {
        
        if(projects!=null && Schema.sObjectType.GT_Project__c.isUpdateable()) {
            update projects;
        }
        
        if(assets!=null && Schema.sObjectType.Asset.isUpdateable()) {
            update assets;
        }
    }
}