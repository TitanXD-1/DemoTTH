/**

* @Description: EDGE_BillingRequestTriggerHelper
* @Purpose : BillingRequest Trigger Helper Class for BillingRequest__c
* @History:
* @Version     Developer		     Date			   Story/Purpose


*  1.0        Sukanya Chatterjee     7/10/2021         ES20-10979 



*/
public with sharing class EDGE_BillingRequestTriggerHelper {
    /**
* @description :Checking if the status of the Billing Request is Closed then the MDM & QCT can't delete the record.
* @return : Void
* @param : Map of id, old Billing_Request__c record
*/
    public static void checkdelrecords(Map<Id,SObject> oldItems){
        List<Billing_Request__c> billingRequestList = new List<Billing_Request__c>();
        Map<Id,Billing_Request__c> oldBillingRequestMap = (Map<Id,Billing_Request__c>)oldItems;
        String profile = Label.Profile_BR;
        String errorMsg = Label.BillingRequestDelError;
        List < String > userProfileinfo = profile.split( ';' );
        User userDetails =[Select Id,Profile.Name From User Where Id=:System.UserInfo.getUserId() WITH SECURITY_ENFORCED];
        if(oldBillingRequestMap!= null)
        { 
            for(Id recordId: oldBillingRequestMap.keySet())
            { 
                if((userProfileinfo.contains (userDetails.Profile.Name)) && oldBillingRequestMap.get(recordId).Status__c.equals('Closed'))
                {
                    billingRequestList.add(oldBillingRequestMap.get(recordId));
                }
            }
            for(Billing_Request__c billingRequest: billingRequestList)
            {  
                billingRequest.addError(errorMsg);
            }
        }
        
    }
}