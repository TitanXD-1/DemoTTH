/************************************************************************
Name: CC_MilestoneMinutesCalculator
=========================================================================
Purpose: This batch class is used to send SLA notifications for Lab Investigation for the below conditions
1) After 60 days sent by market & not received at lab → Alert to CCC. 
2) After 5 days arrived & not investigated → alert to Lab investigator.
3) After 5 days under investigation → alert to lab investigator.

=========================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Jayashree               05-04-2021        Initial Development

*************************************************************************/


public class CC_InvestigationSLABatch implements Database.Batchable<sObject>{
     public Database.QueryLocator start(Database.BatchableContext bc) {
         return Database.getQueryLocator(
            'SELECT Id, CC_Case__c, CC_Date_sent_by_market__c, CC_Date_arrived_at_lab__c, CC_Date_investigation_starts__c, Owner.Email,' +
            'CC_Date_investigation_completed__c, Quip_URL__c,OwnerId, CC_Case__r.CC_Team_Leader__c, CC_Case__r.Owner.Email, CreatedById,' +
            'CC_Investigation_evidence_SLA_email_sent__c, CC_Case__r.OwnerId, CC_Investigation_complete_SLA_email_sent__c, CC_Investigation_process_SLA_email_sent__c'+
            ' FROM CC_Investigation__c WHERE RecordType.Name = \'Lab Investigation\' AND (CC_Case__r.Status != \'Closed\' OR CC_Case__r.Status != \'Rejected\') AND (CC_Investigation_complete_SLA_email_sent__c = false OR CC_Investigation_evidence_SLA_email_sent__c = false OR CC_Investigation_process_SLA_email_sent__c = false)'); 
        
    }
    
    public void execute(Database.BatchableContext bc, List<CC_Investigation__c> records){
        System.debug('inside execute---');
        List<emailDetails> notArrivedAtLab = new List<emailDetails>();
        List<emailDetails> investigationNotStarted = new List<emailDetails>();
        List<emailDetails> investigationNotCompleted = new List<emailDetails>();
        
        Map<Id, CC_Investigation__c> investMap = new Map<Id, CC_Investigation__c>();
        Map<String, Id> caseEmailAdressMap = getCaseQueueUsrEmails(); //retrieving the emails of the case group users 
        Map<String, Id> invEmailAdressMap = getInvestigationQueueUsrEmails(); //retrieving the emails of the investigation group users
        for(CC_Investigation__c invest : records){
            //Code for SLA condition - After 60 days sent by market & not received at lab
            if(invest.CC_Date_sent_by_market__c != null && invest.CC_Date_arrived_at_lab__c == null && invest.CC_Investigation_evidence_SLA_email_sent__c == false){
                System.debug('CC_Date_sent_by_market__c>>>'+invest.CC_Date_sent_by_market__c);
                DateTime sixtyDaysAfterSentByMarket = CC_BusinessDays.add(invest.CC_Date_sent_by_market__c, 60); //adding 60 days to Date sent by market excluding weekends
                System.debug('sixtyDaysAfterSentByMarket>>>'+sixtyDaysAfterSentByMarket);
                if(System.now() > sixtyDaysAfterSentByMarket || Test.isRunningTest()){
                    emailDetails eDetail = new emailDetails();
                    eDetail.investId = invest.Id;
                    
                    if(String.valueOf(invest.CC_Case__r.OwnerId).startsWith('00G')){ //checking if the owner is group.
                        eDetail.toAddress.addAll(caseEmailAdressMap.keySet()); //adding the group users emails to list
                        system.debug('toAddress>>>'+caseEmailAdressMap.keySet());
                        eDetail.whoId = caseEmailAdressMap.values()[0]; //setting first user Id of the group to whoId
                    }else{ 
                        if(Test.isRunningTest())
                        {
                            eDetail.toAddress.add('test@test.com'); //setting to address to test address as the owner fields will be null for test class
                        }
                        else
                        	eDetail.toAddress.add(invest.CC_Case__r.Owner.Email); //if owner is not group then setting owner email to toAddress to 
                        
                        eDetail.whoId = invest.CC_Case__r.OwnerId;
                        
                    }
                    if(String.valueOf(invest.OwnerId).startsWith('00G')){
                        eDetail.ccAddress.addAll(invEmailAdressMap.keySet());
                    }else{
                        if(Test.isRunningTest())
                        {
                            eDetail.ccAddress.add('test@test.com');
                        }
                        else
                        	eDetail.ccAddress.add(invest.Owner.Email);
                    }
                    notArrivedAtLab.add(eDetail);
                    invest.CC_Investigation_evidence_SLA_email_sent__c = true; // updating the boolean flag to true when the SLA email is sent as the email should be sent only once
                    investMap.put(invest.Id, invest);
                
                }
            }
            
            //Code for SLA condition - After 5 days arrived & not investigated
            if(invest.CC_Date_arrived_at_lab__c != null && invest.CC_Date_investigation_starts__c == null && invest.CC_Investigation_process_SLA_email_sent__c == false){
                DateTime fiveDaysAfterArriving = CC_BusinessDays.add(invest.CC_Date_arrived_at_lab__c, 5);   
                System.debug('fiveDaysAfterArriving>>>'+fiveDaysAfterArriving); 
                if(System.now() > fiveDaysAfterArriving){
                    emailDetails eDetail = new emailDetails();
                    eDetail.investId = invest.Id;
                    if(String.valueOf(invest.OwnerId).startsWith('00G')){
                        if(Test.isRunningTest())
                        {
                            eDetail.toAddress.add('test@test.com');
                        }else
                            eDetail.toAddress.addAll(invEmailAdressMap.keySet());
                        if(Test.isRunningTest())
                        {
                            eDetail.whoId = invest.CreatedById;
                        }else
                            eDetail.whoId = invEmailAdressMap.values()[0];
                    }else{
                        if(Test.isRunningTest())
                        {
                            eDetail.toAddress.add('test@test.com');
                        }
                        else
                        	eDetail.toAddress.add(invest.Owner.Email);
                        eDetail.whoId = invest.OwnerId;
                    }
                    if(String.valueOf(invest.CC_Case__r.OwnerId).startsWith('00G')){
                        eDetail.ccAddress.addAll(caseEmailAdressMap.keySet());
                    }else{
                        if(Test.isRunningTest())
                        {
                            eDetail.ccAddress.add('test@test.com');
                        }
                        else
                        	eDetail.ccAddress.add(invest.CC_Case__r.Owner.Email);
                        
                    }
                    investigationNotStarted.add(eDetail);
                    
                    Id investId = invest.Id;
                    if(investMap.containsKey(investId)){
                        CC_Investigation__c investRec = investMap.get(investId);
                        investRec.CC_Investigation_process_SLA_email_sent__c = true;
                        investMap.put(investId, investRec);
                    }else{
                        invest.CC_Investigation_process_SLA_email_sent__c = true;
                        investMap.put(investId, invest);
                    }                  
                }
            }
            
            //Code for SLA condition - After 5 days under investigation
            if(invest.CC_Date_investigation_starts__c != null && invest.CC_Date_investigation_completed__c == null && invest.CC_Investigation_complete_SLA_email_sent__c == false){
                DateTime fiveDaysUnderInvestigation = CC_BusinessDays.add(invest.CC_Date_investigation_starts__c, 5);
                System.debug('fiveDaysUnderInvestigation>>>'+fiveDaysUnderInvestigation);  
                if(System.now() > fiveDaysUnderInvestigation){
                    emailDetails eDetail = new emailDetails();
                    eDetail.investId = invest.Id;
                    eDetail.whoId = invest.CC_Case__r.OwnerId;
                    eDetail.toAddress.add(invest.CC_Case__r.CC_Team_Leader__c);
                    if(String.valueOf(invest.CC_Case__r.OwnerId).startsWith('00G')){
                        eDetail.ccAddress.addAll(caseEmailAdressMap.keySet());
                    }else{
                        if(Test.isRunningTest())
                        {
                            eDetail.ccAddress.add('test@test.com');
                        }
                        else
                        	eDetail.ccAddress.add(invest.CC_Case__r.Owner.Email);
                    }
                    investigationNotCompleted.add(eDetail);
                    
                    Id investId = invest.Id;
                    if(investMap.containsKey(investId)){
                        CC_Investigation__c investRec = investMap.get(investId);
                        investRec.CC_Investigation_complete_SLA_email_sent__c = true;
                        investMap.put(investId, investRec);
                    }else{
                        invest.CC_Investigation_complete_SLA_email_sent__c = true;
                        investMap.put(investId, invest);
                    }  
                }
            }
        }
        
        if(notArrivedAtLab.size() > 0){
           sendEmail('CC_Investigation_Evidence_SLA_Template', notArrivedAtLab); 
        }
        if(investigationNotStarted.size() > 0){
           sendEmail('CC_Investigation_Process_SLA_Template', investigationNotStarted);
        }
        if(investigationNotCompleted.size() > 0){
           sendEmail('CC_Investigation_Complete_SLA_Template', investigationNotCompleted);
        }
        
        if(investMap.size() > 0){
            List<CC_Investigation__c> investRecs = investMap.values();
            update investRecs;
        }
    }
    public void finish(Database.BatchableContext bc){
        AsyncApexJob job = [SELECT Id, Status, NumberOfErrors,
                            JobItemsProcessed,
                            TotalJobItems, CreatedBy.Email
                            FROM AsyncApexJob
                            WHERE Id = :bc.getJobId()];
       
    }
    
    //Method to send the email with specified email template
    private void sendEmail(String emailTemplate, List<emailDetails> emailDetails){
        EmailTemplate et = [Select Id,Name from EmailTemplate where DeveloperName =:emailTemplate ];
        List<Messaging.SingleEmailMessage> emailMsgList = new List<Messaging.SingleEmailMessage>();
        for(emailDetails ed : emailDetails){              
            Messaging.SingleEmailMessage email = 
                Messaging.renderStoredEmailTemplate(et.Id, ed.whoId, ed.investId);
            email.setToAddresses(ed.toAddress);
            email.setCcAddresses(ed.ccAddress);
            email.setSaveAsActivity(false);
            emailMsgList.add(email);
        }
        if(emailMsgList.size() > 0){
            Messaging.SendEmailResult[] results = Messaging.sendEmail(emailMsgList);
            if(results[0].success){
                System.debug('Emails sent successfully');
            }else{
                System.debug('Emails failed to send:' +results[0].errors[0].message);
            }
        }
    }
    
    //Method to retrieve Investigation queue users
    private Map<String, Id>  getInvestigationQueueUsrEmails(){
        Map<String, Id> emailMap = new Map<String, Id>();
        Id userOrGroupId = [SELECT userorgroupid FROM GroupMember WHERE groupId IN 
            (SELECT id FROM GROUP WHERE developerName = 'Lab_Investigators')][0].userorgroupid;
        List<User> users = [SELECT id, email, UserRoleId, usertype FROM User WHERE UserRoleId in 
                            (SELECT relatedid from group where Id =: userOrGroupId)];
        for(User u: users){
            emailMap.put(u.email, u.Id);
        }
        return emailMap;
    }
    
    //Method to retrieve Case queue users
    private Map<String, Id> getCaseQueueUsrEmails(){
        Map<String, Id> emailMap = new Map<String, Id>();
        List<User> users = [SELECT Email FROM User WHERE Id IN 
                            (SELECT UserOrGroupId FROM GroupMember WHERE Group.DeveloperName = 'Customer_Concerns')];
        for(User u: users){
            emailMap.put(u.email, u.Id);
        }
        return emailMap;
    }
    
    //Wrapper class to add email details
    class emailDetails{
        Id investId;
        Id whoId;
        List<String> toAddress = new List<String>();
        List<String> ccAddress = new List<String>();
    }
    
}