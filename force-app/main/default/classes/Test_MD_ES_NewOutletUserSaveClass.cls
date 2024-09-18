@isTest
public class Test_MD_ES_NewOutletUserSaveClass {
	
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
        TestFactory_MD_Account.setupNoUser(true);
    }
    
    @isTest
    public static void insertedRecordsWrapperTest03() {
        Account acc = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Prospect' OR RecordType.DeveloperName = 'Outlet'];
        //Account ac = new Account(Name='TestAccount', VAT_Number__c='594594');
        Contact con = new Contact(Email='TestContact@Test.com');
        con.Mobile__c = '+349999999';
        con.MobilePrefix__c = '+34';
        AccountContactRelation accCon = new AccountContactRelation(MD_Status__c = 'Active', accountid = acc.id, contactid = con.id);
        Geography__c geo = new Geography__c();
        geo.Code__c = 'ES';
        
        Map<String,SObject> formData = new Map<String,SObject>();
        formData.put('Account',acc);
        formData.put('Contact',con);
        formData.put('sObjectToRevert_0',con);
        formData.put('Geography__c',geo);
        formData.put('AccountContactRelation', accCon);
        formData.put('sObjectToRevert_0', accCon);
        
        MD_ES_NewOutletUserSaveClass.SecondaryUser save = new  MD_ES_NewOutletUserSaveClass.SecondaryUser();
        Test.startTest();
        save.execute(formData);
        Test.stopTest();   
        
    }
    
    @isTest
    public static void insertedRecordsWrapperTest01() {
        Account acc = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Prospect' OR RecordType.DeveloperName = 'Outlet'];
        //Account ac = new Account(Name='TestAccount', VAT_Number__c='594594');
        Contact con = new Contact(Email='TestContact@Test.com');
        con.Mobile__c = '+349999999';
        con.MobilePrefix__c = '+34';
        AccountContactRelation accCon = new AccountContactRelation(MD_Status__c = 'Active', accountid = acc.id, contactid = con.id);
        Geography__c geo = new Geography__c();
        geo.Code__c = 'ES';
        Map<String,SObject> formData = new Map<String,SObject>();
        formData.put('Account',acc);
        formData.put('Contact',con);
        formData.put('Geography__c',geo);
        formData.put('AccountContactRelation', accCon);
        MD_ES_NewOutletUserSaveClass.SecondaryUser save = new  MD_ES_NewOutletUserSaveClass.SecondaryUser();
        Test.startTest();
        save.execute(formData);
        Test.stopTest();   
        
    }
    
    @isTest
    public static void insertedRecordsWrapperTest02() {
        Account acc = [SELECT Id FROM Account WHERE RecordType.DeveloperName = 'Prospect' OR RecordType.DeveloperName = 'Outlet'];
        //Account ac = new Account(Name='TestAccount', VAT_Number__c='594594');
        Contact con = new Contact(Email='TestContact@Test.com');
        con.Mobile__c = '+349999999';
        con.MobilePrefix__c = '+34';
        AccountContactRelation accCon = new AccountContactRelation(MD_Status__c = 'Active', accountid = acc.id, contactid = con.id);
        Geography__c geo = new Geography__c();
        geo.Code__c = 'ES';
        Map<String,SObject> formData = new Map<String,SObject>();
        formData.put('Account',acc);
        formData.put('Contact',con);
        formData.put('sObjectToRevert_0',con);
        formData.put('Geography__c',geo);
        formData.put('AccountContactRelation', accCon);
        MD_ES_NewOutletUserSaveClass.SecondaryUser save = new  MD_ES_NewOutletUserSaveClass.SecondaryUser();
        Test.startTest();
        save.execute(formData);
        Test.stopTest();   
        
    }
}