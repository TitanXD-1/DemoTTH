/**********************************************************************
Name: ECM_TemplateAgreementTriggerHandler_Test
=======================================================================
Purpose: This class is used to cover test data for the - 
ECM_TemplateAgreementTriggerHandler
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR         		DATE              DETAIL
1.0		 Saurav Prasad  	 21/12/2020		 Initial Development

***********************************************************************/
@isTest
public class ECM_TemplateAgreementTriggerHandler_Test {
    
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
    public static void dataTest(){
        Test.startTest();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES'); 
        Id geographyId1 = EDGE_UtilityTestClass.setupCountry('AU'); 
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        insert contractType;
        
        ECM_Template_Agreement__c tempAgree= new ECM_Template_Agreement__c();
        tempAgree.ECM_Title__c='Template agreement TITLE';
        tempAgree.ECM_Description__c='Template Agreement Description';
        tempAgree.ECM_Status__c='Active';
        tempAgree.ECM_Apply_Auto_Numbering__c = true;
        tempAgree.ECM_Agreement_Type__c=contractType.Id;
        tempAgree.ECM_Geography__c=geographyId;
        Insert tempAgree;

        System.assertEquals(geographyId, tempAgree.ECM_Geography__c,'Positive Scenario');
        
        tempAgree.ECM_Geography__c=geographyId1;
        Update tempAgree;
        
        System.assertNotEquals(geographyId, tempAgree.ECM_Geography__c,'Negative Scenario');
        Test.stopTest();
    }
    
}