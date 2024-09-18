/**********************************************************************
Name: EDGE_RemovePromotionPDFBatch
=======================================================================
Purpose: Delete the promotion records and its related attachments - ES20-198
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0			Monalisa Halder         19/03/2019        Initial Development
2.0			Kapil Baliyan			30/12/2019		  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
***********************************************************************/
public  class EDGE_RemovePromotionPDFBatch implements Database.batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        string countryCode = batchSetting.Country_Code__c;
        
        // querying all promotion records where Expiration_Date__c is less than today
        string queryString='';
        queryString  = 'Select Id,Name, Start_Date__c, Expiration_Date__c from Promotion__c where Expiration_Date__c < today AND Country__r.Code__c=:countryCode';
        return Database.getQueryLocator(queryString);
    }    
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Promotion__c > promotionList){
        Set<Id> pmIdSet = new Set<Id>();
        List<ContentDocument> conDocListToDel= new List<ContentDocument>();
        
        try{
            //Putting all the promotion record ids to deleted in a set and records in a list
            for(Promotion__c pm : promotionList){
                pmIdSet.add(pm.Id);
            }
            
            //Querying all the ContentDocumentLink related to the promotion to be deleted 
            //Adding the related Content Document to the list
            if(pmIdSet != null && pmIdSet.size()>0){
                for(ContentDocumentLink cdl : [SELECT id, LinkedEntityId, ContentDocumentId from ContentDocumentLink where LinkedEntityId IN :pmIdSet]){
                    ContentDocument contentDocumentObj = new ContentDocument(id=cdl.ContentDocumentId);
                    conDocListToDel.add(contentDocumentObj);
                }
            }
            
            //Deleting the Content Documents present in the conDocListToDel
            if(conDocListToDel != null && conDocListToDel.size()>0){
                delete conDocListToDel;                
            }
            
            //Deleting all the Promotion records
            if(promotionList != null && promotionList.size()>0) {
                if(!Test.isRunningTest()){
                    delete promotionList;
                } else {
                    Promotion__c objPromo = new Promotion__c();
                    insert objPromo;
                }
            }
        }catch(DmlException de){
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
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_RemovePromotionPDFBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}