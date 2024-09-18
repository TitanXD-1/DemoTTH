/*
* @description :  EDGE_TerritoryProcessStatusUpdateHelper

* @purpose : This is the Helper class for the batch class EDGE_TerritoryProcessStatusUpdateBatch
			 & Related to EDGE_TerritoryProcessStatusUpdateHlpExtn Helper class

* @Test Class: EDGE_TerritoryProcessStUpdateBatchTest

* @history :

* Version    Developer         		Date           			User Story/Purpose
	1.0		Dipanjan Das		24.06.2024			154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
	1.0		Sudipta Nandy		24.06.2024			154640 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
*/
/**
 * @description Helper for EDGE_TerritoryProcessStatusUpdateBatch
 */
public without Sharing class EDGE_TerritoryProcessStatusUpdateHelper {
   
    Public static Id salesTerrRecTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Sales_Territory').getRecordTypeId();
    Public static Id qualityTerrRecTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Quality_Territory').getRecordTypeId();
    Public static Id activationTerrRecTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Activation_Territory').getRecordTypeId();
		
/** 
* @description  Fetching Territory Member based on territory record type and territory type
* @return  EDGE_TerritoryProcessWrapper
* @param outletTerrActiveList
**/
	public static EDGE_TerritoryProcessWrapper generateTerrWithUserMap(List<Outlet_Territory__c> outletTerrActiveList){		
		Date currentDate = Date.today();
		Date yesterdayDate = Date.today().addDays(-1);
		EDGE_TerritoryWrapper terrWrap = new EDGE_TerritoryWrapper();
		EDGE_TerritoryProcessWrapper wrapperVariable = new EDGE_TerritoryProcessWrapper();
		wrapperVariable.salesTerrRepMap = new Map<Id,Id>();
		wrapperVariable.dispenseRepMemberMap = new Map<Id, String>();
		wrapperVariable.activationRepMemberMap = new Map<Id,Id>();
		List<Trax_User_Update__c> traxUserUpdate=new List<Trax_User_Update__c>();
		terrWrap = getTerritoryWrapper(outletTerrActiveList);
		if (Schema.sObjectType.Territory_Member__c.isAccessible()){
			for(Territory_Member__c terMemObj :[SELECT Id,User__c,User__r.Profile.Name,Start_Date__c,End_Date__c,Territory__c,Type__c,User__r.Trax_User__c,User__r.Default_Country__c,User__r.Available_Countries__c,User__r.Name from Territory_Member__c 
												 WHERE Territory__c IN:terrWrap.territoryIdSet AND Start_Date__c <= :currentDate AND Type__c = 'Primary' AND (End_Date__c = null OR End_Date__c > :yesterdayDate)]){
                if(terrWrap.salesTerrIdSet.contains(terMemObj.Territory__c)){
                    wrapperVariable.salesTerrRepMap.put(terMemObj.Territory__c,terMemObj.User__c); 
                }else if(terrWrap.dispenseTerrIdSet.contains(terMemObj.Territory__c)){
                    wrapperVariable.dispenseRepMemberMap.put(terMemObj.Territory__c,terMemObj.User__r.Name);
                }else if(terrWrap.activationTerIdSet.contains(terMemObj.Territory__c)){
                    wrapperVariable.activationRepMemberMap.put(terMemObj.Territory__c,terMemObj.User__c);
                }
				if(terMemObj.User__r.Trax_User__c){
					String countryCode = EDGE_BatchUtilityClass.getUserCountryCode(terMemObj.User__r.Default_Country__c, terMemObj.User__r.Available_Countries__c);
					traxUserUpdate.add(new Trax_User_Update__c(name=terMemObj.User__c,Country_Code__c=countryCode));                      
				}				
			}
			wrapperVariable.traxUserUpdate = traxUserUpdate;
		}
		return wrapperVariable;
	}
    
/** 
* @description  Fetching Territory List based on territory record type and territory type
* @return EDGE_TerritoryWrapper 
* @param  outletTerrActiveList
**/
	public static EDGE_TerritoryWrapper getTerritoryWrapper(List<Outlet_Territory__c> outletTerrActiveList){
		EDGE_TerritoryWrapper terrWrap = new EDGE_TerritoryWrapper(); 
		terrWrap.territoryIdSet = new Set<Id>(); 
		terrWrap.salesTerrIdSet = new Set<Id>(); 
		terrWrap.dispenseTerrIdSet = new Set<Id>(); 
		terrWrap.activationTerIdSet = new Set<Id>(); 
		for(Outlet_Territory__c outletTerritory : outletTerrActiveList){
            terrWrap.territoryIdSet.add(outletTerritory.Territory__c);
			if(outletTerritory.Territory__r.RecordTypeId == salesTerrRecTypeId){
				terrWrap.salesTerrIdSet.add(outletTerritory.Territory__c);
			}else if(outletTerritory.Territory__r.RecordTypeId == qualityTerrRecTypeId 
			   && outletTerritory.Territory__r.Territory_Type__c=='Quality Dispense'){
				terrWrap.dispenseTerrIdSet.add(outletTerritory.Territory__c);
			}else if(outletTerritory.Territory__r.RecordTypeId == activationTerrRecTypeId){
				terrWrap.activationTerIdSet.add(outletTerritory.Territory__c);
			}                
        }
		return terrWrap;
	}	
    
    /** 
* @description  Active outlet-territory which are in Waiting Activation
* @return  EDGE_TerritoryProcessWrapper
* @param wrapperVariable
* @param outletTerrActiveList
**/

	public static EDGE_TerritoryProcessUpdateWrapper activateOutletTerritory(EDGE_TerritoryProcessWrapper wrapperVariable, List<Outlet_Territory__c> outletTerrActiveList){
		Set<Territory__c> territorySet = new Set<Territory__c>();
		List<Account> outletsToUpdateList = new List<Account>();
		List<Account> activationTerrAccListToUpdate = new List<Account>();
		List<Account> dispenseRepAccListToUpdate = new List<Account>();
		Map<Id, List<Id>> outletWithRegionListMapToShare = new Map<Id, List<Id>>();
		List<Outlet_Territory__c> updateOTList = new List<Outlet_Territory__c>();
		EDGE_TerritoryProcessUpdateWrapper terrUpdateWrap = new EDGE_TerritoryProcessUpdateWrapper();
		terrUpdateWrap.territoryListtoUpdate = new List<Territory__c>();
		for(Outlet_Territory__c outletTerritory : outletTerrActiveList){
			if(outletTerritory.Territory__r.RecordTypeId == salesTerrRecTypeId){
				Id userId = wrapperVariable.salesTerrRepMap.containsKey(outletTerritory.Territory__c)? wrapperVariable.salesTerrRepMap.get(outletTerritory.Territory__c) : null;
				Account outletToUpdate = primarySalesTerDetailsPopulate(outletTerritory, userId);
				outletsToUpdateList.add(outletToUpdate);
				territorySet.add(primarySalesRepPopulate(outletTerritory,userId));
			}else if(outletTerritory.Territory__r.RecordTypeId == activationTerrRecTypeId){
				//activationTerrAccListToUpdate.add(accObj);
				activationTerrAccListToUpdate.add(getActivationAccountToUpdate(wrapperVariable.activationRepMemberMap, outletTerritory));
			}else if(outletTerritory.Territory__r.RecordTypeId == qualityTerrRecTypeId && outletTerritory.Territory__r.Territory_Type__c=='Quality Dispense'){
				Account accObj = new Account(Id = outletTerritory.Outlet__c);
				accObj.Dispense_Rep__c = wrapperVariable.dispenseRepMemberMap.containsKey(outletTerritory.Territory__c) ? wrapperVariable.dispenseRepMemberMap.get(outletTerritory.Territory__c) : null;
				dispenseRepAccListToUpdate.add(accObj);
			}
			outletWithRegionListMapToShare = generateOutletWithRegionMapToShare(outletWithRegionListMapToShare, outletTerritory);
			outletTerritory.Active__c = EDGE_Constant.ACTIVE;
			updateOTList.add(outletTerritory);	
		}
		terrUpdateWrap.outletsToUpdateList = outletsToUpdateList;
		terrUpdateWrap.activationTerrAccListToUpdate = activationTerrAccListToUpdate;
		terrUpdateWrap.dispenseRepAccListToUpdate = dispenseRepAccListToUpdate;
		terrUpdateWrap.territoryListtoUpdate.addAll(territorySet);
		terrUpdateWrap.outletWithRegionListMapToShare = outletWithRegionListMapToShare;
		terrUpdateWrap.updateOTList = updateOTList;
		return terrUpdateWrap;
	}
    
        /** 
* @description  Popluating Account Details for Activation type o-t
* @return  Account
* @param activationRepMemberMap
* @param outletTerritory
**/

	public static Account getActivationAccountToUpdate(Map<Id,Id> activationRepMemberMap, Outlet_Territory__c outletTerritory){
		Account accObj = new Account(Id = outletTerritory.Outlet__c);
		accObj.Activation_Territory_LT__c = outletTerritory.Territory__c;
		accObj.Activation_Specialist__c = activationRepMemberMap.containsKey(outletTerritory.Territory__c) ? activationRepMemberMap.get(outletTerritory.Territory__c) : null;
		return accObj;
	}
	
 /** 
* @description  generate outlet with region map
* @return  Map<Id, List<Id>>
* @param outletWithRegionListMapToShare
* @param outletTerritory
**/
	public static Map<Id, List<Id>> generateOutletWithRegionMapToShare(Map<Id, List<Id>> outletWithRegionListMapToShare, Outlet_Territory__c outletTerritory){
		if(outletTerritory.Territory__r.RecordTypeId != activationTerrRecTypeId && outletTerritory.Territory__r.Region__c != null){
			if(outletWithRegionListMapToShare.containsKey(outletTerritory.Outlet__c)){
				outletWithRegionListMapToShare.get(outletTerritory.Outlet__c).add(outletTerritory.Territory__r.Region__c);
			}
			else{
				outletWithRegionListMapToShare.put(outletTerritory.Outlet__c,new List<Id>{outletTerritory.Territory__r.Region__c});
			}						
		}
		return outletWithRegionListMapToShare;
	}
        /** 
* @description  Popluating Account Details for Sales type o-t
* @return  Account
* @param outTerObj
* @param userId
**/
    public static Account primarySalesTerDetailsPopulate(Outlet_Territory__c outTerObj, Id userId){
        Id tempAccountId = outTerObj.Outlet__c;
        Account tempAcctObj = new Account(Id=tempAccountId);
        tempAcctObj.Primary_Sales_Territory__c = outTerObj.Territory__c;
        tempAcctObj.Primary_Sales_Territory_Region__c = outTerObj.Territory__r.Region__c;
        tempAcctObj.Primary_Sales_Area__c = outTerObj.Territory__r.Region__r.Parent_BU__c;
        tempAcctObj.Primary_Sales_Territory_Business_Unit__c = outTerObj.Territory__r.Region__r.Parent_BU__r.Parent_BU__c;
        tempAcctObj.Primary_Sales_Rep__c=userId;
        return tempAcctObj;
    }	
	
          /** 
* @description  Method added populate primary sales rep in territory for US-1783
* @return  Territory__c
* @param outTerObj
* @param userId
**/

    public static Territory__c primarySalesRepPopulate(Outlet_Territory__c outTerObj, Id userId){
        Id territoryId = outTerObj.Territory__c;
        Territory__c territoryRec = new Territory__c(Id=territoryId);
        territoryRec.Primary_Sales_Rep__c = userId;
        return territoryRec;       
    }		
	
	//Moved salesManagerSharingOperation, getRegionWithSalesManagerMap, handleSMRemoveOperation, getOutletMapToUpdate Methods in EDGE_TerritoryProcessStatusUpdateHlpExtn Class

}