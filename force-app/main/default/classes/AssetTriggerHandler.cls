/**

*@Description: AssetTriggerHandler

*@Purpose: Trigger Handler Class for Asset

*@History: 

*@Version  Developer          Date			Story/Purpose

* 1.1      Mayank Singh     11/08/2021       ES20-10906
* 1.2      Aparajita		27/09/2021		 ES20-10414
* 1.3 	   Prasanth         26/09/2021       ES20-10398
* 1.4	   Aparajita		07/10/2021		 ES20-11091
* 1.5	   Saranya L		08/10/2021		 ES20-10415
* 1.6	   Rajarshi Lahiri  09/12/2021		 ES20-11646
* 1.7	   Aparajita		14/05/2022       ES20-12149
* 1.8      Wribhu Bose		08/08/2023		143681			
*/

public class AssetTriggerHandler implements TriggerHandler{
    // Allows unit tests (or other code) to disable this trigger for the transaction
    public static Boolean triggerDisabled = false;
    public static string triggerName = 'Asset Trigger';
    public static Boolean isFirstTime = true;
    
    // Checks to see if the trigger has been disabled either by custom setting or by code
    public Boolean isDisabled(){     
        if(!triggerDisabled){
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);
        }        
        return triggerDisabled;
    }
    
    //Before Insert Trigger Handler
    public void beforeInsert(List<SObject> newItems) {
        EDGE_UtilityClass.populateGUID(newItems); //ES20-10906
        EDGE_AssetTriggerHelper.populateInstallDate(newItems); //ES20-10414
        EDGE_AssetTriggerHelper.populateAssetName(newItems,null); //ES20-10398
        EDGE_AssetTriggerHelper.restrictDuplicateNonCOPAssets(newItems,null); //ES20-11091,ES20-12149
        EDGE_AssetTriggerHelper.populateProductDetails(newItems,null);//ES20-10415
        EDGE_AssetTriggerHelper.populateRemovalDate(newItems,null);
        EDGE_AssetTriggerHelper.enablePendingForBatch(newItems,null);
        EDGE_AssetTriggerHelper.validateOffsetDay(newitems);
        if(isFirstTime){
            GT_AssetTriggerHelper.populateLastTRAXOutboundDate(newItems,null); // 143681
        }
    }
    
    //Before Update Trigger Handler
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_AssetTriggerHelper.populateInstallDate(newItems.values()); //ES20-10414
        EDGE_AssetTriggerHelper.populateAssetName(newItems.values(),oldItems); //ES20-10398
        EDGE_AssetTriggerHelper.restrictDuplicateNonCOPAssets(newItems.values(),oldItems); //ES20-11091,ES20-12149
        EDGE_AssetTriggerHelper.populateProductDetails(newItems.values(),oldItems);//ES20-10415
        EDGE_AssetTriggerHelper.populateRemovalDate(newItems.values(),oldItems);
        EDGE_AssetTriggerHelper.enablePendingForBatch(newItems.values(),oldItems);
        EDGE_AssetTriggerHelper.validateOffsetDay(newItems.values());
        EDGE_AssetTriggerHelper.enableOffsetDayFlag(newItems.values(),oldItems);
        if(isFirstTime){
            GT_AssetTriggerHelper.populateLastTRAXOutboundDate(newItems.values(),oldItems); // 143681
        }
    }
    
    //Before Delete Trigger Handler
    public void beforeDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Insert Trigger Handler
    public void afterInsert(Map<Id, SObject> newItems) {
        
    }
    
    //After Update Trigger Handler
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
    }
    
    //After Delete Trigger Handler
    public void afterDelete(Map<Id, SObject> oldItems) {
        
    }
    
    //After Undelete Trigger Handler
    public void afterUndelete(Map<Id, SObject> oldItems) {
        
    }
}