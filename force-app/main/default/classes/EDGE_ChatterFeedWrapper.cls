/**********************************************************************
Name: EDGE_ChatterFeedWrapper
=======================================================================
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Juned khan		       05/02/2021         ES20-9721
***********************************************************************/

global inherited sharing class EDGE_ChatterFeedWrapper {
    
    public List<ChatterNotes> chatterNotesList{get;set;} 
    
    public String outletId {get;set;}
    
    public class ChatterNotes{
        public Id chatterId{get;set;}
        public String body{get;set;}
        public List<ContentRecord> contentRecords {get;set;}
        public datetime createdDate {get; set;}
        public String createdBy {get;set;}
    }
   
    public class  ContentRecord{
    public Id contentVerId {get;set;}
    public Id contentDocId {get;set;}   
    }
    
    
}