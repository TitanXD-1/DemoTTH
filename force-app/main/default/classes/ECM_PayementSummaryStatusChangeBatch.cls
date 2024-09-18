/**********************************************************************
Name: ECM_PayementSummaryStatusChangeBatch
Test Class :ECM_PayementSummaryStatusChangeBatchTest
=======================================================================
Purpose:This class is used to change the status of PayementSummaries
=======================================================================
History                                                            
-------                                                            
AUTHOR				   DATE              DETAIL
Pravalika			02/03/2021		PS remodelling_EU_Logic_PS summary status change flow
Saurav Prasad		15/06/2021		ECM-4515 - Assign manager approval on ps record based on it's corresponding market.	
***********************************************************************/
global class ECM_PayementSummaryStatusChangeBatch  implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    global Database.QueryLocator start(Database.BatchableContext bc) {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        String query=  'SELECT Id,ECM_End_Period__c,ECM_Type__c,ECM_Contract__r.Account.Country__c,ECM_Contract__r.CreatedById FROM ECM_Payment_Summary__c where ECM_Payment_Summary_Status__c=\'Provisional\' and ECM_End_Period__c<=TODAY and ECM_Contract__r.Account.country__r.code__c =: countryCode and (ECM_Type__c=\'Promo-Standard\' OR ECM_Type__c=\'Promo-PrePayment\' OR ECM_Type__c=\'Volume-Based\')' ;
        system.debug('queryss'+query);
        return Database.getQueryLocator(query);
    }
    global void execute(Database.BatchableContext bc, List<ECM_Payment_Summary__c> paySumRecords){
        list<ECM_Payment_Summary__c> paySumlist = new list<ECM_Payment_Summary__c>();
        try{
            /*Part of ECM-4515 */
            set<Id> countryIds = new set<Id>();
            set<Id> userIds = new set<Id>();
            map<Id,Market_Setting__c> mapOfMarSet = new map<Id,Market_Setting__c>();
            
            for(ECM_Payment_Summary__c paySum:paySumRecords){
                countryIds.add(paySum.ECM_Contract__r.Account.Country__c);
                userIds.add(paySum.ECM_Contract__r.CreatedById);
            }
            
            for(Market_Setting__c marSet : [SELECT Id,Geography__c,ECM_Manager_Approval__c FROM Market_Setting__c Where Geography__c IN:countryIds ]){
                mapOfMarSet.put(marSet.Geography__c,marSet);
            }
            
            map<Id,User> userMap = new map<Id,User>([SELECT Id,ManagerId FROM User where Id IN:userIds]);
            /* End of ECM-4515*/
            for(ECM_Payment_Summary__c ps : paySumRecords){
                if(ps.ECM_Type__c=='Promo-PrePayment'){
                    //Part of ECM-4515
                    list<String> managerApprovalPsTypes = new list<String>();
                    User loggedUser = userMap.containsKey(ps.ECM_Contract__r.CreatedById)?userMap.get(ps.ECM_Contract__r.CreatedById):new User();
                    if(mapOfMarSet.containsKey(ps.ECM_Contract__r.Account.Country__c) && mapOfMarSet.get(ps.ECM_Contract__r.Account.Country__c).ECM_Manager_Approval__c !=Null){
                        managerApprovalPsTypes = mapOfMarSet.get(ps.ECM_Contract__r.Account.Country__c).ECM_Manager_Approval__c.split(';');
                    }
                    ps.ECM_Manager_Approver__c = (managerApprovalPsTypes.contains(ps.ECM_Type__c) && loggedUser.ManagerId!=Null)?loggedUser.ManagerId:null;
                    ps.ECM_Payment_Summary_Status__c=ps.ECM_Manager_Approver__c!=null?'In Approval process':'Submitted'; 
                    //End of ECM-4515
                    
                }
                if(ps.ECM_Type__c=='Promo-Standard' || ps.ECM_Type__c=='Volume-Based'){
                    ps.ECM_Payment_Summary_Status__c='Open';  
                    
                }
                
                paySumlist.add(ps);
                
            }
            system.debug('paySumlist'+paySumlist);
            if(!(paySumlist.isEmpty())){
                
                Database.update(paySumlist);
            }
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
        
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_PayementSummaryStatusChangeBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    } 
}