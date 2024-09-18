/**
* @description EDGE_AsyncReturnBeerProcess class for Processing Request in Asynchronous way
* @history
1.0        Sudipta Nandi     08/16/20201       Initial Development

*/
public class EDGE_AsyncReturnBeerProcess implements Queueable, Database.AllowsCallouts {
    public List<String> retrunBeerTagIdCol;
    final static String SAP_Failure_Status = 'SAP Failure';
    final static String Salesforce_Failure_Status = 'Salesforce Failure';
   
    //parameterized constructor
    public EDGE_AsyncReturnBeerProcess(List<String> values) {
        this.retrunBeerTagIdCol = values;
    }
    public void execute(QueueableContext context) {
        list<Return_Beer_Tag__c> returnBeerTagsList =  new list<Return_Beer_Tag__c>();
        
        //Calling directCustomerCheck method for validation and create User
       if(retrunBeerTagIdCol != null && !retrunBeerTagIdCol.isEmpty()){
            EDGE_ReturnBeerTagStatusSendHandler returnBeerHandler = new EDGE_ReturnBeerTagStatusSendHandler();
            set<string> retrunBeerTagIdSet = new set<string>(retrunBeerTagIdCol);
            returnBeerTagsList = [SELECT ID,Status__c,Tag_Number__c,Keg_number__c,Reason_Category__c,Reason_Category__r.Reason_Category_Name__c,Reason_Code__c,Reason_Code__r.Reason_Code_Name__c,Volume__c,
                                  Sample_Taken__c,Broached_Keg__c,Product__r.Product__r.UPIID__c,Product__r.Product__r.SAP_SKU_Code__c,Product__r.Product_UPI__c,
           						  CreatedDate,Case_Task__r.Account__c FROM Return_Beer_Tag__c WHERE Id IN :retrunBeerTagIdSet AND (Status__c =:SAP_Failure_Status OR Status__c =:Salesforce_Failure_Status)];
           if(returnBeerTagsList != null && returnBeerTagsList.Size()>0){
               returnBeerHandler.sendTagsDetails(returnBeerTagsList);
            }        
       }
    }
}