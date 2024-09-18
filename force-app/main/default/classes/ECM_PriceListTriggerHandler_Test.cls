/*
*Name: ECM_PriceListTriggerHandler_Test

*Purpose: This class is used to cover test data for the - ECM_PriceListTriggerHandler

*History                                                            
                                                            
*VERSION    AUTHOR         DATE              DETAIL
1.0		 Pravalika    08/12/2020		Initial Development

*/
@isTest
public class ECM_PriceListTriggerHandler_Test {
    
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
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        ECM_Price_List__c ecmPL1 = new ECM_Price_List__c();
        ecmPL1.ECM_Geography__c = geographyId;      
        ecmPL1.ECM_Active__c = true;
        ecmPL1.Name = 'ES PriceList';
        ecmPL1.ECM_Start_Date__c = system.today()-1;
        ecmPL1.ECM_End_Date__c = system.today()+1;
        insert ecmPL1;
        system.assert(ecmPL1.Id != null,'ecmPL1 Id should not be null');
        
        ecmPL1.ECM_Geography__c = geographyId1;
        update ecmPL1;
        
        Test.stopTest();
    }
    
}