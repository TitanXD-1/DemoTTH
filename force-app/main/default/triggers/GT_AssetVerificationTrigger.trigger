/**
* @Name: GT_AssetVerificationTrigger
* @Purpose: Trigger for GT_Asset_Verification__c object
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     26/07/2023  140748 : [GT-134] Asset Verification Automations
*/

trigger GT_AssetVerificationTrigger on GT_Asset_Verification__c (before insert, after insert, before update, after update, before delete, after delete, after undelete) {
    TriggerDispatcher.run(new GT_AssetVerificationTriggerHandler());
}