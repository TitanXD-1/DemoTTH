/**
 * @ Name: EDGE_getOrderProducts 
 * @ Req: 
 * @ ES20-4623 - VF Template class for Shed Movement Approval Process
 * @ ES20-10737- made changes to template to display url of record and reason in order item table
 * */

public class EDGE_getOrderProducts {
    
    public ID targetObjectId { get; set; }
   
    
    public List<Order_Item__c> getOrderProductItems() {
        List<Order_Item__c> orderItems;

        orderItems= [SELECT Name, Product__r.Name, Quantity__c,Reported_Reason__c FROM Order_Item__c WHERE Order__c = :targetObjectId];

        return orderItems; 
        
    }   
    
  public List<Order__c> getOrderDetails()
    {
        List<Order__c> orderObj;

        orderObj= [SELECT Id, Name, CreatedDate,Sales_Representative__r.Name FROM Order__c WHERE id=: targetObjectId ];

        return orderObj;
    }
 
/** 
 * @ Name : getRecordUrl()
 * @ Description : This method is added to send url of order record which is sent for approval process to manager ES20-10737
 * */    
    
    public string getRecordUrl(){
        String myDomainUrl = URL.getSalesforceBaseUrl().getHost();
        String reqRecordUrl = 'https://' + myDomainUrl + '/' + targetObjectId;
        return reqRecordUrl;
    }
    
}