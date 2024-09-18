public without sharing class CC_ContentDocumentLinkTriggerHelper {
    
    public static boolean calledFromSendFinalReport = false;
    
    public static String retrieveObjectNameFromId(Id recordId){
        String objectName = null;
        String idPrefix = String.valueOf(recordId).substring(0,3);
        Map<String, Schema.SObjectType> gd = Schema.getGlobalDescribe();
        for(Schema.SObjectType SObjType : gd.values()){
            Schema.DescribeSObjectResult r = SObjType.getDescribe();
            String prefix = r.getKeyPrefix();
            if(prefix!=null && prefix.equals(idPrefix)){
                objectName = r.getName();
                break;
            }
        }
        return objectName;
    }
    
    public static void cloneEvidences(List<ContentDocumentLink> evidenceList){
        if(!calledFromSendFinalReport){
            Set<Id> concernIds = new Set<Id>();
            for(ContentDocumentLink cdl : evidenceList){
                concernIds.add(cdl.LinkedEntityId);
            }
            Map<Id,CC_Customer_Concern__c> concernMap = new Map<Id,CC_Customer_Concern__c>([SELECT Id, CC_Case__c
                                                                                            FROM CC_Customer_Concern__c
                                                                                            WHERE Id IN : concernIds]);
            if(concernMap != null && !concernMap.isEmpty() ){
                List<ContentDocumentLink> evidenceClones = new List<ContentDocumentLink>();
                for(ContentDocumentLink cdl : evidenceList){
                    if(concernMap.get(cdl.LinkedEntityId) != null && concernMap.get(cdl.LinkedEntityId).CC_Case__c != null){
                        ContentDocumentLink cdlNew = cdl.clone();
                        cdlNew.LinkedEntityId = concernMap.get(cdl.LinkedEntityId).CC_Case__c;
                        evidenceClones.add(cdlNew);
                    }
                }
                insert evidenceClones;
            }
        }
    }
}