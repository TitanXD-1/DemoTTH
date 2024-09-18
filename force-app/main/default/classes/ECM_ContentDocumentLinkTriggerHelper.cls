/**********************************************************************
Name: ECM_ContentDocumentLinkTriggerHelper
Test Class: ECM_ContentDocumentLinkTriggerHelperTest
=======================================================================
Purpose: To Autopopulate the RecordType and Contnet Type for the Documents.
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            		DATE              DETAIL
1.0      Chandrakanth Suram  	  18/02/2021        ECM-3950  

***********************************************************************/

Public without sharing class ECM_ContentDocumentLinkTriggerHelper{
    public static void recordTypeUpdate(Map<Id,SObject> newItems) {
        
        Id profileID = [SELECT Id from Profile where Name ='Legal User'].Id;
        if(Userinfo.getProfileId() == profileID){
            Set<Id> setContentDoc = new Set<Id>();
            list<ContentDocumentLink> cdLinkList = new list<ContentDocumentLink>();
            Id linkedEntityId;
            set<id> conDocId = New set<id>();
            Map<id,ContentDocumentLink> newContentDocumentLink = (Map<id,ContentDocumentLink>)newItems;
            //To query the recordTypeId of Contracts In Content Version Sobject to update it to the followed Document
            Id rt = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Contracts').getRecordTypeId();
                    
            //To query Uploaded Document
            for(ContentDocumentLink objConDocLink :newContentDocumentLink.values()){
                
                String sobjectName = (objConDocLink.LinkedEntityId).getSObjectType().getDescribe().getName();       
                
                if(sobjectName == 'ECM_Addendum__c'){      
                    
                    conDocId.add(objConDocLink.ContentDocumentId);
                    
                }               
            }
            if(conDocId.size() > 0){
                List<ContentVersion> cdList = new List<ContentVersion>();
                for(ContentVersion cd : [Select Id, RecordTypeId, Content_Type__c from ContentVersion where ContentDocumentId =:conDocId]){    
                    cd.RecordTypeId = rt;
                    cd.Content_Type__c = 'Amended T&C';
                    cdList.add(cd);
                }
                Database.upsert(cdList);
            }
                
            
        }
        
    }
    
    
}