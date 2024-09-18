/**
* @description This is to handle Assets trigger events
* @history
* 1.1     Mayank Singh       11/08/2021
*/

trigger AssetTrigger on Asset (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new AssetTriggerHandler());
}