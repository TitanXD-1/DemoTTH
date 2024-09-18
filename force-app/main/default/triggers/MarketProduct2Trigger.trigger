/**********************************************************************
Name: MarketProduct2Trigger
======================================================
Purpose: Trigger for Market_Product2__c
======================================================
History
-------
VERSION     AUTHOR         DATE       DETAIL
1.0         Ajay                    Initial Development (NCP-2857)
***********************************************************************/
trigger MarketProduct2Trigger on Market_Product2__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new MarketProduct2TriggerHandler());
}