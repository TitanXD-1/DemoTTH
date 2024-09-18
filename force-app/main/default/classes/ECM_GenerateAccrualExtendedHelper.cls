/*
* Class Name: ECM_GenerateAccrualExtendedHelper
* Test Class: ECM_GenerateAccrualBatchTest
* Author: 
* Brief Description: This class is used for ECM_GenerateAccrualBatch.
* Created Date: 06/06/2024
* History: 
* VERSION			AUTHOR				DATE				DETAIL
* 1.0			    Suvendu Roy		    20/05/2024			153432 - New batch creation & calculations Part-2_SFDC
*/
 
public with sharing class ECM_GenerateAccrualExtendedHelper {
    
    
    /**
    * Calculate the number of months between the start and end dates.
    * @param startDate the start date
    * @param endDate the end date
    * @return the number of months between the start and end dates
    */
    public static Integer getDuration(Date startDate,Date endDate){
        Integer monthDiff = startDate.monthsBetween(endDate);
        Integer daysEnd = Date.daysInMonth(endDate.year(), endDate.month());
        Decimal dayStart = startDate.day();
        Decimal dayEnd = endDate.day();
        Decimal factor = 0;
        if(dayStart != dayEnd){
            factor = (dayEnd - dayStart)/daysEnd;
        }
        Decimal k = monthDiff + factor;
        Integer totalMonths  = Integer.valueOf(k.round(System.RoundingMode.CEILING));
        system.debug(LoggingLevel.DEBUG,'Calculated value with CEILING : '+ totalMonths);
        return totalMonths;
    }
    
    
    /**
     * This method is used to calculate the Amount of the Accrual Items
     * @param duration This is the duration of the Contract
     * @param length This is the length from the start of the Contract
     * @param value This is the value from the Contract Item or Sales Driver Item Details
     * @return The Amount which will be populated in the Accrual Items
     */
    public static Decimal setAccrualItemAmounts(Integer duration, Integer length, Decimal value){
        if(duration==1){
            return value;
        }
        else if(length == duration-1){ 
            return value-((value/duration).setScale(2))*(duration-1);            
        }
        else{
            return ((value/duration).setScale(2));
        }
    } 
    
    /**
     * This method is used to calculate duration of lead brand & old to new logic
     * @param isLead This is flag of Contract Item Is Lead field
     * @param length This is the length of Contract duration
     * @param value This is the count of Accrual Item will be created for each CI or SDID
     * @return New count of the Accrual Items will be created for Lead Brand
     */
    public static Integer adjustDuration(Boolean isLead, Integer conDuration, Integer length) {
        if (isLead && conDuration > 12 && length < 12) {
            return 12;
        }else if(isLead && conDuration > 12 && length >= 12){
            return length;
        }
        return conDuration;
    }
    

    /**
    * This method is used to map the Internal Orders to the Contract Item and the Sales Driver Item Details
    * @param conItemList This is the list of Contract Items
    * @param salesDriverItemDetailsList This is the list of Sales Driver Item Details
    * @param budget This is the budget type for Contract Items
    * @return The set of Internal Orders. Each string in the set is in the format ProductId-BudgetTypeID:ContractId-StartDate
    */
    public static Set<String> productItemMapwithBudgetType(List<ECM_Contract_Item__c> conItemList,List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailsList,String budget){
        Set<String> internalOrderKeySet = new Set<String>();
        for(ECM_Contract_Item__c conItem: conItemList){
            Boolean flag = conItem.ECM_Product__r.Product__r.Id!=null && budget != null 
                && conItem.ECM_Contract__c!=null && conItem.ECM_Contract__r.StartDate!=null;
            if(flag){
                internalOrderKeySet.add(conItem.ECM_Product__r.Product__r.Id+'-'+budget+':'
                                        +conItem.ECM_Contract__c+'-'+conItem.ECM_Contract__r.StartDate.format());
            }
        }
        for(ECM_Sales_Driver_Item_Detail__c sdid : salesDriverItemDetailsList){
            Boolean flag = sdid.ECM_Product__r.ECM_Product__r.Product__r.Id != null && sdid.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__r.Id!=null &&
                sdid.ECM_Sales_Driver_Item__r.Contract__c != null && sdid.ECM_Sales_Driver_Item__r.Contract__r.StartDate!=null;
            if(flag){
                internalOrderKeySet.add(sdid.ECM_Product__r.ECM_Product__r.Product__r.Id+'-'
                                        +sdid.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Budget_Type__r.id+':'
                                        +sdid.ECM_Sales_Driver_Item__r.Contract__c+'-'
                                        +sdid.ECM_Sales_Driver_Item__r.Contract__r.StartDate.format());
            }
        }
        System.debug(LoggingLevel.DEBUG,internalOrderKeySet);
        return internalOrderKeySet;
    }
    
    /**
    * This method is used to map the InternalOrdersId with the key as the combination of ProductId-BudgetTypeID-ContractId
    * @param internalOrderKeySet This is the set of strings. Each string in the set is in the format ProductId-BudgetTypeID:ContractId-StartDate
    * @param internalOrderMap This is the map of Internal Orders with the key as the combination of ProductId-BudgetTypeID
    * @return The map of InternalOrdersId with the key as the combination of ProductId-BudgetTypeID-ContractId
    */
    public static Map<String, Id> mapContractToInternalOrder(Set<String> internalOrderKeySet, Map<String,List<ECM_Internal_Order__c>>internalOrderMap){
        Map<String, Id> internalOrderMapWithKey = new Map<String, Id>();
        for(String mainKey : internalOrderKeySet){
            System.debug(LoggingLevel.DEBUG,mainKey);
            String firstKey = mainKey.split(':').get(0);
            System.debug(LoggingLevel.DEBUG,firstKey);
            String secondKey = mainKey.split(':').get(1);
            String conId = secondKey.split('-').get(0);
            String dateString =secondKey.split('-').get(1);
            // Split the string into day, month, and year components
            List<String> dateParts = dateString.split('/');
            
            // Extract the components
            Integer day = Integer.valueOf(dateParts[0]);
            Integer month = Integer.valueOf(dateParts[1]);
            Integer year = Integer.valueOf(dateParts[2]);
            
            // Create a Date instance using the extracted components
            Date conStartDate = Date.newInstance(year, month, day);
            
            if(internalOrderMap.get(firstKey)!=null){
                for(ECM_Internal_Order__c internalOrder: internalOrderMap.get(firstKey)){
                    Boolean flag = internalOrder.ECM_End_Date__c>=conStartDate && internalOrder.ECM_Start_Date__c<=conStartDate;
                    if(flag){
                        internalOrderMapWithKey.put(firstKey+'-'+conId,internalOrder.Id);
                    }
                }
                
            }
        }
        System.debug(LoggingLevel.DEBUG,internalOrderMapWithKey);
        return internalOrderMapWithKey;
    }
}