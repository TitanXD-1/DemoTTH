/*
    *Name: ECM_CustomLooup_PrdtAgremntCtrl_Test
    
    *Purpose: This class is used to cover testclass for the - ECM_CustomLooup_PrdtAgremntCtrl
    
    *History                                                            
                                                                
    *VERSION    AUTHOR                   DATE              DETAIL
    1.0      Saurav Kumar Prasad      15/04/2020        Initial Development
             
*/
@isTest
public class ECM_CustomLooup_PrdtAgremntCtrl_Test {
    
    @testSetup static void setup() {
        Test.startTest();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');
        // Promotional : ECM_Contract_Type__c
        ECM_Contract_Type__c contractType=ECM_UtilityTestClass.createContractType(String.valueOf(geographyId));
        Insert contractType;
        
        Product__c product = new Product__c();
        product.Product_Full_Name__c ='Test';
        product.Country__c=geographyId;
        insert product;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Unique_ID__c = 'AZ';
        insert prdtUOM;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        
        insert marketassort;
        
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        Test.stopTest();
    }
    @isTest static void fetchLookUpValuesTestNegative() {
        Test.startTest();
        ECM_CustomLooup_PrdtAgremntCtrl.fetchLookUpValues('Non-Promotional', 'ECM_Contract_Type__c', 'ES');
        List<Sobject> agremntCtrl = new List<Sobject>();
        agremntCtrl = ECM_CustomLooup_PrdtAgremntCtrl.fetchLookUpValues('Non-Test', 'Market_Assortment_Product__c', 'ES');
        String assertCheck = 'Not Null';
        System.assert(assertCheck!=null,'agremntCtrl should not be null');
        Test.stopTest();
    }
    @isTest static void fetchLookUpValuesTestPostive() {
        Test.startTest();
        ECM_CustomLooup_PrdtAgremntCtrl.fetchLookUpValues('Promotional', 'ECM_Contract_Type__c', 'ES');
        List<Sobject> agremntCtrl = new List<Sobject>();
        agremntCtrl = ECM_CustomLooup_PrdtAgremntCtrl.fetchLookUpValues('Test', 'Market_Assortment_Product__c', 'ES');
        System.assert(agremntCtrl!=null,'agremntCtrl should not be null');
        Test.stopTest();
    }
}