/**
* @Description :  EDGE_ContactManagementBatch

* @Purpose: Batch class for ContactManagement stories

* @History :

* @Version   Developer      Date       User Story	  Purpose
*   1.1      Aparajita    27/04/2022   ES20-12476     Regenerate contact sharing access after owner change

*/

public class EDGE_ContactManagementBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass 
{
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting)
    {
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        String query = '';
        string countryCode = batchSetting.Country_Code__c;
        query = 'SELECT Id, AccountId, Contact_Type__c, OwnerId, Owner_Changed__c, Contact_Shared__c FROM Contact WHERE Account.Country_Code__c =: countryCode '+
				'AND Owner_Changed__c = TRUE AND Contact_Shared__c = TRUE AND Id IN '+
            	'(SELECT ContactId FROM AccountContactRelation WHERE IsDirect = FALSE AND IsDeleted = FALSE AND IsActive = TRUE) '+
				'AND Id NOT IN (SELECT ContactId FROM ContactShare WHERE RowCause = \'Manual\')'; 
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Contact> contactList)
    {
        //Assignment
        Map<Id, AccountContactRelation> acrMap = new Map<Id, AccountContactRelation>();
        Map<Id, SObject> newACRMap = new Map<Id, SObject>();
        Set<Id> contactIdSet = new Set<Id>();
        Set<Contact> contactUpdateSet = new Set<Contact>();
        List<Contact> contactUpdateList = new List<Contact>();

        try{
            //Creating a set of contact Ids matching the entry criteria
            if(contactList!=null && contactList.size()>0){
                for(Contact cont : contactList)
                    contactIdSet.add(cont.Id);   
            }

            if(contactIdSet!=null && contactIdSet.size()>0){
                //Mapping the AccountContactRelation based on the entry criteria
                for(AccountContactRelation acr : [SELECT Id, AccountId, ContactId, IsDirect, IsDeleted, IsActive FROM AccountContactRelation WHERE ContactId IN : contactIdSet]){
                    acrMap.put(acr.Id, acr);
                }

                //Resetting the Owner_Changed__c flag to false and storing in a set to update later
                for(Contact con : [SELECT Id, Owner_Changed__c FROM Contact WHERE Id IN : contactIdSet]){
					con.Owner_Changed__c = FALSE;
					 contactUpdateSet.add(con);                  
                }
            }
			
			//Regenerating ContactSharing records            
            if(acrMap!=null && acrMap.size()>0){
                newACRMap = (Map<Id, SObject>)acrMap;
                EDGE_AccountContactRelationTriggerHelper.indirectContactShare(newACRMap,null);
            }
            
            //Updating Contact records
            if(contactUpdateSet!=null && contactUpdateSet.size()>0){
                contactUpdateList.addAll(contactUpdateSet);
                Database.update(contactUpdateList, false);
            }          
        }catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';  
        } 
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc)
    {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed')
            hasError = true;
        
        //Update Batch Job Status
        if(hasError)
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ContactManagementBatch', exceptionMsg);
        else
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);        
        }
    }
}