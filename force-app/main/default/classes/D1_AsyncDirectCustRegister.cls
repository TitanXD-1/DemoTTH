/**
 * @Name: D1_AsyncDirectCustRegister
 * @Discription : AsyncDirectCustRegister Queueable Class for asynchronous call.
 * 
 * History
 * --
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0        Sudipta Nandi    11/10/2020   
 **/
public class D1_AsyncDirectCustRegister implements Queueable {
    public List<String> contactIdCol;
    /**
     * @description parameterized constructor
     * @param values 
     */    
    public D1_AsyncDirectCustRegister(List<String> values) {
        this.contactIdCol = values;
    }
    /**
     * @description 
     * @param context 
     */    
    public void execute(QueueableContext context) {
        //Calling directCustomerCheck method for validation and create User
        D1_RegistrationDirectCustomerController.processBulkRegistration(contactIdCol);
        
    }
}