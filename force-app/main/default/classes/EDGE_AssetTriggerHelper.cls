/**

* @Description: EDGE_AssetTriggerHelper

* @Purpose : Helper class for AssetTriggerHandler

* @History:

* @Version     Developer		   Date			    Story/Purpose

*    1.1       Aparajita		27/09/2021		   ES20-10414(Method:populateInstallDate)   
*	 1.2       Prasanth         26/09/2021         ES20-10398(Method:populateAssetName)
*    1.3 	   Aparajita        07/10/2021         ES20-11091(Method:restrictDuplicateNonCOPAssets)
*	 1.4	   Saranya L		08/10/2021		   ES20-10415(Method:populateProductDetails)
*	 1.5	   Saurav Paul		08/10/2021		   ES20-9930(Method:populateRemovalDate)
*    1.6	   Subhodeep Sarkar 15/11/2021.        ES20-11438(Method:enablePendingForBatch)
*    1.7	   Rajarshi Lahiri	06/12/2021		   ES20-11646(Method:validateOffsetDay)
*    1.8       Anamika Shukla   24/01/2022         ES20-11918(Method:populateAssetName modified)
*	 1.9	   Aparajita		14/05/2022		   ES20-12149,ES20-12849,ES20-12768,ES20-13013(Method:restrictDuplicateNonCOPAssets,concatFieldValues)
*    2.0       Anamika Shukla   06/03/2022         ES20-ES20-11517(Method:populateRemovalDate modified)
*    2.1       Wribhu 			02/05/2023		   GT-26: Implementation story for adding the filter for Quality record type for the Quality Assets instances
*/

public with sharing class EDGE_AssetTriggerHelper 
{
    public static String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        
    /**

* @description : populateInstallDate - Populate install date as today's date if user leaves it blank

* @return : void

* @param : List<SObject>

*/
    public static void populateInstallDate(List<SObject> newItems)
    {
        List<Asset> assetList = filterAssetRecs((List<Asset>)newItems);//GT-26       
        if(assetList!=null && assetList.size()>0){
            for(Asset assetObj : assetList){
                if(assetObj.InstallDate == null){
                    assetObj.InstallDate = Date.today();
                }
            }
        }
    }
    
    /**

* @description : populateAssetName - Validation for asset Name, if Master Asset object has Line Cleaning Asset as True, its name should be Asset Name

* @return : void

* @param : List<SObject>

*/
    public static void populateAssetName(List<SObject> newItems, Map<Id, SObject> oldItems){
        //New Asset List        
        List<Asset> newAssetList = filterAssetRecs((List<Asset>)newItems);//GT-26
        //Old Asset Map
        Map<Id,Asset> oldAssetMap = (Map<Id,Asset>)oldItems;        							
        //Master Asset Id Set
        Set<Id> masterAssetIdSet = new Set<Id>();
        Id profileId = UserInfo.getProfileId();
        List<String> profileNameList = System.Label.EDGE_ProfileForAsset.split(',');
        String profileName = [Select id,Name from Profile where id=:profileId].Name;
        
        //Master Asset Line Cleaning Asset Map
        Map<Id,Master_Asset__c> masterLineCleanMap  = new Map<Id,Master_Asset__c>();
        if(newAssetList != null && newAssetList.Size()> 0){
            for(Asset newAsset: newAssetList){
                masterAssetIdSet.add(newAsset.Master_Asset__c);
            }   
        }
        //Query to fetch masterLineCleanMap
        if(masterAssetIdSet != null && masterAssetIdSet.Size() > 0){
            for(Master_Asset__c masterAsset : [SELECT Id,Name FROM Master_Asset__c WHERE Id =:masterAssetIdSet]){
                masterLineCleanMap.put(masterAsset.Id,masterAsset);
            }
        }
        //New Asset Name check for INSERT & UPDATE--> ES20-11918 Start
        if(newAssetList != null && newAssetList.Size()> 0){            
            for(Asset assetObj : newAssetList){ 
                if(masterLineCleanMap.get(assetObj.Master_Asset__c) != null){
                    Master_Asset__c mAssetObj = masterLineCleanMap.get(assetObj.Master_Asset__c);
                    if(assetObj.Name != mAssetObj.Name && oldAssetMap == null){
                        assetObj.Name = mAssetObj.Name;
                    }
                    else if(oldAssetMap != null){
                        if((assetObj.Master_Asset__c != oldAssetMap.get(assetObj.Id).Master_Asset__c || assetObj.Name != mAssetObj.Name)){ 
                            if(!(profileNameList.contains(profileName))){ 
                               assetObj.Name = mAssetObj.Name;  
                            } 
                        }
                    }  
                }                
            }
        }
        //ES20-11918-->END
    }
    //GT-26
    public static List<Asset> filterAssetRecs(List<Asset> newAssetList){
        List<Asset> returnAssetLst = new List<Asset>();
        if(!newAssetList.isEmpty()){
            for(Asset assetRec:newAssetList){
                if(assetRec.RecordTypeId == qualityAssetRecordTypeId){
                    returnAssetLst.add(assetRec);
                }
            }
        }
        return returnAssetLst;
    }
    
    /**
* @description : populateProductDetails - Populate Product as Product_Master__c of master asset if branded asset is true

* @return : void

* @param : List<SObject>

*/

    public static void populateProductDetails(List<SObject> newItems, Map<Id, SObject> oldItems)
    {
        List<Asset> newAssetList = filterAssetRecs((List<Asset>)newItems);//GT-26
        Map<Id,Asset> oldAssetMap = (Map<Id,Asset>)oldItems;        
        Set<Id> masterAssetIdSet = new Set<Id>();
        Map<Id,Master_Asset__c> masterAssetMap  = new Map<Id,Master_Asset__c>();
        if(newAssetList != null && newAssetList.Size()> 0){
            for(Asset newAsset: newAssetList){
                masterAssetIdSet.add(newAsset.Master_Asset__c);
            }   
        }
        if(masterAssetIdSet != null && masterAssetIdSet.Size() > 0){
            for(Master_Asset__c masterAsset : [SELECT Id,Name,Branded_Asset__c,Product_Master__c FROM Master_Asset__c WHERE Id =:masterAssetIdSet]){
                masterAssetMap.put(masterAsset.Id,masterAsset);
            }
        }
        if(newAssetList != null && newAssetList.Size()> 0){            
            for(Asset assetObj : newAssetList){ 
                if(masterAssetMap.get(assetObj.Master_Asset__c) != null){
                    Master_Asset__c mAssetObj = masterAssetMap.get(assetObj.Master_Asset__c);
                    
                    if(mAssetObj.Branded_Asset__c == True && assetObj.Product__c != mAssetObj.Product_Master__c && oldAssetMap == null){
                        assetObj.Product__c = mAssetObj.Product_Master__c;
                    }
                    else if(oldAssetMap != null && mAssetObj.Branded_Asset__c == True){
                        if(assetObj.Master_Asset__c != oldAssetMap.get(assetObj.Id).Master_Asset__c || assetObj.Product__c != mAssetObj.Product_Master__c){
                            assetObj.Product__c = mAssetObj.Product_Master__c;
                        }
                    }
                }
            }
            
        }
    }
    
    /**
* @description : This method is used to populate Removal Date if Assetis marked as Removed (ES20-9930) 
* @return : void
* @param : List<Asset>,Map<Id,SObject> oldMap
*/
    public static void populateRemovalDate(List<Asset> newItemsLst, Map<Id,SObject> oldMap){
        
        List<Asset> newItems = filterAssetRecs(newItemsLst); //GT-26  
        DateTime currentUserTime = DateTime.valueOf(DateTime.now().format('yyyy-MM-dd HH:mm:ss')); //changes made by Aparajita for ES20-11468
     
        Map<Id,Asset> oldAssetMap;
        if(oldMap!= null){
            oldAssetMap = (Map<Id,Asset>) oldMap;
        }
        for(Asset assetObj : newItems){
            if(oldMap == null && assetObj.Asset_Removed__c && assetObj.Asset_Removal_Date__c == null){
                assetObj.Asset_Removal_Date__c = currentUserTime ;
            }else if(oldMap!= null && oldAssetMap.containsKey(assetObj.Id) 
                     && assetObj.Asset_Removed__c &&((oldAssetMap.get(assetObj.Id).Asset_Removed__c!=assetObj.Asset_Removed__c)
                                                     &&(oldAssetMap.get(assetObj.Id).Asset_Removal_Date__c == null && assetObj.Asset_Removal_Date__c == null))){
                                                         assetObj.Asset_Removal_Date__c = currentUserTime;   
                                                     }
            else if(oldMap!= null && oldAssetMap.containsKey(assetObj.Id) 
                    && !assetObj.Asset_Removed__c &&((oldAssetMap.get(assetObj.Id).Asset_Removed__c!=assetObj.Asset_Removed__c)
                                                     &&(oldAssetMap.get(assetObj.Id).Asset_Removal_Date__c != null && assetObj.Asset_Removal_Date__c != null))){
                                                         assetObj.Asset_Removal_Date__c = null;  
                                                     }
            else if(assetObj.isClone()== true){
                if(!assetObj.Asset_Removed__c){
                    assetObj.Asset_Removal_Date__c = null;
                }
            }
        }
    }
    
    /**
* @description : This method is used to populate Pending for Batch checkbox (ES20-11438) 
* @return : void
* @param : List<Asset>,Map<Id,SObject> oldMap
*/
    public static void enablePendingForBatch(List<Asset> newItems,Map<Id,SObject> oldItems){
        
        Map<Id,Asset> oldAssetMap= (Map<Id,Asset>) oldItems;//old asset map
        List<Asset> newAssetList = filterAssetRecs(newItems); //new asset list //GT-26
        //Set<Id> masterAssetIdSet = new Set<Id>();
        Map<Id, boolean> masterAssetMap = new  Map<Id, boolean>();
        List<Id> accId = new List<Id>();
        Set<Id> masterAssetIdcheck = new Set<Id>();
        List<Id> accIdCheck = new List<Id>();
        Map<Id,Id> accTerrMap = new Map<Id,Id>();
        Map<Id,Id> terrHMap = new Map<Id,Id>();
        Map<Id, boolean> terrPendingBatch = new  Map<Id, boolean>();
        Map<Id,boolean> terrHiePendingBatch = new  Map<Id, boolean>();
        Map<Id,Territory__c> idTerritoryMap = new Map<Id,Territory__c>();
        Map<Id,Territory_Hierarchy__c> idTerritoryHierarchyMap = new Map<Id,Territory_Hierarchy__c>();
        
        List<Territory__c> updatePendingListTerr =  new List<Territory__c >();
        List<Territory_Hierarchy__c> updatePendingListTH =  new List<Territory_Hierarchy__c >();
        Set<Id> assetIds = new Set<Id>();
        Set<Id> eligibleAssetIds = new Set<Id>();
        
        if (newAssetList!=null && newAssetList.Size()>=0){
            for (Asset assetobj : newAssetList){
                if(assetobj.Id != null){
                    assetIds.add(assetobj.Id);
                }
            }
        }
        
        if (assetIds!=null && assetIds.Size()>=0){
            for(Asset assetRec : [Select Id,  Master_Asset__r.Priority_Assets__c FROM Asset where Master_Asset__r.Priority_Assets__c = true
                                  AND Id in :assetIds]){
                                      eligibleAssetIds.add(assetRec.Id);
                                  }
        }        
        
        //adding updated assets to the list of master
        if (newAssetList!=null && newAssetList.Size()>=0){
            for (Asset assetobj : newAssetList){
                if(oldAssetMap != null && oldAssetMap.Size()>0){//Update scenario
                    
                    if(eligibleAssetIds.contains(assetobj.Id)){
                        if(oldAssetMap.get(assetObj.Id)!=null){
                            Asset oldAsset= oldAssetMap.get(assetObj.Id);
                            
                            if (oldAsset.Asset_Removed__c != assetObj.Asset_Removed__c){
                                masterAssetIdcheck.add(assetObj.Master_Asset__c);
                                accIdCheck.add(assetObj.AccountId);
                            }   
                        }
                    }
                    
                }
                else{
                    masterAssetIdcheck.add(assetObj.Master_Asset__c);
                    accIdCheck.add(assetObj.AccountId);
                }
            }           
        }
        
        if (masterAssetIdcheck!=null && masterAssetIdcheck.Size()>=0){
            for(Master_Asset__c masterassetObj : [Select Id, Priority_Assets__c FROM Master_Asset__c where Id=:masterAssetIdcheck]){
                masterAssetMap.put(masterassetObj.Id,masterassetObj.Priority_Assets__c);
            }
        }
        if(accIdCheck != null && accIdCheck.size()>0){
            for(Outlet_Territory__c oterr : [Select Id, Outlet__c, Territory__c,Territory__r.Region__c, 
                                             Territory__r.Pending_For_Batch__c,
                                             Territory__r.Region__r.Pending_For_Batch__c from Outlet_Territory__c 
                                             where Outlet__c IN :accIdCheck])
            {
                terrPendingBatch.put(oterr.Territory__c,oterr.Territory__r.Pending_For_Batch__c);
                if(oterr.Territory__r.Region__c != null){
                    terrHMap.put(oterr.Territory__c,oterr.Territory__r.Region__c);
                    terrHiePendingBatch.put(oterr.Territory__r.Region__c, oterr.Territory__r.Region__r.Pending_For_Batch__c);
                    
                }
            }
        }
        
        if(terrPendingBatch != null && terrPendingBatch.size() > 0){
            for (Id territoryId : terrPendingBatch.keyset()){
                if(terrPendingBatch.get(territoryId) == false){
                    Territory__c territoryObj = new Territory__c();
                    territoryObj.Id = territoryId;
                    territoryObj.Pending_for_Batch__c = true;
                    if(!idTerritoryMap.containsKey(territoryObj.Id)){
                        idTerritoryMap.put(territoryObj.Id,territoryObj);
                    }
                }
                    if(terrHMap.containskey(territoryId)){
                        Id terrHieId = terrHMap.get(territoryId);
                        if(terrPendingBatch.get(territoryId) == false){
                            Territory_Hierarchy__c territoryHierarchyObj = new Territory_Hierarchy__c();
                            territoryHierarchyObj.Id = terrHieId;
                            territoryHierarchyObj.Pending_for_Batch__c = true;
                            if(!idTerritoryMap.containsKey(territoryHierarchyObj.Id)){
                                idTerritoryHierarchyMap.put(territoryHierarchyObj.Id,territoryHierarchyObj);
                            }
                        }
                    }
                }
            }
        if(Schema.sObjectType.Territory__c.isUpdateable() && idTerritoryMap!= null && idTerritoryMap.size() > 0){
            updatePendingListTerr = idTerritoryMap.values();
             Database.update(updatePendingListTerr);
        }
        if(Schema.sObjectType.Territory__c.isUpdateable() && idTerritoryHierarchyMap!= null && idTerritoryHierarchyMap.size() > 0){
            updatePendingListTH = idTerritoryHierarchyMap.values();
             Database.update(updatePendingListTH);        
        }    
    }
    
    /**

* @description : validateOffsetDay - check if asset Offset day is greater than LC cycle duration

* @return : void

* @param : List<SObject>

*/
    public static void validateOffsetDay(List<SObject> newItems)
    {
        List<Asset> assetList =  filterAssetRecs((List<Asset>)newItems);//GT-26
        Map<Asset,Id> assetAccountMap=new Map<Asset,Id>();
        Map<Id,String> accountCountryMap=new Map<Id,String>();
        Decimal LCDuration;
        Set<String> countryCode = new Set<String>();
        Set<Id> accountIdSet=new Set<Id>();
        Map<String,Decimal> countryLCMap=new Map<String,Decimal>();
        if(assetList!=null && assetList.size()>0){
            List<String> countryCodes=System.label.Asset_Offset_Day_Validation_Markets.split(',');
            if(Schema.sObjectType.Market_Setting__c.isAccessible()){
                for(Market_Setting__c mks : [select Geography__r.Code__c, Line_Cleaning_Duration__c from Market_Setting__c where Geography__r.Code__c IN :countryCodes]){
                    countryLCMap.put(mks.Geography__r.Code__c, mks.Line_Cleaning_Duration__c);
                }
            }
            
            //Use the countryLCMap to get the LC Duration for the country of asset and check the condition
            for(Asset assetObj : assetList){
                if(countryLCMap.containsKey(assetObj.Country_code__c)){
                    LCDuration = countryLCMap.get(assetObj.Country_code__c);
                    if(LCDuration != null && assetObj.Offset_Day__c > LCDuration){
                        assetObj.addError(System.label.Offset_Greater_Than_LC_Duration);
                    }
                }
            }
        }
    }
     /**

* @description : enableOffsetDayFlag - check if asset Offset day is changed

* @return : void

* @param : List<SObject>,Map<Id,SObject>

*/
    
    public static void enableOffsetDayFlag(List<SObject> newItems,Map<Id,SObject> oldItems){

        List<Asset> assetList = filterAssetRecs((List<Asset>)newItems);//GT-26
        Map<Id,Asset> oldAssetMap= (Map<Id,Asset>) oldItems;
        
        if(assetList != null && assetList.Size() > 0){
            for(Asset assetRec:assetList){
                if(oldAssetMap != null && oldAssetMap.Size() > 0){
                    Asset oldAsset = oldAssetMap.get(assetRec.Id);
                    if(oldAsset.Offset_Day__c != assetRec.Offset_Day__c ||oldAsset.Quantity != assetRec.Quantity || oldAsset.Product__c != assetRec.Product__c){
                        assetRec.Is_OffsetDay_Changed__c = true;
                    }
                }
            }
        }               
    }    
    
    /**
* @description : restrictDuplicateNonCOPAssets : restricting duplicate Assets based on MS field values -> ES20-12149,ES20-12849,ES20-12768,ES20-13013
* @return : void
* @param : List<SObject> newItems, Map<Id,SObject> oldItems
*/
    public static void restrictDuplicateNonCOPAssets(List<SObject> newItems, Map<Id,SObject> oldItems)
    {	
        //Assignment
        List<Asset> newAssetList = filterAssetRecs((List<Asset>)newItems);//GT-26
        List<String> allValueList= new List<String>();
        Map<Id,Id> mAsstCountryMap = new Map<Id,Id>();
        Map<Id,Asset> oldAssetMap= (Map<Id,Asset>) oldItems;
        Map<String,String> labelVsApiMap = new Map<String,String>();
        Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
        Map<Id,List<String>> mktSettingMap = new Map<Id,List<String>>();
        Map<Id,Set<String>> assetFieldValueMap = new Map<Id,Set<String>>();
        Map<String,String> valueVsAssetMap = new Map<String,String>();
        Set<Id> accIdSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> assetIdSet = new Set<Id>();
        Set<Id> masterAssetSet = new Set<Id>();
        
        //Creating a set of masterAssetIds from newItems
        if(newAssetList!=null && newAssetList.size()>0){
            for(Asset newAsset : newAssetList){
                if(newAsset.Asset_Removed__c == FALSE && newAsset.AccountId != NULL && newAsset.Master_Asset__c != NULL)
                {
                    masterAssetSet.add(newAsset.Master_Asset__c);
                    accIdSet.add(newAsset.AccountId); //ES20-12849
                }
            }
        }
        
        //Creating a mapping between MasterAsset & Country for newItems to use later
        if(masterAssetSet!=null && masterAssetSet.size()>0){
            for(Master_Asset__c mAsst : [SELECT Id, Country__c FROM Master_Asset__c WHERE Active__c = TRUE AND COP__c = FALSE AND Serialized__c = FALSE AND Id IN : masterAssetSet]){
                mAsstCountryMap.put(mAsst.Id, mAsst.Country__c);
                countryIdSet.add(mAsst.Country__c);
            }
        }
        
        //Listing all picklist values from New_Asset_Validation__c picklist        
        Schema.DescribeFieldResult fieldResult = Market_Setting__c.New_Asset_Validation__c.getDescribe();
        if(fieldResult.getPicklistValues()!=null){
            for(Schema.PicklistEntry pickListVal : fieldResult.getPicklistValues()){
                allValueList.add(pickListVal.getLabel());
            }    
        }
        
        //Creating a mapping between Country & New_Asset_Validation__c selected values
        if(countryIdSet!=null && countryIdSet.size()>0){
            for(Market_Setting__c mktSetting : [select Id, Geography__c, New_Asset_Validation__c from Market_Setting__c 
                                                WHERE Geography__c IN : countryIdSet AND New_Asset_Validation__c!=null])
            {      
                mktSettingMap.put(mktSetting.Geography__c, mktSetting.New_Asset_Validation__c.split(';'));    
            }
        }
        
        //Running the below validation logic if New_Asset_Validation__c field has value/s
        if(mktSettingMap.values()!=null && mktSettingMap.values().size()>0){ 
            
            //Mapping labels & api names of the fields mentioned in the New_Asset_Validation__c picklist
            for(Schema.SObjectField fld : schemaMap.get('Asset').getDescribe().fields.getMap().values()){
                String fldLabel = fld.getDescribe().getLabel();
                String fldApiName = fld.getDescribe().getName();
                
                //Removing the suffix ' ID' from the labels of standard-reference fields
                if(!fld.getDescribe().isCustom() && fldLabel.endsWith(' ID')){
                    fldLabel = fldLabel.removeEnd(' ID');
                }
                
                //Including only those fields in the map that are present in the New_Asset_Validation__c picklist
                if(allValueList.contains(fldLabel)){
                    labelVsApiMap.put(fldLabel, fldApiName);  
                }       
            }
            
            //Looping over existing non-COP, non-Serialized and not Removed assets       
            for(Asset existingAsset : [SELECT Id,RecordTypeId, Account.Country__c, Master_Asset__c, AccountId, Asset_Location__c, Product__c, Asset_Owner__c, Asset_Used_By__c, 
                                       InstallDate FROM Asset WHERE Asset_Removed__c = FALSE AND Master_Asset__r.Active__c = TRUE AND Master_Asset__r.COP__c = FALSE  
                                       AND Master_Asset__r.Serialized__c = FALSE AND Account.Country__c IN : countryIdSet AND AccountId IN : accIdSet AND RecordTypeId =:qualityAssetRecordTypeId]) //ES20-12849 //GT-26
            {
                Id countryId = existingAsset.Account.Country__c;

                //Creating a string of field values selected in the New_Asset_Validation__c picklist per asset
                String selectedValueString = concatFieldValues(labelVsApiMap, mktSettingMap, existingAsset, countryId);
                
                //Creating a mapping between Country and the set of unique strings    
                if(assetFieldValueMap.containsKey(countryId)){
                    assetFieldValueMap.get(countryId).add(selectedValueString);
                }else{
                    assetFieldValueMap.put(countryId, new Set<String>{selectedValueString});
                }           
                
                //Creating a mapping between unique combination and its corresponding unique asset for each country -> ES20-13013
                String cmpKey = countryId + '_' + selectedValueString;
                valueVsAssetMap.put(cmpKey,existingAsset.Id);
            }  
            
            //Looping over newItems
            if(newAssetList!=null && newAssetList.size()>0){
                for(Asset newAsset : newAssetList){
                    
                    Id countryId = mAsstCountryMap.get(newAsset.Master_Asset__c);
                    String selectedValueString = '';
                    
                    //Creating a string of field values selected in the New_Asset_Validation__c picklist per asset
                    if(newAsset.Asset_Removed__c==false){ //ES20-13013
                        selectedValueString = concatFieldValues(labelVsApiMap, mktSettingMap, newAsset, countryId);
                    }
                    
                    if(selectedValueString!=null && selectedValueString!='' && assetFieldValueMap!=null && assetFieldValueMap.size()>0){ //Master Asset & Account are mandatory hence the returned string cannot be null                     
                            
                        //If this string matches with a value in the map for existing assets then throw error
                        if(assetFieldValueMap.get(countryId).contains(selectedValueString)){
                            String cmpKey = countryId + '_' + selectedValueString;
                            
                            //Insert scenario
                            if(oldAssetMap==null){ 
                            newAsset.addError(System.label.EDGE_DuplicateAssetErrorMsg); 
                        }                        
                            //Update scenario
                            else if(oldAssetMap!=null && valueVsAssetMap.get(cmpKey) != oldAssetMap.get(newAsset.Id).Id){ //ES20-13013
                                newAsset.addError(System.label.EDGE_DuplicateAssetErrorMsg); 
                            }
                        }
                        //If this string is unique, then add it to the map for existing assets
                        else{
                            assetFieldValueMap.get(countryId).add(selectedValueString);
                        } 
                    }
                }
            }   
        }
    }
    
    /**
* @description : concatFieldValues : Concatenates string of field values which are selected in New_Asset_Validation__c picklist in MS for each asset -> ES20-12149
* @return : String
* @param : Map<String, String> labelVsApiMap, Map<Id, List<String>> mktSettingMap, Asset assetRec, Id countryId
*/
    public static String concatFieldValues(Map<String, String> labelVsApiMap, Map<Id, List<String>> mktSettingMap, Asset assetRec, Id countryId){
        
        //Listing all the selected values from the New_Asset_Validation__c picklist
        List<String> selectedValueList = mktSettingMap.get(countryId);
        String selectedValueString = '';
        
        //Fetching the api names of the selected fields->fetching the field values->generating the concatenated string to return
        if(selectedValueList.size()==1){ //one value is selected
            String apiName = labelVsApiMap.get(selectedValueList.get(0));
            String assetFieldValue = String.valueOf(assetRec.get(apiName));
            selectedValueString = assetFieldValue;
        }else{ //multiple values are selected
            selectedValueList.sort();
            for(String selectedValue : selectedValueList){
                String apiName = labelVsApiMap.get(selectedValue);
                String assetFieldValue = String.valueOf(assetRec.get(apiName));
                selectedValueString = selectedValueString + assetFieldValue + ';';
            }
        }
        return selectedValueString;
    }
}