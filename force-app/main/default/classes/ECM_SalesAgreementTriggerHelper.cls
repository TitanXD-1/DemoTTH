/*
 * @Name: ECM_SalesAgreementTriggerHelper
 * @Description: This is the Helper class for Sales Agreement Trigger
 * @History                                                            
                                                         
	VERSION    AUTHOR                DATE              DETAIL
	1.0        Sayan Mullick       	10/09/2021         Initial Development for ECM-4416
*/ 
public class ECM_SalesAgreementTriggerHelper {
    /*
    * @Name : SalesAgreementDuplicateCheck (ECM-4416)
	* @description : This method is used to check duplicate Sales Agreement
	* @return : void
	* @param : List of SalesAgreement, Map of Id, old Sales Agreement
	*/
    public static void SalesAgreementDuplicateCheck(List<ECM_Sales_Agreement__c> newSalesAggItem, Map<Id,sObject> oldMap){
        
        //variable declaration
        Set<String> aggTypeSet = new Set<String>();
        Set<String> salesDriverSet = new Set<String>();
        List<ECM_Sales_Agreement__c> salesAggList = new List<ECM_Sales_Agreement__c>();
        Map<Id,ECM_Sales_Agreement__c> oldsalesAggMap;
        Map<String,ECM_Sales_Agreement__c> salesAggMap = new Map<String,ECM_Sales_Agreement__c>();
        
        if(oldMap!= null){
             oldsalesAggMap = (Map<Id,ECM_Sales_Agreement__c>)oldMap;
        }
        
        for(ECM_Sales_Agreement__c salesAggObj: newSalesAggItem){
            if(oldsalesAggMap == null 
               || (oldsalesAggMap!= null && oldsalesAggMap.containskey(salesAggObj.Id) && 
                   oldsalesAggMap.get(salesAggObj.Id).ECM_Sales_Driver__c != salesAggObj.ECM_Sales_Driver__c))
            {
                        salesAggList.add(salesAggObj);
                        aggTypeSet.add(salesAggObj.ECM_Agreement_Type__c);
                        salesDriverSet.add(salesAggObj.ECM_Sales_Driver__c);
            }              
        }
        if(!salesAggList.isEmpty()){
            List<ECM_Sales_Agreement__c> salesAggRec = [SELECT Name,ECM_Agreement_Type__c,ECM_Sales_Driver__c,RecordTypeId
                                                        FROM ECM_Sales_Agreement__c 
                                                        WHERE ECM_Agreement_Type__c IN : aggTypeSet 
                                                        AND ECM_Sales_Driver__c IN : salesDriverSet];
            aggTypeSet.clear();
            salesDriverSet.clear();
            if(!salesAggRec.isEmpty()){
                for (ECM_Sales_Agreement__c salesAgg: salesAggRec){
                    String cmpKey = String.valueOf(salesAgg.ECM_Agreement_Type__c)+'_'+String.valueOf(salesAgg.ECM_Sales_Driver__c)+'_'+String.valueOf(salesAgg.RecordTypeId);
                    salesAggMap.put(cmpKey,salesAgg);
                }
                for(ECM_Sales_Agreement__c salesAggrement: salesAggList){
                    String cmpKey = String.valueOf(salesAggrement.ECM_Agreement_Type__c)+'_'+String.valueOf(salesAggrement.ECM_Sales_Driver__c)+'_'+String.valueOf(salesAggrement.RecordTypeId);
                    if(!salesAggMap.isEmpty() && salesAggMap.containsKey(cmpKey)){
                        String errorMsg = Label.ECM_Sales_Agreement_Error_Msg;
                        errorMsg = errorMsg.replace( '@@@@', salesAggMap.get(cmpKey).Name);
                        salesAggrement.addError(errorMsg);
                    }  
                }  
            }
        }
    }
    
}