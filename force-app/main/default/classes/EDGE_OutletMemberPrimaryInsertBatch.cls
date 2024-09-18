/**

* @description :  EDGE_OutletMemberPrimaryInsertBatch

* @purpose : Batch Class for inserting primary outlet members

* @history :

* Version    Developer         Date           User Story/Purpose

*  1.1      Monalisa Halder   08/02/2021       ES20-9804
*  1.2      Mayukh SRoy       08/11/2022       ES20-13505
 
*/

public class EDGE_OutletMemberPrimaryInsertBatch implements Database.Batchable<EDGE_BatchSObjectWrapper>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceExtended{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    List<EDGE_BatchSObjectWrapper> scopeRecords;
    List<sObject> allRecords;
    
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting, List<Object> scopeRecords){
        this.batchSetting = batchSetting;
        this.scopeRecords = (List<EDGE_BatchSObjectWrapper>)scopeRecords;
    }
    
    
    
    //start method 
    public Iterable<EDGE_BatchSObjectWrapper> start(Database.BatchableContext bc){     
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        return scopeRecords;   
    }
    
    public void execute(Database.BatchableContext bc, List<EDGE_BatchSObjectWrapper> wrapperList){ 
        
       //Outlet_Member__c myOM = [SELECT Id from Outlet_Member__c where id = 'a0r0Q00000IZwFQQA1'];	//to test        

        EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch = true;
        
        List<Outlet_Member__c> outletMemberList = new List<Outlet_Member__c>();
        List<Outlet_Member__c> outletMemberToInsert = new List<Outlet_Member__c>();
        List<Outlet_Member__c> outletMemberToUpdate = new List<Outlet_Member__c>();
        
        for(EDGE_BatchSObjectWrapper wrapperItem : wrapperList){
            
            Outlet_Member__c outMember = (Outlet_Member__c)wrapperItem.recordToProcess;
            if(outMember.Pending_for_Rep_Insert_Batch__c){
                outletMemberList.add(outMember);
            }  
            if(wrapperItem.operationType == 'Insert'){               
                outletMemberToInsert.add(outMember);
                
            }
            if(wrapperItem.operationType == 'Update'){
                outletMemberToUpdate.add(outMember);
            }
        }
   
        if(outletMemberToUpdate.size() > 0){
            Database.update(outletMemberToUpdate, false);    
        }
        if(outletMemberToInsert.size() > 0){
            Database.insert(outletMemberToInsert, false);    
        }


        try{
            if(outletMemberList != null && outletMemberList.size()>0){
                EDGE_OutletMemberTriggerHelper.populatePrimarySalesDetails(outletMemberList,null);
                EDGE_OutletMemberTriggerHelper.createContactSharing(outletMemberList,null); //ES20-13505
            }
            
            EDGE_UtilityClass.printGovLimits(78);   
        }
        catch(Exception batchException){ 
            System.debug(LoggingLEVEL.DEBUG,'Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug(LoggingLEVEL.DEBUG,'StackTraceString '+ batchException.getStackTraceString());
            exceptionMsg += 'Line# ' + batchException.getLineNumber() + ' Message : ' + batchException.getMessage() + '\n';
            hasError = true;
        }
    }
    //finish method
    public void finish(Database.BatchableContext bc){
        EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch = false;
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletMemberPrimaryInsertBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
           EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
}