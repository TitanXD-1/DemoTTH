public without sharing class MD_FeatureController {
    
    public class dataWrapper{
        @AuraEnabled public string contentTitle{get;set;}
        @AuraEnabled public string contentDescription{get;set;}
        @AuraEnabled public string errorMessage{get;set;}
        @AuraEnabled public list<map<String,Object>> featureRecords{get;set;}
    }
    @AuraEnabled
    public static dataWrapper getFeature(String componentExternalId){
        List<MD_Feature__c> featureObj = new List<MD_Feature__c>();
        Map<String,Object> featureMap=new Map<String,Object>();
        list<map<String,Object>> Recordfields = new list<map<String,Object>>();
        
        try{
            //List<DiageoCMS__Component__c> compLst = new List<DiageoCMS__Component__c>();
            //compLst = [SELECT Id,DiageoCMS__ClusterExternalId__c ,DiageoCMS__ExternalId__c FROM DiageoCMS__Component__c WHERE DiageoCMS__ExternalId__c =: componentExternalId];
            //system.debug('compLst-->'+compLst); 
            
            List<DiageoCMS__ContentAssignment__c> conAssignLst = new List<DiageoCMS__ContentAssignment__c>();
            conAssignLst = [SELECT Id, Name, DiageoCMS__Content__c ,DiageoCMS__Component__c, DiageoCMS__ExternalId__c, DiageoCMS__Order__c, DiageoCMS__Component__r.DiageoCMS__ExternalId__c FROM DiageoCMS__ContentAssignment__c WHERE DiageoCMS__Component__r.DiageoCMS__ExternalId__c =: componentExternalId];
            system.debug('conAssignLst-->'+conAssignLst);
            
            List<MD_Feature__c> featureLst = new List<MD_Feature__c>();
            featureLst = [SELECT Id, Name, Content__r.DiageoCMS__Title__c,Content__r.DiageoCMS__Error_Message_On_Lock__c, Content__r.DiageoCMS__Extract__c, Feature_Icon__c,Feature_Title__c,Feature_Description__c,Order__c FROM MD_Feature__c WHERE Content__c =: conAssignLst[0].DiageoCMS__Content__c ORDER BY Order__c];
            system.debug('featureLst-->'+featureLst);
            dataWrapper dwrap = new dataWrapper();
            dwrap.contentTitle = featureLst[0].Content__r.DiageoCMS__Title__c;
            dwrap.contentDescription = featureLst[0].Content__r.DiageoCMS__Extract__c;
            dwrap.errorMessage = featureLst[0].Content__r.DiageoCMS__Error_Message_On_Lock__c;
            system.debug('errorMessage'+featureLst[0].Content__r.DiageoCMS__Error_Message_On_Lock__c);
            for(MD_Feature__c sf :featureLst){
                featureMap=new Map<String,Object>();
                featureMap.put('Icon',sf.Feature_Icon__c);
                featureMap.put('Title',sf.Feature_Title__c);
                featureMap.put('Description',sf.Feature_Description__c);
                Recordfields.add(featureMap);
            }
            dwrap.featureRecords = Recordfields;
            system.debug('@@@JSON'+dwrap);
            return dwrap;  
        }catch(Exception e){
            system.debug('ERROR' + e.getMessage());
            return null; 
        }    
    }
   
}