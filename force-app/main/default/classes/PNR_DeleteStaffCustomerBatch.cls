/**********************************************************************
Name: PNR_DeleteStaffCustomerBatch
=======================================================================
Req:  
User Story : PION-964- Staff Customer Deletion
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Sudipta Nandi       28/10/2019      Initial Development
***********************************************************************/
public class PNR_DeleteStaffCustomerBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,Name,RecordType.Name FROM Account WHERE Sort__c = \'staff\'';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope){
        System.debug('scope account==>' + scope);
        List<AccountContactRelation> accountContactList = new List<AccountContactRelation>();
        List<Order__c> openOrders = new List<Order__c>();
        List<Invoice__c> invoiceList = new List<Invoice__c>();
        List<PNR_Diageo_Contact__c> diageoContact = new List<PNR_Diageo_Contact__c>();
        List<PNR_Partner_Function__c> partnerFunctionList = new List<PNR_Partner_Function__c>();
        List<Case> caseList = new List<Case>();
        List<Case> caseListForContact = new List<Case>();
        List<Id> accountIdList = new List<Id>();
        List<Id> conIdDelList = new List<Id>();
        
        if(!scope.isEmpty()){
            for(Account acc : scope){
                accountIdList.add(acc.Id); 
            }
            //Customer Contact Deletion
            if(!accountIdList.isEmpty() && Schema.SObjectType.AccountContactRelation.isAccessible()){
                accountContactList = [SELECT AccountID, ContactId, Account.RecordType.Name
                                      FROM AccountContactRelation
                                      WHERE AccountId IN : accountIdList];
            }
            if(!accountContactList.isEmpty()){
                for(AccountContactRelation accRel : accountContactList){
                    conIdDelList.add(accRel.ContactId);
                }
                //Delete associated Case for the contacts
                if(Schema.sObjectType.Case.isAccessible()){
                    caseListForContact = [SELECT Id FROM Case WHERE ContactId IN :conIdDelList];
                }
                if(!caseListForContact.isEmpty()){
                    Database.DeleteResult[] delCaseforContact = Database.delete(caseListForContact);
                    for (Database.DeleteResult sr : delCaseforContact) {
                        if (sr.isSuccess()) {
                            
                        }
                        else {
                            for(Database.Error err : sr.getErrors()) {
                                System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                            }
                        }
                    }
                }
            }
           
            if(!conIdDelList.isEmpty()){
            	Database.DeleteResult[] delCon = Database.delete(conIdDelList);
            }
            
            //Diageo Contact Deletion
            if(Schema.sObjectType.PNR_Diageo_Contact__c.isAccessible()){
                diageoContact = [SELECT Id,PNR_Customer__c
                              FROM PNR_Diageo_Contact__c
                              WHERE PNR_Customer__c IN :accountIdList];
            }
            
            if(!diageoContact.isEmpty()){
                Database.DeleteResult[] delDiageoCont = Database.delete(diageoContact);
                for (Database.DeleteResult sr : delDiageoCont) {
                    if (sr.isSuccess()) {
                        
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
            
            //Orders Deletion
            if(Schema.sObjectType.Order__c.isAccessible()){
                openOrders = [SELECT Id 
                              FROM Order__c
                              WHERE Account__c IN :accountIdList OR Payer_Number__c IN :accountIdList ];
            }
            if(!openOrders.isEmpty()){
                Database.DeleteResult[] delOrd = Database.delete(openOrders);
                for (Database.DeleteResult sr : delOrd) {
                    if (sr.isSuccess()) {
                        
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
            
            //Invoice Deletion
            if(Schema.sObjectType.Invoice__c.isAccessible()){
                invoiceList = [SELECT Id 
                               FROM Invoice__c
                               WHERE Account__c IN :accountIdList OR Payer_Number__c IN :accountIdList];
            }
            
            if(!invoiceList.isEmpty()){
                Database.DeleteResult[] delInv = Database.delete(invoiceList);
                for (Database.DeleteResult sr : delInv) {
                    if (sr.isSuccess()) {
                        
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
            
            //Partner Functione Deletion
            if(Schema.sObjectType.PNR_Partner_Function__c.isAccessible()){
                partnerFunctionList = [SELECT Id 
                                       FROM PNR_Partner_Function__c
                                       WHERE PNR_Customer_No__c IN :accountIdList];
            }
            if(!partnerFunctionList.isEmpty()){
                Database.DeleteResult[] delPart = Database.delete(partnerFunctionList);
                for (Database.DeleteResult sr : delPart) {
                    if (sr.isSuccess()) {
                        
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
            
            //Associated Case Deletion
            if(Schema.sObjectType.Case.isAccessible()){
                caseList = [SELECT Id FROM Case WHERE AccountId IN :accountIdList];
            }
            if(!caseList.isEmpty()){
                Database.DeleteResult[] delCase = Database.delete(caseList);
                for (Database.DeleteResult sr : delCase) {
                    if (sr.isSuccess()) {
                        
                    }
                    else {
                        for(Database.Error err : sr.getErrors()) {
                            System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                        }
                    }
                }
            }
            
            Database.DeleteResult[] delAccount = Database.delete(scope);
            for (Database.DeleteResult sr : delAccount) {
                if (sr.isSuccess()) {
                    
                }
                else {
                    for(Database.Error err : sr.getErrors()) {
                        System.debug('Error message ===>'+ err.getStatusCode() + ': ' + err.getMessage());
                    }
                }
            }
            
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}