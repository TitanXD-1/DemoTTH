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
@RestResource(urlMapping='/NotesService/*')

global with sharing class EDGE_NotesServiceClass {
    
    @HttpPost
    global static EDGE_BriefcaseWrapper createNotes(string parentId, string contentDocId, string textMsg) {

        // Add your code
        EDGE_BriefcaseWrapper briefcaseWrapper = new EDGE_BriefcaseWrapper();
        briefcaseWrapper = EDGE_NotesServiceHelperClass.createNotes(parentId, contentDocId, textMsg);

        return briefcaseWrapper;
    }
}