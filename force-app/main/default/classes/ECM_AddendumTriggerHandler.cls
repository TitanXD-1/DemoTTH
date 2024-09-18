/*
* @Name: ECM_AddendumTriggerHandler
* @Purpose: Class with all handler methods of ECM_AddendumTrigger.
* @History:                                                                                                                       
* VERSION        AUTHOR            DATE              DETAIL
* 1.0        Pratap/Subhrojit   02/08/2022    Initial Development for ECM-5964
* 1.1		Saranya L		19/08/2022	ECM-5866 :KPI Recalculation Logic​_SFDC_EU
* 1.2       Ravi            12/09/2022  ECM-5960 :capture the approval date
*/
public class ECM_AddendumTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_AddendumTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);     
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {        	
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_AddendumTriggerHelper.updateApprovalDate((Map<Id,ECM_Addendum__c>) newItems, (Map<Id, ECM_Addendum__c>) oldItems);
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        System.debug('***1'+Limits.getQueries()+' '+Limits.getCpuTime()+' '+Limits.getLimitCpuTime());
        ECM_AddendumTriggerHelper.ECM_createAddendumPaymentSummaries((Map<Id,ECM_Addendum__c>) newItems, (Map<Id, ECM_Addendum__c>) oldItems);
        System.debug('***2'+Limits.getQueries()+' '+Limits.getCpuTime());
        ECM_AddendumTriggerHelper.reCalculateKPI((Map<Id,ECM_Addendum__c>) newItems, (Map<Id, ECM_Addendum__c>) oldItems);//ECM-6078
        System.debug('***3'+Limits.getQueries()+' '+Limits.getCpuTime());
        ECM_AddendumTriggerHelper.updateDistributionAchievedInCI((Map<Id,ECM_Addendum__c>)newItems, (Map<Id,ECM_Addendum__c>)oldItems);//CUS-327
        System.debug('***4'+Limits.getQueries()+' '+Limits.getCpuTime());
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {    
    }  
    
    //After Undelete Trigger Handler     
    public void afterUndelete(Map<Id, SObject> oldItems) {  
        
    }

}