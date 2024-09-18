/**********************************************************************
Name: CC_SendforApprovalToProdManager
=======================================================================
Purpose: This controller used to send email to product manager
=======================================================================
History                                                            
------------------------------------------------------------------------                                                            
VERSION    AUTHOR            DATE              DETAIL
1.0        Dasaratha N     15-04-2021        Initial Development
2.0        Saranga Bobade  22-09-2022        CR-3043
***********************************************************************/
public class CC_SendforApprovalToProdManager {
    @AuraEnabled
    public static CC_Investigation__c fetchInvestigationrecord(String invrecId) {
        CC_Investigation__c investrec=[Select Id, Name,CC_Case__r.CaseNumber,CC_Case_created_date__c,CC_Reference_Number_Case_ID__c,
                                       CC_Case__r.CC_Production_Manager__c,CC_Investigation_evidence_SLA_email_sent__c,
                                       CC_Root_Cause_of_the_Concern__c,CC_Existing_Controls_Category__c, CC_Existing_Controls_Owner__c,
                                       CC_If_yes_Explain_the_preventive_measure__c,CC_Existing_controls_Due_Date__c,
                                       CC_Preventative_actions_Category__c, CC_Closed_out_CCA_100_year_fix_in_place__c,
                                       CC_RCPS_tracker_updated__c, CC_Quality_Verification__c,Quip_URL__c,
                                       CC_Details_of_New_Improvement_Actions__c,Who_will_implement_improvement_action__c,
                                       CC_Implementation_date__c,CC_Additional_comments__c from CC_Investigation__c where Id=:invrecId];
        
        return investrec;
    }
    
    @AuraEnabled
    public static void sendEmailtoProdmanager(string subject,String fromaddress,string toaddress,string body, String invrecId) {
        System.debug('invecid'+ invrecId);
        // Email attachment code by Saranga starts for CR-3043
        List<ContentDocumentLink> cdlList = [SELECT id,ContentDocumentId,linkedEntityId FROM ContentDocumentLink WHERE linkedEntityId = :invrecId];
        System.debug(cdlList.size());
        
        if(cdlList.size() > 0){
            List<Id> listIDs = new List<Id>();
            for(ContentDocumentLink cvv : cdlList){
                listIDs.add(cvv.ContentDocumentId);
            }
            system.debug('listIDs'+listIDs);
            List<ContentVersion> cvList = [SELECT id,VersionData,Title, FileExtension FROM ContentVersion WHERE ContentDocumentId =: listIDs AND IsLatest = true];//listIDs
            
            List<ContentVersion> listCV = new List<ContentVersion>();
            for(ContentVersion cvv : cvList){
                
                ContentVersion cv = new ContentVersion();
                cv.VersionData = cvv.VersionData;
                //cv.FileExtension = cvv.FileExtension;
                cv.Title = cvv.Title+'.'+cvv.FileExtension;
                cv.PathOnClient = cvv.Title;
                cv.Description = cvv.Title;
                cv.isMajorVersion = true;
                insert cv;
                listCV.add(cv);
            }
            
            system.debug('listCV '+ listCV);      
            system.debug('cvListVersionData'+cvList[0].VersionData);
            
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            
            String[] toaddressCol = toaddress.split(',');
            message.toAddresses = toaddressCol;
            message.subject = subject;
            message.htmlbody = body;
            message.setUseSignature(false); 
            message.setCharset('UTF8');
            
            List<Messaging.EmailFileAttachment> lstFileAttachments = new List<Messaging.EmailFileAttachment>();
            for(ContentVersion clist : listCV)
            {
                Messaging.EmailFileAttachment efa = new Messaging.EmailFileAttachment();
                Blob fileData = clist.VersionData;
                System.debug(fileData);
                efa.setFileName(clist.Title); 
                efa.setBody(fileData);
                lstFileAttachments.add(efa);
            }
            message.setFileAttachments(lstFileAttachments);       
            System.debug('message value =============>' + message);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
            
        }
        // Email attachment code by Saranga ends for CR-3043
        else{
            Messaging.SingleEmailMessage message = new Messaging.SingleEmailMessage();
            String[] toaddressCol = toaddress.split(',');
            message.toAddresses = toaddressCol;
            message.subject = subject;
            message.htmlbody = body;
            message.setUseSignature(false); 
            message.setCharset('UTF8');
            System.debug('message value =============>' + message);
            Messaging.SendEmailResult[] results = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{message});
        }
    }
}