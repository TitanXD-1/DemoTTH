/*
Name: ECM_CreateProductAgreement

Purpose: This class is used for Edit and Create Product Agreement in Lightning component - ECM_CreateProductAgreement

History                                                            

VERSION    AUTHOR                DATE              DETAIL
1.0      Pradeep Kumar Reddy    31/01/2020        Initial Development
Veerendra Billakurthi
2.0      Keshav                 10/03/2020        ECM-328  : SFDC_GLO_OBJECT_UX_TI investment rate limit per product   
3.0      Pravalika Golamari     24/05/2021        ECM-3988 : Error message while adding the Product for Agreement
4.0      Anshu & Tanishq        10/06/2022		  ECM-5599 : Error creating product agreement  
*/ 
public class ECM_CreateProductAgreement{
    
    // Method Name : fetchProductAgreement
    // Description : This method is used to fetch the all the values of Product agreement based on selected selected Product Agreement
    
    @AuraEnabled
    public static productAgrementWrapper fetchProductAgreement(String recordId){
        productAgrementWrapper wrap = new productAgrementWrapper();
        ECM_Product_Agreement__c  prdtAgrment = [SELECT Id, ECM_Contract_Type__c, ECM_Market_Assortment_Product__c, ECM_Preferred__c, ECM_Lead_Brand__c, ECM_Min_TI_limit_per_min_UoM_value__c, ECM_Min_TI_limit_per_9LC_EU_value__c, ECM_Max_TI_limit_per_min_UoM_value__c, ECM_Max_TI_limit_per_9LC_EU_value__c, ECM_Min_TI_limit_in_of_XYZ_per_min_UoM__c, ECM_Min_TI_limit_in_of_XYZ_per_9LC_EU__c, ECM_Max_TI_limit_in_of_XYZ_per_min_UoM__c, ECM_Max_TI_limit_in_of_XYZ_per_9LC_EU__c FROM ECM_Product_Agreement__c WHERE Id =: recordId];
        ECM_Contract_Type__c agrmentType = new ECM_Contract_Type__c();
        Market_Assortment_Product__c marketPrdt = new Market_Assortment_Product__c();
        if(prdtAgrment.ECM_Contract_Type__c != null){
            agrmentType = [SELECT Id, Name, Geography__r.Code__c FROM ECM_Contract_Type__c WHERE ID =: prdtAgrment.ECM_Contract_Type__c];
        }
        if(prdtAgrment.ECM_Market_Assortment_Product__c != null){
            marketPrdt = [SELECT id, Name, Product__c, Product__r.Name,Market_Assortment__r.Code__c FROM Market_Assortment_Product__c WHERE Id =: prdtAgrment.ECM_Market_Assortment_Product__c];
        }
        wrap.productAgreement = prdtAgrment;
        wrap.agreementType = agrmentType;
        wrap.MarketProduct = marketPrdt;
        return wrap;
    }
    
    // Method Name : calculateConversionFactor
    // Description : This method fetches "Market Assortment Product" id from component and returns the Product UoM object "Conversion factor" value associated to the Product record.
    
    @AuraEnabled
    public static ProductUomCheckWrapper calculateConversionFactor(String Market){
        String conversionFactor;
        ProductUomCheckWrapper wrapObj = new ProductUomCheckWrapper();
        if(!String.isBlank(Market)){			
            Market_Assortment_Product__c marketAssortObj = new Market_Assortment_Product__c();
            marketAssortObj = [SELECT id, Name, Product__c, Product__r.Name,Market_Assortment__r.Code__c FROM Market_Assortment_Product__c WHERE Id =: Market];
            
            system.debug('marketAssortObj'+marketAssortObj);
            if(marketAssortObj.Product__c != null)
            {
                //Product_UOM__c prodUomObj = new Product_UOM__c();
                List<Product_UOM__c> productUomList = new List<Product_UOM__c>();
                productUomList = [SELECT id, Name, Product__c, Product__r.Name, Conversion_Factor__c FROM Product_UOM__c WHERE Product__c =: marketAssortObj.Product__c AND Conversion_Factor__c != null ORDER BY LastModifiedDate DESC limit 1];
                system.debug('productUomList'+productUomList);
                if(productUomList.size()>0){
                    //productUomList = [SELECT id, Name, Product__c, Product__r.Name, Conversion_Factor__c FROM Product_UOM__c WHERE Product__c =: marketAssortObj.Product__c AND Conversion_Factor__c != null ORDER BY LastModifiedDate DESC limit 1];
                    //conversionFactor = String.valueOf(productUomList[0].Conversion_Factor__c);
                    ConversionFactor = String.isNotBlank(String.valueOf(productUomList[0].Conversion_Factor__c))?String.valueOf(productUomList[0].Conversion_Factor__c):String.valueOf(1);
                    wrapObj.isSuccess = true;
                    wrapObj.conversionFactorVal = conversionFactor;
                    wrapObj.errorMessage=''; 
                    return wrapObj; 
                } 
                wrapObj.isSuccess = false;
                wrapObj.conversionFactorVal = '';
                wrapObj.errorMessage=Label.ECM_Product_UOM_Check; 
                return wrapObj;
            }
            wrapObj.isSuccess = false;
            wrapObj.conversionFactorVal = '';
            wrapObj.errorMessage=Label.ECM_Product_Check_In_Market_Assortment; 
            return wrapObj;
        }
        
        return wrapObj;
    }
    
    // Method Name : SaveProductAgrt1
    // Description : This method is used to insert or update the Product Agreement
    @AuraEnabled
    public static ECM_Product_Agreement__c SaveProductAgrt1(Sobject Product, String Market , String Agreement){
        
        ECM_Product_Agreement__c ProductAgrement = (ECM_Product_Agreement__c)Product;
        ProductAgrement.ECM_Contract_Type__c=Agreement;
        ProductAgrement.ECM_Market_Assortment_Product__c =Market;
        //system.debug('Product'+Product);
        system.debug('Marketcreated'+Market);
        // return market;
        system.debug('Productdetailscreated'+ProductAgrement);
        //system.debug('Contract'+con);
        upsert ProductAgrement;
        return ProductAgrement;
    }
    
    // Wrapper Class : productAgrementWrapper
    // Description   : This wrapper will hold details of Product Agreement, Agreement Type and Market Assortment Product
    public class productAgrementWrapper{
        @AuraEnabled public ECM_Product_Agreement__c productAgreement{get;set;}
        @AuraEnabled public ECM_Contract_Type__c agreementType{get;set;}
        @AuraEnabled public Market_Assortment_Product__c MarketProduct{get;set;}
    }
    public class ProductUomCheckWrapper{
        @AuraEnabled public String conversionFactorVal{get;set;}
        @AuraEnabled public String errorMessage{get;set;}
        @AuraEnabled public Boolean isSuccess{get;set;}
        
    }
}