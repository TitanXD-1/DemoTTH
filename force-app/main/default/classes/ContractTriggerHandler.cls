/*
* @Name: ContractTriggerHandler
* @Purpose: Trigger Handler Class for ContractTrigger ES20-715
* @History                                                            
                                                            
VERSION     AUTHOR                      DATE              DETAIL
1.0      Preyanka Ghosh                 01/04/2019       Initial Development
1.1      Shaunak Bhattacharjee          02/12/2019       CR 1397 - Before Update
1.2		 Saurav Prasad					12/03/2021		 ECM-4116 - After Update
1.3		 Sayan Mullick                  28/07/2021       ECM-4570 - After Update
1.4		 Saurav Prasad					26/10/2021		 ECM-4884 - After Update
1.5		 Saurav Prasad					28/12/2021		 ECM-5089 - After Update
1.6		 Anuja Chattopadhyay			08/03/2022		 ECM-5269 - Befor and After Insert
1.8		 Nikhilesh Chandak				10/06/2022		 ECM-5678 - After Update
1.9		 Suvendu Roy    				01/08/2022		 ECM-5958 - Before Update
1.10     Prashanth L                    04/08/2022       ECM-5956 - Before Insert
2.0		 Saranya L						26/09/2022		 ECM-6175 - After update
2.1		 Saurav Prasad					03/05/2022		 CUS-324 - After update
*/
public with sharing class ContractTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ContractTrigger';
    public static Boolean isFirstTime = true;
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        //EDGE_ContractTriggerHelper.changeStatusToActive(newItems);
        EDGE_UtilityClass.populateGUID(newItems); //ECM-5956
        EDGE_ContractTriggerHelper.updateUOSEarnt(newItems);
        EDGE_ContractTriggerHelper.updateTotalUOSPoints(newItems);
        ECM_ContractTriggerHelper.updateSalesAreaAndTerritory(newItems,null);//ECM-5269
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //CR 1397 -- Shaunak Bhattacharjee  
        EDGE_ContractTriggerHelper.updateUOSEarntOnInitialUpdate(newItems.values(),oldItems);
        EDGE_ContractTriggerHelper.ECM_isUpfrontPaymentDue(newItems,oldItems);
        EDGE_ContractTriggerHelper.updateTotalUOSPointsOnUOSUpdate(newItems.values(),oldItems);
        ECM_ContractTriggerHelper.updateSalesAreaAndTerritory(newItems.values(),oldItems);//ECM-5269
        ECM_ContractTriggerHelper.updateApprovalDate(newItems,oldItems); //ECM-5958
        
        /*
         *  ECM-1558 -- Sai Kumar
         *  Will call method to update the non- A&P recordtype Contracts of Austraila to update the field ECM_Upfront_Payment_Spent__c when status is Approved
         *  with rollup summary field of ECM_Total_Amount_Confirmed__c field from  Payment Summary object
        */
        //EDGE_ContractTriggerHelper.ECM_updateUpfrontPaymentoncontractApproved(newItems,oldItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        EDGE_ContractTriggerHelper.assignContractToOutlet(newItems.values(), null);
        //EDGE_ContractTriggerHelper.assignContractToOutletExecutionHistoric(newItems.values(), null);        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
          
        /*
         *  ECM-2104 -- Veerendra Billakurthi
         *  This method is used to update the non- A&P recordtype Contracts of Austraila and to create Payment Summary records when status is Active.
        */
        if(isFirstTime){
            EDGE_ContractTriggerHelper.onContractStatusUpdate(newItems, oldItems);
            EDGE_ContractTriggerHelper.ECM_PaymentSummary_Creation(newItems,oldItems);
            
            /*
			*  ECM-3600 --Veerendra
			*  This method is used to create Payment Summary records when contract status changes from approved to  Active.
			*/
            
            EDGE_ContractTriggerHelper.ECM_createPaymentSummaries(newItems,oldItems);
            EDGE_ContractTriggerHelper.sendPushNotificationForStatusChange(newItems.values(), oldItems);//ECM-4570 
            ECM_ContractTriggerHelper.updateApprovalLogStatusToCancel(newItems,oldItems);// ECM-5678
            ECM_ContractTriggerHelper.updateParentContract(newItems,oldItems); //ECM-6174, ECM-6175
            
        }
        //updated as a part of ECM-5089
        if(EDGE_ContractTriggerHelper.isTriggered){
            /*
             * ECM-4884
             * Developer : Saurav Prasad
             * This method is used to send approval email to Customer based on Agreement Type - Contract Approval mail to Customer
             */
            System.debug('***1'+Limits.getQueries()+' '+Limits.getCpuTime()+' '+Limits.getLimitCpuTime());
            EDGE_ContractTriggerHelper.sendEmailNotificationToCustomer(newItems,oldItems);
            System.debug('***2'+Limits.getQueries()+' '+Limits.getCpuTime()+' '+Limits.getLimitCpuTime());
        }
        //ECM-5678 - This method is used to update Approval Log Status when Contract Status is changed to Cancelled

        //CUS-324
        if(!ECM_ContractTriggerHelper.isExecutedOnce){
             System.debug('***1'+Limits.getQueries()+' '+Limits.getCpuTime()+' '+Limits.getLimitCpuTime());
            ECM_ContractTriggerHelper.updateDistributionAchievedInCI(newItems,oldItems);
            System.debug('***2'+Limits.getQueries()+' '+Limits.getCpuTime()+' '+Limits.getLimitCpuTime());
        }
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            
        
    }

}