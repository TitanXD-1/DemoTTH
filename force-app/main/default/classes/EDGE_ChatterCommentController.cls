/**********************************************************************
Name: EDGE_ChatterCommentController
=======================================================================
Req: 
ES20-9878
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR              DATE            DETAIL
1.0       Divya              10/03/2021      Initial Development
***********************************************************************/

public without sharing class EDGE_ChatterCommentController {
    
    /*******************************************************************
Purpose: To fetch chatter comments under a particular chatter based on the Feed Id/Chatter Id                                                      
********************************************************************/
    
        public static EDGE_ChatterCommentWrapper getChatterComment(Id feedId){ 
        EDGE_ChatterCommentWrapper chatCommentWrap = new EDGE_ChatterCommentWrapper();
        List<EDGE_ChatterCommentWrapper.ChatterComments> chatterCommentsList =new List<EDGE_ChatterCommentWrapper.ChatterComments>();
        Map<Id,FeedComment> feedCommentIdRecordMap = new Map<Id,FeedComment>();
        List<FeedComment> feedCommentList=new List<FeedComment>();
      
         String queryString='SELECT CommentBody,CreatedBy.Name,CreatedDate,Id,ParentId,FeedItemId,IsRichText FROM FeedComment WHERE FeedItemId =:feedId ';
         		queryString += ' Order by CreatedDate desc ';
                
        if(Schema.sObjectType.FeedComment.isAccessible() ){
            for(FeedComment feedComment :Database.query(queryString)){
                if(feedComment.Id != null && feedComment.ParentId != null){
                    feedCommentList.add(feedComment);   
                }
                feedCommentIdRecordMap.put(feedComment.Id, feedComment);
            }
  
        }
        if(feedCommentIdRecordMap != null){
            for(Id feedRecId : feedCommentIdRecordMap.keySet()){
                FeedComment feedCommentsRec = feedCommentIdRecordMap.get(feedRecId);
                if(feedCommentsRec != null){
                    EDGE_ChatterCommentWrapper.ChatterComments chatterComment = new EDGE_ChatterCommentWrapper.ChatterComments();
                    chatterComment.commentId=feedCommentsRec.Id;
                    chatterComment.body=feedCommentsRec.CommentBody;
                    chatterComment.createdDate=feedCommentsRec.CreatedDate;
                    chatterComment.createdBy=feedCommentsRec.CreatedBy.Name; 
                    chatterCommentsList.add(chatterComment);
                    System.debug('chatterCommentsList = '+ chatterCommentsList);
                    chatCommentWrap.chatterCommentsList = chatterCommentsList;   
                    chatCommentWrap.outletId = feedCommentsRec.ParentId ;
                   
                }
            }
        }
        return chatCommentWrap;
        
    }
}