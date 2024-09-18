/**
* @name : D1_TransferPrimaryUserTest
* @discription : Test classfor D1_TransferPrimaryUser Class 
* @History
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Gaurav            7/9/20    Initial Development(NCP-4310)
**/
@isTest
public without sharing class D1_TransferPrimaryUserTest {
    /**
    * @name : testGenericMethods
    * @description : Test all primary methods of D1_TransferPrimaryUser
    */
    @istest 
    public static void testGenericMethods(){
        Contact con = [SELECT Id, Email, AccountId FROM Contact WHERE Email = 'secondary.contact@yopmail.com' LIMIT 1];
        Contact con2 = [SELECT id,Email,AccountId FROM Contact WHERE Email= 'indirect.contact@yopmail.com' LIMIT 1];
        AccountContactRelation acrStaff = [SELECT Id, D1_Roles__c FROM AccountContactRelation WHERE ContactId = :con2.Id AND AccountId =: con2.AccountId];

        User usr = [SELECT Id,email,LanguageLocaleKey,Available_Countries__c FROM User WHERE contactId =: con.Id LIMIT 1];
        system.runAs(usr){
            Map<String,Object> result = new Map<String,Object>();
            Map<String,Object> result2 = new Map<String,Object>();

            Test.startTest();
                result = D1_TransferPrimaryUser.getPrimaryAccountInfo(null);
                result2 = D1_TransferPrimaryUser.getPrimaryAccountInfo(con.Id);
                D1_TransferPrimaryUser.updatePrimaryAccountInfo(con.Id, true, new List<Id>{acrStaff.Id});
            Test.stopTest();

            System.assert(result != NULL, 'ACCOUTINFOLIST NOT FOUND');
            System.assert(result2 != NULL, 'ACCOUTINFOLIST NOT FOUND');
            Assert.isNotNull(result, 'ACCOUTINFOLIST NOT FOUND');
            Assert.isNotNull(result2, 'ACCOUTINFOLIST NOT FOUND');
        }
    }
    
    /**
    * @name : dataSetup
    * @description : This method is used to create test data
    */
    @testSetup
    public static void dataSetup(){
        //Add Direct Customers - one payer account
        List<Account> directCusts = new List<Account>();

        Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        Account directCustomerPayerAcc = D1_TestDataUtility.getDirectCustomer();
        directCustomerPayerAcc.KUNNR__c = '23456';

        directCusts.add(directCustomer);
        directCusts.add(directCustomerPayerAcc);
        insert directCusts;
        
        //Set Up Buyer for Direct Customer and D1 Setting & Geography
        D1_TestDataUtility.setUpExternalUser(directCustomer, 'Direct Buyer');
        Geography__c country = [SELECT Id,Name FROM Geography__c WHERE RecordType.Name = 'Country'];
        D1_Setting__c d1Setting = [SELECT Id FROM D1_Setting__c LIMIT 1];
        
        //Update geography fields in Direct Customer
        directCustomer.Market__c = D1_TestDataUtility.geoMap.get('Market');
        directCustomer.Hub__c = D1_TestDataUtility.geoMap.get('Hub');
        directCustomer.Cluster__c = D1_TestDataUtility.geoMap.get('Cluster');
        directCustomer.country__c = D1_TestDataUtility.geoMap.get('Country');
        update directCustomer;
        
        //Set Up User Type Role
        D1_User_Type__c d1UserType = D1_TestDataUtility.getD1UserType(country.Name, 'Outlet/Retailers', d1Setting.Id);
        insert d1UserType;
        
        D1_User_Role__c userRole = D1_TestDataUtility.getD1UserRole('Ordering');
        insert userRole;
        
        D1_User_Types_Role__c userTypeRole = D1_TestDataUtility.getD1UserTypeRole(d1UserType, userRole);
        insert userTypeRole;
        
        //Set Up Two Contacts for Direct Customer
        List<Contact> conList = new List<Contact>();
        Contact secContact = D1_TestDataUtility.getContact(directCustomer.Id, 'Secondary');
        secContact.Email = 'secondary.contact@yopmail.com';

        Contact contactStaff = D1_TestDataUtility.getContact(directCustomer.Id, 'Secondary');
        contactStaff.FirstName = 'test678';
        contactStaff.Phone = '12342890';
        contactStaff.Email = 'indirect.contact@yopmail.com';

        conList.add(secContact);
        conList.add(contactStaff);
        insert conList;

        //Set up User Records for the contacts
        List<User> userList = new List<User>();
        User secExtUser = D1_TestDataUtility.runAsUser('secExtUser', 'DiageoOne External User');
        secExtUser.Effective_Account_Id__c = directCustomer.Id;
        secExtUser.ContactId = secContact.Id;
        secExtUser.Email = 'secondary.contact@yopmail.com';
        
        User extUser2 = D1_TestDataUtility.runAsUser('indirectExtUser', 'DiageoOne External User');
        extUser2.Effective_Account_Id__c = directCustomer.Id;
        extUser2.ContactId = contactStaff.Id;
        extUser2.Email = 'indirect.contact@yopmail.com';

        userList.add(secExtUser);
        userList.add(extUser2);
        insert userList;
        
        //Add Partner Functions
        List<PNR_Partner_Function__c> pfList = new List<PNR_Partner_Function__c>();
        PNR_Partner_Function__c directCustomerPayer =  D1_TestDataUtility.getPartnerFunction(directCustomer,'Payer');
        directCustomerPayer.PNR_Sold_To__c = directCustomer.Id;
        directCustomerPayer.PNR_Customer_No__c = directCustomer.Id;
         
        PNR_Partner_Function__c directCustomerPayer2 =  D1_TestDataUtility.getPartnerFunction(directCustomer,'Payer');
        directCustomerPayer2.PNR_Sold_To__c = directCustomer.Id;
        directCustomerPayer2.PNR_Customer_No__c = directCustomerPayerAcc.Id;

        pfList.add(directCustomerPayer);
        pfList.add(directCustomerPayer2);
        insert pfList;

        //Manage ACRs
        List<AccountContactRelation> acrList = new List<AccountContactRelation>();
        AccountContactRelation acrPrimary = [SELECT Id, D1_Roles__c, D1_Active__c, D1_User_Role__c FROM AccountContactRelation WHERE ContactId = :secContact.Id];
        acrPrimary.D1_Roles__c='User Management';
        acrPrimary.D1_Active__c = True;
        acrPrimary.D1_User_Role__c = 'Primary';
        acrList.add(acrPrimary);
        
        AccountContactRelation acrStaff = [SELECT Id, D1_Roles__c, D1_Active__c, D1_User_Role__c FROM AccountContactRelation WHERE ContactId = :contactStaff.Id];
        acrStaff.D1_Roles__c='User Management';
        acrStaff.D1_Active__c = True;
        acrStaff.D1_User_Role__c = 'Member of Staff';
        acrList.add(acrStaff);
   
        AccountContactRelation acrSecContact2 = new AccountContactRelation(
            AccountId = directCustomerPayerAcc.Id,
            ContactId = secContact.Id,
            D1_Roles__c='User Management',
            D1_Active__c = True,
            D1_User_Role__c = 'Primary'
        );
        acrList.add(acrSecContact2);
        
        AccountContactRelation acrStaffContact2 = new AccountContactRelation(
            AccountId = directCustomerPayerAcc.Id,
            ContactId = contactStaff.Id,
            D1_Roles__c='User Management',
            D1_Active__c = True,
            D1_User_Role__c = 'Member of Staff'
        );
        acrList.add(acrStaffContact2);
        upsert acrList;
    }    
}