/*
@Name: ECM_ContractAnniversaryNotificationBatch
@Purpose: This batch is to send email notification to the customer on each Anniversary year completion of contracts 
The functionality is different for GB and IE Market. 
In order to run batch we have to add country code either ECM_Anniv_Default_Template or ECM_Anniv_Default_Template2 label

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Subhodeep Sarkar     18/07/2022        Initial Development (ECM-5903)
1.1        Priya Soni           18/07/2022        Initial Development (ECM-5903)
1.2        Anand Uppalapati     16/09/2022        ECM-6025 Anniversary email to Sales Rep/Customer_SFDC_EU
1.3		   Sagnik && Nidhi	    13/10/2022		  ECM-6236 Anniversary email for Ireland (before 2 months and based on Lead Brand)
1.4        Tanishq Banerjee     08/03/2023        ECM-6788 QA_Defect: Anniversay mails are getting triggered irrespective of contract duration
1.5        Joshraj Sen          01/04/2024        152305 SCA Fix
1.6        Saurav Prasad        21/04/2024        152604 Bug Fix to Ensure the Email is sent only once
*/
public class ECM_ContractAnniversaryNotificationBatch implements Database.Batchable<sObject>, Database.Stateful, BatchJobManagementInterfaceClass{
    
    String exceptionMsg = '';
    Boolean hasError = false ;
    String countryCode = '';
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId;
    Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();
    List<Contract> conLst = new List<Contract>();
    List<String> countryGBFunc = Label.ECM_Anniv_Default_Template.split(',');
    List<String> countryIEFunc = Label.ECM_Anniv_Default_Template2.split(',');
    /*
* @description : get the batch detail for corresponding market 
* @return : void
* @param : Market_Batch_Setting Metadata
*/
    
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
        emailTemplateMap = ECM_ContractAnniversaryNotiMailHelper.getEmailTemplate(countryCode);
    }
    
    /*
* @description : start method of batch
* @return : Database.QueryLocator
* @param : Database.BatchableContext
*/
    
    public Database.QueryLocator start(Database.BatchableContext bc){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        List<String> conRecordTypeNames = new List<String>();//152305
        conRecordTypeNames=Label.ECM_ActualVolumeYTDBatchConRecordType.split(','); //Outlet,Group//152305
        List<String> approvedStatus = new List<String>();//152305
        approvedStatus=Label.ECM_AnniversaryContractStatus.split(',');//Active//152305
        List<String> excludeEmailAnniversary = new List<String>();//152305
        excludeEmailAnniversary=Label.ECM_Agreement_Picklist_Anniv_Email.split(',');//152305
        
        String query = 'SELECT Id, ECM_Contract_Owner__c,Owner.Email,Owner.Manager.Email, Name,Owner.isActive, StartDate, Contract_End_Date__c,AccountId,Account.Country__c, Account.Country__r.Code__c,Account.Email_for_contracts_payments__c, '+
            'ECM_Duration__c, Account.Name, ContractNumber, ECM_Expiration_Notification_sent__c, ECM_Agreement_Type__c,ECM_Agreement_Type__r.ECM_Anniversary_Email_to_Customer__c FROM Contract '+
            'WHERE ECM_Agreement_Type__r.ECM_Anniversary_Email_to_Customer__c NOT IN: excludeEmailAnniversary '+
            'AND ECM_Duration__c > 12 AND Status IN: approvedStatus AND RecordType.Name IN: conRecordTypeNames AND Account.Country__r.Code__c =: countryCode';
        
        return Database.getQueryLocator(query);
        
    }
    
    /*
* @description : execute method of batch
* @return : void
* @param : Database.BatchableContext, List<Contract>
*/
    
    public void execute(Database.BatchableContext bc, List<Contract> contractList){
        
        //List<Contract> conLst = new List<Contract>();
        conLst.clear();
        if(contractList!=null && !contractList.isEmpty()) {
            for(Contract con:contractList){
                buildContractLst(con);
            }
            //helper code
            if(countryGBFunc.contains(countryCode)){
                ECM_ContractAnniversaryNotiMailHelper.createEmailListForAnniversary(conLst,countryCode,emailTemplateMap);
            }else if(countryIEFunc.contains(countryCode)){
                ECM_ContractAnniversaryNotiMailHelper.createEmailListForAnniversaryIE(conLst,countryCode,emailTemplateMap);
            }
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_ContractAnniversaryNotificationBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    private void buildContractLst(Contract con){
        
        Integer monthAhead;
        if(countryGBFunc.contains(countryCode)){
            monthAhead = Integer.valueOf(Label.ECM_ConAnnivmonths_GB);
        }else if(countryIEFunc.contains(countryCode)){
            monthAhead = Integer.valueOf(Label.ECM_ConAnnivmonths_IE);
        }else{
            monthAhead = 0;
        }
        if(con.ECM_Duration__c != null) {  
            for(Integer n=1;n<=(con.ECM_Duration__c/12);n++){
                if(con.StartDate.addMonths(12*n)<con.Contract_End_Date__c.addDays(1) && con.StartDate.addMonths(12*n).addMonths(monthAhead)==System.today()){
                    conLst.add(con);
                    break;
                }
            }
        }
    }
}