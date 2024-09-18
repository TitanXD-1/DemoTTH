/**
*@	Class Name: EDGE_OutletKPIAchivmntUniqKeyUpdateBatch 

*@	Author              	Version       	  Date           Detail
*@	Amar Deep           	  V1.0          21/12/2020     [ES20-9194]
*@	Monalisa Halder           V1.0          18/11/2022     [ES20-13585]
*@	Shivam/Doman		 	  V2.0		    20/09/2023		145439
**/
public class EDGE_OutletKPIAchivmntUniqKeyUpdateBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    //ES20-13585
    //List<Account> processedAccountList = new List<Account>();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        countryCode = batchSetting.Country_Code__c;
        Boolean pendingtrue = true;
        //Add Sub segment
        ////145439 - added Country__c and Global_Channel__c in query String
        String queryString = 'SELECT Id,Primary_Sales_Territory__c,Country__c,Global_Channel__c,Global_Segment__c,Global_Sub_Segment__c,Pending_For_Outlet_KPI_Achievement__c FROM Account WHERE Country__r.Code__c =:countryCode AND Pending_For_Outlet_KPI_Achievement__c =: pendingtrue';
        
        return Database.getQueryLocator(queryString);
    
    }
    public void execute(Database.BatchableContext bc, List<Account> outletList){ 
        
        try{
            //ES20-13585
            List<Account> processedAccountList = new List<Account>();
            Set<Id> territoryIdSet = new Set<Id>();
            List<KPIs_Target__c> kpiTargetList = new List<KPIs_Target__c>();
            List<Outlet_KPI_Achievement__c> lstOutletKPIUpdate = new List<Outlet_KPI_Achievement__c>();
            List<Outlet_KPI_Achievement__c> lstOutletKPI = new List<Outlet_KPI_Achievement__c>();
            set<Id> outletSetIds = new set<Id>();
            if(outletList!=null && outletList.size()>0){
                for(Account outletRecd :outletList){
                    if(outletRecd.Primary_Sales_Territory__c != null){
                        territoryIdSet.add(outletRecd.Primary_Sales_Territory__c);
                        outletSetIds.add(outletRecd.Id);
                    }
                }
                if(territoryIdSet != null && territoryIdSet.size() > 0 && Schema.sObjectType.KPIs_Target__c.isAccessible() && Schema.sObjectType.Outlet_KPI_Achievement__c.isAccessible()){
                    lstOutletKPIUpdate = [SELECT Id, Unique_Id__c, Category__c, KPI_Type__c, Target__c, Outlet__c,Target_Override_Not_Allowed__c FROM Outlet_KPI_Achievement__c WHERE Outlet__c IN :outletSetIds AND KPI_Type__c = 'SoS'];
                    //Add sub segment field
                    kpiTargetList = [SELECT Id, Category__c, Segment__c,Sub_Segment__c, Target__c, Territory__c FROM KPIs_Target__c WHERE Territory__c IN :territoryIdSet];
                    lstOutletKPI = EDGE_KPITargetOperations.populateOutletKPIs(kpiTargetList, outletList,lstOutletKPIUpdate);
                    
                }
            }
          
            if(lstOutletKPI != null && lstOutletKPI.size()>0 && Schema.sObjectType.Outlet_KPI_Achievement__c.isCreateable() && Schema.sObjectType.Outlet_KPI_Achievement__c.isUpdateable()){
                Schema.SObjectField ftoken = Outlet_KPI_Achievement__c.Fields.Unique_Id__c;
                Database.upsert(lstOutletKPI,ftoken,true);
            }
            for(Account accRecd : outletList){
                Account accountobj = new Account(Id = accRecd.Id);
                accountobj.Pending_For_Outlet_KPI_Achievement__c = false;//marking the field Pending for Outlet KPI Achievement false
                processedAccountList.add(accountobj);
            }
                         
            if(processedAccountList != null && processedAccountList.size()>0 && Schema.sObjectType.Account.isUpdateable()){
              Database.update(processedAccountList,false);
            } 
        }
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug('StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletKPIAchivmntUniqKeyUpdateBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
          //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }

}