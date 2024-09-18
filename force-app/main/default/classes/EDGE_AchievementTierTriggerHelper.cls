/*
Name: EDGE_AchievementTierTriggerHelper
Req: 
ES20-4584 
History                                                            
VERSION   AUTHOR            DATE           DETAIL
1.0     Shahbaz Khan     07/01/2020        ES20-4584(method - preventOverlappingRange)
*/
public with sharing class EDGE_AchievementTierTriggerHelper{
    public static void preventOverlappingRange(List<Achievement_Tier__c> newItems){
        Set<Id> bonusDetailIds = new Set<Id>();
        Map<Id,String> errorMap;
        errorMap = new Map<Id,String>();
        String existingRange ;
        existingRange = '';
        
        for(Achievement_Tier__c achivement :newItems){
            bonusDetailIds.add(achivement.Bonus_Detail__c);
        }
        
        if(Schema.SObjectType.Achievement_Tier__c.isAccessible()){
            for(Achievement_Tier__c existingAchTier : [SELECT Id,Bonus_Detail__c, Range_End__c,Range_Start__c,Value__c FROM Achievement_Tier__c WHERE Bonus_Detail__c IN :bonusDetailIds WITH SECURITY_ENFORCED]){
                for(Achievement_Tier__c newAchTier : newItems){
                    if(newAchTier.Bonus_Detail__c == existingAchTier.Bonus_Detail__c){
                        if(newAchTier.Range_Start__c >= existingAchTier.Range_Start__c && newAchTier.Range_Start__c <= existingAchTier.Range_End__c
                           ||(newAchTier.Range_End__c >= existingAchTier.Range_Start__c && newAchTier.Range_End__c <= existingAchTier.Range_End__c)
                           ||(newAchTier.Range_Start__c <= existingAchTier.Range_Start__c && newAchTier.Range_End__c >= existingAchTier.Range_End__c)){
                               if(newAchTier.Id!=existingAchTier.Id || newAchTier.Id==null){
                                   newAchTier.addError('Records for this Range in this Bonus Detail is overlapping with : ' + existingAchTier.Range_Start__c + ' - ' + existingAchTier.Range_End__c);
                                   
                               }
                               
                           }
                        
                    }
                }
                
                
            }
        }
    }
}