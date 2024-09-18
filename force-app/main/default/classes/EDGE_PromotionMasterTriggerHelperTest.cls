/**
* @name EDGE_PromotionMasterTriggerHelperTest
* @purpose - This is a test class to cover EDGE_PromotionMasterTriggerHelper
* @history
* Version              Author                   Date            Detail
   1.0              Mayukh/Geethika           17/06/2022      ES20-12989 - Initial Development

**/


@isTest
public class EDGE_PromotionMasterTriggerHelperTest {
    public static Date todays = Date.today();
    public static Id FreeProductRecordTypeId = Promotion_Master__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Free Product').getRecordTypeId();
@isTest
    public static void testCaseConfiguration(){
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        
        insert testAdminUser;
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU');
        
          Test.startTest();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        system.assert(pickupOption.Id != null);
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert outlet;
        system.assert(outlet.Id != null);
        
        
        Promotion_Master__c pmObj = new Promotion_Master__c();
        pmObj.Name = 'Promotion Master 1';
        pmObj.Description__c = 'Promo Desc';
        pmObj.Start_Date__c = todays.addDays(-4);
        pmObj.End_Date__c = todays.addDays(10);
        pmObj.Total_Order_quantity_for_Free_Product__c = 20;
        pmObj.RecordTypeId = FreeProductRecordTypeId;
        insert pmObj;  
        
        
       // update pmObj;        
        
        system.assert(pmObj.Id != null);
        Test.stopTest();
    }

    @isTest
    public static void checkSharingTest(){
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Promotion_Master__c pmObj = new Promotion_Master__c();
        pmObj.Name = 'Promotion Master 1';
        pmObj.Description__c = 'Promo Desc';
        pmObj.Start_Date__c = todays.addDays(-4);
        pmObj.End_Date__c = todays.addDays(10);
        pmObj.Total_Order_quantity_for_Free_Product__c = 20;
        pmObj.RecordTypeId = FreeProductRecordTypeId;
        insert pmObj;  
       
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        pmObj.Country__c = secCountry.Id;
               
        update pmObj;        
        system.assert(pmObj.Id != null);  
        delete pmObj;
        undelete pmObj;
        Test.stopTest();
    }
}