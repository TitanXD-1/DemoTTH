/**********************************************************************
Name: EDGE_SurveyQuestionListController
=======================================================================
Purpose: This is to handle EDGE_SurveyQuestionListCmp component
=======================================================================  
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -    Saurav Paul      05/04/2019      Initial Development
2.0     Sagar Barman      04/04/2010        ES20-6897
3.0     Sagar Barman      26/05/2020        ES20-7948
4.0     Sandip Ghosh      11/09/2020        ES20-8846
5.0     Sandip Ghosh      22/01/2021        US-0026148
6.0 	Juned Khan		  13/03/2021	    ES20-9823
***********************************************************************/
public with sharing class EDGE_SurveyQuestionListController {
    
    //Name : getSurveyName
    //Description : return Survey Name
    @AuraEnabled
    public static Survey__c getSurveyName(Id surveyId){
        //Added Schema.SObjectType.Survey__c.isAccessible() --by Divya
        if(surveyId != null && Schema.SObjectType.Survey__c.isAccessible() && Schema.SObjectType.RecordType.isAccessible()){
            List<Survey__c> lstSurvey = [SELECT Id,Name, RecordTypeId, RecordType.Name FROM Survey__c WHERE Id =:surveyId LIMIT 1];
            return lstSurvey[0];
        }else{
            return null;
        }
    }
    
    //Name : getSurveyQuestions
    //Description : return list of Survey Question related to a Survey
    
    @AuraEnabled
    public static List<Survey_Question__c> getSurveyQuestions(Id surveyId){
        system.debug('getSurveyQuestions');
        List<Survey_Question__c> surveyQuestionList = new List<Survey_Question__c>();
        if(surveyId != null  && Schema.SObjectType.Survey__c.isAccessible() && Schema.SObjectType.Survey_Question__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Id.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Answer_Option__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Active__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Mandatory__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Order_Number__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Question__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Response_Type__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Survey__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Grid_Survey__c.isAccessible()
           && Schema.sObjectType.Survey_Question__c.fields.Allow_Decimal_Response__c.isAccessible() //ES20-9823
          ){
              //Added for Guinness Survey Brand Survey - starts
              if(Schema.sObjectType.Survey_Question__c.fields.E7Cs_Criteria__c.isAccessible() 
                 && Schema.sObjectType.Survey_Question__c.fields.E7Cs_Category__c.isAccessible()
                 && Schema.sObjectType.Survey_Question__c.fields.E7Cs_Media__c.isAccessible()
                 && Schema.sObjectType.Survey_Question__c.fields.Expected_Response__c.isAccessible()
                 && Schema.sObjectType.Survey_Question__c.fields.E7Cs_Description__c.isAccessible())
              {
                  surveyQuestionList = [SELECT Id, Name,Answer_Option__c, Active__c, Mandatory__c, Image_Required__c,
                                        Order_Number__c, Question__c, Response_Type__c, Survey__c,Survey__r.RecordType.Name, Survey_KPI__c,
                                        Parent_Question__c,Parent_Question__r.Name,Parent_Answer_Option__c,Grid_Survey__c,Grid_Survey__r.Name,
                                        Allow_Decimal_Response__c,E7Cs_Description__c,E7Cs_Category__c,E7Cs_Media__c,Expected_Response__c,E7Cs_Criteria__c
                                        FROM Survey_Question__c 
                                        WHERE Survey__c =: surveyId 
                                        ORDER BY Order_Number__c NULLS LAST];
              }else{
                  //Added for Guinness Survey Brand Survey - ends
                  surveyQuestionList = [SELECT Id, Name,Answer_Option__c, Active__c, Mandatory__c, Image_Required__c,
                                        Order_Number__c, Question__c, Response_Type__c, Survey__c, Survey__r.RecordType.Name, Survey_KPI__c,
                                        Parent_Question__c,Parent_Question__r.Name,Parent_Answer_Option__c,Grid_Survey__c,Grid_Survey__r.Name,
                                        Allow_Decimal_Response__c //ES20-9823
                                        FROM Survey_Question__c   
                                        WHERE Survey__c =: surveyId 
                                        ORDER BY Order_Number__c NULLS LAST]; 
              }    //Added for Guinness Survey Brand Survey
          }
        return surveyQuestionList;
    }
    
    //Name : insertSurveyOptions
    //Description : insert list of Survey_Answer__c related to a Survey Question
    @AuraEnabled
    public static void insertSurveyOptions(Id surveyQstId,List<Survey_Answer__c> surveyAnrLst,Boolean isKPIEnable){
        List<Survey_Answer__c> surveyAnsrIsrtLst = new List<Survey_Answer__c>();
        for(Survey_Answer__c srvyAnsrObj : surveyAnrLst){
            if(String.isBlank(srvyAnsrObj.Id) && String.isBlank(srvyAnsrObj.GUID__c)){
                Blob aes = Crypto.generateAesKey(128);
                String guidVal = EncodingUtil.convertToHex(aes);
                srvyAnsrObj.GUID__c = guidVal;
                srvyAnsrObj.Survey_Question__c = surveyQstId;
            }
            
            if(!isKPIEnable){
                srvyAnsrObj.Bonus_Applicable_Response__c = false;
            }
            
            surveyAnsrIsrtLst.add(srvyAnsrObj);
        } 
        if(!surveyAnsrIsrtLst.isEmpty()){
            try{
                Database.upsert(surveyAnsrIsrtLst,Survey_Answer__c.Fields.GUID__c);
            }catch(Exception ex){
                System.debug('===Exception occurred ==='+ex.getCause());
                if((ex.getMessage()).containsIgnoreCase('STRING_TOO_LONG')){
                    throw new AuraHandledException(Label.Survey_Answer_Too_Long);
                } else {
                    throw new AuraHandledException(ex.getMessage());
                }                
            }
        }
    }
    //Name : getSurvyAnsr
    //Description : used to fetch Survey_Answer for a specific Survey Qstn 
    @AuraEnabled
    public static List<Survey_Answer__c> getSurvyAnsr(Id survyQstnId){
        List<Survey_Answer__c> surveyAnsrLst = new List<Survey_Answer__c>();
        if(Schema.SObjectType.Survey__c.isAccessible() && Schema.SObjectType.Survey_Question__c.isAccessible() 
           && Schema.SObjectType.Survey_Answer__c.isAccessible()
           && Schema.sObjectType.Survey_Answer__c.fields.Id.isAccessible()
           && Schema.sObjectType.Survey_Answer__c.fields.GUID__c.isAccessible()
           && Schema.sObjectType.Survey_Answer__c.fields.Survey_Question__c.isAccessible()
           && Schema.sObjectType.Survey_Answer__c.fields.Option_Value__c.isAccessible())
        {
            surveyAnsrLst = [SELECT Id,GUID__c,Survey_Question__c,Option_Value__c, Bonus_Applicable_Response__c 
                             FROM Survey_Answer__c 
                             WHERE Survey_Question__c =:survyQstnId ];
        }
        return surveyAnsrLst;
    }
    
    @AuraEnabled
    public static List<SurveyQuestionWrapper> getConditionalSurveyQuestion(Id surveyId,Id parentQuestionId){
        
        List<SurveyQuestionWrapper> surveyQuestionWrapperList = new List<SurveyQuestionWrapper>();
        for(Survey_Question__c question : [SELECT Id, Answer_Option__c, Active__c, Mandatory__c, Image_Required__c,
                                           Order_Number__c, Question__c, Response_Type__c, Survey__c, Survey__r.RecordType.Name,
                                           Survey_KPI__c,Grid_Survey__c,Allow_Decimal_Response__c //ES20-9823
                                           FROM Survey_Question__c 
                                           WHERE Survey__c =:surveyId AND Active__c = true AND Parent_Question__c = null 
                                           AND isParent__c = false AND ID !=: parentQuestionId
                                           ORDER BY Order_Number__c NULLS LAST])
        {
            SurveyQuestionWrapper surveyQuestionWrapper = new SurveyQuestionWrapper();
            surveyQuestionWrapper.isSelected = false;
            surveyQuestionWrapper.questionId = question.Id;
            surveyQuestionWrapper.questionName = question.Question__c;
            surveyQuestionWrapper.questionType = question.Response_Type__c;
            
            surveyQuestionWrapperList.add(surveyQuestionWrapper);
        }
        return surveyQuestionWrapperList;
    }
    
    public class SurveyQuestionWrapper {
        @AuraEnabled public boolean isSelected {get;set;}
        @AuraEnabled public string questionId {get;set;}
        @AuraEnabled public string questionName {get;set;}
        @AuraEnabled public string questionType {get;set;}
    }
    
    @AuraEnabled
    public static void saveChildQuestion(List<Survey_Question__c> surveyQuestionList,String parentQuestionId){
        if(surveyQuestionList.size()>0){            
            update surveyQuestionList;
            //update the parent Question
            //Added Schema.sObjectType.Survey_Question__c.isUpdateable() --by Divya
            if(parentQuestionId != null && parentQuestionId != '' && Schema.sObjectType.Survey_Question__c.isUpdateable()){
                Survey_Question__c parentSQ = new Survey_Question__c(Id=parentQuestionId); 
                parentSQ.isParent__c = true;
                update parentSQ;    
            } 
        }           
    }  
    // Added for ES20-8846
    @AuraEnabled
    public static boolean checkImageRequiredForGridSurvey(Id surveyId,String gridSurveyId, String currentSrvyQsId){//Id gridSurveyId, Id currentSrvyQsId -- US-0026148 : Changed the parameter type
        boolean imageChecked = false;
        //System.debug('1. imageChecked = '+ imageChecked);
        string gridSurveyRecTypeId = Survey__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Grid Survey').getRecordTypeId();
        
        System.debug('gridSurveyId = '+ gridSurveyId);
        System.debug('currentSrvyQsId = '+ currentSrvyQsId);
        if(gridSurveyId != null){
            for(Survey_Question__c surveyques : [SELECT Id,Image_Required__c,Active__c, Survey__c, Survey__r.RecordTypeId 
                                                 FROM Survey_Question__c 
                                                 WHERE Survey__c =:surveyId AND Active__c = true AND Survey__r.RecordTypeId =:gridSurveyRecTypeId AND Grid_Survey__c =:gridSurveyId
                                                 AND Id <> :currentSrvyQsId])
            {
                if(surveyques.Image_Required__c){
                    imageChecked = true;
                    break;
                }
            }
        }
        system.debug('imageChecked= '+ imageChecked);
        return imageChecked;
    }
    
}