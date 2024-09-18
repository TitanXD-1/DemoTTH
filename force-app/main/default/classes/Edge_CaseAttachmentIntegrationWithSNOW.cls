/**

* @description :  Edge_CaseAttachmentIntegrationWithSNOW

* @history :

* Version   Developer      		Date       User Story	  Purpose
* 1.0       Monalisa Halder   26/07/2021   ES20-9662      Class implemented to send the Case details to Service Now.
* 1.1		Shivam Chauhan    18/10/2023	146993			Migrating Authentication Mechanism to oAuth 2.0_SFDC_Tech Debt
*/


public without sharing class Edge_CaseAttachmentIntegrationWithSNOW  implements Queueable,Database.AllowsCallouts {
    
    public static final String EDGE_MULESOFT_ATTACHMENT = 'EDGE_Mulesoft_SNAttachment';//146993
    
    Map<Id,Map<Id, String>> caseIdConVersionIdMap = new Map<Id,Map<Id, String>>();
    //public static final String ENDPOINT = system.Label.Send_Attachment_SNOW_End_Point;
    //public static final string CLIENTID= system.Label.Service_Now_Client_Id ;
    //public static final string CLIENTSECRET= system.Label.Service_Now_Client_Secret;
    public static final string TOTALALLOWEDCALLOUTSSTR = system.Label.Service_Now_Case_Attachment_Allowed_Callouts;
    
    /*Constructor*/
    public Edge_CaseAttachmentIntegrationWithSNOW(Map<Id,Map<Id, String>> caseIdConVersionIdMap){
        this.caseIdConVersionIdMap = caseIdConVersionIdMap;
    }
    
/*
Method  : execute
Purpose : This method makes callout to SNOW with Case details
*/     
    public void execute(QueueableContext bc){
        
        Map<Id,String> caseAttachmentDetailsMap = new Map<Id,String>();
        list<Id> caseListNotProcessed = new list<Id>();
        Integer totalCallOutsPerformed = 0;
        Integer totalAllowedCallOuts = Integer.valueOf(TOTALALLOWEDCALLOUTSSTR);
        string request = '';
        string response = '';
        
        if(caseIdConVersionIdMap != null){
            caseAttachmentDetailsMap = getCaseAttachmentDetail(caseIdConVersionIdMap);
        }        
        try{
            if(caseAttachmentDetailsMap != null && caseAttachmentDetailsMap.size() > 0){
                
                for(Id ide : caseAttachmentDetailsMap.keySet() ){
                    
                    HttpRequest req = new HttpRequest();
                    //req.setEndpoint(endPoint);
                    req.setEndpoint('callout:' + EDGE_MULESOFT_ATTACHMENT);//146993
                    req.setMethod('POST');
                    string requestBody = caseAttachmentDetailsMap.get(ide);
                    req.setBody(requestBody);
                 //   req.setHeader('client_id',clientId);
               //     req.setHeader('client_secret',clientSecret);
                    req.setHeader('Content-Type', 'application/json');
                    
                    request = requestBody;
                    
                    if(!Test.isRunningTest()){
                        Http http = new Http();
                        if(Limits.getCallouts() < Limits.getLimitCallouts() &&  totalCallOutsPerformed < totalAllowedCallOuts){
                            HTTPResponse res = http.send(req);
                            totalCallOutsPerformed++;
                            if(res.getStatusCode() == 200){
                                D1_CustomLoggingUtility.logMessage('EDGE_CaseAttachmentIntegrationWithSNOW', 'execute', 'SUCCESS','','', request != null ? request : '', res.getBody());
                            }else{
                                D1_CustomLoggingUtility.logMessage('EDGE_CaseAttachmentIntegrationWithSNOW', 'execute', res.getStatus()+';'+res.getStatusCode(),'','',  request != null ? request : '', res.getBody());
                            }
                        }else{
                            caseListNotProcessed.add(ide);
                        }
                    } 
                    
                }
            }
        }catch(exception ex){
            D1_CustomLoggingUtility.logMessage('EDGE_CaseAttachmentIntegrationWithSNOW', 'execute', ex.getCause()+';'+ex.getLineNumber()+';'+ex.getMessage(),ex.getStackTraceString(),ex.getTypeName(), request != NULL ?request:'', response != NULL ? response:'');
            
        }
        
        
    }
    
    
/*
Method  : getCaseAttachmentDetail (ES20-9662)
Purpose : This method creates a JSON string format for case attachment details to 
be sent to SNOW
*/ 
    public  Map<Id,String> getCaseAttachmentDetail(Map<Id,Map<Id, String>> caseIdConVersionIdMap){
        
        Map<Id,String> caseAttachmentDetailsMap = new Map<Id,String>();
        Map<Id,String> caseIdSysIdMap = new Map<Id,String>();
        String contentVerId;
        String caseId;
        String sysid;
        String name;
        
        if(caseIdConVersionIdMap != null){
            for(Case caseRec :[Select Id,sys_id__c from Case where Id IN :caseIdConVersionIdMap.keySet()]){
                caseIdSysIdMap.put(caseRec.Id,caseRec.sys_id__c);
            }
            
            if(caseIdSysIdMap != null && caseIdSysIdMap.size() > 0){
                
                for( Id  cId :caseIdSysIdMap.keySet()){
                    Map<Id,String> contentVersionIdTitleMap = new Map<Id,String>();
                    contentVersionIdTitleMap = caseIdConVersionIdMap.get(cId);
                    
                    if(contentVersionIdTitleMap != null && contentVersionIdTitleMap.Size()>0){
                        for(Id contentVersionId :contentVersionIdTitleMap.keySet()){
                            contentVerId = contentVersionId;
                            caseId = cId;
                            sysid = caseIdSysIdMap.get(cId);
                            name = contentVersionIdTitleMap.get(contentVersionId);
                            
                        }
                        
                    }
                    
                    JSONGenerator gen = JSON.createGenerator(true);
                    gen.writeStartObject();
                    
                    if(sysid != null){
                        gen.writeStringField('ContentVerId', contentVerId == null?'': contentVerId);
                        gen.writeStringField('CaseId', caseId == null?'': caseId);
                        gen.writeStringField('Sys_id', sysid == null?'': sysid);
                        gen.writeStringField('Name', name == null?'': name);
                    }      
                    
                    gen.writeEndObject();
                    string jsonString = gen.getAsString();
                    caseAttachmentDetailsMap.put(cId,jsonString);
                    
                }
                
            } 
            
        }
        return caseAttachmentDetailsMap;
    }
    
}