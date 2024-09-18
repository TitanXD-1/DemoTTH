/*
* Class Name: ECM_ApprovalLogTriggerHelper
* Author: 
* Brief Description: Helper Class for ECM_ApprovalLogTriggerHandler.
* Created Date: 
* History: 
VERSION    AUTHOR                DATE              DETAIL
1.0		Manikandan.T		17/05/2022		ECM-5586: Initial Development
1.1     Vinay Tummala       07/06/2022      ECM-5649: SFDC to handle the Approval request Email to be sent to Extra Approver_Approval request for sales manager
1.2     Saurav Prasad       23/06/2022      ECM-5764: 1) Approval Flow_Contract getting Approved with pending EXTRA_APPROVER and 2) Approval log_Extra record is getting created for EA
1.3		Saurav Prasad		02/08/2022		ECM-5867: Approval flow for Addendum (Prim+Contract)_SFDC_EU
1.4     Pratap/Subhrojit	05/08/2022		ECM-6009: Fix for bug related to Extra Approval Emails
1.5     Anand Uppalapati    08/08/2022      ECM-5905: Approval flow for Addendum (SD+Legal)_SFDC_EU
1.6		Saurav Prasad		16/08/2022		ECM-6032: Approval flow for Addendum (Prim+Contract+SD+SDI)_SFDC_EU
1.7		Saurav Prasad		24/08/2022		ECM-6069: QA Defect : Logic change for the addendum Extra Approvals with type=Contract
1.8     Pratap Sen          26/08/2022      ECM-5816: SFDC_E&S_Logic: workflow to primary & extra approver
1.9     Saurav Prasad       13/12/2022      ECM-6450: QA_Defect : Not receiving Push notification
2.0     Saurav Prasad       13/07/2023      142555	: CM static code violation for the classes_SFDC_Technical Debt
2.1     Saurav Prasad       18/07/2023      143259	: QA: Sales Manager is not able to approve contract.
*/

public without sharing class ECM_ApprovalLogTriggerHelper {
    public static List<Contract> afterUpdatecontractList = new List<Contract>(); //added as part of ECM-6450
    public static List<Messaging.SingleEmailMessage> multiuserEmailList = new List<Messaging.SingleEmailMessage>();//ECM-6830
    /*
    * @description : This method checks if the approval log has been approved or Rejected. If approved then fires approvals for Extra Approvers.
    * @return : void
    * @param : trigger.New,Map_Contract
    */
    public static void approvalResponseHandler(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        Set<Id> contractIdList= new Set<Id>();
        Map<Id,ECM_Approval_Log__c> newApprovalLogItems= new Map<Id,ECM_Approval_Log__c>();
        Map<Id,ECM_Approval_Log__c> oldApprovalLogItems= new Map<Id,ECM_Approval_Log__c>();
        Map<Id,Map<String,Decimal>> contractSalesDriverItemMap = new Map<Id,Map<String,Decimal>>();
        Map<Id,List<ECM_Sales_Driver_Item_Detail__c>> contractSalesDriverItemDetailMap= new Map<Id,List<ECM_Sales_Driver_Item_Detail__c>>();
        List<ECM_Approval_Log__c> approvalLogList= new List<ECM_Approval_Log__c>();
        List<Id> agreementIdList= new list<Id>();
        Set<String> contractCountrySet = new Set<String>();
        Set<String> marketSettingEmailTemplate = new Set<String>();
        ECM_ApprovalLogWrapper approvalLogWrapper = new ECM_ApprovalLogWrapper();
        Map<Id,List<ECM_Approval_Log__c>> approvallogMap = new Map<Id,List<ECM_Approval_Log__c>>();
        Map<Id,List<ECM_Approval_Log__c>> legalApprovalMap = new Map<Id,List<ECM_Approval_Log__c>>();   //NOPMD
        Map<Id,Id> primaryApprovalLogMap = new Map<Id,Id>();
        List<Contract> updatecontractList= new List<Contract>();
        Map<String,Market_Setting__c> marketSettingMap= new Map<String,Market_Setting__c>();
        Map<String,emailTemplate> emailTemplateMap= new Map<String,emailTemplate>();
        Map<Id,ContentDocumentLink> contentDocumentLinkMap= new Map<Id,ContentDocumentLink>();
        Map<Id,ContentDocumentLink> contentDocumentLinkMapAddendum= new Map<Id,ContentDocumentLink>();
        Id primaryApproverRecordTypeId=Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Primary_approver').getRecordTypeId();
        ECM_Approval_Log__c recentPrimaryApprovalLog= new ECM_Approval_Log__c();
        Map<String, String> mailTemplateTrigger = new Map<String, String>();
        for(ECM_Email_Template_Setting__mdt emailTemp:[SELECT Id,Masterlabel,DeveloperName,ECM_Related_to_Object__c, ECM_Type__c  
                                                       FROM ECM_Email_Template_Setting__mdt WITH SECURITY_ENFORCED]){
                                                           mailTemplateTrigger.put(emailTemp.ECM_Related_to_Object__c+'-'+emailTemp.ECM_Type__c,emailTemp.Masterlabel);
                                                       }
       
        //ECM-5867
        Map<String,Decimal> newInvestmentConItemsMap = new Map<String,Decimal>();
        Map<Id,set<String>> existingLegalApprovalLogsMap = new Map<Id,set<String>>();
        //ECM-5764           
        Map<Id,Decimal> approvalcount= new Map<Id,Decimal>();
        Map<Id,Decimal> legalApprovalCount= new Map<Id,Decimal>();
        List<ECM_Addendum__c> updateAddendumList= new List<ECM_Addendum__c>();//ECM-5868
        String countryName = '';//ECM-6009
        String countryCode = '';//ECM-6009
        //ECM-6069
        Map<Id,Decimal> contractAandPmap = new Map<Id,Decimal>();
        Map<Id,Decimal> contractTImap = new Map<Id,Decimal>();
        Id sdidSDRecId = Schema.SObjectType.ECM_Sales_Driver_Item_Detail__c.getRecordTypeInfosByName().get('Sales Driver').getRecordTypeId();
        
        try{
            if(newItems!=null){
                newApprovalLogItems=(Map<Id,ECM_Approval_Log__c>)newItems;
            }
            
            if(oldItems!=null){
                oldApprovalLogItems=(Map<Id,ECM_Approval_Log__c>)oldItems;
            }
            
            
            for(ECM_Approval_Log__c currentApprovalLog:newApprovalLogItems.values() ){
                //Changes related to ECM-5675->start
                if (currentApprovalLog.ecm_status__c!=oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c && 
                    ((oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c=='Approved' && (currentApprovalLog.ECM_Status__c =='Rejected' || currentApprovalLog.ECM_Status__c =='Requested' || currentApprovalLog.ECM_Status__c =='Recalled' || currentApprovalLog.ECM_Status__c =='Cancelled'))
                     || (oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c=='Rejected' && (currentApprovalLog.ECM_Status__c =='Approved' || currentApprovalLog.ECM_Status__c =='Requested' || currentApprovalLog.ECM_Status__c =='Recalled' || currentApprovalLog.ECM_Status__c =='Cancelled'))
                     || (oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c=='Recalled' && (currentApprovalLog.ECM_Status__c =='Approved' || currentApprovalLog.ECM_Status__c =='Requested' || currentApprovalLog.ECM_Status__c =='Rejected' || currentApprovalLog.ECM_Status__c =='Cancelled'))
                     || (oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c=='Cancelled' && (currentApprovalLog.ECM_Status__c =='Approved' || currentApprovalLog.ECM_Status__c =='Requested' || currentApprovalLog.ECM_Status__c =='Rejected' || currentApprovalLog.ECM_Status__c =='Recalled')))){
                         currentApprovalLog.addError('The Contract has been already moved to '+ oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c +' status. Hence your Action cannot be taken in account');		
                     }        
                //Changes related to ECM-5675->end
                if(currentApprovalLog.ecm_status__c!=oldApprovalLogItems.get(currentApprovalLog.Id).ecm_status__c && (currentApprovalLog.ECM_Status__c=='Approved' || currentApprovalLog.ECM_Status__c=='Rejected')){
                    contractIdList.add(currentApprovalLog.ECM_Contract__c);
                }        
            }
            if(!contractIdList.isEmpty()){
                list<ECM_Approval_Log__c> ecmAllApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                                recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                                ECM_Sales_Driver__c,ECM_Type__c,ECM_Contract__c,ECM_Addendum__c
                                                                From ECM_Approval_Log__c 
                                                                Where ECM_Contract__c IN:contractIdList WITH SECURITY_ENFORCED order by createdDate DESC ];
                //142555
                getApprovalCountAndLegalCount(ecmAllApprovalLogs, approvalcount, legalApprovalCount);
                
                System.debug(LoggingLevel.DEBUG,'approvalcount @'+approvalcount);
                System.debug(LoggingLevel.DEBUG,'legalApprovalCount @'+legalApprovalCount);
                
                //ECM-5764->Added condtion for approvalcount
                for(ECM_Approval_Log__c currentApprovalLog:ecmAllApprovalLogs ){
                    if(approvalcount.containsKey(currentApprovalLog.ECM_Contract__c) &&
                       currentApprovalLog.ECM_No_of_Approval_Cycles__c == approvalcount.get(currentApprovalLog.ECM_Contract__c)
                       && ApprovallogMap.containsKey(currentApprovalLog.ECM_Contract__c)){
                           List<ECM_Approval_Log__c>tempApprovalLogs=ApprovallogMap.get(currentApprovalLog.ECM_Contract__c);
                           tempApprovalLogs.add(currentApprovalLog);
                           ApprovallogMap.put(currentApprovalLog.ECM_Contract__c,tempApprovalLogs);	
                           
                       }else if(approvalcount.containsKey(currentApprovalLog.ECM_Contract__c) &&
                                currentApprovalLog.ECM_No_of_Approval_Cycles__c == approvalcount.get(currentApprovalLog.ECM_Contract__c)
                                && !ApprovallogMap.containsKey(currentApprovalLog.ECM_Contract__c)){
                                    ApprovallogMap.put(currentApprovalLog.ECM_Contract__c,new List<ECM_Approval_Log__c>{currentApprovalLog});
                                }
                    
                    if(legalApprovalCount.containsKey(currentApprovalLog.ECM_Contract__c) &&
                       currentApprovalLog.ECM_No_of_Approval_Cycles__c == legalApprovalCount.get(currentApprovalLog.ECM_Contract__c)){
                           getExistingLegalApprovalLogsMap(ExistingLegalApprovalLogsMap, currentApprovalLog);
                       }
                    //ECM-5649
                    if(currentApprovalLog.recordTypeId==primaryApproverRecordTypeId
                       && recentPrimaryApprovalLog.Id==null){
                           recentPrimaryApprovalLog=currentApprovalLog;
                           primaryApprovalLogMap.put(recentPrimaryApprovalLog.ECM_Contract__c,recentPrimaryApprovalLog.Id);
                           
                       }
                }
                approvalLogWrapper.legalApprovalLog=ExistingLegalApprovalLogsMap;//ECM-5905
                approvalLogWrapper.primaryApprovalLogMap=primaryApprovalLogMap;
                system.debug(LoggingLevel.DEBUG,'primaryApprovalLogMap-->'+approvalLogWrapper.primaryApprovalLogMap);
                //ECM-5649
                Map<Id,Contract> contraRecMap = new Map<Id,Contract>();
                //142555
                contraRecMap.putALL(getContractDetails(contractIdList));
                System.debug(LoggingLevel.DEBUG,'contraRecMap @'+contraRecMap);
                    
                for(Contract currentRecord:contraRecMap.values()){
                    
                    agreementIdList.add(currentRecord.ECM_Agreement_Type__c);
                    contractCountrySet.add(currentRecord.Account.Country__c);
                    countryName = currentRecord.Account.Country__r.Name;
                    countryCode = currentRecord.Account.Country__r.Code__c;
                    
                }
                //ECM-6009
                Map<Id,ECM_Contract_Type__c> agreementTypeMap;
                if(countryName.equalsIgnoreCase('Australia') || countryCode.equalsIgnoreCase('AU')){
                    agreementTypeMap = new Map<Id,ECM_Contract_Type__c>([Select Id,
                                                  (Select Id,ECM_Extra_Approval__r.Id,
                                                   ECM_Extra_Approval__r.Name,
                                                   ECM_Extra_Approval__r.ECM_Active__c,
                                                   ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c,
                                                   ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c,
                                                   ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c,
                                                   ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c,
                                                   ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c,
                                                   ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c,
                                                   ECM_Extra_Approval__r.ECM_Enable_Delegation__c,
                                                   ECM_Extra_Approval__r.ECM_Approver_Position_Name__c,
                                                   ECM_Extra_Approval__r.ECM_Type__c,ECM_Extra_Approval__r.ECM_Sales_Driver__c
                                                   from Agreement_Approvals__r 
                                                   where ECM_Extra_Approval__r.ECM_Active__c =TRUE AND
                                                   ECM_Extra_Approval__r.ECM_Type__c = 'Contract' 
                                                   ORDER BY ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c ASC NULLS LAST) 
                                                  from ECM_Contract_Type__c where Id IN :agreementIdList]);
                    
                }
                else{
                 	agreementTypeMap = new Map<Id,ECM_Contract_Type__c>([SELECT Id,(SELECT Id,ECM_Extra_Approval__r.Id,ECM_Extra_Approval__r.name,ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c,
                                                                                    ECM_Extra_Approval__r.ECM_Active__c,ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c,ECM_Extra_Approval__r.ECM_Enable_Delegation__c,
                                                                                    ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c,ECM_Extra_Approval__r.ECM_Approver_Position_Name__c,
                                                                                    ECM_Extra_Approval__r.ECM_Type__c,ECM_Extra_Approval__r.ECM_Sales_Driver__c,
                                                                                    ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c,ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c,ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c,
                                                                                    ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c,ECM_Extra_Approval__r.ECM_Legal_Related__c
                                                                                    FROM Agreement_Approvals__r 
                                                                                    WHERE ECM_Extra_Approval__r.ECM_Active__c =TRUE AND
                                                                                    (ECM_Extra_Approval__r.ECM_Type__c = 'Contract' OR
                                                                                     ECM_Extra_Approval__r.ECM_Type__c = 'Contract Sales Driver' OR
                                                                                     ECM_Extra_Approval__r.ECM_Type__c = 'Contract Sales Driver Item')
                                                                                    ORDER by ECM_Extra_Approval__r.ECM_Type__c ASC) 
                                                                         			from ECM_Contract_Type__c where Id IN:agreementIdList]);
                }
                approvalLogWrapper.agreementTypeMap=agreementTypeMap;
                
                //addendum
                for(ECM_Sales_Driver_Item__c sdItem:
                    [SELECT id,Contract__c,ECM_Total_Investment_Amount__c, ECM_Sales_Driver__c,
                     (SELECT id,ECM_Sales_Driver_Item__r.Contract__c,ECM_Investment_Amount__c,
                      ECM_Budget_Type__c,ECM_Addendum__c, RecordTypeId,ECM_Product__c 
                      FROM Sales_Driver_Item_Details__r) 
                     FROM ECM_Sales_Driver_Item__c 
                     WHERE Contract__c IN :contractIdList WITH SECURITY_ENFORCED]){
                         
                         //142555
                         getContractSalesDriverItemMap(sdItem,ContractSalesDriverItemMap);
                         
                         if(sdItem.Sales_Driver_Item_Details__r!=null){
                             getContractSalesDriverItemDetailMap(sdItem,ContractSalesDriverItemDetailMap);
                            
                             //ECM-6069
                             for(ECM_Sales_Driver_Item_Detail__c sdItemRec:sdItem.Sales_Driver_Item_Details__r){

                                 getAnPBudgetTypeMap(sdItemRec,contractAandPmap,sdidSDRecId);
                                 getTIBudgetTypeMap(sdItemRec,contractTImap,sdidSDRecId);
                             }
                         } 
                     }
               
                System.debug(LoggingLevel.DEBUG,'contractAandPmap @'+contractAandPmap);
                System.debug(LoggingLevel.DEBUG,'contractTImap @'+contractTImap);
                System.debug(LoggingLevel.DEBUG,'ContractSalesDriverItemDetailMap @'+ContractSalesDriverItemDetailMap);
                System.debug(LoggingLevel.DEBUG,'ContractSalesDriverItemMap @'+ContractSalesDriverItemMap);
                
                //END of ECM-6069
                approvalLogWrapper.ContractSalesDriverItemMap=ContractSalesDriverItemMap;
                approvalLogWrapper.ContractSalesDriverItemDetailMap=ContractSalesDriverItemDetailMap;
                
                for(Market_Setting__c  marketObj : [SELECT Id, Name__c,ECM_Evidence_email_enabled__c, ECM_Payment_Evidence_Pre_Payment_SP__c,ECM_Payment_Evidence_Pre_Payment__c,ECM_Payment_Evidence_SP_template__c,
                                                    ECM_Payment_Evidence_template__c,ECM_Payment_Invoice_SP_template__c,ECM_Contract_Approval_Template__c,ECM_Payment_Invoice_template__c, ECM_Payment_Management_Email__c, Geography__c, Geography__r.Name, 
                                                    Geography__r.Code__c, ECM_Contract_pdf_to_Approval_Mails__c,ECM_Rejection_Email_to_Sales_Rep__c
                                                    FROM Market_Setting__c WHERE Geography__c IN: contractCountrySet]){
                                                        
                                                        marketSettingMap.put(marketObj.Geography__c,marketObj);
                                                        marketSettingEmailTemplate.add(marketObj.ECM_Contract_Approval_Template__c);
                                                    }
                
                
                for(emailTemplate em: [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where (DeveloperName IN:marketSettingEmailTemplate) or (DeveloperName IN:mailTemplateTrigger.values()) WITH SECURITY_ENFORCED]){
                    emailTemplateMap.put(em.DeveloperName,em);
                }
                
                for(ContentDocumentLink  existConDoc : [SELECT Id, LinkedEntityId, ContentDocumentId, ContentDocument.FileExtension, ContentDocument.Title,ContentDocument.LatestPublishedVersion.Content_Type__c,ContentDocument.LatestPublishedVersion.VersionData FROM ContentDocumentLink 
                                                        WHERE LinkedEntityId IN: contraRecMap.keySet() OR (LinkedEntityId IN:primaryApprovalLogMap.values() and (ContentDocument.title=:system.label.ECM_Contract_Approval_Email_PDF_Name OR ContentDocument.title=: system.label.ECM_Addendum_Approval_File_Name)) WITH SECURITY_ENFORCED]){
                                                            if(Label.ECM_ContentTypeApprovalMail.contains(existConDoc.ContentDocument.LatestPublishedVersion.Content_Type__c)){  
                                                                
                                                                ContentDocumentLinkMap.put(existConDoc.LinkedEntityId,existConDoc);
                                                            }else if(existConDoc.ContentDocument.title==system.label.ECM_Contract_Approval_Email_PDF_Name){
                                                                ContentDocumentLinkMap.put(existConDoc.LinkedEntityId,existConDoc);
                                                                
                                                            }else if(existConDoc.ContentDocument.title==system.label.ECM_Addendum_Approval_File_Name){
                                                                ContentDocumentLinkMapAddendum.put(existConDoc.LinkedEntityId,existConDoc);
                                                            }
                                                            system.debug(LoggingLevel.DEBUG,'@@@doc '+existConDoc.ContentDocument.title+' '+existConDoc.ContentDocument.LatestPublishedVersion.Content_Type__c);
                                                            
                                                        }
                system.debug(LoggingLevel.DEBUG,'@@@doc2 '+ContentDocumentLinkMapAddendum);
                system.debug(LoggingLevel.DEBUG,'@@@doc3 '+ContentDocumentLinkMap);
                approvalLogWrapper.marketSettingMap=marketSettingMap;
                approvalLogWrapper.emailTemplateMap=emailTemplateMap;
                approvalLogWrapper.ContentDocumentLinkMap=ContentDocumentLinkMap;
                approvalLogWrapper.ContentDocumentLinkMapAddendum=ContentDocumentLinkMapAddendum;
                approvalLogWrapper.OrgWideEmailAddressId=[select Id,Address from OrgWideEmailAddress where Address =:Label.ECM_ContractApproverOrgWideEmail Limit 1].Id;
                approvalLogWrapper.rejectionEmailTemplateId=[Select Id from EmailTemplate where DeveloperName =:Label.ECM_RejectionEmailToSalesRep_Template Limit 1].Id;
                //ECM-5867 
                for(ECM_Contract_Item__c conItem:
                    [SELECT Id,ECM_Contract__c,ECM_Addendum__c,ECM_Retro_investment__c,
                     ECM_AnP_investment__c,ECM_Trade_investments__c 
                     FROM ECM_Contract_Item__c WHERE ECM_Contract__c IN:contractIdList WITH SECURITY_ENFORCED]){
                         Decimal newInvestment=0;
                         newInvestment+=  conItem.ECM_Retro_investment__c!=Null?conItem.ECM_Retro_investment__c:0;
                         newInvestment += contractAandPmap.containsKey(conItem.Id)?contractAandPmap.get(conItem.Id):0;
                         newInvestment += contractTImap.containsKey(conItem.Id)?contractTImap.get(conItem.Id):0;
                         
                         String temp = String.valueOf(conItem.ECM_Contract__c+'-'+conItem.ECM_Addendum__c);
                         if(!newInvestmentConItemsMap.containsKey(temp)){
                             newInvestmentConItemsMap.put(temp,newInvestment.setScale(2));
                         }else{
                             Decimal tempVar = newInvestmentConItemsMap.get(temp);
                             tempVar+=newInvestment;
                             newInvestmentConItemsMap.put(temp,tempVar.setScale(2));
                         }
                     }
                approvalLogWrapper.newInvestmentConItemAddendum = newInvestmentConItemsMap;
                //End of ECM-5867 
                
                Map<String,Boolean> conApprovalMap= new Map<String,Boolean> ();
                for(ECM_Technical_Market_Setting__mdt mdt: [select masterlabel,ECM_Country__c,ECM_Contract_Extra_Approval__c from ECM_Technical_Market_Setting__mdt where ECM_Contract_Extra_Approval__c=True WITH SECURITY_ENFORCED]){
                    conApprovalMap.put(mdt.ECM_Country__c,mdt.ECM_Contract_Extra_Approval__c);
                }

                for(ECM_Approval_Log__c currentApprovalLog:newApprovalLogItems.Values()){
                    //ECM-5764
                    approvalLogWrapper.currentApprovalLog = currentApprovalLog;
                    
                    Boolean isNotApproved = false;
                    List<ECM_Approval_Log__c>ecmApprovalLogs= new List<ECM_Approval_Log__c>();
                    Contract contraRec= new contract();
                    
                    if(contraRecMap.containsKey(currentApprovalLog.ecm_contract__c)){
                        contraRec=contraRecMap.get(currentApprovalLog.ecm_contract__c);
                    }
                    if(ApprovallogMap.containsKey(currentApprovalLog.ecm_contract__c)){
                        ecmApprovalLogs=ApprovallogMap.get(currentApprovalLog.ecm_contract__c);
                    }
                    //ECM-5764
                    for(ECM_Approval_Log__c ecmAL : ApprovallogMap.get(currentApprovalLog.ECM_Contract__c)){
                        
                        if(!newApprovalLogItems.containsKey(ecmAL.Id) && 
                           ecmAL.ECM_Status__c!='Approved'){
                               isNotApproved = true;
                           }
                    }
                    
                    //validtaion for approved primary approval log
                    String earlyStatusOfApprover=oldApprovalLogItems.get(currentApprovalLog.Id).ECM_Status__c;
                    //143259
                    if(String.isNotEmpty(earlyStatusOfApprover) && earlyStatusOfApprover.containsIgnoreCase('Requested') && currentApprovalLog.ECM_Status__c=='Approved'){
                        Id primaryApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Primary_approver').getRecordTypeId();
                        Id extraApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                        Boolean isAnotherLogs = false;
                        if(currentApprovalLog.recordTypeId == primaryApprovalLog){
                            system.debug('coutry Name->'+contraRec.Account.Country__r.Name);		
                            if(contraRec.Account.Country__r.Name.equalsIgnoreCase('Australia') ||
                               contraRec.Account.Country__r.Name.equalsIgnoreCase('AU')){
                                   isAnotherLogs = ECM_ApprovalLogUtility.updatePrimaryApprovalLog_AU(contraRec,ecmApprovalLogs,approvalLogWrapper);
                               }else{
                                   
                                   if(conApprovalMap.get(contraRec.Account.Country__r.Code__c)!=null){
                                       if(conApprovalMap.get(contraRec.Account.Country__r.Code__c)){
                                           //ECM-5867 
                                           if(currentApprovalLog.ECM_Addendum__c != NULL){
                                               isAnotherLogs = ECM_ApprovalLogUtility.updatePrimaryApprovalLogAddendum(contraRec,ecmApprovalLogs,approvalLogWrapper);
                                           }else{
                                               isAnotherLogs = ECM_ApprovalLogUtility.updatePrimaryApprovalLog(contraRec,ecmApprovalLogs,approvalLogWrapper);
                                           }
                                       }
                                   }
                                   
                               }
                            
                        }else if(currentApprovalLog.recordTypeId==extraApprovalLog){
                            if(contraRec.Account.Country__r.Name.equalsIgnoreCase('Australia') ||
                               contraRec.Account.Country__r.Name.equalsIgnoreCase('AU')){
                                   isAnotherLogs = ECM_ApprovalLogUtility.updateExtraApprovalLog_AU(contraRec,ecmApprovalLogs,currentApprovalLog,approvalLogWrapper);
                               }
                        }
                        if(isNotApproved==false && isAnotherLogs==true){
                            isNotApproved = true;
                        }
                    }
                    //End of 143259
                    //ECM-5868->Added Addendum condtion 
                    if((!isNotApproved || currentApprovalLog.ECM_Status__c=='Rejected') && currentApprovalLog.ECM_Addendum__c == NULL){
                        contract tempContract= new Contract(Id=contraRec.Id);
                        tempContract.Status = contraRec.Status=='Approved' || currentApprovalLog.ECM_Status__c=='Approved'?'Approved':'Draft';
                        updatecontractList.add(tempContract);
                        
                    }
                    //ECM-5868->Start
                    else if((!isNotApproved || currentApprovalLog.ECM_Status__c=='Rejected') && currentApprovalLog.ECM_Addendum__c != NULL){
                        ECM_Addendum__c tempAddendum = new ECM_Addendum__c(Id=currentApprovalLog.ECM_Addendum__c);
                        tempAddendum.ECM_Status__c = currentApprovalLog.ECM_Status__c=='Approved'?'Approved':'Draft';
                        updateAddendumList.add(tempAddendum);
                    }
                    //ECM-5868->End
                    //ECM-5868->Added Addendum condtion 
                    if(currentApprovalLog.ECM_Status__c.containsIgnoreCase('Rejected') && currentApprovalLog.ECM_Addendum__c == NULL){
                        ECM_ApprovalLogUtility.sendRejectionEmailToSalesRep(currentApprovalLog.Id, contraRec, approvalLogWrapper);
                    }
                }
            }
            
            if(!approvalLogWrapper.ApprovalLogList.isEmpty()){
                Database.Insert(approvalLogWrapper.ApprovalLogList);
            }
            
            if(!updatecontractList.isEmpty()){
                //Database.update(updatecontractList); //added and commented as part of ECM-6450
                afterUpdatecontractList.addAll(updatecontractList);
            }
            //ECM-5868->Start
            if(!updateAddendumList.isEmpty()){
                Database.update(updateAddendumList);
            }
            //ECM-5868->End
            if(!approvalLogWrapper.multiuserEmailList.isEmpty()){
                multiuserEmailList.addAll(approvalLogWrapper.multiuserEmailList);//ECM-6830
                //Messaging.SendEmailResult[] r = Messaging.sendEmail(approvalLogWrapper.multiuserEmailList);   
            }
            //approvalUpdate();
        }catch(Exception e){
            system.debug(LoggingLevel.DEBUG,'Exception caught at Line Number '+e.getLineNumber()+' Error: '+e.getMessage());
        }
        
    }
    //142555
    public static void getExistingLegalApprovalLogsMap(Map<Id,Set<String>> existingLegalApprovalLogsMap,ECM_Approval_Log__c currentApprovalLog){
        List<String> types = currentApprovalLog.ECM_Type__c != NULL?currentApprovalLog.ECM_Type__c.split(';'):new List<String>();
        for(String applogType:types){
            if(applogType =='Contract'){
                if(ExistingLegalApprovalLogsMap.containsKey(currentApprovalLog.ECM_Contract__c)){
                    ExistingLegalApprovalLogsMap.get(currentApprovalLog.ECM_Contract__c).add(currentApprovalLog.name);
                }
                else{
                    ExistingLegalApprovalLogsMap.put(currentApprovalLog.ECM_Contract__c,new set<String>{currentApprovalLog.name});
                }
                
            }
        }
        
    }

    public static void getAnPBudgetTypeMap(ECM_Sales_Driver_Item_Detail__c sdItemRec,Map<Id,Decimal> budgetMap,Id sdidSDRecId){
        if(sdItemRec.ECM_Budget_Type__c !=null && sdItemRec.ECM_Budget_Type__c.contains('A&P') && sdItemRec.RecordTypeId == sdidSDRecId){
            Decimal sdItemInv = (sdItemRec.ECM_Investment_Amount__c != Null)? sdItemRec.ECM_Investment_Amount__c : 0;
            
            if(budgetMap.containsKey(sdItemRec.ECM_Product__c)){
                budgetMap.put(sdItemRec.ECM_Product__c,sdItemInv+(budgetMap.containsKey(sdItemRec.ECM_Product__c)?budgetMap.get(sdItemRec.ECM_Product__c):0));
            }else{
                budgetMap.put(sdItemRec.ECM_Product__c,sdItemInv);
            }
        }
    }
    public static void getTIBudgetTypeMap(ECM_Sales_Driver_Item_Detail__c sdItemRec,Map<Id,Decimal> budgetMap,Id sdidSDRecId){
        if(sdItemRec.ECM_Budget_Type__c !=null && sdItemRec.ECM_Budget_Type__c.contains('TI') && sdItemRec.RecordTypeId == sdidSDRecId){
            Decimal sdItemInv = (sdItemRec.ECM_Investment_Amount__c != Null)? sdItemRec.ECM_Investment_Amount__c : 0;
            
            if(budgetMap.containsKey(sdItemRec.ECM_Product__c)){
                budgetMap.put(sdItemRec.ECM_Product__c,sdItemInv+(budgetMap.containsKey(sdItemRec.ECM_Product__c)?budgetMap.get(sdItemRec.ECM_Product__c):0));
            }else{
                budgetMap.put(sdItemRec.ECM_Product__c,sdItemInv);
            }
        }
    }
    
    public static Map<Id,Contract> getContractDetails(set<Id> contractIdList){
        Map<Id,Contract> contractMap = new Map<Id,Contract>();
        for(Contract con : 
            [select Id, ECM_Overall_Investment_Amount__c, ECM_Agreement_Type__c,Status,Account.Country__r.Name,Account.Country__r.Code__c,
             Account.Country__c,ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c, ECM_Hybrid_CustInvest_Total_PercentGP__c,
             ECM_Overall_Investment_Figure__c,ECM_Territory__r.Country__r.Name,ECM_Territory__r.Region__c,
             ECM_Territory__r.Business_Unit__c,ECM_Territory__r.Sales_Area__c,ECM_Territory__c,Recordtype.DeveloperName,
             ECM_Recalled__c,ECM_Reason_For_Recall__c,ECM_Parent_Contract__c,ECM_Parent_Contract__r.startDate,startDate,ECM_Duration__c,ECM_Parent_Contract__r.ECM_Duration__c,
             ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c,ECM_of_the_total_investment_vs_NSV__c,ECM_Parent_Contract__r.ECM_Overall_investments__c,ECM_Overall_investments__c,
             ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c,ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c, Owner.Email,RecordTypeId,
             ECM_Parent_Contract__r.ECM_Indicative_Total_Funding__c,ECM_Indicative_Total_Funding__c,ECM_Amended__c
             from Contract where Id IN :contractIdList AND (Status='In Approval Process' OR Status='Active') WITH SECURITY_ENFORCED]){
                 contractMap.put(con.Id,con);        
             }
        return contractMap;
    }
    
    public static void getApprovalCountAndLegalCount(List<ECM_Approval_Log__c> ecmAllApprovalLogs, Map<Id,Decimal> approvalcount, Map<Id,Decimal> legalApprovalCount){
        //those records addendum is present
        //ECM-5764->Start
        for(ECM_Approval_Log__c appLogOb :ecmAllApprovalLogs){
            if(!approvalcount.containsKey(appLogOb.ECM_Contract__c)){
                approvalcount.put(appLogOb.ECM_Contract__c,appLogOb.ECM_No_of_Approval_Cycles__c);
            }
            else{
                if(appLogOb.ECM_No_of_Approval_Cycles__c > approvalcount.get(appLogOb.ECM_Contract__c) ){
                    approvalcount.put(appLogOb.ECM_Contract__c,appLogOb.ECM_No_of_Approval_Cycles__c);
                }
            }
            
            //ECM-5905
            if(appLogOb.ECM_Addendum__c == NULL && !legalApprovalCount.containsKey(appLogOb.ECM_Contract__c)){
                legalApprovalCount.put(appLogOb.ECM_Contract__c,appLogOb.ECM_No_of_Approval_Cycles__c);
            }
            else if(appLogOb.ECM_Addendum__c == NULL && legalApprovalCount.containsKey(appLogOb.ECM_Contract__c)
                    && appLogOb.ECM_No_of_Approval_Cycles__c > legalApprovalCount.get(appLogOb.ECM_Contract__c) ){
                        legalApprovalCount.put(appLogOb.ECM_Contract__c,appLogOb.ECM_No_of_Approval_Cycles__c);
                    }
        }
        //ECM-5764->End
        
    }
    
    public static void getContractSalesDriverItemMap(ECM_Sales_Driver_Item__c sdItem,Map<Id,Map<String,Decimal>> contractSalesDriverItemMap){
        
        if(ContractSalesDriverItemMap.containsKey(sdItem.Contract__c)){
            
            Map<String,Decimal> salesDriverMap= ContractSalesDriverItemMap.get(sdItem.Contract__c);
            switch on String.valueOf(SalesDriverMap.containsKey(sdItem.ECM_Sales_Driver__c)) {
                when 'true' {
                    decimal totalAmt=SalesDriverMap.get(sdItem.ECM_Sales_Driver__c)+sdItem.ECM_Total_Investment_Amount__c;
                    SalesDriverMap.put(sdItem.ECM_Sales_Driver__c,totalAmt);
                }
                when else {
                    SalesDriverMap.put(sdItem.ECM_Sales_Driver__c,sdItem.ECM_Total_Investment_Amount__c);
                }
            }
            ContractSalesDriverItemMap.put(sdItem.Contract__c,SalesDriverMap);
            
        }else{								
            
            ContractSalesDriverItemMap.put(sdItem.Contract__c,new Map<String,Decimal>{sdItem.ECM_Sales_Driver__c=>sdItem.ECM_Total_Investment_Amount__c});
            
        }
    }
    
    public static void getContractSalesDriverItemDetailMap(ECM_Sales_Driver_Item__c sdItem,Map<Id,List<ECM_Sales_Driver_Item_Detail__c>> contractSalesDriverItemDetailMap){
        
        switch on String.valueOf(ContractSalesDriverItemDetailMap.containsKey(sdItem.Contract__c)) {
            when 'true' {
                List<ECM_Sales_Driver_Item_Detail__c> sDIDList= ContractSalesDriverItemDetailMap.get(sdItem.Contract__c);
                SDIDList.addAll(sdItem.Sales_Driver_Item_Details__r);
                ContractSalesDriverItemDetailMap.put(sdItem.Contract__c,SDIDList);
            }
            when else {
                List<ECM_Sales_Driver_Item_Detail__c> sDIDList=new List<ECM_Sales_Driver_Item_Detail__c>();
                SDIDList.addAll(sdItem.Sales_Driver_Item_Details__r);
                ContractSalesDriverItemDetailMap.put(sdItem.Contract__c,SDIDList);
            }
        }
    }
    
    //added below method as part of ECM-6450
    public static void afterUpdateContractList(){
        Set<Contract> afterUpdatecontractSet = new Set<Contract>(); //added as part of ECM-6450
        if(!afterUpdatecontractList.isEmpty()){
            	afterUpdatecontractSet.addAll(afterUpdatecontractList);
            	afterUpdatecontractList.clear();
            	afterUpdatecontractList.addAll(afterUpdatecontractSet);
                Database.update(afterUpdatecontractList);
            }
        //ECM-6830
        if(!multiuserEmailList.isEmpty() && !Test.isRunningTest()){
            Messaging.SendEmailResult[] r = Messaging.sendEmail(multiuserEmailList);   //NOPMD
        }
    }
    
}