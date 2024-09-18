/*
 * @Name: ECM_PriceListItemTriggerHelperTest
 * @Description: This is the test class for PriceListItem Trigger
 * @History                                                            
                                                         
VERSION    AUTHOR                DATE              DETAIL
1.0        Tanishq	        	01/09/2021         Initial Development for ECM-4763
*/ 
@isTest
public class ECM_PriceListItemTriggerHelperTest {
	@isTest
    public static void priceListItemValidationTest(){
        WrapperInst wrapobj = createData();
        ECM_Price_List_Item__c priceListItemObj1 = ECM_UtilityTestClass.createPriceListItem(wrapobj.pkUpoptnObj,wrapobj.productObj,wrapobj.priceListObj);
        priceListItemObj1.ECM_Base_UoM__c = 'BTL';
        Test.startTest();
        try{
            insert priceListItemObj1;
            system.assert(priceListItemObj1.Id != null,'priceListItemObj1 Id should not be null');
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            
        }
        Test.stopTest();
    }
    @isTest
    public static void priceListItemValidationUpdateTest(){
        WrapperInst wrapobj = createData();
        ECM_Price_List_Item__c priceListItemObj1 = ECM_UtilityTestClass.createPriceListItem(wrapobj.pkUpoptnObj,wrapobj.productObj,wrapobj.priceListObj);
        priceListItemObj1.ECM_Base_UoM__c = 'KEG';
        insert priceListItemObj1;
        system.assert(priceListItemObj1.Id != null,'priceListItemObj1 Id should not be null');
        priceListItemObj1.ECM_Base_UoM__c = 'BTL';
        Test.startTest();
        try{
            update priceListItemObj1;
            
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            
        }
        Test.stopTest();
        
    }
    @isTest
    public static void priceListItemValidationDeleteTest(){
        WrapperInst wrapobj = createData();
        ECM_Price_List_Item__c priceListItemObj1 = ECM_UtilityTestClass.createPriceListItem(wrapobj.pkUpoptnObj,wrapobj.productObj,wrapobj.priceListObj);
        priceListItemObj1.ECM_Base_UoM__c = 'KEG';
        insert priceListItemObj1;
        system.assert(priceListItemObj1.Id != null,'priceListItemObj1 Id should not be null');
        //priceListItemObj1.ECM_Base_UoM__c = 'BTL';
        Test.startTest();
        try{
            delete priceListItemObj1;
        }catch(Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
            
        }
        Test.stopTest();
        
    }

    public static WrapperInst createData(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
        Id bnnrRecTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Banner').getRecordTypeId();
        
        Pick_Up_Options__c pkUpoptnObj = ECM_UtilityTestClass.createPickUpOption(countryId,bnnrRecTypeId);
        pkUpoptnObj.Name = 'Spirits[ES]';
        insert pkUpoptnObj;
        
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
        
        DateTime dt = System.now();
        String dtStr = 'Spain Price List'+dt.format('dd MMMM YYYY');
        ECM_Price_List__c priceListObj = ECM_UtilityTestClass.createPriceList(dtStr,countryId);
        insert priceListObj;
        ECM_Price_List_Item__c priceListItemObj = ECM_UtilityTestClass.createPriceListItem(pkUpoptnObj.Id,productObj.id,priceListObj.Id);
        priceListItemObj.ECM_Base_UoM__c = 'BTL';
        insert priceListItemObj;
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.pkUpoptnObj = pkUpoptnObj.Id;
        wrapObj.productObj = productObj.Id;
        wrapObj.priceListObj = priceListObj.id;
        wrapObj.countryId = countryId;
        return wrapObj;
    }
    class WrapperInst{
        String pkUpoptnObj{get;set;}
        String productObj{get;set;}
        String priceListObj{get;set;}
        String countryId{get;set;}
    }
}