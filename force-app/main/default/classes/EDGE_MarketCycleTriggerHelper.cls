/**********************************************************************
Name: EDGE_MarketCycleTriggerHelper
=======================================================================
Req: 
ES20-647 - 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Anuja Chattopadhyay  03/04/2019      Initial Development
2.0		Preyanka Ghosh		21/05/2019		ES20-1615

***********************************************************************/
public with sharing class EDGE_MarketCycleTriggerHelper {
    
    public static void checkMarketCycleOverlap(List<Market_Cycle__c> newItems,Map<Id, SObject> oldItems){
        //Variables
        List<Market_Cycle__c> existingMarCycleList = new List<Market_Cycle__c>();
        Map<Id,List<Market_Cycle__c>> existingMarCycleMap = new Map<Id,List<Market_Cycle__c>>();
        Set<Id> marketIdSet = new Set<Id>();
        Map<Id,Market_Cycle__c> oldCycleMap;
        
        if(oldItems!=null){
            oldCycleMap = (Map<Id,Market_Cycle__c>)oldItems;  
        }
        
        //Preparing marketidset to use it to fetch existing market cycle records in next step
        for(Market_Cycle__c newMarCycle:newItems ){
            
            if(oldCycleMap==null || (oldCycleMap!=null && oldCycleMap.get(newMarCycle.id).Start_Date__c!=newMarCycle.Start_Date__c || 
                                     oldCycleMap.get(newMarCycle.id).End_Date__c!=newMarCycle.End_Date__c)){
                                         marketIdSet.add(newMarCycle.Geography__c);
                                         
                                     }     
        }
        
        //Fetching existing market cycle records
        for(Market_Cycle__c objMarCycle :[Select Active__c,End_Date__c,Geography__c,Start_Date__c 
                                          from Market_Cycle__c where Geography__c IN: marketIdSet]){
                                              if(existingMarCycleMap.get(objMarCycle.Geography__c)!=null){
                                                  existingMarCycleMap.get(objMarCycle.Geography__c).add(objMarCycle);
                                              }
                                              else{
                                                  List<Market_Cycle__c> temMarCycle= new List<Market_Cycle__c>();
                                                  temMarCycle.add(objMarCycle);
                                                  existingMarCycleMap.put(objMarCycle.Geography__c,temMarCycle);
                                              }          
                                          }
        //checking if the time frame is overlapping
        for(Market_Cycle__c newMarCycle:newItems ){
            if(existingMarCycleMap.get(newMarCycle.Geography__c)!=null){
                for(Market_Cycle__c existingMarCycle : existingMarCycleMap.get(newMarCycle.Geography__c)){
                    if((newMarCycle.Start_Date__c >= existingMarCycle.Start_Date__c && newMarCycle.Start_Date__c <= existingMarCycle.End_Date__c)
                       ||(newMarCycle.End_Date__c >= existingMarCycle.Start_Date__c && newMarCycle.End_Date__c <= existingMarCycle.End_Date__c)){  
                           newMarCycle.addError(label.MarketCycleTimeOverlap);
                       }   
                }
            }
        }
    }
    
    public static void calculateMarketCycleWeek(List<Market_Cycle__c> newItems,Map<Id, SObject> oldItems){     
        Map<Id,Market_Cycle__c> oldCycleMap;
        
        if(oldItems!=null){
            oldCycleMap = (Map<Id,Market_Cycle__c>)oldItems;  
        }
        
        for(Market_Cycle__c newMarCycle:newItems){
            Integer weekCount = 0;
            if(oldItems==null||(oldCycleMap!=null && oldCycleMap.get(newMarCycle.id).Start_Date__c!=newMarCycle.Start_Date__c || 
                                oldCycleMap.get(newMarCycle.id).End_Date__c!=newMarCycle.End_Date__c)){
                                    weekCount =  EDGE_UtilityClass.getCurrWeekNumberInCycle(newMarCycle.Start_Date__c,newMarCycle.End_Date__c);
                                    newMarCycle.Number_of_Week__c = weekCount ;
                                    
                                }
        }
    }
    
    /*******************************************************************
Method  : checkAndGenerateSharing
Purpose : To create sharing record on Insert
********************************************************************/
    public static void checkAndGenerateSharing(List<Market_Cycle__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Geography__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Geography__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
Method  : validateAndReGenerateSharing
Purpose : Modify, Validate sharing record on update
********************************************************************/
    public static void validateAndReGenerateSharing(List<Market_Cycle__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Market_Cycle__c> mapOldItems;
        List<Market_Cycle__c> lstNewChangeGeography = new List<Market_Cycle__c>();
        List<Market_Cycle__c> lstOldChangeGeography = new List<Market_Cycle__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Market_Cycle__c>)oldItems;
        }
        
        for(Market_Cycle__c objMarketCycle : newItems){
            if(mapOldItems.containsKey(objMarketCycle.Id) && objMarketCycle.Geography__c != mapOldItems.get(objMarketCycle.Id).Geography__c){
                lstNewChangeGeography.add(objMarketCycle);
                lstOldChangeGeography.add(mapOldItems.get(objMarketCycle.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Geography__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Geography__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Geography__c', 'Down', 'Edit');
        }       
    }
}