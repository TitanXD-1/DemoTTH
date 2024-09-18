public without sharing class E7C_SurveyArchiveDetailController {
    
    /*@AuraEnabled
public static List<E7C_Survey_Response__c> getSurveyResponseDetails1(String srId){
List<E7C_Survey_Response__c> list1 = [SELECT Id, E7C_Outlet_Name__c, E7C_Outlet_Geometry__c, E7C_Outlet_Geometry__Latitude__s, E7C_Outlet_Geometry__Longitude__s, E7C_Survey_Response_Date__c
FROM E7C_Survey_Response__c WHERE Id =: srId];

System.debug(list1[0]);

return list1;
}*/
    
    
    @AuraEnabled
    public static wrapperClass getSurveyResponseDetails(String srId){
        wrapperClass wrapperClassVar = new wrapperClass();
        
        E7C_Survey_Response__c srRec = [SELECT Id, E7C_Outlet_Name__c, E7C_Outlet_Address__c,
                                        E7C_Outlet_Geometry__c, E7C_Outlet_Geometry__Latitude__s, E7C_Outlet_Geometry__Longitude__s, 
                                        E7C_Survey_Response_Date__c, Survey__c, E7C_Notes__c
                                        FROM E7C_Survey_Response__c WHERE Id =: srId];
        
        if(srRec != null){
            wrapperClassVar.outletname = srRec.E7C_Outlet_Name__c;
            wrapperClassVar.outletAddress = srRec.E7C_Outlet_Address__c;
            wrapperClassVar.outletLatitude = String.valueOf(srRec.E7C_Outlet_Geometry__Latitude__s);
            wrapperClassVar.outletLongitude = String.valueOf(srRec.E7C_Outlet_Geometry__Longitude__s);
            wrapperClassVar.day = String.valueOf(srRec.E7C_Survey_Response_Date__c.day());
            wrapperClassVar.month = String.valueOf(srRec.E7C_Survey_Response_Date__c.format('MMMMM'));
            wrapperClassVar.year = String.valueOf(srRec.E7C_Survey_Response_Date__c.year());
            wrapperClassVar.formattedTime = String.valueOf(srRec.E7C_Survey_Response_Date__c.format('h:mm a'));
            
            wrapperClassVar.surveyId = String.valueOf(srRec.Survey__c);
            wrapperClassVar.surveyResNotes = String.valueOf(srRec.E7C_Notes__c);
            
            
            List<ContentDocumentLink> cdls = [SELECT ContentDocumentId, LinkedEntityId 
                                              FROM ContentDocumentLink WHERE LinkedEntityId = :srId];
            if(cdls.size() > 0){
                wrapperClassVar.attachmentId = cdls[0].ContentDocumentId;
                
                try{
                    wrapperClassVar.attachmentId2 = cdls[1].ContentDocumentId;
                }catch(Exception e){
                    wrapperClassVar.attachmentId2 = '';
                }
                
                //wrapperClassVar.attachmentId2 = cdls.size() > 1 ? cdls[1].ContentDocumentId : '';
            }
            
            
            return wrapperClassVar;
        }else{
            return null;   
        }
    }
    
    @AuraEnabled
    public static void updateConVersion(String docId, String pintType){
        try{
            contentVersion conVer = [SELECT Id, E7C_Pint_Type__c FROM ContentVersion 
                                     WHERE ContentDocumentId = :docId];
            conVer.E7C_Pint_Type__c = pintType;
            System.debug('conVer>>>'+conVer);
            update conVer;
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());            
        }
    }
    
    @AuraEnabled
    public static Map<Id,Survey_Question__c> getquestionMap(String surveyId)
    {
        
        try{
            String datevalue;
            Map<Id,Survey_Question__c> questionMap = new Map<Id,Survey_Question__c>();
            List<Survey_Question__c> questionList= new List<Survey_Question__c>();
            questionList= [SELECT Id,Question__c, E7Cs_Category__c,E7Cs_Criteria__c,Response_Type__c,
                           Order_Number__c ,Parent_Question__c ,Expected_Response__c, E7Cs_Description__c, Survey__c 
                           FROM Survey_Question__c 
                           where Order_Number__c!=null ORDER BY Order_Number__c ASC];
            for(Survey_Question__c obj : questionList)
            {
                questionMap.put(obj.Id, obj);
                system.debug('queMap'+questionMap);
                
            }
            
            return questionMap;
        }catch(exception ex){
            system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
            return null;
        }
        
        
        
    }
    @AuraEnabled
    public static questionWrapper getChosenAnswers(String srId)
    {
        try{
            Map<Id,String> responseMap = new Map<Id,String>();
            Datetime responsetime;
            List<E7C_Survey_Question_Response__c> responseList= new List<E7C_Survey_Question_Response__c>();
            responseList= [SELECT id ,E7C_Question__c,E7C_Answer__c,LastModifiedDate, E7C_Survey_Response__c
                           FROM E7C_Survey_Question_Response__c 
                           where E7C_Survey_Response__c =: srId AND E7C_Question__r.Order_Number__c!=null
                           ORDER BY E7C_Question__r.E7Cs_Criteria__c];
            for(E7C_Survey_Question_Response__c obj : responseList)
            {
                responseMap.put(obj.E7C_Question__c, obj.E7C_Answer__c);
                responsetime=obj.LastModifiedDate;
                system.debug('queMap'+responseMap);
            }
            questionWrapper c= new questionWrapper(responsetime,responseMap);
            system.debug('c val'+c);
            return c;
        }catch(exception ex){
            system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
            return null;
        }
    }
    
    public class questionWrapper{
        @AuraEnabled
        public Datetime dateVal;
        @AuraEnabled
        public Map<Id,String> questionMap;
        public questionWrapper(Datetime x1,Map<Id,String> questionmapVal){
            this.dateVal=x1;
            this.questionMap=questionmapVal;
        }
    }
    
    public class wrapperClass{
        @AuraEnabled public String outletname{get; set;}
        @AuraEnabled public String outletAddress{get; set;}
        @AuraEnabled public String outletLatitude{get; set;}
        @AuraEnabled public String outletLongitude{get; set;}
        
        @AuraEnabled public String day {get; set;}
        @AuraEnabled public String month {get; set;}
        @AuraEnabled public String year {get; set;}
        @AuraEnabled public String formattedTime {get; set;}
        
        @AuraEnabled public String surveyId {get; set;}
        @AuraEnabled public String surveyResNotes {get; set;}
        
        @AuraEnabled public String attachmentId {get; set;}        
        @AuraEnabled public String attachmentId2 {get; set;}        
    }
    
}