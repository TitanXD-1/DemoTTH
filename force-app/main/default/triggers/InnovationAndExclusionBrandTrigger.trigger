/**
*Name: InnovationAndExclusionBrandTrigger
*Purpose: Provide access to Innovation_Exclusion_Brand__c

*History                                                            

VERSION    AUTHOR                    DATE                   DETAIL
1.0 -    Nidhi/Stuti           13/10/2023      146952 - Provide access to new Objects_Tech_SFDC
**/
trigger InnovationAndExclusionBrandTrigger on Innovation_Exclusion_Brand__c (after delete, after insert, after undelete, after update, before delete, before insert, before update) {
    TriggerDispatcher.run(new InnovationExclusionBrandTriggerHandler());
}