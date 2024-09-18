/**
* @name : CampaignTrigger
* @description : This is to handle Campaign Trigger Events
* @history 
* VERSION     AUTHOR         DATE           DETAIL
* 1.0         Rithika        06/12/21       NCP-5443
**/
trigger CampaignTrigger on Campaign (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CampaignTriggerHandler());
}