/**********************************************************************
	Name: MarketSettingTrigger
=======================================================================
	Purpose: This is to handle Market Setting Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION      AUTHOR            DATE              DETAIL
       1.0     Aniket Sen       30/06/2020      Initial Development
***********************************************************************/
trigger MarketSettingTrigger on Market_Setting__c (before insert, before update, after insert, after update, before Delete, after Delete, after Undelete) {
    TriggerDispatcher.run(new MarketSettingTriggerHandler());
}