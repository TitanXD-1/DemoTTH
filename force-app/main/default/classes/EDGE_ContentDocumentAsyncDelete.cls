public class EDGE_ContentDocumentAsyncDelete implements Queueable{
    private List<ContentDocument> contentDocDeleteList;

    public EDGE_ContentDocumentAsyncDelete(List<ContentDocument> contentDocDeleteList) {
        this.contentDocDeleteList = contentDocDeleteList;
    }
    
    public void execute(QueueableContext context) {       
        if(contentDocDeleteList!=null && contentDocDeleteList.size()>0){
             Database.delete(contentDocDeleteList,true);
        }
        
        
    }
    

}