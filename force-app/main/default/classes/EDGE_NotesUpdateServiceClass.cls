/**********************************************************************
Name: EDGE_NotesUpdateServiceClass
======================================================================================
Req: The requirement is to build Custom API for mobile to update FeedItem.
User Story : ES20-
=======================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                DATE              DETAIL
1.0       Kapil Baliyan         18/04/2019        ES20-
***********************************************************************/
@RestResource(urlMapping='/NotesUpdateService/*')

global with sharing class EDGE_NotesUpdateServiceClass {
    
    @HttpPost
    global static EDGE_BriefcaseWrapper updateNotes(string feedId, string contentDocId, string textMsg) {

        // Add your code
        EDGE_BriefcaseWrapper briefcaseWrapper = new EDGE_BriefcaseWrapper();
        briefcaseWrapper = EDGE_NotesServiceHelperClass.updateNotes(feedId, contentDocId, textMsg);

        return briefcaseWrapper;
    }
}