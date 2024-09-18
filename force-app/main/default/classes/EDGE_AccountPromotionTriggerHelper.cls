/**********************************************************************
Name: EDGE_AccountPromotionTriggerHelper
=======================================================================
Req: 
ES20-198 - 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Monalisa Halder    12/05/2019      Initial Development

***********************************************************************/
public with sharing class EDGE_AccountPromotionTriggerHelper {
    
    /*******************************************************************
Method  : checkPromotionOwnerCycle
Purpose : This methods used to check whether Promotion exist with in same time frame if so throw error message
********************************************************************/ 
    public static void checkAccountPromotionCycle(List<Account_Promotion__c> newItems, Map<Id, SObject> oldItems){
        
        Set<ID> setDistributorId = new Set<ID>();
        Set<ID> setPromotionId = new Set<ID>();
        Map<id,List<Account_Promotion__c>> distributorPromotionOwnerMap = new  Map<id,List<Account_Promotion__c>>();
        Map<Id,Account_Promotion__c> oldPromoOwnerMap = new Map<Id,Account_Promotion__c>();
        Map<Id,Promotion__c> promotionMap = new Map<Id,Promotion__c>();
        if(oldItems!=null){
            oldPromoOwnerMap=(Map<Id,Account_Promotion__c>)oldItems;  
        }
        // Fetching the distributor/owner ids of the new Promotion Owners
        for(Account_Promotion__c newPromotionOwner : newItems){
            setDistributorId.add(newPromotionOwner.Distributor_Owner__c);  
            setPromotionId.add(newPromotionOwner.Promotion__c);
           
        }
        
        //Putting distributor/owner and promotion owner in a map
        for(Account_Promotion__c objPromotionOwner : [SELECT Promotion__c, Distributor_Owner__c FROM Account_Promotion__c WHERE Distributor_Owner__c IN :setDistributorId]){
            if(distributorPromotionOwnerMap.get(objPromotionOwner.Distributor_Owner__c) != null){
                distributorPromotionOwnerMap.get(objPromotionOwner.Distributor_Owner__c).add(objPromotionOwner);
            }
            else{
                List<Account_Promotion__c> tempPromotionOwner = new List<Account_Promotion__c>();
                tempPromotionOwner.add(objPromotionOwner);
                distributorPromotionOwnerMap.put(objPromotionOwner.Distributor_Owner__c,tempPromotionOwner);
            }
            setPromotionId.add(objPromotionOwner.Promotion__c);
        }
        
        //Retrieving the promotion records with the promotion ids in the promotion owner records
        for(Promotion__c objPromotion : [SELECT Id, Start_Date__c, Expiration_Date__c FROM Promotion__c WHERE Id IN :setPromotionId]){
            promotionMap.put(objPromotion.Id, objPromotion);
        }
        
        for(Account_Promotion__c newPromotionOwner : newItems){
            //Check distributorPromotionOwnerMap contains the added Distributor in the database
            if(distributorPromotionOwnerMap.get(newPromotionOwner.Distributor_Owner__c) != null){
                Promotion__c newPromotion = promotionMap.get(newPromotionOwner.Promotion__c);
                for(Account_Promotion__c existingPromotionOwner : distributorPromotionOwnerMap.get(newPromotionOwner.Distributor_Owner__c)){
                    //Check only for different promotion records with the same distributor, and ignore the same one
                    if(existingPromotionOwner.Id != newPromotionOwner.Id){
                        Promotion__c existingPromotion = promotionMap.get(existingPromotionOwner.Promotion__c);
                        //Check for start date and expiration date comparison for all the exisiting promotions in the database with the new promotion
                        if((newPromotion.Start_Date__c >= existingPromotion.Start_Date__c && newPromotion.Start_Date__c <= existingPromotion.Expiration_Date__c)
                           || (newPromotion.Expiration_Date__c >= existingPromotion.Start_Date__c && newPromotion.Expiration_Date__c <= existingPromotion.Expiration_Date__c)){
                               newPromotionOwner.addError(label.PromotionTimeFrame);
                           } 
                    }
                }
                
            }
        }
    } 
    
}