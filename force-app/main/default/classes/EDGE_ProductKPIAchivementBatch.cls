/**
* @Name: EDGE_ProductKPIAchivementBatch
* @Req: 
* @ES20-4589 - Actuals and Achievement Calculation for Product Level KPIs
* @History                                                            
* @VERSION     AUTHOR              DATE              DETAIL
	1.0         Dipanjan D          12/12/2019        ES20-4589
	2.0			Kapil Baliyan	    30/12/2019	      Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
	3.0         Monalisa Halder     17/10/2022        [ES20-13380]
*/
public class EDGE_ProductKPIAchivementBatch implements Database.Batchable<sObject>,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    Set<Id> territoryIdSet;
    Set<Id> territoryId = new Set<Id>();
    List<Territory__c> processedTerrLst = new List<Territory__c>();
    Set<Id> processedTerrSet = new Set<Id>();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        String territoryType='Sales';        
        String countryCode = batchSetting.Country_Code__c; 
        String activeStatus='Active';
        Boolean pendingforBatch = true ;  
        
        //Get sales territories        
        String queryString='SELECT ID, Country__c, Region__c FROM Territory__c WHERE Territory_Type__c =:territoryType AND Country__r.Code__c =:countryCode AND Pending_For_Batch__c =:pendingforBatch AND Status__c =:activeStatus';        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Territory__c> scope){ 
        Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>();
        try{
            for(Territory__c territory : scope){
                territoryMap.put(territory.Id, territory);
            }

            if(territoryMap != null && territoryMap.size() > 0){
                EDGE_ProductKPIAchivementOperations.calculateProductKPIAchivements(territoryMap);
                  
            }
            if(territoryMap != null && territoryMap.size() > 0){
                for(Id terrId : territoryMap.keyset()){
                    if(!processedTerrSet.contains(terrId)){
                        processedTerrSet.add(terrId);
                        
                    }
                }
            }
            
           /* if(Test.isRunningTest()){ 
				processedTerrLst[0].Territory_Type__c = 'Sales1';
				update processedTerrLst[0];                 
                throw new EDGE_GenericException();
            }*/
        }
        /*catch(DmlException de){ 
            
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
           
        }*/
        catch(Exception ex){            
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_ProductKPIAchivementBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            //ES20-13380 Added
            if(processedTerrSet != null && !processedTerrSet.isEmpty()){
                for(Id terrId : processedTerrSet){
                    Territory__c territoryobj = new Territory__c(Id = terrId);
                    territoryobj.Pending_For_Batch__c = false;
                    processedTerrLst.add(territoryobj); 
                }
                //system.debug('@@processedTerrLst'+processedTerrLst);  
            }
            
            if(processedTerrLst != null && processedTerrLst.size()>0 && Schema.sObjectType.Territory__c.isUpdateable()){
               Database.update(processedTerrLst,false);
             }
        }

        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}