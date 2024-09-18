global without sharing class E7C_SurveyQuestionController {
    List<questionWrapper> qwrap= new List<questionWrapper>();
    
    /*//Deprecated
@AuraEnabled
global static Map<Integer,E7C_Survey_Question__c> fetchSurveyQuestions(String location)
{

try{

String surveyId = E7C_Utility.getSurveyId(location);

Map<Integer,E7C_Survey_Question__c> surveyQuestionMap = new Map<Integer,E7C_Survey_Question__c>();
List<E7C_Survey_Question__c> surveyQuestionList= new List<E7C_Survey_Question__c>();
surveyQuestionList= [SELECT Id,E7C_Question__c,E7C_Media__r.E7C_Description__c ,E7C_Media__r.E7C_Youtube_URL__c, E7C_Question_Category__c,
E7C_Question_Priority__c,E7C_Response_Type__c,Sequence__c ,Survey_Question__c ,Expected_Response__c ,
(SELECT Id,E7C_Option_Value__c, E7C_Answer_Type__c from E7C_Survey_Answers__r), (SELECT Id from Survey_Question__r LIMIT 1)
FROM E7C_Survey_Question__c where Sequence__c!=null AND E7C_Survey__c =: surveyId
ORDER BY Sequence__c ASC];
for(E7C_Survey_Question__c obj : surveyQuestionList)
{
surveyQuestionMap.put(Integer.valueOf(obj.Sequence__c), obj);
system.debug('ert'+surveyQuestionMap);
}

return surveyQuestionMap;
}catch(exception ex){
system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
return null;
}



}

//Deprecated
@AuraEnabled
global static E7C_Survey_Question__c fetchParentQuestion(Id parentId)
{
try{
E7C_Survey_Question__c parentQue=new E7C_Survey_Question__c();
if(parentId!=null){
parentQue= [SELECT Id,E7C_Question__c,E7C_Media__r.E7C_Description__c , E7C_Question_Category__c,E7C_Question_Priority__c,
E7C_Response_Type__c,Sequence__c ,Survey_Question__c ,
(SELECT Id,E7C_Option_Value__c, E7C_Answer_Type__c from E7C_Survey_Answers__r)
FROM E7C_Survey_Question__c where Id= :parentId LIMIT 1];
}
return parentQue;
} catch(Exception ex){
system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
return null;
}       
}*/
    
    //new method-used in sur question
    @AuraEnabled
    global static Survey_Question__c getParentQuestion(Id recId)
    {
        try{
            Survey_Question__c childQues = new Survey_Question__c();
            if(recId!=null){
                childQues= [SELECT Id,Question__c,E7Cs_Media__r.E7C_Description__c , E7Cs_Criteria__c,E7Cs_Category__c,
                            Response_Type__c,Order_Number__c ,Answer_Option__c, Parent_Question__c
                            FROM Survey_Question__c where Id= :recId AND Parent_Question__c != '' LIMIT 1];
            }
            return childQues;
        } catch(Exception ex){
            system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
            return null;
        }       
    }
    
    
    //used in sur result
    @AuraEnabled
    global static Map<Id, Survey_Question__c> getquestionMap()
    {
        
        try{
            String datevalue;
            Map<Id,Survey_Question__c> questionMap = new Map<Id,Survey_Question__c>();
            List<Survey_Question__c> questionList= new List<Survey_Question__c>();
            questionList= [SELECT Id,Question__c, E7Cs_Category__c,E7Cs_Criteria__c, Response_Type__c, Order_Number__c,
                           Parent_Question__c, Expected_Response__c, E7Cs_Description__c 
                           FROM Survey_Question__c 
                           where Order_Number__c !=null and Survey__r.RecordType.name ='Guinness Brand Survey' ORDER BY Order_Number__c ASC];
            
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
    
    //used in sur result
    @AuraEnabled
    public static questionWrapper getChosenAnswers(String surResponseId)
    {
        try{
            Map<Id,String> responseMap = new Map<Id,String>();
            Datetime responsetime;
            String outletName;
            Boolean submitted = false;
            Boolean reported = false;
            List<E7C_Survey_Question_Response__c> responseList= new List<E7C_Survey_Question_Response__c>();
            responseList= [SELECT id ,E7C_Question__c,E7C_Answer__c,LastModifiedDate, E7C_Survey_Response__c, E7C_Survey_Response__r.E7C_Outlet_Name__c, E7C_Question__r.E7Cs_Description__c, E7C_Survey_Response__r.E7C_Status__c, E7C_Survey_Response__r.E7C_Reported__c
                           FROM E7C_Survey_Question_Response__c where E7C_Survey_Response__c = :surResponseId AND E7C_Question__r.Order_Number__c!=null ORDER BY E7C_Question__r.E7Cs_Criteria__c];
            for(E7C_Survey_Question_Response__c obj : responseList)
            {
                responseMap.put(obj.E7C_Question__c, obj.E7C_Answer__c);
                responsetime=obj.LastModifiedDate;
                outletName = obj.E7C_Survey_Response__r.E7C_Outlet_Name__c;
                if(obj.E7C_Survey_Response__r.E7C_Status__c == 'Submitted'){
                    submitted = true;
                }
                reported = obj.E7C_Survey_Response__r.E7C_Reported__c;
                system.debug('queMap'+responseMap);
            }
            questionWrapper c= new questionWrapper(responsetime,responseMap, outletName,submitted, reported);
            system.debug('c val'+c);
            return c;
        }catch(exception ex){
            system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
            return null;
        }
        
        
        
    }
    
    //used in sur question
    @AuraEnabled
    global static void saveResponsesCaptured(List<E7C_Survey_Question_Response__c> mapofResponses, String surveyReponseId)
    {
        try{
            system.debug('insode saveReponsesCaptured'+mapofResponses);
            List<Id> questlistids= new List<Id>();
            List<E7C_Survey_Response__c> surveyResp= new List<E7C_Survey_Response__c>();
            List<E7C_Survey_Question_Response__c> responseList= new List<E7C_Survey_Question_Response__c>();
            if(mapofResponses!=null){
                for(integer i=0;i<mapofResponses.size();i++){
                    E7C_Survey_Question_Response__c sqResponse = new E7C_Survey_Question_Response__c();
                    //E7C_Survey_Question_Response__c rec=(E7C_Survey_Question_Response__c)mapofResponses.get(idKey);
                    sqResponse.E7C_Question__c = mapofResponses[i].E7C_Question__c;
                    questlistids.add(mapofResponses[i].E7C_Question__c);
                    system.debug('map record'+mapofResponses[i]);
                    sqResponse.E7C_Answer__c = mapofResponses[i].E7C_Answer__c;
                    sqResponse.E7C_Survey_Response__c = surveyReponseId;  
                    responseList.add(sqResponse);
                }
            }
            system.debug('list record'+responseList);
            system.debug('map record'+mapofResponses);
            if(!questlistids.isEmpty()){
                list<E7C_Survey_Question_Response__c> cw= [select id from E7C_Survey_Question_Response__c where E7C_Survey_Response__c = :surveyReponseId];
                if(!cw.isEmpty())
                    delete cw;
            }
            Map<Id,Survey_Question__c> questionMap= new Map<Id,Survey_Question__c>([SELECT Id, Expected_Response__c FROM Survey_Question__c WHERE Id IN :questlistids]);
            E7C_Survey_Response__c surRes;
            if(questionMap!=null){
                for(integer i=0;i<mapofResponses.size();i++){
                    System.debug('Has Question:: '+questionMap.containsKey(mapofResponses[i].E7C_Question__c));
                    System.debug('Given answer:: '+mapofResponses[i].E7C_Answer__c);
                    System.debug('Exp answer:: '+questionMap.get(mapofResponses[i].E7C_Question__c).Expected_Response__c);
                    //if(questionMap.containsKey(mapofResponses[i].E7C_Question__c) && mapofResponses[i].E7C_Answer__c != questionMap.get(mapofResponses[i].E7C_Question__c).Expected_Response__c){
                    if(questionMap.containsKey(mapofResponses[i].E7C_Question__c) 
                       && (!questionMap.get(mapofResponses[i].E7C_Question__c).Expected_Response__c.split(';').contains(mapofResponses[i].E7C_Answer__c))){
                           surRes = new E7C_Survey_Response__c();
                           surRes.Id = surveyReponseId;
                           surRes.E7C_Survey_Result__c = 'Fail';
                           break;
                       }else{
                           surRes = new E7C_Survey_Response__c();
                           surRes.Id = surveyReponseId;
                           surRes.E7C_Survey_Result__c = 'Pass';
                           
                       }
                }
            }
            if(!responseList.isEmpty()) {
                insert responseList;  
            }   
            
            if(surveyReponseId!=''){
                E7C_Survey_Response__c comSurvey=new E7C_Survey_Response__c();
                comSurvey.Id = surveyReponseId;
                comSurvey.E7C_Status__c='Completed';
                update comSurvey;
            }
            
            if(surRes != null && surRes.Id != null){
                update surRes;
            }
        } catch(Exception ex){
            system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
            System.debug('Exception>>>'+ex.getStackTraceString());
            
        }       
    }
    
    //used in both
    @AuraEnabled
    public static Id getSurveyResId(String location){
        try{
            System.debug('UserInfo>>>'+UserInfo.getUserId());
            Id srId = E7C_Utility.getSurveyId(location);
            Id surResId = E7C_Utility.getSurveyResponseId(srId);
            return surResId;
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());
            return null;
        }
    }	
    
    //used in sur ques
    @AuraEnabled
    public static void submitSurveytoServer(String notes, String locationVal){
        try{
            List<E7C_Survey_Response__c> surveyResp= new List<E7C_Survey_Response__c>();
            System.debug('UserInfo>>>'+UserInfo.getUserId());
            Id srId = E7C_Utility.getSurveyId(locationVal);
            Id surResId = E7C_Utility.getCompletedSurveyResponseId(srId);
            System.debug('surResId>>>'+surResId);
            if(surResId!=null){
                E7C_Survey_Response__c surRes= new E7C_Survey_Response__c();
                surRes.Id = surResId;
                surRes.E7C_Status__c='Submitted';
                surRes.E7C_Notes__c=notes!=''?notes:'';
                update surRes;
            }
        }catch(Exception e){
            System.debug('Exception>>>'+e.getStackTraceString());
        }
    }
    
    //used in sur result
    @AuraEnabled
    public static void sendReportEmail(String location, String needImprovementRes, String surveyResponseId){
        try{
            String toAddress;
            System.debug('location>>> '+location);
            System.debug('needImprovementRes>>> '+needImprovementRes);
            System.debug('surveyResponseId>>> '+surveyResponseId);
            List<NeedImproveSurvey> surResImp = (List<NeedImproveSurvey>) JSON.deserialize(needImprovementRes, List<NeedImproveSurvey>.class);
            System.debug('surResImp>>> '+surResImp);
            E7C_Survey_Response__c surRes = [SELECT E7C_Survey_Outlet__c, E7C_Reported__c,E7C_Notes__c FROM E7C_Survey_Response__c WHERE Id= :surveyResponseId];
            String surveyOutlet = surRes.E7C_Survey_Outlet__c;
            String outletName =  surveyOutlet.substringBefore(','); 
            String outletAddress = surveyOutlet.substringAfter(',');
            String surveyNotes = surRes.E7C_Notes__c;
            if(location == 'Ireland'){
                toAddress = Label.E7C_IrelandEmailAddress;
            }else if(location == 'Great Britain'){
                toAddress = Label.E7C_UKEmailAddress;
            }
            Set<Id> cdIds = new Set<Id>();
            ContentDocumentLink[] cdls = [SELECT ContentDocumentId 
                                          FROM ContentDocumentLink 
                                          WHERE LinkedEntityId = :surveyResponseId];
            System.debug('cdls>>> '+cdls);
            for(ContentDocumentLink cdl : cdls)
                cdIds.add(cdl.ContentDocumentId);
            ContentVersion[] cvs = [SELECT Id, E7C_Pint_Type__c 
                                    FROM ContentVersion
                                    WHERE ContentDocumentId IN :cdIds];
            System.debug('cvs>>> '+cvs);
            String fullPintImageAdd;
            String empPintImageAdd;
            String baseUrl = System.Url.getOrgDomainUrl().toExternalForm();
            for(ContentVersion cv : cvs){
                if(cv.E7C_Pint_Type__c == 'Full'){
                    fullPintImageAdd = baseUrl+'/sfc/servlet.shepherd/version/download/'+cv.Id;
                }else if(cv.E7C_Pint_Type__c == 'Empty'){
                    empPintImageAdd = baseUrl+'/sfc/servlet.shepherd/version/download/'+cv.Id;
                }
            }
            List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
            Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
            List<String> sendTo = new List<String>();
            sendTo.add(toAddress);
            mail.setToAddresses(sendTo);
            mail.setSenderDisplayName('noreply@guinness.com');
            mail.setSubject('Emergency Quality Assessment');
            String body = '<html>';
            body += '<head>';
            body += '<meta http-equiv="Content-Type" content="text/html; charset=us-ascii">';
            body += '</head>';
            body += '<body>';
            body += '<p>Hi,</p>';
            body += '<p>The quality of the Guinness Draught at <em>'+ outletName +'</em> in <em>' +outletAddress+ '</em> is not quite where it should be. They might need some help to ensure they are always serving the perfect pint. These are the criteria that the outlet';
            body += ' failed on:</p>';
            body += '<p></p>';
            body += '<ul>';
            for(NeedImproveSurvey ns: surResImp){
                for(Activities a : ns.activities){
                    body += '<li>'+ns.priority.toLowerCase()+ ' - ';
                    body += a.category+': '+a.question+ ',</li>';
                }
            }
            body += '</ul><p></p>';
            body += '<p>Full Pint Image: <a href="'+fullPintImageAdd+'">';
            body += fullPintImageAdd+'</a></p>';
            if(empPintImageAdd != null){
                body += '<p>Empty Pint Image: <a href="'+empPintImageAdd+'">'+empPintImageAdd+'</a></p>';
            }else{
                body += '<p>Empty Pint Image: <a href="#">#</a></p>';
            }
            body += '<p>Additional notes: '+surveyNotes+'<br>';
            body += '<em></em></p>';
            body += '<p>Thanks</p>';
            body += '<p>The Guinness 7Cs team</p>';
            body += '<hr>';
            body += 'This email and any files transmitted with it are confidential and intended solely for the use of the individual or entity to which they are addressed. If you have received this email in error please notify the Global Diageo Service Desk on +44 (0) 203 684 9280.';
            body += 'For Diageo India, please contact - 1800 3000 1197 <br>';
            body += '<br>';
            body += 'This footnote also confirms that this email has been scanned for all viruses by the Proofpoint Email Security service.';
            body += '<br>';
            body += '<br>';
            body += 'http://www.diageo.com<br>';
            body += '</body>';
            body += '</html>';
            mail.setHtmlBody(body);
            mails.add(mail);
            Messaging.sendEmail(mails);
            surRes.E7C_Reported__c = true;
            Update surRes;
        }
        catch(Exception ex){
            system.debug('getline number'+ex.getLineNumber()+'getmessage '+ex.getMessage());
            System.debug('Exception>>>'+ex.getStackTraceString());
            
        }
    }
    
    //used in sur ques
    @AuraEnabled
    global static Map<Integer,Survey_Question__c> getSurveyQuestions(String location)
    {
        
        try{
            
            String surveyId = E7C_Utility.getSurveyId(location);
            
            Map<Integer,Survey_Question__c> surveyQuestionMap = new Map<Integer,Survey_Question__c>();
            List<Survey_Question__c> surveyQuestionList= new List<Survey_Question__c>();
            surveyQuestionList= [SELECT Id,Question__c,E7Cs_Media__r.E7C_Description__c ,E7Cs_Media__r.E7C_Youtube_URL__c, E7Cs_Category__c,
                                 E7Cs_Criteria__c,Response_Type__c,Order_Number__c ,Survey__c ,Expected_Response__c ,
                                 Answer_Option__c, (SELECT Id from Survey_Questions__r LIMIT 1)
                                 FROM Survey_Question__c where Order_Number__c!=null AND Survey__c =: surveyId AND Survey__r.RecordType.DeveloperName = 'Guinness_Brand_Survey'
                                 AND Parent_Question__c = ''
                                 ORDER BY Order_Number__c ASC];
            
            Integer seq = 1;
            for(Survey_Question__c obj : surveyQuestionList)
            {
                surveyQuestionMap.put(seq, obj);
                seq++;
                system.debug('ert'+surveyQuestionMap);
            }
            
            return surveyQuestionMap;
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
        
        @AuraEnabled
        public String outlet;
        
        @AuraEnabled
        public Boolean submitted;
        
        @AuraEnabled
        public Boolean reported;
        
        public questionWrapper(Datetime x1,Map<Id,String> questionmapVal, String outletName, Boolean submitted, Boolean reported){
            this.dateVal=x1;
            this.questionMap=questionmapVal;
            this.outlet = outletName;
            this.submitted = submitted;
            this.reported = reported;
        }
    }
    
    public class NeedImproveSurvey{
        public Activities[] activities;
        public string priority;
        
    }
    
    public class Activities{
        public String category;
        public String question;
    }
    
}