/*
@Name: ECM_MobilePaymentSummaryRestResource
@Description: This class is needed to update payment summary from mobile sales reps.
@History:                                                           
@VERSION			AUTHOR					DATE				DETAIL
@1.0			Pratik Somani			04/03/2022			ECM-5310 : Payment summary SFDC_need to validate the existing code to reconfigure it to access it through mobile (Part 1)
@1.1			Saurav Prasad			08/03/2022			ECM-5315 : Payment summary SFDC_need to validate the existing code to reconfigure it to access it through mobile (Part 2)

*/

@RestResource(urlMapping='/paymentSummaryConfirmation/')
global with sharing class ECM_MobilePaymentSummaryRestResource{
    /** 
* @description	:	ECM-5315 & ECM-5310 - Handles the Post Request from Mobile Application for Payment Summary process.
**/
    @HttpPost
    global static void PaymentSummaryConfirmation(){
         System.debug('PaymentSummaryConfirmation@@@@@');
        RestRequest request = RestContext.request;
        RestResponse resp = RestContext.response;
        RestContext.response.addHeader('Content-Type', 'application/json');   
        
        Map<Id,ECM_Payment_Summary_Item__c> mapOfPayItems = new Map<Id,ECM_Payment_Summary_Item__c>();
        ECM_Payment_Summary__c paymentSummaryRecord = new ECM_Payment_Summary__c();
        
        try{ 
            String jsonBody = request.requestBody.toString();
            System.debug('jsonBody@'+jsonBody);
            
            ECM_Payment_Summary__c paySum = (ECM_Payment_Summary__c) JSON.deserialize(request.requestBody.toString(),ECM_Payment_Summary__c.class);
            System.debug('paySum@'+paySum);
            if(String.isEmpty(paySum.ECM_Type__c) || String.isEmpty(paySum.ECM_Payment_Summary_Status__c) || 
               !system.label.ECM_Mobile_Payment_Summary_Status.contains(paySum.ECM_Payment_Summary_Status__c) || 
               paySum.ECM_Type__c == system.label.ECM_Non_Volume){
              RestContext.response.statusCode = 400;
              RestContext.response.responseBody = Blob.valueOf('{"Status" : "Error while processiong request","StatusCode" : "400","ErrorMessage" : "Data Issue"}');     
              return;
            }
            
            for(ECM_Payment_Summary_Item__c paySumItem:paySum.Payment_Summary_Item__r){
                System.debug('singleData@'+paySumItem);
                mapOfPayItems.put(paySumItem.Id,paySumItem);
            }
            if(!mapOfPayItems.values().isEmpty()){
                update mapOfPayItems.values();
            }
            if(paySum.Id!=Null){
                update paySum;
                paymentSummaryRecord = ECM_PaymentSummaryController.getPaymentSummary(paySum.Id);
            }
            //if(paySum.ECM_Type__c == 'Volume-Based'){
            if(paySum.ECM_Type__c != system.label.ECM_Non_Volume){
                ECM_PaymentSummaryController.updatePaymentSummaryAndSubmit(paymentSummaryRecord,JSON.serialize(paymentSummaryRecord.Payment_Summary_Item__r));
            }
            //RestContext.response.addHeader('Content-Type', 'application/json');   
            RestContext.response.statusCode = 200;
            RestContext.response.responseBody = Blob.valueOf('{"Status" : "Payment Summary Updated Successfully","StatusCode" : "200", "Reference Id" : "'+paySum.Id+'"}');
            
        }catch(Exception e){
            string errorMessage = e.getMessage();
            //RestContext.response.addHeader('Content-Type', 'application/json');   
            RestContext.response.statusCode = 500;
            RestContext.response.responseBody = Blob.valueOf('{"Status" : "Server Exception","StatusCode" : "500","ErrorMessage" : "'+errorMessage+'"}');
        }
    }
    
}