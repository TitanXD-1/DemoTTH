/**
* @Description :  EDGE_CreateTempAccessForOldUserCTBatch
* @Purpose : When there is a change in territory for outlet or territory member, this batch provides temporary access to old reps for the outlets if user has open, pending case tasks
* @History :
* Version    Developer         Date           User Story/Purpose
*  1.0       Saranya L       23/05/2022       Initial Development(ES20-12764)
**/

public class EDGE_CreateTempAccessForOldUserCTBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string countryCode;
    string exceptionMsg = '';
    Id marketBatchJobId;
    static String  qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    public static List<String> caseTaskStatusList = new List<String> {'Open','Pending'};
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    /* Start Method */   
    public Database.QueryLocator start(Database.BatchableContext bc){        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        
        countryCode = batchSetting.Country_Code__c;
        String strQuery = 'SELECT Id,Outlet__c,Outlet_Role__c,User__c,Business_Role__c,CreatedDate,LastModifiedDate,Flag_For_Deletion__c,Temporary_Assigned__c FROM Outlet_Member__c WHERE Flag_For_Deletion__c = true  AND Outlet__r.Country__r.Code__c=:countryCode AND User__r.IsActive=true AND (User__r.Profile.Name != \'Sales Manager\' OR User__r.Profile.Name != \'Quality Manager\')';
        return Database.getQueryLocator(strQuery);
    }
    /* Execute Method*/
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        Map<Id,Outlet_Member__c> outletMemToUpdate = new Map<Id, Outlet_Member__c>();
        Map<Id,Outlet_Member__c> outletMemMap = new Map<Id, Outlet_Member__c>();
        Set<ID> userIdsSet= new set<ID>();
        Set<ID> outletIdsSet= new set<ID>();
        Map<String, Outlet_Member__c> userOutletMap = new Map<String, Outlet_Member__c>();
        Map<String,Integer> totalCaseTaskMap = new Map<String,Integer>();
        try{    
            for(sObject sObj:scope){
                Outlet_Member__c outletmember = (Outlet_Member__c)sObj;
                if(outletmember.User__c !=null && outletmember.Outlet__c !=null){
                    userIdsSet.add(outletmember.User__c);
                    outletIdsSet.add(outletmember.Outlet__c);
                    if(!userOutletMap.ContainsKey(outletmember.User__c + '_' + outletmember.Outlet__c)){
                        userOutletMap.put(outletmember.User__c + '_' + outletmember.Outlet__c,outletmember);//creating a map of outlet member records with user and outlet combination as key
                    }
                }
            }
            //Fetching the count of open, pending Case Tasks assigned to a user for a particular outlet and storing it in a map
            for(sobject cstList : [SELECT User_Assigned_To__c,Account__c,count(Id) from Case_Task__c WHERE Achievement_Status__c IN :caseTaskStatusList AND Case__c !=NULL
                                   AND User_Assigned_To__c IN:userIdsSet AND Account__c IN :outletIdsSet AND 
                				   User_Assigned_To__c != NULL and Account__c != NULL AND Achievement_Status__c != NULL AND Case__r.RecordTypeId =:qualityRecordTypeId
                                   group by User_Assigned_To__c ,Account__c]){
                                       totalCaseTaskMap.put((String) cstList.get('User_Assigned_To__c') + '_' + (String) cstList.get('Account__c'), (Integer)cstList.get('expr0'));
                                       //mapping the user,account and the count of open or pending case tasks under the user,account
                }
            
            //Making the Outlet Member as temporaryly assigned User and marking Flag For Deletion as false
            if(userOutletMap != null && userOutletMap.size()>0 && totalCaseTaskMap != null && totalCaseTaskMap.size()>0){
                for(String uniKey : userOutletMap.KeySet()){
                    if(totalCaseTaskMap.containskey(uniKey)){
                        if(totalCaseTaskMap.get(uniKey) != 0){
                            Outlet_Member__c outMemRec = userOutletMap.get(uniKey);
                            outMemRec.Flag_For_Deletion__c = false;
                            outMemRec.Temporary_Assigned__c = true;
                            outletMemToUpdate.put(outMemRec.Id,outMemRec);
                        }
                    }
                }
            }
            // Updating the Outlet Member Records
            if(outletMemToUpdate != null && outletMemToUpdate.size()>0){
                Database.update(outletMemToUpdate.values(),false);  
            }
        }
    	catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
	}
	public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_CreateTempAccessForOldUserCTBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }

        //Schedule Next Batch from Batch Utility Class
         if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
         }
    }
    
}