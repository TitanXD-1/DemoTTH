/**********************************************************************
Name: EDGE_POSAllocationControllerTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR              DATE            DETAIL
1.0         Sandeep Sahoo      30/07/2019      Initial Development
2.0         Swaraj Samanta     05/09/2022      Test Class Correction due to Failure(ES20-13284)
***********************************************************************/
@isTest
public class EDGE_POSAllocationControllerTest {
    @isTest
    public static void checkStock()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id areaRecTypeId= mapGeographyRecordTypes.get('Area').getRecordTypeId();
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id countryId1 = geoMap.get('Country');
        Geography__c area = createGeography('Area');
        area.Name = 'Spain Mainland';
        area.Code__c = 'ESM';
        area.Parent_Geography__c = countryId1;
        area.RecordTypeId=areaRecTypeId;
        insert area;
        EDGE_UtilityTestClass.createOrgSettings();
        
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        Test.startTest();
        Product__c product = EDGE_UtilityTestClass.getProd();
        product.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('POS').getRecordTypeId();
        product.Supplier_Partner__c= deliveryPartner.Id;
        insert product;
        
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        insert salesRep; 
        
        
        
        EDGE_POSAllocationController.searchStockDetails(product.Id,countryId,area.Id,True);
        EDGE_POSAllocationController.searchStockDetails(product.Id,countryId,area.Id,False);
        
        EDGE_POSAllocationController.searchStockDetails(outlet.Id,countryId,area.Id,True);
        
        EDGE_POSAllocationController.getProduct(product.Id);
        EDGE_POSAllocationController.getRecordType();
        Boolean timPOScheck = EDGE_POSAllocationController.getPOSTimeBasedMarketSetting(countryId);
 
        
        Stock__c stock = EDGE_UtilityTestClass.getStock(countryId, product.Id, salesRep.Id);
        insert stock;
        System.assert(stock.id != null);
        List<Stock__c> allocationList = new  List<Stock__c>();
        allocationList.add(stock);
        EDGE_POSAllocationController.saveAllocation(stock);
        EDGE_POSAllocationController.adjustAlloc(stock);
        EDGE_POSAllocationController.adjustAllocateList(allocationList);
        EDGE_POSAllocationController.saveWarehouseAllocation(20,stock);
        
        Stock__c stock1 = EDGE_UtilityTestClass.getStock(countryId, product.Id, salesRep.Id);
        List <Stock__c > stockallocationList = new List <Stock__c >();
        stockallocationList.add(stock1);
        
        
        
        try 
        {
            EDGE_POSAllocationController.saveAllocation(stock1);
        }
        catch (Exception e) 
        {
            System.debug('>>> ERROR ='+e);
        }        
        
        
        try {
            
            EDGE_POSAllocationController.adjustAllocateList(stockallocationList);
            
        }
        catch (Exception ex) 
        {
            System.debug('>>> ERROR ='+ex);
        }      
        
    }
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
}