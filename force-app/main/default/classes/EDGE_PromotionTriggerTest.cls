/**********************************************************************
Name: EDGE_PromotionTriggerTest
=======================================================================
Req: This is the test class for PromotionTrigger,PromotionTriggerHandler,
EDGE_PromotionTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0   Monalisa Halder     20/03/2019      Initial Development
2.0   Swaraj Samanta      05/09/2022      Test Class Correction due to Failure(ES20-13284)
***********************************************************************/
@isTest
public with sharing class EDGE_PromotionTriggerTest {
    
    /*******************************************************************
    Method  : checkPromotionTimeFrameUpdateTest
    Purpose : Test method for checkPromotionCycle
    ********************************************************************/
  
    @isTest
    public static void checkPromotionTimeFrameUpdateTest(){
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT'); 
        Account disAccrec = EDGE_UtilityTestClass.getDistriAccRec();
        insert disAccrec;
        System.assert(disAccrec.Id != null);
        List<Promotion__c> promotions=new List<Promotion__c>();
        Promotion__c promotion = EDGE_UtilityTestClass.getPromotionRecord(geographyId );
        promotions.add(promotion);
        //system.assert(promotion.Id != null);
        
        Promotion__c promotion1 = EDGE_UtilityTestClass.getPromotionRecord(geographyId );
        promotion1.Start_Date__c = System.today().addDays(7);
        promotion1.Expiration_Date__c = System.today().addDays(10);
        promotions.add(promotion1);
        
        Promotion__c promotion2 = EDGE_UtilityTestClass.getPromotionRecord(geographyId );
        promotion2.Start_Date__c = System.today().addDays(7);
        promotion2.Expiration_Date__c = System.today().addDays(10);
        promotions.add(promotion2);
        insert promotions;
        delete promotion2;
        Test.startTest();
        List<Account_Promotion__c> accountPromotions=new List<Account_Promotion__c>();
        Account_Promotion__c accPromo = EDGE_UtilityTestClass.getAccountPromotion(disAccrec.Id, promotion.Id);
        accountPromotions.add(accPromo);
        
        
        Account_Promotion__c accPromo1 = EDGE_UtilityTestClass.getAccountPromotion(disAccrec.Id, promotion1.Id);
         accountPromotions.add(accPromo1);
        insert accountPromotions;
        system.assert(accPromo1.Id != null);
        
        
        try{
            promotion1.Start_Date__c = System.today().addDays(-5);
            update promotion1;
        }catch(Exception ex){
            //Checking one Promotion time frame Validation Rule
            System.Assert(ex.getMessage().contains(Label.PromotionTimeFrame));
        }
        Test.stopTest();
        
    }
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
         //Creating Promotion Record
        Promotion__c promotion = EDGE_UtilityTestClass.getPromotionRecord(countryId);
        insert promotion;
        system.assert(promotion.Id != null);
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        promotion.Country__c = secCountry.Id;
        update promotion;        
        delete promotion;
        undelete promotion;
        Test.stopTest();
    }

  
}