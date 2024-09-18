/*
* Class Name: ECM_GenerateAccrualBatch
* Test Class: ECM_GenerateAccrualBatchTest
* Author: 
* Brief Description: This class is used to create Accrual & Accrual Items when contract move to Active Status.
* Created Date: 20/05/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0               Joshraj Sen         19/05/2024          Initial Development :153431 New batch creation & calculations Part-1_SFDC
* 2.0			    Suvendu Roy		    20/05/2024			153432 - New batch creation & calculations Part-2_SFDC
* 3.0			    Suvendu Roy		    01/05/2024			154094 - Accrual for Lead Products  in Contracts (Part-1)_SFDC
* 4.0				Sudipta Nandy		03/06/2024			154135 - To populate Payment Frequency field in Accrual Items
*/ 

public class ECM_GenerateAccrualBatch implements Database.Batchable<SObject>,Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    Market_Batch_Setting__mdt batchSetting; 
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId;
    String countryCode ='';
    String budget='';
    Market_Setting__c marketSetting;
    Boolean isAccrualCreationChanged;
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    
    /**
* @description : start - start method for the Batch
* @return : Database.QueryLocator
* @param : Database.BatchableContext
*/
    public Database.QueryLocator start(Database.BatchableContext bc){  
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        
        String contractGroupRecordtypeId = Contract.sobjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        String contractOutletRecordtypeId = Contract.sobjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();      
        marketSetting = [Select Id,ECM_Budget_Type_for_Volume_Based_PS__c,Accrual_Creation__c,ECM_Change_in_Accrual_Logic__c from Market_Setting__c where Geography__r.Code__c=:countryCode Limit 1];
        String strQuery='';
        System.debug(LoggingLevel.DEBUG,contractGroupRecordtypeId+contractOutletRecordtypeId);
        ECM_Accruals_Financial_Period__mdt metadate = [SELECT Id,ECM_Country_Code__c, ECM_End_Month__c, ECM_Start_Month__c FROM ECM_Accruals_Financial_Period__mdt WHERE ECM_Country_Code__c =:countryCode WITH SECURITY_ENFORCED LIMIT 1 ];
        if(marketSetting.Accrual_Creation__c =='Upto 2 Decimals'  && metadate != null ){
            budget = marketSetting.ECM_Budget_Type_for_Volume_Based_PS__c;
            isAccrualCreationChanged =marketSetting.ECM_Change_in_Accrual_Logic__c;
            strQuery = 'SELECT Id, Name, Status, AccountId, StartDate, Contract_End_Date__c, ECM_Is_Accrual_Created__c, '+
                'RecordType.Name, ECM_Duration__c, Account.country__r.code__c, '+
                '(SELECT Id, ECM_Product_Name__c, ECM_Contract__c,  ECM_Contract__r.Account.country__r.code__c, '+
                'ECM_Product__r.Product__r.Id, ECM_Retro_investment__c, ECM_Contract__r.StartDate, ECM_Contract__r.Contract_End_Date__c, '+
                'ECM_TotalSKU_SpecificRebate__c, ECM_Product__c, ECM_Lead_Brand__c, '+
                'ECM_Product__r.Product__c, ECM_Volume__c, ECM_Contract__r.AccountId,'+
                'ECM_UoM__c,ECM_Contract__r.ECM_Payment_Frequency_type__r.ECM_Type__c FROM Contract_Items__r WHERE ECM_Retro_investment__c > 0) ';
            if(isAccrualCreationChanged){//Market Setting Accrual_Creation__c is getting changed
                strQuery += ',(SELECT Id, ECM_Fiscal_Year__c, ECM_Period__c from Accruals__r) '+
                    'FROM Contract WHERE (RecordTypeid=: contractOutletRecordtypeId OR RecordTypeid=: contractGroupRecordtypeId) '+
                    'AND Account.country__r.code__c =: countryCode AND Status = \'Active\'';
            }else{
                strQuery +='FROM Contract WHERE (RecordTypeid=: contractOutletRecordtypeId OR RecordTypeid=: contractGroupRecordtypeId) '+
                    'AND Account.country__r.code__c =: countryCode AND Status = \'Active\' AND ECM_Is_Accrual_Created__c != TRUE';
            }
            
        }else{
            strQuery='SELECT Id FROM Contract LIMIT 0';
        }
        
        return Database.getQueryLocator(strQuery);
    }
    
    /**
* @description : execute - execute method for the Batch
* @return : void
* @param : Database.BatchableContext, List<Contract> 
*/
    public void execute(Database.BatchableContext bc, List<Contract> scope){
        // System.debug(LoggingLevel.DEBUG,scope.size()+'->'+scope);

        //Declaring Veriables
        String internalOrderCMRecordtypeId = ECM_Internal_Order__c.sobjectType.getDescribe().getRecordTypeInfosByName().get('CM Internal Order').getRecordTypeId();
        List<ECM_Accrual__c> accrualList = new List<ECM_Accrual__c>();
        List<ECM_Accrual_Item__c> accrualItemList=new List<ECM_Accrual_Item__c>();
        List<ECM_Contract_Item__c> conItemList = new List<ECM_Contract_Item__c>();
        List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailsList = new List<ECM_Sales_Driver_Item_Detail__c>();
        Map<String,Id> accrualMapWithContractId = new Map<String,Id>();
        Map<String,List<ECM_Internal_Order__c>>internalOrderMap = new Map<String,List<ECM_Internal_Order__c>>();

        //Deletion Extra Accruals & AccrualsItems
        if(isAccrualCreationChanged){
            ECM_GenerateAccrualHelper.deleteExtraAccruals(scope);
        }
        //Setting Map Of Fiscal Period to Contract Id in Helper
        ECM_GenerateAccrualHelper.generateFiscalPeriods(scope);
        
        //Creating Accrual List
        accrualList = ECM_GenerateAccrualHelper.generateAccruals(scope);
        // System.debug(LoggingLevel.DEBUG,accrualList.size());
        
        //Making List of ContractItems & updating contracts
        for(Contract conRec:scope){
            conRec.ECM_Is_Accrual_Created__c  = true;
            conItemList.addALL(conRec.Contract_Items__r);
        }
        
        Boolean isAccessible = !accrualList.isEmpty() && (Schema.sObjectType.ECM_Accrual__c.isAccessible()||Schema.sObjectType.Contract.isAccessible());//To reduce SCA
        //Inserting Accrual List
        //Updating Contract ECM_Is_Accrual_Created__c = true
        if(isAccessible){
            Database.insert(accrualList,false);
            Database.update(scope,false);
        }
        
        
        //Making Accrual map with ConID_20XX_PX 
        for(ECM_Accrual__c accrualRec : accrualList){
            String key = accrualRec.ECM_Contract__c+'_'+accrualRec.ECM_Fiscal_Year__c+'_'+accrualRec.ECM_Period__c;
            accrualMapWithContractId.put(key, accrualRec.Id);
        }
        
        //Getting Sales Driver Item Details for Accrual Item creation
        salesDriverItemDetailsList = [SELECT Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Budget_Type__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__r.id,
                                      ECM_Sales_Driver_Item__c,ECM_Product__r.ECM_Investment__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c,ECM_Product__r.ECM_Lead_Brand__c,
                                      ECM_Product__r.ECM_Product__r.Product__r.Id, ECM_Sales_Driver_Item__r.Contract__c,ECM_Sales_Driver_Item__r.Contract__r.AccountId,
                                      ECM_Product__r.ECM_Product__r.Product__c, ECM_Product__r.ECM_Product_Name__c,ECM_Product__r.Id,ECM_Sales_Driver_Item__r.Contract__r.StartDate,
                                      ECM_Sales_Driver_Item__r.Contract__r.ECM_Duration__c,ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c, 
                                      ECM_Sales_Driver_Item__r.Contract__r.Contract_End_Date__c FROM ECM_Sales_Driver_Item_Detail__c
                                      WHERE ECM_Sales_Driver_Item__r.Contract__c IN:scope 
                                      AND ECM_Budget_Type__c!=null AND ECM_Investment_Amount__c > 0];
        // System.debug(LoggingLevel.DEBUG,'SDID list size '+salesDriverItemDetailsList.size());
        
        //Creating Accrual Map with productID-budgetType
        for(ECM_Internal_Order__c internalOrder: [SELECT Id,name,ECM_Product__r.name,ECM_Budget_Type_Pickup_Option__c,
                                                  ECM_Active__c,ECM_Geography__c,ECM_Product__c,ECM_Fiscal_Year__c, ECM_Start_Date__c ,ECM_End_Date__c 
                                                  FROM ECM_Internal_Order__c WHERE ECM_Active__c=:TRUE AND RecordTypeId =:internalOrderCMRecordtypeId
                                                  AND ECM_Geography__r.Code__c=:countryCode  ORDER BY LastModifiedDate ASC]){
                                                      String key = String.valueOf(internalOrder.ECM_Product__c+'-'+internalOrder.ECM_Budget_Type_Pickup_Option__c);
                                                      if(!internalOrderMap.containsKey(key)){
                                                          internalOrderMap.put(key,new List<ECM_Internal_Order__c>{internalOrder});
                                                      }
                                                      internalOrderMap.get(key).add(internalOrder);
                                                  }
        
        //Getting keySet[productID-budgetType:ConId-ConStartDate] to get Final Map of Internal Order Id
        Set<String> internalOrderKeySet = ECM_GenerateAccrualExtendedHelper.productItemMapwithBudgetType(conItemList,salesDriverItemDetailsList,budget);
        //Getting Final Map of Internal Order Id to generate Accrual Items
        Map<String, Id> internalOrderMapWithKey = ECM_GenerateAccrualExtendedHelper.mapContractToInternalOrder(internalOrderKeySet,internalOrderMap);
        
        //Getting Accrual Items For Contract Item
        accrualItemList.addAll(ECM_GenerateAccrualHelper.getAccrualItemsForContractItem(new Map<String,List<ECM_Contract_Item__c>>{budget => conItemList},internalOrderMapWithKey,accrualMapWithContractId));
        // System.debug(LoggingLevel.DEBUG,accrualItemList.size());
        
        //Getting Accrual Items For SDID
        accrualItemList.addAll(ECM_GenerateAccrualHelper.getAccrualItemsForSalesDriverItemDetails(salesDriverItemDetailsList,internalOrderMapWithKey,accrualMapWithContractId));
        // System.debug(LoggingLevel.DEBUG,accrualItemList.size());
        
        //Inserting Accrual Items List
        if(!accrualItemList.isEmpty() && Schema.sObjectType.ECM_Accrual_Item__c.isAccessible()){
            Database.insert(accrualItemList,false);
        }
        ECM_GenerateAccrualHelper.deleteAccrualWithNoAccrualItems(accrualMapWithContractId.values());//Mychanges
    }
    
    /**
* @description : finish - Finish method for the Batch
* @return : void
* @param : Database.BatchableContext - Batchable Context
*/  
    public void finish(Database.BatchableContext bc){  
        
        
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId); //Get Batch Job
        String reducedExceptionMsg = '';
        hasError = !hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed';
        if(hasError){ //Update Batch Job Status
            reducedExceptionMsg = (exceptionMsg != null  && exceptionMsg.length() >= 32768)? exceptionMsg.substring(0, 32768): exceptionMsg; 
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_GenerateAccrualBatch', reducedExceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            //Updating Market Settings 
        }
        if (marketSetting.ECM_Change_in_Accrual_Logic__c && Schema.sObjectType.Market_Setting__c.isUpdateable()) {
            marketSetting.ECM_Change_in_Accrual_Logic__c = false;
            Database.update(marketSetting, false);
        }
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError); //Schedule Next Batch from Batch Utility Class     
        }
    }
    
}