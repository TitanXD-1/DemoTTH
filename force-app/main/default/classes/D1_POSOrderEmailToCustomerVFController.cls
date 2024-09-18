public class D1_POSOrderEmailToCustomerVFController {
    public String orderId;
    public Order__c orderRecord     {get;set;}
    public String bodyHeader        {get;set;}
    public String bodyText1         {get;set;}
    
    public void setOrderId (String orderId) {
        this.orderId = orderId;
        If( String.isNotBlank(this.orderId) ){
            orderRecord = [Select Id,Name, toLabel(Request_Type__c), toLabel(Status__c), 
                     D1_Settings_Contact_Us_Email__c, D1_Settings_Contact_Us_Phone__c, D1_Contact_First_Name__c,
                     CreatedBy.LanguageLocaleKey
                     from Order__c
                     where Id = :orderId limit 1];

            bodyHeader = Label.D1_Pos_Email_Body_Header;
            bodyHeader = bodyHeader.replace('{0}', (orderRecord.Request_Type__c != NULL? orderRecord.Request_Type__c:''));
            bodyHeader = bodyHeader.replace('{1}', (orderRecord.Status__c != NULL? orderRecord.Status__c:''));

            bodyText1 = Label.D1_Pos_Request_Email_Body;
            bodyText1 = bodyText1.replace('{0}', (orderRecord.Request_Type__c != NULL? orderRecord.Request_Type__c:''));
            bodyText1 = bodyText1.replace('{1}', (orderRecord.Status__c != NULL? orderRecord.Status__c:''));
        }
    }
    
    public String getOrderId() {
        return orderId;
    }
}