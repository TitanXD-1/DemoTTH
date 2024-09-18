/*
* @Name: MasterAssetAgreementTrigger
* @description: This is Class for fetch required data to create trigger on Master Asset Aggrement Object.
* @History                                                            

* VERSION   AUTHOR                   DATE                    DETAIL
* 1.0       Rajani        			2/8/2022                ECM-5891- Initial Development 
*/
trigger MasterAssetAgreementTrigger on ECM_Master_Asset_Agreements__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new MasterAssetAgreementTriggerHandler());
}