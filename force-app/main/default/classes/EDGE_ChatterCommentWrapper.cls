/**********************************************************************
Name: EDGE_ChatterCommentWrapper
=======================================================================
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Divya		            10/03/2021        ES20-9878
***********************************************************************/
global without sharing class EDGE_ChatterCommentWrapper {
    
    public List<ChatterComments> chatterCommentsList{get;set;}    
    
    public Id outletId {get;set;}
    

    public class ChatterComments{
        public Id commentId{get;set;}
        public String body{get;set;}
        public datetime createdDate{get; set;}
        public String createdBy{get;set;}
       
        
    }

}