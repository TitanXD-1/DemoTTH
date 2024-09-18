/**********************************************************************
Class Name: ECM_AccrualforAnP_TI_RetroBatch
TestClassName : ECM_AccrualItemsCalculation_Batch_Test
=======================================================================
Req: This batch class to insert Accrual and Accrual Item for every contract Item for Retro(Volume) and for A&P and TI Sales drivers .

=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR					DATE			DETAIL
1.0		Pravalika Glamari		08/02/2021		ECM-3887 -  Batch for calculating Retro Volume accruals_SFDC_US2_Accrual
1.1		Veerendra Billakurthi	10/02/2021		ECM-3888 - Batch for Calculating Accrual Items for A&P and TI Sales drivers_SFDC_US3_Accrual
1.2		Chandrakanth Suram		26/02/2021		ECM-3961 - Modifying the Target Volume from Decimal to whole number in Accrual item	
1.3		Pravalika Glamari		25/02/2021		ECM-3967 - Logic to populate Internal order field _SFDC_Accrual
1.4		Anshu Prakash			26/02/2021		ECM-3966 - Modifying the Amount without Tax Formula _SFDC_Accrual
1.5		Chandrakanth Suram/		02/03/2021		ECM-3962 - Calculating Tiering Volume accruals for Group Contract/Outlet Contract_SFDC_Accrual
		Saurav Prasad
1.6		Pravalika Glamari		08/03/2021		ECM-3969 - Populating Sales driver field in the Accrual item _SFDC_Accrual
1.7		Chandrakanth Suram		15/03/2021		ECM-4071 - Changing the Start point as April for Batch decimal calculation
1.8		Anshu					10/05/2021		ECM-4143 - Populating Acrrual item forecast Volume and Forecast Amount
1.9		Chandrakanth Suram		16/06/2021		ECM-4446 - Budget Type TI and A&P hard coding is removed for Sales Driver Item Query
2.0		Wribhu Bose				21/12/2022		ECM-6574 - Accrual Fiscal Year fix; 1 Jul to 31 Dec: CY + 1, 1 Jan to 30 Jun: CY
2.1		Saikiran				04/06/2024		153429 - Logic to run the batch if the Market setting is set to 'Whole Numbers'
2.2		Saurav Prasad			16/09/2024		154645 - CM Classes_Fix Static Code Analysis_Contract Management
************************************************************************/
public class ECM_AccrualforAnP_TI_RetroBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; 
    String countryCode ='';
    String budget;
    
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
        countryCode = batchSetting.Country_Code__c;
    }
    /** Start Method **/   
    public Database.QueryLocator start(Database.BatchableContext bc)
    {        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        
        //Query to check if  Accrual creation in market setting changed to Whole Numbers 
        Id contractGroupRecordtypeId=Contract.sobjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        System.debug(LoggingLevel.DEBUG,contractGroupRecordtypeId);
        Id contractOutletRecordtypeId=Contract.sobjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        System.debug(LoggingLevel.DEBUG,contractOutletRecordtypeId);
        Market_Setting__c marketSetting = [Select Id,ECM_Budget_Type_for_Volume_Based_PS__c,Accrual_Creation__c,ECM_Change_in_Accrual_Logic__c from Market_Setting__c where Geography__r.Code__c=:countryCode Limit 1];
        String strQuery='';
        
        if(marketSetting.Accrual_Creation__c =='Whole Numbers' ){ //153429
            budget = marketSetting.ECM_Budget_Type_for_Volume_Based_PS__c;
            
            strQuery = 'SELECT Id, Name, Status, AccountId, StartDate,account.recordtypeid, Contract_End_Date__c, ECM_Is_Accrual_Created__c, '+
                'RecordType.Name, ECM_Duration__c, Account.country__r.code__c, ECM_Agreement_Type__r.Geography__c, '+
                '(SELECT Id, ECM_Product_Name__c, ECM_Contract__c,  ECM_Contract__r.Account.country__r.code__c, '+
                'ECM_Product__r.Product__r.Id, ECM_Retro_investment__c, ECM_Contract__r.StartDate, '+
                'ECM_TotalSKU_SpecificRebate__c, ECM_Product__c, ECM_Lead_Brand__c, '+
                'ECM_Product__r.Product__c, ECM_Volume__c, ECM_Contract__r.AccountId,'+
                'ECM_UoM__c,ECM_Contract__r.ECM_Payment_Frequency_type__r.ECM_Type__c FROM Contract_Items__r WHERE ECM_Retro_investment__c > 0) ';
            
            strQuery +='FROM Contract WHERE (RecordTypeid=: contractOutletRecordtypeId OR RecordTypeid=: contractGroupRecordtypeId) '+
                'AND Account.country__r.code__c =: countryCode AND Status = \'Active\'';
        }
        else{
            strQuery='SELECT Id FROM Contract LIMIT 0';
        }
        return Database.getQueryLocator(strQuery);
    }
    
    /** Execute Method **/ 
    public void execute(Database.BatchableContext bc, List<Contract> scope){
       
        //Set<Id> exitedAccruals = new Set<Id>();
        
        try{
            List<ECM_Accrual_Period__c> apList= [select id,Period__c,ECM_Start_Date__c,ECM_End_Date__c,ECM_Market_Setting__r.Geography__r.code__c,ECM_Market_Setting__r.ECM_Budget_Type_for_Volume_Based_PS__c,
                                                 ECM_Is_Forecast__c,ECM_Market_Setting__r.ECM_Tiering_consideration_for_Accrual__c from ECM_Accrual_Period__c 
                                                 where ECM_Payment_Calculation_Date__c=:System.today() and ECM_Market_Setting__r.Geography__r.code__c =: countryCode
                                                 AND period__c!=null AND ECM_Market_Setting__r.ECM_Budget_Type_for_Volume_Based_PS__c!=null 
                                                 order by ECM_Start_Date__c desc];
            if(!(apList.isEmpty())){
                System.debug(LoggingLevel.DEBUG,apList[0]);
                budget=apList[0].ECM_Market_Setting__r.ECM_Budget_Type_for_Volume_Based_PS__c;
                System.debug(LoggingLevel.Debug,'apList @'+apList[0]);
                //AccStart=apList[0].ECM_Start_Date__c;
                //Start added as part of ECM-4663-Production Fix
                //}
                //End added as part of ECM-4663-Production Fix
                //ECM-4143 starts
                
                //154645
                WrapperCls wrapperInstance = new WrapperCls();
                
                wrapperInstance = ECM_AccrualforAnP_TI_RetroBatchHelper.processMapping(scope,apList);
                System.debug(LoggingLevel.Debug,'wrapperInstance @'+wrapperInstance);
                //ECM-4143 ends
                
                
                handleIteration(scope,apList,wrapperInstance);
                
               
                //Start added as part of ECM-4663-Production Fix
            }
            //End added as part of ECM-4663-Production Fix
            
        }
        catch(DmlException de){
            exceptionHandler(de,null);
        }
        catch(Exception ex) {
            exceptionHandler(null,ex);
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_AccrualforAnP_TI_RetroBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
            
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
    
    /** 
     * 154645 : Additonal method for PMD violations* 
     * */
    
    public void exceptionHandler(DmlException de,Exception ex){
        hasError = true;
        if(de!=Null){
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }else{
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
        
        System.debug(LoggingLevel.Debug,'exceptionMsg @'+exceptionMsg);
    }
    
    
    private void handleIteration(List<Contract> scope, List<ECM_Accrual_Period__c>apList,WrapperCls wrapperInstance){
        Map<String,ECM_Accrual__c>accuralMap= new  Map<String,ECM_Accrual__c>();
        List<ECM_Accrual_Item__c> accuralItemList= new List<ECM_Accrual_Item__c>();
        set<id> accrualWithItems= new set<id>();
        Map<String,List<ECM_Sales_Driver_Item_Detail__c>> salesdriveMap = new  Map<String,List<ECM_Sales_Driver_Item_Detail__c>>();
        
        salesdriveMap = wrapperInstance.salesdriveMap; //154645
        accuralMap = wrapperInstance.accuralMap;//154645
        
        for(Contract c : scope){ 
            for(ECM_Contract_Item__c contractItem: c.Contract_Items__r){
                //Retro Volume check                
                ECM_Accrual_Item__c accrualItem= new ECM_Accrual_Item__c();
                AccuralWrapper wrap = new AccuralWrapper();
                wrap.c = c;
                wrap.contractItem = contractItem;
                wrap.apList = apList;
                
                accrualItem = ECM_AccrualforAnP_TI_RetroBatchHelper.accuralItemCIMapping(wrap, wrapperInstance, this.budget);
                
                accrualItem.ECM_Accrual__c=accuralMap.get(c.id).Id;
                accrualWithItems.add(accuralMap.get(c.id).Id);
                System.debug(LoggingLevel.Debug,'Contract Item accrualItem @'+accrualItem);
                accuralItemList.add(accrualItem);
            }
            
            //sales drivers items details with budget check TI and A&P
            if (salesdriveMap.containsKey(c.id)){
                
                for(ECM_Sales_Driver_Item_Detail__c salesDriverItemDetail:salesdriveMap.get(c.id) ){
                    
                    ECM_Accrual_Item__c accItem= new ECM_Accrual_Item__c();
                    accItem = accuralItemSDMapping(c, wrapperInstance, salesDriverItemDetail);
                    accItem.ECM_Accrual__c=accuralMap.get(c.id).Id;
                    System.debug(LoggingLevel.Debug,'Sales Driver accItem @'+accItem);
                    accrualWithItems.add(accuralMap.get(c.id).Id);
                    accuralItemList.add(accItem);
                }
                
            }
        }
        if(!(accuralItemList.isEmpty())){
            
            Database.insert(accuralItemList,false);
        }
        System.debug(Logginglevel.debug,'accuralItemList @'+accuralItemList);
        deleteAccruals(accuralMap, accrualWithItems);
    }
    
    private ECM_Accrual_Item__c accuralItemSDMapping(Contract c, WrapperCls wrapperInstance, ECM_Sales_Driver_Item_Detail__c salesDriverItemDetail){
        map<string,ECM_Internal_Order__c> internalOrderMap = wrapperInstance.internalOrderMap;
        ECM_Accrual_Item__c accItem= new ECM_Accrual_Item__c();
        accItem.ECM_Product__c=salesDriverItemDetail.ECM_Product__r.ECM_Product__r.Product__r.id;
        accItem.ECM_Amount_Without_Tax__c=salesDriverItemDetail.ECM_Investment_Amount__c/salesDriverItemDetail.ECM_Sales_Driver_Item__r.Contract__r.ECM_Duration__c;
        accItem.ECM_Contract_Item__c=salesDriverItemDetail.ECM_Product__c;
        accItem.Budget_Pickup_Option__c=salesDriverItemDetail.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__r.id; 
        accItem.ECM_Outlet__c=c.AccountId;
        accItem.ECM_Sales_Driver__c=salesDriverItemDetail.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c;
        
        if(internalOrderMap.containsKey(String.valueOf(c.ECM_Agreement_Type__r.Geography__c+'-'+accItem.ECM_Product__c+'-'+accItem.Budget_Pickup_Option__c))){
            accItem.ECM_Internal_Order__c=internalOrderMap.get(String.valueOf(c.ECM_Agreement_Type__r.Geography__c+'-'+accItem.ECM_Product__c+'-'+accItem.Budget_Pickup_Option__c)).id;
        }
        
        return accItem;
    }
    
    private void deleteAccruals(Map<String,ECM_Accrual__c>accuralMap, set<id> accrualWithItems){
        //removing accrual with no accrual item
        List<ECM_Accrual__c> deleteAccrualList= new list<ECM_Accrual__c>();
        for(ECM_Accrual__c accrual:[SELECT Id from ECM_Accrual__c where id IN:accuralMap.values() AND id NOT IN:accrualWithItems]){
            deleteAccrualList.add(accrual);
        }
        System.debug(LoggingLevel.DEBUG,'deleteAccrualList-->'+deleteAccrualList);
        if(deleteAccrualList.size()>0){
            Database.delete(deleteAccrualList);
        }
    }
    
    public class WrapperCls {
        public Map<String,ECM_Accrual__c>accuralMap;        
        public Map<string,Decimal> depletionProductMap;
        public Map<Id,ECM_Tiering__c> tierMap;
        public map<string,ECM_Internal_Order__c> internalOrderMap;
        public Map<String,List<ECM_Sales_Driver_Item_Detail__c>> salesdriveMap;
        
        public WrapperCls(){
            this.accuralMap  = new  Map<String,ECM_Accrual__c>();
            this.depletionProductMap = new Map<String,Decimal>();
            this.tierMap = new Map<Id,ECM_Tiering__c>();
            this.internalOrderMap = new map<string,ECM_Internal_Order__c>();
            this.salesdriveMap = new Map<String,List<ECM_Sales_Driver_Item_Detail__c>>();
        } 
    }
    
    
    public class AccuralWrapper {
        
        public Contract c;
        public ECM_Contract_Item__c contractItem;
        public List<ECM_Accrual_Period__c> apList;
        
        public void accrualWrapper(){
            this.c = new Contract();
            this.contractItem = new ECM_Contract_Item__c();
            this.apList = new List<ECM_Accrual_Period__c>();
        }
        
    }
}