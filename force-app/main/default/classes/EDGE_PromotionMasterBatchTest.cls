/**

* @description :  EDGE_PromotionMasterBatchTest

* @purpose : This is the test class for EDGE_PromotionMasterBatch

* @history :

* Version    Developer         Date           User Story/Purpose

*  1.1      Prasanth         15/07/2022		    ES20-12982


*/

@isTest
public class EDGE_PromotionMasterBatchTest{
    
    @testSetup
    static void setup() {
        
        
        
        Map<String,Id> geoMap=new Map<String,Id>();
        Id countryId;
        Geography__c globalRec = EDGE_UtilityTestClass.createGeography('Global');
        globalRec.Name = 'Global3';
        globalRec.Code__c = 'GL3';
        globalRec.RecordTypeId=EDGE_UtilityTestClass.GlobalRecTypeId;
        insert globalRec;
        geoMap.put('Global3',globalRec.Id);
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'Europe and Turkey';
        market.Code__c = 'EU';
        market.Parent_Geography__c = globalRec.Id;
        market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
        insert market;
        //marketMap.put('Market',market.Id);
        geoMap.put('Market',market.Id);
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Southern Europe';
        hub.Code__c = 'SEH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Spain';
        cluster.Code__c = 'SPC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Spain';
        country.Code__c ='ES';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Spain Canaries';
        area.Code__c = 'ESC';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'CANARIAS';
        region.Code__c = 'ES1';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id; 
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        terriHierBU.Geography__c=geoMap.get('Country');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        terriHierSA.Geography__c=geoMap.get('Country');
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Geography__c=geoMap.get('Country');
        insert terriHier;
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Region__c =terriHier.Id;
        territory.Country__c=geoMap.get('Country');
        insert territory;
        Account outlet =EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name='Tes outle classs';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = geoMap.get('Country');
        outlet.Hub__c = geoMap.get('Hub');
        outlet.Region__c=geoMap.get('Region');
        outlet.Area__c=geoMap.get('Area');
        outlet.Market__c = geoMap.get('Market');
        outlet.Cluster__c= geoMap.get('Cluster');
        insert outlet;
        Outlet_Territory__c  outletTerritory3  =  EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, territory.Id);
        outletTerritory3.Active__c = 'Waiting Activation';
        insert outletTerritory3;
        Promotion_Master__c promotion=new Promotion_Master__c();
        Id priceIncentivePromotionMasterRecordTypeId=Schema.SObjectType.Promotion_Master__c.getRecordTypeInfosByName().get('Price Incentive Order').getRecordTypeId();
        promotion.Country__c=geoMap.get('Country');
        promotion.Name='Test Promotion Price Incentive';
        promotion.Description__c='This is a test Promotion';
        promotion.Start_Date__c=System.today().addDays(-30);
        promotion.End_Date__c=System.today().addDays(-1);
        promotion.Discount_for_promotion__c=30;
        promotion.Discount_type__c='Discount in amount';
        promotion.RecordTypeId=priceIncentivePromotionMasterRecordTypeId;
        insert promotion;
        Outlet_Promotion__c outletPromotion=new Outlet_Promotion__c();
        outletPromotion.Status__c='Active';
        outletPromotion.Outlet__c=outlet.Id;
        outletPromotion.Promotion__c=promotion.Id;
        outletPromotion.Promotion_Limit__c=100;
        outletPromotion.Promotion_Used__c=1;
        insert outletPromotion;
        Territory_Promotion__c territoryPromotion=new Territory_Promotion__c();
        territoryPromotion.Status__c='Active';
        territoryPromotion.Territory__c=territory.Id;
        territoryPromotion.Promotion__c=promotion.Id;
        territoryPromotion.Promotion_Limit__c=100;
        territoryPromotion.Promotion_Used__c=1;
        insert territoryPromotion;
        
        
        
        
       
    }
    @isTest 
    static void testPromotionMasterBatch() {
        Test.startTest();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_PromotionMasterBatch'
                                                  and Country_Code__c ='ES' Limit 1];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //EDGE_PromotionMasterBatch uca = new EDGE_PromotionMasterBatch();
        //Id batchId = Database.executeBatch(uca);
        Test.stopTest();      
    }
}