public class EDGE_AsyncContactRemover implements Queueable {
    
    private Id contactId;

    public EDGE_AsyncContactRemover(Id contactId) {
        this.contactId = contactId;
    }
    
    public void execute(QueueableContext context) {       
        deleteContactDetails(this.contactId);
    }
    
    @TestVisible
    private static void deleteContactDetails(Id contactRecordId){
        Contact contactRec;
        List<Contact> conList = [Select Id,Name from Contact where Id = :contactRecordId];
        System.debug(LoggingLevel.Debug,'conList = '+ conList);
        try{
            if(conList != null && conList.size() > 0){
                contactRec = conList[0];
                System.debug(LoggingLevel.Debug,'contactRec = '+ contactRec);
                Database.delete(contactRec);
            }
        }catch(Exception exceptionRec){
                System.debug(LoggingLevel.Debug,'exceptionRec : message = '+ exceptionRec.getMessage());
                System.debug(LoggingLevel.Debug,'exceptionRec : getStackTraceString = '+ exceptionRec.getStackTraceString());
            }
    }
    
}