/*
@Name: ECM_DepletionsTriggerHandler_Test
@Purpose: Class with all handler methods of DepletionsTrigger.
@History                                                                                                                      
@VERSION  	AUTHOR              DATE              	DETAIL
1.0        	Pravlika           	07/12/2020      	Initial Development
2.0			Nidhi && Sagnik		27/10/2022			ECM-6256 to populate country from account's country
2.1			Saurav Prasad		14/07/2023			142555	: CM static code violation for the classes_SFDC_Technical Debt
*/
@isTest
public class ECM_DepletionsTriggerHandler_Test {
    
    @testSetup static void setup() {
        Test.startTest();
        
        Profile prof = [select id from profile where name=: 'Master Data Manager'];
        User usr = new User();
        usr.firstName = 'test1';
        usr.lastName = 'test2';
        usr.profileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm123@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='ES';
        usr.Title='Legal';
        insert usr;
        
        User usr1 = new User();
        usr1.firstName = 'test11';
        usr1.lastName = 'test21';
        usr1.profileId = prof.id;        
        usr1.email = 'test1@test.com';
        usr1.Username ='testcm1231@test.com';
        usr1.Alias='test1';
        usr1.Timezonesidkey='America/Los_Angeles';
        usr1.LocaleSidKey='en_US';
        usr1.LanguageLocaleKey='en_US';
        usr1.EmailEncodingKey='UTF-8';
        usr1.Available_Countries__c='AU';
        usr1.Title='Legal';
        insert usr1;
        
        Test.stopTest();
    }
    @isTest
    public static void testdata(){
        Test.startTest();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        //Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='LI[ES]';
        insert pOption;
        
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        acc.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;  
        insert acc;
        
        Depletions__c ecmDep = new Depletions__c();  
        ecmDep.ECM_Outlet__c = Acc.Id;    
        ecmDep.ECM_Volume__c = 100.00;
        ecmDep.ECM_Start_Period__c = system.today()-1;
        ecmDep.ECM_End_Period__c = system.today()+1;
        insert ecmDep;
        
        Account a = [SELECT id,Country__c From Account where Name =: 'Test_Outlet'];
        
        Depletions__C d = [SELECT id, ECM_Geography__c from Depletions__C Where ECM_Outlet__c =: A.id];
        system.assertEquals(A.Country__c, d.ECM_Geography__c,'Expected');
        Assert.areEqual(A.Country__c, d.ECM_Geography__c,'Expected');
        Test.stopTest();
    }
     @isTest
    public static void testdata1(){
        Test.startTest();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        
        Depletions__c ecmDep = new Depletions__c();
        ecmDep.ECM_Geography__c = geographyId;      
        ecmDep.ECM_Volume__c = 100.00;
        ecmDep.ECM_Start_Period__c = system.today()-1;
        ecmDep.ECM_End_Period__c = system.today()+1;
        insert ecmDep;
        
        ecmDep.ECM_Geography__c = geographyId1;
        update ecmDep;

        system.assertEquals(ecmDep.ECM_Geography__c, geographyId1,'Expected');
        Assert.areEqual(ecmDep.ECM_Geography__c, geographyId1,'Expected');
        Test.stopTest();
    }
    
}