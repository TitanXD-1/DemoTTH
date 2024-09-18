/**
 * @ Name: EDGE_OutletKPIAchievementCalcBatch
 * @ Req: Calculate Outlet KPI Achievement
 * @ History    
 * @ VERSION   AUTHOR            	 DATE              DETAIL
 * @ 1.0      Monalisa Halder     08/01/2020     Initial Development(ES20-9195)
 * @ 2.0	  Saranya L			  29/11/2021	 ES20-11036( Extending to quality) 
 * @ 3.0      Anand Uppalapati    03/01/2022     ES20-11915
 * @ 4.0      Subhodeep Sarkar    10/02/2022     ES20-11839
 * @ 5.0      Joshraj Sen         25/02/2022     ES20-12177
 * @ 6.0	  Saranya L			  22/02/2022	 ES20-12222(Included activation territory)
 * @ 7.0      Monalisa Halder     02/11/2022     ES20-13380
**/
public class EDGE_OutletKPIAchievementCalcBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId; 
    //commented for ES20-13380
    /*List<Territory__c> processedTerrLst = new List<Territory__c>();
    Set<Territory__c> processedTerrSet = new Set<Territory__c>();*/
    Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>();
    List<Territory__c> territoryList = new List<Territory__c>();
    Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
    set<Id> territorySetIds = new Set<Id>();
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  //Update ES20-6594  
        String territoryType='Sales';
        String countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        Boolean batchPending = true;   //filter added to process those territories only whose Pending_For_Batch__c is true 
        List<String> allowedKPITypes = new List<String>{'SOS','Volume'};
        
        territoryList = [SELECT ID,Pending_For_Batch__c,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c,
                         Distribution_Target__c, Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c,RecordType.Name,
                         (SELECT Id, Volume_Category_Premium_Core_Target__c, Volume_Category_Deluxe_Target__c, Volume_Category_Reserve_Target__c, Volume_Category_RTD_Target__c,
                          Volume_Category_Super_Deluxe_Target__c, Volume_Target_Value__c FROM Territory_Cycles__r WHERE Market_Cycle__r.Active__c = TRUE)
                         FROM Territory__c WHERE (RecordType.Name IN ('Sales Territory','Quality Territory','Activation Territory')) AND Country__r.Code__c =:countryCode
                         AND Pending_For_Batch__c =:batchPending AND Status__c =:activeStatus];// Added activation territory for ES20-12222
        
        if(territoryList != null && territoryList.size()>0){
            for(Territory__c territory : territoryList){
                territoryMap.put(territory.Id, territory);
                if(territory.Territory_Cycles__r != null && territory.Territory_Cycles__r.size() > 0){
                    territoryWithCycleMap.put(territory.Id, territory.Territory_Cycles__r[0]);	
                }
            }
        }
        territorySetIds = territoryMap.keySet();
       
                
        String queryString='SELECT Outlet__r.Primary_Sales_Territory__c, KPI_Type__c, Category__c, Volume_Category__c, Total_Denominator__c,' +
            + ' Actual_Numerator__c, Achievement__c, Previous_Achievement__c, Target__c,Target_Number__c, Last_Compliant_Call_Date__c,Valid__c,Territory__c FROM Outlet_KPI_Achievement__c' +
            + ' WHERE ((Outlet__r.Primary_Sales_Territory__c IN :territorySetIds) OR (Outlet__r.Activation_Territory_LT__c  IN :territorySetIds) OR (KPI_Type__c IN :allowedKPITypes))' +
            + ' AND Outlet__r.Country__r.Code__c = :countryCode '+
            + ' AND Outlet__r.Status__c =:activeStatus ORDER BY Outlet__r.Primary_Sales_Territory__c DESC,Category__c DESC,Outlet__r.Activation_Territory_LT__c DESC';
        system.debug('queryString::'+queryString);
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Outlet_KPI_Achievement__c> outletKPIAchievementList){     	
        try{
            Set<Id> outletIds = new Set<Id>();
            List<Outlet_KPI_Achievement__c> revisedOutletKPIAchievementList = new List<Outlet_KPI_Achievement__c>();
            Map<Id, Territory__c> reducedTerritoryMap = new Map<Id, Territory__c>();
            Set<Id> revisedOutletIds = new Set<Id>();
            Set<Id> okpiIdsSet = new Set<Id>();
            List<Territory__c> territoryListperOutlet=new List<Territory__c>();
                
            for(Outlet_KPI_Achievement__c outKpi:outletKPIAchievementList){
                outletIds.add(outKpi.Outlet__c);
            }
            Map<Id, List<Territory__c>> outletToTerritoryMap = new Map<Id, List<Territory__c>>();
            if(outletIds!=null && outletIds.size()>0){
                for(Outlet_Territory__c outletTerr : [SELECT Id, Territory__c,Territory__r.Region__c, Outlet__c from Outlet_Territory__c 
                                                      WHERE Outlet__c IN :outletIds 
                                                      AND Outlet__r.Status__c = :EDGE_Constant.ACTIVE
                                                      AND Active__c = :EDGE_Constant.ACTIVE])
                {
                    
                    Territory__c terr = new Territory__c(Id=outletTerr.Territory__c,Region__c=outletTerr.Territory__r.Region__c);
                    if(territorySetIds.contains(terr.Id)){
                        terr.Pending_For_Batch__c = true;
                    }
                    if(outletToTerritoryMap.containsKey(outletTerr.outlet__c)){
                        outletToTerritoryMap.get(outletTerr.outlet__c).add(terr);
                    }
                    else{
                        outletToTerritoryMap.put(outletTerr.outlet__c, new List<Territory__c>{terr});
                    }
                }
            }
            for(Outlet_KPI_Achievement__c outKpi:outletKPIAchievementList){
                Id outletId = outKpi.Outlet__c;
                if(outletToTerritoryMap.containsKey(outletId)){          //ES20-11915
                    territoryListperOutlet=outletToTerritoryMap.get(outletId);
                    if(territoryListperOutlet!=null && territoryListperOutlet.size()>0){
                        for(Territory__c terr  : outletToTerritoryMap.get(outletId)){
                            if(terr.Pending_For_Batch__c){
                                if(!okpiIdsSet.contains(outKpi.Id)){
                                    revisedOutletKPIAchievementList.add(outKpi);
                                }
                                reducedTerritoryMap.put(terr.Id,terr);
                                revisedOutletIds.add(outKpi.Outlet__c);
                                okpiIdsSet.add(outKpi.Id);
                            }
                        }
                    }
                }
            }
            List<KPI_Achivement__c> kpiAchvmntList = new List<KPI_Achivement__c>();
            List<KPI_Achivement__c> kpiAchvmntSalesList = new List<KPI_Achivement__c>();
            List<KPI_Achivement__c> kpiAchvmntQalityList = new List<KPI_Achivement__c>();
            if(territoryMap != null && territoryMap.size() > 0 ){
                kpiAchvmntList = EDGE_KPIAchivementOperations.calculateSOSandVolumeCategoryKPIAchivements(reducedTerritoryMap,territoryWithCycleMap,revisedOutletKPIAchievementList, batchSetting.Country_Code__c,revisedOutletIds);
            }
            //commented for ES20-13380
            /*for(Id terrId : territoryMap.keyset()){
                Territory__c territoryobj = new Territory__c(Id = terrId);
                territoryobj.Pending_For_Batch__c = false;//marking the field Pending for Batch false
                if(!processedTerrLst.contains(territoryobj)){
                    processedTerrLst.add(territoryobj);    
                }
            }*/
            if(kpiAchvmntList != null && kpiAchvmntList.size() > 0){
                List<Database.upsertResult> uResults = Database.upsert(kpiAchvmntList,false);
                //System.debug('uResults : '+ uResults);
                for(Database.upsertResult result:uResults) {
                    /*if (result.isSuccess()) {
                        System.debug('sucess : result.getId() : '+ result.getId());
                        System.debug('sucess : result : '+ result);
                    }*/
                    if (!result.isSuccess()) {
                        System.debug('failure : result.getId() : '+ result.getId());
                        System.debug('failure : result : '+ result);
                    }
                }
                
            }
                
            
        }
        catch(DmlException de){
            System.debug('DML Exception :'+ de.getStackTraceString());
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex) {
            System.debug('Exception :'+ ex.getStackTraceString());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    //Update ES20-6594
    public void finish(Database.BatchableContext bc){ 
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_OutletKPIAchievementCalcBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            //commented for ES20-13380
            /*if(processedTerrLst != null && processedTerrLst.size()>0 && Schema.sObjectType.Territory__c.isUpdateable()){
                //system.debug('@@processedTerrLst' +processedTerrLst);
                Database.update(processedTerrLst,false);
            }*/
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}