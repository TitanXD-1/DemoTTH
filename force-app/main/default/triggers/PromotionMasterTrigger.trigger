/**
* @name PromotionMasterTrigger
* @purpose - This is to handle Promotion Master Trigger Events
* @history
* Version              Author                   Date            Detail
   1.0              Mayukh/Geethika           17/06/2022      ES20-12989 - Initial Development

**/
trigger PromotionMasterTrigger on Promotion_Master__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new PromotionMasterHandler());
}