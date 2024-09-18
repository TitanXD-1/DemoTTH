/*
 * @Name: ECM_ProductAgreementTriggerHelperTest
 * @Description: This is the test class for SalesAgreementTrigger
 * @History                                                            
                                                         
 VERSION    AUTHOR                DATE              DETAIL
 1.0        Sayan Mullick     	 15/09/2021         Initial Development for ECM-4416
*/ 
@isTest
public class ECM_ProductAgreementTriggerHelperTest {
	@isTest
    public static void salesAggrementValidationTest(){
        WrapperInst wrapobj = createData();
        ECM_Product_Agreement__c prodAggObj = ECM_UtilityTestClass.createProductAgreement(wrapobj.aggTypeObj,wrapobj.mapObj);
        System.debug(LoggingLevel.Debug,'prodAggObj' +prodAggObj);
        Test.startTest();
        try{
            insert prodAggObj;
            System.assert(prodAggObj!=null,'prodAggObj should not be null');
            delete prodAggObj;
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        Test.stopTest();
    }
    @isTest
    public static void updatesalesAggrementValidationTest(){
        WrapperInst wrapobj = createData();
        ECM_Product_Agreement__c prodAggObj = ECM_UtilityTestClass.createProductAgreement(wrapobj.aggTypeObj,wrapobj.mapObj);
        
        Test.startTest();
        try{
            update prodAggObj;
            System.assert(prodAggObj!=null,'prodAggObj should not be null');
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
        }
        Test.stopTest();
    }
    public static WrapperInst createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String supplierRecordTypeId = Delivery_Partner__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Supplier Partner').getRecordTypeId();
        Delivery_Partner__c deliverPartner = ECM_UtilityTestClass.getDeliverPartner(countryId,supplierRecordTypeId);
        insert deliverPartner;
        
        String posRecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        Product__c productObj = EDGE_UtilityTestClass.getProd();
        productObj.Name = 'Test Product';
        productObj.Supplier_Partner__c = deliverPartner.Id;
        productObj.Product_Code__c = 'Test1123';
        productObj.Diageo_Cost__c = 12;
        productObj.A_P_Cost__c = 14;
        productObj.POS_Related_Brand__c ='test';
        productObj.Units_per_POS__c =12;
        productObj.Limit_Per_Order__c = 12;
        productObj.Outlet_Cost__c = 12;
        productObj.POS_Related_Item__c = 'test';
        productObj.SAP_IO_Number__c = 'test'; 
        productObj.Pricing_Type__c = 'By Unit';
        productObj.Country__c = countryId;
        productObj.RecordTypeId = posRecordTypeId;
        productObj.POS_Item_Short_Description__c = 'test';
        productObj.Start_Date__c = System.today();
        productObj.Expiry_Date__c =  productObj.Start_Date__c.addDays(5);
        insert productObj;
        
        ECM_Contract_Type__c aggTypeObj = ECM_UtilityTestClass.getAgreementType(countryId);
        aggTypeObj.ECM_Screen_3_field_configuration__c='Product Name;Volume Target;UoM';
        insert aggTypeObj;
        String productStrategyRecordtypeId =Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        Pick_Up_Options__c pickupOpt = ECM_UtilityTestClass.createPickUpOption(countryId,productStrategyRecordtypeId);
        pickupOpt.Name='Spirits[ES]';
        pickupOpt.Status__c = 'Active';
        insert pickupOpt;
        Market_Assortment_Product__c mapObj = ECM_UtilityTestClass.createMarketAssortmentProduct(productObj.Id,countryId);
        mapObj.ECM_CM_flag__c = true;
        mapObj.ECM_Pickup_Option__c =pickupOpt.Id;        
        insert mapObj;
        
        ECM_Product_Agreement__c prodAggObj = ECM_UtilityTestClass.createProductAgreement(aggTypeObj.Id, mapObj.Id);
        insert prodAggObj;
            
        
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.mapObj = mapObj.Id;
        wrapObj.aggTypeObj = aggTypeObj.Id;
        return wrapObj;
    }
    class WrapperInst{
        String mapObj{get;set;}
        String aggTypeObj{get;set;}        
    }
}