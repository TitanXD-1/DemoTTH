/**********************************************************************
Name: CC_CustomerConcernTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for Customer Concern
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			DATE			DETAIL
1.0				Bhargav S		06/05/2021		Initial Development
***********************************************************************/
public without sharing class CC_CustomerConcernTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Customer Concern Trigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        List<SObject> triggerNew = newItems.values();
       // List<CC_Customer_Concern__c> relevantRecords = new List<CC_Customer_Concern__c>();
        for(SObject o : triggerNew){
            CC_Customer_Concern__c ccNew = (CC_Customer_Concern__c)newItems.get(o.Id);
            CC_Customer_Concern__c ccOld = (CC_Customer_Concern__c)oldItems.get(o.Id);
            if(ccNew.CC_Status__c != ccOld.CC_Status__c){
               // relevantRecords.add(ccNew);
                if(ccNew.CC_Status__c == 'Closed')
                    ccNew.CC_Closed__c = System.today();
            }
        }
        //if(relevantRecords.size()>0)
           // CC_CreateCaseFromConcern.updateCaseStatus(relevantRecords);
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {

        List<SObject> relevantRecords = new List<SObject>();
        for(SObject o : newItems.values()){
            CC_Customer_Concern__c cc = (CC_Customer_Concern__c)o;
            if(cc.CC_Case__c == null)
                relevantRecords.add(o);
        }
        CC_CreateCaseFromConcern.createCase(relevantRecords);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
		List<SObject> triggerNew = newItems.values();
        List<CC_Customer_Concern__c> relevantRecords = new List<CC_Customer_Concern__c>();
        for(SObject o : triggerNew){
            CC_Customer_Concern__c ccNew = (CC_Customer_Concern__c)newItems.get(o.Id);
            CC_Customer_Concern__c ccOld = (CC_Customer_Concern__c)oldItems.get(o.Id);
            if(ccNew.CC_Status__c != ccOld.CC_Status__c){
                relevantRecords.add(ccNew);               
            }
        }
        if(relevantRecords.size()>0)
            CC_CreateCaseFromConcern.updateCaseStatus(relevantRecords);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
       
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}