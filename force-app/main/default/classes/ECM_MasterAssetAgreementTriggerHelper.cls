/*
* @Name: ECM_MasterAssetAgreementTriggerHelper
* @description: This is Class for fetch required data to create trigger on Master Asset Aggrement Object.
* @History                                                            

* VERSION   AUTHOR                   DATE                    DETAIL
* 1.0       Rajani && Anand        2/8/2022                ECM-5891- Initial Development 
*/
        
public class ECM_MasterAssetAgreementTriggerHelper {
    //This method is used to validate that new Maste Asset agreement 
    //can't be created or deleted if there is any Active
    //Asset Contract present with the Agreement Type
    public static void aggrementTypeDuplicateCheck(List<ECM_Master_Asset_Agreements__c> newMstrAsstAggItem, Map<Id,SObject> oldItems){
        Map<Id,ECM_Master_Asset_Agreements__c> oldMstrAsstAggItem;
        List<ECM_Master_Asset_Agreements__c> masterAsstAggtListToValidate = new List<ECM_Master_Asset_Agreements__c>();
        Set<Id> aggrementIdSet = new Set<Id>(); 
        Map<String,Contract> agreementWithContractMap = new Map<String,Contract>();
        Id profileId = UserInfo.getProfileId();
        List<String> readOnlyProfiles = System.label.Master_Asset_Agreement_Obj.split(',');
        Profile profileObj = [SELECT Id, Name FROM Profile WHERE Id =: profileId];
        //this is for new Master Asset Agreement Creation
        if(newMstrAsstAggItem!= null && newMstrAsstAggItem.size()>0 && !newMstrAsstAggItem.isEmpty()){
            masterAsstAggtListToValidate.addAll(newMstrAsstAggItem);
             System.debug('InsertData'+masterAsstAggtListToValidate);
        }else if(oldItems != null && oldItems.size()>0 && !oldItems.isEmpty()){ // this is for delete Master Asset Agreement
            oldMstrAsstAggItem = (Map<Id,ECM_Master_Asset_Agreements__c>) oldItems;
            masterAsstAggtListToValidate.addAll(oldMstrAsstAggItem.values());
            System.debug('DeleteData'+masterAsstAggtListToValidate);
        }
        for(ECM_Master_Asset_Agreements__c maObj : masterAsstAggtListToValidate){
            aggrementIdSet.add(maObj.ECM_Agreement_Type__c);
        }
        if(!aggrementIdSet.isEmpty()){
            for(Contract conObj : [SELECT Id,ECM_Agreement_Type__c,status 
                                   FROM Contract 
                                   WHERE Status='Active' 
                                   AND ECM_Agreement_Type__c IN : aggrementIdSet 
                                   AND Recordtype.Name = 'Asset Contract']){
                agreementWithContractMap.put(conObj.ECM_Agreement_Type__c, conObj);
            }
        }
        if(!agreementWithContractMap.isEmpty()){
            for(ECM_Master_Asset_Agreements__c maObj : masterAsstAggtListToValidate){
                if(agreementWithContractMap.containsKey(maObj.ECM_Agreement_Type__c) && readOnlyProfiles.contains(profileObj.Name)){
                    maObj.addError(System.Label.Error_Msg_on_ECM_MasterAssetAgreementTrigger);
                }
            }
        }
    } 
}