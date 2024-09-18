/**********************************************************************
Name: EDGE_BonusAssignmentTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for BonusAssignmentTrigger
=======================================================================
History                                                            
-------                                                            
VERSION  	  AUTHOR            DATE              DETAIL
1.0			  Sandip Ghosh      07-Jan-2020		  Initial Development,Method : syncGlblAndTerrWtForHeader,
updateGlblAndTerrWtFrmDetails, populateWeights
populateWeights (ES20-4995,ES20-4997)
2.0			  Vikas Anand		09-Jan-2020		  ES20-4996 (Unique Id Generation for Bonus Assignment) method :- updateuniquekey
3.0           Amar Deep         22-jan-2020       ES20-6810 ,Method : validateBonusAssignment
*******************************************************************************/

public with sharing class EDGE_BonusAssignmentTriggerHelper {
    
    private static String bonushdrRecordTypeId = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
    private static String bonusdtlRecordTypeId = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
    private static String bonusdtlKPIRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('KPI').getRecordTypeId();
    private static String bonusdtlKPIPrdRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('KPI - Product Level').getRecordTypeId();
    private static String bonusdtlSurveyRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey').getRecordTypeId();
    private static List<String> globalKPITypes = label.EDGE_Global_KPI_Types.split(';');
    private static List<String> terrKPITypes = label.EDGE_Territory_KPI_Types.split(';');
    
    //Method to update Unique Key
    public static void updateuniquekey(List<SObject> newItems){
        
        List<Bonus_Assignment__c> newbonusAssignment = (List<Bonus_Assignment__c>) newItems;
        Set<Id> bonusDetailIds = new Set<Id>();
        Map<Id, Bonus_Detail__c> bonusDetailMap = new Map<Id, Bonus_Detail__c>();
        
        for(Bonus_Assignment__c bonusAssmt : newbonusAssignment){
            if(bonusAssmt.RecordTypeId == bonusdtlRecordTypeId && bonusAssmt.Bonus_Header__c !=null && bonusAssmt.Bonus_Detail__c != null ){ 
                bonusDetailIds.add(bonusAssmt.Bonus_Detail__c);
            }
        }
        
        if(bonusDetailIds.size()>0){
            for(Bonus_Detail__c bonusDtlRec : [Select Id,RecordTypeId,KPI_Type__c,Product__c,Survey_KPI__c from Bonus_Detail__c where Id IN :bonusDetailIds]){
                bonusDetailMap.put(bonusDtlRec.Id, bonusDtlRec);
            }
        }
        
        //Generate Unique Key
        for(Bonus_Assignment__c bonusAssnmt : newbonusAssignment){
            if(bonusAssnmt.RecordTypeId == bonushdrRecordTypeId && bonusAssnmt.Bonus_Header__c !=null &&
               bonusAssnmt.Territory__c !=null && bonusAssnmt.Bonus_Detail__c == null) 
            {
                bonusAssnmt.Unique_ID__c = String.valueof(bonusAssnmt.Bonus_Header__c) + '_' + String.valueOf(bonusAssnmt.Territory__c);
            }
            if(bonusAssnmt.RecordTypeId == bonusdtlRecordTypeId && bonusAssnmt.Bonus_Header__c !=null && 
               bonusAssnmt.Bonus_Detail__c !=null)
            {
                if(bonusDetailMap.size()>0 && bonusDetailMap.containsKey(bonusAssnmt.Bonus_Detail__c)){
                    Bonus_Detail__c bonusdtlRec = bonusDetailMap.get(bonusAssnmt.Bonus_Detail__c);
                    if(bonusdtlRec.RecordTypeId == bonusdtlKPIRecordTypeId && bonusdtlRec.KPI_Type__c != null){
                        bonusAssnmt.Unique_ID__c = String.valueof(bonusAssnmt.Bonus_Header__c) + '_' + String.valueOf(bonusdtlRec.KPI_Type__c);
                    }
                    if(bonusdtlRec.RecordTypeId == bonusdtlKPIPrdRecordTypeId && bonusdtlRec.KPI_Type__c !=null && bonusdtlRec.Product__c != null){
                        bonusAssnmt.Unique_ID__c = String.valueof(bonusAssnmt.Bonus_Header__c) + '_' 
                            + String.valueOf(bonusdtlRec.KPI_Type__c) + '_'
                            + String.valueOf(bonusdtlRec.Product__c)+ '_' + String.valueof(bonusAssnmt.Territory__c);
                    }
                    if(bonusdtlRec.RecordTypeId == bonusdtlSurveyRecordTypeId && bonusdtlRec.KPI_Type__c !=null && bonusdtlRec.Survey_KPI__c !=null){
                        bonusAssnmt.Unique_ID__c = String.valueof(bonusAssnmt.Bonus_Header__c) + '_' 
                            + String.valueOf(bonusdtlRec.KPI_Type__c) + '_'
                            + String.valueOf(bonusdtlRec.Survey_KPI__c) + '_' + String.valueof(bonusAssnmt.Territory__c);
                    }
                }
            }
        }     
    }
    
    //Method to sync Global & Territory Weights of the Header down from the details when one or more
    //new territories are added
    public static void syncGlblAndTerrWtForHeader(List<SObject> newItems){
        
        List<Bonus_Assignment__c> newbonusAssignment = (List<Bonus_Assignment__c>) newItems;
        set<Id> bonusheaderIds= new set<Id>(); 
        Map<Id,List<Bonus_Assignment__c>> bonusAssigmentHeader= new Map<Id,List<Bonus_Assignment__c>>();
        
        //Get the record ids of the new bonus assignment records(record type = Bonus Hedaer) associated with 
        //new territories
        for(Bonus_Assignment__c bonusAssnmt : newbonusAssignment){
            if(bonusAssnmt.RecordTypeId == bonushdrRecordTypeId && bonusAssnmt.Bonus_Header__c !=null){// && bonusAssnmt.Id == null
                bonusheaderIds.add(bonusAssnmt.Bonus_Header__c);
                // bonusHeaderAssignments.add(bonusAssnmt);
                if(bonusAssigmentHeader.get(bonusAssnmt.Bonus_Header__c)!=null){
                    bonusAssigmentHeader.get(bonusAssnmt.Bonus_Header__c).add(bonusAssnmt);
                }
                else{
                    bonusAssigmentHeader.put(bonusAssnmt.Bonus_Header__c, new List<Bonus_Assignment__c>{bonusAssnmt});
                }
                
            }
        }
        
        //Get the child bonus detail ids and the respective bonus assigments records of record type bonus details 
        if(bonusheaderIds.size() > 0){
            for(Bonus_Assignment__c bonusAssgRec : [SELECT Id, Bonus_Header__c, Bonus_Detail__r.RecordTypeId,Bonus_Detail__r.KPI_Type__c, 
                                                    Bonus_Detail__r.Weight__c,Bonus_Detail__c,RecordTypeId,Global_Percentage__c, Territory_Percentage__c, 
                                                    Territory__c FROM Bonus_Assignment__c WHERE Bonus_Header__c IN :bonusheaderIds AND RecordTypeId = :bonusdtlRecordTypeId]){
                                                        if(bonusAssigmentHeader.get(bonusAssgRec.Bonus_Header__c)!=null){
                                                            for(Bonus_Assignment__c bonusassObj : bonusAssigmentHeader.get(bonusAssgRec.Bonus_Header__c)){
                                                                
                                                                If(globalKPITypes.contains(bonusAssgRec.Bonus_Detail__r.KPI_Type__c)){
                                                                    bonusassObj.Global_Percentage__c=EDGE_UtilityClass.checkForNull(bonusassObj.Global_Percentage__c)+bonusAssgRec.Bonus_Detail__r.Weight__c;
                                                                }
                                                                else{
                                                                    If(terrKPITypes.contains(bonusAssgRec.Bonus_Detail__r.KPI_Type__c)&& bonusassObj.Territory__c==bonusAssgRec.Territory__c){
                                                                        bonusassObj.Territory_Percentage__c=EDGE_UtilityClass.checkForNull(bonusassObj.Territory_Percentage__c)+bonusAssgRec.Bonus_Detail__r.Weight__c;
                                                                    }
                                                                }
                                                            }
                                                        }   
                                                    }            
        }
    }
    
    /*Method to Update Global & Territory Weight based on Bonus Assignment records inserted or 
	updated (record type = Bonus Details)*/
    public static void updateGlblAndTerrWtFrmDetails( List<SObject> newItems, Map<Id, SObject> oldItems){
        
        List<Bonus_Assignment__c> newbonusAssignment = (List<Bonus_Assignment__c>) newItems;
        Map<Id,Bonus_Assignment__c> oldbonusAssignment = (Map<Id,Bonus_Assignment__c>) oldItems;
        Map<Id,Bonus_Detail__c> bonusIdToBonusMap = new Map<Id,Bonus_Detail__c>();
        Set<Id> bonusheaderIds = new Set<Id>();
        Set<Id> bonusDetailIds = new Set<Id>();
        List<Bonus_Assignment__c> bonusDtlAssignmentList = new List<Bonus_Assignment__c>();
        Map<String ,Decimal> percentageMap= new Map<String,Decimal>();
        List<Bonus_Assignment__c> existAssignment= new List<Bonus_Assignment__c>();
        List<Bonus_Assignment__c> updateBonusHrAss= new List<Bonus_Assignment__c>();
        
        for(Bonus_Assignment__c bonusAssnmt : newbonusAssignment){
            if(bonusAssnmt.RecordTypeId == bonusdtlRecordTypeId && bonusAssnmt.Bonus_Header__c !=null){  
                bonusheaderIds.add(bonusAssnmt.Bonus_Header__c);
                bonusDetailIds.add(bonusAssnmt.Bonus_Detail__c); // Bonus Details w.r.t new or updated assignment reocrds
                bonusDtlAssignmentList.add(bonusAssnmt);// Bonus details assignments w.r.t new or updated assignment reocrds
            }
        }
        if(bonusDetailIds.size() > 0){
            for(Bonus_Detail__c bonusDetail : [Select Id, RecordTypeId, KPI_Type__c, Weight__c,Bonus_Header__c from Bonus_Detail__c where Bonus_Header__c in :bonusheaderIds]){
                bonusIdToBonusMap.put(bonusDetail.Id, bonusDetail);
            } 
        }
        system.debug('oldbonusAssignment @@'+oldItems);
        If(oldItems!=null){
            existAssignment =[SELECT Id, Bonus_Header__c, Bonus_Detail__c,RecordTypeId,Global_Percentage__c, Territory_Percentage__c, 
                              Territory__c FROM Bonus_Assignment__c WHERE id not IN :oldItems.keyset() AND RecordTypeId = :bonusdtlRecordTypeId
                              and Bonus_Header__c in :bonusheaderIds]; 
            
        }
        else{        
            bonusDtlAssignmentList =[SELECT Id, Bonus_Header__c, Bonus_Detail__c,RecordTypeId,Global_Percentage__c, Territory_Percentage__c, 
                                     Territory__c FROM Bonus_Assignment__c WHERE RecordTypeId = :bonusdtlRecordTypeId
                                     and Bonus_Header__c in :bonusheaderIds];
            
        }											
        system.debug('@@@ existAssignment'+existAssignment);
        if(existAssignment!=null){
            bonusDtlAssignmentList.addall(existAssignment);
        }    
        system.debug('@@@ existAssignment'+bonusDtlAssignmentList);
        percentageMap= getWeightPercentage(bonusDtlAssignmentList,bonusIdToBonusMap);
        system.debug('@@@ Existing percentageMap'+percentageMap);
        
        if(bonusheaderIds.size()> 0){
            for(Bonus_Assignment__c bonusHeaderAssgRec : [Select Id, Bonus_Header__c,Unique_ID__c,Territory__c, Territory_Percentage__c, Global_Percentage__c from Bonus_Assignment__c where Bonus_Header__c in :bonusheaderIds AND RecordTypeId = :bonushdrRecordTypeId]){
                bonusHeaderAssgRec.Global_Percentage__c=percentageMap.get(bonusHeaderAssgRec.Bonus_Header__c);
                bonusHeaderAssgRec.Territory_Percentage__c=percentageMap.get(string.valueOf(bonusHeaderAssgRec.Bonus_Header__c)+string.valueOf(bonusHeaderAssgRec.Territory__c));
                updateBonusHrAss.add(bonusHeaderAssgRec);
            }
        }           
        
        if(updateBonusHrAss.size()>0){
            database.update(updateBonusHrAss);
        }
    }

    // new method added
    public static Map<string, Decimal> getWeightPercentage(List<Bonus_Assignment__c> bonusAssignmentlst, Map<Id,Bonus_Detail__c> bonusIdToBonusMap){
        Map<String ,Decimal> percentageMap= new Map<String,Decimal>();
        for(Bonus_Assignment__c bonusAssignmentRec : bonusAssignmentlst){
            if(globalKPITypes.contains(bonusIdToBonusMap.get(bonusAssignmentRec.Bonus_Detail__c).KPI_Type__c)){
                If(percentageMap.get(bonusAssignmentRec.Bonus_Header__c)!=null){
                    percentageMap.put(bonusAssignmentRec.Bonus_Header__c,percentageMap.get(bonusAssignmentRec.Bonus_Header__c)+bonusAssignmentRec.Global_Percentage__c);
                }
                else{
                    percentageMap.put(bonusAssignmentRec.Bonus_Header__c,EDGE_UtilityClass.checkForNull(bonusAssignmentRec.Global_Percentage__c));
                }
                
            }
            else{
                If(terrKPITypes.contains(bonusIdToBonusMap.get(bonusAssignmentRec.Bonus_Detail__c).KPI_Type__c)){
                    string key = string.valueOf(bonusAssignmentRec.Bonus_Header__c)+String.valueOf(bonusAssignmentRec.Territory__c);
                    if(percentageMap.get(key)!=null){
                        percentageMap.put(key,percentageMap.get(key)+bonusAssignmentRec.Territory_Percentage__c);
                    }
                    else{
                        percentageMap.put(key,EDGE_UtilityClass.checkForNull(bonusAssignmentRec.Territory_Percentage__c));
                    }
                }
                
                
            }
        }
        return percentageMap;      
    }
    
    /*******************************************************************
    Method  : validateBonusAssignment
    Purpose : We can't add/remove territory, if the respective Bonus Header Status is Active(ES20-6810)
    ********************************************************************/
    public static void validateBonusAssignment(List<sObject> newItems){
        List<Bonus_Assignment__c> newbonusAssignmentList = (List<Bonus_Assignment__c>) newItems;
        set<Id> bonusHeaderIds = new set<Id>();
        Map<String, Bonus_Header__c> bonusHeaderStatusMap = new Map<String,Bonus_Header__c>();
        
        if(newbonusAssignmentList != null){
            for(Bonus_Assignment__c bonusAssignment : newbonusAssignmentList){
                bonusHeaderIds.add(bonusAssignment.Bonus_Header__c);
            }
        }
        if(bonusHeaderIds != null && bonusHeaderIds.size() > 0 && Schema.SObjectType.Bonus_Header__c.isAccessible()){
            for(Bonus_Header__c bonusHeader : [SELECT Id,Status__c FROM Bonus_Header__c WHERE Id =:bonusHeaderIds AND Status__c = 'Active']){
                bonusHeaderStatusMap.put(bonusHeader.Id, bonusHeader);
            }
        }
        
        for(Bonus_Assignment__c bonusAssignment : newbonusAssignmentList){
            //when existing territory is removed from bonus assignment
            if(bonusHeaderStatusMap.size()>0 && bonusHeaderStatusMap.containskey(bonusAssignment.Bonus_Header__c)){
                bonusAssignment.addError(label.EDGE_RemoveBonusAssignment);
            }
        }
    }	
}