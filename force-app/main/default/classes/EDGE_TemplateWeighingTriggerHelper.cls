/**********************************************************************
Name: EDGE_TemplateWeighingTriggerHelper
=======================================================================
Req: This 
User Story : ES20-1324 - To chck if any duplicate Template Weighing record present in the system 
             with the combination of Country Opportunity_Template and Sub_Segment.
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Saurav Paul      17/05/2019       US : ES20-1324
***********************************************************************/
public with sharing class EDGE_TemplateWeighingTriggerHelper {
    /*******************************************************************    
    Purpose: Check for Duplicate Template Weighing Records 
    ********************************************************************/
    public static void validateDuplicateRecord(List<Template_Weighing__c> temWeighList,Boolean isUpdate, Map<Id,sObject> oldMap){
        //Variables
        Map<Id,Template_Weighing__c> tempWeighOldMap;
        Set<Id> oppTempIdSet = new Set<Id>();
        Set<Id> countryIdSet = new Set<Id>();
        Set<String> subSegmentSet = new Set<String>();
        List<Template_Weighing__c> oldtempWeighList = new List<Template_Weighing__c>();
        Map<String,Template_Weighing__c> oldtempWeighMap = new Map<String,Template_Weighing__c>();
        Map<Id,Template_Weighing__c> oldtemplWeigMap;
        //Variables
        if(oldMap!= null){
            oldtemplWeigMap = (Map<Id,Template_Weighing__c>)oldMap;
        }
        for(Template_Weighing__c tempWeigObj : temWeighList){
            if((isUpdate && oldtemplWeigMap!= null && oldtemplWeigMap.containsKey(tempWeigObj.Id) && (oldtemplWeigMap.get(tempWeigObj.Id).Opportunity_Template__c != tempWeigObj.Opportunity_Template__c ||
               oldtemplWeigMap.get(tempWeigObj.Id).Country__c != tempWeigObj.Country__c||
               oldtemplWeigMap.get(tempWeigObj.Id).Sub_Segment__c != tempWeigObj.Sub_Segment__c)) || !isUpdate){
                oppTempIdSet.add(tempWeigObj.Opportunity_Template__c);
            	countryIdSet.add(tempWeigObj.Country__c);
            	subSegmentSet.add(tempWeigObj.Sub_Segment__c);       
        	}
        }
        //fetching old records
        if(Schema.sObjectType.Template_Weighing__c.isAccessible() && !oppTempIdSet.isEmpty()){
            oldtempWeighList = [SELECT Id,Opportunity_Template__c,Country__c,Sub_Segment__c 
                                FROM Template_Weighing__c 
                                WHERE Opportunity_Template__c IN :oppTempIdSet
                                AND Country__c IN :countryIdSet
                                AND Sub_Segment__c IN :subSegmentSet];
            if(!oldtempWeighList.isEmpty()){
                for(Template_Weighing__c tempWeObj : oldtempWeighList){
                    String cmpKey = String.valueOf(tempWeObj.Country__c)+String.valueOf(tempWeObj.Opportunity_Template__c)+tempWeObj.Sub_Segment__c;
                    oldtempWeighMap.put(cmpKey,tempWeObj);
                }
            }
        }
        for(Template_Weighing__c tempWeigObj : temWeighList){
            String cmpKey = String.valueOf(tempWeigObj.Country__c)+String.valueOf(tempWeigObj.Opportunity_Template__c)+tempWeigObj.Sub_Segment__c;
            if(oldtempWeighMap!= null && !oldtempWeighMap.isEmpty() && oldtempWeighMap.containsKey(cmpKey)){
               tempWeigObj.addError(Label.Duplicate_Template_Weighing_Error) ;
            }
        }
    }
}