/*
 * Class Name : ECM_PaymentSummarySendEmailBatch
 * @description: Batch class to send Email for A&P Prepayment Evidences 
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.1        Anuja && Saurav       13/08/2021		  Initial Developement : ECM-4696
*/
global class ECM_PaymentSummarySendEmailBatch  implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    //Global Variable
    Market_Batch_Setting__mdt batchSetting;
    String countryCode ='';
    Id marketBatchJobId;
    boolean hasError = false;
    string exceptionMsg = '';
    OrgWideEmailAddress owEmailAddress = new OrgWideEmailAddress();
    Map<String,EmailTemplate> countrywiseEmailTemplate = new Map<String,EmailTemplate>();
    //Constructor
    public ECM_PaymentSummarySendEmailBatch(){
    	owEmailAddress =  [SELECT Id, Address, DisplayName 
                           FROM OrgWideEmailAddress 
                           WHERE Address =: Label.ECM_OrgWideEmailAddress limit 1];
        for(EmailTemplate empTemp :[SELECT Id,Name,DeveloperName, FolderId, FolderName, IsActive, Body, Subject, Description 
                                    FROM EmailTemplate 
                                    WHERE Folder.Name ='ECM_ContractManagementEmails' 
                                    AND name LIKE 'ECM_PrePayI&ETemplate%']){
            if(empTemp.name.contains('[') && empTemp.name.contains(']')){
             	String localeKey = String.valueOf(empTemp).substringAfterLast('[');
             	localeKey =   localeKey.substringBefore(']') ; 
             	countrywiseEmailTemplate.put(localeKey,empTemp);
             }
        }
    }  
    /*
	* @description : get the batch detail for corresponding market 
	* @return : void
	* @param : Market_Batch_Setting Metadata
	*/
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    /*
	* @description : start method of batch
	* @return : Database.QueryLocator
	* @param : Database.BatchableContext
	*/
	global Database.QueryLocator start(Database.BatchableContext bc) {
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        if(Test.isRunningTest()){
            return Database.getquerylocator([SELECT Id, ECM_Contract__r.ECM_Agreement_Type__r.ECM_Prepayment_Reminder__c,ECM_Invoice_Attachment__c, ECM_Evidence_Attachment__c,
                                         	 ECM_Notification_Sending_Date__c,ECM_Type__c,ECM_Contract__r.Owner.Email, ECM_Contract__r.Owner.Manager.Email,
                                             ECM_Contract__r.CreatedBy.LanguageLocaleKey,ECM_Contract__r.OwnerId,Name
                                             FROM ECM_Payment_Summary__c]);
        }else{
            return Database.getquerylocator([SELECT Id, ECM_Contract__r.ECM_Agreement_Type__r.ECM_Prepayment_Reminder__c,ECM_Invoice_Attachment__c, ECM_Evidence_Attachment__c,
                                         	 ECM_Notification_Sending_Date__c,ECM_Type__c,ECM_Contract__r.Owner.Email, ECM_Contract__r.Owner.Manager.Email,
                                             ECM_Contract__r.CreatedBy.LanguageLocaleKey,ECM_Contract__r.OwnerId,Name
                                         	 FROM ECM_Payment_Summary__c 
                                         	 WHERE ECM_Type__c ='Promo-PrePayment' 
                                         	 AND ECM_Contract__r.ECM_Agreement_Type__r.ECM_Prepayment_Reminder__c!= null
                                         	 AND (ECM_Invoice_Attachment__c = false OR ECM_Evidence_Attachment__c = false)
                                         	 AND ECM_Notification_Sending_Date__c = TODAY 
                                             AND ECM_Contract__r.Account.Country__r.Code__c =: countryCode]);
        }
    }
	/*
	* @description : execute method of batch
	* @return : void
	* @param : Database.BatchableContext,List ECM_Payment_Summary
	*/
	global void execute(Database.BatchableContext bc, List<ECM_Payment_Summary__c> paySumList) {
        
        List<Messaging.SingleEmailMessage> sendEmailList= new List<Messaging.SingleEmailMessage>();
        
        for(ECM_Payment_Summary__c paySumObj : paySumList){
            List<String> emailList = new List<String>();
            String countryCode ='en_US';
            if(String.isNotBlank(paySumObj.ECM_Contract__r.Owner.Email)){
                emailList.add(paySumObj.ECM_Contract__r.Owner.Email);
            }
            if(String.isNotBlank(paySumObj.ECM_Contract__r.Owner.Manager.Email)){
                emailList.add(paySumObj.ECM_Contract__r.Owner.Manager.Email); 
            }
            if(!emailList.isEmpty()){
                String userLocale = String.valueOf(paySumObj.ECM_Contract__r.CreatedBy.LanguageLocaleKey);
                if(!countrywiseEmailTemplate.isEmpty() && countrywiseEmailTemplate.containsKey(userLocale)){
                    countryCode =  String.valueOf(userLocale);
                }
                String emlSubject = Label.ECM_PS_Email_Subject;
                emlSubject = emlSubject.replace('####',paySumObj.Name);
                if(!paySumObj.ECM_Invoice_Attachment__c && !paySumObj.ECM_Evidence_Attachment__c){
                    emlSubject = emlSubject.replace('$$$$',Label.ECM_PS_Email_Subject_Evidence);
                    emlSubject = emlSubject.replace('&&&&', Label.ECM_PS_Email_Subject_And);
                    emlSubject = emlSubject.replace('****', Label.ECM_PS_Email_Subject_Invoice);
                }else{
                    if(!paySumObj.ECM_Invoice_Attachment__c){
                        emlSubject = emlSubject.replace('****', Label.ECM_PS_Email_Subject_Invoice);
                    }else if(!paySumObj.ECM_Evidence_Attachment__c){
                        emlSubject = emlSubject.replace('$$$$',Label.ECM_PS_Email_Subject_Evidence);
                    }
                    emlSubject = emlSubject.replace('$$$$','');
                    emlSubject = emlSubject.replace('&&&&', '');
                    emlSubject = emlSubject.replace('****', '');
                }
                EmailTemplate emlTempObj = countrywiseEmailTemplate.get(countryCode);
                Messaging.SingleEmailMessage email = Messaging.renderStoredEmailTemplate(emlTempObj.Id, paySumObj.ECM_Contract__r.OwnerId, paySumObj.Id);
                email.setToAddresses(emailList);
                email.setOrgWideEmailAddressId(owEmailAddress.Id);
                email.setSaveAsActivity(false);
                email.setSubject(emlSubject);
                sendEmailList.add(email);
            }
        }
        if(!sendEmailList.isEmpty()){
            Messaging.sendEmail(sendEmailList);
        }
    }
	/*
	* @description : finish method of batch
	* @return : void
	* @param : Database.BatchableContext
	*/
	public void finish(database.BatchableContext bc) {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_PaymentSummarySendEmailBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}