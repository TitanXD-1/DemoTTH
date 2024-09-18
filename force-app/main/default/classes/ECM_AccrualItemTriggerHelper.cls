/*
 * @Name: ECM_AccrualItemTriggerHelper
 * @Description: This is the Helper class for AccrualItemTrigger
 * @History                                                            
 *                                                       
 * VERSION    	AUTHOR       		DATE                DETAIL
 * 1.0     		Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country
*/ 

public class ECM_AccrualItemTriggerHelper {
	//We are updating currency ISO code from the Currency field of Accrual 
    public static void populateCurrency(List<ECM_Accrual_Item__c> newItems){
        Set<Id> accrualIdSet = new Set<Id>();
        Map<Id,ECM_Accrual__c> acrlMap;
        for(ECM_Accrual_Item__c acrlObj : newItems){
            accrualIdSet.add(acrlObj.ECM_Accrual__c);
        }
        if(!accrualIdSet.isEmpty()){
            acrlMap = new Map<Id,ECM_Accrual__c>([SELECT Id,CurrencyIsoCode FROM ECM_Accrual__c WHERE Id IN : accrualIdSet]);
        }
        for(ECM_Accrual_Item__c acrlObj : newItems){
            if(acrlMap!= null && acrlMap.containsKey(acrlObj.ECM_Accrual__c)){
                acrlObj.CurrencyIsoCode = acrlMap.get(acrlObj.ECM_Accrual__c).CurrencyIsoCode;
            }
        }
    }
}