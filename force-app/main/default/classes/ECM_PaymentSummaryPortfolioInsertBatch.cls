/*
Name: ECM_PaymentSummaryPortfolioInsertBatch
*
*
*
History                                                            
*                                                            
VERSION      AUTHOR                   DATE              DETAIL
1.0       Anivesh Muppa            05/02/2021        Initial Development
2.0       Joshraj Sen              20/12/2023        146153 No Payment Summaries for CRG Contracts 
3.0       Joshraj Sen              01/04/2024        152305 Batch Fix
*/

public class ECM_PaymentSummaryPortfolioInsertBatch implements Database.Batchable<sObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    private String COUNTRYNAME = 'Australia';
    string exceptionMsg = '';
    boolean hasError = false ;
    Market_Batch_Setting__mdt batchSetting;
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    public Database.QueryLocator start(Database.BatchableContext BC){
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        String crgRecordTypeId = '';//146153
        crgRecordTypeId=Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();
        string countryCode = batchSetting.Country_Code__c;
        
        //if (rebateCalendarMap.Size() > 0) {
        return Database.getQueryLocator([select Id,UOS_Rebate_Rate__c,Status,Accountid,Account.Parent_Outlet__c,Account.Recordtypeid,RecordTypeId,Account.Hybrid__c,(select id,ECM_Product_Name__c,ECM_Total_SKU_Specific_Rebate__c,ECM_TotalSKU_SpecificRebate__c,ECM_Product__c,ECM_Product__r.Product__c from Contract_Items__r) from Contract where Status ='Active' and 
                                         Account.country__r.Code__c=:countryCode AND UOS_Rebate_Rate__c>0 AND RecordTypeID != :crgRecordTypeId]);//146153
        /*
}else{
return Database.getQueryLocator([
select Id,UOS_Rebate_Rate__c,Status,accountid,account.recordtypeid,(select id,ECM_Product_Name__c,ECM_Total_SKU_Specific_Rebate__c,ECM_TotalSKU_SpecificRebate__c,ECM_Product__c,ECM_Product__r.Product__c from Contract_Items__r) from Contract where Status ='Active' and 
Account.country__r.Code__c=:countryCode limit 0]);
}*/
    }
    public void execute(Database.BatchableContext BC, List<Contract>scope){
        string BUDGET_TYPE = 'Portfolio Rebates [AU]'; 
        ECM_Rebates_Calendar__mdt rebateCalendarMap;
        Map<id,set<string>> productSet = new Map<id,set<string>>();
        Map<String,Decimal> depletionCountForOutlets = new Map<String,Decimal>();
        List<ECM_Payment_Summary_Item__c> newPSItemList = new list<ECM_Payment_Summary_Item__c>();
        Id budgetType_RecordId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        Id outlet_RecordId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Set<Id> AccountId = new Set<Id>(); 
        Map<ID,Set<string>> ConIdWithAccId = new Map<ID,Set<string>>();
        List < ECM_Payment_Summary__c > paymentUpdateLst = new List < ECM_Payment_Summary__c > ();
        List<ECM_Rebates_Calendar__mdt> rebateCalendar =new List<ECM_Rebates_Calendar__mdt>();
        String queryString='';
        if(!Test.isRunningTest())
        {
            queryString='SELECT ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_Start__c, ECM_Rebate_Period_End__c, ECM_Region__c, ECM_Financial_Year__c, ECM_Quarter__c, Id FROM ECM_Rebates_Calendar__mdt Where ECM_Rebate_Calculation_Date__c =TODAY LIMIT 1';         
        }
        else
        {
            String year='2023';
            queryString='SELECT ECM_Rebate_Calculation_Date__c, ECM_Rebate_Period_Start__c, ECM_Rebate_Period_End__c, ECM_Region__c, ECM_Financial_Year__c, ECM_Quarter__c, Id FROM ECM_Rebates_Calendar__mdt Where ECM_Financial_Year__c =:year LIMIT 1';
        }
        rebateCalendar=Database.query(queryString);
        
        
        try{
            if(rebateCalendar!=Null && rebateCalendar.size()>0){
                rebateCalendarMap = rebateCalendar[0];
                Pick_Up_Options__c pickOptionRecord= [select id, Name, Geography__r.Name, Status__c, RecordTypeId from Pick_Up_Options__c
                                                      Where Geography__r.Code__c =: batchSetting.Country_Code__c AND Name =: BUDGET_TYPE AND Status__c = 'Active'
                                                      AND RecordTypeId =: budgetType_RecordId limit 1
                                                     ];
                for(Contract contrt : scope){
                    // if(contrt.RecordTypeId == outlet_RecordId){
                    ECM_Payment_Summary__c paymntRecord = new ECM_Payment_Summary__c();
                    paymntRecord.ECM_Contract__c = contrt.Id;
                    paymntRecord.ECM_Type__c = 'Volume-Based';
                    paymntRecord.ECM_Budget_types__c = pickOptionRecord.Id;//budgetTypeValues.size() > 0 && budgetTypeValues.containskey('SKU Specific Rebates [AU]') ? budgetTypeValues.get('SKU Specific Rebates [AU]').Id : Null;
                    paymntRecord.ECM_Payment_Summary_Status__c = 'Open';
                    paymentUpdateLst.add(paymntRecord);
                    Set<string> accIds = new Set<string>();
                    if(ConIdWithAccId.containskey(contrt.Id)){
                        accIds = ConIdWithAccId.get(contrt.Id);
                    }
                    if(contrt.Account.Hybrid__c && contrt.Account.parent_outlet__c!=null){
                        accIds.add(contrt.Account.parent_outlet__c);
                        ConIdWithAccId.put(contrt.Id,accIds); 
                        AccountId.add(contrt.Account.parent_outlet__c);
                    }else{
                        accIds.add(contrt.AccountId);
                        ConIdWithAccId.put(contrt.Id,accIds);  
                        AccountId.add(contrt.AccountId);
                    }
                    
                    // }                    
                }
                for(Outlet_Contract__c o: [select id,Outlet__c,Contract__c from Outlet_Contract__c where Contract__c in:ConIdWithAccId.keyset()]){
                    if(o.Outlet__c!=null){
                        AccountId.add(o.Outlet__c);
                    }     
                    if(ConIdWithAccId.containskey(o.Contract__c)){                        
                        ConIdWithAccId.get(o.Contract__c).add(o.Outlet__c);                        
                    }else{
                        ConIdWithAccId.put(o.Contract__c,new Set<String>{o.Outlet__c});
                    }
                }
                
                // Date startDate = ECM_PS.ECM_Contract__r.StartDate > rebateCalendarMap.ECM_Rebate_Period_Start__c?ECM_PS.ECM_Contract__r.StartDate:rcMDT.ECM_Rebate_Period_Start__c;
                for(Depletions__c depletionRecord: [SELECT Id, ECM_Outlet__c, ECM_Start_Period__c,ECM_Product__r.Name, ECM_End_Period__c, ECM_Product__c,ECM_geography__r.code__c,
                                                    ECM_Volume__c, ECM_UoM__c FROM Depletions__c Where ECM_geography__r.code__c=:batchSetting.Country_Code__c AND ECM_Start_Period__c>=:rebateCalendarMap.ECM_Rebate_Period_Start__c 
                                                    AND ECM_End_Period__c<=:rebateCalendarMap.ECM_Rebate_Period_End__c AND ECM_Volume__c>0 AND ECM_Outlet__c IN:AccountId]){
                                                        set<string> prodIds =  new set<string>();
                                                        if(productSet.containskey(depletionRecord.ECM_Outlet__c))
                                                            prodIds = productSet.get(depletionRecord.ECM_Outlet__c);
                                                        prodIds.add(depletionRecord.ECM_Product__c);
                                                        productSet.put((ID)depletionRecord.ECM_Outlet__c,prodIds);
                                                        if(AccountId.contains(depletionRecord.ECM_Outlet__c)){
                                                            if(depletionCountForOutlets.containsKey(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c)){
                                                                Decimal volumeRate = depletionCountForOutlets.get(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c)+depletionRecord.ECM_Volume__c;
                                                                depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c,volumeRate);
                                                            }else{
                                                                depletionCountForOutlets.put(depletionRecord.ECM_Outlet__c+'-'+depletionRecord.ECM_Product__c,depletionRecord.ECM_Volume__c);
                                                            }
                                                        }
                                                        
                                                    }
                
                
                try{
                    List<Database.SaveResult> insertResults = new List<Database.SaveResult>();
                    if(paymentUpdateLst.size()>0){
                        insertResults = Database.insert(paymentUpdateLst, false);
                    }
                    Set<Id> successIds = new Set<Id>();
                    
                    for (Database.SaveResult sr : insertResults) {
                        if (sr.isSuccess()) {
                            // Operation was successful, so get the ID of the record that was processed
                            System.debug('Successfully inserted Payment summary ID: ' + sr.getId());
                            successIds.add(sr.getId());
                        }
                        else {
                            // Operation failed, so get all errors                
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('The following error has occurred.');                    
                                System.debug(err.getStatusCode() + ': ' + err.getMessage());
                            }
                        }
                    }
                    for(ECM_Payment_Summary__c PSinserted : paymentUpdateLst){
                        if(successIds.contains(PSinserted.Id)){
                            for(string accId : ConIdWithAccId.get(PSinserted.ECM_Contract__c)){
                                if(productSet.containskey(accId)){
                                    for(string prodId : productSet.get(accId)){                                        
                                        ECM_Payment_Summary_Item__c newPSI = new ECM_Payment_Summary_Item__c();
                                        newPSI.ECM_Payment_Summary__c = PSinserted.Id;
                                        newPSI.ECM_Product__c = prodId;
                                        newPSI.ECM_Actual_Cases__c = depletionCountForOutlets.get(accId+'-'+prodId)==NULL?0:depletionCountForOutlets.get(accId+'-'+prodId);
                                        newPSI.ECM_Confirmed_Volume__c = 0; 
                                        newPSI.ECM_Confirm__c= true;
                                        newPSItemList.add(newPSI);
                                    }
                                }
                                
                            }
                            /*if(ConIdWithAccId.containskey(PSinserted.ECM_Contract__c) && productSet.containskey(ConIdWithAccId.get(PSinserted.ECM_Contract__c))){
for(string prodId : productSet.get(ConIdWithAccId.get(PSinserted.ECM_Contract__c))){
integer volume = 0;

ECM_Payment_Summary_Item__c newPSI = new ECM_Payment_Summary_Item__c();
newPSI.ECM_Payment_Summary__c = PSinserted.Id;
newPSI.ECM_Product__c = prodId;
newPSI.ECM_Actual_Cases__c = depletionCountForOutlets.get(ConIdWithAccId.get(PSinserted.ECM_Contract__c)+'-'+prodId)==NULL?0:depletionCountForOutlets.get(ConIdWithAccId.get(PSinserted.ECM_Contract__c)+'-'+prodId);
newPSI.ECM_Confirmed_Volume__c = 0; 
newPSI.ECM_Confirm__c= true;
newPSItemList.add(newPSI);
}
}                            */
                        }
                    }
                    system.debug('PSI to Insert ='+newPSItemList);
                    if(newPSItemList.Size()>0){
                        Insert newPSItemList;
                    }
                }catch(DmlException de){
                    hasError = true;
                    Integer numErrors = de.getNumDml();
                    for(Integer i=0; i<numErrors; i++) {
                        exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
                    }
                    system.debug('Exception @ '+de.getMessage());            
                }  
            }            
        }catch(Exception Ex){
            system.debug('Exception @ '+Ex.getMessage());
        } 
        
        
    }
    public void finish(Database.BatchableContext BC){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'ECM_PaymentSummaryPortfolioInsertBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
    
}