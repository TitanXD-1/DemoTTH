/**********************************************************************
Name: EDGE_NotesServiceClass
======================================================================================
Req: The requirement is to build Custom API for mobile to create FeedItem.
User Story : ES20-
=======================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                DATE              DETAIL
1.0       Kapil Baliyan         18/04/2019        ES20-
***********************************************************************/

public inherited sharing class EDGE_NotesServiceHelperClass {
    
    //This Method is used to create notes
    public static EDGE_BriefcaseWrapper createNotes(string parentId, string contentDocId, string textMsg){
        EDGE_BriefcaseWrapper briefcaseWrapper = new EDGE_BriefcaseWrapper();
        string conVersionId = '';

        //Check If ParentId is not Blank
        if(string.isNotEmpty(parentId)){
            //Get ContentVersion Id
            if(string.isNotEmpty(contentDocId)){
                List<ContentVersion> contentVersionList = [select Id, ContentDocumentId from ContentVersion where ContentDocumentId =:contentDocId];
                if(contentVersionList != null && contentVersionList.size()>0){
                    conVersionId = contentVersionList[0].Id;
                    updateContentVerDetails(conVersionId, contentDocId, true);
                }
            }

            // Define the FeedItemInput object to pass to postFeedElement
            ConnectApi.FeedItemInput feedItemInput = createFeedItemInput(parentId, contentDocId, textMsg, true);

            // Post the feed item. 
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(Network.getNetworkId(), feedItemInput);

            //Get Response that we need to send to Mobile
            briefcaseWrapper = getResponse(feedElement, contentDocId, conVersionId);
        }
        return briefcaseWrapper;
    }

    //This Method is used to update notes
    public static EDGE_BriefcaseWrapper updateNotes(string feedId, string contentDocId, string textMsg){
        EDGE_BriefcaseWrapper briefcaseWrapper = new EDGE_BriefcaseWrapper();
        string conVersionId = '';

        //Check If ParentId is not Blank
        if(string.isNotEmpty(feedId)){

            if(string.isNotEmpty(contentDocId)){
                //Get ContentVersion Id
                List<ContentVersion> contentVersionList = [select Id, ContentDocumentId from ContentVersion where ContentDocumentId =:contentDocId];
                if(contentVersionList != null && contentVersionList.size()>0){
                    conVersionId = contentVersionList[0].Id;
                    updateContentVerDetails(conVersionId, contentDocId, true);
                }

                //Get Existing ContentDocumentId
                List<FeedItem> feedItems = [Select Id, RelatedRecordId from FeedItem WHERE Id = :feedId];
                if (!feedItems.isEmpty()) {
                    //Check if Mobile Device has send same content or Update Content. In case of updated content delete existing content and link new
                    if(feedItems[0].RelatedRecordId != null && conVersionId != feedItems[0].RelatedRecordId){
                        //Delete Old Content
                        List<ContentDocument> contentDocList = [select id from ContentDocument where LatestPublishedVersionId =:feedItems[0].RelatedRecordId];

                        if(!contentDocList.isEmpty()){
                            delete contentDocList;
                        }
                    }
                }
                
            }

            // Define the FeedItemInput object to pass to postFeedElement
            ConnectApi.FeedItemInput feedItemInput = createFeedItemInput('', contentDocId, textMsg, false);

            // Update the feed item. 
            ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.updateFeedElement(Network.getNetworkId(), feedId, feedItemInput);

            //Get Response that we need to send to Mobile
            briefcaseWrapper = getResponse(feedElement, contentDocId, conVersionId);
        }
        return briefcaseWrapper;
    }

    //This Method is used to create FeedItemInput Instance
    public static ConnectApi.FeedItemInput createFeedItemInput(string parentId, string contentDocId, string textMsg, boolean isCreate){
        // Define the FeedItemInput object to pass to postFeedElement
        ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
        //Only assign subjectId in case of feeditem create
        if(isCreate){
            feedItemInput.subjectId = parentId;
        }

        ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
        textSegmentInput.text = textMsg;

        //The MessageBodyInput object holds the text in the post
        ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
        messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
        messageBodyInput.messageSegments.add(textSegmentInput);
        feedItemInput.body = messageBodyInput;

        //The FeedElementCapabilitiesInput object holds the capabilities of the feed item.
        //For this feed item, we define a files capability to hold the file(s).
        if(string.isNotEmpty(contentDocId)){    
        
            ConnectApi.FilesCapabilityInput filesInput = new ConnectApi.FilesCapabilityInput();
            filesInput.items = new List<ConnectApi.FileIdInput>();

            ConnectApi.FileIdInput idInput = new ConnectApi.FileIdInput();
            idInput.id = contentDocId;
            filesInput.items.add(idInput);

            ConnectApi.FeedElementCapabilitiesInput feedElementCapabilitiesInput = new ConnectApi.FeedElementCapabilitiesInput();
            feedElementCapabilitiesInput.files = filesInput;

            feedItemInput.capabilities = feedElementCapabilitiesInput;
        }

        return feedItemInput;
    }

    //This method is used to create response that we need to send back to mobile
    public static EDGE_BriefcaseWrapper getResponse(ConnectApi.FeedElement feedElement, string contentDocId, string conVersionId){
        EDGE_BriefcaseWrapper briefcaseWrapper = new EDGE_BriefcaseWrapper();

        //Parse feed Body
        ConnectApi.FeedBody feedBody = feedElement.body;

        //Parse Feed Parent Id
        ConnectApi.ActorWithId actorWithId = feedElement.parent;

        //Create Wrapper Instance and return it
        briefcaseWrapper.noteId = feedElement.id;
        briefcaseWrapper.noteBody = feedBody.text;
        briefcaseWrapper.noteCreatedBy = userInfo.getName();
        briefcaseWrapper.noteCreatedById = UserInfo.getUserId();
        briefcaseWrapper.noteCreatedDate = feedElement.createdDate;
        briefcaseWrapper.noteLastModDate = feedElement.modifiedDate;
        briefcaseWrapper.noteParentId = actorWithId.Id;
        briefcaseWrapper.conDocumentId = contentDocId;
        briefcaseWrapper.conVersionId = conVersionId;

        return briefcaseWrapper;
    }
    
    //This method is used to update the Record, Content Type and Library of Content Version
    public static void updateContentVerDetails(Id contentVersionId, Id contentDocumentId, Boolean isInsert){
        
        if(String.isNotBlank(contentVersionId) && String.isNotBlank(contentDocumentId)){
            String libraryName = Label.Notes_Library;
            ContentWorkspace contentWorkSpc = [SELECT Id FROM ContentWorkspace where name = :libraryName LIMIT 1];
            String notesRecordId =  ContentVersion.sObjectType.getDescribe().getRecordTypeInfosByName().get(libraryName).getRecordTypeId();
            ContentVersion objContentVersion = new ContentVersion(Id=contentVersionId,
                                                                  RecordTypeId = notesRecordId,
                                                                  Content_Type__c = libraryName
                                                                 );
            update objContentVersion;
            
            //For update we donot need to create the Workspace as it is already created
            if(isInsert){
                ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
                newWorkspaceDoc.ContentWorkspaceId = contentWorkSpc.Id; 
                newWorkspaceDoc.ContentDocumentId = contentDocumentId;
                insert newWorkspaceDoc;
            }
        }
    }
}