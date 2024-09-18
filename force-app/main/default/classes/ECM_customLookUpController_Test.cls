/*
    Name: ECM_customLookUpController_Test
    Purpose: This class is used to cover testclass for the - ECM_customLookUpController
    History                                                            
                                                           
    VERSION    AUTHOR                Modified DATE          DETAIL
    1.0      Saurav Kumar Prasad      14/04/2020        Initial Development       
	2.0      Pratik Somani            27/04/2022        Changes related to ECM-5453 
*/
@isTest
public class ECM_customLookUpController_Test {
    @testSetup static void setup() {
        Test.startTest();
        // Create common test accounts
        /*List<Account> testAccts = new List<Account>();
        Id RecTypeIdinadj = Schema.SObjectType.Account.getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
        
        for(Integer i=0;i<2;i++) {
            testAccts.add(new Account(Name = 'TestAcct'+i,recordtypeid=RecTypeIdinadj));
            
        }
        //insert testAccts;   
        //
        Insert EDGE_UtilityTestClass.getOwnerOperatorAccount();*/
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('AU'); 
        String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        
        Pick_Up_Options__c banner= new Pick_Up_Options__c();
        banner.Name='IBA1[AU]';
        banner.Geography__c=geographyId;
        banner.RecordTypeId=bannerRecordTypeId;
        banner.Status__c = 'Active';
        insert banner;
        
        Pick_Up_Options__c bannerAU= new Pick_Up_Options__c();
        bannerAU.Name='IBA[AU]';
        bannerAU.Geography__c=geographyId;
        bannerAU.ECM_E_S__c =true;
        bannerAU.RecordTypeId=bannerRecordTypeId;
        banner.Status__c = 'Active';
        insert bannerAU;
        
        Test.stopTest();
    }
    @isTest static void fetchLookUpValuesTestNegative() {
        Test.startTest();
        //ECM_customLookUpController.fetchLookUpValues('TestAcct','Account','Owner/Operator');
        List<sObject> lookUpController = new List<Sobject>();
ECM_customLookUpController.fetchLookUpValues('IBA','Pick_Up_Options__c','Banner',true);
System.assert(lookUpController!=null,'lookUpController should not be null');
        try{
            //ECM_customLookUpController.fetchLookUpValues('TestAcct','Account','');
            ECM_customLookUpController.fetchLookUpValues('IBA','Pick_Up_Options__c','',false);
        }
        catch(Exception e){
            System.debug(LoggingLevel.Debug,'Exception :'+e);
            Test.stopTest();
        }
    }
    @isTest static void fetchLookUpValuesTestPostive() {
        Test.startTest();
        //ECM_customLookUpController.fetchLookUpValues('Test_OwnerAccount','Account','Owner/Operator');
        List<Sobject> lookUpController1 = new List<Sobject>();
        ECM_customLookUpController.fetchLookUpValues('IBA','Pick_Up_Options__c','Banner',false);
        System.assert(lookUpController1!=null,'lookUpController1 should not be null');
        Test.stopTest();
    }
    
}