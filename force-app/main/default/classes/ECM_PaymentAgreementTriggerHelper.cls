/*
 * @Name: ECM_PaymentAgreementTriggerHelper
 * @Description: This is the Helper class for Sales Agreement Trigger
 * @History                                                            
                                                         
	VERSION    AUTHOR                DATE              DETAIL
	1.0        Subhrojit Majumdar    13/09/2021        Initial Development for ECM-4416
*/ 
public class ECM_PaymentAgreementTriggerHelper {
    /*
    * @Name : PaymentAgreementDuplicateCheck (ECM-4416)
	* @description : This method is used to check duplicate Payment Agreement
	* @return : void
	* @param : List of PaymentAgreement, Map of Id,old Payment Agreement
	*/
    public static void PaymentAgreementDuplicateCheck(List<ECM_Payment_Agreement__c> newPaymentAggItem, Map<Id,sObject> oldMap){
        
        //variable declaration
        Set<String> aggTypeSet = new Set<String>();
        Set<String> paymentFreqSet = new Set<String>();
        List<ECM_Payment_Agreement__c> paymentAggList = new List<ECM_Payment_Agreement__c>();
        Map<Id,ECM_Payment_Agreement__c> oldPaymentAggMap;
        Map<String,ECM_Payment_Agreement__c> paymentAggMap = new Map<String,ECM_Payment_Agreement__c>();
        
        if(oldMap!= null){
             oldPaymentAggMap = (Map<Id,ECM_Payment_Agreement__c>)oldMap;
        }
        
        for(ECM_Payment_Agreement__c paymentAggObj: newPaymentAggItem){
            if(oldPaymentAggMap == null 
               || (oldPaymentAggMap!= null && oldPaymentAggMap.containskey(paymentAggObj.Id) && 
                   (oldPaymentAggMap.get(paymentAggObj.Id).ECM_Agreement_Type__c != paymentAggObj.ECM_Agreement_Type__c
                    || oldPaymentAggMap.get(paymentAggObj.Id).ECM_Payment_Frequency__c != paymentAggObj.ECM_Payment_Frequency__c)))
            {
                        paymentAggList.add(paymentAggObj);
                        aggTypeSet.add(paymentAggObj.ECM_Agreement_Type__c);
                        paymentFreqSet.add(paymentAggObj.ECM_Payment_Frequency__c);
            }              
        }
        if(!paymentAggList.isEmpty()){
            List<ECM_Payment_Agreement__c> paymentAggRec = [SELECT Name,ECM_Agreement_Type__c,ECM_Payment_Frequency__c
                                                        FROM ECM_Payment_Agreement__c 
                                                        WHERE ECM_Agreement_Type__c IN : aggTypeSet 
                                                        AND ECM_Payment_Frequency__c IN : paymentFreqSet];
            aggTypeSet.clear();
            paymentFreqSet.clear();
            if(!paymentAggRec.isEmpty()){
                for (ECM_Payment_Agreement__c paymentAgg: paymentAggRec){
                    String cmpKey = String.valueOf(paymentAgg.ECM_Agreement_Type__c)+'_'+String.valueOf(paymentAgg.ECM_Payment_Frequency__c);
                   paymentAggMap.put(cmpKey,paymentAgg);
                }
                for(ECM_Payment_Agreement__c paymentAggrement: paymentAggList){
                    String cmpKey = String.valueOf(paymentAggrement.ECM_Agreement_Type__c)+'_'+String.valueOf(paymentAggrement.ECM_Payment_Frequency__c);
                    if(paymentAggMap.containsKey(cmpKey)){
                        String errorMsg = Label.ECM_Payment_Agreement_Error_Message;
                        errorMsg = errorMsg.replace( '@@@@',paymentAggMap.get(cmpKey).Name);
                        paymentAggrement.addError(errorMsg);
                    }  
                }  
            }
        }
    }
    
}