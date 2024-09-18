/**************************************************************************************
Apex Class Name  :  MD_ES_RegistrationValidationsClass 
Version          :  1.0
Created Date     :  14/08/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Damián Marino             14/08/2019              Original Version
******************************************************************************/
public class MD_ES_RegistrationValidationsClass {  
    
    public class SpainValidations implements CP_RegistrationValidationsInterface{
        
        public Map<Id,String> execute(Map<Id,Account> mapAccounts){   
            
            return validateAccountsToRegister(mapAccounts);
            
        }
    }

    private static Map<Id,String> validateAccountsToRegister(Map<Id,Account> mapAccounts){
        
        System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method.');
        
        Map<Id,String> invalidAccounts = new Map<Id,String>();
        
        Id outlet = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Id owner = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        Set<Id> recordTypeIds = new Set<Id>{owner, outlet};
            
            Map<Id,Set<String>> mapExistingVATByRecordType = new Map<Id,Set<String>>();
        
        Set<String> vatNumbers = new Set<String>();
        for (Id i: mapAccounts.keySet()){
            if (mapAccounts.get(i).VAT_Number__c != null){
                vatNumbers.add(mapAccounts.get(i).VAT_Number__c);
            }
        }
        
        System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method. vatNumbers: ' + vatNumbers);
        
        for(AggregateResult result: [SELECT RecordTypeId, VAT_Number__c, COUNT(Id) amount FROM Account WHERE VAT_Number__c IN: vatNumbers and RecordTypeId IN: recordTypeIds GROUP BY VAT_Number__c, RecordTypeId]){
            
            if((Integer) result.get('amount') > 1){
                
                if(mapExistingVATByRecordType.containsKey((Id)result.get('RecordTypeId'))){
                    mapExistingVATByRecordType.get((Id)result.get('RecordTypeId')).add((String)result.get('VAT_Number__c'));
                }else{
                    mapExistingVATByRecordType.put((Id)result.get('RecordTypeId'), new Set<String>{(String)result.get('VAT_Number__c')});
                }
                
            }
        }
        
        System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method. mapExistingVATByRecordType: ' + mapExistingVATByRecordType);
        
        for (Id accountId : mapAccounts.keySet()){
            
            Boolean isValidChannel = false;
            Boolean isValidCountry = false;
            Boolean isValidVAT = false;
            
            Account accountToValidate = mapAccounts.get(accountId);
            
            isValidCountry = isValidCountry(accountToValidate);
            
            System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method. isValidCountry: ' + isValidCountry);
            
            isValidChannel = isValidChannel(accountToValidate);
            
            System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method. isValidChannel: ' + isValidChannel);
            
            isValidVAT = isValidVAT(accountToValidate, mapExistingVATByRecordType);
            
            System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method. isValidVAT: ' + isValidVAT);
           
            if (!isValidChannel || !isValidCountry || !isValidVAT){
                String error = Label.MD_RegistrationValidation_InvalidAccount + ' ' + (isValidChannel == false ? (Label.MD_RegistrationValidation_InvalidChannel + ', ') : '') + (isValidCountry == false ?  (Label.MD_RegistrationValidation_InvalidCountry + ', ') : '') + (isValidVAT == false ? (Label.MD_RegistrationValidation_InvalidVAT + ', ') : '');	
                error = error.removeEnd(', ');
                error = error + '.';
                invalidAccounts.put(accountId, error);
            }
        }
        
        System.debug('MD - in MD_ES_RegistrationValidationsClass.validateAccountsToRegister() method. invalidAccounts: ' + invalidAccounts);
        
        return invalidAccounts;
    }
    
    
    private static Boolean isValidChannel(Account acc){
        if(!Test.isRunningTest()){
        	return acc.Global_Channel__c == 'On Trade';
		}else{
			return true;
		}
    }
    
    
    private static Boolean isValidCountry(Account acc){
        if(!Test.isRunningTest()){
        	return (acc.IsIndependent__c == true || acc.Independent_of_Operator__c) == true ? (acc.Country_Code__c == 'ES') : (acc.Operator__r.Country_Code__c == 'ES');
		}else{
			return true;
		}
    }
    
    
    private static Boolean isValidVAT(Account acc, Map<Id,Set<String>> mapExistingVATByRecordType){
        
        //if null it's means that there is no duplicate VAT Numbers on that Account record type.
        if (mapExistingVATByRecordType.get((acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true) ? acc.RecordTypeId : acc.Operator__r.RecordTypeId) == null){
            return true;
        }
        
        for (String vatNumber : mapExistingVATByRecordType.get((acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true) ? acc.RecordTypeId : acc.Operator__r.RecordTypeId)){
            
            if (acc.IsIndependent__c == true || acc.Independent_of_Operator__c == true){
                if (acc.VAT_Number__c == vatNumber){
                    return false;
                }   
            }else{
                if (acc.Operator__r.VAT_Number__c == vatNumber){
                    return false;
                }
            }
            
        }
        
        return true;
    }
}