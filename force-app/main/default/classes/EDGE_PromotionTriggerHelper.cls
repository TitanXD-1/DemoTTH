/**********************************************************************
Name: EDGE_PromotionTriggerHelper
=======================================================================
Req: 
ES20-198 - 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Preyanka Ghosh    19/03/2019      Initial Development

***********************************************************************/
public with sharing class EDGE_PromotionTriggerHelper {
    
    /*******************************************************************
Method  : checkPromotionCycle
Purpose : This methods used to check whether Promotion exist with in same time frame if so throw error message
********************************************************************/
    public static void checkPromotionCycle(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        system.debug('Inside Method');
        Set<ID> setPromotionId = new Set<ID>();
        Map<Id,Promotion__c> oldPromoMap;
        Map<Id,Promotion__c> newPromoMap = (Map<Id,Promotion__c>)newItems;
        Map<Id, Map<Id,Promotion__c>> mapNewAccountPromotion = new Map<Id, Map<Id,Promotion__c>>();
        Map<Id, Map<Id,Promotion__c>> mapExistAccountPromotion = new Map<Id, Map<Id,Promotion__c>>();
        
        
        if(oldItems!=null){
            oldPromoMap=(Map<Id,Promotion__c>)oldItems;
        }
        
        //Get all the Promotion to fetch Account Id from Junction object
        for(Promotion__c newPromotion : newPromoMap.values()){    
            if(oldPromoMap==null ||
               (oldPromoMap !=null && oldPromoMap.containsKey(newPromotion.id) && (oldPromoMap.get(newPromotion.id).Start_Date__c!=newPromotion.Start_Date__c || 
                                                                                   oldPromoMap.get(newPromotion.id).Expiration_Date__c!=newPromotion.Expiration_Date__c))
              ){
                  setPromotionId.add(newPromotion.Id);  
              }
        }       
        
        
        //Create a Map of new Account and Promotion
        for(Account_Promotion__c objAccountPromotion : [SELECT Promotion__c, Distributor_Owner__c FROM Account_Promotion__c WHERE Promotion__c IN :setPromotionId]){
            if(newPromoMap.containsKey(objAccountPromotion.Promotion__c)){
                if(mapNewAccountPromotion.containsKey(objAccountPromotion.Distributor_Owner__c)){
                    mapNewAccountPromotion.get(objAccountPromotion.Distributor_Owner__c).put(objAccountPromotion.Promotion__c, newPromoMap.get(objAccountPromotion.Promotion__c));                    
                } else{
                    mapNewAccountPromotion.put(objAccountPromotion.Distributor_Owner__c, new Map<Id,Promotion__c>{objAccountPromotion.Promotion__c => newPromoMap.get(objAccountPromotion.Promotion__c)});                    
                }                
            }            
        }
        
        //Create a Map of Existing Account and Promotion
        if(mapNewAccountPromotion != null && mapNewAccountPromotion.size()>0){
            for(Account_Promotion__c objAccountPromotion : [SELECT Promotion__c, Promotion__r.Start_Date__c, Promotion__r.Expiration_Date__c, Distributor_Owner__c FROM Account_Promotion__c WHERE Distributor_Owner__c IN :mapNewAccountPromotion.keySet() and Promotion__c NOT IN :newPromoMap.keySet()]){
                Promotion__c objPromotion = new Promotion__c(Id = objAccountPromotion.Promotion__c,
                                                             Start_Date__c = objAccountPromotion.Promotion__r.Start_Date__c,
                                                             Expiration_Date__c = objAccountPromotion.Promotion__r.Expiration_Date__c
                                                            );
                if(mapExistAccountPromotion.containsKey(objAccountPromotion.Distributor_Owner__c)){
                    mapExistAccountPromotion.get(objAccountPromotion.Distributor_Owner__c).put(objAccountPromotion.Promotion__c, objPromotion);                    
                } else{
                    mapExistAccountPromotion.put(objAccountPromotion.Distributor_Owner__c, new Map<Id,Promotion__c>{objAccountPromotion.Promotion__c => objPromotion});                    
                }                
            }            
        }
        
        
        for(Id newAccountId : mapNewAccountPromotion.keySet()){
            if(mapExistAccountPromotion.containsKey(newAccountId)){
                for(Promotion__c existPromotion : mapExistAccountPromotion.get(newAccountId).values()){
                    for(Promotion__c newPromotion : mapNewAccountPromotion.get(newAccountId).values()){
                        if((newPromotion.Start_Date__c >= existPromotion.Start_Date__c && newPromotion.Start_Date__c <= existPromotion.Expiration_Date__c) ||
                           (newPromotion.Expiration_Date__c >= existPromotion.Start_Date__c && newPromotion.Expiration_Date__c <= existPromotion.Expiration_Date__c)
                          ){
                              newPromoMap.get(newPromotion.Id).addError(label.PromotionTimeFrame);
                          }            
                    }
                }                
            }                        
        }                
    }
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Promotion__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Promotion__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Promotion__c> mapOldItems;
        List<Promotion__c> lstNewChangeGeography = new List<Promotion__c>();
        List<Promotion__c> lstOldChangeGeography = new List<Promotion__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Promotion__c>)oldItems;
        }
        
        for(Promotion__c objPromotion : newItems){
            if(mapOldItems.containsKey(objPromotion.Id) && objPromotion.Country__c != mapOldItems.get(objPromotion.Id).Country__c){
                lstNewChangeGeography.add(objPromotion);
                lstOldChangeGeography.add(mapOldItems.get(objPromotion.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
}