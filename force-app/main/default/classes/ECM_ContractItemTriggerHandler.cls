/*
* Class Name : ECM_ContractItemTriggerHandler
* @description: Class with all handler methods of ECM_ContractItemTrigger.
* @history
* AUTHOR            	DATE              	DETAIL
* Keshava Murthy M     27/01/2022      	ECM-5127 : Disable Edit for related objects of Contract_SFDC_GLO
* Pratap Sen           11/02/2022       ECM-5218 : Fix for the Bug - Enable Profile Check
* Tanishq Banerjee     10/11/2022       ECM-6316 : CTD KPI Testing
*/
public class ECM_ContractItemTriggerHandler implements TriggerHandler {
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ECM_ContractItemTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){        
        triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {  
         ECM_ContractItemTriggerHelper.updateCiNSV(newItems,null);//ECM-6316

    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_ContractItemTriggerHelper.disableConItem(newItems,oldItems);
        ECM_ContractItemTriggerHelper.updateCiNSV(newItems.values(),oldItems);//Fixed implementation of ECM-5292
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        ECM_ContractItemTriggerHelper.disableConItem(null,oldItems);
        //ECM_ContractItemTriggerHelper.rollUpsCal(null,oldItems);
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        ECM_ContractItemTriggerHelper.rollUpsCalalter(newItems.values(),null);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        ECM_ContractItemTriggerHelper.rollUpsCalalter(newItems.values(),oldItems);
        ECM_ContractItemTriggerHelper.updateChildVolumeCTD(newItems.values(),oldItems);
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {    
        ECM_ContractItemTriggerHelper.rollUpsCalDel(oldItems);
    }  
    
    //After Undelete Trigger Handler     
    public void afterUndelete(Map<Id, SObject> oldItems) {  
        
    }
    
}