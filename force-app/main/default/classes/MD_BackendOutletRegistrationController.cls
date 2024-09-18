public class MD_BackendOutletRegistrationController {
    
    @AuraEnabled 
    public static DiageoCMS.FormResponseWrapper validateAccount(Id accId){
        DiageoCMS.FormResponseWrapper response = new  DiageoCMS.FormResponseWrapper();
        Account acc = [SELECT Id, Operator__r.Country_Code__c, Country_Code__c, Global_Channel__c
                            , IsIndependent__c, Independent_of_Operator__c, Operator__r.Global_Channel__c, VAT_Number__c, Operator__r.VAT_Number__c 
                       FROM Account WHERE Id =: accId];
        //Independent_of_Operator__c
        
        if ((acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true) ? acc.Country_Code__c != 'ES' : acc.Operator__r.Country_Code__c != 'ES'){
            response.status = 'failed';
            response.message = 'Country Validation';
            return response;
        }
        if ((acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true) ? acc.Global_Channel__c != 'On Trade' : acc.Operator__r.Global_Channel__c != 'On Trade'){
            response.status = 'failed';
            response.message = 'Channel Validation';
            return response;
        }
        
        String vatNumber;
        
        if(acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true) {
            vatNumber = acc.VAT_Number__c;
        }else {
            if(acc.Operator__r != null) {
               vatNumber = acc.Operator__r.VAT_Number__c;
            }
        }
         
        String recordType = (acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true) ? 'Outlet' : 'Owner';      
        
        String query = '';
        query += 'SELECT Id FROM Account ';
        query += 'WHERE VAT_Number__c =: vatNumber ';
        query += 'AND RecordType.DeveloperName =: recordType';
        
        List<Account> accs = Database.query(query);
        
        if (accs.size() == 0 || accs.size()>1){
            response.status = 'failed';
            response.message = 'VAT Validation';
        }
        
        response.status = 'success';
        return response;
    }
    
    @AuraEnabled
    public static List<AccountContactRelation> getCustomerContacts(Id accId){
        DiageoCMS.FormResponseWrapper response = new  DiageoCMS.FormResponseWrapper();
        return [SELECT Id, ContactId, Contact.Name, Contact.Email, Contact.Phone FROM AccountContactRelation WHERE AccountId =: accId];
        
        
    }
    
    @AuraEnabled
    public static List<Contact> getContacts(String search, String whereCondition){
        String query = '';
        query += 'SELECT Id, Account.Name, Name, Email, Phone ';
        query += 'FROM Contact ';
        query += 'WHERE '+ whereCondition +' LIKE \'%'+search+'%\'';
        return Database.query(query);
    }
    
    @AuraEnabled
    public static DiageoCMS.FormResponseWrapper registerContactToAccount(Id accountId, Id contactId){
        DiageoCMS.FormResponseWrapper response = new  DiageoCMS.FormResponseWrapper();
        
        //Key: contactId, Value: set of accountId
        Map<Id,Set<Id>> mapInput = new Map<Id,Set<Id>>();
        mapInput.put(contactId, new Set<Id>{accountId});
        
        String countryCode = [SELECT Id, Country__r.Code__c FROM Account WHERE Id =: accountId].Country__r.Code__c;
        
        Map<Id,Map<Id,String>> resultsMap = MD_RegistrationUtil.registerContacts(mapInput, countryCode, false, false, 'MyDiageo', 'Backend', 'Primary User');        
        
        response.status =  resultsMap.get(contactId).get(accountId) == 'Success' ? 'success' : 'failed';
        response.message =  resultsMap.get(contactId).get(accountId) == 'Success' ? '' :  resultsMap.get(contactId).get(accountId);
        
        return response;
        
    }
}