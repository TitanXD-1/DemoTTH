/**********************************************************************
  Name: EDGE_SurveyAnswerTriggerHelper
=======================================================================
  Purpose: This is to handle Survey Answer Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Saurav Paul      05/04/2019      Initial Development
***********************************************************************/
public with sharing class EDGE_SurveyAnswerTriggerHelper {
	//Name : addOptionsVal
	//Description  : This will roll-up Option value from Survey_Answers to Survey_Question in Answer_Option__c field
    public static void addOptionsVal(Boolean isUpdate, List<SObject> newList, Map<Id,SObject> oldMap){
    	Set<Id> surVeyQstnIdSet = new Set<Id>(); 
    	List<Survey_Question__c> surVeyQstnLst = new List<Survey_Question__c>();
    	List<Survey_Question__c> surveyqstnUpdateLst = new List<Survey_Question__c>(); 
    	for(SObject sObj : newList){
    		Survey_Answer__c surveyAnsr = (Survey_Answer__c)sObj;
    		if(isUpdate && oldMap!= null && oldMap.containsKey(surveyAnsr.Id)){
    			Survey_Answer__c surveyAnsrOld = (Survey_Answer__c)oldMap.get(surveyAnsr.Id);
    			if(String.isNotBlank(surveyAnsr.Survey_Question__c) && surveyAnsrOld.Option_Value__c != surveyAnsr.Option_Value__c){
    				surVeyQstnIdSet.add(surveyAnsr.Survey_Question__c);
    			}
    			
    		}else if(!isUpdate && String.isNotBlank(surveyAnsr.Survey_Question__c)){
    			surVeyQstnIdSet.add(surveyAnsr.Survey_Question__c);
    		}
    	}
        
    	if(!surVeyQstnIdSet.isEmpty()){
            if(Schema.SObjectType.Survey__c.isAccessible() && Schema.SObjectType.Survey_Question__c.isAccessible() 
               && Schema.SObjectType.Survey_Answer__c.isAccessible()
               && Schema.sObjectType.Survey__c.fields.Name.isAccessible()
               && Schema.sObjectType.Survey_Question__c.fields.Name.isAccessible()
               && Schema.sObjectType.Survey_Answer__c.fields.Name.isAccessible()
               && Schema.sObjectType.Survey_Question__c.fields.Answer_Option__c.isAccessible()
               && Schema.sObjectType.Survey_Question__c.fields.Id.isAccessible()
               && Schema.sObjectType.Survey_Question__c.fields.Response_Type__c.isAccessible()
               && Schema.sObjectType.Survey_Answer__c.fields.Id.isAccessible()
               && Schema.sObjectType.Survey_Answer__c.fields.Option_Value__c.isAccessible()
              ){
            	surVeyQstnLst = [SELECT Answer_Option__c,Id,Response_Type__c,
    								(SELECT Id,Option_Value__c FROM Survey_Answers__r) 
    							FROM Survey_Question__c
    						 	WHERE Id IN :surVeyQstnIdSet];
            }
    		if(!surVeyQstnLst.isEmpty()){
    			for(Survey_Question__c qstnObj : surVeyQstnLst){
    				if(qstnObj.Response_Type__c.equals('CheckBox') || qstnObj.Response_Type__c.equals('RadioButton') ||
    					qstnObj.Response_Type__c.equals('Picklist') || qstnObj.Response_Type__c.equals('Multi Select Picklist')){
    					String optnVal = '';
	    				for(Survey_Answer__c ansrObj : qstnObj.Survey_Answers__r){
	    					optnVal = optnVal + ansrObj.Option_Value__c+ ';';
	    				}
	    				optnVal = optnVal.removeEnd(';');
	    				qstnObj.Answer_Option__c = optnVal;
	    				surveyqstnUpdateLst.add(qstnObj);
    				}
    			}
    		}
    	}
    	if(!surveyqstnUpdateLst.isEmpty() ){
            if(Schema.SObjectType.Survey__c.isAccessible() && Schema.SObjectType.Survey_Question__c.isAccessible() 
               && Schema.SObjectType.Survey_Question__c.isUpdateable()
               && Schema.sObjectType.Survey_Question__c.fields.Answer_Option__c.isUpdateable()){
                update surveyqstnUpdateLst;
            }
    	}
    }
    
    
}