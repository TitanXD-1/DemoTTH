/**********************************************************************
Name: PNR_deleteContactBatch
=======================================================================
Req:  
User Story : PION-806- Old Contact Deletion
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0    Tanmoy Bardhan       21/10/2019      Initial Development
2.0    Tanmoy Bardhan       31/10/2019      Modified
***********************************************************************/
public class PNR_deleteContactBatch implements Database.Batchable<sObject>{
    public Database.QueryLocator start(Database.BatchableContext BC){
        String deleteContact = '%deleted%';
        String query = 'SELECT Id,Name,Account.RecordType.Name FROM Contact WHERE Name LIKE \'' + deleteContact+ '\' ';
        return Database.getQueryLocator(query);
    }
    
    public void execute(Database.BatchableContext BC, List<Contact> scope){
        List<AccountContactRelation> accountIdList = new List<AccountContactRelation>();
        List<Id> contactIdList = new List<Id>();
        Map<Id, List<String>> contactMap = new Map<Id, List<String>>();
        List<String> recordTypeListStr = new List<String>();
        List<Id> conIdDelList = new List<Id>();
        List<Id> accConRelDelList = new List<Id>();
        List<AccountContactRelation> accConRelDelFinalList = new List<AccountContactRelation>();
            
        if(!scope.isEmpty()){
            for(Contact con : scope){
               contactIdList.add(con.Id); 
            }
            
                             
            if(!contactIdList.isEmpty() && Schema.SObjectType.AccountContactRelation.isAccessible()){
                 accountIdList = [SELECT Id, AccountID, ContactId, Account.RecordType.Name
                                 FROM AccountContactRelation
                                 WHERE ContactID IN : contactIdList];
            }
            
            
            if(!accountIdList.isEmpty()){
                for(AccountContactRelation accRel : accountIdList){

                    if(!contactMap.containsKey(accRel.ContactId)){
                        contactMap.put(accRel.ContactId,new List<String>{accRel.Account.RecordType.Name});
                    }else{
                        contactMap.get(accRel.ContactId).add(accRel.Account.RecordType.Name);
                    }
                    
                }
            }
            
            for(Id idCon : contactIdList){
                recordTypeListStr = contactMap.get(idCon);
                Boolean flag = false;
                for(String str : recordTypeListStr){
                    if(str != 'Direct Customer'){
                        accConRelDelList.add(idCon);
                        flag = true;
                        break;
                    }
                }
                if(!flag){
                    conIdDelList.add(idCon);
                }
            }
            
            accConRelDelFinalList = [SELECT ID FROM AccountContactRelation
                                     WHERE ContactID IN :accConRelDelList
                                     AND Account.RecordType.Name = 'Direct Customer'];
            
            Database.DeleteResult[] delaccConRel = Database.delete(accConRelDelFinalList);
            Database.DeleteResult[] delCon = Database.delete(conIdDelList);
        }
        
    }
    
    public void finish(Database.BatchableContext BC){
        
    }
}