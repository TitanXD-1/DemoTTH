@isTest
public class D1_BulkContactRegistrationControllerTest {
    
    @isTest
    public static void testDirectCustomerCheck(){
        
        User testAdminUser;
        testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator'); 
        testAdminUser.Email = 'abc@diageo.com';
        insert testAdminUser;
        
        String common = 'Geog1_es';
        String recordTypeId = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        
        Geography__c geog = new Geography__c();
        geog.RecordTypeId = recordTypeId;
        geog.Name = 'Geog1';
        geog.Code__c = '123';
        geog.isDiageoOneEnabled__c = True;
        geog.Code__c ='es';
        insert geog;
        
        D1_Setting__c d1setting = new D1_Setting__c();
        d1setting.Name = 'Spain';
        d1setting.Unique_ID__c = common;
        d1setting.Language__c = D1_Setting__c.Language__c.getDescribe().getPicklistValues()[0].getValue();
        d1setting.Market__c = geog.id;
        d1setting.Default__c = true;
        insert d1setting;
        
        D1_User_Type__c d1UserType = new D1_User_Type__c();
        d1UserType.Name = 'Direct Buyer';
        d1UserType.D1_Setting__c = d1setting.id;
        d1UserType.User_Type__c = D1_User_Type__c.User_Type__c.getDescribe().getPicklistValues()[0].getValue();
        d1UserType.Customer_Service_Group__c = 'abc@diageo.com';
        insert d1UserType;
        
        String outletRecTypeId =  Schema.SObjectType.Account.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        Account distAccount = new Account();
        distAccount.Name = 'Test Customer Account';
        distAccount.AccountNumber = '10483';
        distAccount.Country__c = geog.Id;
        distAccount.BillingStreet = '17 Asian Highway 45';
        distAccount.BillingCity = 'Sydney';
        distAccount.BillingState = 'Tasmania';
        distAccount.BillingPostalCode = '5668';
        distAccount.Primary_Sales_Rep__c = testAdminUser.id;
        distAccount.RecordTypeId =  outletRecTypeId;
        distAccount.Outlet_Email_Address__c = 'test@test.com';
        distAccount.VAT_Number__c = '1234';
        distAccount.BillingCountry = 'Australia';
        distAccount.Direct_Customer__c = true;
        Insert distAccount;
        
        distAccount.VAT_Number__c = '1234';
        update distAccount;
        
        Contact primcon1=new Contact(FirstName='fname1',
                                     LastName = 'lname',
                                     Email = 'email1@gmail.com',
                                     Phone = '12345672890',Contact_Type__c='Primary',AccountID=distAccount.Id); 
        insert primcon1;
        
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        acrList  = [Select id,D1_User_Role__c,IsActive ,AccountId,ContactId 
                    from AccountContactRelation
                    where AccountId =:distAccount.id AND ContactId =:primcon1.id];
                
        for(AccountContactRelation var : acrList){
            var.D1_User_Role__c ='Primary';
            var.Contact_Type__c ='Secondary';
            var.D1_Active__c = true;
        }
        update acrList;
        
        List<String> contactList = new List<String>();
        contactList.add(primcon1.Id);
        
        Account distAccount1 = new Account();
        distAccount1.Name = 'Test Customer Account1';
        distAccount1.AccountNumber = '104831';
        distAccount1.Country__c = geog.Id;
        distAccount1.BillingStreet = '17 Asian Highway 45';
        distAccount1.BillingCity = 'Sydney';
        distAccount1.BillingState = 'Tasmania';
        distAccount1.BillingPostalCode = '5668';
        distAccount1.Primary_Sales_Rep__c = testAdminUser.id;
        distAccount1.RecordTypeId =  outletRecTypeId;
        distAccount1.Outlet_Email_Address__c = 'test1@test.com';
        distAccount1.VAT_Number__c = '1234';
        distAccount1.BillingCountry = 'Australia';
        distAccount1.Direct_Customer__c = true;
        Insert distAccount1;
        
        distAccount1.VAT_Number__c = '1234';
        update distAccount1;
        
        Contact primcon2=new Contact(FirstName='faname1',
                                     LastName = 'laname',
                                     Email = 'email1@diageo.com',
                                     Phone = '23333',Contact_Type__c='Primary',AccountID=distAccount1.Id); 
        insert primcon2;
        
        List<AccountContactRelation> acrList1 = new List<AccountContactRelation>();
        acrList1  = [Select id,D1_User_Role__c,IsActive ,AccountId,ContactId 
                     from AccountContactRelation
                     where AccountId =:distAccount1.id AND ContactId =:primcon2.id];
        
        for(AccountContactRelation var : acrList1){
            var.D1_User_Role__c ='Primary';
            var.Contact_Type__c ='Primary';
            var.D1_Active__c = true;
        }
        
        update acrList1;

        contactList.add(primcon2.Id);
        
        Account distAccount2 = new Account();
        distAccount2.Name = 'Test Customer3 Account';
        distAccount2.AccountNumber = '1048311';
        distAccount2.Country__c = geog.Id;
        distAccount2.BillingStreet = '17 Asian Highway 45';
        distAccount2.BillingCity = 'Sydney';
        distAccount2.BillingState = 'Tasmania';
        distAccount2.BillingPostalCode = '5668';
        distAccount2.Primary_Sales_Rep__c = testAdminUser.id;
        distAccount2.RecordTypeId =  outletRecTypeId;
        distAccount2.Outlet_Email_Address__c = 'test2@test.com';
        distAccount2.VAT_Number__c = '1234';
        distAccount2.BillingCountry = 'Australia';
        Insert distAccount2;
        
        distAccount.VAT_Number__c = '1234';
        update distAccount2;
        
        Contact primcon3=new Contact(FirstName='name1',
                                     LastName = 'name',
                                     Email = 'email1@abc.com',
                                     Phone = '12345',Contact_Type__c='Primary',AccountID=distAccount2.Id); 
        insert primcon3;
        
        List<AccountContactRelation> acrList2 = new List<AccountContactRelation>();
        acrList2  = [Select id,D1_User_Role__c,IsActive ,AccountId,ContactId 
                     from AccountContactRelation
                     where AccountId =:distAccount2.id AND ContactId =:primcon3.id];
        
        for(AccountContactRelation var : acrList2){
            var.D1_User_Role__c ='Primary';
            var.Contact_Type__c ='Secondary';
            var.D1_Active__c = true;
        }

        update acrList2;
        
        contactList.add(primcon3.Id);
        
        Account distAccount3 = new Account();
        distAccount3.Name = 'Test Customer4 Account';
        distAccount3.AccountNumber = '101311';
        distAccount3.Country__c = geog.Id;
        distAccount3.BillingStreet = '17 Asian Highway 45';
        distAccount3.BillingCity = 'Sydney';
        distAccount3.BillingState = 'Tasmania';
        distAccount3.BillingPostalCode = '5668';
        distAccount3.Primary_Sales_Rep__c = testAdminUser.id;
        distAccount3.RecordTypeId =  outletRecTypeId;
        distAccount3.Outlet_Email_Address__c = 'test2@test.com';
        distAccount3.VAT_Number__c = '1234';
        distAccount3.BillingCountry = 'Australia';
        distAccount3.Direct_Customer__c = true;
        Insert distAccount3;
        
        distAccount3.VAT_Number__c = '1234';
        update distAccount3;
        
        Contact primcon4=new Contact(FirstName='name1',
                                     LastName = 'name',
                                     Email = 'email1@xyz.com',
                                     Phone = '1234115',Contact_Type__c='Primary',AccountID=distAccount3.Id); 
        insert primcon4;
        
        List<AccountContactRelation> acrList3 = new List<AccountContactRelation>();
        acrList3  = [Select id,D1_User_Role__c,IsActive ,AccountId,ContactId 
                     from AccountContactRelation
                     where AccountId =:distAccount3.id AND ContactId =:primcon4.id];
        
        for(AccountContactRelation var : acrList3){
            var.D1_User_Role__c ='Primary';
            var.Contact_Type__c ='Primary';
            var.D1_Active__c = false;
        }

        update acrList3;
        
        contactList.add(primcon4.Id);
        D1_BulkContactRegistrationController.Requests obj = new D1_BulkContactRegistrationController.Requests();
        obj.contactId = contactList;
        System.assert(obj.contactId != NULL, 'Contact not registered');
        Test.startTest();
            D1_BulkContactRegistrationController.createD1User(new List<D1_BulkContactRegistrationController.Requests>{obj});
        Test.stopTest();
        
    }
}