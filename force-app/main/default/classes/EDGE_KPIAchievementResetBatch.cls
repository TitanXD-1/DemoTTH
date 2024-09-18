/**
* @ Name : EDGE_KPIAchievementResetBatch
* @ Description : 
* @ History  
* @ Author               Version    				Date           Detail
* @	Monalisa Halder    Initial Development	     08-01-2020     Initial Development
* @ Joshraj Sen             1.1                  10-02-2022       ES20-11690 (Updated execute method for Quality Territories)


* @ Subhodeep Sarkar        2.0                  14-02-2022       ES20-11839 (Updated execute method for SOS Kpi in Quality Territories)
* @ Anamika Shukla          3.0                  22/02/2022       ES20-12094 (Base Achievement Refresh for Quality KPIs)
* @ Wribhu Bose				4.0					 21/03/2022		  ES20-12281; added Activation Territory to Label.EDGE_Territory_Record_Types (no change in code)
* @ Mayukh S Roy            5.0                  26/10/2022       ES20-13391
* @ Joshraj Sen             6.0                  11/01/2023       ES20-13719
* @ Rajarshi Lahiri         7.0					 12/01/2023       ES20-13499

**/


public class EDGE_KPIAchievementResetBatch implements Database.Batchable<sObject>,Database.Stateful, Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{    
    
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Set<Id> territoryIdSet = new Set<Id>();
    Id marketBatchJobId; 
    List<Territory__c> territoryList = new List<Territory__c>();
    Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
    List<String> territoryTypes=new List<String>();
    //Added below by ES20-12100
    string countryCode = '';
    List<Market_Cycle__c> marketCycleRecord ;
    List<Market_Setting__c> marketSettingList;

    Date actvMarketCycleStartDate;
    Date actvMarketCycleEndtDate;
    Date today;
    public boolean dateMatch = false;
    Decimal numOfworkingDay = 0.0;
    List<String> territoryRecordTypes = new List<String>();
    
    public static final String virtualCallComp = 'Virtual Call Compliance';
    public Id userKPIRecordTypeId=Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByName().get('User KPI').getRecordTypeId();

        
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    // start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());  //Update ES20-6594  
        String territoryRecordTypesLabel = Label.EDGE_Territory_Record_Types;
        
        if(territoryRecordTypesLabel !=null){
            territoryRecordTypes = territoryRecordTypesLabel.split(',');
        }
        String countryCode = batchSetting.Country_Code__c;
        String activeStatus = 'Active';
        //Boolean batchPending = true;
        
        if(territoryRecordTypes != null){
            territoryList = [SELECT ID,Pending_For_Batch__c,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c,
                             Distribution_Target__c, Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c,
                             (SELECT Id, Volume_Category_Premium_Core_Target__c, Volume_Category_Deluxe_Target__c, Volume_Category_Reserve_Target__c, Volume_Category_RTD_Target__c, Volume_Category_Super_Deluxe_Target__c, Volume_Target_Value__c FROM Territory_Cycles__r WHERE Market_Cycle__r.Active__c = TRUE)
                             FROM Territory__c WHERE RecordType.Name in :territoryRecordTypes AND Country__r.Code__c =:countryCode AND Status__c =:activeStatus];
        }
       
        if(territoryList != null && territoryList.size()>0){
            for(Territory__c territory : territoryList){
                territoryIdSet.add(territory.Id);
            }
            
        }

        //Get sales territories        
        String queryString='SELECT Id,Territory__r.Total_Number_Of_Outlets__c, KPI_Type__c,Total_Outlets__c, Category__c, Volume_Category__c, Total_Denominator__c,' +
            + ' Actual_Numerator__c, Target_Number__c, Achievement__c, Previous_Achievement__c, Target__c,Territory__c,Territory__r.Pending_For_Batch__c,RecordTypeId,Pending_Reset__c FROM KPI_Achivement__c' +
            + ' WHERE (Territory__c IN :territoryIdSet) OR (Country__r.Code__c = \'' + countryCode +'\' AND RecordTypeID =\'' + userKPIRecordTypeId +'\' AND' + 
            + ' KPI_Type__c = \'' + virtualCallComp +'\') Order By RecordTypeID'; 
        
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<KPI_Achivement__c> kPIAchievementList){     	
        try{
            countryCode = batchSetting.Country_Code__c;
            today = Date.today();
            marketSettingList = [Select Id, Geography__c,Outlet_Execution_Score__c, Minimum_Activation_Standards__c, Minimum_Product_Assortment__c, Distribution__c, 
                                                     Share_Of_Space__c, New_Product_Distribution__c, Share_of_Space_facings__c from Market_Setting__c 
                                                     WHERE Geography__r.Code__c = :countryCode LIMIT 1];
            marketCycleRecord = [SELECT Id,Start_Date__c,Number_of_Week__c,Number_Of_Working_Day__c,End_Date__c,Geography__r.Code__c from Market_Cycle__c WHERE Geography__r.Code__c =:countryCode AND Active__c= True LIMIT 1] ;

            if(marketCycleRecord!=null && marketCycleRecord.size()>0){
                actvMarketCycleStartDate = marketCycleRecord[0].Start_Date__c;
                actvMarketCycleEndtDate = marketCycleRecord[0].End_Date__c; 
                numOfworkingDay =  marketCycleRecord[0].Number_Of_Working_Day__c;
            }
            if(actvMarketCycleStartDate!=null && actvMarketCycleStartDate == today){
                dateMatch = true;  
            }
            Set<Id> territoryIdsSet = new Set<Id>();
            Map<Id, KPI_Achivement__c> kpiAchievmentMap = new Map<Id, KPI_Achivement__c>();
            Map<Id, KPI_Achivement__c> kpiAchievmentSosVolMap = new Map<Id, KPI_Achivement__c>();
            Set<Id> kpiRecsAlreadyCovered = new Set<Id> ();
            List<String> kpiTypes=Label.EDGE_SurveyActKPITypes.split(',');

            List<KPI_Achivement__c> kpiAchvmntListToUpdate = new List<KPI_Achivement__c>();
            for (KPI_Achivement__c kpi : kPIAchievementList){
                if(kpi.KPI_Type__c != virtualCallComp && kpi.RecordTypeId != userKPIRecordTypeId && !kpiTypes.contains(kpi.KPI_Type__c)){ //ES20-13391
                    if(kpi.Territory__r.Pending_For_Batch__c == true){
                        if(kpi.KPI_Type__c == 'SoS' || kpi.KPI_Type__c == 'Volume Category Performance' ){
                            kpi.Actual_Numerator__c = 0;
                            kpi.Total_Denominator__c = 0;
                            kpi.Achievement__c = 0;
                            //modified as part of ES20-11839
                            if(kpi.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_facings__c  == 'Facings in number' ){
                               
                                kpi.Target_Number__c=0;
                                kpi.Target__c = null;
                            }
                            else if(kpi.KPI_Type__c == 'SoS' && marketSettingList[0].Share_of_Space_facings__c  == 'Facings in %' )
                            {	
                                kpi.Target_Number__c=null;
    
    
                                kpi.Target__c = 0;
                            }
                            else if(kpi.KPI_Type__c == 'Volume Category Performance'){
                                kpi.Target__c = 0;
                            }
    
    
                            kpi.Previous_Achievement__c = 0;
                            kpi.Total_Outlets__c = 0;
                            kpiAchievmentSosVolMap.put(kpi.Id, kpi);
                    	}
                	}
                    if(kpi.Territory__c != null){
                        territoryIdsSet.add(kpi.Territory__c);
                    }
                	kpiAchievmentMap.put(kpi.Id, kpi);
                }
                
                //ES20-13391
                else if(kpi.KPI_Type__c == virtualCallComp && kpi.RecordTypeId == userKPIRecordTypeId && dateMatch){
                    kpi.Actual_Numerator__c = 0;
                    kpi.Achievement__c = 0;
                    kpiAchvmntListToUpdate.add(kpi);
                }
                //ES20-13499
				//To Change Survey,Activation Survey and Total Activation KPI with Pending_Reset__c as true to false so that historic KPI records are not recalculated
                else if(kpiTypes.contains(kpi.KPI_Type__c) && kpi.Pending_Reset__c){
                    kpi.Pending_Reset__c=false;
                    if(dateMatch){
                        kpiAchvmntListToUpdate.add(kpi);
                    }
                    else{
                        kpiAchievmentMap.put(kpi.Id, kpi);
                    }	
                    
                }
            }
            if(dateMatch){//Start of Market Cycle
                
                
                
                if(!territoryIdsSet.isEmpty()){
                    for(Id kpiId : kpiAchievmentMap.keySet()){
                        KPI_Achivement__c kpiRec =  kpiAchievmentMap.get(kpiId);
                        if(!kpiRecsAlreadyCovered.contains(kpiRec.Id) && kpiRec.Territory__c != null && kpiRec.Territory__r.Total_Number_Of_Outlets__c>0 )
                        {
                            if(kpiAchievmentSosVolMap.containsKey(kpiRec.Id)){//SOS and Volume related KPI Achievements
                                KPI_Achivement__c kpiRecSOSVol = kpiAchievmentSosVolMap.get(kpiRec.Id);
                                kpiRecSOSVol.Base_Achievement__c = kpiRecSOSVol.Achievement__c;
                                kpiRecsAlreadyCovered.add(kpiRecSOSVol.Id);
                                kpiAchvmntListToUpdate.add(kpiRecSOSVol);
                            }else{//KPI Achievemnets other than SOS and Volume
                                kpiRec.Base_Achievement__c = kpiRec.Achievement__c;
                                kpiRecsAlreadyCovered.add(kpiRec.Id);
                                kpiAchvmntListToUpdate.add(kpiRec);
                            }
                        }
                    }
                }
			System.debug(LoggingLevel.DEBUG,'kpiAchvmntListToUpdate - '+kpiAchvmntListToUpdate);
            System.debug(LoggingLevel.DEBUG,'kpiAchievmentMap - ' +kpiAchievmentMap.values());
                
            if(kpiAchvmntListToUpdate != null && kpiAchvmntListToUpdate.size() > 0){
                    Database.update(kpiAchvmntListToUpdate, false);
                } 
            }
            else{ //for daily batch run
                if(kpiAchievmentMap != null && kpiAchievmentMap.size() > 0){
                    Database.update(kpiAchievmentMap.values(), false);

                }
            }



            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed','EDGE_KPIAchievementResetBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}