/**
* @Class Name: EDGE_OperatorCBOpportunityDetailsBatch

* @Author              Version       Date           Detail
*  Monalisa Halder      V1.0        18/09/2020     [ES20-8499,8602]
*  Monalisa Halder      V2.0        12/05/2021      ES20-10314
*  Anand U              V3.0        31/01/2022      ES20-12031
**/
public class EDGE_OperatorCBOpportunityDetailsBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    Map<Id,List<Opportunity>> operatorWithOppMap = new Map<Id,List<Opportunity>>();
    Map<Id,Integer> operatorWithOpenOpp = new Map<Id,Integer>();
    Map<Id,Integer> operatorWithClosedOpp = new Map<Id,Integer>();
    Date markCycleStartDate;
    Date markCycleEndDate;
    String queryString='';
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(23);
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        List<Market_Cycle__c> markCycle = new List<Market_Cycle__c>();       
        if(countryCode!=null){
            markCycle = [SELECT Id,Geography__c,Start_Date__c,End_Date__c,Active__c FROM Market_Cycle__c WHERE Active__c = TRUE AND Geography__r.Code__c =:countryCode LIMIT 1];
        }
        if(markCycle !=null && markCycle.size()>0){//ES20-12031
        markCycleStartDate = markCycle[0].Start_Date__c;
        markCycleEndDate = markCycle[0].End_Date__c;
        
         queryString = 'SELECT Id,Name,AccountId,Account.Operator__c,Account.Name,CloseDate,Start_Date__c,Opportunity_Template__r.End_Date__c,StageName,Pending_Date__c,Weight_Value__c,CreatedDate '+
                             ' FROM Opportunity WHERE Type = \'Cycle Brief\' AND (((StageName = \'Open\' OR StageName = \'Pending\')AND (Opportunity_Template__r.End_Date__c >= :markCycleStartDate AND Opportunity_Template__r.End_Date__c <= :markCycleEndDate))'+ 
                             ' OR (StageName = \'Closed\' AND CloseDate >= :markCycleStartDate AND CloseDate <= :markCycleEndDate) ) '+
                             ' AND Account.Country__r.Code__c =:countryCode AND Account.Operator__c != null Order by Account.Operator__c Desc,CreatedDate Desc ';
        }else{//ES20-12031
          queryString='SELECT Id FROM Opportunity LIMIT 0';
        }
        return Database.getQueryLocator(queryString);
    }
    
    //execute method
    public void execute(Database.BatchableContext bc, List<Opportunity> listOfOpps){
        Map<Id,Integer> operatorIdOpportunityCountMap = new Map<Id, Integer>();
        //System.debug('***getHeapSize() > Line Number  48'  + ' : ' + System.now() + ' = ' + Limits.getHeapSize());
        try{
           
            Set<Id> operatorIds = new Set<Id>();
            for(Opportunity oppRec : listOfOpps){
                operatorIds.add(oppRec.Account.Operator__c);
            }
            
           //ES20-10314
           for(AggregateResult agResult : [Select Count(Id) noOfOpportunities,Account.Operator__c operator FROM Opportunity 
                                           WHERE Type = 'Cycle Brief' AND Account.Operator__c != null AND Account.Country__r.Code__c =:countryCode
                                           AND (((StageName = 'Open' OR StageName = 'Pending') AND (Opportunity_Template__r.End_Date__c >= :markCycleStartDate AND Opportunity_Template__r.End_Date__c <= :markCycleEndDate))
                                           OR (StageName = 'Closed' AND CloseDate >= :markCycleStartDate AND CloseDate <= :markCycleEndDate) )
                                           AND Account.Operator__c in :operatorIds
                                           GROUP by Account.Operator__c])
            {
                    operatorIdOpportunityCountMap.put((Id)agResult.get('operator'), (Integer)agResult.get('noOfOpportunities'));
            }
            
           
            if(listOfOpps!=null && listOfOpps.size()>0){
				List<Opportunity> openClosedOppList = new List<Opportunity> ();
				for(Opportunity opp1 :listOfOpps){
					if(opp1.StageName == 'Closed' && (opp1.CloseDate >= markCycleStartDate && opp1.CloseDate <= markCycleEndDate)){
						openClosedOppList.add(opp1);		
					}else if((opp1.StageName == 'Pending' || opp1.StageName == 'Open') && opp1.Opportunity_Template__r.End_Date__c != null && (opp1.Opportunity_Template__r.End_Date__c >= markCycleStartDate && opp1.Opportunity_Template__r.End_Date__c <= markCycleEndDate)){
						openClosedOppList.add(opp1);
					}
				}
                for(Opportunity opp :openClosedOppList){
                    if(opp.StageName =='Open' || opp.StageName =='Pending'){
                    if(!operatorWithOpenOpp.containsKey(opp.Account.Operator__c)){
                        operatorWithOpenOpp.put(opp.Account.Operator__c,1);
                    }
                    else{
                        Integer openOpp = operatorWithOpenOpp.get(opp.Account.Operator__c);
                        operatorWithOpenOpp.put(opp.Account.Operator__c,openOpp+1);
                    }
                }
                else if(opp.StageName =='Closed'){
                    if(!operatorWithClosedOpp.containsKey(opp.Account.Operator__c)){
                        operatorWithClosedOpp.put(opp.Account.Operator__c,1);
                    }
                    else{
                        Integer closedOpp = operatorWithClosedOpp.get(opp.Account.Operator__c);
                        operatorWithClosedOpp.put(opp.Account.Operator__c, closedOpp+1);
                    }
                }
                    if(!operatorWithOppMap.containsKey(opp.Account.Operator__c)){
                        operatorWithOppMap.put(opp.Account.Operator__c,new List<Opportunity>{opp});                      
                    }
                    else{
                        if(operatorWithOppMap.get(opp.Account.Operator__c).size() < 500){
                            operatorWithOppMap.get(opp.Account.Operator__c).add(opp);
                        }
                        
                    }
                }
                List<Account> operatorListToUpdate = EDGE_OperatorCycleBriefOppDetailsHelper.operatorOppDetails(operatorWithOpenOpp, operatorWithClosedOpp, operatorWithOppMap,operatorIdOpportunityCountMap);
                
                //update operators
                if(operatorListToUpdate!=null && operatorListToUpdate.size()>0 && Schema.sObjectType.Account.isUpdateable()){
                    Database.update(operatorListToUpdate,true);
                }
                //ES20-10314
                if(operatorListToUpdate!=null && operatorListToUpdate.size()>0){
                    for(Account operator :operatorListToUpdate){
                     if(operatorWithOppMap.get(operator.Id).size() == 500){
                          operatorWithOppMap.remove(operator.Id);
                      }else if(operatorWithOppMap.get(operator.Id).size() < 500
                              && (operatorWithOppMap.get(operator.Id).size() == operatorIdOpportunityCountMap.get(operator.Id))){
                                  operatorWithOppMap.remove(operator.Id);
                      }
                   }    
                }
            }
            
        }
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            hasError = true;
        }
        
        
    }
    //finish method
    public void finish(Database.BatchableContext bc){
        EDGE_UtilityClass.printGovLimits(99);
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OperatorCBOpportunityDetailsBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        	EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError); 
        }
        
    }
    
}