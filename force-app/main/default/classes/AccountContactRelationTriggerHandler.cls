/**
 * @name : AccountContactRelationTriggerHandler
 * @description : Trigger Handler Class for AccountContactRelationTrigger
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Sagar Barman    20/03/2019      Initial Development
 * 2.0          Anamika Shukla  28/01/2021      ES20-9443
 * 3.0          Rubeena Naaz    21/04/2021      NCP-2803(createExternalManageAccount, removeExternalManageAccount)
 * 4.0          Kapil Baliyan   03/01/2022      NCP-5143 (syncACR)

 * * 5.0        Rajarshi Lahiri 06/04/2022      ES20-12341(indirectContactShare)
 * 6.0          Wribhu Bose     26/04/2022      ES20-12548 and ES20-12393 (commented out method calls pertaining to Primary/Secondary Contacts validations)
 * 7.0          Saranya L       09/05/2022      ES20-12653(syncOutletRole)
 * 8.0			Rubeena			18/05/2022		NCP-6710(updateD1FirstOrderEmailCheck)
 * 9.0          Swaraj Samanta  03/06/2022      ES20-12654(updateDirectContactRoleFields)
 * 10.0			Rubeena			14/06/2022		NCP-6835(updatePOSOrderDateOnContact,clearPOSOrderDetails)

 */
public with sharing class AccountContactRelationTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'AccountContactRelationTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        //added for ES20-9443 
        EDGE_UtilityClass.populateGUID(newItems);
        //Commented out for ES20-12548 and ES20-12393
        //EDGE_AccountContactRelationTriggerHelper.validateContactOnInsert(newItems);   
          
    }
     //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //Commented out for ES20-12548 and ES20-12393
        //EDGE_AccountContactRelationTriggerHelper.checkPrimaryContactUpdate(newItems,oldItems); 
        D1_AccountContactRelationTriggerHelper.updateLastPOSOrderOnACR(newItems, oldItems); 
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        D1_AccountContactRelationTriggerHelper.createExternalManageAccount(newItems,null); 
        D1_AccountContactRelationTriggerHelper.afterInsertACRelationNotification(newItems,null); 
        D1_AccountContactRelationTriggerHelper.checkAndEnableBuyerSystem(newItems,null); // NCP-4527
        D1_AccountContactRelationTriggerHelper.syncACR(newItems,null); //NCP-5143
        EDGE_AccountContactRelationTriggerHelper.indirectContactShare(newItems,null);//ES20-12341////CUS-383
        EDGE_AccountContactRelationTriggerHelper.syncOutletRole(newitems);//ES20-12653
        D1_AccountContactRelationTriggerHelper.reParentingShipToContact(newItems);
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //Commented out for ES20-12548 and ES20-12393
    	//EDGE_AccountContactRelationTriggerHelper.updateRelatedContact(newItems,oldItems);
        D1_AccountContactRelationTriggerHelper.createExternalManageAccount(newItems,oldItems); //NCP-2781
        D1_AccountContactRelationTriggerHelper.removeExternalManageAccount(newItems,oldItems); //NCP-2803
        D1_AccountContactRelationTriggerHelper.afterUpdateACRelationNotification(newItems,oldItems); //NCP-2803
        D1_AccountContactRelationTriggerHelper.checkAndEnableBuyerSystem(newItems,oldItems); //NCP-4527
        D1_AccountContactRelationTriggerHelper.updateD1FirstOrderEmailCheck(newItems, oldItems); //NCP-6710
        D1_AccountContactRelationTriggerHelper.updatePOSOrderDateOnContact(newItems, oldItems); //NCP-6835
        D1_AccountContactRelationTriggerHelper.clearPOSOrderDetails(newItems, oldItems); //NCP-6835
        D1_AccountContactRelationTriggerHelper.syncACR(newItems,oldItems); //NCP-5143
        EDGE_AccountContactRelationTriggerHelper.updateDirectContactRoleFields(newItems.values(),oldItems); //ES20-12654
        EDGE_AccountContactRelationTriggerHelper.indirectContactShare(newItems,oldItems);//CUS-383
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
        
    }
}