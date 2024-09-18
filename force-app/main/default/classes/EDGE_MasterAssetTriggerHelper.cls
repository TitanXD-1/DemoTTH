/**
 * @description :  EDGE_MasterAssetTriggerHelper
 * @purpose : Helper Class for MasterAssetTrigger
 * @history :
 * Version  Developer         Date          User Story/Purpose
 * 1.1      Dinesh Sharma     26/07/2021    Initial Development
 * 1.2      Anamika Shukla    20/09/2021    ES20-10369
 * 1.3      Joshraj Sen       08/11/2021    ES20-11439
 * 1.4      Swagat Shaw       14/01/2022    NCP-7826(Implement Sharing for D1 External Users)
 */

public with sharing class EDGE_MasterAssetTriggerHelper {
    
    //ES20-11439
    static final String qualityRecordTypeId=Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    /**
    * @description : checkAndGenerateSharing - To create sharing record on Insert
    * @return : void
    * @param : List<Master_Asset__c>
    */
    public static void checkAndGenerateSharing(List<Master_Asset__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');  
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Read');//NCP-7826
    }
    
    /**
    * @description : validateAndReGenerateSharing - Modify, Validate sharing record on update
    * @return : void
    * @param : List<Master_Asset__c>, Map<Id, SObject> 
    */
    public static void validateAndReGenerateSharing(List<Master_Asset__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Master_Asset__c> mapOldItems;
        List<Master_Asset__c> lstNewChangeGeography = new List<Master_Asset__c>();
        List<Master_Asset__c> lstOldChangeGeography = new List<Master_Asset__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Master_Asset__c>)oldItems;
        }
        
        for(Master_Asset__c objBusinessRole : newItems){
            if(mapOldItems.containsKey(objBusinessRole.Id) && objBusinessRole.Country__c != mapOldItems.get(objBusinessRole.Id).Country__c){
                lstNewChangeGeography.add(objBusinessRole);
                lstOldChangeGeography.add(mapOldItems.get(objBusinessRole.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
            D1_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');//NCP-7826
            D1_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Read');//NCP-7826
        }       
    }
    
    /**
    * @description : hasPriorityActive
    * @return : void
    * @param : List<SObject>, Map<Id, SObject>
    */
    public static void hasPriorityActive(List<SObject> newItems, Map<Id, SObject> oldItems){
        List<Master_Asset__c> newMasterAssetList = (List<Master_Asset__c>)newItems;
        Map<Id,Master_Asset__c> oldMasterAssetMap = (Map<Id,Master_Asset__c>)oldItems;
        Map<String,Integer> mapCountryPriorityCount = new Map<String,Integer>(); 
        List<sobject> lstCountryPriorityCount = new List<sobject>();
        if(newMasterAssetList!=null && newMasterAssetList.size()>0)
        {
            lstCountryPriorityCount = [Select Country__c,count(Id) from Master_Asset__c where Priority_Assets__c= true group by Country__c];
            if(lstCountryPriorityCount != null && lstCountryPriorityCount.size()>0 ){
                for(sobject cPriorityCount : lstCountryPriorityCount){
                    mapCountryPriorityCount.put((String) cPriorityCount.get('Country__c'), (Integer)cPriorityCount.get('expr0'));
                }
            }
        }
        if(newMasterAssetList!=null && newMasterAssetList.size()>0)
        {
            for(Master_Asset__c mAssetObj : newMasterAssetList ){
                Integer countryWithPriorityAssetcount = mapCountryPriorityCount.containsKey(mAssetObj.Country__c) ? mapCountryPriorityCount.get(mAssetObj.Country__c) : 0;

                //insert
                if(oldMasterAssetMap == null && mAssetObj.Priority_Assets__c == true && countryWithPriorityAssetcount != null){
                    countryWithPriorityAssetcount=countryWithPriorityAssetcount+1;
                    mapCountryPriorityCount.put(mAssetObj.Country__c, mapCountryPriorityCount.containsKey(mAssetObj.Country__c) ? countryWithPriorityAssetcount : 0);
                }
                //update
                else if(oldMasterAssetMap != null && oldMasterAssetMap.get(mAssetObj.Id) != null && oldMasterAssetMap.get(mAssetObj.Id).Priority_Assets__c!=mAssetObj.Priority_Assets__c){                    
                    //true -> false : deduct count
                    if(mAssetObj.Priority_Assets__c == false){
                        countryWithPriorityAssetcount = countryWithPriorityAssetcount - 1; 
                        mapCountryPriorityCount.put(mAssetObj.Country__c, mapCountryPriorityCount.containsKey(mAssetObj.Country__c) ? countryWithPriorityAssetcount : 0);                   
                    }
                    //false ->  : true : increase count
                    else if(mAssetObj.Priority_Assets__c == true){
                        countryWithPriorityAssetcount = countryWithPriorityAssetcount + 1; 
                        mapCountryPriorityCount.put(mAssetObj.Country__c, mapCountryPriorityCount.containsKey(mAssetObj.Country__c) ? countryWithPriorityAssetcount : 0);      
                    }    
                }
                if(countryWithPriorityAssetcount != null && (countryWithPriorityAssetcount < 1 || countryWithPriorityAssetcount > 3)){
                    mAssetObj.addError(System.label.EDGE_AddErrorPriorityAsset);
                }
            }
        }  
    }

    /**
    * @description : hasPendingForBatchActive
    * @return : void
    * @param : List<SObject>, Map<Id, SObject>
    */
    public static void hasPendingForBatchActive(List<SObject> newItems, Map<Id, SObject> oldItems){
        
        List<Master_Asset__c> masterAssetList=(List<Master_Asset__c>)newItems;
        Map<Id,Master_Asset__c> oldMap=new Map<ID,Master_Asset__c>();
        List<Master_Asset__c> updateList=new List<Master_Asset__c>();
        Set<Id> masterAssetId=new Set<Id>();
        Set<Id> accountId=new Set<Id>();
        Set<ID>territoryId=new Set<Id>();
        Set<ID> territoryHierarchiesId=new Set<Id>();
        List<Territory__c>territories=new List<Territory__c>();
        List<Territory_Hierarchy__c> territoryHierarchies=new List<Territory_Hierarchy__c>(); 
        
        //Null Check for Old Items
        if(oldItems!=null)
        {
            oldMap=(Map<Id,Master_Asset__c>)oldItems;
            for(Master_Asset__c masterAsset : masterAssetList){
                if(oldMap.containsKey(masterAsset.ID)){ 
                    Master_Asset__c oldMasterAsset=oldMap.get(masterAsset.ID);
                    if(oldMasterAsset.Priority_Assets__c!=masterAsset.Priority_Assets__c)
                        //Storing the Ids of the Master Assets whose priority checkbox has been changed
                        masterAssetId.add(masterAsset.Id);                    
                }
            }
            //Null Check for masterAsset List
            if(masterAssetId!=null && masterAssetId.size()>0)
            {
                for(Asset asset:[Select Id,AccountId FROM Asset where Master_Asset__c in :masterAssetId 
                                 AND AccountId!=null and Asset.RecordTypeId=:qualityRecordTypeId])
                {    
                    //Storing the Ids of the outlets from the Asset records
                    accountId.add(asset.AccountId);   
                }
                
                //Null Check for accountId List
                if(accountId!=null && accountId.size()>0)
                {
                    for(Outlet_Territory__c outletTerritory:[Select Id,Territory__c,Outlet__c From Outlet_Territory__c 
                                                             where Outlet__c in :accountId and Territory__c!=null])
                    {   
                        //Storing the Ids of the territories from outlet-territory records
                        territoryId.add(outletTerritory.Territory__c);
                    }
                    //Null Check for territoryId List
                    if(territoryId!=null && territoryId.size()>0) 
                    {
                        for(Territory__c territory:[Select Id,Region__c,Pending_For_Batch__c, Region__r.Pending_For_Batch__c
                                                    From Territory__c 
                                                    where Id in:territoryId and Region__c!=null 
                                                    and Pending_For_Batch__c!=true])
                        { 
                            //Storing the Ids of the regions from the territories
                            
                            territory.Pending_For_Batch__c=true;
                            territories.add(territory);
                            
                            Id regionId = territory.Region__c;
                            
                            if(regionId != null && !territoryHierarchiesId.contains(regionId)){
                                Territory_Hierarchy__c th = new Territory_Hierarchy__c();
                                th.Id = regionId;
                                th.Pending_For_Batch__c = true;
                                territoryHierarchies.add(th);
                                territoryHierarchiesId.add(regionId);
                            }
                        }
                        
                        //Updating the territories
                        if(territories != null && territories.size()> 0 && Schema.sObjectType.Territory__c.isUpdateable()){
                            Database.update(territories);
                        }
                        
                        //Updating the regions
                        if(territoryHierarchies != null && territoryHierarchies.size()> 0 && 
                           Schema.sObjectType.Territory_Hierarchy__c.isUpdateable())
                        {
                            Database.update(territoryHierarchies);
                        }
                    }
                }        
            }  
        }
    }
}