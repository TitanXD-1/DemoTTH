/*
* @Name: EDGE_OutletExecutionsHistoricKPIBatch
* @Req: User Story - ES20-5362
* @History                                                            
* @VERSION      AUTHOR             DATE              		DETAIL
*  1.1			Vikas Anand        13/11/2019		        Create a new record of Outlet Execution Historic on the
                                                    		1st of every month for all Active Outlets.
*  2.0			Kapil Baliyan	   30/12/2019	  	 		Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*  3.0          Rai Kant           11/05/2022      			Update Called on and In Contract.
*  4.0          Wribhu Bose        12/12/2022               Changes for ECM-6396
*/

public class EDGE_OutletExecutionsHistoricKPIBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
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
        Id outletRecTypeId = Schema.SObjectType.Account.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();
        String outletContractRecordType = Label.ECM_Outlet_Contract_RecordType;
        List<String> activeStatusType = Label.ECM_AnniversaryContractStatus.split(',');
        String strQuery = 'SELECT Id, Name, Date_of_Execution__c, Outlet_Execution_Score__c, Distribution__c, Minimum_Activation_Standards__c,' +
            'Minimum_Product_Assortment__c, New_Product_Distribution__c, Called_on__c, (Select Id from Contracts where Status IN :activeStatusType and recordType.Name =: outletContractRecordType) FROM Account WHERE Country_Code__c  =:countryCode AND recordTypeId =:outletRecTypeId AND Status__c IN :activeStatusType';
        
        return Database.getQueryLocator(strQuery);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Account> lstOfOutlet){ 
        Integer month = Date.today().month();
        Integer year = Date.Today().Year();
        String dt = string.valueOf(month) + '/' + string.valueof(year);
        Id outletKPIRecTypeId = Schema.SObjectType.Outlet_Execution_Historic__c.getRecordTypeInfosByDeveloperName().get('Outlet_KPI').getRecordTypeId();
        List<Outlet_Execution_Historic__c> outletExHisListtoInsert = new List<Outlet_Execution_Historic__c>();
        
        try{
            if(lstOfOutlet != null && lstOfOutlet.size()>0){
                for(Account outlet : lstOfOutlet){
                    String outletName=outlet.Name;
                    Outlet_Execution_Historic__c outletKPIRec = new Outlet_Execution_Historic__c();
                    outletKPIRec.RecordTypeId = outletKPIRecTypeId;
                    If(outletName.length()>70){
						outletName=outletName.SubString(0,70);
					}	
                    /** Start: Changes as per ECM-5474*/
                    if(outlet.Called_on__c){
                        outletKPIRec.ECM_Called_On__c = true;
                    }else{
                        outletKPIRec.ECM_Called_On__c = false;
                    }

                    if(outlet.Contracts.size()>0){
                        outletKPIRec.ECM_In_Contract__c = true;
                    }else{
                        outletKPIRec.ECM_In_Contract__c = false;
                    }
                    /** End: Changes as per ECM-5474*/
                    outletKPIRec.Name = outletName + '-' + dt;
                    outletKPIRec.Outlet__c = outlet.Id;
                    outletKPIRec.Unique_Id__c=string.valueOf(month)+string.valueOf(year)+outlet.id;
                    outletKPIRec.Date_of_Execution__c = Date.today();
                    outletKPIRec.Distribution__c = outlet.Distribution__c;
                    outletKPIRec.Minimum_Activation_Standards__c = outlet.Minimum_Activation_Standards__c;
                    outletKPIRec.Minimum_Product_Assortment__c = outlet.Minimum_Product_Assortment__c;
                    outletKPIRec.New_Product_Distribution__c = outlet.New_Product_Distribution__c;
                    outletKPIRec.Outlet_Execution_Score__c = outlet.Outlet_Execution_Score__c;
                    
                    outletExHisListtoInsert.add(outletKPIRec);
                }
            }
            
            if(outletExHisListtoInsert != null && outletExHisListtoInsert.size()>0){
                upsert outletExHisListtoInsert Unique_Id__c;
            }
        }catch(Exception ex){
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletExecutionsHistoricKPIBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}