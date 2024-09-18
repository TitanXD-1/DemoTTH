/**********************************************************************
Name: ECM_volumeInputController_Test
=======================================================================
Purpose: This Class is test class for ECM_volumeInputController class.
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                    		 DATE              DETAIL
1.0      Chandrakanth Suram               22/04/2021        Initial Development
2.0      Joshraj Sen                      14/05/2024        PMD Fix
3.0      Joshraj Sen                      11/06/2024        PMD Fix
***********************************************************************/
@isTest
/**
 * @description Test Class for ECM_volumeInputController
 */
public class ECM_volumeInputController_Test {
   @isTest
    public static void dataSetup(){
        Profile prof = [select id from profile where name=: 'Sales Representative'];
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
        insert usr;
        System.assert(usr!=null,'User is Added');
        System.runAs(usr){
            Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
            Territory__c testterritory=New Territory__c();
            testterritory.Name='Testterriotory';
            testterritory.Territory_Type__c='Sales';
            testterritory.Country__c= geographyId;
            testterritory.Status__c='Active';
            testterritory.Primary_Sales_Rep__c = usr.id;
            insert testterritory;
            
            Territory_Hierarchy__c hirarchy= ECM_UtilityTestClass.createhirarchy(geographyId);
            hirarchy.recordtypeId=Schema.SObjectType.Territory_Hierarchy__c.getRecordTypeInfosByName().get('Region').getRecordTypeId();
            insert hirarchy;
            
            testterritory.Primary_Sales_Rep__c = usr.id;
            testterritory.Country__c= geographyId;
            testterritory.Region__c=hirarchy.Id;
            update testterritory;
            
            
            ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
            contractType.Name='Promotional';
            contractType.Geography__c=geographyId;
            contractType.ECM_Abbreviation__c='POM';
            contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
            contractType.Volume_UoM_for_Spirits__c='CAS';
            contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;Volume Target;Investment';
            contractType.ECM_Volume_UoM_for_Beer__c='KEG';
            insert contractType;
            
            Market_Setting__c mktSetting =EDGE_UtilityTestClass.getMarketSetting(geographyId);
            insert mktSetting;
            mktSetting.Depletion_market__c=false;
            update mktSetting;
            
            String bannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        	String budgetTypeRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Budget Type').getRecordTypeId();
        
            Pick_Up_Options__c banner= new Pick_Up_Options__c();
            banner.Name='Range[ES]';
            banner.Geography__c=geographyId;
            banner.RecordTypeId=bannerRecordTypeId;
            insert banner;
            
            Pick_Up_Options__c budgetType= new Pick_Up_Options__c();
            budgetType.Name='TI[ES]';
            budgetType.Geography__c=geographyId;
            budgetType.RecordTypeId=budgetTypeRecordTypeId;
            insert budgetType;
            
            String accRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId(); 
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Name = 'Test_Outlet';
            outlet.RecordTypeId = accRecordTypeId;
            outlet.BillingStreet = '17 Asian Highway 45';
            outlet.BillingCity = 'Sydney';
            outlet.IsOperator__c=true;
            outlet.BillingState = 'Tasmania';
            outlet.BillingPostalCode = '5668';
            outlet.BillingCountry = 'Australia';
            outlet.BillingCountryCode = 'AU';
            outlet.Outlet_Email_Address__c = 'test@test.com';
            outlet.Global_Channel__c = 'Off Trade';
            outlet.Global_Sub_Channel__c = 'Retailer';
            outlet.Global_Segment__c = 'Hypermarket';
            outlet.Global_Sub_Segment__c = 'Modern Hypermarket';
            outlet.Status__c= 'Active';
            insert outlet; 
            outlet.country__c = geographyId;
            update outlet;
            
            
            ECM_Payment_Frequency__c paymfreq = new ECM_Payment_Frequency__c();
            paymfreq.ECM_Type__c='Partial Prepayment';
            paymfreq.ECM_Other_Investment__c=true;
            paymfreq.ECM_Volume_target__c=true;
            //paymfreq.ECM_Number_of_months_for_recurrence__c='20';
            paymfreq.ECM_Prepayment__c=true;
            paymfreq.ECM_Geography__c=geographyId;
            Insert paymfreq;
            
            String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
            
            Contract objContract = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
            objContract.Status = 'Draft';
            objContract.Contract_End_Date__c = System.today().adddays(365);
            objContract.AccountId=outlet.Id;
            objContract.ECM_Territory__c=testterritory.Id;
            objContract.ECM_Agreement_Type__c=contractType.Id;
            objContract.recordTypeId=contractRecordTypeId;
            objContract.ECM_Channel__c='On-Premise';
            objContract.ECM_Banner__c=banner.Id;
            objContract.StartDate = system.today();
            objContract.ECM_Payment_Frequency_type__c =paymfreq.Id;
            insert objContract;
            objContract.Status ='Active';
            update objContract;
            
            Test.startTest();
            	ECM_volumeInputController.contractValues(objContract.id);
           		ECM_volumeInputController.getVolumeInputAccess(objContract.id);
            Test.stopTest();
        }
    }
}