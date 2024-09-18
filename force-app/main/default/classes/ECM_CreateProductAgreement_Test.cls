/*
    Name: ECM_CreateProductAgreement_Test
    
    Purpose: This class is used to cover testclass for the - ECM_CreateProductAgreement
    
    History                                                            
                                                               
    VERSION    AUTHOR                   DATE              DETAIL
    1.0      Veerendra Billakurthi    10/02/2020        Initial Development
    2.0      Anshu & Tanishq		  10/06/2022        ECM-5599        
*/ 
@isTest 
public class ECM_CreateProductAgreement_Test {
 @isTest 
    public static void createProductAgreementTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        
        Product__c product = new Product__c();
        product.Product_Full_Name__c='Test';
        product.Country__c=geographyId;
        insert product;
        system.assert(product.Id != null,'product Id should not be null');
        
        Product__c product1 = new Product__c();
        product1.Product_Full_Name__c='Test1';
        product1.Country__c=geographyId;
        insert product1;
        
        Product_UOM__c prdtUOM = new Product_UOM__c();
        prdtUOM.Product__c = product.Id;
        prdtUOM.Conversion_Factor__c = 2;
        prdtUOM.Unique_ID__c= product.id +'BTL';
        insert prdtUOM;
        
        Product_UOM__c prdtUOM1 = new Product_UOM__c();
        prdtUOM1.Product__c = product1.Id;
        //prdtUOM.Conversion_Factor__c = ;
        prdtUOM1.Unique_ID__c= product1.id +'BTL';
        insert prdtUOM1;
        
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.Volume_UoM_for_Spirits__c='BTL';
        contractType.ECM_Volume_UoM_for_Beer__c = 'Not Applicable';
        contractType.ECM_Automatic_approval_amount_threshold__c=30.00;
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;';
        contractType.ECM_Volume_UoM_for_RTD__c = 'Can/Bottle 24 Pack';
        contractType.ECM_Volume_UoM_for_Draught_Cocktails__c = '10L BIB';
        insert contractType;
        
        Market_Assortment_Product__c marketassort = new Market_Assortment_Product__c();
        marketassort.Product__c=product.Id;
        marketassort.Market_Assortment__c=geographyId;
        //marketassort.ECM_Strategy__c='2';
        Market_Assortment_Product__c marketassort1 = new Market_Assortment_Product__c();
        marketassort1.Product__c=product1.Id;
        marketassort1.Market_Assortment__c=geographyId;
        
        Market_Assortment_Product__c marketassort2 = new Market_Assortment_Product__c();
        //Marketassort1.Product__c=product1.Id;
        marketassort2.Market_Assortment__c=geographyId;
        
        insert marketassort;
        insert marketassort1;
        insert marketassort2;
        
        ECM_Product_Agreement__c productagg = new ECM_Product_Agreement__c();
        productagg.ECM_Market_Assortment_Product__c=marketassort.Id;
        productagg.ECM_Contract_Type__c=contractType.Id;
        insert productagg;
        
        ECM_Product_Agreement__c productagg1 = new ECM_Product_Agreement__c();
        productagg1.ECM_Market_Assortment_Product__c=Marketassort1.Id;
        productagg1.ECM_Contract_Type__c=contractType.Id;
        insert productagg1;
        
        String marketAssortId = marketassort.Id;
        String marketAssortId1 = marketassort1.Id;
        String marketAssortId2 = marketassort2.Id;
        
        ECM_CreateProductAgreement.fetchProductAgreement(productagg.Id);
        ECM_CreateProductAgreement.SaveProductAgrt1(productagg, Marketassort.Id, contractType.Id);
        ECM_CreateProductAgreement.calculateConversionFactor(marketAssortId);
        ECM_CreateProductAgreement.calculateConversionFactor(marketAssortId1);
        ECM_CreateProductAgreement.calculateConversionFactor(marketAssortId2);
        ECM_CreateProductAgreement.calculateConversionFactor('');
    }
}