/*
Name: EDGE_CallNotesController
Req: 
ES20-623
History                                                                                                                        
VERSION   AUTHOR            DATE              DETAIL
1.0    Preyanka Ghosh     22/04/2019      Initial Development
2.0	   Shivam Chauhan	  29/07/2023	  143367
*/
public without sharing class EDGE_CallNotesController {
    
    static List<EDGE_CallNotesWrapper> lstNotesWrapper = new List<EDGE_CallNotesWrapper>();
	static Map<Id, List<FeedItem>> mapContentVerFeedItem = new Map<Id, List<FeedItem>>();
    /* 
Purpose: To fetch all Notes related to call and account                                                       
*/
    @AuraEnabled
    public Static List<EDGE_CallNotesWrapper> getCallNotes(String accId){
         Map<Id,FeedItem> mapFeedItem = new Map<id,FeedItem>();
         //Map<Id, List<FeedItem>> mapContentVerFeedItem = new Map<Id, List<FeedItem>>();
         Map<Id, List<ContentVersion>> mapFeedWithConVer = new Map<Id, List<ContentVersion>>();
        Set<Id> setParentId = new Set<Id>();
        
        try{
            if(String.isNotBlank(accId)){
                setParentId.add(accId);
                for(Call__c objCall : [SELECT Id FROM Call__c WHERE Account__c =:accId WITH SECURITY_ENFORCED]) {
                    setParentId.add(objCall.Id);
                }
                if(setParentId != null && setParentId.size()>0){

                     mapFeedItem =  new Map<Id,FeedItem>([SELECT Id, Body, Type, ParentId, Parent.Name, CreatedById, CreatedBy.Name, CreatedBy.FirstName, 
                                                         CreatedBy.LastName, CreatedDate, RelatedRecordId,
                                                         (SELECT FeedEntityId, Id, RecordId, Title, Type, Value FROM FeedAttachments)
                                                         FROM FeedItem 
                                                         WHERE (Type = 'TextPost' OR Type = 'ContentPost') AND ParentId IN :setParentId ORDER BY CreatedDate DESC
                                                        ]);

            }
                    if(mapFeedItem != null && mapFeedItem.size()>0){
                        mapContentVerFeedItem = objFeedItemValue(mapFeedItem);
                        mapFeedWithConVer = getobjContentVersion(mapContentVerFeedItem);
                        getfeedId(mapFeedItem,mapFeedWithConVer);
                    }
            }
        }
            catch(Exception excption){
                System.debug(LoggingLevel.Debug,'excption:::'+excption);
            }
            System.debug(LoggingLevel.Debug,'lstNotesWrapper:::'+lstNotesWrapper);
            return lstNotesWrapper;
        }

        public Static Map<Id, List<FeedItem>> objFeedItemValue(Map<id,FeedItem> mapFeedItem){
            Map<Id, List<FeedItem>> mapContentVerFeedItem = new Map<Id, List<FeedItem>>() ;
            for(FeedItem objFeedItem: mapFeedItem.values()){
                mapContentVerFeedItem.putAll(populateMapContentVerFeedItem(objFeedItem)); 
            } 
            return mapContentVerFeedItem;
        }
        //This method is populating objFeedAttachment and adding it to objFeeditem.
        public static Map<Id, List<FeedItem>> populateMapContentVerFeedItem(FeedItem objFeedItem){
            //Map<Id, List<FeedItem>> mapContentVerFeedItem = new Map<Id, List<FeedItem>>() ;
            if(objFeedItem.RelatedRecordId != null && objFeedItem.FeedAttachments != null && objFeedItem.FeedAttachments.size()>0){


                List<FeedAttachment> lstFeedAttach = objFeedItem.FeedAttachments;
                for(FeedAttachment objFeedAttachment : lstFeedAttach){

                    if(mapContentVerFeedItem.containsKey(objFeedAttachment.RecordId)){
                        mapContentVerFeedItem.get(objFeedAttachment.RecordId).add(objFeedItem);
                    }else{
                        mapContentVerFeedItem.put(objFeedAttachment.RecordId, new List<FeedItem>{objFeedItem});
                    }
                }                                
            } else {
                createNoteWrapper(objFeedItem, null);
            }
            return mapContentVerFeedItem;
        }
        
        public Static Map<Id, List<ContentVersion>> getobjContentVersion(Map<Id, List<FeedItem>> mapContentVerFeedItem){
            Map<Id, List<ContentVersion>> mapFeedWithConVer = new  Map<Id, List<ContentVersion>>();
            if(mapContentVerFeedItem != null && mapContentVerFeedItem.size()>0){
                for(ContentVersion objContentVersion : [SELECT Id, ContentDocument.FileType, ContentDocument.Title, ContentDocumentId FROM ContentVersion WHERE Id in :mapContentVerFeedItem.keySet() WITH SECURITY_ENFORCED]){
                    mapFeedWithConVer.putAll(populateObjContentVersionId(mapContentVerFeedItem,objContentVersion));
                }
            }
            return mapFeedWithConVer;
        }
        // This method is populating objFeedItem and adding it to objContentVersion.
        public static Map<Id, List<ContentVersion>> populateObjContentVersionId(Map<Id, List<FeedItem>> mapContentVerFeedItem, ContentVersion objContentVersion ){
            Map<Id, List<ContentVersion>> mapFeedWithConVer = new  Map<Id, List<ContentVersion>>();
            if(mapContentVerFeedItem.containsKey(objContentVersion.Id)){
                List<FeedItem> objFeedItemList = mapContentVerFeedItem.get(objContentVersion.Id);
                for(FeedItem objFeedItem : objFeedItemList){
                    if(mapFeedWithConVer.containskey(objFeedItem.Id)){
                        mapFeedWithConVer.get(objFeedItem.Id).add(objContentVersion);
                    } else {
                        mapFeedWithConVer.put(objFeedItem.Id, new List<Contentversion>{objContentVersion});
                    }
                    
                }       
            }
            return mapFeedWithConVer ;
        }
        public Static void getfeedId(Map<id,FeedItem> mapFeedItem,Map<Id, List<ContentVersion>> mapFeedWithConVer){
            if(mapFeedWithConVer != null && mapFeedWithConVer.size()>0){
                for(Id feedId : mapFeedWithConVer.keySet()){
                    createNoteWrapper(mapFeedItem.get(feedId), mapFeedWithConVer.get(feedId));
                }
            }
        }
        public static void createNoteWrapper(FeedItem objFeedItem, List<Contentversion> lstContentVersion){
            if(objFeedItem != null){
                EDGE_CallNotesWrapper edgeNotes = new EDGE_CallNotesWrapper();
                edgeNotes.feedId = objFeedItem.Id;
                edgeNotes.feedBody = objFeedItem.Body;
                edgeNotes.feedType = objFeedItem.Type;
                edgeNotes.feedParentId = objFeedItem.ParentId;
                edgeNotes.feedParentName = objFeedItem.Parent.Name;
                edgeNotes.feedCreatedById = objFeedItem.CreatedById;
                edgeNotes.feedCreatedByName = objFeedItem.CreatedBy.Name;
                edgeNotes.feedCreatedByFirstName = objFeedItem.CreatedBy.FirstName;
                edgeNotes.feedCreatedByLastName = objFeedItem.CreatedBy.LastName;
                edgeNotes.feedCreatedDate = objFeedItem.CreatedDate;
                edgeNotes.feedContentVerId = objFeedItem.RelatedRecordId;
                if(lstContentVersion != null && lstContentVersion.size()>0){
                    edgeNotes.lstContentVersion = lstContentVersion;
                }
                lstNotesWrapper.add(edgeNotes);
            }        
           
        }
     
    }