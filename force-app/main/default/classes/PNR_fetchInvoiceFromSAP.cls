/**********************************************************************
Name: PNR_fetchInvoiceFromSAP
=======================================================================
Req:  
User Story : PION-875-Reference invoice to be fetched from SAP when creating a dispute - header data
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Tanmoy Bardhan       19/09/2019      Initial Development
1.1		Saurav Paul			22/10/2019		getSAPData
1.2		Saurav Paul			13/03/2020		getInvoiceDetl
***********************************************************************/
public class PNR_fetchInvoiceFromSAP {
	/*******************************************************************
    Method  : getInvoiceList
    Purpose : This method is used to get the Invoice list.
    ***********************************************************************/
    @AuraEnabled
    public static List<Invoice_Line_Item__c> getInvoiceList(String Invoice,String orgName) {
        //List<Invoice__c> invoicelist= new List<Invoice__c>();
        List<Invoice_Line_Item__c> invoiceLineItemList = new List<Invoice_Line_Item__c>();
        
        if(Invoice != null && (String.isNotBlank(Invoice)) && Schema.SObjectType.Invoice__c.isAccessible() 
           && Schema.SObjectType.Account.isAccessible() && Schema.SObjectType.Order__c.isAccessible()
           && Schema.SObjectType.Invoice_Line_Item__c.isAccessible()){
               invoiceLineItemList = [SELECT Id, Name
                                      FROM Invoice_Line_Item__c
                                      WHERE Invoice__r.SAP_Invoice_Number__c = :Invoice
                                      AND Invoice__r.Sales_Org__c = :orgName and (Invoice__r.Due_Type__c !='cancelled' AND Invoice__r.Document_Type__c ='YF2')];//PION-1985
           }
        return invoiceLineItemList;
    }
    /*******************************************************************
    Method  : getSAPData
    Purpose : This method is used to get SAP Data.
    ***********************************************************************/
    @AuraEnabled
    public static String getSAPData(String orgName,String invNumber){
        /*
        list<Invoice__c> invList = [select id from Invoice__c where  SAP_Invoice_Number__c =: invNumber 
                                    and Sales_Org__c =:orgName and (Due_Type__c ='cancelled' or Document_Type__c !='YF2')];//PION-1985
        if(invList.size()>0){//PION-1985
          return  Label.Invalid_Invoice_Type;
        }*///SAI COMMENT
        String msg = PNR_CustomerDetailSearch.sendReq(orgName,null,null,null,invNumber);
        return msg;
    }
    
    @AuraEnabled
    public static void updateCaseRecord(String recordId, String Invoice, String orgName){
		List<Invoice__c> invoicelist = new List<Invoice__c>();
		if(Schema.SObjectType.Invoice__c.isAccessible()){
		    invoicelist = [SELECT Id, SAP_Invoice_Number__c
                       FROM Invoice__c
                       WHERE SAP_Invoice_Number__c = :Invoice
                       AND Sales_Org__c = :orgName];
		}
        
        if(!invoicelist.isEmpty()){
            Case cse = new Case();
            cse.Id = recordId;
            cse.Reference_Invoice__c = invoicelist[0].Id;
            cse.Sales_Org__c = orgName;
            Database.SaveResult saveRslt = Database.update(cse, false);
        }
    }
    //Developed for PION-1348
    @AuraEnabled
    public static InvDetl getInvoiceDetl(String recordId){
        List<Case> caseLst = new List<Case>();
        caseLst = [SELECT Sales_Org__c, Reference_Invoice__c, Reference_Invoice__r.SAP_Invoice_Number__c 
                  FROM Case
                  WHERE Id =: recordId];
        InvDetl inDtlObj = new InvDetl(caseLst[0]);
        return inDtlObj;
    }
    //Developed for PION-1348
    public class InvDetl{
        @AuraEnabled
        public String slsOrg{get;set;}
        @AuraEnabled
        public String invNumber{get;set;}
        InvDetl(case caseObj){
        	this.slsOrg = caseObj.Sales_Org__c;
          	this.invNumber = caseObj.Reference_Invoice__r.SAP_Invoice_Number__c;
        }
    }
}