/**
 * @name D1_UserTriggerHelper
 * @description User Trigger Helper for DiageoOne
 * @history                                                                                                                        
 * VERSION   AUTHOR            DATE              DETAIL

**/

public without sharing class D1_UserTriggerHelper {
    /**
     * @description updateCurrency
     * @param newUsers 
     */        
    public static void updateCurrency(List<User> newUsers){
        Id profId = [SELECT Id,name FROM Profile WHERE Name = 'DiageoOne External User'].Id;
        Set<Id> accountIds =  new Set<Id>();
        Set<Id> contactIds =  new Set<Id>();
       
        Set<Id> partnerFunctionSoldToIds = new Set<Id>();
        
        Map<Id,String> mapPFSoldToIdCurrency = new Map<Id,String>();
        if(!newUsers.isEmpty()){
            for(User user : newUsers){
                if(user.ProfileId == profId){
                    user.CurrencyIsoCode = user.DefaultCurrencyIsoCode;
                    contactIds.add(user.contactId);
                }
            }
            
            map<Id,Id> mapContactIdToAccountId = new map<Id,Id>();
            if(!contactIds.isEmpty()) {
                for(Contact contactObj : [select AccountId from contact where Id IN : contactIds]) {
                    accountIds.add(contactObj.AccountId);
                    mapContactIdToAccountId.put(contactObj.Id,contactObj.AccountId);
                }
            }
            
            if(!accountIds.isEmpty()){
                for(PNR_Partner_Function__c partnerFunctionObj : [select CurrencyIsoCode,PNR_Sold_To__c
                                                                    from PNR_Partner_Function__c where PNR_Type__c Like 'Sold-To' and
                                                                    D1_EDGE_Customer__c = true and 
                                                                    PNR_Sold_To__r.D1_EDGE_Customer__c= true and
                                                                    PNR_Sold_To__c IN : accountIds]) {
                    partnerFunctionSoldToIds.add(partnerFunctionObj.PNR_Sold_To__c);                    
                    mapPFSoldToIdCurrency.put(partnerFunctionObj.PNR_Sold_To__c,partnerFunctionObj.CurrencyIsoCode);                                                            
                }
            }

            
            if(mapPFSoldToIdCurrency !=null && !mapPFSoldToIdCurrency.isEmpty()){
                for(User userObj : newUsers){
                    userObj.CurrencyIsoCode = userObj.DefaultCurrencyIsoCode;
                    if(userObj.contactId != NULL && mapContactIdToAccountId != NULL && mapContactIdToAccountId.get(userObj.contactId) != NULL &&
                            partnerFunctionSoldToIds.contains(mapContactIdToAccountId.get(userObj.contactId))){
                        if(mapPFSoldToIdCurrency.get(mapContactIdToAccountId.get(userObj.contactId)) != NULL){ 
                            userObj.CurrencyIsoCode = mapPFSoldToIdCurrency.get(mapContactIdToAccountId.get(userObj.contactId));                        
                            userObj.DefaultCurrencyIsoCode = mapPFSoldToIdCurrency.get(mapContactIdToAccountId.get(userObj.contactId));                        
                        }                        
                    }
                }
            }
        }
    }
    /**
     * @description updateAccountCurrency
     * @param newItems 
     */    
    public static void updateAccountCurrency(Map<Id, SObject> newItems){
        List<Account> accountToUpdate = new List<Account>();
        boolean flagToUpdateAccount = false;
        Set<Id> userIdSet = new Set<Id>();
        for(SObject sObj : newItems.values()) {
            User userObj = (User)sObj;
            userIdSet.add(userObj.Id);
        }
        map<Id,User> userMap = new  map<Id,User>([select accountId,CurrencyIsoCode,account.Products_Enabled__c,account.CurrencyIsoCode,account.isBuyer 
                                                    from User where Id IN : userIdSet and Profile.Name = 'DiageoOne External User']);
        
        set<Id> accountIdAlreadyAdded = new set<Id>();
        for(SObject sObj : newItems.values()) {
            User userObj = (User)sObj;
            if(userObj.accountId != NULL && userMap != NULL && userMap.containsKey(userObj.Id)) {
                Account accObj = new Account(Id = userObj.accountId);
                if(userObj.CurrencyIsoCode != userMap.get(userObj.Id).account.CurrencyIsoCode) { 
                    accObj.CurrencyIsoCode = userObj.CurrencyIsoCode;
                    flagToUpdateAccount = true;
                }
                if(userMap.get(userObj.Id).account.Products_Enabled__c == NULL){
                    accObj.Products_Enabled__c = 'Diageo One';
                    flagToUpdateAccount = true;
                } else if(!userMap.get(userObj.Id).account.Products_Enabled__c.contains('Diageo One')) {
                    accObj.Products_Enabled__c = userMap.get(userObj.Id).account.Products_Enabled__c + ';Diageo One';
                    flagToUpdateAccount = true;
                }  
                if(flagToUpdateAccount == true && !accountIdAlreadyAdded.contains(accObj.Id)) {
                    accountToUpdate.add(accObj);
                    accountIdAlreadyAdded.add(accObj.Id);
                }
            }                   
        }
        if(accountToUpdate !=null && accountToUpdate.size()>0) {
            try {
                Database.update(accountToUpdate,false);
            } catch(Exception ex) {
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
    }
}