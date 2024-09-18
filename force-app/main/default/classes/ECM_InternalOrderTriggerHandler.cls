/**********************************************************************
Name: ECM_InternalOrderTriggerHandler
=======================================================================
Purpose: Trigger Handler Class for ECM_InternalOrderTrigger  ECM-2235
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                        DATE              DETAIL
1.0      Anivesh Muppa                  14/07/2020       Initial Development
2.0		 Pradeep Kumar Reddy			23-12-2020       Apex sharing for the Internal Orders ECM-3486
2.1		 Sayan Mullick					20/12/2021		 Internal Order Sharing from Sales organisation CST-497
***********************************************************************/
public with sharing class ECM_InternalOrderTriggerHandler implements TriggerHandler{
	public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_InternalOrderTriggerHandler';
    public static Boolean isFirstTime = true;
    
    //Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){ 
        
        triggerDisabled = false;//EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        system.debug('bol '+triggerDisabled);
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler 
    public void beforeInsert(List<SObject> newItems) {
         system.debug('beforeInsert');
        //Fiscal Year calculation on Internal Order.        
        ECM_InternalOrderTriggerHelper.updateIOFasicalYear(newItems);
		CST_SharingUtil.updateSalesOrganization(newItems, null,'SAP_Company_Code__c');
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        system.debug('beforeUpdate');
       ECM_InternalOrderTriggerHelper.updateIOFasicalYearOnBefore(newItems.values(),oldItems);
	   CST_SharingUtil.updateSalesOrganization(newItems.values(), oldItems.values(), 'SAP_Company_Code__c'); 
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        ECM_InternalOrderTriggerHelper.checkAndGenerateSharing(newItems.values());    
        ECM_InternalOrderTriggerHelper.checkAndGenerateSharingfromSalesOrg(newItems.values());
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        If(isFirstTime){
        	ECM_InternalOrderTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
        ECM_InternalOrderTriggerHelper.validateAndReGenerateSharingfromSalesOrg(newItems.values(), oldItems);
        }
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            
        
    }
}