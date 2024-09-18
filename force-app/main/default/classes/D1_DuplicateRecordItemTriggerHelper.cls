/*
* @name: D1_DuplicateRecordItemTriggerHelper
* @discription : Trigger Helper Class for DuplicateRecordItem.
* @History                                                            
* VERSION    AUTHOR              DATE              DETAIL
* 1.0        Saurav Paul         05/03/2021       
* */
public with sharing class D1_DuplicateRecordItemTriggerHelper {
    public static void populateRecordType(List<SObject> newItems){
        //Variables
        Set<Id> accIdSet = new Set<Id>();
        Map<Id,Account> accountMap;
        List<DuplicateRecordItem> dupRecrdItmList = new List<DuplicateRecordItem>();
        //Variables
        for(SObject sObj : newItems){
            DuplicateRecordItem itemObj = (DuplicateRecordItem)sObj;
            Schema.sObjectType entityType = itemObj.RecordId.getSObjectType();
            if(entityType == Account.sObjectType){
                accIdSet.add(itemObj.RecordId);
                dupRecrdItmList.add(itemObj);
            }
            if(!accIdSet.isEmpty()){
                accountMap = new Map<Id,Account>([SELECT Id,RecordType.Name FROM Account WHERE Id IN :accIdSet]);
                if(!dupRecrdItmList.isEmpty()){
                    for(DuplicateRecordItem itmObj : dupRecrdItmList){
                        if(accountMap!= null && accountMap.containsKey(itmObj.RecordId)){
                            itmObj.RecordType_Name__c = accountMap.get(itmObj.RecordId).RecordType.Name;
                        }
                    }
                }
            }
        }
    }
}