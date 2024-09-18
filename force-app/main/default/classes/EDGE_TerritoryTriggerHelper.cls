/**
* @description Trigger Helper Class for Territory Trigger
* @history
* 1.0      Saurav Paul     02-Mar-2019        Initial Development
*/
public  with sharing class EDGE_TerritoryTriggerHelper {
    //Name  : populateParentTerHierrarchy
    //Description : This will populate Sales Area and Business unit
    final static String QualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();     
    final static String QualityHierarchyRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
    
    public static void populateParentTerHierrarchy(List<Territory__c> newItems,Map<Id, SObject> oldItems){
        //Variables
        Map<Id, Territory__c> oldMap;
        Set<Id> regionIdSet = new Set<Id>();
        Map<Id,Territory_Hierarchy__c> terrHierarchyMap;
        List<Territory__c> territoryLst = new List<Territory__c>();
        //Variables
        if(oldItems!= null){
            oldMap = (Map<Id, Territory__c>)oldItems;
        }
        for(Territory__c terriObj : newItems){
            if((oldMap == null && terriObj.Region__c != null) ||
               (oldMap != null && terriObj.Region__c != null && oldMap.containsKey(terriObj.Id) && oldMap.get(terriObj.Id).Region__c != terriObj.Region__c)){
                   regionIdSet.add(terriObj.Region__c);
                   territoryLst.add(terriObj);  
               }
        }
        if(!regionIdSet.isEmpty()){
            terrHierarchyMap = new Map<Id,Territory_Hierarchy__c>([SELECT Id,Parent_BU__c, Parent_BU__r.Parent_BU__c 
                                                                   FROM Territory_Hierarchy__c 
                                                                   WHERE Id IN : regionIdSet]);
            if(!terrHierarchyMap.isEmpty() && !territoryLst.isEmpty()){
                for(Territory__c terrObj : territoryLst){
                    if(terrHierarchyMap.containsKey(terrObj.Region__c)){
                        Territory_Hierarchy__c terriHierarObj = terrHierarchyMap.get(terrObj.Region__c);
                        terrObj.Sales_Area__c = terriHierarObj.Parent_BU__c != null ? terriHierarObj.Parent_BU__c : null;
                        terrObj.Business_Unit__c = terriHierarObj.Parent_BU__r.Parent_BU__c != null ? terriHierarObj.Parent_BU__r.Parent_BU__c : null;
                    }
                }
            }
        }
    }
    
    /**
* @description To create sharing record on Insert
*/
    public static void checkAndGenerateSharing(List<Territory__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /**
* @description Modify, Validate sharing record on update
*/
    public static void validateAndReGenerateSharing(List<Territory__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Territory__c> mapOldItems;
        List<Territory__c> lstNewChangeGeography = new List<Territory__c>();
        List<Territory__c> lstOldChangeGeography = new List<Territory__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Territory__c>)oldItems;
        }
        
        for(Territory__c objBusinessRole : newItems){
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
        }       
    }
    
    /**
* @description Validating Territory Type to Territory Hierarchy Type
*/
    public static void validatingTerritoryHierarchyType(list<Territory__c> newItems){
        Set<ID> terrHierId = new Set<ID>();
        Map<ID,String> terrHierarchyMap = new Map<ID,String>();
        Map<ID,Territory_Hierarchy__c> territoryWithHierarchyMap = new Map<ID,Territory_Hierarchy__c>();
        List<Territory_Hierarchy__c> terrHierList = new List<Territory_Hierarchy__c>();
        Map<String, list<String>> terrTypeWithHierarchyMapping = new Map<String, list<String>>();
        
        if(newItems != null){
            for(Territory__c terr : newItems){
                // Get Territory Hierarchy Id
                if(terr.RecordTypeId == QualityRecordTypeId){
                    terrHierId.add(terr.Region__c);
                }
            }
            
            // Quering Metadata from Database
            if(Schema.SObjectType.Mapping_QT_to_Territory_Hierarchy_Type__mdt.isAccessible()){
                for(Mapping_QT_to_Territory_Hierarchy_Type__mdt territoryHtypeCheckMtd : [SELECT Territory_Hierarchy_Type__c, Territory_Type__c FROM Mapping_QT_to_Territory_Hierarchy_Type__mdt]){
                    if(!terrTypeWithHierarchyMapping.containsKey(territoryHtypeCheckMtd.Territory_Type__c)){
                        terrTypeWithHierarchyMapping.put(territoryHtypeCheckMtd.Territory_Type__c, new list<string> {territoryHtypeCheckMtd.Territory_Hierarchy_Type__c});
                    }else{
                        terrTypeWithHierarchyMapping.get(territoryHtypeCheckMtd.Territory_Type__c).add(territoryHtypeCheckMtd.Territory_Hierarchy_Type__c);
                    }
                } 
            } 
            
            if(terrHierId != null){
                terrHierList = [Select Id, Name, RecordTypeId, Territory_Hierarchy_Type__c from Territory_Hierarchy__c where Id = :terrHierId AND RecordTypeId = :QualityHierarchyRecordTypeId];
            }
            // Get Map of Territory Hierarchy Id and Territory Hierarchy type
            if(terrHierList != null && terrHierList.size() > 0)
            {
                for(Territory_Hierarchy__c terrH : terrHierList){
                    if(!territoryWithHierarchyMap.containskey(terrH.Id)){
                        territoryWithHierarchyMap.put(terrH.Id, terrH); 
                    }
                }
            }
            
            // Get Map of Territory Id with Territory Hierarchy type
            if(territoryWithHierarchyMap != null && territoryWithHierarchyMap.size() >0)
            {
                for(Territory__c terrRec : newItems){
                    if(!terrHierarchyMap.containskey(terrRec.Id)){
                        if(territoryWithHierarchyMap.get(terrRec.Region__c) != null){
                            String terrHierType = territoryWithHierarchyMap.get(terrRec.Region__c).Territory_Hierarchy_Type__c;
                            terrHierarchyMap.put(terrRec.Id, terrHierType); 
                        }
                    }
                }
            }
            
            // Check Validation for insert
            if(terrHierarchyMap != null && terrHierarchyMap.size() > 0){
                
                if(terrTypeWithHierarchyMapping != null && terrTypeWithHierarchyMapping.size() > 0)
                {
                    for(Territory__c terrRec :newItems ){
                        string terrHierType = terrHierarchyMap.get(terrRec.id);
                        list<string> allowedterrHierTypes = terrTypeWithHierarchyMapping.get(terrRec.Territory_Type__c);
                        if(allowedterrHierTypes != null && !allowedterrHierTypes.contains(terrHierType)){
                            terrRec.addError(label.Validate_Territory_Type_and_Territory_Hierarchy_Type);
                        }
                    }
                }
            }
        }
        
    }
    
    /**
* @description
*/
    
    /*public static void salesManagerOutletShare(Map<Id, SObject> newItems,Map<Id, SObject> oldItems){
//Variables
Map<Id, Territory__c> oldMap , newMap;
Boolean isDelete = false;
Map<Id,Territory_Hierarchy__c> terrHierarchyMap;
Map<Id,Id> newterritoryRegionMap = new Map<Id,Id>();
Map<Id,Id> oldterritoryRegionMap = new Map<Id,Id>();
//Variables
//
if(oldItems!= null){
oldMap = (Map<Id, Territory__c>)oldItems;
}
if(newItems!= null){
newMap = (Map<Id, Territory__c>)newItems;
}

//Populate territory with region map for Old and New Values
for(Id territoryId : newMap.keySet()){
if(oldMap != null && oldMap.get(territoryId).Region__c != null && oldMap.get(territoryId).Region__c != newMap.get(territoryId).Region__c){
oldterritoryRegionMap.put(territoryId,oldMap.get(territoryId).Region__c);               
}
if(newMap.get(territoryId).Region__c != null){
newterritoryRegionMap.put(territoryId,newMap.get(territoryId).Region__c);         
}
}
if(oldterritoryRegionMap != null ){            
outletMemberOperation(oldterritoryRegionMap,true);
}
outletMemberOperation(newterritoryRegionMap,false);

}*/
    /*******************************************************************
Method  : outletMemberOperation
Purpose : Generic method to add and delete sharing Outlet Member 
********************************************************************/
    /*private static void outletMemberOperation(Map<Id,Id> territoryRegionMap, Boolean isDelete){

Set<Id> managerIds = new Set<Id>();
Map<Id, Id> outletWithRegionMap = new Map<Id, Id>();
Map<Id, Id> regionWithSalesManagerMap = new Map<Id, Id>();
Id regionRecTypeId = Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByDeveloperName().get('Region').getRecordTypeId();

//Creating Map for Territory Hierarchy (Region) with Sales Manager
for(Territory_Hierarchy_Member__c terrHierMem : [SELECT Id, Territory_Hierarchy__c, User__c FROM Territory_Hierarchy_Member__c
WHERE  Territory_Hierarchy__c IN : territoryRegionMap.values() AND Territory_Hierarchy__r.recordTypeId = :regionRecTypeId AND Status__c = 'Active']){
regionWithSalesManagerMap.put(terrHierMem.Territory_Hierarchy__c, terrHierMem.User__c);
} 

for(Outlet_Territory__c outletTerr : [SELECT Outlet__c, Territory__c, Territory__r.Region__c FROM Outlet_Territory__c WHERE Territory__c IN :territoryRegionMap.keySet() AND Active__c = 'Active']){
outletWithRegionMap.put(outletTerr.Outlet__c, outletTerr.Territory__r.Region__c);
}                          

//Generic class call for Outlet Member and Account Team Deletion/ Creation  
if(outletWithRegionMap != null && regionWithSalesManagerMap != null && regionWithSalesManagerMap.size() > 0){
if(isDelete){
managerIds.addAll(regionWithSalesManagerMap.values());
EDGE_SalesManagerSharingOperations.salesManagerOutletRemove(managerIds, outletWithRegionMap.keySet());
}else{
EDGE_SalesManagerSharingOperations.salesManagerOutletShare(regionWithSalesManagerMap, outletWithRegionMap);
}

}  
}*/
}