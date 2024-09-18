/*
* @Name: C360_MilestoneTimeCalculatorTest
* @description: This is Test Class for C360_MilestoneTimeCalculator
* @History                                                            

VERSION			AUTHOR					DATE					DETAIL
1.0			Swagat Shaw			07/31/2023				Test Class for C360_MilestoneTimeCalculator
*/ 
@isTest
public class C360_MilestoneTimeCalculatorTest {
    @testSetup
    public static void setup(){
        D1_TestDataUtility.setupCountry('GB');
        Account outletAccount = D1_TestDataUtility.getD1Customer();
        outletAccount.Direct_Customer__c = false;      
        

        D1_TestDataUtility.setUpExternalUser(outletAccount,'Outlet/Retailers');
        Id contractRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		Contract conRec = D1_TestDataUtility.getContract(outletAccount.Id, contractRecTypeId);
        insert conRec;
        
    }
    
    @isTest
    public static void c360TestMethod(){
    Profile prof = [select id from profile where name= 'System Administrator'];
        PermissionSet mockedPermissionSetId = [Select id,name from PermissionSet Where Name='C360_Customer_Services_Team'];
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
        System.assert(usr1 != NULL, 'User not found');
        
        insert new PermissionSetAssignment(AssigneeId=usr.Id,
                                           PermissionSetId=mockedPermissionSetId.Id);
        
        System.runAs(usr1){
            usr.C360_Customer_360_User__c = true;
            update usr;
        }
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
            caseRecd.OwnerId = usr.Id;
            insert caseRecd;
			System.assert(caseRecd != NULL, 'Case record not found');
            
            String milestoneName ='';
            
            for(Customer_360_Entitlement_Setting__mdt mdt:Customer_360_Entitlement_Setting__mdt.getAll().values()){
                milestoneName = mdt.C360_Milestone_Name__c;
            }
            MilestoneType mt = new MilestoneType();
            mt = [SELECT Id,Name,Description FROM MilestoneType WHERE Name=:milestoneName];
            
            C360_MilestoneTimeCalculator newInstance = new C360_MilestoneTimeCalculator();
            newInstance.calculateMilestoneTriggerTime(caseRecd.Id, mt.Id);
        }
    }
}