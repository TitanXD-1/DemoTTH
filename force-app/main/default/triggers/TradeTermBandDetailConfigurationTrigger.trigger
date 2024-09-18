/**
*Name: TradeTermBandDetailConfigurationTrigger
*Purpose: Provide access to Trade_Term_Band_Detail__c

*History                                                            

VERSION    AUTHOR                    DATE                   DETAIL
1.0 -    Nidhi/Stuti           13/10/2023      146952 - Provide access to new Objects_Tech_SFDC
**/
trigger TradeTermBandDetailConfigurationTrigger on Trade_Term_Band_Detail__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new TradeTermBandDetailTriggerHandler());
}