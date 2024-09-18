/*
@ Name: RangingBonusDetailsTrigger

@ Description: This is the trigger of RangingBonusDetails object

@History:                                                            
                                                            
VERSION       AUTHOR               DATE              DETAIL
1.0           Sagnik Sanyal        04/09/2024        156151 - Enable Country based Sharing _SFDC
*/

trigger RangingBonusDetailsTrigger on Ranging_Bonus_Details__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new RangingBonusDetailsTriggerHandler());
}