/*
* @description :  EDGE_TerritoryProcessStatusUpdateHlpExtn

* @purpose : This is the Extended Helper class for the batch class EDGE_TerritoryProcessStatusUpdateBatch & EDGE_TerritoryProcessStatusUpdateHelper

* @Test Class: EDGE_TerritoryProcessStUpdateBatchTest 

* @history :

* Version    Developer         		Date           			User Story/Purpose
	1.0		Dipanjan Das		24.06.2024			154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
	1.0		Sudipta Nandy		24.06.2024			154640 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
*/

/**
 * @description Extenstion Helper for EDGE_TerritoryProcessStatusUpdateBatch
 */

public without Sharing class EDGE_TerritoryProcessStatusUpdateHlpExtn {
	
    Public static Id salesTerrRecTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Sales_Territory').getRecordTypeId();
    Public static Id qualityTerrRecTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Quality_Territory').getRecordTypeId();
    Public static Id activationTerrRecTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Activation_Territory').getRecordTypeId();	

    /** 
* @description  Sharing Access for Sales Manager
* @return  List<AccountTeamMember>
* @param outletWithRegionMap
* @param isRemove
**/
    public static List<AccountTeamMember> salesManagerSharingOperation(Map<Id, List<Id>> outletWithRegionMap, Boolean isRemove){
        List<Id> regionLst = new List<Id>();
        Map<Id, Id> regionWithSalesManagerMap = new Map<Id, Id>(); 
        List<AccountTeamMember> accTM = new List<AccountTeamMember>();
		for(Id outlet : outletWithRegionMap.keySet()){
			regionLst.addAll(outletWithRegionMap.get(outlet));
		}
		regionWithSalesManagerMap = getRegionWithSalesManagerMap(regionLst);
				
		if(regionWithSalesManagerMap != null && regionWithSalesManagerMap.size() > 0){
			if(isRemove){	
				System.debug(LoggingLEVEL.DEBUG,'RemovedMap::'+regionWithSalesManagerMap);
				accTM = handleSMRemoveOperation(regionLst, regionWithSalesManagerMap, outletWithRegionMap); 
			}else{
				accTM = EDGE_SalesManagerSharingOperations.salesManagerOutletShare(regionWithSalesManagerMap, outletWithRegionMap);                                           
			}
		}                               
        return accTM;
    } 	
	
       /** 
* @description  Generate Map with Territory Hierarchy
* @return  Map<Id, Id>
* @param regionLst
**/
	public static Map<Id, Id> getRegionWithSalesManagerMap(List<Id> regionLst){
		Map<Id, Id> regionWithSalesManagerMap = new Map<Id, Id>(); 
		if (Schema.sObjectType.Territory_Hierarchy_Member__c.isAccessible()){
			for(Territory_Hierarchy_Member__c terrHierMem :[SELECT Id, Territory_Hierarchy__c, User__c FROM Territory_Hierarchy_Member__c WHERE Territory_Hierarchy__c IN :regionLst AND Status__c = 'Active']){
				regionWithSalesManagerMap.put(terrHierMem.Territory_Hierarchy__c, terrHierMem.User__c);
			}			
		}
		return regionWithSalesManagerMap;
	}
   /** 
* @description Remove Manager from Account Team
* @return  List<AccountTeamMember>
* @param regionLst
* @param regionWithSalesManagerMap
* @param outletWithRegionMap
**/	
	public static List<AccountTeamMember> handleSMRemoveOperation(List<Id> regionLst, Map<Id, Id> regionWithSalesManagerMap, Map<Id, List<Id>> outletWithRegionMap){
		List<AccountTeamMember> accTM = new List<AccountTeamMember>();
		if (Schema.sObjectType.Outlet_Territory__c.isAccessible()){
			for(Outlet_Territory__c activeOutletTerr : [SELECT Id, Outlet__c,Territory__r.Region__c FROM Outlet_Territory__c WHERE Outlet__c IN :outletWithRegionMap.keySet() AND Territory__r.Region__c IN :regionLst AND Active__c = 'Active']){
				if(outletWithRegionMap.get(activeOutletTerr.Outlet__c) != null && outletWithRegionMap.get(activeOutletTerr.Outlet__c).contains(activeOutletTerr.Territory__r.Region__c)){
					Integer index = outletWithRegionMap.get(activeOutletTerr.Outlet__c).indexOf(activeOutletTerr.Territory__r.Region__c);
					//if(index != null){}
                    outletWithRegionMap.get(activeOutletTerr.Outlet__c).remove(index);
				}
				if(outletWithRegionMap.get(activeOutletTerr.Outlet__c).size() == 0 ){
					outletWithRegionMap.remove(activeOutletTerr.Outlet__c);
				}
			}
		accTM = EDGE_SalesManagerSharingOperations.salesManagerOutletRemove(regionWithSalesManagerMap, outletWithRegionMap); 
		}
		return accTM;
	}
	
   /** 
* @description  Remove Outlet territory which are in Waiting Removal
* @return  EDGE_TerritoryProcessUpdateWrapper
* @param terrUpdateWrap
* @param outletTerrRemovallList
**/
	public static EDGE_TerritoryProcessUpdateWrapper removeOutletTerritory(EDGE_TerritoryProcessUpdateWrapper terrUpdateWrap, List<Outlet_Territory__c> outletTerrRemovallList){
		List<Outlet_Territory__c> deleteOTList = new List<Outlet_Territory__c>();
		Map<Id, List<Id>> outletWithRegionListMapToRemove = new Map<Id, List<Id>>();
		for(Outlet_Territory__c outletTerritory : outletTerrRemovallList){
			if(outletTerritory.Territory__r.RecordTypeId == salesTerrRecTypeId){
				Account accObj = primarySalesTerDetailsRemove(outletTerritory.Outlet__c);
				terrUpdateWrap.outletsToUpdateList.add(accObj);
			}else if(outletTerritory.Territory__r.RecordTypeId == activationTerrRecTypeId){
				Account accObj = primarySaleswithASDetailsRemove(outletTerritory.Outlet__c);
				terrUpdateWrap.activationTerrAccListToUpdate.add(accObj);
			}else if(outletTerritory.Territory__r.RecordTypeId == qualityTerrRecTypeId && outletTerritory.Territory__r.Territory_Type__c=='Quality Dispense'){
				Account accObj = new Account(Id = outletTerritory.Outlet__c);
				accObj.Dispense_Rep__c= null;
				terrUpdateWrap.dispenseRepAccListToUpdate.add(accObj);
			}
			if(outletTerritory.Territory__r.RecordTypeId != activationTerrRecTypeId && outletTerritory.Territory__r.Region__c != null){
				if(outletWithRegionListMapToRemove.containsKey(outletTerritory.Outlet__c)){
					outletWithRegionListMapToRemove.get(outletTerritory.Outlet__c).add(outletTerritory.Territory__r.Region__c);
				}
				else{
					outletWithRegionListMapToRemove.put(outletTerritory.Outlet__c,new List<Id>{outletTerritory.Territory__r.Region__c});
				}					
			}
		deleteOTList.add(outletTerritory);	
		}
		terrUpdateWrap.deleteOTList = deleteOTList;
		terrUpdateWrap.outletWithRegionListMapToRemove = outletWithRegionListMapToRemove;
		return terrUpdateWrap;
	}	
	
   /** 
* @description  Method added remove primary sales territory details in outlet
* @return  Account
* @param accountObjId
**/	

    public static Account primarySalesTerDetailsRemove(Id accountObjId){
        Account tempAcctObj = new Account(Id = accountObjId);
        tempAcctObj.Primary_Sales_Territory__c = null;
        tempAcctObj.Primary_Sales_Territory_Region__c = null;
        tempAcctObj.Primary_Sales_Area__c = null;
        tempAcctObj.Primary_Sales_Territory_Business_Unit__c = null;
        return tempAcctObj;
    }
	
   /** 
* @description  method added to remove sales territory details along with AS AT in outlet for ES20-8780
* @return  Account
* @param accountObjId
**/		
    public static Account primarySaleswithASDetailsRemove(Id accountObjId){
        Account tempAcctObj = new Account(Id = accountObjId);
        tempAcctObj.Activation_Territory_LT__c= null;
        tempAcctObj.Activation_Specialist__c=null;
        return tempAcctObj;
    }
	
 /** 
* @description  Generate map of Outlet with Territory details
* @return  Map<Id,Account>
* @param terrUpdateWrap
**/	
	public static Map<Id,Account> getOutletMapToUpdate(EDGE_TerritoryProcessUpdateWrapper terrUpdateWrap){
		Map<Id,Account> accountMapToUpdate = new Map<Id,Account>();
		for(Account out:terrUpdateWrap.outletsToUpdateList){
			accountMapToUpdate.put(out.id,out);
		}		
		for(Account out:terrUpdateWrap.activationTerrAccListToUpdate){
			if(accountMapToUpdate.containsKey(out.id)){
				Account outlet = accountMapToUpdate.get(out.id);
				outlet.Activation_Territory_LT__c = out.Activation_Territory_LT__c;
				outlet.Activation_Specialist__c = out.Activation_Specialist__c;
				accountMapToUpdate.put(out.Id,outlet);
			}
			else{
				accountMapToUpdate.put(out.Id,out);
			}
		}	
		for(Account out:terrUpdateWrap.dispenseRepAccListToUpdate){
			if(accountMapToUpdate.containsKey(out.id)){
				Account outlet = accountMapToUpdate.get(out.id);
				outlet.Dispense_Rep__c = out.Dispense_Rep__c;
				accountMapToUpdate.put(out.Id,outlet);
			}
			else{
				accountMapToUpdate.put(out.Id,out);
			}
		}
		return accountMapToUpdate;
	}	
}