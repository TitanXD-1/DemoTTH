/**********************************************************************
Name: EDGE_NotesHistoryService
================================================================================
Req: The requirement is to build Custom API for mobile to get Notes History Data
User Story : ES20-927
================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                DATE              DETAIL
1.0       Monalisa Halder       17/04/2019           
***********************************************************************/

@RestResource(urlMapping='/NotesHistoryService/*')
global without sharing class EDGE_NotesHistoryService{

    @HttpGet
    global static List<EDGE_BriefcaseWrapper> doGet() {
        Id userId = RestContext.request.params.get('userid');
        
        List<EDGE_BriefcaseWrapper> briefCaseWrapList = new List<EDGE_BriefcaseWrapper>();
        if(userId != null){
            briefCaseWrapList = EDGE_BriefcaseController.getNotesHistory(userId);
        }  
        return briefCaseWrapList;
    }
    
    
}