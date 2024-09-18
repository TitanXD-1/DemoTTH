/**
 * @Description: ContactTriggerHandler

 * @Purpose: Trigger Handler Class for ContactTrigger

 * @History:
 
 * @VERSION        AUTHOR              DATE            DETAIL
 * 1.0          Sandeep Sahoo       2019-03-15      Initial Development
 * 2.0          Sai Kumar           2021-11-09      NCP-5159
 * 3.0          Rakesh Kumar        2021-12-09      NCP-3358 (updateLoginNextAction)
 * 4.0          Rubeena Naaz        2022-03-28      NCP-6408 (updateAccountData)
 * 5.0          Rajarshi Lahiri	    26/04/2022      ES20-12548 and ES20-12393 (commented out method calls pertaining to Primary/Secondary Contacts validations)
 * 6.0			Aparajita    		27/04/2022      ES20-12476(Method:updateOwnerChangedFlag)
 * 7.0			Rubeena				14/06/2022		NCP-6837
 * 8.0          Suvendu             25/07/2023      143004 Allow users to create/edit contact based on Business Role_SFDC
 **/
public with sharing class ContactTriggerHandler implements TriggerHandler{
    
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'ContactTrigger';
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        //Commented out for ES20-12548 and ES20-12393
        //EDGE_ContactTriggerHelper.checkPrimaryContact(newItems);
        EDGE_ContactTriggerHelper.validatePhoneNumber(newItems, null);
        EDGE_UtilityClass.populateGUID(newItems);   
        EDGE_ContactTriggerHelper.populatePardotBUCode(newItems, null);
        D1_ContactTriggerHelper.updateEmailPreference(newItems, null); //(NCP-5159)
        D1_ContactTriggerHelper.validatePreferredLanguage(newItems); //(NCP-6349)
        D1_ContactTriggerHelper.validateUserBusinessRole(newItems, null); //143004
    }

    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        //Commented out for ES20-12548 and ES20-12393
       //EDGE_ContactTriggerHelper.checkPrimaryContactUpdate(newItems,oldItems); 
        EDGE_ContactTriggerHelper.validatePhoneNumber(newItems.values(), oldItems);
        EDGE_ContactTriggerHelper.populatePardotBUCode(newItems.values(), oldItems);
        D1_ContactTriggerHelper.updateEmailPreference(newItems.values(), oldItems); //(NCP-5159)
        D1_ContactTriggerHelper.updateLoginNextAction(newItems.values(), oldItems); //(NCP-3358)
        D1_ContactTriggerHelper.validatePreferredLanguage(newItems.values()); //(NCP-6349)
        EDGE_ContactTriggerHelper.updateOwnerChangedFlag(newItems.values(), oldItems); //ES20-12476
        D1_ContactTriggerHelper.updatePOSOrderDate(newItems, oldItems); //NCP-6837
        D1_ContactTriggerHelper.validateUserBusinessRole(newItems.values(), oldItems); //143004

        
    }
    
    //Before Delete Trigger Handler   
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }   
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        //Commented out for ES20-12548 and ES20-12393
        //EDGE_ContactTriggerHelper.updateAccountContact(newItems);        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_ContactTriggerExtendedHelper.updateUserFields(newItems.values(), oldItems);
        D1_ContactTriggerHelper.updateAccountData(newItems,oldItems); //NCP-6408
        D1_ContactTriggerHelper.updatePOSOrderDateOnACR(newItems, oldItems); //NCP-6837
        
    }
    
    //After Delete Trigger Handler
    
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }  
    
    //After Undelete Trigger Handler    
    public void afterUndelete(Map<Id, SObject> oldItems) {
            
        
    }
}