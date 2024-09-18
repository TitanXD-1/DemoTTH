/**
* @description Test Class for EDGE_TerritoryTriggerHelper
* @history
* 1.0         Anuja Chattopadhyay    02/05/2019     
* 2.0         Joshraj Sen            08/04/2024
*/
@isTest
public class EDGE_TerritoryTriggerHelperTest {
    /**
* @description To Populate Parent Territory Hierarchy Based on Chosen Region While Inserting Territory
*/
    @isTest
    public static void testPopulateParentTerHierrarchyInsert(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();    
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        //Id countryId1=geoMap.get('Country');
        
        //Territory Hierarchy records creation for all different recordtypes
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        insert terrHierBsUnitobj; 
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj;
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj.Parent_BU__c=terrHierSalAreaobj.Id;
        insert terrHierRegionobj;
        
        string quRecType = 'Quality Territory Hierarchy';
        Territory_Hierarchy__c terrHierQTHobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, quRecType);
        terrHierQTHobj.Territory_Hierarchy_Type__c = 'Dispense Manager';
        insert terrHierQTHobj;
        
        String qualityRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
        Territory__c territoryQualityObj = new Territory__c();
        territoryQualityObj.Name = 'Test Territory';
        territoryQualityObj.Status__c = 'Active';
        territoryQualityObj.Territory_Type__c ='Service Lead';
        territoryQualityObj.Region__c = terrHierQTHobj.Id;
        territoryQualityObj.Country__c	= countryId;
        territoryQualityObj.recordTypeID = qualityRecordTypeId;
       

        
        //Terrory record creation to populate Sales Area and Business Unit 
        Territory__c territoryObj=EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Territory_Type__c ='Sales';
        territoryObj.Region__c = terrHierRegionobj.Id;
        Test.startTest();
        insert territoryObj;
         try{
        insert territoryQualityObj;
        }
        Catch(exception e){
            system.debug(LoggingLevel.Debug,'Error from Class');
        }
        Test.stopTest();
        
        Territory__c createdTerRecd = [Select Id,Region__c,Sales_Area__c,Business_Unit__c from Territory__c where Id  =:territoryObj.Id limit 1];
        System.assertEquals(createdTerRecd.Sales_Area__c,terrHierSalAreaobj.Id,'Match');
        System.assertEquals(createdTerRecd.Business_Unit__c,terrHierBsUnitobj.Id,'Match');
    }
    /**
* @description To Populate Parent Territory Hierarchy Based on Chosen Region While Inserting Territory
*/
    @isTest
    public static void testPopulateParentTerHierrarchyUpdate(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        // Handling the lookup filter for user on Territory Hierarchy Member
        User testSalesMgr = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Sales Manager');    
        insert testSalesMgr;
        
        User testMDMUser = EDGE_UtilityTestClass.runAsUser('EDGEMDM','Master Data Manager');    
        insert testMDMUser;
        
        EDGE_UtilityTestClass.createOrgSettings();     
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        //Id countryId1 = '';
        ///countryId1=geoMap.get('Cluster');
        
        Geography__c country = new Geography__c();
        country=[SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        /*  Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
secCountry.Name = 'Australia Country1';
secCountry.Code__c = 'AU1';
secCountry.Parent_Geography__c = countryId1;
insert secCountry; */
        
        //Territory Hierarchy records creation for all different recordtypes
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        insert terrHierBsUnitobj; 
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj;
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj1 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj1.Parent_BU__c=terrHierSalAreaobj.Id;
        insert terrHierRegionobj1;
        
        Territory_Hierarchy__c terrHierRegionobj2 = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj2.Parent_BU__c=terrHierSalAreaobj.Id;
        terrHierRegionobj2.Name = 'Updated Australia Territory Hierarchy';
        insert terrHierRegionobj2;
        
        Territory_Hierarchy_member__c terrHierMem = new Territory_Hierarchy_member__c();
        terrHierMem.Territory_Hierarchy__c = terrHierRegionobj1.Id;
        // Handling the lookup filter for user on Territory Hierarchy Member
        terrHierMem.User__c= testSalesMgr.Id;
        //terrHierMem.User__c= testMDMUser.Id;
        terrHierMem.Start_Date__c = Date.today().addDays(2);
        terrHierMem.End_Date__c = Date.today().addDays(10);
        insert terrHierMem;
        
        Territory_Hierarchy_member__c terrHierMem1 = new Territory_Hierarchy_member__c();
        terrHierMem1.Territory_Hierarchy__c = terrHierRegionobj2.Id;
        // Handling the lookup filter for user on Territory Hierarchy Member
        terrHierMem.User__c= testSalesMgr.Id;
        //terrHierMem1.User__c= testMDMUser.Id;
        terrHierMem1.Start_Date__c = Date.today().addDays(2);
        terrHierMem1.End_Date__c = Date.today().addDays(10);
        insert terrHierMem1;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        outlet.Primary_Sales_Territory_Region__c=terrHierRegionobj1.id;       
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Territory__c territoryObj1=EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj1.Territory_Type__c ='Sales';
        territoryObj1.Region__c = terrHierRegionobj1.Id;
        territoryObj1.Country__c	= countryId;
        insert territoryObj1;
        
        Outlet_Territory__c outTerr = new Outlet_Territory__c();
        outTerr.Outlet__c = outlet.Id;
        outTerr.Territory__c = territoryObj1.Id;
        
        //Terrory record update to populate Sales Area and Business Unit 
        Territory__c territoryObj=EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Territory_Type__c ='Sales';
        territoryObj.Region__c = terrHierRegionobj1.Id;
        territoryObj.Country__c	= countryId;
        insert territoryObj;
        Outlet_Territory__c outTerr1 = new Outlet_Territory__c();
        outTerr1.Outlet__c = outlet.Id;
        outTerr1.Territory__c = territoryObj.Id;
        
        //territoryObj.Region__c=terrHierRegionobj2.Id;
        territoryObj.Country__c	=countryId;
        Test.startTest();
        update territoryObj;        
        Territory__c createdTerRecd = [Select Id,Region__c,Sales_Area__c,Business_Unit__c from Territory__c where Id  =:territoryObj.Id limit 1];
        System.assertEquals(createdTerRecd.Sales_Area__c,terrHierSalAreaobj.Id,'Match');
        System.assertEquals(createdTerRecd.Business_Unit__c,terrHierBsUnitobj.Id,'Match');
        delete territoryObj;
        undelete territoryObj;  
        Test.stopTest();
    } 

}