/**

* @description :  EDGE_CaseCommentIntegrationWithSNOW

* @history :

* Version   Developer      Date       User Story	  Purpose
* 1.0       Prasanth T   08/02/2021   ES20-9673      Class to send the Sysid and Comment for every caseComment created to Service Now.
* 1.1     	Shivam Chauhan    	18/10/2023      146993			Migrating Authentication Mechanism to oAuth 2.0_SFDC_Tech Debt
*/
public with sharing class EDGE_CaseCommentIntegrationWithSNOW implements Queueable,Database.AllowsCallouts{
    public static final String EDGE_MULESOFT_COMMENT = 'Edge_Mulesoft_Comment_Creation';//146993
    
    //public static final String ENDPOINT = system.Label.EDGE_Case_Comment_End_Point;
    //public static final String CLIENTID = system.Label.Service_Now_Client_Id ;
    //public static final String CLIENTSECRET = system.Label.Service_Now_Client_Secret;
    public static final String DEFAULTCONTACTLANGUAGE = 'en';
    public static final String TOTALALLOWEDCALLOUTSSTR = system.Label.EDGE_Case_Comment_Total_Allowed_Callouts ;
    public static final String SYSIDLABEL = 'sys_id';
    public static final String COMMENTBODYLABEL = 'comments';
    Map<Id,List<String>>  sysIdCommentMap = new Map<Id,List<String>> ();
    Map<Id,String> caseCommentJsonStringMap = new Map<Id,String>();
    Map<Id,Map<Id, String>> caseIdConVersionIdMap = new Map<Id,Map<Id, String>>();
    List<Id> caseCommentNotProcessed = new List<Id>();
    boolean attachmentPresent;
    
    public EDGE_CaseCommentIntegrationWithSNOW (Map<Id,List<String>>  newItems,Map<Id,Map<Id, String>> caseIdConVersionIdMap, boolean attachmentPresent){
        this.sysIdCommentMap = newItems;
        this.caseIdConVersionIdMap = caseIdConVersionIdMap;
        this.attachmentPresent = attachmentPresent;
    }
    public void execute(QueueableContext bc){
        //Map<Id,List<String>> caseCommentReturnedMap = new Map<Id,List<String>>();
        Integer totalCallOutsPerformed = 0;
        Integer totalAllowedCallOuts = Integer.valueOf(TOTALALLOWEDCALLOUTSSTR);
        string request = '';
        string response = '';
        if(sysIdCommentMap!= null && sysIdCommentMap.size()>0){
            caseCommentJsonStringMap = fetchCaseCommentJson(sysIdCommentMap);            
        }
        try{
            if(caseCommentJsonStringMap!=null && caseCommentJsonStringMap.size()>0){
                for(Id casId: caseCommentJsonStringMap.keySet()){
                    HttpRequest req = new HttpRequest();
                    //req.setEndpoint(endPoint);
                    req.setEndpoint('callout:' + EDGE_MULESOFT_COMMENT);//146993
                    req.setMethod('POST');
                    string requestBody = caseCommentJsonStringMap.get(casId);
                    req.setBody(requestBody);
                    //req.setHeader('client_id',clientId);
                   // req.setHeader('client_secret',clientSecret);
                    req.setHeader('Content-Type', 'application/json');
                    request = requestBody;
                    Http http = new Http();
                    if(Limits.getCallouts() < Limits.getLimitCallouts() &&  totalCallOutsPerformed < totalAllowedCallOuts){
                        HTTPResponse res = http.send(req);
                        totalCallOutsPerformed++;
                        if(res.getStatusCode() == 200){
                            D1_CustomLoggingUtility.logMessage('EDGE_CaseCommentIntegrationWithSNOW', 'execute', 'SUCCESS','','', request != null ? request : '', res.getBody());
                        }else{
                            D1_CustomLoggingUtility.logMessage('EDGE_CaseCommentIntegrationWithSNOW', 'execute', res.getStatus()+';'+res.getStatusCode(),'','',  request != null ? request : '', res.getBody());
                        }
                    }else{
                        caseCommentNotProcessed.add(casId);
                    }                    
                }
            }
        }catch(exception ex){
            D1_CustomLoggingUtility.logMessage('EDGE_CaseCommentIntegrationWithSNOW', 'execute', ex.getCause()+';'+ex.getLineNumber()+';'+ex.getMessage(),ex.getStackTraceString(),ex.getTypeName(), request != NULL ?request:'', response != NULL ? response:'');
        }
        if(attachmentPresent && caseIdConVersionIdMap != null && caseIdConVersionIdMap.size() > 0){
            if(!Test.isRunningTest()){
                System.enqueueJob(new Edge_CaseAttachmentIntegrationWithSNOW(caseIdConVersionIdMap));
            }
            
        } 
    } 
    public Map<Id,String> fetchCaseCommentJson(Map<Id,List<String>> sysIdCommentMap){
        Map<Id,String> caseSysidCommentMap = new Map<Id,String> ();
        List<String> sysidCommentList = new List<String>();
        String sysId;
        String commentBody;
        //Separating Sysid and Comment for Each Case Id
        if(sysIdCommentMap != null && sysIdCommentMap.Size()>0){
            for (Id caseId : sysIdCommentMap.keyset())
            {
                sysidCommentList = sysIdCommentMap.get(caseId);
                if(sysidCommentList != null && sysidCommentList.Size()>1){
                    sysId = sysidCommentList[0];
                    commentBody = sysidCommentList[1];
                }
                sysidCommentList = null;
                //JSON Generator for SysId and Comment         
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                string sysIdCheck = sysId == null?'':sysId;
                string commentBodyCheck = commentBody == null?'':commentBody;
                gen.writeStringField(SYSIDLABEL, sysIdcheck); 
                gen.writeStringField(COMMENTBODYLABEL, commentBodyCheck);        
                gen.writeEndObject();
                string jsonString = gen.getAsString();
                caseSysidCommentMap.put(caseId,jsonString);
                
            }
        }
        return caseSysidCommentMap;
    }    
}