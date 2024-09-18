/*
* Class Name: ECM_ContractApprovalEmailService
* Author: 
* Brief Description: This class is used to receive inbound email for contract.
* Created Date: 
* History: 
VERSION    AUTHOR                DATE              DETAIL
1.0												Initial Development
1.1		Saurav Prasad			25/06/2021		ECM-4565 SD Extra approval_Global_SFDC_Approval revamp

1.2		Saurav Prasad			27/07/2021		ECM-4639 Legal Approval for Product level investment exceeding x amount_SFDC_Ireland MVP
1.3		Saurav Prasad			16/08/2021		ECM-4690 Approval Email consolidation: Contract approval+ SD+SD Item Approval mails
1.4		Saurav Prasad			18/08/2021		ECM-4740 Approval Logs: Change field type to multi select pick list
1.5		Saurav Prasad			24/03/2022		ECM-5358: Contract rejection email to Sales Rep_SFDC_GLO
1.6		Manikandan.T			17/05/2022		ECM-5586: Revamped and moved the logic to ECm_ApprovalTriggerHelper.
1.7		Pratik Somani			08/08/2022		ECM-5868: Approval & rejection for Addendum_SFDC_EU
1.8     Anshu Prakash           03/03/2022      ECM-6800: [Fast Track] Email Reply by GAS User _SFDC_March Release
*/
global class ECM_ContractApprovalEmailService implements Messaging.InboundEmailHandler {
    global Messaging.InboundEmailResult handleInboundEmail(Messaging.InboundEmail email, Messaging.InboundEnvelope envelope) {
        Messaging.InboundEmailResult result = new Messaging.InboundEmailresult();
        String userComments;
        String status;
        String contractId;
        //ECM-5868->Start
        Boolean isAddendum = false;
        String conStatus;
        if(email.subject.containsIgnoreCase('Addendum')){
            List<String> subStrLst = email.subject.split('_');
            if(subStrLst.size() > 2){//Addendum for non-amended con: connumber_txt_date_txt
                isAddendum = true;
                conStatus = 'Active';
            }
            else{
                conStatus = 'In Approval Process'; //Addendum for Amended Con : connumber_txt
            }
        }
        else{
            conStatus = 'In Approval Process';
        }
        system.debug(LoggingLevel.INFO,'sub '+email.subject);
        system.debug(LoggingLevel.INFO,'body '+email.plainTextBody);
        //ECM-5868->End
        if(email.subject.contains('Sandbox')){
            contractId = email.subject.substringBetween('Sandbox:','_').trim();
        }
        //ECM-6800
        else{
            if(Label.ECM_ContractRejectReplyUpper.containsIgnoreCase(email.subject.substringBefore(':'))){
                contractId = email.subject.substringBetween(':','_').trim();
            }
        }
        try{

            String emailType;//ECM-4639

            Integer multipleApproverCount = 0;
            Map<String,ECM_Approval_Log__c> approvalLogMap = new Map<String,ECM_Approval_Log__c>();
            Integer approvalcount = 0;
            list<ECM_Approval_Log__c>ecmApprovalLogs = new list<ECM_Approval_Log__c>();


            System.debug(LoggingLevel.INFO,'email.subject@'+email.subject);
            //ECM-4740
            if(email.subject.containsIgnoreCase('contract, sales driver and sales driver item details')){
                emailType = 'Contract;Contract Sales Driver;Contract Sales Driver Item';
            }else if(email.subject.containsIgnoreCase('contract and sales driver details')){
                emailType = 'Contract;Contract Sales Driver';
            }else if(email.subject.containsIgnoreCase('contract and sales driver item details')){
                emailType = 'Contract;Contract Sales Driver Item';
            }else if(email.subject.containsIgnoreCase('sales driver and sales driver item details')){
                emailType = 'Contract Sales Driver;Contract Sales Driver Item';
            }//End of ECM-4740
            //changes for ECM-4639
            else if(email.subject.containsIgnoreCase('sales driver item details')){//ECM-4690
                emailType = 'Contract Sales Driver Item';
            }else if(email.subject.containsIgnoreCase('sales driver details')){
                emailType = 'Contract Sales Driver';

            }else{
                emailType = 'Contract';
            }
            //end of ECM-4639

			//ECM-5868->Add status condition for Addendum
            contract contraRec = [SELECT Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
                                  Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
                                  ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
                                  ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,
                                  ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
                                  ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
                                  ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email,ECM_Amended__c
             					  FROM 
                                  Contract 
                                  WHERE ContractNumber=:contractId AND Status=:conStatus LIMIT 1];
                				  //from Contract where ContractNumber=:ContractId AND Status='In Approval Process' limit 1];
            //Check if user present in the org
            String emailId = email.fromAddress;
            List<User> emailFromUser  = [Select id,Name,IsActive,Email,Title,Available_Countries__c from User where Email=:emailId limit 1];
            Boolean isNotApproved = false;
            Boolean isRequested = false;
            ECM_Approval_Log__c ecmCurrentApprovalLog = new ECM_Approval_Log__c();
            String earlyStatusOfApprover = '';
            if(contraRec!=null){
                for(integer i=0;i<email.plainTextBody.split('\n').size();i++ ){
                    if(i>0){
                        userComments =userComments==Null?email.plainTextBody.split('\n')[i]+' ':userComments+email.plainTextBody.split('\n')[i]+' ';
                    }else{
                        status = email.plainTextBody.split('\n')[i];
                    }
                }
                //ECM-5868->Start
               
                list<ECM_Approval_Log__c>ecmAllApprovalLogs = new list<ECM_Approval_Log__c>();
                list<ECM_Addendum__c> ecmAddendums = new list<ECM_Addendum__c>();
                if(isAddendum){
                	ecmAddendums = [Select Id, Name, ECM_Status__c,ECM_Contract__c From ECM_Addendum__c 
                                                    Where ECM_Contract__c=:contraRec.Id AND ECM_Status__c = 'In Approval' order by createdDate DESC];        
                    if(ecmAddendums.size()>0){
                          ecmAllApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                            recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                            ECM_Sales_Driver__c,ECM_Type__c,ECM_Approval_Rejection_Channel__c,ECM_Addendum__c
                                                            From ECM_Approval_Log__c 
                                                            Where ECM_Contract__c=:contraRec.Id AND ECM_Addendum__c = :ecmAddendums[0].Id order by createdDate DESC];
                    }
                        
                }
                else{
                //ECM-5868->End
                 ecmAllApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                            recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                            ECM_Sales_Driver__c,ECM_Type__c,ECM_Approval_Rejection_Channel__c
                                                            From ECM_Approval_Log__c 
                                                            Where ECM_Contract__c=:contraRec.Id  order by createdDate DESC];
                }
                
                for(ECM_Approval_Log__c appLogOb :ecmAllApprovalLogs){
                    if(appLogOb.ECM_No_of_Approval_Cycles__c > approvalcount ){
                        approvalcount = Integer.valueOf(appLogOb.ECM_No_of_Approval_Cycles__c);
                    }
                }
                System.debug(LoggingLevel.INFO,'approvalcount--->'+approvalcount);
                //Part of ECM-4565
                if(ecmAllApprovalLogs !=null && ecmAllApprovalLogs.size()>0){
                    for(ECM_Approval_Log__c ecmAL : ecmAllApprovalLogs){
                        if(ecmAL.ECM_No_of_Approval_Cycles__c == approvalcount){
                            ecmApprovalLogs.add(ecmAL);

                            String cmpKey = ecmAL.Name+'_'+ecmAL.ECM_Type__c;//ECM-4639

                            approvalLogMap.put(cmpKey, ecmAL);
                            
                        }
                    }
                }
                System.debug(LoggingLevel.INFO,'approvalLogMap--->'+approvalLogMap);
                System.debug(LoggingLevel.INFO,'ecmApprovalLogs--->'+ecmApprovalLogs);
                
                if(ecmApprovalLogs !=null && ecmApprovalLogs.size()>0){
                    for(ECM_Approval_Log__c ecmAL : ecmApprovalLogs){
                        System.debug(LoggingLevel.INFO,'ecmAL--->'+ecmAL);
                        if(String.isNotEmpty(email.fromAddress) && String.isNotEmpty(ecmAL.Name)){
                            if(ecmAL.Name == email.fromAddress && ecmAL.ECM_Status__c == 'Requested'){

                                String cmpKey = ecmAL.Name+'_'+emailType;//ECM-4639

                                System.debug(LoggingLevel.INFO,'cmpKey-->'+cmpKey);
                                if(approvalLogMap.containsKey(cmpKey)){
                                    ecmCurrentApprovalLog = approvalLogMap.get(cmpKey);
                                    earlyStatusOfApprover = approvalLogMap.get(cmpKey).ECM_Status__c;
                                }
                                multipleApproverCount = multipleApproverCount+1;
                            }else{                               
                                if(ecmAL.ECM_Status__c !='Approved'){
                                    isNotApproved = true;                                   
                                }                             
                            }
                        }
                        System.debug(LoggingLevel.INFO,'ecmCurrentApprovalLog1' +ecmCurrentApprovalLog);
                        System.debug(LoggingLevel.INFO,'earlyStatusOfApprover1' +earlyStatusOfApprover);
                    }
                }

                

                //Part of ECM-4565
                if(multipleApproverCount>1){
                    isNotApproved = true;  
                }
                if(ecmCurrentApprovalLog==null || String.isEmpty(ecmCurrentApprovalLog.Id)){
                    ECM_Approval_Log__c al = new ECM_Approval_Log__c();
                    //ECM-5868->Start
                    if(isAddendum && ecmAddendums.size()>0){
                    	ecmCurrentApprovalLog.ECM_Addendum__c = ecmAddendums[0].id;
                    }
  				    //ECM-5868->End
                    ecmCurrentApprovalLog.ECM_Contract__c = contraRec.Id; 
                    ecmCurrentApprovalLog.ECM_Status__c = 'Requested';
                    ecmCurrentApprovalLog.ECM_Type__c = 'Contract';
                    ecmCurrentApprovalLog.ECM_No_of_Approval_Cycles__c = approvalcount;
                    earlyStatusOfApprover = 'Requested';
                    if(String.isNotEmpty(email.fromAddress)){
                        ecmCurrentApprovalLog.Name= email.fromAddress;
                    }
                    if(emailFromUser !=null && emailFromUser.size()>0){
                        if(String.isNotEmpty(emailFromUser[0].Title)){
                            //null check Approvers Position of ECM-4194
                            if(ecmCurrentApprovalLog.ECM_Approver_s_Position__c==Null){
                                ecmCurrentApprovalLog.ECM_Approver_s_Position__c = emailFromUser[0].Title;
                            }
                        }
                        Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Primary_approver').getRecordTypeId();
                        if(String.isNotEmpty(recordIdApprovalLog)){
                            ecmCurrentApprovalLog.RecordTypeId = recordIdApprovalLog;
                        }
                    }else{
                        Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                        if(String.isNotEmpty(recordIdApprovalLog)){
                            ecmCurrentApprovalLog.RecordTypeId = recordIdApprovalLog;
                        }
                    }
                    
                }else{
                    if(emailFromUser !=null && emailFromUser.size()>0 && String.isNotEmpty(emailFromUser[0].Title)){
                        //null check Approvers Position of ECM-4194
                        if(ecmCurrentApprovalLog.ECM_Approver_s_Position__c==Null){
                            ecmCurrentApprovalLog.ECM_Approver_s_Position__c = emailFromUser[0].Title;
                        }
                    }
                }
                ecmCurrentApprovalLog.ECM_Time_Date_Log__c = System.now();
                
                if(status !='' && status !=Null && ecmCurrentApprovalLog.ECM_Status__c.containsIgnoreCase('Requested')){
                    ecmCurrentApprovalLog.ECM_Status__c = status.equalsignorecase('approve') || status.equalsignorecase('approved')?'Approved':status.equalsignorecase('rejected') || status.equalsignorecase('reject') ?'Rejected':ecmCurrentApprovalLog.ECM_Status__c;
                    ecmCurrentApprovalLog.ECM_Approval_Rejection_Channel__c = 'Email';
                }         
                if(userComments !='' && userComments !=Null ){
                    if(userComments.substringBeforeLast('From:').length() >131072){
                        ecmCurrentApprovalLog.ECM_Comment__c = userComments.substringBeforeLast('From:').substring(0, 131072);
                    }else{
                        ecmCurrentApprovalLog.ECM_Comment__c = userComments.substringBeforeLast('From:');
                    }
                }
                //update or create Approval log
                if(String.isNotEmpty(earlyStatusOfApprover) && earlyStatusOfApprover.containsIgnoreCase('Requested')){
                    upsert ecmCurrentApprovalLog ;
                }
                

                //get record type on contractVersion
                Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
                ContentVersion cVersion = new ContentVersion();
                if(String.isNotEmpty(recordIdContentVersion)){
                    cVersion.RecordTypeId = recordIdContentVersion;
                }
                cVersion.Content_Type__c = 'Approvals';
                cVersion.ContentLocation = 'S'; //S-Document is in Salesforce. E-Document is outside of Salesforce. L-Document is on a Social Netork.
                cVersion.PathOnClient = 'Email_Comunication.eml';//File name with extention
                cVersion.Title = 'Email Comunication';//Name of the file
                cVersion.VersionData = Blob.valueOf('from: '+email.fromName+'<'+email.fromAddress+'>'+ '\n'+ 
                                                    'to: '+email.toAddresses+'\n'+
                                                    'cc: '+email.ccAddresses+'\n'+
                                                    'inReplyTo: '+email.inReplyTo+'\n'+
                                                    'replyTo: '+email.replyTo+'\n'+
                                                    'date: '+System.now()+'\n'+
                                                    'subject: '+email.subject+'\n'+'\n'+
                                                    email.plainTextBody);//File content
                Insert cVersion;
                
                //After saved the Content Verison, get the ContentDocumentId
                Id conDocument = [SELECT ContentDocumentId FROM ContentVersion WHERE Id =:cVersion.Id].ContentDocumentId;
                ContentDocumentLink cDocLink = new ContentDocumentLink();
                cDocLink.ContentDocumentId = conDocument;//Add ContentDocumentId
                cDocLink.LinkedEntityId = ecmCurrentApprovalLog.Id;//Add attachment parentId
                cDocLink.ShareType = 'I';//V - Viewer permission. C - Collaborator permission. I - Inferred permission.
                cDocLink.Visibility = 'InternalUsers';//AllUsers, InternalUsers, SharedUsers
                Insert cDocLink;

                //End of ECM-5358
            }
        }catch(Exception e){
            system.debug(LoggingLevel.INFO,'Exception Caught in ECM_ContractApprovalEmailService class at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        result.success = true;
        return result;
    }
    
}