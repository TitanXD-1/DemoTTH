@isTest
public class Test_MD_RegistrationSaveClass {
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
    }
    static testMethod void saveContact(){
        Account ac = new Account(Name='TestAccount', VAT_Number__c='594594');
        Contact con = new Contact(Email='TestContact@Test.com');
        Geography__c geo = new Geography__c();
        geo.Code__c = 'ES';
        Map<String,SObject> formData = new Map<String,SObject>();
        formData.put('Account',ac);
        formData.put('Contact',con);
        formData.put('Geography__c',geo);
        MD_RegistrationSaveClass.saveContact save = new  MD_RegistrationSaveClass.saveContact();
        Test.startTest();
        save.execute(formData);
        Test.stopTest();   
    }
    
    static testMethod void saveContactExtended(){
        Map<String, Geography__c> geoMap = TestFactory_MD_Account.createGeographies();
        Account ac = new Account(Name='TestAccount', VAT_Number__c='594594',BillingStreet='test',BillingCity='test',BillingPostalCode='test');
        Contact con = new Contact(FirstName='testname', LastName='testlastname', Email='TestContact@Test.com', MobilePhone='1234');
        Geography__c geo = new Geography__c();
        geo.Code__c = geoMap.get('Country').Code__c;
        insert new Pick_Up_Options__c(Name = 'N0[ES]', Geography__c = geoMap.get('Country').Id, Type__c = 'Outlet Visit Prioritization');

        Map<String,SObject> formData = new Map<String,SObject>();
        formData.put('Account',ac);
        formData.put('Contact',con);
        formData.put('Geography__c',geo);
        MD_RegistrationSaveClass.saveContactExtended save = new MD_RegistrationSaveClass.saveContactExtended();
        Test.startTest();
        save.execute(formData);
        Test.stopTest();
        
    }

    
}