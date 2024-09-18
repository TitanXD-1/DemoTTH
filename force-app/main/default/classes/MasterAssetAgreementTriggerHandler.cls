/*
* @Name: MasterAssetAgreementTriggerHandler
* @description: This is Class for fetch required data to create trigger on Master Asset Aggrement Object.
* @History                                                            

VERSION    	AUTHOR                	DATE					DETAIL
1.0     	Rajani Abbireddy        2/8/2022				ECM-5891-Initial Development 
*/


public class MasterAssetAgreementTriggerHandler implements TriggerHandler
{
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'MasterAssetAgreementTrigger';
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        ECM_MasterAssetAgreementTriggerHelper.aggrementTypeDuplicateCheck(newItems,null);
    }
    //BeforeUpdate Trigger Handler 
    public void beforeUpdate (Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }    
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        ECM_MasterAssetAgreementTriggerHelper.aggrementTypeDuplicateCheck(null,oldItems);
    }   
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {            
        
    }
    //AfterUpdate
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        
    }  
    //AfterInsert
    public void afterInsert(Map<Id, SObject> newItems) {
        
    }   
}