/*
@ Name: RangingBounusDetailsTriggerTest

@ Description: This is the test class for RangingBonusDetailsTrigger,RangingBonusDetailsTriggerHandler,RangingBonusDetailsHelper

@ History:                                                            

VERSION       AUTHOR               DATE              DETAIL
1.0           Sagnik Sanyal        04/09/2024        156151 - Enable Country based Sharing _SFDC  
*/

@isTest
public with sharing class RangingBounusDetailsTriggerTest {
    

    
    /*
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    */
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
         //Creating Ranging Bonus Details record
        List<Ranging_Bonus_Details__c> rangingBonusList = new List<Ranging_Bonus_Details__c>();
        Ranging_Bonus_Details__c  rangingBonus1 = new Ranging_Bonus_Details__c();
        rangingBonus1.Country__c = countryId;
        rangingBonus1.Product_Sub_Category__c = 'Ale';
        insert rangingBonus1;
        system.assert(rangingBonus1.Id != null,'rangingbonus cannot be null');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        rangingBonus1.Country__c = secCountry.Id;
        update rangingBonus1;        
        delete rangingBonus1;
        undelete rangingBonus1;
        rangingBonusList.add(rangingBonus1);
        Test.stopTest();
    }
}