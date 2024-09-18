/**********************************************************************
Name: EDGE_OpportunityTemplateTriggerHelper
=======================================================================
Req: 
ES20-812 -Check Duplicate Opportunity Templates in the System.
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                            DATE              DETAIL
1.0       Sandeep Sahoo                     17/04/2019      Initial Development
2.0       Preyanka Ghosh                    21/05/2019      ES20-1615
3.0       Juned Khan                        20/09/2020      ES20-8610:Compound Key generation logic change to accept 18 characters to validate if any existig template is present

***********************************************************************/
public with sharing class EDGE_OpportunityTemplateTriggerHelper {
    /**************
    Name        : checkDuplicateOpptemplate
    Description : This method will check system for Duplicate Opportunity Template existing in the esystem.
    ***************/    
    public static void checkDuplicateOppTemplate(List<SObject> oppTemplateList, Map<Id,SObject> oldMap, Boolean isUpdate){        
        Map<Opportunity_Template__c,String> outletTemplateNewMap = new Map<Opportunity_Template__c,String>();
        Map<Opportunity_Template__c,String> outletTemplateExistingMap = new Map<Opportunity_Template__c,String>();
        String compkey='';
        String compkeyan='';
        for(SObject sObj : oppTemplateList){
            Opportunity_Template__c oppTemplateObj = (Opportunity_Template__c)sObj;
                // Update Logic
                if(isUpdate && oldMap!= null && oldMap.containsKey(oppTemplateObj.Id) && oppTemplateObj.Opportunity_Type__c!='Cycle Brief'){
                    Opportunity_Template__c oldOppTemplateObj = (Opportunity_Template__c)oldMap.get(oppTemplateObj.Id);
                    if(oldOppTemplateObj.Cluster__c!=oppTemplateObj.Cluster__c || oldOppTemplateObj.Area_Region__c!=oppTemplateObj.Area_Region__c || oldOppTemplateObj.Territory__c!=oppTemplateObj.Territory__c || 
                       oldOppTemplateObj.Product__c!=oppTemplateObj.Product__c || oldOppTemplateObj.Opportunity_Type__c!=oppTemplateObj.Opportunity_Type__c || oldOppTemplateObj.Sub_Segment__c!=oppTemplateObj.Sub_Segment__c || //compared old sub_segment with new sub_segment value
                       oldOppTemplateObj.Channel__c != oppTemplateObj.Channel__c || oldOppTemplateObj.Segment__c != oppTemplateObj.Segment__c || oldOppTemplateObj.Activation__c != oppTemplateObj.Activation__c||
                        oldOppTemplateObj.Fascia__c != oppTemplateObj.Fascia__c)
                      
                    {
                         //included sub_Segment__c in combination key 
                        compkey = keyGenerator(oppTemplateObj.Cluster__c)+'_'+keyGenerator(oppTemplateObj.Area_Region__c)+'_'+keyGenerator(oppTemplateObj.Territory__c)+'_'+String.valueOf(oppTemplateObj.Channel__c)+'_'+String.valueOf(oppTemplateObj.Segment__c)+'_'+String.valueOf(oppTemplateObj.Sub_Segment__c) +'_'+keyGenerator(oppTemplateObj.Fascia__c)+'_'+String.valueOf(oppTemplateObj.Opportunity_Type__c);
                        compkey = checkProductOrActivation(oppTemplateObj, compkey) ; 
                       
                    }
                    String replaceCompkey = compkey.replace('null', '');
                     system.debug('$$$$ update '+replaceCompkey);
                    outletTemplateNewMap.put(opptemplateObj,replaceCompkey);    
                }
                // insert Logic
                else if(oppTemplateObj.Opportunity_Type__c!='Cycle Brief'){
         
                    //included Sub_Segment__c in combination key 
                    compkey= keyGenerator(oppTemplateObj.Cluster__c)+'_'+keyGenerator(oppTemplateObj.Area_Region__c)+'_'+keyGenerator(oppTemplateObj.Territory__c)+'_'+String.valueOf(oppTemplateObj.Channel__c)+'_'+String.valueOf(oppTemplateObj.Segment__c)+'_'+String.valueOf(oppTemplateObj.Sub_Segment__c)+'_'+keyGenerator(oppTemplateObj.Fascia__c) +'_'+String.valueOf(oppTemplateObj.Opportunity_Type__c);
                    compkey = checkProductOrActivation(oppTemplateObj, compkey);
                    String replaceCompkey = compkey.replace('null', '');
                    system.debug('$$$$ insert '+replaceCompkey);
                    
                    outletTemplateNewMap.put(opptemplateObj,replaceCompkey);
                    
                }                               
        }
        System.debug('@@outletTemplateNewMap' +outletTemplateNewMap);
        // fetch existing Opp Templates
        for(Opportunity_Template__c oppTempExist : [SELECT ID,Compound_Key__c FROM Opportunity_Template__c WHERE Compound_Key__c IN: outletTemplateNewMap.values()]){
           outletTemplateExistingMap.put(oppTempExist,opptempexist.Compound_Key__c);
           System.debug('@@outletTemplateExistingMap' +outletTemplateExistingMap); 
        } 
        
        //check and throw error for existing Opp Templates
        for(SObject sObj : oppTemplateList){
            Opportunity_Template__c oppTemplateObj = (Opportunity_Template__c)sObj;
            if(outletTemplateExistingMap!=null){
                for(Opportunity_Template__c otExist : outletTemplateExistingMap.keySet()){
                    if(outletTemplateExistingMap.get(otExist) == outletTemplateNewMap.get(oppTemplateObj)){
                        oppTemplateObj.addError(Label.Duplicate_Opportunity_Template);    
                    } 
                }     
            }
        }
    }    
    //the below method generates Key
    public static String keyGenerator(Id objectId){
        String compkey = '';
        if(objectId!=null){
            compkey += String.valueOf(objectId); //ES20-8610-removed code which was earlier convertig objectId to 15 digits      
        }
        if(objectId==null){
            compkey += '';
        }        
        return compkey;
    }
    public static String checkProductOrActivation(Opportunity_Template__c oppTemplateObj, String compkey){
        if(oppTemplateObj.Product__c!=null && oppTemplateObj.Activation__c==null){
            compkey=compkey+'_'+oppTemplateObj.Product__c;                    
        }else if(opptemplateObj.Product__c==null && opptemplateObj.Activation__c!=null){
            compkey= compkey+'_'+oppTemplateObj.Activation__c;  //replaced String.valueOf(oppTemplateObj.Activation__c) with keyGenerator(oppTemplateObj.Activation__c) as Activation is a lookup field instead of text(earlier)                 
        }
        return compkey;
    }
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Opportunity_Template__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Cluster__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Cluster__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Cluster__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Opportunity_Template__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Opportunity_Template__c> mapOldItems;
        List<Opportunity_Template__c> lstNewChangeGeography = new List<Opportunity_Template__c>();
        List<Opportunity_Template__c> lstOldChangeGeography = new List<Opportunity_Template__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Opportunity_Template__c>)oldItems;
        }
        
        for(Opportunity_Template__c objOppTemp : newItems){
            if(mapOldItems.containsKey(objOppTemp.Id) && objOppTemp.Cluster__c != mapOldItems.get(objOppTemp.Id).Cluster__c){
                lstNewChangeGeography.add(objOppTemp);
                lstOldChangeGeography.add(mapOldItems.get(objOppTemp.Id));
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Cluster__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Cluster__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Cluster__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Cluster__c', 'Down', 'Edit');
        }       
    }
        
    /*******************************************************************
    Method  : checkTerritoryGeoOppTemplate
    Purpose : To check if territory and cluster belong to same geography hierarchy
    ********************************************************************/
    public static void checkTerritoryGeoOppTemplate(List<Opportunity_Template__c> newItems, Map<Id, SObject> oldItems){
        //Variables
        List<Opportunity_Template__c> existingOpptyTemplateList = new List<Opportunity_Template__c>();
        Map<Id,List<Opportunity_Template__c>> existingMarCycleMap = new Map<Id,List<Opportunity_Template__c>>();
        Set<Id> marketIdSet = new Set<Id>();
        
        Map<Id,Opportunity_Template__c> oldOptyTemMap;
        List<Opportunity_Template__c> opptyTemplateToCheck = new List<Opportunity_Template__c>();
        Set<String> opptyTemplateClusterSet = new Set<String>();
        Set<String> territorySet = new Set<String>();
        Map<String,Geography__c> clusterRecordTypeMap = new Map<String,Geography__c>();
        
        Map<String,String> terrMarketMap = new Map<String,String>();
        Map<String,String> terrHubMap = new Map<String,String>();
        Map<String,String> terrClusterMap = new Map<String,String>();
        Map<String,String> terrCountryMap = new Map<String,String>();
        String countryRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Country').getRecordTypeId();
        String clusterRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Cluster').getRecordTypeId();
        String hubRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Hub').getRecordTypeId();
        String marketRecordTypeId = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Market').getRecordTypeId();
        
        if(oldItems!=null){
            oldOptyTemMap = (Map<Id,Opportunity_Template__c>)oldItems;  
        }
        //Preparing territory and cluster set to use it to check later if they belong to same hierarchy 
        for(Opportunity_Template__c newOptyTemp : newItems ){
            if(newOptyTemp.Territory__c != null && 
               (oldOptyTemMap == null || (oldOptyTemMap != null && 
                                          (oldOptyTemMap.get(newOptyTemp.id).Territory__c != newOptyTemp.Territory__c || 
                                           oldOptyTemMap.get(newOptyTemp.id).Cluster__c != newOptyTemp.Cluster__c)))){
                opptyTemplateToCheck.add(newOptyTemp);
                opptyTemplateClusterSet.add(newOptyTemp.Cluster__c);
                territorySet.add(newOptyTemp.Territory__c);
            }                    
        }
        
        System.debug('@@opptyTemplateToCheck' +opptyTemplateToCheck);
        System.debug('@@opptyTemplateClusterSet' +opptyTemplateClusterSet);
        System.debug('@@territorySet' +territorySet);
        
        if(opptyTemplateClusterSet!=null && opptyTemplateClusterSet.size()>0){
            for(Geography__c geoObj : [SELECT Id, RecordTypeId, Parent_Geography__c FROM Geography__c WHERE Id IN :opptyTemplateClusterSet]){
                clusterRecordTypeMap.put(geoObj.Id, geoObj);
            }
        }
        System.debug('@@clusterRecordTypeMap' +clusterRecordTypeMap);
        
        //Market,Hub,Cluster,Country Map creation with respect to associated territory
        for(Territory__c terObj :[Select Id, Country__c, Country__r.Parent_Geography__c, Country__r.Parent_Geography__r.Parent_Geography__c, 
                                  Country__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c from Territory__c where Id in :territorySet])
        {
            terrCountryMap.put(terObj.Id, terObj.Country__c);
            terrClusterMap.put(terObj.Id, terObj.Country__r.Parent_Geography__c);
            terrHubMap.put(terObj.Id, terObj.Country__r.Parent_Geography__r.Parent_Geography__c);
            terrMarketMap.put(terObj.Id, terObj.Country__r.Parent_Geography__r.Parent_Geography__r.Parent_Geography__c);                          
        }
        
        for(Opportunity_Template__c newOptyTemp : opptyTemplateToCheck){
            if(clusterRecordTypeMap != null && clusterRecordTypeMap.containsKey(newOptyTemp.cluster__c)){
                String recordTypeId = clusterRecordTypeMap.get(newOptyTemp.cluster__c).RecordTypeId;
                if(recordTypeId == countryRecordTypeId && terrCountryMap != null 
                   && newOptyTemp.Cluster__c != terrCountryMap.get(newOptyTemp.Territory__c))
                {
                    newOptyTemp.addError('Your Cluster And Territory Are Not In Same Geography Hierarchy');
                }
                else if(recordTypeId == clusterRecordTypeId && terrClusterMap != null 
                        && newOptyTemp.Cluster__c != terrClusterMap.get(newOptyTemp.Territory__c))
                {
                    newOptyTemp.addError('Your Cluster And Territory Are Not In Same Geography Hierarchy');
                }
                else if(recordTypeId == hubRecordTypeId && terrHubMap != null 
                        && newOptyTemp.Cluster__c != terrHubMap.get(newOptyTemp.Territory__c))
                {
                    newOptyTemp.addError('Your Cluster And Territory Are Not In Same Geography Hierarchy');
                }
                else if(recordTypeId == marketRecordTypeId && terrMarketMap != null 
                        && newOptyTemp.cluster__c != terrMarketMap.get(newOptyTemp.Territory__c))
                {
                    newOptyTemp.addError('Your Cluster And Territory Are Not In Same Geography Hierarchy');
                }
            }
        }
    }
}