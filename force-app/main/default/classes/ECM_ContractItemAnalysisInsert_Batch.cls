/**********************************************************************
Name: ECM_ContractItemAnalysisInsert_Batch
=======================================================================
Purpose: This Class is used to insert records to contract item analysis object through batch.
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0       Veerendra Billakurthi    13/08/2020        Initial Development
1.1      Anivesh Muppa             15/08/2020        Initial Development
1.2      Veerendra Billakurthi     04/01/2021        ECM-3554

***********************************************************************/ 


global class ECM_ContractItemAnalysisInsert_Batch implements Database.Batchable<sObject>, Database.Stateful {
    
    global ECM_ContractItemAnalysisInsert_Batch(){
    }
    
    global Database.QueryLocator start(Database.BatchableContext BC){
        //SELECT Id,Name,ECM_Contract__c,ECM_Product__r.Base_UOM__c,ECM_Product__r.Product__c,ECM_Contract__r.StartDate,ECM_Contract__r.ECM_Duration__c,ECM_Contract__r.AccountID,ECMTotal_Additional_Discounts_for_Banner__c,ECM_AnP_investment__c,ECM_Baseline_volume__c,ECM_CAP_ROI_EU__c,ECM_FinalLUC_Current__c,ECM_FinalLUC_Target__c,ECM_First_Pour__c,ECM_GP_ROI_EU__c,ECM_Generated_NSV_EU__c,ECM_Gross_Profit__c,ECM_Gross_margin__c,ECM_Hybrid_ON__c,ECM_Investment__c,ECM_LUC_Discount__c,ECM_Lead_Brand__c,ECM_MAT_ON__c,ECM_MAT_UOS_ON__c,ECM_MAT_UOS__c,ECM_MAT_original__c,ECM_MAT_override__c,ECM_Mandatory_Back_Bar__c,ECM_NSV__c,ECM_Price_List_ConItem__c,ECM_Product_Name__c,ECM_Product__c,ECM_Retro_investment__c,ECM_TSDD_Original__c,ECM_TSDD_Override__c,ECM_TotalAdditional_Discount__c,ECM_TotalSKU_SpecificRebate__c,ECM_Total_Additional_Dis_for_Ban_ON__c,ECM_Total_COGS_ON__c,ECM_Total_COGS__c,ECM_Total_GP_EU__c,ECM_Total_GP_ON__c,ECM_Total_GP__c,ECM_Total_SKU_Specific_Off_Invoice_ON__c,ECM_Total_SKU_Specific_Off_Invoice__c,ECM_Total_SKU_Specific_Rebate_ON__c,ECM_Total_SKU_Specific_Rebate__c,ECM_Total_Sales_Driver_Discount_ON__c,ECM_Total_Sales_Driver_Discount__c,ECM_Trade_investments__c,ECM_UOS__c,ECM_UoM__c,ECM_Retro_investment__c,ECM_Volume_Target_Investment_Description__c,ECM_Volume__c,ECM_Volume_hybrid_original__c,ECM_volume_hybrid_override__c,ECM_Actual_Volume_YTD__c,ECM_Volume_Target_per_PF__c,ECM_Category__c,ECM_Brand__c FROM ECM_Contract_Item__
        //select Id,(select id, ECM_Budget_Type__c from Sales_Driver_Item_Details__r)  from ECM_Contract_Item__c
        //Sales_Driver_Item_Details__r==Null{}
        return Database.getQueryLocator([
            select Id,ECM_Product_Name__c,ECM_Contract__r.Contract_End_Date__c,ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name,ECM_Contract__r.Account.SAP_Sold_to__c,ECM_Contract__r.Account.Geolocation__c,ECM_Contract__r.Account.Country__r.Name,ECM_Contract__r.Account.Sales_Org__c ,CurrencyIsoCode,ECM_Contract__r.ContractNumber,ECM_Contract__r.ECM_Agreement_Type__r.Name,ECM_Contract__r.ECM_Territory__r.Name,
            ECM_Contract__c,ECM_Contract__r.ECM_Fiscal_Years__c,ECM_Contract__r.Status,ECM_UoM__c,ECM_Retro_investment__c,ECM_Product__r.ECM_INTO_Material__c,ECM_Contract__r.RecordTypeId,ECM_Contract__r.ECM_Territory__c,
            ECM_Product__r.Base_UOM__c,ECM_Product__r.Product__c,ECM_Contract__r.StartDate,ECM_Contract__r.ECM_Duration__c,ECM_Contract__r.AccountID,ECM_Contract__r.Name,ECM_Contract__r.ECM_Territory__r.Sales_Area__r.Name
            ,(select id, ECM_Budget_Type__c from Sales_Driver_Item_Details__r) from ECM_Contract_Item__c where ECM_Contract__r.Contract_End_Date__c >= TODAY and
            (ECM_Contract__r.Status !='Cancelled' AND ECM_Contract__r.Status !='Lost' AND ECM_Contract__r.Status !='Won' AND ECM_Contract__r.Status !='Terminated') 
        ]);
    }
    
    
    
    global void execute(Database.BatchableContext BC, List<ECM_Contract_Item__c>scope){
        system.debug('scopeeinsert'+scope);
        Map<string,Decimal> getAmountwithoutTaxS = new Map<string,Decimal>(); 
        ECM_AccrualsAmountCalculator AccrualsAmntCaltr = new ECM_AccrualsAmountCalculator();//.getAmountwithoutTax(Id,ECM_Contract_Item__c);
        getAmountwithoutTaxS = AccrualsAmntCaltr.getAmountwithoutTax(new Map<Id,ECM_Contract_Item__c>(scope)); 
        Set<Id> prodid = new Set<Id>();
        for(ECM_Contract_Item__c prod : scope ){
            prodid.add(prod.ECM_Product__r.Product__c);
            
        }
        Set<Id> accids = new Set<Id>();
        Set<Id> prodids = new Set<Id>();
        Map<string,ECM_Contract_Item_Analysis__c> ciaBudget = new Map<string,ECM_Contract_Item_Analysis__c>(); 
        List<string> uniqueContractProduct = new List<string>();
        Map<string,Decimal> conitemBudgetWithAmount = new  Map<string,Decimal>(); 
        Date lastDate = system.today().addmonths(-1);
        integer periodval =  system.today().month();
        
        string fiscal = ECM_AccrualsAmountCalculator.FiscalYear(system.today().toStartOfMonth(),system.today().addMonths(1).addDays(-1)).removeEndIgnoreCase('/');
        system.debug('fiscal-='+fiscal);
        integer periodval1=0;
        if(periodval>6){
            periodval1 = (periodval-7)+1;
        }else{
            periodval1 = periodval+6;
        }
        system.debug('=='+periodval1); 
        
        list <ECM_Internal_Order__c> INLIST = [select id,Name,ECM_Budget_Type_Pickup_Option__r.Name,ECM_Geography__r.Name,ECM_Fiscal_Year__c,
                                               ECM_Product__r.Name from ECM_Internal_Order__c
                                               where (ECM_Budget_Type_Pickup_Option__r.Name= 'TI [ES]' OR ECM_Budget_Type_Pickup_Option__r.Name= 'A&P [ES]') /*and ECM_Product__c IN : prodid*/];
        Map<String,String> iomap =new Map<String,String>();
        
        
        for(ECM_Internal_Order__c icocheck : INLIST){            
            iomap.put(icocheck.ECM_Product__r.Name+'-'+icocheck.ECM_Budget_Type_Pickup_Option__r.Name+'-'+icocheck.ECM_Geography__r.Name+'-'+icocheck.ECM_Fiscal_Year__c,icocheck.Name);
        }
        system.debug('Batch ='+getAmountwithoutTaxS);
        system.debug('iomapvaluesss--'+iomap);
        List<ECM_Contract_Item__c> CIList = new List<ECM_Contract_Item__c>();
        List<ECM_Contract_Item_Analysis__c> CAList = new List<ECM_Contract_Item_Analysis__c>();
        
        for(ECM_Contract_Item__c si : scope){ 
            Set<String> uniqBudgettype = new Set<string>();            
            if(si.Sales_Driver_Item_Details__r !=null){
                for(ECM_Sales_Driver_Item_Detail__c SDI :si.Sales_Driver_Item_Details__r ){
                    if(SDI.ECM_Budget_Type__c!=Null && !uniqBudgettype.contains(SDI.ECM_Budget_Type__c)){
                        uniqBudgettype.add(SDI.ECM_Budget_Type__c);
                        /*
                        ECM_Contract_Item_Analysis__c ContAns = new ECM_Contract_Item_Analysis__c();
                        ContAns.ECM_Budget_Type_Name__c  = SDI.ECM_Budget_Type__c ;
                        ContAns.ECM_Contract_Status__c = si.ECM_Contract__r.Status; 
                        ContAns.ECM_Product_Name__c = si.ECM_Product_Name__c;
                        ContAns.ECM_Fiscal_Year__c = fiscal;
                        ContAns.ECM_Agreement_Type_Name__c=si.ECM_Contract__r.ECM_Agreement_Type__r.Name;
                        ContAns.CurrencyIsoCode= si.CurrencyIsoCode;
                        system.debug(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c+'getAmountwithoutTaxS=='+getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c));
                        ContAns.Amount_Without_Tax__c = getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c);
                        ContAns.ECM_Contract_Item_ID__c = si.Id;
                        ContAns.ECM_Sales_Org__c = si.ECM_Contract__r.Account.Sales_Org__c;
                        ContAns.ECM_SAP_sold_to__c = si.ECM_Contract__r.Account.SAP_Sold_to__c;          
                        ContAns.ECM_INTO_Material__c = String.valueOf(si.ECM_Product__r.ECM_INTO_Material__c);
                        ContAns.ECM_Period__c = 'P'+String.valueOf(periodval1);
                        ContAns.ECM_Internal_Order__c = iomap.get(si.ECM_Product_Name__c+'-'+SDI.ECM_Budget_Type__c+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal);
                        ContAns.ECM_Territory__c = si.ECM_Contract__r.ECM_Territory__r.Name;
                        ContAns.ECM_Territory_Hierarchy__c = si.ECM_Contract__r.ECM_Territory__r.Sales_Area__r.Name;
                        ContAns.ECM_Concept__c= si.ECM_Contract__r.ContractNumber;
                        system.debug('si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Nam'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name);
*/
                        CAList.add(mapconitemanysis(si,fiscal,getAmountwithoutTaxS,string.valueOf(periodval1),iomap.get(si.ECM_Product_Name__c+'-'+SDI.ECM_Budget_Type__c+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal),SDI.ECM_Budget_Type__c));
                    }                    
                }
                if(!uniqBudgettype.contains('TI [ES]')){
                    if(si.ECM_Retro_investment__c !=Null && si.ECM_Retro_investment__c >0){
                       CAList.add(mapconitemanysis(si,fiscal,getAmountwithoutTaxS,string.valueOf(periodval1),iomap.get(si.ECM_Product_Name__c+'-'+'TI [ES]'+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal),'TI [ES]'));
/*
                        ECM_Contract_Item_Analysis__c ContAns = new ECM_Contract_Item_Analysis__c(); 
                        ContAns.ECM_Budget_Type_Name__c = 'TI [ES]';
                        ContAns.ECM_Contract_Status__c = si.ECM_Contract__r.Status; 
                        ContAns.ECM_Product_Name__c = si.ECM_Product_Name__c;
                        ContAns.ECM_Fiscal_Year__c = fiscal;
                        ContAns.ECM_Agreement_Type_Name__c=si.ECM_Contract__r.ECM_Agreement_Type__r.Name;
                        ContAns.CurrencyIsoCode= si.CurrencyIsoCode;
                        ContAns.Amount_Without_Tax__c = getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c);
                        ContAns.ECM_Contract_Item_ID__c = si.Id;
                        ContAns.ECM_Sales_Org__c = si.ECM_Contract__r.Account.Sales_Org__c;
                        ContAns.ECM_SAP_sold_to__c = si.ECM_Contract__r.Account.SAP_Sold_to__c;          
                        ContAns.ECM_INTO_Material__c = String.valueOf(si.ECM_Product__r.ECM_INTO_Material__c);
                        ContAns.ECM_Period__c = 'P'+String.valueOf(periodval1);
                        ContAns.ECM_Internal_Order__c = iomap.get(si.ECM_Product_Name__c+'-'+ContAns.ECM_Budget_Type_Name__c+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal);
                        ContAns.ECM_Territory__c = si.ECM_Contract__r.ECM_Territory__r.Name;
                        ContAns.ECM_Territory_Hierarchy__c = si.ECM_Contract__r.ECM_Territory__r.Sales_Area__r.Name;
                        ContAns.ECM_Concept__c= si.ECM_Contract__r.ContractNumber;                
                        CAList.add(ContAns);*/
                    }                   
                }                
            }
            else if(si.ECM_Retro_investment__c !=Null && si.ECM_Retro_investment__c >0){
                CAList.add(mapconitemanysis(si,fiscal,getAmountwithoutTaxS,string.valueOf(periodval1),iomap.get(si.ECM_Product_Name__c+'-'+'TI [ES]'+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal),'TI [ES]'));
/*
                ECM_Contract_Item_Analysis__c ContAns = new ECM_Contract_Item_Analysis__c(); 
                ContAns.ECM_Budget_Type_Name__c = 'TI [ES]';
                ContAns.ECM_Contract_Status__c = si.ECM_Contract__r.Status; 
                ContAns.ECM_Product_Name__c = si.ECM_Product_Name__c;
                ContAns.ECM_Fiscal_Year__c = fiscal;
                ContAns.ECM_Agreement_Type_Name__c=si.ECM_Contract__r.ECM_Agreement_Type__r.Name;
                ContAns.CurrencyIsoCode= si.CurrencyIsoCode;
                ContAns.Amount_Without_Tax__c = getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c);
                ContAns.ECM_Contract_Item_ID__c = si.Id;
                ContAns.ECM_Sales_Org__c = si.ECM_Contract__r.Account.Sales_Org__c;
                ContAns.ECM_SAP_sold_to__c = si.ECM_Contract__r.Account.SAP_Sold_to__c;          
                ContAns.ECM_INTO_Material__c = String.valueOf(si.ECM_Product__r.ECM_INTO_Material__c);
                ContAns.ECM_Period__c = 'P'+String.valueOf(periodval1);
                ContAns.ECM_Internal_Order__c = iomap.get(si.ECM_Product_Name__c+'-'+ContAns.ECM_Budget_Type_Name__c+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal);
                ContAns.ECM_Territory__c = si.ECM_Contract__r.ECM_Territory__r.Name;
                ContAns.ECM_Territory_Hierarchy__c = si.ECM_Contract__r.ECM_Territory__r.Sales_Area__r.Name;
                ContAns.ECM_Concept__c= si.ECM_Contract__r.ContractNumber;                
                CAList.add(ContAns);  */ 
            }/*else{
                    ECM_Contract_Item_Analysis__c ContAns = new ECM_Contract_Item_Analysis__c(); 
                    ContAns.ECM_Budget_Type_Name__c = '';
                    ContAns.ECM_Contract_Status__c = si.ECM_Contract__r.Status; 
                    ContAns.ECM_Product_Name__c = si.ECM_Product_Name__c;
                    ContAns.ECM_Fiscal_Year__c = fiscal;
                    ContAns.ECM_Agreement_Type_Name__c=si.ECM_Contract__r.ECM_Agreement_Type__r.Name;
                    ContAns.CurrencyIsoCode= si.CurrencyIsoCode;
                    ContAns.Amount_Without_Tax__c = getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c);
                    ContAns.ECM_Contract_Item_ID__c = si.Id;
                    ContAns.ECM_Sales_Org__c = si.ECM_Contract__r.Account.Sales_Org__c;
                    ContAns.ECM_SAP_sold_to__c = si.ECM_Contract__r.Account.SAP_Sold_to__c;          
                    ContAns.ECM_INTO_Material__c = String.valueOf(si.ECM_Product__r.ECM_INTO_Material__c);
                    ContAns.ECM_Period__c = 'P'+String.valueOf(periodval1);
                    ContAns.ECM_Internal_Order__c = '';
                    ContAns.ECM_Territory__c = si.ECM_Contract__r.ECM_Territory__r.Name;
                    ContAns.ECM_Territory_Hierarchy__c = si.ECM_Contract__r.ECM_Territory__r.Sales_Area__r.Name;
                    ContAns.ECM_Concept__c= si.ECM_Contract__r.ContractNumber;                
                    CAList.add(ContAns);   
                    }*/
                   
        }
        system.debug('CAList'+CAList);
        // insert CAList;
        Database.SaveResult[] srList = Database.insert(CAList, false);
        
        // Iterate through each returned result
        for (Database.SaveResult sr : srList) {
            if (sr.isSuccess()) {
                // Operation was successful, so get the ID of the record that was processed
                System.debug('Successfully inserted Analysis. record ID: ' + sr.getId());
            }
            else {
                // Operation failed, so get all errors                
                for(Database.Error err : sr.getErrors()) {
                    System.debug('The following error has occurred.');                    
                    System.debug(err.getStatusCode() + ': ' + err.getMessage());
                    System.debug('Analysis record fields that affected this error: ' + err.getFields());
                }
            }
        }
        
    }
    
    global void finish(Database.BatchableContext BC){
        //Delete batch job call
        Database.executeBatch(new ECM_ContractItemAnalysisDelete_Batch());
    }
    public static ECM_Contract_Item_Analysis__c mapconitemanysis(ECM_Contract_Item__c si,string fiscal,Map<string,Decimal> getAmountwithoutTaxS,string periodval1,string iocode,string budgettype){
        system.debug(si.Id+'-'+budgettype+'values=='+periodval1);  
        system.debug('io code '+iocode);
        ECM_Contract_Item_Analysis__c ContAns = new ECM_Contract_Item_Analysis__c();
        ContAns.ECM_Budget_Type_Name__c  = budgettype ;
        ContAns.ECM_Contract_Item__c=si.id;
        ContAns.ECM_Contract_Status__c = si.ECM_Contract__r.Status; 
        ContAns.ECM_Product_Name__c = si.ECM_Product_Name__c;
        ContAns.ECM_Fiscal_Year__c = fiscal;
        ContAns.ECM_Agreement_Type_Name__c=si.ECM_Contract__r.ECM_Agreement_Type__r.Name;
        ContAns.CurrencyIsoCode= si.CurrencyIsoCode;
        system.debug(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c+'getAmountwithoutTaxS=='+getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c));
        ContAns.Amount_Without_Tax__c = getAmountwithoutTaxS.get(si.Id+'-'+ContAns.ECM_Budget_Type_Name__c);
        ContAns.ECM_Contract_Item_ID__c = si.Id;
        ContAns.ECM_Sales_Org__c = si.ECM_Contract__r.Account.Sales_Org__c;
        ContAns.ECM_SAP_sold_to__c = si.ECM_Contract__r.Account.SAP_Sold_to__c;          
        ContAns.ECM_INTO_Material__c = String.valueOf(si.ECM_Product__r.ECM_INTO_Material__c);
        ContAns.ECM_Period__c = 'P'+String.valueOf(periodval1);
        ContAns.ECM_Internal_Order__c = iocode;// iomap.get(si.ECM_Product_Name__c+'-'+SDI.ECM_Budget_Type__c+'-'+si.ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Name+'-'+fiscal);
        ContAns.ECM_Territory__c = si.ECM_Contract__r.ECM_Territory__r.Name;
        ContAns.ECM_Territory_Hierarchy__c = si.ECM_Contract__r.ECM_Territory__r.Sales_Area__r.Name;
        ContAns.ECM_Concept__c= si.ECM_Contract__r.ContractNumber;                
        return ContAns;
    }
}