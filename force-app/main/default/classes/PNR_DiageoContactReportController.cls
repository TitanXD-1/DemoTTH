/****************************************************************************
  Name: PNR_DiageoContactReportController
=============================================================================
  Purpose: This is the Controller class for PNR_DiageoContactReportController
=============================================================================
    History                                                            
-----------------------------------------------------------------------------                                                            
    VERSION    AUTHOR              DATE              DETAIL
    1.0        Jyothsna Nagapudi   26-08-2019        Initial Development
	2.0			Tanmoy Bardhan	   28-08-2019		 Modified
****************************************************************************/
public with sharing class PNR_DiageoContactReportController {
     /***********************************************************
     * Name : fetchDiageoContact
     * Description : This method is used to fetch diageo contact
    *************************************************************/
    @AuraEnabled
    public static List<wrapperClass> fetchDiageoContact(String saleOrg) {
        List<PNR_Diageo_Contact__c> diageoContactList = new List<PNR_Diageo_Contact__c>();
        List<PNR_Diageo_Contact__c> finaldiageoContactList = new List<PNR_Diageo_Contact__c>();
        List<Account> accountList = new List<Account>();
        List<wrapperClass> wrapList = new List<wrapperClass>();
        wrapperClass wrapObj;
        
        List<PNR_Partner_Function__c> pfList = new List<PNR_Partner_Function__c>();
        Set<Id> customerSet = new Set<Id>();

        //This methd is for getting diageo contacts for customer based on sales org.
        if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
                pfList = [SELECT Id, PNR_Customer_No__c, PNR_Deletion_Flag_for_Sales_Level__c, PNR_Sales_Org__c, 
                          PNR_Customer_No__r.Deletion_Flag_from_SAP__c  
                          FROM PNR_Partner_Function__c 
                          WHERE PNR_Sales_Org__c = :saleOrg AND PNR_Customer_No__r.Deletion_Flag_from_SAP__c = FALSE 
                          AND PNR_Deletion_Flag_for_Sales_Level__c = FALSE];
                              
        }
        for(PNR_Partner_Function__c customer : pfList) {
        	customerSet.add(customer.PNR_Customer_No__c);    
        }
        
        if(Schema.sObjectType.Account.isAccessible()){
            accountList = [SELECT Id, Name, AccountNumber FROM Account WHERE Id IN :customerSet];
        }
        
        
        if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
                diageoContactList = [SELECT Id, PNR_Contact_Type__c, PNR_Customer__c, PNR_Diageo_Rep__c, PNR_Name__c,
                                     PNR_Customer__r.Name,PNR_Customer__r.AccountNumber, 
                                     PNR_Diageo_Rep__r.Name
                              		 FROM PNR_Diageo_Contact__c
                                     WHERE PNR_Customer__c IN :customerSet];
                              
        }
        for(Account accountObj : accountList) {
            Boolean isServiceRepAvailable = false;
            Boolean isCreditControllerAvailable = false;
            Boolean isAccountMangerAvailable = false;
            for(PNR_Diageo_Contact__c diageoContact : diageoContactList) {
                if(diageoContact.PNR_Customer__c == accountObj.Id) {
                    wrapObj = new wrapperClass();
                    if(diageoContact.PNR_Contact_Type__c == 'Customer Service Rep'){
                     	isServiceRepAvailable = true;
                        //finaldiageoContactList.add(diageoContact);
						wrapObj.salesOrg = saleOrg;
                        wrapObj.customerName = accountObj.Name;
                        wrapObj.customerNumber = accountObj.AccountNumber;
                        wrapObj.contactType = 'Customer Service Rep';
                        wrapObj.contactName = diageoContact.PNR_Diageo_Rep__r.Name;
                        wrapList.add(wrapObj);
                    }
                    else if(diageoContact.PNR_Contact_Type__c == 'Credit Controller'){
                        isCreditControllerAvailable = true;
                        //finaldiageoContactList.add(diageoContact);
                        wrapObj.salesOrg = saleOrg;
                        wrapObj.customerName = accountObj.Name;
                        wrapObj.customerNumber = accountObj.AccountNumber;
                        wrapObj.contactType = 'Credit Controller';
                        wrapObj.contactName = diageoContact.PNR_Diageo_Rep__r.Name;
                        wrapList.add(wrapObj);
                    }
                    else if(diageoContact.PNR_Contact_Type__c == 'Account Manager'){
                        isAccountMangerAvailable = true;
                        //finaldiageoContactList.add(diageoContact);
                        wrapObj.salesOrg = saleOrg;
                        wrapObj.customerName = accountObj.Name;
                        wrapObj.customerNumber = accountObj.AccountNumber;
                        wrapObj.contactType = 'Account Manager';
                        wrapObj.contactName = diageoContact.PNR_Name__c;
                        wrapList.add(wrapObj);
                    }
                } 
             }

            if(!isServiceRepAvailable) {
                //PNR_Diageo_Contact__c emptyServiceRep = new PNR_Diageo_Contact__c();
                wrapObj = new wrapperClass();
                wrapObj.salesOrg = saleOrg;
                wrapObj.customerName = accountObj.Name;
                wrapObj.customerNumber = accountObj.AccountNumber;
                wrapObj.contactType = 'Customer Service Rep';
                wrapObj.contactName = '';
                wrapList.add(wrapObj);
            }if(!isCreditControllerAvailable){
                wrapObj = new wrapperClass();
                wrapObj.salesOrg = saleOrg;
                wrapObj.customerName = accountObj.Name;
                wrapObj.customerNumber = accountObj.AccountNumber;
                wrapObj.contactType = 'Credit Controller';
                wrapObj.contactName = '';
                wrapList.add(wrapObj);
            }if(!isAccountMangerAvailable){
                wrapObj = new wrapperClass();
                wrapObj.salesOrg = saleOrg;
                wrapObj.customerName = accountObj.Name;
                wrapObj.customerNumber = accountObj.AccountNumber;
                wrapObj.contactType = 'Account Manager';
                wrapObj.contactName = '';
                wrapList.add(wrapObj);
            }
        }
        return wrapList;
        
    }
    
    @AuraEnabled
    public static List<String> fetchSalesOrgs(){
        List<String> salesOrgMdtList = new List<String>();
        List<PNR_SalesOrgs__mdt> salesOrgList =new List<PNR_SalesOrgs__mdt>();
        if(Schema.sObjectType.PNR_SalesOrgs__mdt.isAccessible()){
        salesOrgList = [SELECT PNR_Sales_Org__c FROM PNR_SalesOrgs__mdt ORDER BY PNR_Sales_Org__c];
        }
        for(PNR_SalesOrgs__mdt mdtObj : salesOrgList){
            salesOrgMdtList.add(mdtObj.PNR_Sales_Org__c);
        }
        return salesOrgMdtList;
    }
    
    public class wrapperClass{
        @AuraEnabled public String salesOrg {get;set;}
        @AuraEnabled public String customerName {get;set;}
        @AuraEnabled public String customerNumber {get;set;}
        @AuraEnabled public String contactType {get;set;}
        @AuraEnabled public String contactName {get;set;}
    }
    

}