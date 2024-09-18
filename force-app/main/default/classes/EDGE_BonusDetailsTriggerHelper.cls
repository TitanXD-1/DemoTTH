/**********************************************************************
Name: EDGE_BonusDetailsTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for BonusDetailsTrigger
=======================================================================
History                                                            
-------                                                            
VERSION  	  AUTHOR            DATE             		 DETAIL
1.0       Sandip Ghosh      08-Jan-2020      	Initial Development(ES20-4995,ES20-4997) methods :
												createBonusAssignments,updateBonusAssignments

2.0      Vikas Anand		20-Jan-2020			Method to Validate Bonus Detail Record 
												Creation/Updation/Deletion(ES20-6811)
												Method:validateBonusDetailRecord
***********************************************************************/
public with sharing class EDGE_BonusDetailsTriggerHelper {
    
    private static String bonushdrRecordTypeId = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
    private static String bonusdtlRecordTypeId = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Detail').getRecordTypeId();
    private static String bonusdtlKPIRecordTypeId = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('KPI').getRecordTypeId();
    private static List<String> globalKPITypes = label.EDGE_Global_KPI_Types.split(';');
    private static List<String> terrKPITypes = label.EDGE_Territory_KPI_Types.split(';');
    
    //Method to Create Bonus Assignment for Bonus Detail of Type MPA, MAS, OES, Volume
    public static void createBonusAssignments(Map<Id, SObject> newItemsMap){
        
        List<Bonus_Detail__c> newbonusDetailRecs = (List<Bonus_Detail__c>) newItemsMap.values();
        List<Bonus_Assignment__c> bonusAssignments = new List<Bonus_Assignment__c>();
        
        for(Bonus_Detail__c bonusDetail : newbonusDetailRecs){
            if(bonusDetail.RecordTypeId == bonusdtlKPIRecordTypeId && globalKPITypes.contains(bonusDetail.KPI_Type__c)){                  
                Bonus_Assignment__c bonusAssgRec = new Bonus_Assignment__c();
                bonusAssgRec.Bonus_Detail__c = bonusDetail.Id;
                bonusAssgRec.Bonus_Header__c = bonusDetail.Bonus_Header__c;
                bonusAssgRec.Global_Percentage__c = bonusDetail.Weight__c;
                bonusAssgRec.RecordTypeId = bonusdtlRecordTypeId;
                bonusAssignments.add(bonusAssgRec);
            }
        }
        System.debug('bonusAssignments = '+ bonusAssignments);
        if(bonusAssignments.size() > 0 && Bonus_Assignment__c.sObjectType.getDescribe().isCreateable()){
            List<Database.SaveResult> dsResults = Database.insert(bonusAssignments, false);            
            populateErros(dsResults, newItemsMap, bonusAssignments);
        }
    }
    
    //Method to Update Bonus Assignment Global & Territory Weight
    public static void updateBonusAssignments(Map<Id, SObject> newItemsMap, Map<Id, SObject> oldItemsMap){
        
        List<Bonus_Detail__c> newbonusDetailRecs = (List<Bonus_Detail__c>) newItemsMap.values();
        List<Bonus_Assignment__c> bonusAssignments = new List<Bonus_Assignment__c>();
        Set<Id> bonusDetailIds = new Set<Id>();
        Map<Id, Double> bonusDtlIdToWtMap = new Map<Id, Double>();
        
        for(Bonus_Detail__c bonusDetail : newbonusDetailRecs){
            Bonus_Detail__c oldBonusDetail = (Bonus_Detail__c)oldItemsMap.get(bonusDetail.Id);
            if(oldBonusDetail != null && bonusDetail.Weight__c != oldBonusDetail.Weight__c){
                bonusDtlIdToWtMap.put(bonusDetail.Id,bonusDetail.Weight__c);//Bonus_Header__c
            }
        }
        
        if(!bonusDtlIdToWtMap.isEmpty()){
            for(Bonus_Assignment__c bonusAssgRec : [Select Id, Bonus_Header__c, Bonus_Detail__c, Global_Percentage__c 
                                                    from Bonus_Assignment__c where Bonus_Detail__c 
                                                    IN :bonusDtlIdToWtMap.keySet()
                                                    AND RecordTypeId = :bonusdtlRecordTypeId]){
                                                        Double updatedWt = bonusDtlIdToWtMap.get(bonusAssgRec.Bonus_Detail__c);
                                                        Bonus_Detail__c bonusDetail = (Bonus_Detail__c)newItemsMap.get(bonusAssgRec.Bonus_Detail__c);
                                                        
                                                        if(bonusDetail != null && updatedWt != null){
                                                            if(globalKPITypes.contains(bonusDetail.KPI_Type__c)){
                                                                bonusAssgRec.Global_Percentage__c = updatedWt;
                                                                bonusAssignments.add(bonusAssgRec);
                                                            }else if(terrKPITypes.contains(bonusDetail.KPI_Type__c)){
                                                                bonusAssgRec.Territory_Percentage__c = updatedWt;
                                                                bonusAssignments.add(bonusAssgRec);
                                                            }
                                                        }
                                                    } 
        }
        
        if(bonusAssignments.size() > 0 && Bonus_Assignment__c.sObjectType.getDescribe().isUpdateable()){
            List<Database.SaveResult> dsResults = Database.update(bonusAssignments, false);
            populateErros(dsResults, newItemsMap, bonusAssignments);
        }
    }
    
    //Method to populate records with error message in case of any exception during DML opeartion
    private static void populateErros(List<Database.SaveResult> dsResults, Map<Id, SObject> newItemsMap, List<Bonus_Assignment__c> bonusAssignments){
        Integer recordCount = 0;
        for(Database.SaveResult saveResult : dsResults){
            System.debug('saveResult = '+ saveResult);
            if(!saveResult.isSuccess()){
                for (Database.Error error : saveResult.getErrors()) {
                    String errorMessage = '';
                    if (error.getStatusCode() == System.StatusCode.DUPLICATE_VALUE){
                        errorMessage =  'Already a bonus details record exists with the same KPI configuration.';
                    }else{
                        errorMessage =  error.getMessage();
                    }
                    if(bonusAssignments != null && bonusAssignments.size() > 0){
                        Bonus_Assignment__c bnsAssgnRecord = bonusAssignments[recordCount];
                        if(bnsAssgnRecord != null && bnsAssgnRecord.Bonus_Detail__c != null){
                            Bonus_Detail__c record = (Bonus_Detail__c)newItemsMap.get(bnsAssgnRecord.Bonus_Detail__c);
                            if(record != null){
                                record.addError(errorMessage);
                            } 
                        } 
                    }
                }                                       	
            }
            recordCount++;
        }
    }
    
    //Method to Check When Related Bonus Header is Active, then cannot Create/Update/Delete Bonus Detail Record
    public Static void validateBonusDetailRecord(List<SObject> newItems){
        
        List<Bonus_Detail__c> newbonusDetailRecsList = (List<Bonus_Detail__c>) newItems;
        Set<Id> bonusHeaderStatusId = new Set<Id>();
        String errorMsg = Label.Bonus_Detail_Error_Message;
        Set<Id> bonusHeaderIds = new Set<Id>();
        
        for(Bonus_Detail__c bonusdtl : newbonusDetailRecsList){
            bonusHeaderIds.add(bonusdtl.Bonus_Header__c);  
        }
        if(bonusHeaderIds.size()>0){
            for(Bonus_Header__c bonusHdr : [Select Id, Status__c from Bonus_Header__c Where Id IN :bonusHeaderIds AND Status__c = 'Active']){
                bonusHeaderStatusId.add(bonusHdr.Id);
            }
        }
        if(bonusHeaderStatusId.size()>0){
            for(Bonus_Detail__c bonusDetail : newbonusDetailRecsList){
                //When Bonus Detail Record is Created/Edited/Deleted
                if(bonusHeaderStatusId.Contains(bonusDetail.Bonus_Header__c)){
                    bonusDetail.addError(errorMsg);      
                }
            }
        }
    }
}