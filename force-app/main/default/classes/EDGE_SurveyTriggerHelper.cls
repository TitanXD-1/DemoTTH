/**********************************************************************
Name: EDGE_SurveyTriggerHelper
=======================================================================
Req: 
ES20-704 - Setting up Recurring surveys- With Prepopulated Responses
ES20-738 - Setting up Recurring surveys- Without Prepopulated Responses
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1  .0    Monalisa Halder   05/04/2019        ES20-704,ES20-738

***********************************************************************/

public with sharing class EDGE_SurveyTriggerHelper{
    
    public static void surveyFreqChange(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        Map<Id,Integer> surveyFreqDiffMap = new Map<Id,Integer>();
        List<Outlet_Survey__c> outletSurveyList = new List<Outlet_Survey__c>();
        List<Outlet_Survey__c> updateOutletSurveyList = new List<Outlet_Survey__c>();
        
        //if the survey frequency value is changed 
        if(!oldItems.isEmpty() && !newItems.isEmpty()){
            for(SObject obj :newItems.values()){
                Survey__c  surveyRec  = (Survey__c)obj; 
                Survey__c oldSurveyRec = (Survey__c)oldItems.get(surveyRec.Id);
                //Checking if old map is not null
                if(oldSurveyRec != null && oldSurveyRec.Frequency__c != null && surveyRec.Frequency__c != oldSurveyRec.Frequency__c){
                   	//if New map frequency is not null, keeping the integer value of the frequency else setting it to zero
                    Integer frequency = surveyRec.Frequency__c != null ? Integer.valueof(surveyRec.Frequency__c): 0;
                    //Get the difference if the frequency values are not matching
                    Integer freqDiff  = frequency  != oldSurveyRec.Frequency__c ? frequency - Integer.valueof(oldSurveyRec.Frequency__c): 0;
                    if(freqDiff != 0){
                       surveyFreqDiffMap.put(surveyRec.Id,freqDiff);
                        
                    }
                    
                }
                
            } 
        }
        //Update the outlet survey completion date , if there is any change in the survey frequency
        if(!surveyFreqDiffMap.isEmpty()){
            if(Schema.sObjectType.Outlet_Survey__c.isAccessible()) {
                outletSurveyList = [SELECT Id, Survey__c, Completion_Date__c,Survey_Valid_From__c,Achievement_status__c from Outlet_Survey__c where Achievement_status__c = 'In Progress' and Survey__c IN :surveyFreqDiffMap.keySet()];
            } 
            for(Outlet_Survey__c outletSurveyRec :outletSurveyList){
                
                if(outletSurveyRec.Survey_Valid_From__c != null && (surveyFreqDiffMap.containsKey(outletSurveyRec.Survey__c))){
                
                    outletSurveyRec.Survey_Valid_From__c = outletSurveyRec.Survey_Valid_From__c.addDays(surveyFreqDiffMap.get(outletSurveyRec.Survey__c));  
                }
                
                updateOutletSurveyList.add(outletSurveyRec);
            }
            if(!updateOutletSurveyList.IsEmpty()){
                if(Schema.sObjectType.Outlet_Survey__c.isUpdateable() ) {
                    update updateOutletSurveyList;
                }
            }
        }
    }
    
    /*******************************************************************
    Method  : checkAndGenerateSharing
    Purpose : To create sharing record on Insert
    ********************************************************************/
    public static void checkAndGenerateSharing(List<Survey__c> newItems){
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    
    /*******************************************************************
    Method  : validateAndReGenerateSharing
    Purpose : Modify, Validate sharing record on update
    ********************************************************************/
    public static void validateAndReGenerateSharing(List<Survey__c> newItems,Map<Id, SObject> oldItems){
        Map<Id, Survey__c> mapOldItems;
        List<Survey__c> lstNewChangeGeography = new List<Survey__c>();
        List<Survey__c> lstOldChangeGeography = new List<Survey__c>();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
        if(oldItems != null){
            mapOldItems = (Map<Id, Survey__c>)oldItems;
        }
        
        for(Survey__c objBusinessRole : newItems){
            if(mapOldItems.containsKey(objBusinessRole.Id) && objBusinessRole.Country__c != mapOldItems.get(objBusinessRole.Id).Country__c){
                lstNewChangeGeography.add(objBusinessRole);
                lstOldChangeGeography.add(mapOldItems.get(objBusinessRole.Id));
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