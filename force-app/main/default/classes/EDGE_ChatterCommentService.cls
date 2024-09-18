/**********************************************************************
Name: EDGE_ChatterCommentService
================================================================================
Req: The requirement is to build Custom API for mobile to get  Chatter comments based on the Feed Id/Comment Id.
User Story : ES20-9878
================================================================================
History                                                            
-------                                                            
VERSION   AUTHOR                DATE              DETAIL
1.0       Divya	                 10/03/2021           
***********************************************************************/

@RestResource(urlMapping='/ChatterCommentService/*')
global without sharing class EDGE_ChatterCommentService{
    @HttpGet
    global static EDGE_ChatterCommentWrapper doGet(){
     Id feedId = Restcontext.request.params.get('feedid');   
     EDGE_ChatterCommentWrapper chatterCommentWrap = new EDGE_ChatterCommentWrapper();
        if(feedId!=null){ 
            chatterCommentWrap = EDGE_ChatterCommentController.getChatterComment(feedId); 
          }  
        
        return chatterCommentWrap;

        }
        
}