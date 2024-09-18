/**********************************************************************
Name: EDGE_TerritoryCycleTriggerHelper
=======================================================================
Req: US 1782 one Territory can be assigned to a market cycle only once.

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
v0.1	  Sagar Barman		28/05/2019		Written checkTerritoryCycleInsert and checkTerritoryCycleUpdate
***********************************************************************/
public with sharing class EDGE_TerritoryCycleTriggerHelper {
    //before insert method to throw Error if there is already a Territory cycle with same market cycle
    public static void checkTerritoryCycleInsert(List<sObject> newItems){
        Set<Id> marketCycleIdSet = new Set<Id>();
        Set<Id> territoryIdSet= new Set<Id>();
        Map<Id, Boolean> territoryCycleMap = new map<Id,Boolean>();
        for(sObject obj : newItems){
            Territory_Cycle__c newTCycle = (Territory_Cycle__c)obj;
            marketCycleIdSet.add(newTCycle.Market_Cycle__c); 
            territoryIdSet.add(newTCycle.Territory__c);
        }
        //get the territoryCycleMap
        territoryCycleMap = getTerritoryCycleMap(marketCycleIdSet,territoryIdSet);
        //throw Error if there is already a Territory cycle with same market cycle
        for(sObject obj : newItems){
            Territory_Cycle__c newTCycle = (Territory_Cycle__c)obj;
            if(territoryCycleMap!=null && territoryCycleMap.containsKey(newTCycle.Market_Cycle__c)){
                if(territoryCycleMap.get(newTCycle.Market_Cycle__c) == true){
                    obj.addError(Label.EDGE_Territory_Cycle_Error);	    
                }    
            }	    
        }
    }
    //before update method to throw Error if there is already a Territory cycle with same market cycle
    public static void checkTerritoryCycleUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Set<Id> marketCycleIdSet = new Set<Id>();
        Set<Id> territoryIdSet= new Set<Id>();
        Map<Id, Boolean> territoryCycleMap = new map<Id,Boolean>();
        for(sObject obj : newItems.values()){
            Territory_Cycle__c newTCycle = (Territory_Cycle__c)obj;
            Territory_Cycle__c oldTCycle = (Territory_Cycle__c)oldItems.get(newTCycle.Id);
            if((newTCycle.Market_Cycle__c != oldTCycle.Market_Cycle__c) || (newTCycle.Territory__c != oldTCycle.Territory__c)){
                marketCycleIdSet.add(newTCycle.Market_Cycle__c); 
                territoryIdSet.add(newTCycle.Territory__c);    
            }
        }
        //get the territoryCycleMap
        territoryCycleMap = getTerritoryCycleMap(marketCycleIdSet,territoryIdSet);
        //throw Error if there is already a Territory cycle with same market cycle
        for(sObject obj : newItems.values()){
            Territory_Cycle__c newTCycle = (Territory_Cycle__c)obj;
            if(territoryCycleMap!=null && territoryCycleMap.containsKey(newTCycle.Market_Cycle__c)){
                if(territoryCycleMap.get(newTCycle.Market_Cycle__c) == true){
                    obj.addError(Label.EDGE_Territory_Cycle_Error);	    
                }    
            }	    
        }    
    }    
    public static Map<Id, Boolean> getTerritoryCycleMap(Set<Id> marketCycleIdSet,Set<Id> territoryIdSet){
        Map<Id, Boolean> territoryCycleMap = new map<Id,Boolean>();
        List<Market_Cycle__c> marketCyclelist = new List<Market_Cycle__c>();
        if(Schema.sObjectType.Market_Cycle__c.isAccessible() && Schema.sObjectType.Territory_Cycle__c.isAccessible() && Schema.sObjectType.Territory__c.isAccessible()) {
            marketCyclelist = [SELECT Id,(SELECT Id FROM Territory_Cycles__r WHERE Territory__c IN : territoryIdSet) FROM Market_Cycle__c WHERE Id IN :marketCycleIdSet];            
        }        
        for(Market_Cycle__c mCycle : marketCyclelist){
            territoryCycleMap.put(mCycle.Id, mCycle.Territory_Cycles__r.size()>0 ? true : false); 
        }
        return territoryCycleMap;        
    }
}