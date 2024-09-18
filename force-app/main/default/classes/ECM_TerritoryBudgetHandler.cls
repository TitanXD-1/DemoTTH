/**********************************************************************
Name: ECM_TerritoryBudgetHandler
=======================================================================
Purpose: Class with all handler methods of TerritoryBudgetTrigger.
=======================================================================
History                                                            
-------                                                            
AUTHOR            DATE              DETAIL
Saurav Prasad   25/11/2020      ECM-2190 : Add territory field  to territory budget_SFDC_Object_GLO_Budget management  
***********************************************************************/
public class ECM_TerritoryBudgetHandler {
    public void onBeforeInsert(List<Territory_Budget__c> newTerBud, map<Id,Territory_Budget__c> newMapTerBud){ 
        //Check Territory
        territoryCheck(newTerBud, newMapTerBud);
    }
    public void onBeforeUpdate(List<Territory_Budget__c> oldTerBud, map<Id,Territory_Budget__c> oldMapTerBud,List<Territory_Budget__c> newTerBud,map<Id,Territory_Budget__c> newMapTerBud){ 
        //Check Territory
        territoryCheck(newTerBud, newMapTerBud);
    }
    /* 
Name: territoryCheck
Developer: Saurav Prasad
Description: Method to check whether the Territory is related to Territory Hierarchy
*/
    public void territoryCheck(List<Territory_Budget__c> newTerBud, map<Id,Territory_Budget__c> newMapTerBud){
        Map<id,id> territoryBudgetTerritoryMap =new Map<id,id>();
        Map<id,id> territoryBudgetTerritoryHierarchyMap =new Map<id,id>();
        
        for(Territory_Budget__c territoryBudget:newTerBud){
            if(territoryBudget.Territory__c!=Null){
                territoryBudgetTerritoryMap.put(territoryBudget.id,territoryBudget.Territory__c);
                territoryBudgetTerritoryHierarchyMap.put(territoryBudget.id,territoryBudget.ECM_Territory_Hierarchy__c);
            }
        }
        
        Map<id,id> territoryHierarchyMap = new Map<id,id>();
        Map<id,Territory__c> territoryMap = new Map<id,Territory__c>();
        for(Territory__c territory:[SELECT id,Activation_Territory__c,Business_Unit__c,
                                    Sales_Area__c,Region__c from Territory__c WHERE
                                   (Activation_Territory__c IN:territoryBudgetTerritoryHierarchyMap.values()
                                   OR Business_Unit__c IN:territoryBudgetTerritoryHierarchyMap.values()
                                   OR Sales_Area__c IN:territoryBudgetTerritoryHierarchyMap.values()
                                   OR Region__c IN:territoryBudgetTerritoryHierarchyMap.values())
                                   AND id IN:territoryBudgetTerritoryMap.values()]){
                                     territoryMap.put(territory.id,territory); 
                                   }
        
        for(Territory_Budget__c territoryBudget:newTerBud){
            list<Territory__c> tempList = new List<Territory__c>();
            if(territoryMap.containsKey(territoryBudgetTerritoryMap.get(territoryBudget.id))){
                tempList.add(territoryMap.get(territoryBudgetTerritoryMap.get(territoryBudget.Id)));
            }
            if(tempList.size()==0 && territoryBudget.Territory__c!=Null){
                territoryBudget.addError(System.Label.ECM_TerritoryBudget_ErrorMessage);
            }
        }
        
    }
}