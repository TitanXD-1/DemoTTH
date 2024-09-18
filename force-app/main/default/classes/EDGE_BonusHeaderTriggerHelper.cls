/**********************************************************************
Name: EDGE_BonusHeaderTriggerHelper
=======================================================================
Purpose: This is to handle Bonus Header Trigger Handler Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE			DETAIL
1.0			Shahbaz Khan	20/01/2020		Initial Development
2.0			Preyanka Ghosh	21/01/2020		ES20-4598 (Aggregating values to Bonus Header Result)
***********************************************************************/

public with sharing class EDGE_BonusHeaderTriggerHelper {
/*******************************************************************
Method  : checkAndGenerateSharing
Purpose : To create sharing record on Insert
********************************************************************/
    public static void checkAndGenerateSharing(List<Bonus_Header__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
/*******************************************************************
Method  : validateAndReGenerateSharing
Purpose : Modify, Validate sharing record on update
********************************************************************/
    public static void validateAndReGenerateSharing(List<Bonus_Header__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Bonus_Header__c> mapOldItems;
        List<Bonus_Header__c> lstNewChangeGeography = new List<Bonus_Header__c>();
        List<Bonus_Header__c> lstOldChangeGeography = new List<Bonus_Header__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Bonus_Header__c>)oldItems;
        }
        
        for(Bonus_Header__c bonHeaderObj : newItems){
            if(mapOldItems.containsKey(bonHeaderObj.Id) && bonHeaderObj.Country__c != mapOldItems.get(bonHeaderObj.Id).Country__c){
                lstNewChangeGeography.add(bonHeaderObj);
                lstOldChangeGeography.add(mapOldItems.get(bonHeaderObj.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
    
    /*******************************************************************
Method  : upsertBonusHeaderResult
Purpose : Upsert Bonus Header Result when the status changed to Active
********************************************************************/
    public static void upsertBonusHeaderResult(List<Bonus_Header__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Bonus_Header__c> mapOldItems;
        Map<Id, Id> mapMarketCycle = new Map<Id, Id>();
        Map<String, Id> mapTerritoryCycle = new Map<String, Id>();
        List<Bonus_Header__c> lstActiveBonusHeader = new List<Bonus_Header__c>();
        List<Bonus_Assignment__c> lstBonusAssignment = new List<Bonus_Assignment__c>();
        Set<Id> setTerritoryId = new Set<Id>();
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Bonus_Header__c>)oldItems;
        }
        
        if(newItems != null && newItems.size()>0) {
            //Create a list of Active Bonus Header
            for(Bonus_Header__c bonusHeader : newItems){
                //As bonus header will only be change to Active if Bonus Assignment is assigned hence considered only update scenario
                if((oldItems != null && mapOldItems.get(bonusHeader.Id).Status__c !=bonusHeader.Status__c  && bonusHeader.Status__c == 'Active')){
                    lstActiveBonusHeader.add(bonusHeader);                    
                }                
            }
            
            if(lstActiveBonusHeader != null && lstActiveBonusHeader.size()>0 && Schema.sObjectType.Bonus_Assignment__c.isAccessible() && Schema.sObjectType.Bonus_Cycle__c.isAccessible()){
                //Retrieve all the Bonus assignment attached with Active Bonus Header
                for(Bonus_Assignment__c bonusAssignment : [SELECT Id, Bonus_Header__c, Territory__c FROM Bonus_Assignment__c WHERE Bonus_Header__c IN :lstActiveBonusHeader AND RecordType.DeveloperName = 'Bonus_Header' AND Bonus_Header__r.Status__c = 'Active']){
                    setTerritoryId.add(bonusAssignment.Territory__c);
                    lstBonusAssignment.add(bonusAssignment);
                }
                
                //Retrieve Bonus Cycle attached with Active Bonus Header
                for(Bonus_Cycle__c bonusCycle : [SELECT ID, Bonus_Header__c, Market_Cycle__c FROM Bonus_Cycle__c WHERE Bonus_Header__c IN :lstActiveBonusHeader AND Market_Cycle__r.Active__c = True]){
                    mapMarketCycle.put(bonusCycle.Bonus_Header__c, bonusCycle.Market_Cycle__c);                    
                }
                
                //Retrieve Territory Cycle
                if(setTerritoryId != null && setTerritoryId.size()>0 && mapMarketCycle != null && mapMarketCycle.size()>0 && Schema.sObjectType.Territory_Cycle__c.isAccessible()){
                    for(Territory_Cycle__c territoryCycle : [SELECT Id, Market_Cycle__c, Territory__c FROM Territory_Cycle__c WHERE Territory__c IN :setTerritoryId AND Market_Cycle__c IN :mapMarketCycle.values() AND Market_Cycle__r.Active__c = True]){
                        mapTerritoryCycle.put(territoryCycle.Territory__c+'_'+territoryCycle.Market_Cycle__c,territoryCycle.Id);                    
                    } 
                                        
                    //Create Bonus Header Result
                    List<Bonus_Header_Result__c> lstBonusResult = new List<Bonus_Header_Result__c>();
                    for(Bonus_Assignment__c bonusAssignment : lstBonusAssignment){
                        Bonus_Header_Result__c bonusResult = new Bonus_Header_Result__c();
                        bonusResult.Bonus_Assignment__c = bonusAssignment.Id;
                        bonusResult.Bonus_Header__c = bonusAssignment.Bonus_Header__c;
                        bonusResult.Territory__c = bonusAssignment.Territory__c;
                        bonusResult.Market_Cycle__c = mapMarketCycle.get(bonusAssignment.Bonus_Header__c);
                        bonusResult.Territory_Cycle__c = mapTerritoryCycle.get(bonusAssignment.Territory__c+'_'+bonusResult.Market_Cycle__c);
                        bonusResult.Unique_Id__c = bonusAssignment.Bonus_Header__c+'_'+bonusAssignment.Id+'_'+bonusResult.Market_Cycle__c;                        
                        lstBonusResult.add(bonusResult);
                    }
                    
                    if(lstBonusResult != null && lstBonusResult.size()>0 && Schema.sObjectType.Bonus_Header_Result__c.isCreateable()){
                        Schema.SObjectField uniqueToken = Bonus_Header_Result__c.Fields.Unique_Id__c;
                        Database.upsert(lstBonusResult, uniqueToken, false);
                    }
                }                
            }            
        }        
    }
}