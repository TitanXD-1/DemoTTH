/*
* Class Name: ECM_GenerateAccrualHelper
* Test Class: ECM_GenerateAccrualBatchTest
* Author: 
* Brief Description: This class is used for ECM_GenerateAccrualBatch.
* Created Date: 19/05/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0               Joshraj Sen         19/05/2024          Initial Development :153431 New batch creation & calculations Part-1_SFDC
* 1.0			    Suvendu Roy		    20/05/2024			153432 - New batch creation & calculations Part-2_SFDC
* 2.0				Sudipta Nandy		03/06/2024			154135 - To populate Payment Frequency field in Accrual Items
* 3.0			    Suvendu Roy		    05/05/2024			154094 - Accrual for Lead Products  in Contracts (Part-1)_SFDC
* 4.0               Joshraj Sen         07/06/2024          153433 - Delete Accruals that have No Accrual Items
*/
 
public with sharing class ECM_GenerateAccrualHelper {
    
    public static  Map<Id,List<String>> conMapToFiscalPeriods;
    public static  Map<Id,List<String>> conMapToExistingFiscalPeriods = new Map<Id,List<String>>();
    public static  Map<Id,Decimal> conItemMapToOldAccItemsTotalVolumn = new Map<Id,Decimal> ();
    public static  Map<Id,Decimal> conItemMapToOldAccItemsAmountWithOutTax = new Map<Id,Decimal> ();
    public static  Map<Id,Decimal> sDIDMapToOldAccItemsAmountWithOutTax = new Map<Id,Decimal> ();
    public static  Set<Id> accrualwithAccrualItems =new Set<Id>();  //My Changes
    public static  Set<String> fiscalYearsToDeletion=new Set<String>();
    

    /**
    * This method is used for deleting Accrual and Accrual Items for the Old to New Logic chnage and Updating MS.
    * @param conList the list of contracts
    * @param marketSetting the Market Setting record for all the Contracts
    */
    public static void deleteExtraAccruals(List<Contract> conList) {
        List<ECM_Accrual__c> accrualListToBeDeleted = new List<ECM_Accrual__c> ();
        String countryCode = conList.get(0).Account.country__r.code__c;
        ECM_Accruals_Financial_Period__mdt metadate = [SELECT Id,ECM_Country_Code__c, ECM_End_Month__c, ECM_Start_Month__c FROM ECM_Accruals_Financial_Period__mdt WHERE ECM_Country_Code__c =:countryCode WITH SECURITY_ENFORCED LIMIT 1 ];
        Integer fiscalYearStartMonth = Integer.ValueOf(metadate.ECM_Start_Month__c);
        Date today = Date.today();
        Integer currentYear = today.year();
        Integer currentMonth = today.month();
        Integer fiscalYearToDelete = currentMonth < fiscalYearStartMonth ? currentYear : currentYear+1;
        System.debug(LoggingLevel.Debug,'Value of fiscalYeartoDelete '+fiscalYearToDelete);
        for(Contract conRec:conList){
            List<String> existingFiscalPeriods= new List<String>();
            for(ECM_Accrual__c accrualRec : conRec.Accruals__r){
                if(Integer.valueOf(accrualRec.ECM_Fiscal_Year__c) >= fiscalYearToDelete){
                    accrualListToBeDeleted.add(accrualRec);
                    fiscalYearsToDeletion.add(accrualRec.ECM_Fiscal_Year__c);
                }else{
                    existingFiscalPeriods.add(accrualRec.ECM_Fiscal_Year__c+'_'+accrualRec.ECM_Period__c);
                }
            }
            if(!existingFiscalPeriods.isEmpty()){
                conMapToExistingFiscalPeriods.put(conRec.Id, existingFiscalPeriods);
            }
        }
        if (Schema.sObjectType.ECM_Accrual__c.isDeletable()) {
            Database.delete(accrualListToBeDeleted, false);
        }
    }
    
    
    
    /**
    * Generate the fiscal periods for a given list of contracts.
    * Set Map Of Fiscal Period to Contract Id in common local variable - conMapToFiscalPeriods[ConID={2024_P1,2024_P2,2024_P3,2024_P4..}]
    * @param conList the list of contracts
    */
    public static void generateFiscalPeriods(List<Contract> conList) {
        conMapToFiscalPeriods = new Map<Id,List<String>>();
        String countryCode = conList.get(0).Account.country__r.code__c;
        ECM_Accruals_Financial_Period__mdt metadate = [SELECT Id,ECM_Country_Code__c, ECM_End_Month__c, ECM_Start_Month__c FROM ECM_Accruals_Financial_Period__mdt WHERE ECM_Country_Code__c =:countryCode WITH SECURITY_ENFORCED LIMIT 1 ];
        
        // Define the start of the fiscal year from Metadata
        Integer fiscalYearStartMonth = Integer.ValueOf(metadate.ECM_Start_Month__c);
        
        for(Contract con : conList){
            List<String> fiscalPeriods = new List<String>();
            Date startDate = con.StartDate;
            Date endDate = con.Contract_End_Date__c;
            Integer totalMonths = ECM_GenerateAccrualExtendedHelper.getDuration(startDate, endDate);
            for(Integer i = 0; i < totalMonths; i++){
                Date currentDate = startDate.addMonths(i);
                Integer currentYear = currentDate.year();
                Integer currentMonth = currentDate.month();
                
                // Calculate the fiscal year
                Integer fiscalYear = currentMonth < fiscalYearStartMonth ? currentYear : currentYear+1;
                // Calculate the fiscal period (1-based index, May is 1, June is 2, ..., April is 12)
                Integer fiscalPeriod = Math.mod((currentMonth - fiscalYearStartMonth + 12), 12) + 1;
                
                // Create the fiscal period string (e.g., 2024_P1)
                //String fiscalPeriodString = 'FY' + String.valueOf(Math.mod(fiscalYear, 100)).leftPad(2, '0') + '_P' + String.valueOf(fiscalPeriod);
                String fiscalPeriodString = String.valueOf(fiscalYear) + '_P' + String.valueOf(fiscalPeriod);
                
                // Add to the list
                if(conMapToExistingFiscalPeriods.containsKey(con.Id) && conMapToExistingFiscalPeriods.get(con.Id).contains(fiscalPeriodString)){
                    System.debug(LoggingLevel.DEBUG,conMapToExistingFiscalPeriods.get(con.Id));
                }else{
                    fiscalPeriods.add(fiscalPeriodString);
                }
            }
            conMapToFiscalPeriods.put(con.Id,fiscalPeriods);
        }
        System.debug(LoggingLevel.DEBUG,conMapToFiscalPeriods);
        //return conMapToFiscalPeriods;
    }
    
    
    /**
     * Generates ECM_Accrual__c records for each contract based on fiscal periods derived from contract duration.
     * @param conList the list of Contract records
     * @return a list of ECM_Accrual__c records
     */
    public static List<ECM_Accrual__c> generateAccruals(List<Contract> conList){
        List<ECM_Accrual__c> accrualList = new List<ECM_Accrual__c> ();
        for(Contract conRec : conList){
            System.debug(LoggingLevel.DEBUG,'conRec: '+conRec.Name+ ' Duration --> '+ conMapToFiscalPeriods.get(conRec.Id).Size());
            for(String str : conMapToFiscalPeriods.get(conRec.Id)){
                ECM_Accrual__c accrualRec = new ECM_Accrual__c();
                accrualRec.ECM_Period__c = str.split('_').get(1);
                accrualRec.ECM_Fiscal_Year__c = str.split('_').get(0);
                accrualRec.ECM_Contract__c = conRec.Id;
                if(conRec.RecordType.Name == 'Outlet'){
                    accrualRec.ECM_Outlet__c = conRec.AccountId;  
                }
                else{
                    accrualRec.ECM_Operator__c=conRec.AccountId; 
                }
                accrualRec.ECM_Unique_Id__c=conRec.Id+'_'+conRec.AccountId+'_'+accrualRec.ECM_Period__c +'_'+accrualRec.ECM_Fiscal_Year__c;
                accrualList.add(accrualRec);
            }
        }
        return accrualList;
    }
    
    /**
    * This method is used to generate the Accrual Items for the Contract Items
    * @param conItemListWithBudgetType This is the map of Contract Items with their respective Budget Types
    * @param internalOrderMapWithKey This is the map of InternalOrdersID with the key as the combination of ProductId-BudgetTypeID-ContractId
    * @param accrualMapWithContractId This is the map of AccrualsID with the key as the combination of ContractId_FiscalYear_Periods
    * @return a list of Accrual Items
    */    
    public static List<ECM_Accrual_Item__c> getAccrualItemsForContractItem(Map<String,List<ECM_Contract_Item__c>> conItemListWithBudgetType, Map<String, Id> internalOrderMapWithKey,Map<String,Id> accrualMapWithContractId){
        
        List<ECM_Accrual_Item__c> accuralItemList=new List<ECM_Accrual_Item__c>();
        String budget = new List<String>(conItemListWithBudgetType.keySet())[0];
        List<ECM_Contract_Item__c> conItemList = conItemListWithBudgetType.get(budget);
        
        for(ECM_Contract_Item__c conItemRec:conItemList){
            Integer conDuration = ECM_GenerateAccrualExtendedHelper.getDuration(conItemRec.ECM_Contract__r.StartDate,conItemRec.ECM_Contract__r.Contract_End_Date__c);
            Integer newDuration = conMapToFiscalPeriods.get(conItemRec.ECM_Contract__c).size();
            Integer length = conDuration - newDuration;
            System.debug(LoggingLevel.Debug,'is Lead brand: '+conItemRec.ECM_Lead_Brand__c+' ->length: '+length+ ' ->duration:  '+conDuration+'-> new: '+newDuration+'-> '+conMapToFiscalPeriods.get(conItemRec.ECM_Contract__c));
            // if (conItemRec.ECM_Lead_Brand__c && conDuration > 12 && length < 12) { //All new contract
            //     System.debug(LoggingLevel.Debug,length+ 'dont Skip Contract Item ');
            //     conDuration = 12;
            // }else if(conItemRec.ECM_Lead_Brand__c && conDuration > 12 && length >= 12){//Old contract with more then equal 12 month Accrual items for lead barand
            //     System.debug(LoggingLevel.Debug,length+ ' Skip Contract Item ');
            //     continue;
            // }
            conDuration = ECM_GenerateAccrualExtendedHelper.adjustDuration(conItemRec.ECM_Lead_Brand__c, conDuration, length);

            System.debug(LoggingLevel.DEBUG,'conRec: '+conItemRec.ECM_Contract__c+ ' 1sDuration --> '+ conMapToFiscalPeriods.get(conItemRec.ECM_Contract__c).Size());
            for(String str: conMapToFiscalPeriods.get(conItemRec.ECM_Contract__c)){
                if(length==conDuration){
                    System.debug(LoggingLevel.Debug,length+ 'Breaking here: '+str);
                    break;
                }
                
                String fiscalYear = str.split('_').get(0);
                String periods = str.split('_').get(1);
                String key = conItemRec.ECM_Contract__c+'_'+fiscalYear+'_'+periods;
                
                ECM_Accrual_Item__c accrualItemRec = new ECM_Accrual_Item__c();
                accrualItemRec.ECM_Product__c = conItemRec.ECM_Product__r.Product__r.Id;
                accrualItemRec.ECM_Contract_Item__c = conItemRec.Id;
                accrualItemRec.ECM_Accrual__c = accrualMapWithContractId.get(key);
                accrualwithAccrualItems.add(accrualItemRec.ECM_Accrual__c); //My Changes
                accrualItemRec.Budget_Pickup_Option__c = budget;// For Accrual Items which are created due to Contract Items, their Budget Type comes from the Market Setting 
                accrualItemRec.ECM_Outlet__c=conItemRec.ECM_Contract__r.AccountId;
                accrualItemRec.ECM_Payment_Frequency__c= conItemRec.ECM_Contract__r.ECM_Payment_Frequency_type__r.ECM_Type__c;//154135
                String secondKey = accrualItemRec.ECM_Product__c+'-'+accrualItemRec.Budget_Pickup_Option__c+'-'+conItemRec.ECM_Contract__c;
                accrualItemRec.ECM_Internal_Order__c=internalOrderMapWithKey.get(secondKey);//The Internal Order shall be populated based on the Product ID, Budget Type,Contract Id and the Start Date of the Contract should be within the Start Date and End Date of the Internal Order
                accrualItemRec.ECM_Target_Volume__c = ECM_GenerateAccrualExtendedHelper.setAccrualItemAmounts(conDuration, length, conItemRec.ECM_Volume__c);
                accrualItemRec.ECM_Amount_Without_Tax__c = ECM_GenerateAccrualExtendedHelper.setAccrualItemAmounts(conDuration, length, conItemRec.ECM_Retro_investment__c);
                
                length++;
                accuralItemList.add(accrualItemRec);
            }
        }
        return accuralItemList;
    }


        
    /**
    * This method is used to generate the Accrual Items for Sales Driver Item Details
    * @param salesDriverItemDetailsList This is the list of Sales Driver Item Details
    * @param internalOrderMapWithKey This is the map of InternalOrdersID with the key as the combination of ProductId-BudgetTypeID-ContractId
    * @param accrualMapWithContractId This is the map of AccrualsID with the key as the combination of ContractId_FiscalYear_Periods
    * @return The list of Accrual Items
    */    
    public static List<ECM_Accrual_Item__c> getAccrualItemsForSalesDriverItemDetails(List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailsList, Map<String, Id> internalOrderMapWithKey,Map<String,Id> accrualMapWithContractId){
        List<ECM_Accrual_Item__c> accuralItemList=new List<ECM_Accrual_Item__c>();
        
        for(ECM_Sales_Driver_Item_Detail__c salesDriverItemDetailsRec:salesDriverItemDetailsList){
            Integer conDuration = ECM_GenerateAccrualExtendedHelper.getDuration(salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__r.StartDate, salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__r.Contract_End_Date__c);
            Integer newDuration = conMapToFiscalPeriods.get(salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__c).size();
            Integer length = conDuration - newDuration;
            System.debug(LoggingLevel.Debug,'is Lead brand: '+salesDriverItemDetailsRec.ECM_Product__r.ECM_Lead_Brand__c+' ->length: '+length+ ' ->duration:  '+conDuration+'-> new: '+newDuration+'-> '+conMapToFiscalPeriods.get(salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__c));
            // if (salesDriverItemDetailsRec.ECM_Product__r.ECM_Lead_Brand__c && conDuration > 12 && length < 12) { //All new contract
            //     System.debug(LoggingLevel.Debug,length+ ' dont Skip Contract Item-sdid ');
            //     conDuration = 12;
            // }else if(salesDriverItemDetailsRec.ECM_Product__r.ECM_Lead_Brand__c && conDuration > 12 && length >= 12){//Old contract with more then equal 12 month Accrual items for lead barand
            //     System.debug(LoggingLevel.Debug,length+ ' Skip Contract Item-sdid ');
            //     continue;
            // }
            conDuration = ECM_GenerateAccrualExtendedHelper.adjustDuration(salesDriverItemDetailsRec.ECM_Product__r.ECM_Lead_Brand__c, conDuration, length);
            
            for(String str: conMapToFiscalPeriods.get(salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__c)){
                if(length==conDuration){
                    System.debug(LoggingLevel.Debug,length+ 'Breaking here: '+salesDriverItemDetailsRec.Id);
                    break;
                }
                String fiscalYear = str.split('_').get(0);
                String periods = str.split('_').get(1);
                String key = salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__c+'_'+fiscalYear+'_'+periods;
                
                ECM_Accrual_Item__c accrualItemRec = new ECM_Accrual_Item__c();
                accrualItemRec.ECM_Product__c = salesDriverItemDetailsRec.ECM_Product__r.ECM_Product__r.Product__r.Id;
                accrualItemRec.ECM_Contract_Item__c = salesDriverItemDetailsRec.ECM_Product__r.Id;
                accrualItemRec.ECM_Accrual__c = accrualMapWithContractId.get(key);
                accrualwithAccrualItems.add(accrualItemRec.ECM_Accrual__c);//My Changes
                accrualItemRec.Budget_Pickup_Option__c = salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__r.Id;
                accrualItemRec.ECM_Outlet__c=salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__r.AccountId;
                accrualItemRec.ECM_Sales_Driver__c=salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c;
                accrualItemRec.ECM_Payment_Frequency__c = salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.ECM_Payment_Frequency__r.ECM_Type__c; //154135
                String secondKey = accrualItemRec.ECM_Product__c+'-'+accrualItemRec.Budget_Pickup_Option__c+'-'+salesDriverItemDetailsRec.ECM_Sales_Driver_Item__r.Contract__c;
                accrualItemRec.ECM_Internal_Order__c=internalOrderMapWithKey.get(secondKey);
                accrualItemRec.ECM_Amount_Without_Tax__c = ECM_GenerateAccrualExtendedHelper.setAccrualItemAmounts(conDuration, length, salesDriverItemDetailsRec.ECM_Investment_Amount__c);
                
                length++;
                accuralItemList.add(accrualItemRec);
            }
        }
        return accuralItemList;
    }
    
    public static void deleteAccrualWithNoAccrualItems(List<Id> accrualIdValueSet){
        System.debug(LoggingLevel.Debug,'@@@ Value 1 '+conMapToFiscalPeriods.keySet().size());
        System.debug(LoggingLevel.Debug,'@@@ Value 2 '+accrualwithAccrualItems.size());
        List<ECM_Accrual__c> deleteAccruals=[Select Id from ECM_Accrual__c where Id not in :accrualwithAccrualItems and Id in :accrualIdValueSet];
        System.debug(LoggingLevel.Debug,'@@@ Value 3 '+deleteAccruals.size());
        if(deleteAccruals!=null && deleteAccruals.size()>0 && Schema.sObjectType.ECM_Accrual__c.isDeletable())
        {   
            Database.delete(deleteAccruals,true);
        }         
    }
}