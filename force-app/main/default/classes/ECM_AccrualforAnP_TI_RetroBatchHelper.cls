/*
* Class Name: ECM_AccrualforAnP_TI_RetroBatchHelper
* Test Class: ECM_AccrualforAnP_TI_RetroBatchTest
* Author: 
* Brief Description: This class is used for ECM_AccrualforAnP_TI_RetroBatch.
* Created Date: 06/06/2024
* History: 
* VERSION	   AUTHOR				        	DATE				DETAIL
1.0 		   Suvendu Roy & Sagnik Sanyal		06/06/2024			153434 - For contacts moving from New to Old Logic_SFDC
2.0				Saurav Prasad					18/09/2024			154645 - CM Classes_Fix Static Code Analysis_Contract Management
*/

public with sharing class ECM_AccrualforAnP_TI_RetroBatchHelper {
    
    /* Method to check list of accrual to deleteDifferent logic if today's date is greater 
     * or equal to payment calculation date & less than payment calculation date
     * @param List<Contract> conList which will get from the scope
     * @param marketSetting the Market Setting record for all the Contracts
    */
    public static List<ECM_Accrual__c> deleteExtraAccrualsNewtoOld(List<ECM_Accrual__c> accrualList,String countryCode) {
        List<ECM_Accrual__c> accrualListToBeDeleted = new List<ECM_Accrual__c> ();
        //Map<Id,ECM_Accrual__c> accrualMapForDuplicate = new Map<Id,ECM_Accrual__c>();
        Integer fiscalYearStartMonth = 7; 
        Date today = Date.today();
        Integer currentMonth = today.month();
        Integer currentYear = today.year();
        Integer fiscalYearToDelete = currentMonth < fiscalYearStartMonth ? currentYear : currentYear+1;
        Integer fiscalPeriodToDelete = Math.mod((currentMonth - fiscalYearStartMonth + 12), 12) + 1;
        //String paymentDateStatus = getFiscalPeriodToDelete(countryCode);
        Boolean isBeforePayment = getFiscalPeriodToDelete(countryCode);
        //System.debug(paymentDateStatus +'-->'+isToday);
        if(isBeforePayment){
            fiscalPeriodToDelete = fiscalPeriodToDelete - 1;
        }
        
        for(ECM_Accrual__c accrualRec : accrualList){
                String period = accrualRec.ECM_Period__c;//P1, P2, P3
                if(period != null){
                    Integer periodsFromAccrual = Integer.valueof(period.replace('P',''));//1,2,3
                	Boolean flag = (Integer.valueof(accrualRec.ECM_Fiscal_Year__c) == fiscalYearToDelete && periodsFromAccrual> fiscalPeriodToDelete) || Integer.valueof(accrualRec.ECM_Fiscal_Year__c) > fiscalYearToDelete;
                    if(flag){
                    	accrualListToBeDeleted.add(accrualRec);
                	}
                }                
        }
        return accrualListToBeDeleted;
    }
    
    
    
    public static Boolean getFiscalPeriodToDelete(String countryCode) {
        
        List<ECM_Accrual_Period__c> accrualPeriodList= new List<ECM_Accrual_Period__c>();
        Date today = Date.today();
        
        accrualPeriodList= [select Id,Period__c ,ECM_Payment_Calculation_Date__c from ECM_Accrual_Period__c 
                            where ECM_Payment_Calculation_Date__c !=null and ECM_Market_Setting__r.Geography__r.code__c =: countryCode
                            AND ECM_Start_Date__c<=TODAY AND ECM_End_Date__c >=TODAY AND ECM_Market_Setting__r.ECM_Budget_Type_for_Volume_Based_PS__c!=null WITH SECURITY_ENFORCED 
                            order by ECM_Start_Date__c desc ];
        
        if(!accrualPeriodList.isEmpty() && accrualPeriodList[0].ECM_Payment_Calculation_Date__c >= today){
            return true;
        }
        return false;
    }
    
    /** 
     * 154645 : Additonal method for PMD violations* 
     * */
    
    public static ECM_AccrualforAnP_TI_RetroBatch.WrapperCls processMapping(List<Contract> scope, List<ECM_Accrual_Period__c> apList){
        Map<String,ECM_Accrual__c>accuralMap= new  Map<String,ECM_Accrual__c>();
        set<id> geoAreaSet= new set<id>();
        
        for(Contract c : scope){
            
            ECM_Accrual__c accural= new ECM_Accrual__c();
            accural = accrualMapping(c,apList);
            accuralMap.put(accural.ECM_Contract__c,accural);  
            geoAreaSet.add(c.ECM_Agreement_Type__r.Geography__c);        
        }
        if(!(accuralMap.values().isEmpty())){
            
            Database.insert(accuralMap.Values(),false);
        }     
        System.debug(LoggingLevel.Debug,'accuralMap @'+accuralMap);
        System.debug(LoggingLevel.Debug,'accuralMap size @'+accuralMap.size());
        
        ECM_AccrualforAnP_TI_RetroBatch.WrapperCls wrapperInstance = new ECM_AccrualforAnP_TI_RetroBatch.WrapperCls();
        wrapperInstance = processRecords(scope,apList);
        
        //Internal Orders
        map<string,ECM_Internal_Order__c> internalOrderMap = new map<string,ECM_Internal_Order__c>();
        String fiscalyear='FY'+string.valueof(System.today().year()).right(2);
        
        for(ECM_Internal_Order__c internalOrder:[select id,ECM_Budget_Type_Pickup_Option__c,
                                                 ECM_Active__c,ECM_Geography__c,ECM_Product__c 
                                                 from ECM_Internal_Order__c where
                                                 ECM_Active__c=:true and ECM_Geography__c IN:geoAreaSet 
                                                 and ECM_Fiscal_Year__c=:fiscalyear
                                                 WITH SECURITY_ENFORCED]){
                                                     internalOrderMap.put(String.valueOf(internalOrder.ECM_Geography__c+'-'+internalOrder.ECM_Product__c+'-'+internalOrder.ECM_Budget_Type_Pickup_Option__c),internalOrder);
                                                 }
        
        system.debug(LoggingLevel.DEBUG,'internalOrderMap'+internalOrderMap);
        
        
        
        
        wrapperInstance.internalOrderMap = internalOrderMap;
        wrapperInstance.accuralMap = accuralMap;
        return wrapperInstance;
            
    }
    
    public static ECM_AccrualforAnP_TI_RetroBatch.WrapperCls processRecords(List<Contract> scope, List<ECM_Accrual_Period__c> apList){
        ECM_AccrualforAnP_TI_RetroBatch.WrapperCls wrapperInstance = new ECM_AccrualforAnP_TI_RetroBatch.WrapperCls();
        
        Map<string,Decimal> depletionProductMap = new Map<string,Decimal>();
        map<Id,ECM_Tiering__c> tierMap = new map<Id,ECM_Tiering__c>();
        Map<String,List<ECM_Sales_Driver_Item_Detail__c>> salesdriveMap = new  Map<String,List<ECM_Sales_Driver_Item_Detail__c>>(); 
        
        //depletions
        List<Depletions__c> depletionLst=[select id ,ECM_End_Period__c, ECM_Start_Period__c,Contract__c,Forecast_Volume__c,
                                          ECM_Product__c from Depletions__c where Contract__c in :scope and ECM_Start_Period__c >=:apList[0].ECM_Start_Date__c
                                          and ECM_End_Period__c <=: apList[0].ECM_End_Date__c WITH SECURITY_ENFORCED];
        for(Depletions__c depletionRec : depletionLst){
            depletionProductMap.put(depletionRec.Contract__c+'_'+depletionRec.ECM_Product__c,depletionRec.Forecast_Volume__c);
        }
        
        //tiering 
        //Fetching Tiering records
        
        for(ECM_Tiering__c tier : [SELECT Id,ECM_Contract_Item__c,ECM_Tier_1_rate_per_UoM__c,
                                   ECM_Tier2_rate_per_UoM__c,ECM_Tier_3_rate_per_UoM__c 
                                   FROM ECM_Tiering__c where ECM_Contract_Item__r.ECM_Contract__c IN:scope
                                   WITH SECURITY_ENFORCED]){
                                       tierMap.put(tier.ECM_Contract_Item__c,tier);
                                   }
        System.debug(LoggingLevel.DEBUG,'tierMap-->'+tierMap);
        
        //SDID
       
        //Budget Type TI and A&P hard coding is removed as part of ECM-4446
        list<ECM_Sales_Driver_Item_Detail__c> salesDriversList= [select Id,Name,ECM_Product__c,ECM_Investment_Amount__c,ECM_Budget_Type__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__r.id,
                                                                 ECM_Sales_Driver_Item__c,ECM_Product__r.ECM_Investment__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__c,
                                                                 ECM_Product__r.ECM_Product__r.Product__r.id, ECM_Sales_Driver_Item__r.Contract__c,
                                                                 ECM_Product__r.ECM_Product__r.Product__c, ECM_Product__r.ECM_Product_Name__c,
                                                                 ECM_Sales_Driver_Item__r.Contract__r.ECM_Duration__c from ECM_Sales_Driver_Item_Detail__c
                                                                 where ECM_Sales_Driver_Item__r.Contract__c in:scope 
                                                                 AND ECM_Budget_Type__c!=null 
                                                                 WITH SECURITY_ENFORCED];
        for(ECM_Sales_Driver_Item_Detail__c salesdriveitems: salesDriversList){
            if(salesdriveMap.containskey(salesdriveitems.ECM_Sales_Driver_Item__r.Contract__c)){
                
                list<ECM_Sales_Driver_Item_Detail__c> saleslist = new list<ECM_Sales_Driver_Item_Detail__c>();
                saleslist.addAll(salesdriveMap.get(salesdriveitems.ECM_Sales_Driver_Item__r.Contract__c));
                saleslist.add(salesdriveitems);
                salesdriveMap.put(salesdriveitems.ECM_Sales_Driver_Item__r.Contract__c,saleslist);
                
            }else{
                
                salesdriveMap.put(salesdriveitems.ECM_Sales_Driver_Item__r.Contract__c,new List<ECM_Sales_Driver_Item_Detail__c>{salesdriveitems});
                
            }
            
        }
        System.debug(LoggingLevel.DEBUG,'salesdriveMap-->'+salesdriveMap);
        //wrapper assignment
        wrapperInstance.depletionProductMap = depletionProductMap;
        wrapperInstance.tierMap = tierMap;
        wrapperInstance.salesdriveMap = salesdriveMap;
        
        return wrapperInstance;
        
    }
    
    public static ECM_Accrual__c accrualMapping(Contract c,List<ECM_Accrual_Period__c> apList){
        
        ECM_Accrual__c accural= new ECM_Accrual__c();
        accural.ECM_Period__c= apList[0].period__c;
        accural.ECM_Fiscal_Year__c = System.today().month() > 6 ? String.ValueOf(System.today().year() + 1) : String.ValueOf(System.today().year()); //ECM-6574
        accural.ECM_Contract__c=c.Id;  
        if(c.RecordType.Name=='Outlet'){
            accural.ECM_Outlet__c=c.AccountId;  
        }
        else{
            accural.ECM_Operator__c=c.AccountId; 
        }
        accural.ECM_Unique_Id__c=c.Id+'_'+c.AccountId+'_'+apList[0].period__c+'_'+accural.ECM_Fiscal_Year__c;
        
        return accural;
    }
    
    public static ECM_Accrual_Item__c accuralItemCIMapping(ECM_AccrualforAnP_TI_RetroBatch.AccuralWrapper accwrap,ECM_AccrualforAnP_TI_RetroBatch.WrapperCls wrapper, String budget){
        //wrapper
        ECM_Contract_Item__c contractItem = accwrap.contractItem;
        Contract c = accwrap.c;  
        List<ECM_Accrual_Period__c> apList = accwrap.apList;
        
        Integer month=apList[0].ECM_Start_Date__c.month();
        Integer year=apList[0].ECM_Start_Date__c.year();
        Integer accrualStartMonth = integer.valueOf(label.ECM_Accrual_Batch_Start_Date);
        Integer accrualStartYear = integer.valueOf(label.ECM_Accrual_Batch_Start_year);
        
        ECM_Accrual_Item__c accrualItem = New ECM_Accrual_Item__c();
        
        accrualItem.ECM_Product__c=contractItem.ECM_Product__r.Product__r.Id;
        accrualItem.ECM_Contract_Item__c=contractItem.Id;
        accrualItem.Budget_Pickup_Option__c = budget;
        
        //Enhancement as part of ECM-4071
        if(c.StartDate.year() <= accrualStartYear  && c.StartDate.month() < accrualStartMonth ){
            accrualItem.ECM_Target_Volume__c = contractItem.ECM_Volume__c/c.ECM_Duration__c;                        
        }else{
            if(year ==c.StartDate.year() && month == c.StartDate.month()){
                accrualItem.ECM_Target_Volume__c = math.floor(contractItem.ECM_Volume__c/c.ECM_Duration__c)+math.mod((contractItem.ECM_Volume__c).intValue(),(c.ECM_Duration__c).intValue());
            }else{
                accrualItem.ECM_Target_Volume__c = math.floor(contractItem.ECM_Volume__c/c.ECM_Duration__c);
            }
        }
        
        accrualItem = accuralItemSwitchHandler(accwrap,wrapper,accrualItem);
        
        System.debug(LoggingLevel.Debug,'accrualItem @'+accrualItem);
        return accrualItem;
        
    }
    
    public static ECM_Accrual_Item__c accuralItemSwitchHandler(ECM_AccrualforAnP_TI_RetroBatch.AccuralWrapper wrap, ECM_AccrualforAnP_TI_RetroBatch.WrapperCls wrapper,ECM_Accrual_Item__c accrualItem){
        Contract c = wrap.c;
        ECM_Contract_Item__c contractItem = wrap.contractItem;
        List<ECM_Accrual_Period__c> apList = wrap.apList;
        
        Map<Id,ECM_Tiering__c> tierMap = wrapper.tierMap;
        map<string,ECM_Internal_Order__c> internalOrderMap = wrapper.internalOrderMap;
        Map<string,Decimal> depletionProductMap = wrapper.depletionProductMap;
        
        Decimal retroDiscount;
        //Tiering Calculations as part of ECM-3962 
        //String Check
        String switchCase =  !(apList.isEmpty()) && tierMap.ContainsKey(contractItem.Id)? apList[0].ECM_Market_Setting__r.ECM_Tiering_consideration_for_Accrual__c:'';  
        System.debug(LoggingLevel.Debug,'switchCase @'+switchCase);
        switch on switchCase {
            when 'Tier 1' {
                retroDiscount= (tierMap.get(contractItem.Id).ECM_Tier_1_rate_per_UoM__c == Null ? 0: tierMap.get(contractItem.Id).ECM_Tier_1_rate_per_UoM__c);
            }
            when 'Tier 2' {
                retroDiscount= (tierMap.get(contractItem.Id).ECM_Tier2_rate_per_UoM__c == Null ? 0: tierMap.get(contractItem.Id).ECM_Tier2_rate_per_UoM__c); 
            }
            when 'Tier 3' {
                retroDiscount= (tierMap.get(contractItem.Id).ECM_Tier_3_rate_per_UoM__c == Null ? 0: tierMap.get(contractItem.Id).ECM_Tier_3_rate_per_UoM__c); 
            }
            when else {
                retroDiscount= Decimal.valueOf(contractItem.ECM_UoM__c ==Null ? '0':contractItem.ECM_UoM__c); 
                
            }
        }
        
        System.debug(LoggingLevel.Debug,'retroDiscount @'+retroDiscount);
        
        accrualItem.ECM_Amount_Without_Tax__c= accrualItem.ECM_Target_Volume__c * retroDiscount;
        
        //internal order field population(ECM-3967)
        if(internalOrderMap.containsKey(String.valueOf(c.ECM_Agreement_Type__r.Geography__c+'-'+accrualItem.ECM_Product__c+'-'+accrualItem.Budget_Pickup_Option__c))){
            accrualItem.ECM_Internal_Order__c=internalOrderMap.get(String.valueOf(c.ECM_Agreement_Type__r.Geography__c+'-'+accrualItem.ECM_Product__c+'-'+accrualItem.Budget_Pickup_Option__c)).id;
        }
        //ECM-4143	starts
        if(depletionProductMap.get(c.id+'_'+ contractItem.ECM_Product__r.Product__c)!=null){
            accrualItem.Forecast_Volume__c=depletionProductMap.get(c.id+'_'+ contractItem.ECM_Product__r.Product__c);
            accrualItem.Forecast_Amount__c= accrualItem.Forecast_Volume__c* retroDiscount;
        }//ECM-4143	ends
        
        accrualItem.ECM_Outlet__c=c.AccountId;
        
        return accrualItem;
        
    }
    
}