/*
 * @Name: ECM_ProductAgreementTriggerHelper
 * @Description: This is the Helper class for Product Agreement Trigger
 * @History                                                            
                                                         
	VERSION    AUTHOR                DATE              DETAIL
	1.0        Sayan Mullick       	13/09/2021         Initial Development for ECM-4416
*/ 
public class ECM_ProductAgreementTriggerHelper {
    /*
    * @Name : ProductAgreementDuplicateCheck (ECM-4416)
	* @description : This method is used to check duplicate Product Agreement
	* @return : void
	* @param : List of Product Agreement, Map of Id, old Product Agreement
	*/
    public static void ProductAgreementDuplicateCheck(List<ECM_Product_Agreement__c> newProdAgg, Map<Id,sObject> oldMap){
        
        //variable declaration
        Set<String> aggTypeSet = new Set<String>();
        Set<String> mapSet = new Set<String>();
        List<ECM_Product_Agreement__c> prodAggList = new List<ECM_Product_Agreement__c>();
        Map<Id,ECM_Product_Agreement__c> oldprodAggMap;
        Map<String,ECM_Product_Agreement__c> prodAggMap = new Map<String,ECM_Product_Agreement__c>();
        
        if(oldMap!= null){
             oldprodAggMap = (Map<Id,ECM_Product_Agreement__c>)oldMap;
        }
        for(ECM_Product_Agreement__c prodAggObj: newProdAgg){
            if(oldprodAggMap == null 
               || (oldprodAggMap!= null && oldprodAggMap.containskey(prodAggObj.Id) && 
                   (oldprodAggMap.get(prodAggObj.Id).ECM_Market_Assortment_Product__c != prodAggObj.ECM_Market_Assortment_Product__c)))
            {
                        prodAggList.add(prodAggObj);
                        aggTypeSet.add(prodAggObj.ECM_Contract_Type__c);
                        mapSet.add(prodAggObj.ECM_Market_Assortment_Product__c);
            }              
        }
        if(!prodAggList.isEmpty()){
            List<ECM_Product_Agreement__c> prodAggRec = [SELECT Name,ECM_Contract_Type__c,ECM_Market_Assortment_Product__c
                                                        FROM ECM_Product_Agreement__c 
                                                        WHERE ECM_Contract_Type__c IN : aggTypeSet 
                                                        AND ECM_Market_Assortment_Product__c IN : mapSet];
            aggTypeSet.clear();
            mapSet.clear();
            if(!prodAggRec.isEmpty()){
                for (ECM_Product_Agreement__c prodAgg: prodAggRec){
                    String cmpKey = String.valueOf(prodAgg.ECM_Contract_Type__c)+'_'+String.valueOf(prodAgg.ECM_Market_Assortment_Product__c);
                    prodAggMap.put(cmpKey,prodAgg);
                }
                for(ECM_Product_Agreement__c prodAggrement: prodAggList){
                    String cmpKey = String.valueOf(prodAggrement.ECM_Contract_Type__c)+'_'+String.valueOf(prodAggrement.ECM_Market_Assortment_Product__c);
                    if(prodAggMap.containsKey(cmpKey)){
                        String errorMsg = Label.ECM_Duplicate_Product_Agreement_Error_Msg;
                        errorMsg = errorMsg.replace( '@@@@', prodAggMap.get(cmpKey).Name);
                        prodAggrement.addError(errorMsg);
                    }  
                }  
            }
        }
    }
}