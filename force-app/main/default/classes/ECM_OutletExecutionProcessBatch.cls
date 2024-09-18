global class ECM_OutletExecutionProcessBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    Boolean hasError = false;
    String exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    final static String outletExecutionProductRecordTypeId = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        system.debug('this.batchSetting=='+this.batchSetting);
    }
    //start method 
    public Database.QueryLocator start(Database.BatchableContext bc){
       
        system.debug('batchSetting=='+batchSetting);
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        countryCode = batchSetting.Country_Code__c;
        Boolean latesttrue = true;
        String queryString;
        String todayDate = System.label.ECM_OE_Today;
        String yesterdayDate = System.label.ECM_OE_Yesterday;
        String yesString=System.label.D1_Yes;
        if (!Test.isRunningTest()){
            queryString = 'SELECT Id,Outlet__c,Outlet__r.Latest_Date_Of_Execution_Activation__c,Outlet__r.Latest_Date_Of_Execution_Product__c,Product__c,Date_of_Execution__c, Latest_Entry__c, RecordTypeId, Activation_Reference__c FROM Outlet_Execution__c  WHERE Outlet__r.Country__r.Code__c =:countryCode' +
                + ' AND Date_of_Execution__c != null AND RecordTypeId =: outletExecutionProductRecordTypeId AND Outlet__c != NULL AND lastmodifieddate ='+ yesterdayDate + ' AND Product__c!= NULL AND Distribution_TRAX__c=:yesString ORDER BY Outlet__c DESC, Date_of_Execution__c DESC';
        }
        else {
            queryString = 'SELECT Id,Outlet__c,Outlet__r.Latest_Date_Of_Execution_Activation__c,Outlet__r.Latest_Date_Of_Execution_Product__c,Product__c,Date_of_Execution__c, Latest_Entry__c, RecordTypeId, Activation_Reference__c FROM Outlet_Execution__c  WHERE Outlet__r.Country__r.Code__c =:countryCode' +
                + ' AND Date_of_Execution__c != null AND RecordTypeId =: outletExecutionProductRecordTypeId AND Outlet__c != NULL AND lastmodifieddate ='+ todayDate + ' AND Product__c!= NULL AND Distribution_TRAX__c=:yesString ORDER BY Outlet__c DESC, Date_of_Execution__c  DESC';
        }
       
          
        
        system.debug('queryString--'+queryString);
        return Database.getQueryLocator(queryString);
        
    }
    public void execute(Database.BatchableContext bc, List<Outlet_Execution__c> outletExecutionList){ 
        system.debug('outletExecutionList=='+outletExecutionList);
        Map<String, Date> outletMap = new Map<String, Date>();
        Set<id> outletIds = new Set<id>();
        
        try{
                for(Outlet_Execution__c oexecRec :outletExecutionList)
                {
                   outletIds.add(oexecRec.outlet__c);
                   outletMap.put(oexecRec.outlet__c + '_' + oexecRec.product__c, oexecRec.Date_of_Execution__c);
        }
            updateDistributionAchievedInCI(outletIds, outletMap);//CUS-327 change
        }
        
        catch(Exception batchException){
            System.debug('Exception '+ batchException.getCause() + 'has ocurrred at line '+ batchException.getLineNumber());
            System.debug('StackTraceString '+ batchException.getStackTraceString());
            hasError = true;
        }
    }
        //CUS-327 Change
        private static void updateDistributionAchievedInCI(Set<id> outletIds, Map<String, Date> mapOfOutletWithOutletEx){
            
            //Variable Declaration -> Start
            
            Set<Id> mainOutletIds = outletIds;
            set<Id> contractIds = new set<Id>();
            map<ID,String> accountMap = new map<ID,String>();
            Map<Id,Set<Id>> contractWithOutletMap = new Map<Id,Set<Id>>();
            map<Id,String> contractMap = new map<Id,String>();
            set<Id> setOfConItemsWithDistribution = new set<Id>();
            
            String groupContractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get(System.Label.ECM_Group_Contract_RecordType).getRecordTypeId();
            String outletContractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get(System.Label.ECM_Outlet_Contract_RecordType).getRecordTypeId();
            
            Map<Id,Integer> contractWithCITotal = new  Map<Id,Integer>();
            Map<Id,Integer> contractWithCIDistributionYes = new  Map<Id,Integer>();
            List<Outlet_Contract__c> outletContractList = new List<Outlet_Contract__c>();
            List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
            List<Contract> conList = new List<Contract>();
            //Variable Declaration -> End
            //
            for(Outlet_Contract__c outletContract:
                [SELECT Id,Outlet__c,Contract__c,Contract__r.Status,
                 Contract__r.AccountId,Contract__r.RecordTypeId,
                 Contract__r.StartDate,Contract__r.Contract_End_Date__c
                 FROM Outlet_Contract__c
                 WHERE Outlet__c IN:mainOutletIds AND
                 Contract__r.Status =:System.Label.ECM_DistributionAchieved_ContractStatus AND
                 (Contract__r.RecordTypeId =:groupContractRecordTypeId OR
                  Contract__r.RecordTypeId =:outletContractRecordTypeId)]){
                      accountMap.put(outletContract.Contract__r.AccountId,'');
                      outletContractList.add(outletContract);
                  }
            
            if(!accountMap.isEmpty()){
                for(Account acc:
                    [SELECT Id,Country__r.Code__c
                     FROM Account WHERE Id IN:accountMap.keySet()]){
                         accountMap.put(acc.Id, acc.Country__r.Code__c);
                     }
            }
            
            for(Outlet_Contract__c outletContract:outletContractList){
                if(accountMap.containsKey(outletContract.Contract__r.AccountId) && 
                   System.Label.ECM_DistributionAchieved_ContractCountryCodes.split(';').contains(accountMap.get(outletContract.Contract__r.AccountId)) ){
                       contractMap.put(outletContract.Contract__c, outletContract.Contract__r.StartDate+';'+outletContract.Contract__r.Contract_End_Date__c);
                       if(!contractWithOutletMap.containsKey(outletContract.Contract__c)){
                           contractWithOutletMap.put(outletContract.Contract__c,new set<Id>{outletContract.Outlet__c});
                       }else{
                           contractWithOutletMap.get(outletContract.Contract__c).add(outletContract.Outlet__c);
                       }
                       
                       if(!contractWithCITotal.containsKey(outletContract.Contract__c)){
                           contractWithCITotal.put(outletContract.Contract__c, 0);
                       }
                       
                       if(!contractWithCIDistributionYes.containsKey(outletContract.Contract__c)){
                           contractWithCIDistributionYes.put(outletContract.Contract__c, 0);
                       }
                   }
            }
            
            //CUS-327 -> Logic Start
            
            if(!contractMap.isEmpty()){
                for(ECM_Contract_Item__c conItem :
                    [SELECT Id,ECM_Contract__c,ECM_Contract__r.RecordTypeId,ECM_Product__c,
                     ECM_Contract__r.AccountId,ECM_Distribution_Achieved__c,
                     ECM_Product__r.Product__c,ECM_Product__r.Product__r.RecordTypeId,
                     ECM_Product__r.Product__r.RecordType.DeveloperName,
                     ECM_Product__r.Product__r.CRI__c,ECM_Product__r.Product__r.Brand_Varient__c,
                     ECM_Product__r.Product__r.Item__r.Brand_Varient__c FROM ECM_Contract_Item__c 
                     WHERE ECM_Contract__c IN:contractMap.keySet()
                     Order by ECM_Contract__c]){
                         conItemList.add(conItem);
                         Date startDate = Date.valueOf(contractMap.get(conItem.ECM_Contract__c).split(';')[0]);
                         Date endDate = Date.valueOf(contractMap.get(conItem.ECM_Contract__c).split(';')[1]);
                         
                         if (contractWithOutletMap.containsKey(conItem.ECM_Contract__c)){
                             
                             for(Id outletId:contractWithOutletMap.get(conItem.ECM_Contract__c)){
                                     switch on conItem.ECM_Product__r.Product__r.RecordType.DeveloperName {
                                   
                                   when 'SKU' {
                                       String key1,key2;
                                        key1 = outletId + '_' + conItem.ECM_Product__r.Product__r.CRI__c;
                                        key2 = outletId + '_' + conItem.ECM_Product__r.Product__r.Brand_Varient__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate)) ||
                                         (mapOfOutletWithOutletEx.containsKey(key2) && 
                                           (mapOfOutletWithOutletEx.get(key2)>=startDate && mapOfOutletWithOutletEx.get(key2)<=endDate))){
                                           setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                       }
                                       
                                   }
                                   
                                   when 'CRI' {
                                       String key1,key2;
                                       key1 = outletId + '_' + conItem.ECM_Product__r.Product__c;
                                       key2 = outletId + '_' + conItem.ECM_Product__r.Product__r.Item__r.Brand_Varient__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate)) ||
                                         (mapOfOutletWithOutletEx.containsKey(key2) && 
                                           (mapOfOutletWithOutletEx.get(key2)>=startDate && mapOfOutletWithOutletEx.get(key2)<=endDate))){
                                           setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                       }
                                       
                                   }
                                   
                                   when 'Item' {
                                       String key1;
                                       key1 = outletId + '_' + conItem.ECM_Product__r.Product__r.Brand_Varient__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate))){
                                               setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                           }
                                   }
                                   
                                   when 'Brand_Variant' {
                                       String key1;
                                       key1 = outletId + '_' + conItem.ECM_Product__r.Product__c;
                                       
                                       if((mapOfOutletWithOutletEx.containsKey(key1) && 
                                           (mapOfOutletWithOutletEx.get(key1)>=startDate && mapOfOutletWithOutletEx.get(key1)<=endDate))){
                                               setOfConItemsWithDistribution.add(conItem.Id);
                                               break;
                                           }
                                   }
                                   
                                   when else {
                                       System.debug('none of the above');
                                   }
                               }
                             }
                         }
                     }
                
                for(ECM_Contract_Item__c conItem : conItemList){
                    conItem.ECM_Distribution_Achieved__c  = setOfConItemsWithDistribution.contains(conItem.Id)?'Yes':'No';
                    if(conItem.ECM_Distribution_Achieved__c == 'Yes' &&
                      contractWithCIDistributionYes.containsKey(conItem.ECM_Contract__c)){
                            contractWithCIDistributionYes.put(conItem.ECM_Contract__c,contractWithCIDistributionYes.get(conItem.ECM_Contract__c) +1);
                    }
                    contractWithCITotal.put(conItem.ECM_Contract__c,contractWithCITotal.get(conItem.ECM_Contract__c)+ 1);
                }
                
                if(!conItemList.isEmpty()){
                    update conItemList;
                }
                
                for(Id conId: contractMap.keySet()){
                    Contract conRec = new Contract(Id=conId);
                    decimal numerator = contractWithCIDistributionYes.containsKey(conId)?contractWithCIDistributionYes.get(conId):0;
                    decimal denominator = contractWithCITotal.containsKey(conId)?contractWithCITotal.get(conId):0;
                    conRec.ECM_Distribution_Percentage__c = (numerator/denominator)*100;
                    conList.add(conRec);
                }
                
                if(!conList.isEmpty()){
                    update conList;
                }
            }
            
        }
    

    //finish method
    public void finish(Database.BatchableContext bc){    
        Country_Batch_Job_Log__c batchJobLog = new Country_Batch_Job_Log__c();
        //Get Batch Job
        batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_OutletExecutionMarkLatestEntryBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
}