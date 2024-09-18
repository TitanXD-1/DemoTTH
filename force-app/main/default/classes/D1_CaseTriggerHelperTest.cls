/**
 * @name : D1_CaseTriggerHelperTest
 * @description : Test Class for D1_CaseTriggerHelper
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Amar            30/07/2021      Initial Development (NCP-3817)
 * 2.0          Kapil Baliyan   06/04/2022      NCP-6387
 * 2.1			Saurav Prasad	14/04/2023		CUS-265
 */

@isTest
public class D1_CaseTriggerHelperTest {
    @testSetup
    public static void setup(){
        Account outletAccount = D1_TestDataUtility.getD1Customer();
        outletAccount.Direct_Customer__c = false;

        D1_TestDataUtility.setUpExternalUser(outletAccount,'Direct Buyer');

        Id contractRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		Contract conRec = D1_TestDataUtility.getContract(outletAccount.Id, contractRecTypeId);
        insert conRec;
    }
    
    @isTest
    public static void createTestData(){
        Account accountId = [Select Id from Account limit 1];
        List<PNR_Partner_Function__c> ptrfunRac = [SELECT Id, PNR_Sales_Org__c, PNR_Sold_To__c
                                                            FROM PNR_Partner_Function__c 
                                                            WHERE PNR_Type__c = 'Sold-To' AND PNR_Sold_To__c =: accountId.Id];
        
        Contact primcon1=new Contact(FirstName='fname2',
                                         LastName = 'lname1',
                                         Email = 'testclassextuser2@testdomain.com',
                                         Phone = '12345672891',Contact_Type__c='Secondary',AccountID=accountId.Id); 
        insert primcon1;

        accountId.Account_Type__c ='Ship-To';
        Update accountId;
        
        ptrfunRac[0].PNR_Customer_No__c = accountId.Id;
        update ptrfunRac[0];

        Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();
        
        D1_TestDataUtility.createOrgSettings();
        Case caseRecd = D1_TestDataUtility.createCase(caseRecTypeId,'Quality Issues', 'Equipment Fault', 'Testing Description', 'Open');
        caseRecd.accountId = ptrfunRac[0].PNR_Sold_To__c;
        caseRecd.ContactId = primcon1.Id;
        caseRecd.Origin = 'Diageo One';
        insert caseRecd;

        system.assert(caseRecd.Id != null, 'case record not found');
        
        caseRecd.Subject = 'Testing2 Subject';
        caseRecd.Status  = 'Closed';
        update caseRecd;
        
        delete caseRecd;
        
        undelete caseRecd;
        
        Contract conRecd = [Select Id,ContractNumber from Contract limit 1];
        
        Case newCaseRecd = D1_TestDataUtility.createCase(caseRecTypeId,'Contracts', 'Contract terms', 'Testing Description', 'Open');
        newCaseRecd.accountId = ptrfunRac[0].PNR_Sold_To__c;
        newCaseRecd.ContactId = primcon1.Id;
        newCaseRecd.D1_Contract_Number__c = conRecd.ContractNumber;
        newCaseRecd.Origin = 'Diageo One';
        insert newCaseRecd;
    }

    @isTest
    public static void c360TestMethod(){
        Profile prof = [select id from profile where name= 'System Administrator'];
        PermissionSet mockedPermissionSetId = [Select id,name from PermissionSet Where Name='C360_Logistics_Team'];
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE;NIR;GB';
        insert usr;
        
        insert new PermissionSetAssignment(AssigneeId=usr.Id, PermissionSetId=mockedPermissionSetId.Id);
        
        System.runAs(usr){
            Account accountId = [Select Id,Country__c,Country_Code__c from Account limit 1 ];
            Geography__c country = [SELECT Id,Code__c FROM Geography__c where Id =:accountId.Country__c Limit 1];
            country.Code__c = 'IE';
            update country;
            
            List<PNR_Partner_Function__c> ptrfunRac = [SELECT Id, PNR_Sales_Org__c, PNR_Sold_To__c
                                                       FROM PNR_Partner_Function__c 
                                                       WHERE PNR_Type__c = 'Sold-To' AND PNR_Sold_To__c =: accountId.Id];
            
            Contact primcon1=new Contact(FirstName='fname2',
                                         LastName = 'lname1',
                                         Email = 'testclassextuser2@testdomain.com',
                                         Phone = '12345672891',Contact_Type__c='Secondary',AccountID=accountId.Id); 
            insert primcon1;

            accountId.Account_Type__c ='Ship-To';
            Update accountId;
            
            ptrfunRac[0].PNR_Customer_No__c = accountId.Id;
            update ptrfunRac[0];    
            
            Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();
            
            D1_TestDataUtility.createOrgSettings();
            Case caseRecd = D1_TestDataUtility.createCase(caseRecTypeId,'Quality Issues', 'Equipment Fault', 'Testing Description', 'Open');
            caseRecd.accountId = ptrfunRac[0].PNR_Sold_To__c;
            caseRecd.ContactId = primcon1.Id;
            caseRecd.Origin = 'Diageo One';
            caseRecd.OwnerId = usr.Id;
            insert caseRecd;
            
            system.assert(caseRecd.Id != null, 'case record not found');

            try{
                caseRecd.Type_of_Communication__c = 'Phone Call';
                update caseRecd;
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
    }

    @isTest
    public static void c360TestMethod1(){
        List<User> userList = new List<User>();
        Profile prof = [select id from profile where name= 'System Administrator'];
        PermissionSet mockedPermissionSetId = [Select id,name from PermissionSet Where Name='C360_Customer_Services_Team'];
        PermissionSetGroup mockedPermissionSetGroupId = [Select id,DeveloperName,status from PermissionSetGroup Where DeveloperName='C360_Case_Management_Service_Team'];
        
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE;NIR;GB';
        //insert usr;
        userList.add(usr);
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof.id;        
        usr1.email = 'test.MamagerSfdc12@test.com';
        usr1.Username ='test.MamagerSfdc12@test.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='IE;NIR;GB';
        //insert usr1;
        userList.add(usr1);
        insert userList;
        if (mockedPermissionSetGroupId.Status != 'Updated') {
      		Test.calculatePermissionSetGroup(mockedPermissionSetGroupId.Id);
    	}
        
        insert new PermissionSetAssignment(AssigneeId=userList[0].Id, PermissionSetId=mockedPermissionSetId.Id);
        insert new PermissionSetAssignment(AssigneeId=userList[0].Id, PermissionSetGroupId=mockedPermissionSetGroupId.Id);
        insert new PermissionSetAssignment(AssigneeId=userList[1].Id, PermissionSetGroupId=mockedPermissionSetGroupId.Id);
        
        System.runAs(userList[0]){
            
            Account accountId = [Select Id,Country__c,Country_Code__c from Account limit 1 ];
            Geography__c country = [SELECT Id,Code__c FROM Geography__c where Id =:accountId.Country__c Limit 1];
            country.Code__c = 'IE';
            update country;
            
            List<PNR_Partner_Function__c> ptrfunRac = [SELECT Id, PNR_Sales_Org__c, PNR_Sold_To__c
                                                       FROM PNR_Partner_Function__c 
                                                       WHERE PNR_Type__c = 'Sold-To' AND PNR_Sold_To__c =: accountId.Id];
            
            Contact primcon1=new Contact(FirstName='fname2',
                                         LastName = 'lname1',
                                         Email = 'testclassextuser2@testdomain.com',
                                         Phone = '12345672891',Contact_Type__c='Secondary',AccountID=accountId.Id); 
            insert primcon1;

            accountId.Account_Type__c ='Ship-To';
            update accountId;
            
            ptrfunRac[0].PNR_Customer_No__c = accountId.Id;
            update ptrfunRac[0];    
            
            Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();
            
            List<Case> caseList = new List<Case>();
            D1_TestDataUtility.createOrgSettings();
            Case caseRecd = D1_TestDataUtility.createCase(caseRecTypeId,'Quality Issues', 'Equipment Fault', 'Testing Description', 'Closed');
            caseRecd.accountId = ptrfunRac[0].PNR_Sold_To__c;
            caseRecd.ContactId = primcon1.Id;
            caseRecd.Origin = 'Diageo One';
            caseRecd.OwnerId = userList[0].Id;
            caseRecd.C360_Case_Agent__c = userList[1].Id;
            //insert caseRecd;
            caseList.add(caseRecd);
			Test.startTest();
            Case caseRecd1 = D1_TestDataUtility.createCase(caseRecTypeId,'Quality Issues', 'Equipment Fault', 'Testing Description', 'Open');
            caseRecd1.accountId = ptrfunRac[0].PNR_Sold_To__c;
            caseRecd1.ContactId = primcon1.Id;
            caseRecd1.Origin = 'Diageo One';
            caseRecd1.OwnerId = userList[0].Id;
            //insert caseRecd1;
            caseList.add(caseRecd1);
            insert caseList;
            system.assert(caseList[0].Id != null, 'case record not found');

            caseList[1].Type_of_Communication__c = 'Phone Call';
            caseList[1].Status = 'Closed';
            update caseList[1];
            
            try{
                caseList[0].Type_of_Communication__c = 'Phone Call';
                update caseList[0];
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        Test.stopTest();
        }
    }

    @isTest
    public static void c360TestMethod2(){
        Profile prof = [select id from profile where name= 'System Administrator'];
        PermissionSetGroup mockedPermissionSetGroupId = [Select id,DeveloperName,status from PermissionSetGroup Where DeveloperName='C360_Case_Management_Admin'];
        PermissionSetGroup mockedPermissionSetGroupId1 = [Select id,DeveloperName,status from PermissionSetGroup Where DeveloperName='C360_Case_Management_Service_Team'];

        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test.MamagerSfdc1@test.com';
        usr.Username ='test.MamagerSfdc1@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='IE;NIR;GB';
        insert usr;
        
        User usr1 = new User();
        usr1.firstName = 'test1';
        usr1.lastName = 'test2';
        usr1.profileId = prof.id;        
        usr1.email = 'test.MamagerSfdc12@test.com';
        usr1.Username ='test.MamagerSfdc12@test.com';
        usr1.Alias='test';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='IE;NIR;GB';
        insert usr1;
        
        if (mockedPermissionSetGroupId.Status != 'Updated') {
      		Test.calculatePermissionSetGroup(mockedPermissionSetGroupId.Id);
    	}
        if (mockedPermissionSetGroupId1.Status != 'Updated') {
      		Test.calculatePermissionSetGroup(mockedPermissionSetGroupId1.Id);
    	}
        insert new PermissionSetAssignment(AssigneeId=usr.Id, PermissionSetGroupId=mockedPermissionSetGroupId.Id);
        insert new PermissionSetAssignment(AssigneeId=usr1.Id, PermissionSetGroupId=mockedPermissionSetGroupId.Id);
        insert new PermissionSetAssignment(AssigneeId=usr1.Id, PermissionSetGroupId=mockedPermissionSetGroupId1.Id);
        
        System.runAs(usr){
            Account accountId = [Select Id,Country__c,Country_Code__c from Account limit 1 ];
            Geography__c country = [SELECT Id,Code__c FROM Geography__c where Id =:accountId.Country__c Limit 1];
            country.Code__c = 'IE';
            update country;
            
            List<PNR_Partner_Function__c> ptrfunRac = [SELECT Id, PNR_Sales_Org__c, PNR_Sold_To__c
                                                       FROM PNR_Partner_Function__c 
                                                       WHERE PNR_Type__c = 'Sold-To' AND PNR_Sold_To__c =: accountId.Id];
            
            Contact primcon1=new Contact(FirstName='fname2',
                                         LastName = 'lname1',
                                         Email = 'testclassextuser2@testdomain.com',
                                         Phone = '12345672891',Contact_Type__c='Secondary',AccountID=accountId.Id); 
            insert primcon1;

            accountId.Account_Type__c ='Ship-To';
            Update accountId;

            ptrfunRac[0].PNR_Customer_No__c = accountId.Id;
            Update ptrfunRac[0];   

            Map <String,Schema.RecordTypeInfo> mapAccountRecordTypes = Case.sObjectType.getDescribe().getRecordTypeInfosByName();
            Id caseRecTypeId = mapAccountRecordTypes.get('Diageo One Cases').getRecordTypeId();
            
            D1_TestDataUtility.createOrgSettings();
            Case caseRecd = D1_TestDataUtility.createCase(caseRecTypeId,'Quality Issues', 'Equipment Fault', 'Testing Description', 'Closed');
            caseRecd.accountId = ptrfunRac[0].PNR_Sold_To__c;
            caseRecd.ContactId = primcon1.Id;
            caseRecd.Origin = 'Diageo One';
            insert caseRecd;

            system.assert(caseRecd.Id != null, 'case record not found');
            
            //Test.startTest();
            Case caseRecd1 = D1_TestDataUtility.createCase(caseRecTypeId,'Quality Issues', 'Equipment Fault', 'Testing Description', 'Open');
            caseRecd1.accountId = ptrfunRac[0].PNR_Sold_To__c;
            caseRecd1.ContactId = primcon1.Id;
            caseRecd1.Origin = 'Diageo One';
            caseRecd1.OwnerId = usr.Id;
            insert caseRecd1;
			Test.startTest();
            caseRecd1.Contacted_Date__c = System.today().addDays(1);
            caseRecd1.Type_of_Communication__c = 'Phone Call';
            caseRecd1.Status = 'Closed';
            caseRecd1.C360_Case_Agent__c = usr1.Id;
            update caseRecd1;
            
            caseRecd1.Status = 'Re-Opened';
            update caseRecd1;
            
            try{
                caseRecd1.C360_Case_Agent__c = usr.Id;
                update caseRecd1;
            }catch(Exception ex){
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
            Test.stopTest();
        }
    }
    
}