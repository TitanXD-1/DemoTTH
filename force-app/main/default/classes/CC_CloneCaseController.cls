/**********************************************************************
Name: CC_CloneCaseController
=======================================================================
Purpose: This is to clone the existing Case record
=======================================================================
History                                                            
-------                                                            
VERSION			AUTHOR			           DATE			    DETAIL
1.0				Ch V Lakshminarayana       30/04/2021		Create a new Case with clone of Existing Case
***********************************************************************/
public class CC_CloneCaseController {
    
    @AuraEnabled
    public static String cloneAnySobjet(String recordId){
        if(!String.isBlank(recordId)){
            try{
            Set<Id> contentDocIds = new Set<Id>();
            for(ContentDocumentLink contDoc :[select ContentDocumentId, LinkedEntityId, shareType, Visibility from ContentDocumentLink 
                                              Where LinkedEntityId =: recordId])
            {
                contentDocIds.add(contDoc.ContentDocumentId);
            }
            List<ContentVersion> contVerList = new list<ContentVersion>();
            if(contentDocIds.size() >0){
                contVerList=[select Id, ContentLocation, pathOnClient, Origin, OwnerId, title, versionData
                             from ContentVersion Where ContentDocumentId IN: contentDocIds];
            }
            Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            String objectAPIName = '';
            String keyPrefix = recordId.substring(0,3);
            for( Schema.SObjectType obj : schemaMap.Values() ){
                String prefix = obj.getDescribe().getKeyPrefix();
                if(prefix == keyPrefix){
                    objectAPIName = obj.getDescribe().getName();
                    break;
                }
            }
            Set <String> fieldMap = schemaMap.get(objectAPIName).getDescribe().fields.getMap().keySet();
            String soqlQuery = 'SELECT ' ; 
            for (String s :fieldMap ){
                if(schema.getGlobalDescribe().get(objectAPIName).getDescribe().fields.getMap().get(s).getDescribe().isAccessible()){
                    soqlQuery +=  + s+',';
                }
            }
            soqlQuery =  soqlQuery.removeEnd(',');
            soqlQuery += ' FROM ' +objectAPIName +' WHERE ID = \'' + recordId +'\'' ;
            System.debug('soqlQuery'+soqlQuery);
            Case record = Database.query(soqlQuery);
            Case clondedParentRecordID= record.clone(false, false, false, false);
            if(clondedParentRecordID != null ){
                clondedParentRecordID.Evidence_Requested__c = null;
                clondedParentRecordID.CC_Evidence_Received__c = null;
                clondedParentRecordID.CC_Received_from_Investigation__c = null;
                clondedParentRecordID.CC_Passed_for_Investigation__c = null;
                clondedParentRecordID.CC_Final_Report_Issued__c = null;
                clondedParentRecordID.CC_Interim_Report_Issued__c = null;
                clondedParentRecordID.CC_Closed__c = null;
                clondedParentRecordID.CC_Is_Customer_Concern_Created__c = false;
            }
            system.debug('Clone rec ' + clondedParentRecordID);
            
            insert clondedParentRecordID ;
            List<Contentversion> newContVerList = new List<ContentVersion>();
            if(!String.isBlank(clondedParentRecordID.Id) && contVerList.size() > 0){
                for(Contentversion conVer:contVerList){
                    system.debug('conVer==='+conVer.ContentLocation+'=='+conVer.Title);
                    if(conVer.ContentLocation =='S'){
                    ContentVersion newContVer= new ContentVersion();
                    newContVer.ContentLocation = conVer.ContentLocation;
                    newContVer.PathOnClient = conVer.PathOnClient;
                    newContVer.Origin = conVer.Origin;
                    newContVer.OwnerId =conVer.OwnerId;
                    newContVer.Title = conVer.Title;
                    newContVer.VersionData = conVer.VersionData; 
                    newContVerList.add(newContVer);
                    }
                } 
            }
            if(newContVerList.size() > 0)
            {
                insert newContVerList;
                List<ContentDocumentLink> newContDocList = new List<ContentDocumentLink>();
                for(ContentVersion conV:[Select ContentDocumentId From ContentVersion Where ID IN : newContVerList]){
                    ContentDocumentLink newconDoc = new ContentDocumentLink();
                    newconDoc.ContentDocumentId = conV.ContentDocumentId;
                    newconDoc.LinkedEntityId = clondedParentRecordID.Id;
                    newconDoc.ShareType = 'V';
                    newconDoc.Visibility = 'InternalUsers';
                    newContDocList.add(newconDoc);
                }
                insert newContDocList;
            }
            return clondedParentRecordID.Id ; 
            }catch(exception ex){
                throw new AuraHandledException('Something went wrong in case clone');
            }
    }
        return '';
    }

}