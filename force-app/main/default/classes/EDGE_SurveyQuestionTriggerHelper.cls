/**********************************************************************
Name: EDGE_SurveyQuestionTriggerHelper
=======================================================================
Req: 
ES20-4593 - Assign Bonus Type Questions in a Survey
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR               DATE              DETAIL
1.0       Preyanka Ghosh       08/01/2020        Initial Development 
2.0       Sagar Barman         09/04/2020        ES20 - 6897   
***********************************************************************/
public with sharing class EDGE_SurveyQuestionTriggerHelper {
    
    /*******************************************************************
    Method  : checkDuplicateSurveyKPI
    Purpose : In a Survey there can be only one question with the 
            Selected "Survey KPI" Pickup option, a second question with the same Survey KPI is not valid
    ********************************************************************/
    public static void checkDuplicateSurveyKPI(List<Survey_Question__c> newItems, Map<Id, SObject> oldItems){
        Map<Id,List<Id>> mapSurveyWithKPI = new Map<Id,List<Id>>();
        Map<Id,Survey_Question__c> mapOldItem; 
        Map<Id,List<Id>> mapTempSurveyKPI = new Map<Id,List<Id>>();
        Set<Id> setSurvey = new Set<Id>();
        Id outletSurveyId = Schema.SObjectType.Survey__c.getRecordTypeInfosByName().get('Outlet Survey').getRecordTypeId();
        
        if(oldItems != null){
            mapOldItem = (Map<Id,Survey_Question__c>) oldItems;
        }
        
        //Create mapping between Survey and Survey Question 
        for(Survey_Question__c surveyQus : newItems){
            if(surveyQus.Survey_KPI__c != null && (oldItems  == null ||(oldItems != null && surveyQus.Survey_KPI__c != mapOldItem.get(surveyQus.Id).Survey_KPI__c))){
                setSurvey.add(surveyQus.Survey__c);     
                
                //Check whether in same transaction duplicate Survey KPI exists for same survey or not
                if(mapTempSurveyKPI.containskey(surveyQus.Survey__c)){
                    List<Id> lstSurveyKPI = mapTempSurveyKPI.get(surveyQus.Survey__c);
                    if(lstSurveyKPI.contains(surveyQus.Survey_KPI__c)){
                        surveyQus.addError(Label.EDGE_SurveyKPIError);
                    } else {
                        mapTempSurveyKPI.get(surveyQus.Survey__c).add(surveyQus.Survey_KPI__c);
                    }
                } else {
                    mapTempSurveyKPI.put(surveyQus.Survey__c, new List<Id>{surveyQus.Survey_KPI__c});
                }
            }                
        }
        
        //Get all the related Question for a Survey
        for(Survey_Question__c surveyQus : [SELECT Id, Name, Survey__c, Survey_KPI__c FROM Survey_Question__c WHERE Survey__r.RecordTypeId =:outletSurveyId AND Survey__c IN :setSurvey AND Survey_KPI__c != null AND Active__c = True]){
            if(mapSurveyWithKPI.containsKey(surveyQus.Survey__c)){
                List<Id> lstSurveyQus = mapSurveyWithKPI.get(surveyQus.Survey__c);
                /*if(mapOldItem != null && !mapOldItem.containsKey(surveyQus.Id)){
                    mapSurveyWithKPI.get(surveyQus.Survey__c).add(surveyQus.Survey_KPI__c);
                }*/
                if(!lstSurveyQus.contains(surveyQus.Survey_KPI__c) && mapOldItem == null){
                    mapSurveyWithKPI.get(surveyQus.Survey__c).add(surveyQus.Survey_KPI__c);                    
                } else if (mapOldItem != null && !mapOldItem.containsKey(surveyQus.Id)){
                    mapSurveyWithKPI.get(surveyQus.Survey__c).add(surveyQus.Survey_KPI__c);                    
                }
            } else {
                mapSurveyWithKPI.put(surveyQus.Survey__c, new List<Id>{surveyQus.Survey_KPI__c});                        
            }
        }
        
        //Detect the duplicate Survey KPI
        for(Survey_Question__c surveyQus : newItems){
            if(mapSurveyWithKPI.containsKey(surveyQus.Survey__c) && mapSurveyWithKPI.get(surveyQus.Survey__c).contains(surveyQus.Survey_KPI__c)){
                surveyQus.addError(Label.EDGE_SurveyKPIError);
            }                               
        }        
    }
    //***The below method is for Conditional Survey check***//
    public static void validateChildQuestion(List<Survey_Question__c> newItemsList,Map<Id,SObject> newItemsMap, Map<Id, SObject> oldItems){
        Set<Id> parentQuestionIdSet = new Set<Id>();
        List<String> parentAnswerOptList = new List<String>();
        Map<String,Integer> mapParentToChildCount = new Map<String,Integer>();
        List<Survey_Question__c> existingQuestionList = new List<Survey_Question__c>(); 
        Map<Id,Survey_Question__c> mapOldItem,mapNewItem; 
        mapNewItem = (Map<Id,Survey_Question__c>) newItemsMap;
        Map<Id,Integer> mapParentQAndChildQNumber = new Map<Id,Integer>();
        //insert
        if(oldItems == null){
            for(Survey_Question__c surveyQus : newItemsList){            
                if(surveyQus.Parent_Question__c !=null && surveyQus.Parent_Answer_Option__c!=null){
                    List<String> tempList = surveyQus.Parent_Answer_Option__c.split(';');
                    parentQuestionIdSet.add(surveyQus.Parent_Question__c);
                    parentAnswerOptList.addAll(tempList); 
                    //populate the mapParentQAndChildQNumber
                    String key = surveyQus.Parent_Question__c;
                    if(mapParentQAndChildQNumber.containsKey(key)){
                        Integer count = mapParentToChildCount.get(key);                                                 
                        mapParentQAndChildQNumber.put(key,count+1);        
                    }else{
                        mapParentQAndChildQNumber.put(key,1);    
                    }
                }    
            }       
        }
        //update
        if(oldItems!=null){
            mapOldItem = (Map<Id,Survey_Question__c>) oldItems;
            for(Survey_Question__c surveyQus : mapOldItem.values()){
                if((mapNewItem.get(surveyQus.Id).Parent_Question__c !=null && mapNewItem.get(surveyQus.Id).Parent_Answer_Option__c!=null) 
                   && ((mapNewItem.get(surveyQus.Id).Parent_Question__c != mapOldItem.get(surveyQus.Id).Parent_Question__c) 
                   || (mapNewItem.get(surveyQus.Id).Parent_Answer_Option__c != mapOldItem.get(surveyQus.Id).Parent_Answer_Option__c))){
                    List<String> tempList = mapNewItem.get(surveyQus.Id).Parent_Answer_Option__c.split(';');
                    parentQuestionIdSet.add(mapNewItem.get(surveyQus.Id).Parent_Question__c);
                    parentAnswerOptList.addAll(tempList);
                }    
            }       
        }
         
        if(parentQuestionIdSet.size()>0 && parentAnswerOptList.size()>0){
            for(Survey_Question__c sq : [SELECT Id,Parent_Question__c,Parent_Answer_Option__c FROM Survey_Question__c 
                                         WHERE Parent_Question__c IN :parentQuestionIdSet AND Parent_Answer_Option__c IN : parentAnswerOptList]){
                                             String key = sq.Parent_Question__c+'_'+sq.Parent_Answer_Option__c;                                               
                                             if(mapParentToChildCount.containsKey(key)){
                                                 Integer count = mapParentToChildCount.get(key);                                                 
                                                 mapParentToChildCount.put(key,count+1);        
                                             }else{
                                                 mapParentToChildCount.put(key,1);    
                                             }     
            }            
        }        
        for(Survey_Question__c surveyQus : newItemsList){
            String key = surveyQus.Parent_Question__c+'_'+surveyQus.Parent_Answer_Option__c;
            Integer childQuestionLimit = Integer.valueOf(System.Label.EDGE_Child_Questions_Limit);
            if(mapParentToChildCount.containsKey(key)){
                Integer existingCount = mapParentToChildCount.get(key);
                Integer questionsLeft = childQuestionLimit - existingCount ;
                if(questionsLeft < 1 && key != null && key.split('_') != null && key.split('_').size() > 1){
                    surveyQus.addError('Error : One parent Question can have maximum '+ childQuestionLimit+' child questions per Option.Here the Parent Question Option '+key.split('_')[1] + ' already has '+ existingCount + ' child questions in System.');
                }else if(mapParentQAndChildQNumber.get(surveyQus.Parent_Question__c) > questionsLeft && key != null && key.split('_') != null && key.split('_').size() > 1){
                    surveyQus.addError('Error : One parent Question can have maximum '+ childQuestionLimit+' child questions per Option.Here the Parent Question Option '+key.split('_')[1] + ' already has '+ existingCount + ' child questions in System.You can associate '+questionsLeft+' more child questions only.');
                }
            }    
        }       
        
    }    
    
}