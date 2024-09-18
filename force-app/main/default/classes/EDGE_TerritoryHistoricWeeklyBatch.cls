/*
Name:EDGE_TerritoryHistoricWeeklyBatch

History                                                            
                                                          
VERSION   AUTHOR                   DATE              DETAIL
1.0       Dipanjan D               04/02/2020        ES20-6926 : SF_New weekly batch process for weekly KPI 
1.1       Amar Deep                13/07/2020        ES20-8248 
1.2       Mayukh SRoy              13/02/2023        ES20-13790 (fixing the batch faliure) 
*/
public class EDGE_TerritoryHistoricWeeklyBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
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
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  //Update ES20-6594 
        String territoryType='Sales'; 
        String countryCode = batchSetting.Country_Code__c;
        String activeStatus='Active';
        String weeklyKpis='Weekly_KPIs';
        String queryString = 'SELECT Id FROM Territory__c WHERE Territory_Type__c =:territoryType AND Country__r.Code__c =:countryCode AND Status__c =:activeStatus';
        return Database.getQueryLocator(queryString);
    }
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Territory__c> territoryList){ 
    
        List<Territory_Historic__c> terrHistoricListToUpdate = new List<Territory_Historic__c>(); 
        Set<String> kpiTypes = new Set<String>{'MAS','MPA','NPD','OES','Distribution','Total Activation Survey','Virtual Call Compliance'}; 
        Set<Id> territoryIds = (new Map<Id, Territory__c>(territoryList)).keySet();        
        Map<Id,List<KPI_Achivement__c>> territoryKPIAchivementMap = new  Map<Id,List<KPI_Achivement__c>>();
		Map<Id, Id> currentTerrHistoricMap = new Map<Id, Id>();
        Map<Id,Territory_Historic__c> prevTerrHistoricMap = new Map<Id,Territory_Historic__c>();
		Map<Id, Decimal> territoryWithCPDMap = new Map<Id, Decimal>();
		Map<Id, Integer> territoryWithCallsMap =  new Map<Id, Integer>();
		Map<Id, Integer> territoryWithOppsMap =  new Map<Id, Integer>();
        Date prevExeDate = system.today().addDays(-7).toStartOfWeek();
		Date currentExeDate = system.today().toStartOfWeek();
        //Territory_Historic__c newTerrHistRecord;
        List<KPI_Achivement__c> kpiAchivementList = [SELECT Id, Achievement__c, Current_National_Ranking__c, Country__c, KPI_Type__c, Territory__c FROM KPI_Achivement__c WHERE Territory__c IN :territoryIds AND recordType.developerName = 'Territory_KPI' AND KPI_Type__c IN :kpiTypes];
        Integer count=0;
        String territoryId='';
        //prepare a map between territory and different type of KPI present for that territory
        try{
           
            for(KPI_Achivement__c kpiAchvmntRecord : kpiAchivementList) {
                if(territoryKPIAchivementMap.containsKey(kpiAchvmntRecord.Territory__c)){
                    territoryKPIAchivementMap.get(kpiAchvmntRecord.Territory__c).add(kpiAchvmntRecord);
                } else{
                    territoryKPIAchivementMap.put(kpiAchvmntRecord.Territory__c, new List<KPI_Achivement__c>{kpiAchvmntRecord});
                }
            } 
            //query existing Territory Historic records for current month
            for(Territory_Historic__c terHisRecord : [SELECT Id,Territory_Name__c,Date_Of_Execution__c, National_MAS_Rank__c, National_MPA_Rank__c, National_OES_Rank__c FROM Territory_Historic__c WHERE Territory_Name__c IN :territoryKPIAchivementMap.keySet() AND recordType.developerName = 'Weekly_KPIs' AND (Date_Of_Execution__c = :prevExeDate OR Date_Of_Execution__c =:currentExeDate) ]){
				if(terHisRecord.Date_Of_Execution__c == prevExeDate){
					prevTerrHistoricMap.put(terHisRecord.Territory_Name__c,terHisRecord);					
				}else{
					currentTerrHistoricMap.put(terHisRecord.Territory_Name__c, terHisRecord.Id);
				}	
            }
			
			//Query on Territory Member for Calls per day
			for(Territory_Member__c terrMember : [SELECT Territory__c, User__r.Calls_Per_Day__c FROM Territory_Member__c WHERE Type__c = 'Primary' AND Start_Date__c <= Today AND (End_Date__c = null OR End_Date__c > Today) AND Territory__c IN :territoryKPIAchivementMap.keySet()]){
				territoryWithCPDMap.put(terrMember.Territory__c, terrMember.User__r.Calls_Per_Day__c);	
			}
			//Query on Call for Outlet Calls
			for(AggregateResult callPerformed : [SELECT count(Id) calls ,Account__r.Primary_Sales_Territory__c TerritoryId FROM Call__c WHERE Account__r.Primary_Sales_Territory__c IN : territoryKPIAchivementMap.keySet() AND Status__c = 'Completed' AND (End_Date__c >= :prevExeDate AND End_Date__c < Today) Group By Account__r.Primary_Sales_Territory__c]){//ES20-13790				
				count=(Integer)callPerformed.get('calls');
                territoryId=(Id)callPerformed.get('TerritoryId');
                territoryWithCallsMap.put(territoryId, count);
			}
			
			//Query on Opportunity for Opportunity Close
			for(AggregateResult opp : [SELECT count(Id) opps, Account.Primary_Sales_Territory__c TerritoryId FROM Opportunity WHERE Account.Primary_Sales_Territory__c IN : territoryKPIAchivementMap.keySet() AND (CloseDate >= :prevExeDate AND CloseDate < Today) Group By Account.Primary_Sales_Territory__c]){//ES20-13790
			    count=(Integer)opp.get('opps');
                territoryId=(Id)opp.get('TerritoryId');
				territoryWithOppsMap.put(territoryId,count);
			}
			
            String weeklyRecTypeId = Territory_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByDeveloperName().get('Weekly_KPIs').getRecordTypeId();
			
            //Iterate over all the KPI Achivement records
            for(Id terrId : territoryKPIAchivementMap.keySet()){ 			
				Territory_Historic__c terrHistoricRec = new Territory_Historic__c(Id = currentTerrHistoricMap.containsKey(terrId) ? currentTerrHistoricMap.get(terrId) : null);
				terrHistoricRec.Date_Of_Execution__c = currentExeDate;
				terrHistoricRec.Territory_Name__c = terrId;	
				terrHistoricRec.recordTypeId = weeklyRecTypeId;
				terrHistoricRec.Number_of_calls_per_day__c = territoryWithCPDMap.containsKey(terrId) ? territoryWithCPDMap.get(terrId) : null;
				terrHistoricRec.Outlet_Calls__c = territoryWithCallsMap.containsKey(terrId) ? territoryWithCallsMap.get(terrId) : null;
				terrHistoricRec.Opportunity_Close__c = territoryWithOppsMap.containsKey(terrId) ? territoryWithOppsMap.get(terrId) : null;
                for(KPI_Achivement__c kpiAchvmentRecord : territoryKPIAchivementMap.get(terrId)) {
                                        
                    switch on kpiAchvmentRecord.KPI_Type__c {
                        when 'Distribution'{
                            terrHistoricRec.Distribution__c = kpiAchvmentRecord.Achievement__c; 
                        }
                        when 'MAS'{
                            terrHistoricRec.Minimum_Standard_Activations__c = kpiAchvmentRecord.Achievement__c;
                            terrHistoricRec.National_MAS_Rank__c = kpiAchvmentRecord.Current_National_Ranking__c;
                            if(prevTerrHistoricMap.containsKey(kpiAchvmentRecord.Territory__c)){
                                terrHistoricRec.MAS_Performance_Indicator__c = getIndicator(terrHistoricRec.National_MAS_Rank__c, prevTerrHistoricMap.get(kpiAchvmentRecord.Territory__c).National_MAS_Rank__c);
                            }else{
                                terrHistoricRec.MAS_Performance_Indicator__c = 'Same';
                            }
                        }   
                        when 'MPA'{
                            terrHistoricRec.Minimum_Product_Assortment__c = kpiAchvmentRecord.Achievement__c;
                            terrHistoricRec.National_MPA_Rank__c = kpiAchvmentRecord.Current_National_Ranking__c;
                            if(prevTerrHistoricMap.containsKey(kpiAchvmentRecord.Territory__c)){
                                terrHistoricRec.MPA_Performance_Indicator__c = getIndicator(terrHistoricRec.National_MPA_Rank__c, prevTerrHistoricMap.get(kpiAchvmentRecord.Territory__c).National_MPA_Rank__c);
                            }else{
                                terrHistoricRec.MPA_Performance_Indicator__c = 'Same';
                            }							
                        }
                        when 'OES'{
                            terrHistoricRec.Outlet_Execution_Score__c = kpiAchvmentRecord.Achievement__c;
                            terrHistoricRec.National_OES_Rank__c = kpiAchvmentRecord.Current_National_Ranking__c;
                            if(prevTerrHistoricMap.containsKey(kpiAchvmentRecord.Territory__c)){
                                terrHistoricRec.OES_Performance_Indicator__c = getIndicator(terrHistoricRec.National_OES_Rank__c, prevTerrHistoricMap.get(kpiAchvmentRecord.Territory__c).National_OES_Rank__c);
                            }else{
                                terrHistoricRec.OES_Performance_Indicator__c = 'Same';
                            }
                        }
                        when 'NPD'{
                            terrHistoricRec.New_Product_Distribution__c = kpiAchvmentRecord.Achievement__c;                         
                        }
                        when 'Total Activation Survey'{
                            terrHistoricRec.Total_Activation_Survey__c = kpiAchvmentRecord.Achievement__c;
                        }
                        when 'Virtual Call Compliance'{
                            terrHistoricRec.Total_Virtual_Calls__c = kpiAchvmentRecord.Achievement__c;
                        }
                    }                                       
                }
				terrHistoricListToUpdate.add(terrHistoricRec); 
            }
            
            
            //Insert new records and Update old ones
            if(Schema.sObjectType.Territory_Historic__c.isUpdateable() && terrHistoricListToUpdate != null && terrHistoricListToUpdate.size() > 0){
                database.insert(terrHistoricListToUpdate, false);
            }            
        }catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        
    }
    
    private static String getIndicator(Decimal newValue, Decimal prevValue){
        return newValue > prevValue ? 'Down' : (newValue < prevValue ? 'Up' : 'Same');
    }   

    
    public void finish(Database.BatchableContext bc) {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_WeeklyTerritoryHistoricBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting,marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }        
        
    }
 
}