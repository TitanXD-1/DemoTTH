/*
* @name: D1_SupportRequestListControllerTest
* @discription: Test Class for D1_SupportRequestListController
* @history
* VERSION       AUTHOR              DATE            DETAIL
* 1.0           Gaurav              29/5/2022      CreateCase
*/
@isTest
public class D1_SupportRequestListControllerTest {
    
    @testSetup
    static void makeData(){  

        Id countryId = D1_TestDataUtility.setupCountry('GB');
        Geography__c country = [SELECT Id FROM Geography__c WHERE Id = :countryId];
        
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test[GB]'); 
        pickupOption = D1_TestDataUtility.getPickUpOption(country.Id,'Outlet Prioritization','Outlet Visit Prioritization','Test[GB]'); 
        Account outletAccount = D1_TestDataUtility.getD1Customer();//outlet record
        outletAccount.Direct_Customer__c = false;
        
        D1_TestDataUtility.setUpExternalUser(outletAccount,'Outlet/Retailers');
                
        D1_User_Type__c userType = [SELECT Id,Tax_Identification_Number__c FROM D1_User_Type__c limit 1];
        userType.Tax_Identification_Number__c = '';
        update userType;
        
        Test.startTest();
        
        String recordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        String recordTypeQualityId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        
        //Create case with parameters RecordTypeId, Type, D1_Subject__c, Description and Status respectively.
        Case cs1 = D1_TestDataUtility.createCase(recordTypeId,'Account Management','My Profile','Test Comments','Open');
        Case cs2 = D1_TestDataUtility.createCase(recordTypeQualityId,'Account Management','My Profile','Test Comments','Open');
        cs1.AccountId = outletAccount.Id;
        cs2.AccountId = outletAccount.Id;
        cs1.Origin = 'Diageo One';
        cs2.Origin = 'Diageo One';
        insert new List<Case>{cs1,cs2};
        Test.stopTest();

    }


    @isTest
    public static void getRequestListTest(){
        
        User externalUserTest= [Select id from User where Email ='testclassextuser1@testdomain.com' limit 1];        
        system.runAs(externalUserTest){ 
            Map<String,Object> result1 = new Map<String,Object>();
            Map<String,Object> result2 = new Map<String,Object>();
            Map<String,Object> result3 = new Map<String,Object>();
            Map<String,Object> result4 = new Map<String,Object>();

            Test.startTest();
            result1 = D1_SupportRequestListController.getRequestList('All', false, 'In-Direct','');
            result2 = D1_SupportRequestListController.getRequestList('Customer Service', false, 'In-Direct','');
            result3 = D1_SupportRequestListController.getRequestList('Diageo One', false, 'In-Direct','');
            result4 = D1_SupportRequestListController.getRequestList('Related Queries', false, 'In-Direct','');
            Test.stopTest();

            System.assert(result1 != NULL, 'request list not found');
            System.assert(result2 != NULL, 'request list not found');
            System.assert(result3 != NULL, 'request list not found');
            System.assert(result4 != NULL, 'request list not found');

        }

    }

}