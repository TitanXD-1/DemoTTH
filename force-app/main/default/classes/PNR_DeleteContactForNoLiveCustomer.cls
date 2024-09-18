/**********************************************************************
Name: PNR_DeleteContactForNoLiveCustomer
=======================================================================
Req:  
User Story : PION-1408- Contact Deletion for No Live Customer
=======================================================================
Description:
*This batch is to delete contacts and closes the cases of the accounts which are deleted in SAP
*This batch removes the referenced account from the cases which are marked for closing
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Sudipta Nandi       2/3/2020      Initial Development
2.0 	Jayashree R			15/11/2021		Modified
***********************************************************************/
public class PNR_DeleteContactForNoLiveCustomer implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String query = 'SELECT Id,Name,RecordType.Name FROM Account WHERE Deletion_Flag_from_SAP__c = True AND AccountSource = \'SAP - Pioneer\' AND RecordType.Name =\'Direct Customer\' ';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Account> scope){ 
        List<AccountContactRelation> accountIdListCol = new List<AccountContactRelation>();
        List<AccountContactRelation> contactIdListCol = new List<AccountContactRelation>();
        List<Id> accountIdList = new List<Id>();
        List<Id> contactIdList = new List<Id>();
        Map<Id, List<String>> contactMap = new Map<Id, List<String>>();
        List<String> recordTypeListStr = new List<String>();
        List<Id> conIdDelList = new List<Id>();
        List<Id> accConRelDelList = new List<Id>();
        List<AccountContactRelation> accConRelDelFinalList = new List<AccountContactRelation>();
        List<Case> caseListForContact = new List<Case>();
        List<Case> caseListForAccount = new List<Case>();
        
        List<Case> caseListForAccountFinalList = new List<Case>();
        try{  //PION-1611 : Exception handling
            if(!scope.isEmpty()){
                for(Account acc : scope){
                    accountIdList.add(acc.Id); 
                }
                //Fetch Customer Contact 
                if(!accountIdList.isEmpty() && Schema.SObjectType.AccountContactRelation.isAccessible()){
                    accountIdListCol = [SELECT AccountID, ContactId, Account.RecordType.Name
                                        FROM AccountContactRelation
                                        WHERE AccountId IN : accountIdList];
                }
                if(!accountIdListCol.isEmpty()){
                    for(AccountContactRelation accRel : accountIdListCol){
                        contactIdList.add(accRel.ContactId);
                    }
                }
                if(!contactIdList.isEmpty() && Schema.SObjectType.AccountContactRelation.isAccessible()){
                    contactIdListCol = [SELECT Id, AccountID, ContactId, Account.RecordType.Name,Account.Deletion_Flag_from_SAP__c,Account.Products_Enabled__c
                                        FROM AccountContactRelation
                                        WHERE ContactID IN : contactIdList];
                }
                
                if(!contactIdListCol.isEmpty()){
                    for(AccountContactRelation accRel : contactIdListCol){
                        if(accRel.Account.Products_Enabled__c != null && (accRel.Account.Products_Enabled__c.contains(Label.PNR_ProductsEnabledForEdge) 
                                                                          || accRel.Account.Products_Enabled__c.contains(Label.PNR_ProductsEnabledForMyDiageo)
                                                                          || accRel.Account.Products_Enabled__c.contains(Label.PNR_ProductsEnabledForDBA)
                                                                          || accRel.Account.Products_Enabled__c.contains(Label.PNR_ProductsEnabledForDiageoOne)))
                        {
                            accConRelDelList.add(accRel.ContactId);
                        }
                        else{
                            if(!accRel.Account.Deletion_Flag_from_SAP__c){
                                accConRelDelList.add(accRel.ContactId);
                            }
                        }
                        
                    }
                }
                for(Id idCon : contactIdList){
                    if(!accConRelDelList.contains(idCon)){
                        conIdDelList.add(idCon);
                    }
                }
                
                //Change case status to Closed for No Live Customer
                if(Schema.sObjectType.Case.isAccessible()){
                    caseListForAccount = [SELECT Id,AccountId,ContactId,Status,Type,Reference_Order__c,Reference_Invoice__c,Dispute_Breakdown__c,Dispute_Sub_type__c, Sales_Org__c, RecordType.DeveloperName FROM Case WHERE AccountId IN :accountIdList];
                }
                if(!caseListForAccount.isEmpty()){
                    for(Case cse : caseListForAccount){
                        if(cse.Status!='Closed' && cse.Status!='Rejected' ){
                            Case cseUpdate= new Case();
                            cseUpdate.Id=cse.Id;
                            cseUpdate.AccountId = Null;
                            cseUpdate.ContactId = Null;
                            cseUpdate.Reference_Order__c = Null;
                            cseUpdate.Reference_Invoice__c = Null;
                            if(cse.Dispute_Breakdown__c == null || cse.Dispute_Breakdown__c ==''){
                                if(cse.Type =='Dispute – Delivery'){
                                    cseUpdate.Dispute_Breakdown__c ='Damaged Goods';
                                    cseUpdate.Dispute_Sub_type__c ='Damages Haulier/Carrier';
                                }
                                else if(cse.Type =='Dispute – Pricing'){
                                    cseUpdate.Dispute_Breakdown__c ='Discount Issue';
                                    /*PION-1611 : changed dispute sub type from 'Set up too late' to
                                     *'set up late - long term discount' as the value 'Set up too late' was not
									 * included in the field dependency of Dispute breakdown field for 'Discount Issue'
									*/ 
                                    cseUpdate.Dispute_Sub_type__c ='set up late - long term discount';
                                }
                            }
                            if(cse.Dispute_Sub_type__c == null || cse.Dispute_Sub_type__c ==''){
                                if(cse.Type =='Dispute – Delivery'){
                                    cseUpdate.Dispute_Sub_type__c ='Damages Haulier/Carrier';
                                }
                                else if(cse.Type =='Dispute – Pricing'){
                                    /*PION-1611 : changed dispute sub type from 'Set up too late' to
                                     *'set up late - long term discount' as the value 'Set up too late' was not
									 * included in the field dependency of Dispute breakdown field for 'Discount Issue'
									*/
                                    cseUpdate.Dispute_Sub_type__c = 'set up late - long term discount';
                                }
                            }
                            if(cse.Sales_Org__c == null || cse.Sales_Org__c == ''){
                                cseUpdate.Sales_Org__c = 'GB01';
                            }
                            /*PION-1611 : Adding new rejection reason for direct disputes cases as the dispute cases
                             * cannot be closed without rejection reason*/ 
                            if(cse.RecordType.DeveloperName == 'Direct_Disputes'){
                            	cseUpdate.Rejection_Reason__c = 'Account Closed';
                            }
                            cseUpdate.Status ='Closed';
                            caseListForAccountFinalList.Add(cseUpdate);
                        }
                        
                    }
                    if(!caseListForAccountFinalList.isEmpty())
                    {
                    	update caseListForAccountFinalList;
                    }
                }
                /*PION-1611 : commented below code to eliminate duplicate loops and the logic inside this if clause is
                 * moved to the previous block */
                /*if(!caseListForAccountFinalList.isEmpty()){
					for(Case cse : caseListForAccountFinalList){
						if(cse.Status!='Closed' && cse.Status!='Rejected'){
						cse.Status ='Closed';
						}
					}
					update caseListForAccountFinalList;
				}*/
                
                //Delete case-contact relation for the contacts
                if(Schema.sObjectType.Case.isAccessible()){
                    caseListForContact = [SELECT Id,AccountId,ContactId,Status FROM Case WHERE ContactId IN :conIdDelList];
                }
                if(!caseListForContact.isEmpty()){
                    for(Case cse : caseListForContact){
                        cse.ContactId = null;
                    }
                    update caseListForContact;
                }
                
                Database.DeleteResult[] delCon = Database.delete(conIdDelList);
                
            }
        }catch(Exception e){ //PION-1611 : Exception handling
            System.debug('Exception::: '+e.getStackTraceString());
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}