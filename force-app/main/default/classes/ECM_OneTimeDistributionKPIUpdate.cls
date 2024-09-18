/*
* Name: ECM_OneTimeDistributionKPIUpdate
* Purpose: This is Class for One time update Distribution Achieved in Contract Items based on Outlet Execution
* History                                                            

VERSION    	AUTHOR                	DATE              	DETAIL
1.0      	Sneha Borkar        	08/08/2023        	Initial Development

*/

public with sharing class ECM_OneTimeDistributionKPIUpdate implements Database.Batchable<SObject>, Database.Stateful{
    private String countryCode;
    public ECM_OneTimeDistributionKPIUpdate(String country){
        this.countryCode = country;
    }    
    
    /**
    * @description : start - start method for the Batch
    * @return : List<contract> 
    * @param : Database.BatchableContext
    */
    public Database.QueryLocator start(Database.BatchableContext bc){ 
        List<String> statusValues = new List<String>{'active','Expired'};
        List<String> conRecordTypeNames =new List<String>{System.Label.ECM_Group_Contract_RecordType,System.Label.ECM_Outlet_Contract_RecordType};
        System.debug(LoggingLevel.Debug,'statusValues' + statusValues + 'conRecordTypeNames ' + conRecordTypeNames);
        
        String queryString = '';
        queryString = 'Select id from contract where Status IN: statusValues AND Account.Country__r.Code__c=:countryCode AND RecordType.Name IN: conRecordTypeNames order by ContractNumber';
        if(Test.isRunningTest()){
            queryString = 'Select id from contract where Status IN: statusValues AND RecordType.Name IN: conRecordTypeNames order by ContractNumber';
        }
        return Database.getQueryLocator(queryString);                        
    }
    
    /**
    * @description : execute - execute method for the Batch
    * @return : void
    * @param : Database.BatchableContext, List<contract> 
    */
    public void execute(Database.BatchableContext bc, List<contract> scope){
        try{
            if(scope != null){
                updateDistributionAchievedInCI(scope);
            }
        }
        catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Exception Occured '+ex.getMessage());
        } 
    }
    public void updateDistributionAchievedInCI(List<contract> contractMap){
        map<Id,List<ECM_Contract_Item__c>> mapOfContractWithCI = new Map<Id,List<ECM_Contract_Item__c>>();
        map<String, Date> mapOfOutletWithOutletEx = new map<String, Date>();
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        
        String outletExProductRecordTypeId = Schema.SObjectType.Outlet_Execution__c.getRecordTypeInfosByName().get(System.Label.ECM_OutletExecution_ProductRecordType).getRecordTypeId();
        
        String yesString=System.label.D1_Yes;//CUS-369
        set<Id> outletIds = new set<Id>();
        set<Id> productIds = new set<Id>();
        map<Id,set<Id>> contractWithOutletContracts = new map<Id,set<Id>>();
        
        set<Id> setOfConItemsWithDistribution = new set<Id>();
        List<Contract> conRecsToUpdate = new List<Contract>();
        Map<Id, Decimal> distCountMap = new Map<Id, Decimal>();
        for(Outlet_Contract__c outletContract : 
            [SELECT Id,Outlet__c,Contract__c FROM Outlet_Contract__c 
             WHERE Contract__c IN:contractMap]){
                 outletIds.add(outletContract.Outlet__c);
                 if(!contractWithOutletContracts.containsKey(outletContract.Contract__c)){
                     contractWithOutletContracts.put(outletContract.Contract__c,new set<Id>{outletContract.Outlet__c});
                 }else{
                     contractWithOutletContracts.get(outletContract.Contract__c).add(outletContract.Outlet__c);
                 }
             }
        
        //Get all contract items and products
        for(ECM_Contract_Item__c conItem :
            [SELECT Id,ECM_Contract__c,ECM_Contract__r.RecordTypeId,ECM_Product__c,
             ECM_Contract__r.AccountId,ECM_Distribution_Achieved__c,ECM_Contract__r.startDate,
             ECM_Contract__r.Contract_End_Date__c,Name,
             ECM_Product__r.Product__c,ECM_Product__r.Product__r.RecordTypeId,
             ECM_Product__r.Product__r.RecordType.DeveloperName,
             ECM_Product__r.Product__r.CRI__c,ECM_Product__r.Product__r.Brand_Varient__c,
             ECM_Product__r.Product__r.Item__r.Brand_Varient__c FROM ECM_Contract_Item__c 
             WHERE ECM_Contract__c IN:contractMap
             Order by ECM_Contract__c]){
                 conItemList.add(conItem);
                 if(mapOfContractWithCI.containsKey(conItem.ECM_Contract__c)){
                     mapOfContractWithCI.get(conItem.ECM_Contract__c).add(conItem);
                 }
                 else{
                     mapOfContractWithCI.put(conItem.ECM_Contract__c,new List<ECM_Contract_Item__c>{conItem});
                 }
                 switch on conItem.ECM_Product__r.Product__r.RecordType.DeveloperName {
                     when 'SKU' {
                         productIds.add(conItem.ECM_Product__r.Product__r.CRI__c);
                         productIds.add(conItem.ECM_Product__r.Product__r.Brand_Varient__c);
                     }
                     when 'CRI' {
                         productIds.add(conItem.ECM_Product__r.Product__c);
                         productIds.add(conItem.ECM_Product__r.Product__r.Item__r.Brand_Varient__c);
                     }
                     when 'Item' {
                         productIds.add(conItem.ECM_Product__r.Product__r.Brand_Varient__c);
                     }
                     when 'Brand_Variant' {
                         productIds.add(conItem.ECM_Product__r.Product__c);
                     }
                     when else {
                         System.debug(LoggingLevel.Debug,'Else Condition');
                     }
                 }
                 
             }
        
        //Get Outlet Executions
        for(Outlet_Execution__c outletEx:
            [SELECT Id,Product__c,Product__r.RecordTypeId,Outlet__c,
             Product__r.RecordType.DeveloperName,Date_of_Execution__c
             FROM Outlet_Execution__c 
             WHERE Outlet__c IN:outletIds AND
             Distribution_TRAX__c=:yesString AND //CUS-369
             Product__c IN:productIds AND
             RecordTypeId=:outletExProductRecordTypeId
             Order by Product__r.RecordType.DeveloperName]){
                 mapOfOutletWithOutletEx.put(outletEx.Outlet__c + '_' + outletEx.Product__c,outletEx.Date_of_Execution__c);
                 
             }
        
        if(!contractMap.isEmpty()){
            for(ECM_Contract_Item__c conItem :conItemList){
                Date startDate = conItem.ECM_Contract__r.startDate;
                Date endDate = conItem.ECM_Contract__r.Contract_End_Date__c;
                
                if(contractWithOutletContracts.containsKey(conItem.ECM_Contract__c)){
                    
                    for(Id outletId:contractWithOutletContracts.get(conItem.ECM_Contract__c)){
                        
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
                               System.debug(LoggingLevel.Debug,'Reached Else Condition');
                            }
                        }
                        //end of switch case
                    }
                    //end of inner loop
                }
            }
        }
        for(ECM_Contract_Item__c conItem : conItemList){
            conItem.ECM_Distribution_Achieved__c  = setOfConItemsWithDistribution.contains(conItem.Id)?'Yes':'No';
            if(conItem.ECM_Distribution_Achieved__c == 'Yes'){
                if(distCountMap.containsKey(conItem.ECM_Contract__c)){
                    Decimal count  = distCountMap.get(conItem.ECM_Contract__c) + 1;
                    distCountMap.put(conItem.ECM_Contract__c,count);
                }
                else{
                    distCountMap.put(conItem.ECM_Contract__c, 1);
                }
            }
        }
        if(!conItemList.isEmpty()){
            update conItemList;
        }
        
        for(Id conId : mapOfContractWithCI.keySet()){
            
            Decimal totalSize = mapOfContractWithCI.get(conId).size();
            Decimal countSize = distCountMap.containsKey(conId)?distCountMap.get(conId):0;
            if(totalSize!=0){
                Decimal percentageVal = countSize != 0? ((countSize/totalSize)*100):0;
                Contract conRecord = new Contract(Id=conId);
                conRecord.ECM_Distribution_Percentage__c = percentageVal.setScale(2);
                conRecsToUpdate.add(conRecord);
            }
        }
        if(!conRecsToUpdate.isEmpty()){
            update conRecsToUpdate;
        }
    }
    
    
    /**
    * @description : finish - Finish method for the Batch
    * @return : void
    */
    public void finish(Database.BatchableContext bc){  
    
        System.debug(LoggingLevel.Debug,'Reached Finish');
    }
}