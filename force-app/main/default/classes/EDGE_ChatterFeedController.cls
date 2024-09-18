/**
Name: EDGE_ChatterFeedController

Req: 
ES20-9721

History                                                            
-------                                                            
VERSION   AUTHOR              DATE            DETAIL
1.0       Juned Khan          05/02/2021      Initial Development
1.1		  Doman Murmu		  17/07/2023	  142822
**/

public inherited sharing class EDGE_ChatterFeedController {
    
/**
Purpose: To fetch x number of chatter notes depend on market settings                                                        
**/
    
    public static EDGE_ChatterFeedWrapper getChatterNote(Id outletId,String timeStamp){ 
        EDGE_ChatterFeedWrapper chatFeedWrap = new EDGE_ChatterFeedWrapper();
        List<EDGE_ChatterFeedWrapper.ChatterNotes> chatterList =new List<EDGE_ChatterFeedWrapper.ChatterNotes>();
        Map<Id, EDGE_ChatterFeedWrapper> chatterWrapMap = new Map<Id, EDGE_ChatterFeedWrapper>();
        Map<Id,Id> contentVerToConDocMap =new Map<Id,Id>();
        Map<Id,List<Id>> chatterIdToContentVerMap =new Map<Id,List<Id>>();
        ContentVersion conVersionRec=new ContentVersion();
        List<ContentVersion> contentversionList= new List<ContentVersion>();
        List<FeedAttachment > feedAttachmentList = new List<FeedAttachment >();
        Map<Id,FeedAttachment> feedAttachMap=new  Map<Id,FeedAttachment>();
        Map<Id,List<Id>> ChatterContentVerMap= new Map<Id,List<Id>>();
        Map<Id,Id> contentVerToChatterMap= new Map<Id,Id>();
        List<AccountFeed> accfeedList=new List<AccountFeed>();
        Set<Id> contVerSet = new Set<Id>();
        Market_Setting__c mrktSetting;
        Account accountRecord;
        List<String> countryCodeList = new List<String>();
        Map<Id,Id> contVerToConDocIdMap = new Map<Id,Id>();
        Map<Id,AccountFeed> feedIdTofeedRecMap = new Map<Id,AccountFeed>();
        
        if(Schema.sObjectType.Account.isAccessible()){
            accountRecord=[Select id,Country__c,Country_Code__c,Primary_Sales_Rep__c,Status__c from Account where id=:outletId AND Status__c ='Active'];
        }
        if(accountRecord != null ){
            //Fetch Market Setting Records Based on Outlet record country
            List<Market_Setting__c> marketSettingRecords = [SELECT id,Number_of_Notes_per_Outlet__c from Market_Setting__c WHERE Geography__r.Code__c = :accountRecord.Country_Code__c LIMIT 1] ;
            if(marketSettingRecords != null && marketSettingRecords.size() > 0){
                mrktSetting = marketSettingRecords[0];
            }   
            
        }
        Integer numberOfNotes;
        if(mrktSetting != null){
            numberOfNotes =Integer.valueOf(mrktSetting.Number_of_Notes_per_Outlet__c);
        }
      //  System.debug('numberOfNotes = '+ numberOfNotes);
        String queryString='SELECT BestCommentId,Body,CommentCount,CreatedBy.Name,CreatedDate,Id,ParentId,RelatedRecordId,Title,Type,Visibility FROM AccountFeed WHERE ParentId=:outletId ';
        if(timeStamp !=null && !String.isEmpty(timeStamp) ){
            queryString += ' AND CreatedDate >='+ timeStamp + ' Order by CreatedDate desc ';
        }
        else{
            queryString += ' Order by CreatedDate desc ';
        }
        if(numberOfNotes !=null && numberOfNotes>0){
            queryString +='limit '+ numberOfNotes;
        }
        else{
            queryString +='limit '+ 0; 
        }
        if(Schema.sObjectType.AccountFeed.isAccessible() ){
            for(AccountFeed accFeed :Database.query(String.escapeSingleQuotes(queryString))){	//142822
                if(accFeed.Id != null && accFeed.ParentId != null){
                    accfeedList.add(accFeed);
                }
                feedIdTofeedRecMap.put(accFeed.Id, accFeed);
            }
            
            for(FeedAttachment feed : [Select Id,FeedEntityId,RecordId from FeedAttachment where FeedEntityId IN :accfeedList]){
                contVerSet.add(feed.RecordId);
            }
            
            for(ContentVersion contentVerRec : [Select id, ContentDocumentId,CreatedDate from ContentVersion where Id in :contVerSet ]){
                contVerToConDocIdMap.put(contentVerRec.Id,contentVerRec.ContentDocumentId);
            }           
            
                for(FeedAttachment feed : [Select Id,FeedEntityId,RecordId from FeedAttachment where FeedEntityId IN :accfeedList]){
                    if(chatterIdToContentVerMap.containsKey(feed.FeedEntityId)){
                        chatterIdToContentVerMap.get(feed.FeedEntityId).add(feed.RecordId);
                    }
                    else{
                        chatterIdToContentVerMap.put(feed.FeedEntityId, new List<Id> {feed.RecordId});                       
                    }
                }  
        }
        if(feedIdTofeedRecMap != null){
            for(Id feedRecId : feedIdTofeedRecMap.keySet()){
                AccountFeed accountFeedRec = feedIdTofeedRecMap.get(feedRecId);
                if(accountFeedRec != null){
                    EDGE_ChatterFeedWrapper.ChatterNotes chatterNote = new EDGE_ChatterFeedWrapper.ChatterNotes();
                    chatterNote.chatterId=accountFeedRec.Id;
                    chatterNote.body=accountFeedRec.Body;
                    chatterNote.createdDate=accountFeedRec.CreatedDate;
                    chatterNote.createdBy=accountFeedRec.CreatedBy.Name; 
                    List<Id> contentVersionListId =  chatterIdToContentVerMap.get(accountFeedRec.Id);
                    List<EDGE_ChatterFeedWrapper.ContentRecord>  contentRecordsList = new List<EDGE_ChatterFeedWrapper.ContentRecord>();
                    if(contentVersionListId != null){
                        for(Id cvRecId : contentVersionListId){
                            EDGE_ChatterFeedWrapper.ContentRecord conRec = new EDGE_ChatterFeedWrapper.ContentRecord();
                            conRec.contentVerId = cvRecId;
                            conRec.contentDocId = contVerToConDocIdMap.get(cvRecId);
                            contentRecordsList.add(conRec);
                        }
                    }
                    
                    chatterNote.contentRecords = contentRecordsList;
                    chatterList.add(chatterNote); 
                    chatFeedWrap.chatterNotesList = chatterList;   
                    chatFeedWrap.outletId =accountFeedRec.ParentId ;    
                }
            }
        }
        return  chatFeedWrap;
        
    }
}