@isTest
public class Test_MD_ES_RegistrationValidationsClass {
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
    }
    static testMethod void validateAccounts(){
        
        Map<String, Geography__c> geos = TestFactory_MD_Account.createGeographies();
        Map<String, RecordType> accountsRt = new Map<String, RecordType>();
        
        for(RecordType art : [SELECT Id, DeveloperName FROM RecordType WHERE SobjectType = 'Account']) {
            accountsRt.put(art.DeveloperName, art);
        }
        
        List<Account> ownerAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Owner'), 'TestAccountOwner', 10, geos, true);
        List<Account> outletsAccounts = TestFactory_MD_Account.createAccounts(accountsRt.get('Outlet'), 'TestAccountOutlet', 10, geos, false);
        
        Integer i = 0;
        for(Account outletAccount : outletsAccounts) {
            outletAccount.ParentId = ownerAccounts.get(i).Id;
            outletAccount.Operator__c = ownerAccounts.get(i).Id;
            i++;
        }
        
        insert outletsAccounts;
        
        List<Account> accToUpdate = new List<Account>();
        
        for (Account a: [SELECT Id, VAT_Number__c FROM Account WHERE RecordType.DeveloperName = 'Owner']){
            a.VAT_Number__c = '123456789';
            accToUpdate.add(a);
        }
        
        
        update accToUpdate;

        Map<Id,Account> mapAccounts = new Map<Id,Account>([SELECT Id, RecordTypeId, Operator__r.RecordTypeId, Operator__r.Country_Code__c, Country_Code__c, Global_Channel__c, IsIndependent__c, Independent_of_Operator__c, VAT_Number__c, Operator__r.VAT_Number__c, Operator__r.Global_Channel__c FROM Account]);
        
        System.debug('SIZE : ' + mapAccounts.size());
        
        MD_ES_RegistrationValidationsClass.SpainValidations validations = new  MD_ES_RegistrationValidationsClass.SpainValidations();
        
        Test.startTest();
        validations.execute(mapAccounts);
        Test.stopTest();   
        
    }
}