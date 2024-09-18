/*
*@Name: ECM_PaymentSummaryStatusChangeBatch
*@Test Class: ECM_PaymentSummaryStatusChangeBatchTest
*@Description: This class is used to change the status of PayementSummaries
*@History                                                            

*VERSION			AUTHOR				   DATE                     DETAIL
*1.0			  Pravalika			    02/03/2021		PS remodelling_EU_Logic_PS summary status change flow
*1.1			Saurav Prasad			15/06/2021		ECM-4515	:	Assign manager approval on ps record based on it's corresponding market.	
*1.2			Saurav Prasad			13/07/2021		ECM-4634	:	Making PS open based on start date_SFDC_Ireland MVP
* 																		Modified Query - SELECT Id,ECM_Type__c,ECM_Contract__r.Account.Country__c,ECM_Contract__r.CreatedById FROM ECM_Payment_Summary__c where ECM_Payment_Summary_Status__c=\'Provisional\' and ECM_Start_Period__c<=TODAY and ECM_Contract__r.Account.country__r.code__c =: countryCode and (ECM_Type__c=\'Promo-Standard\' OR ECM_Type__c=\'Promo-PrePayment\' OR ECM_Type__c=\'Volume-Based\')
*1.3            Pratap Sen              23/03/2021      ECM-5164	:	End Date based Status Change based on PF
                                                                  		Modified Query - Added ECM_End_Period__c & ECM_Payment_Frequency__r.ECM_Type__c
*1.4            Tanishq/Pratik          25/01/2023      ECM-6710	:	Delegation of Manager approval for Payment Summary is not Working_EU
*1.5			Saurav Prasad			07/07/2023		142555		:	CM static code violation for the classes_SFDC_Technical Debt
*
*/
global class ECM_PaymentSummaryStatusChangeBatch  implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    List<ECM_Payment_Summary__c> psSuccessList= new List<ECM_Payment_Summary__c>();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        String query=  'SELECT Id,ECM_Type__c,ECM_End_Period__c,ECM_Payment_Frequency__r.ECM_Type__c,'

            		  +'ECM_Contract__r.Account.Country__c,ECM_Contract__r.CreatedById,ECM_Contract__r.ECM_Agreement_Type__r.ECM_Prepayment_SR_approval__c,ecm_contract__r.owner.name,ecm_contract__r.ownerId,ecm_contract__r.owner.email,'

                      +'ECM_Approval_Sub_Status__c,ECM_Payment_Summary_Status__c FROM ECM_Payment_Summary__c '
                      +'where ECM_Payment_Summary_Status__c=\'Provisional\' and ECM_Start_Period__c<=TODAY and ECM_Contract__r.Account.country__r.code__c =: countryCode '
                      +'and (ECM_Type__c=\'Promo-Standard\' OR ECM_Type__c=\'Promo-PrePayment\' OR ECM_Type__c=\'Volume-Based\')';
        system.debug(LoggingLevel.DEBUG,'query--->'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<ECM_Payment_Summary__c> paymentSumRecords){
        list<ECM_Payment_Summary__c> paySumlist = new list<ECM_Payment_Summary__c>();
        try{
            /*Part of ECM-4515 */
            map<Id,Market_Setting__c> mapOfMarSet = new map<Id,Market_Setting__c>();
            Map<id,ECM_Payment_Summary__c> paySummaryMap = new Map<id,ECM_Payment_Summary__c>(); 
            map<Id,User> userMap = new map<Id,User>();
            List<ECM_Payment_Summary__c> paySumRecords = new List<ECM_Payment_Summary__c>(); //List of PaymentSummaries to be Opened
            
            //142555
            
            paySumRecords.addAll(getPSData(mapOfMarSet,userMap,paymentSumRecords));
            /* End of ECM-4515*/
            WrapperClass wrap = new WrapperClass();
            wrap.mapOfMarSet = mapOfMarSet;
            wrap.userMap = userMap;
            
            paySumlist.addAll(loopingLogic(paySumRecords,wrap,paySummaryMap));
            
            system.debug(LoggingLevel.DEBUG,'paySumlist'+paySumlist);
            if(!(paySumlist.isEmpty())){
                //142555
                updatePaySum(paySumlist,paySummaryMap);
            }
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
        
    }

    public List<ECM_Payment_Summary__c> loopingLogic(List<ECM_Payment_Summary__c> paySumRecords,WrapperClass wrap,Map<id,ECM_Payment_Summary__c> paySummaryMap){
        
        map<Id,Market_Setting__c> mapOfMarSet = wrap.mapOfMarSet;
        map<Id,User> userMap = wrap.userMap;
        
        list<ECM_Payment_Summary__c> paySumlist = new list<ECM_Payment_Summary__c>();

        for(ECM_Payment_Summary__c ps : paySumRecords){
            if(ps.ECM_Type__c=='Promo-PrePayment' && !ps.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Prepayment_SR_approval__c){
                ps = prePaymentLogic(ps,mapOfMarSet,userMap);
            }
            
            if(ps.ECM_Type__c=='Promo-Standard' || ps.ECM_Type__c=='Volume-Based' || (ps.ECM_Type__c=='Promo-PrePayment' && ps.ECM_Contract__r.ECM_Agreement_Type__r.ECM_Prepayment_SR_approval__c )){
                ps.ECM_Payment_Summary_Status__c='Open';  
                paySummaryMap.put(ps.id,ps);
                
            }
            
            paySumlist.add(ps);
        }

        return paySumlist;
    }

    public ECM_Payment_Summary__c prePaymentLogic(ECM_Payment_Summary__c ps,map<Id,Market_Setting__c> mapOfMarSet,map<Id,User> userMap){
        System.debug(LoggingLevel.DEBUG,'@@ Inside if');
        System.debug(LoggingLevel.DEBUG,ps.ECM_Payment_Summary_Status__c);
        //Part of ECM-4515
        list<String> managerApprovalPsTypes = new list<String>();
        User loggedUser = userMap.containsKey(ps.ECM_Contract__r.CreatedById)?userMap.get(ps.ECM_Contract__r.CreatedById):new User();
        if(mapOfMarSet.containsKey(ps.ECM_Contract__r.Account.Country__c) && mapOfMarSet.get(ps.ECM_Contract__r.Account.Country__c).ECM_Manager_Approval__c !=Null){
            managerApprovalPsTypes = mapOfMarSet.get(ps.ECM_Contract__r.Account.Country__c).ECM_Manager_Approval__c.split(';');
        }                    
        ps.ECM_Manager_Approver__c = (managerApprovalPsTypes.contains(ps.ECM_Type__c) && loggedUser.ManagerId!=Null)?loggedUser.Manager.DelegatedApproverId!=Null?loggedUser.Manager.DelegatedApproverId:loggedUser.ManagerId:null;//ECM-6710
        ps.ECM_Payment_Summary_Status__c=ps.ECM_Manager_Approver__c!=null?'In Approval process':'Submitted';
        System.debug(LoggingLevel.DEBUG,ps.ECM_Payment_Summary_Status__c);
        
        ps = approvalSubStatusCheck(ps);
        //End of ECM-4515

        return ps;
    }

    public ECM_Payment_Summary__c approvalSubStatusCheck(ECM_Payment_Summary__c ps){
        ps.ECM_Approval_Sub_Status__c = ps.ECM_Payment_Summary_Status__c == 'In Approval process'?Label.ECM_In_Manager_Approval:
        ps.ECM_Payment_Summary_Status__c == 'Submitted'?Label.ECM_CIO_Approval:ps.ECM_Approval_Sub_Status__c;
        
        System.debug(LoggingLevel.DEBUG,ps.ECM_Approval_Sub_Status__c);

        return ps;
    }
    
    //142555
    public List<ECM_Payment_Summary__c> getPSData(map<Id,Market_Setting__c> mapOfMarSet, map<Id,User> userMap, List<ECM_Payment_Summary__c> paymentSumRecords){
        set<Id> countryIds = new set<Id>();
        set<Id> userIds = new set<Id>();
        list<ECM_Payment_Summary__c> paySumRecords = new List<ECM_Payment_Summary__c>();
        
        //ECM-5164 starts - ECM_PFforEndDateBasedStatusChangePS : All PF with Retrospective Suffix & At the end of Contract
        for(ECM_Payment_Summary__c psRec : paymentSumRecords){
            Boolean endDateBasedPS = (psRec.ECM_Payment_Frequency__r.ECM_Type__c!=NULL && 
                                      System.Label.ECM_PFforEndDateBasedStatusChangePS.replace('\r\n','').split(',').contains(
                                          psRec.ECM_Payment_Frequency__r.ECM_Type__c)) ? true : false;
            if(!endDateBasedPS || (endDateBasedPS && psRec.ECM_End_Period__c <= System.today())){
                paySumRecords.add(psRec);
            }
        }
        //ECM-5164 ends
        
        for(ECM_Payment_Summary__c paySum:paySumRecords){
            countryIds.add(paySum.ECM_Contract__r.Account.Country__c);
            userIds.add(paySum.ECM_Contract__r.CreatedById);
        }
        
        mapOfMarSet.putAll(getMarketSetting(countryIds));

        for(User usr :[SELECT Id,ManagerId,Manager.DelegatedApproverId FROM User where Id IN:userIds]){
            userMap.put(usr.Id,usr);  
        }//ECM-6710
        
        return paySumRecords;
    }

    public map<Id,Market_Setting__c> getMarketSetting(set<Id> countryIds){
        map<Id,Market_Setting__c> mapOfMarSet = new map<Id,Market_Setting__c>();

        for(Market_Setting__c marSet : [SELECT Id,Geography__c,ECM_Manager_Approval__c FROM Market_Setting__c Where Geography__c IN:countryIds ]){
            mapOfMarSet.put(marSet.Geography__c,marSet);
        }
        return mapOfMarSet;
    }
    
    //finish method
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_PaymentSummaryStatusChangeBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        if(!psSuccessList.isEmpty()){
            sendPSOpenEmailToSalesRep(psSuccessList);
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
     public static void sendPSOpenEmailToSalesRep(List<ECM_Payment_Summary__c>sendPSOpenEmailList){
        
        try{
                List<Messaging.SingleEmailMessage> emailList= new List<Messaging.SingleEmailMessage>();
                List<Emailtemplate> emailtemplateList=[select id from emailtemplate where developername='ECM_PaymentSummary_Open'];
                for(ECM_Payment_Summary__c paySum: sendPSOpenEmailList){
                    
                    Messaging.SingleEmailMessage email= new Messaging.SingleEmailMessage();
                    email.setTemplateid(emailtemplateList[0].Id);
                    email.setTargetObjectid(paySum.ecm_contract__r.ownerId);
                    email.setwhatId(paySum.id);
                    email.setToAddresses(new List<String>{paySum.ecm_contract__r.owner.email});
                    email.setSaveAsActivity(false);
                    emailList.add(email);
                    
                }
                        Messaging.SendEmailResult[] r = Messaging.sendEmail(emailList); //NOPMD
            }catch(Exception ex){
                System.debug(LoggingLevel.DEBUG,'Exception Caught at Line: '+ex.getLineNumber()+'\n Error: '+ex.getMessage());
            }        
    }
        
    //142555
    public void updatePaySum(List<ECM_Payment_Summary__c> paySumlist, Map<id,ECM_Payment_Summary__c> paySummaryMap){
        try{
            Database.SaveResult[] srList= Database.update(paySumlist);
            for(Database.SaveResult sr:srList){
                if(sr.isSuccess() && paySummaryMap.containsKey(sr.getId()) ){
                    psSuccessList.add(paySummaryMap.get(sr.getId()));
                }
            }
        }catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
            System.debug(LoggingLevel.DEBUG,'Method:updatePaySum - Exception Caught at Line: '+ex.getLineNumber()+'\n Error: '+ex.getMessage());
            
        }
    }
    
    public class WrapperClass{
        public map<Id,Market_Setting__c> mapOfMarSet;
        public map<Id,User> userMap;
        
        public WrapperClass(){
            this.mapOfMarSet = new map<Id,Market_Setting__c>();
            this.userMap = new map<Id,User>();
        }
    }
}