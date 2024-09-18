public without sharing class D1_TermsAndConditionsPopupCtrl {    
    @AuraEnabled(cacheable = false)
    public static D1_Terms_Conditions__c getJMLConditionsForFirstTimeLogin() {
        Map<Id,D1_Terms_Conditions__c> mapActiveTerms = new Map<Id,D1_Terms_Conditions__c>();
        Map<Id,D1_Contact_Agreement__c> mapContAgreements = new Map<Id,D1_Contact_Agreement__c>();
        List<User> usrList = new List<user>();
        
        Id jmlRecordId= Schema.SObjectType.D1_Terms_Conditions__c.getRecordTypeInfosByName().get('JML').getRecordTypeId();
        usrList = [Select Id, ContactId,Contact.AccountId, Contact.D1_JML_T_C__c,Available_Countries__c,LanguageLocaleKey FROM User where id =:UserInfo.getUserId()];
        if(usrList.size()>0){           
            D1_Terms_Conditions__c tc = new D1_Terms_Conditions__c();
            D1_Contact_Agreement__c ca = new D1_Contact_Agreement__c();
            mapActiveTerms = new Map<ID, D1_Terms_Conditions__c>([SELECT Id, Name,Status__c,Version__c,
                                                                    Market__c,Language__c,Content__c,Market__r.Market__r.isDiageoOneEnabled__c , Market__r.Market__r.Code__c ,Market__r.Language__c
                                                                    FROM D1_Terms_Conditions__c WHERE Status__c='Active' and Market__r.Market__r.isDiageoOneEnabled__c=true and RecordTypeId=:jmlRecordId
                                                                    AND Market__r.Language__c =: usrList[0].LanguageLocaleKey 
                                                                    AND Market__r.Market__r.Code__c = : usrList[0].Available_Countries__c 
                                                                    ORDER BY Version__c DESC LIMIT 1]);
            if(mapActiveTerms == null || mapActiveTerms.size() == 0){ //US 150154:PMD Fix
                return Null;
            }
            mapContAgreements = new Map<Id,D1_Contact_Agreement__c>([SELECT Id, Name, Version__c, JML_Accepted_Time__c, D1_Terms_Conditions__c, Account__c, Contact__c 
                                                                     FROM D1_Contact_Agreement__c 
                                                                     WHERE D1_Terms_Conditions__c =: mapActiveTerms.KeySet() 
                                                                     AND Contact__c = :usrList[0].ContactId order by Version__c desc LIMIT 1]);
            
            tc = mapActiveTerms.values();
            if(mapContAgreements!=null && mapContAgreements.size()>0){ //US 150154:PMD Fix
                ca = mapContAgreements.values();
            }
            if(mapContAgreements != null && mapContAgreements.size()>0 && ca!= null &&tc.version__c <= ca.version__c){  
                
                return null;
            }            
            else{
                for(D1_Terms_Conditions__c termCondition: mapActiveTerms.values()){
                    return termCondition;
                }
            }
        }        
        return Null;
    }

    @AuraEnabled
    public static Boolean setJMLConditions(Id termsConditions) {
        List<User> usrList = new List<user>();
        usrList = [Select Id,AccountId, ContactId, Contact.D1_JML_T_C__c FROM User where id =:UserInfo.getUserId()];
        Contact conRec = new Contact(Id =usrList[0].ContactId);
        Account acc = new Account(Id =usrList[0].AccountId);
        if( termsConditions != null){
            D1_Terms_Conditions__c obj = [SELECT (SELECT Id, Name, Version__c, JML_Accepted_Time__c, D1_Terms_Conditions__c, Account__c, Contact__c 
                                                  FROM D1_Contact_Agreements__r WHERE Contact__c =:conRec.Id ORDER BY Version__c DESC), Status__c, Content__c, Version__c, Market__c, Language__c, Name, Id,RecordTypeId,Releases__c
                                          FROM D1_Terms_Conditions__c WHERE Id=:termsConditions LIMIT 1];
            
            D1_Contact_Agreement__c contactAgreement = new D1_Contact_Agreement__c();
            contactAgreement.Contact__c = conRec.Id;
            contactAgreement.Account__c = acc.Id;
            contactAgreement.D1_Terms_Conditions__c = termsConditions;
            contactAgreement.JML_Accepted_Time__c = System.now();
            contactAgreement.Version__c = obj.Version__c;
            
            if(obj.D1_Contact_Agreements__r != null && obj.D1_Contact_Agreements__r.size()>0){
                for(D1_Contact_Agreement__c o : obj.D1_Contact_Agreements__r){
                    if(obj.Version__c >= o.Version__c){
                        try{
                            insert contactAgreement;
                            return true;
                        }catch (Exception e){
                            return false;
                        }
                    }
                }
            }else {
                try{
                    insert contactAgreement;
                    return true;
                }catch (Exception e){
                    return false;
                }
            }
        }
        return false;
    }
    @AuraEnabled(cacheable = true)
    public static D1_Setting__c getD1Setting(String availableCountry, String langauages){
       List<D1_Setting__c> d1Settings = [SELECT Id,Enable_Sales_Area_Terms_and_Conditions__c FROM D1_Setting__c WHERE Market__r.Code__c =: availableCountry AND Language__c =: langauages LIMIT 1];
       return d1Settings.isEmpty()?null:d1Settings[0];                          
    }
    @AuraEnabled(cacheable = true)
    public static OrderSplit__c getSalesArea(String oSplit){
        if(oSplit=='') { //US 150154:PMD Fix
            return null;
        }
        return [SELECT Id, Sales_Area__c FROM OrderSplit__c WHERE Id=:oSplit Limit 1];
    } 

    @AuraEnabled(cacheable = false) //NCP-5435
    public static D1_Terms_Conditions__c getJMLOrderConditions(String recordTypeName, String orderSplitId ) {
        Map<Id,D1_Terms_Conditions__c> mapActiveTerms = new Map<Id,D1_Terms_Conditions__c>();
        Map<Id,D1_Contact_Agreement__c> mapContAgreements = new Map<Id,D1_Contact_Agreement__c>();
        List<User> usrList = new List<user>();
        OrderSplit__c os = new OrderSplit__c ();
        usrList = [Select Id, ContactId,Contact.AccountId, Contact.D1_JML_T_C__c,Available_Countries__c,LanguageLocaleKey FROM User where id =:UserInfo.getUserId()];
        if(usrList.size()>0){  
            D1_Terms_Conditions__c tc = new D1_Terms_Conditions__c();
            D1_Contact_Agreement__c ca = new D1_Contact_Agreement__c();
            mapActiveTerms = new Map<ID, D1_Terms_Conditions__c>([SELECT Id, Name,Status__c,Sales_Area__c,Version__c,
                                                                    Market__c,Language__c,Content__c,Market__r.Market__r.isDiageoOneEnabled__c , Market__r.Market__r.Code__c ,Market__r.Language__c
                                                                    FROM D1_Terms_Conditions__c WHERE Status__c='Active' and Market__r.Market__r.isDiageoOneEnabled__c=true and RecordType.Name=:recordTypeName
                                                                    AND Market__r.Language__c =: usrList[0].LanguageLocaleKey 
                                                                    AND Market__r.Market__r.Code__c = : usrList[0].Available_Countries__c 
                                                                    ORDER BY Version__c DESC]);
            
            if(recordTypeName == 'JML'){               
                if(mapActiveTerms == null || mapActiveTerms.size() == 0){
                    return Null;
                }
                mapContAgreements = new Map<Id,D1_Contact_Agreement__c>([SELECT Id, Name, Version__c, JML_Accepted_Time__c, D1_Terms_Conditions__c, Account__c, Contact__c 
                                                                     FROM D1_Contact_Agreement__c 
                                                                     WHERE D1_Terms_Conditions__c =: mapActiveTerms.KeySet() 
                                                                     AND Contact__c = :usrList[0].ContactId order by Version__c desc LIMIT 1]);            
                tc = mapActiveTerms.values();
                if(mapContAgreements!=null && mapContAgreements.size()>0) { //US 150154:PMD Fix           
                    ca = mapContAgreements.values();
                }
                if(mapContAgreements != null && mapContAgreements.size()>0 && ca!= null &&tc.version__c <= ca.version__c){                
                    for(D1_Terms_Conditions__c termCondition: mapActiveTerms.values()){              
                        return termCondition;
                    }
                }             
                else{
                    return null;
                }
         
            } 
            else if(recordTypeName == 'Order Terms and Condition'){
                D1_Setting__c d1Setting = getD1Setting(usrList[0].Available_Countries__c,usrList[0].LanguageLocaleKey);
                os = getSalesArea(orderSplitId);
                for(D1_Terms_Conditions__c termCondition: mapActiveTerms.values()){
                    if(
                        (d1Setting.Enable_Sales_Area_Terms_and_Conditions__c && termCondition.Sales_Area__c== os.Sales_Area__c) 
                        ||
                        (!d1Setting.Enable_Sales_Area_Terms_and_Conditions__c && termCondition.Sales_Area__c==null)
                    ){
                        return termCondition;
                    }                
                }
            }
        }      
        return Null;
    }
}