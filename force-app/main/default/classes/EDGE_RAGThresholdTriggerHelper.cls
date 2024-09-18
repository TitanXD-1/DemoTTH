/**********************************************************************
Name: EDGE_RAGThresholdTriggerHelper
=======================================================================
Req: 
ES20-1034
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Preyanka Ghosh     29/04/2019      Initial Development
***********************************************************************/
public with sharing class EDGE_RAGThresholdTriggerHelper {
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<KPI_RAG_Threshold__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<KPI_RAG_Threshold__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, KPI_RAG_Threshold__c> mapOldItems;
        List<KPI_RAG_Threshold__c> lstNewChangeGeography = new List<KPI_RAG_Threshold__c>();
        List<KPI_RAG_Threshold__c> lstOldChangeGeography = new List<KPI_RAG_Threshold__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, KPI_RAG_Threshold__c>)oldItems;
        }
        
        for(KPI_RAG_Threshold__c ragThreshold : newItems){
            if(mapOldItems.containsKey(ragThreshold.Id) && ragThreshold.Country__c != mapOldItems.get(ragThreshold.Id).Country__c){
                lstNewChangeGeography.add(ragThreshold);
                lstOldChangeGeography.add(mapOldItems.get(ragThreshold.Id));
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
    Method  : updateRecordType
    Purpose : This method is used to update custom Record Type field 
    with RecordType.Name which helps in duplicate rule
    ********************************************************************/    
    public static void updateRecordType(List<KPI_RAG_Threshold__c> newItems, Map<Id, SObject> oldItems) {
        Map<Id, RecordType> ragRecordTypeMap = new Map<Id, RecordType>([SELECT Id, Name FROM RecordType WHERE SobjectType = 'KPI_RAG_Threshold__c']);
        Map<Id, KPI_RAG_Threshold__c> mapOldItems;
        
        if(oldItems != null && oldItems.size()>0){
            mapOldItems = (Map<Id, KPI_RAG_Threshold__c>)oldItems;  
        }
        
        if(newItems != null && newItems.size()>0){
            for(KPI_RAG_Threshold__c objKPIRAG : newItems) {
                if(objKPIRAG.RecordTypeId != null && ragRecordTypeMap.containsKey(objKPIRAG.RecordTypeId) && 
                   (mapOldItems == null ||
                    (mapOldItems != null && 
                     (mapOldItems.get(objKPIRAG.Id).RecordTypeId != objKPIRAG.RecordTypeId || 
                      mapOldItems.get(objKPIRAG.Id).Country__c != objKPIRAG.Country__c || 
                      mapOldItems.get(objKPIRAG.Id).KPI_Type__c != objKPIRAG.KPI_Type__c
                     )
                    )
                   )
                  ){
                      objKPIRAG.Record__c = ragRecordTypeMap.get(objKPIRAG.RecordTypeId).Name;
                      if(ragRecordTypeMap.get(objKPIRAG.RecordTypeId).Name == 'Territory' && objKPIRAG.KPI_Type__c != null){
                          objKPIRAG.KPI_Type__c = null;
                      }
                  }
            }
        }
    }
    
}