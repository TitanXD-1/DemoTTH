/**

* @Name : EDGE_AssetTriggerHandlerTest



* @Purpose: Test class for AssetTriggerHandler/EDGE_AssetTriggerHelper

* @History:

* @Version     Developer         Date          Story/Purpose

*  1.1			Saranya 		16/08/2021		Initial development
*  1.2			Aparajita		28/09/2021		ES20-10414/ES20-10398(Method:testPopulateInstallDateAndAssetName)
*  1.3			Saurav Paul		08/10/2021		ES20-9930
*  1.4			Aparajita		07/10/2021		ES20-11091(Method:testRestrictDuplicateNonCOPAssets)
*  1.5          Anamika Shukla  24/01/2022      ES20-11918(Method:populateAssetNameTest)
*/

@isTest
public class EDGE_AssetTriggerHandlerTest {
    
    Final Public Static Id COUNTRYID = EDGE_UtilityTestClass.setupCountryGB('GB');
    
    @isTest
    public static void testPopulateInstallDateAndAssetName()
    {
        List<SObject> assetList = new List<SObject>();
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'United Kingdom';  
            insert outlet;
            
            //ES20-10414 STARTS
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Test';
            masterAsst.GUID__c = 'TWRFSHJAKSVGG';
            masterAsst.Short_Description__c = 'test';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = TRUE;
            masterAsst.Active__c = TRUE;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            Test.startTest();
            
            Asset asst = new Asset();
            asst.Name = 'Test_Asset';
            asst.GUID__c = 'TWRFSHJAKSVGG';
            asst.AccountId = outlet.Id;
            asst.Country__c = COUNTRYID;
            asst.Quantity = 1;
            asst.Master_Asset__c = masterAsst.Id;
            asst.InstallDate = null;
            asst.Asset_Location__c = 'Bar';
            
            assetList.add(asst);        
            EDGE_AssetTriggerHelper.populateInstallDate(assetList); //testing before insert
            insert asst;      
            assetList.clear(); 
            asst.InstallDate = null;
            assetList.add(asst);        
            EDGE_AssetTriggerHelper.populateInstallDate(assetList); //testing before update
            update asst;
            delete asst;
            undelete asst;   
            //ES20-10414 ENDS
            
            //ES20-10398 STARTS
            Master_Asset__c masterAsst1 = new Master_Asset__C();
            masterAsst1.Name = 'Test1';
            masterAsst1.GUID__c = 'TWRFSHJAKSVG1';
            masterAsst1.Short_Description__c = 'test1';
            masterAsst1.Country__c = COUNTRYID;
            masterAsst1.Line_Cleaning_Asset__c = TRUE;
            masterAsst1.Active__c = TRUE;
            insert masterAsst1;
            
            Asset asst1 = new Asset();
            asst1.Name = 'Test_Asset_1';
            asst1.GUID__c = 'TWRFSHJAKSVG1';
            asst1.AccountId = outlet.Id;
            asst1.Country__c = COUNTRYID;
            asst1.Quantity = 1;
            asst1.Asset_Location__c = 'Temporary Bar';
            asst1.Master_Asset__c = masterAsst1.Id; //testing oldItems equals null - new asset
            insert asst1; 
            
            asst.Master_Asset__c = masterAsst1.Id; //testing oldItems not equals null - existing asset
            update asst; 
            //ES20-10398 ENDS
            
            Test.stopTest();
        }
    } 
    /**
* @description : Test methd for populateRemovalDate before insert (ES20-9930) 
* @return : void
* @param : Void
*/
    
    @isTest
    public static void testPopulateRemovalDate(){
        List<SObject> assetList = new List<SObject>();
        EDGE_UtilityTestClass.createOrgSettings();  
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'United Kingdom';  
            insert outlet;
            
            
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Asset Name';
            masterAsst.Short_Description__c = 'Diageo master Asset';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = true;
            masterAsst.Active__c = true;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            Test.startTest();
            
            Asset asst = new Asset();
            asst.Name = 'Test_Asset';
            asst.AccountId = outlet.Id;
            asst.Country__c = COUNTRYID;
            asst.Quantity = 1;
            asst.Master_Asset__c = masterAsst.Id;
            asst.Asset_Removed__c = true;
            assetList.add(asst);
            
           Asset asst1 = new Asset();
            asst1.Name = 'Test_Asset';
            asst1.AccountId = outlet.Id;
            asst1.Country__c = COUNTRYID;
            asst1.Quantity = 1;
            asst1.Master_Asset__c = masterAsst.Id;
            asst1.Asset_Removed__c = true;
            assetList.add(asst1);
            insert assetList;
            asst1.Asset_Removed__c = false;
            update asst1;
            Test.stopTest();
        }  
    }
    
    /**
* @description : Test methd for populateRemovalDate after insert (ES20-9930) 
* @return : void
* @param : Void
*/
    
    @isTest
    public static void testPopulateRemovalDateAfterUpdate(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'United Kingdom';  
            insert outlet;
            
            System.debug(Logginglevel.debug,'@@@'+outlet.Country__c);
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Master Asset Test';
            masterAsst.Short_Description__c = 'Master Asset Desc';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = true;
            masterAsst.Active__c = true;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            Test.startTest();
            
            Asset asst = new Asset();
            asst.Name = 'Test_Asset';
            asst.AccountId = outlet.Id;
            asst.Country__c = COUNTRYID;
            asst.Quantity = 1;
            asst.Master_Asset__c = masterAsst.Id;
            insert asst;
            asst.Asset_Removed__c = true;
            update asst;
            Test.stopTest();
        }
    }
    
   @isTest
    public static void testRestrictDuplicateNonCOPAssets(){
        EDGE_UtilityTestClass.createOrgSettings();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(COUNTRYID);
            marketSettings.New_Asset_Validation__c = 'Asset Location;Master Asset';
            marketSettings.Threshold_Format__c = 'Percent';
            marketSettings.Line_Cleaning_Duration__c=25;
            insert marketSettings;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'United Kingdom';  
            insert outlet;
            
            System.debug(Logginglevel.debug,'@@@'+outlet.Country__c); 
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Test Master Asset';
            masterAsst.GUID__c = 'TWRFSHJAKSVGA';
            masterAsst.Short_Description__c = 'test';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = TRUE;
            masterAsst.Active__c = TRUE;
            masterAsst.COP__c = FALSE;
            masterAsst.Serialized__c = FALSE;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            
            Test.startTest();
            
            Asset asst1 = new Asset();
            asst1.Name = 'Test_Asset1';
            asst1.GUID__c = 'TWRFSHJAKSVG1';
            asst1.AccountId = outlet.Id;
            asst1.Country__c = COUNTRYID;
            asst1.Quantity = 1;
            asst1.Master_Asset__c = masterAsst.Id;
            asst1.InstallDate = null;
            asst1.Asset_Removed__c = false;
            asst1.Asset_Location__c = 'Bar';
           // ASST1.ACCOUNT.COUNTRY__C = COUNTRYID;
            asst1.Product__c = null;
            asst1.Asset_Owner__c = null;
            asst1.Asset_Used_By__c = null;
            insert asst1;
            
            Asset asst2 = new Asset();
            asst2.Name = 'Test_Asset2';
            asst2.GUID__c = 'TWRFSHJAKSVG2';
            asst2.AccountId = outlet.Id;
            asst2.Country__c = COUNTRYID;
            asst2.Quantity = 1;
            asst2.Master_Asset__c = masterAsst.Id;
            asst2.InstallDate = null;
            asst2.Asset_Removed__c = false;
            asst2.Asset_Location__c = 'Bar';
            asst2.Product__c = null;
            asst2.Asset_Owner__c = null;
            asst2.Asset_Used_By__c = null;
            
            //List<Asset> assetList = new list<Asset>();
            //assetList.add(asst1);
            //assetList.add(asst2);
            try{
                insert asst2;
                //insert assetList;
            }catch(Exception e){
                System.debug(Logginglevel.Debug,'Get Message '+e.getMessage());
                //Boolean expectedExceptionThrown =  e.getMessage().contains(System.label.EDGE_DuplicateAssetErrorMsg) ? true : false;
                //System.assertEquals(expectedExceptionThrown,true);       
            }
           
            List<Asset> assetlist2 = new List<Asset>();
            Asset asst3 = new Asset();
            asst3.Name = 'Test_Asset3';
            asst3.GUID__c = 'TWRFSHJAKSVG3';
            asst3.AccountId = outlet.Id;
            asst3.Country__c = COUNTRYID;
            asst3.Quantity = 1;
            asst3.Master_Asset__c = masterAsst.Id;
            asst3.InstallDate = null;
            asst3.Asset_Removed__c = true;
            asst3.Asset_Location__c = 'Temporary bar';
            insert asst3;
            
            asst1.Asset_Location__c = 'Cellar';
            asst2.Asset_Location__c = 'Cellar';
            asst3.Asset_Location__c = 'Cellar';
            assetlist2.add(asst1);
            assetlist2.add(asst2);
            assetlist2.add(asst3);
             try{
                insert assetList2;
            }catch(Exception e){
                System.debug(Logginglevel.Debug,'Get Message '+e.getMessage());
                //Boolean expectedExceptionThrown =  e.getMessage().contains(System.label.EDGE_DuplicateAssetErrorMsg) ? true : false;
                //System.assertEquals(expectedExceptionThrown,true);       
            }
            
           /* asst1.Quantity = 2;
            update asst1;
            
            Asset asst3 = new Asset();
            asst3.Name = 'Test_Asset3';
            asst3.GUID__c = 'TWRFSHJAKSVG3';
            asst3.AccountId = outlet.Id;
            asst3.Country__c = COUNTRYID;
            asst3.Quantity = 1;
            asst3.Master_Asset__c = masterAsst.Id;
            asst3.InstallDate = null;
            asst3.Asset_Removed__c = true;
            asst3.Asset_Location__c = 'Cellar';
            insert asst3;*/
                        Test.stopTest();

        }
    }
    @isTest
    public static void populatePendingBatchTest(){
        List<SObject> assetList = new List<SObject>();
        Map<Id,Id> accTerrMap = new Map<Id,Id>();
        EDGE_UtilityTestClass.createOrgSettings();    
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            outlet.ShippingCountry = 'United Kingdom';  
            insert outlet;
            
            Territory__c salesTerritory = new Territory__c();
            salesTerritory.Territory_Type__c = 'Service';
            salesTerritory.Country__c = COUNTRYID;
            insert salesTerritory;
            
            Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
            outletTerritory.Territory__c = salesTerritory.id;
            outletTerritory.Outlet__c = outlet.id;
            insert outletTerritory;
            
            Test.startTest();
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Test Master Asset';
            masterAsst.GUID__c = 'TWRFSHJAKSVGA';
            masterAsst.Short_Description__c = 'test';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = TRUE;
            masterAsst.Active__c = TRUE;
            masterAsst.COP__c = FALSE;
            masterAsst.Serialized__c = FALSE;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            
            Asset asst1 = new Asset();
            asst1.Name = 'Test_Asset1';
            asst1.GUID__c = 'TWRFSHJAKSVG1';
            asst1.AccountId = outlet.Id;
            asst1.Country__c = COUNTRYID;
            asst1.Quantity = 1;
            asst1.Master_Asset__c = masterAsst.Id;
            asst1.InstallDate = null;
            asst1.Asset_Removed__c = true;
            asst1.Asset_Location__c = 'Bar';
            insert asst1;
            assetList.add(asst1);
            accTerrMap.put(outletTerritory.Outlet__c,outletTerritory.Territory__c);
            Test.stopTest();
        }
    }
    @isTest
    public static void validateOffsetDayTest(){
        //Map<String,Id> geoMap = new Map<String,Id>();
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            
           /* Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
            market.Name = 'Europe and Turkey';
            market.Code__c = 'EU';
            market.Parent_Geography__c = globalRec.Id;
            market.RecordTypeId=EDGE_UtilityTestClass.marketRecTypeId;
            insert market;
            geoMap.put('Market',market.Id);
            
            Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
            hub.Name = 'Southern Europe';
            hub.Code__c = 'SEH';
            hub.Parent_Geography__c = market.Id;
            hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
            insert hub;
            geoMap.put('Hub',hub.Id);
            
            Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
            cluster.Name = 'Italy';
            cluster.Code__c = 'ITCC';
            cluster.Parent_Geography__c = hub.Id;
            cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
            insert cluster;
            geoMap.put('Cluster',cluster.Id);
            
            Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
            country.Name = 'Republic of Ireland';
            country.Code__c = countryCode;
            country.Parent_Geography__c = cluster.Id;
            country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
            insert country;
            geoMap.put('Country',country.Id);
            
            Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
            area.Name = 'Republic of Ireland';
            area.Code__c = 'IEA';
            area.Parent_Geography__c = country.Id;
            area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
            insert area;
            geoMap.put('Area',area.Id);        
            
            Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
            region.Name = 'Dublin 20';
            region.Code__c = 'IE18';
            region.Parent_Geography__c = area.Id;
            region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
            insert region;
            geoMap.put('Region',region.Id);*/
            
            Market_Setting__c marketset = EDGE_UtilityTestClass.getMarketSetting(COUNTRYID);
            marketset.Threshold_Format__c = 'Percent';
            marketset.Line_Cleaning_Duration__c=25;
            List<BusinessHours> bHoursList = [SELECT Id FROM BusinessHours];
            if(bHoursList.size()>0){
                marketset.Business_Hours__c = bHoursList[0].Id;	    
            }
            insert marketset;
            
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            /*outlet.Country__c = geoMap.get('Country');
            outlet.Hub__c = geoMap.get('Hub');
            outlet.Region__c=geoMap.get('Region');
            outlet.Area__c=geoMap.get('Area');
            outlet.Market__c = geoMap.get('Market');
            outlet.Cluster__c= geoMap.get('Cluster');*/
            outlet.ShippingCountry = 'United Kingdom';  
            insert outlet;
            
            Decimal mks=[select Geography__r.Code__c, Line_Cleaning_Duration__c from Market_Setting__c where Geography__c =: COUNTRYID].Line_Cleaning_Duration__c;
            System.debug(Logginglevel.debug,'LC'+mks);
            
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Test Master Asset 2';
            masterAsst.GUID__c = 'TWRFSHJAKSVGAZ';
            masterAsst.Short_Description__c = 'test';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = TRUE;
            masterAsst.Active__c = TRUE;
            masterAsst.COP__c = FALSE;
            masterAsst.Serialized__c = FALSE;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            
            Test.startTest();
            
            Asset asst1 = new Asset();
            asst1.Name = 'Test_Asset1';
            asst1.GUID__c = 'TWRFSHJAKSVG1';
            asst1.AccountId = outlet.Id;
            asst1.Country__c = COUNTRYID;
            asst1.Quantity = 1;
            asst1.Master_Asset__c = masterAsst.Id;
            asst1.InstallDate = null;
            asst1.Asset_Removed__c = true;
            asst1.Asset_Location__c = 'Bar';
            asst1.Offset_Day__c=40;
            insert asst1;
            
            Test.stopTest();        
        }
    }
    @isTest
    public Static void populateAssetNameTest(){
        //this is a test method for which we can populate assetname with master
        //asset to check the name is present as same as master asset
        List<SObject> assetList = new List<SObject>();
        EDGE_UtilityTestClass.createOrgSettings();     
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(COUNTRYID,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold[GB]';
            insert pickupOption;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
			outlet.ShippingCountry = 'United Kingdom';            
            insert outlet;
            
            Test.startTest(); 
            
            //String COUNTRYID = EDGE_UtilityTestClass.setupCountry('GB');
            User newUserMgr;
            User newUser = EDGE_UtilityTestClass.runAsUser('systemadmin', 'System Administrator');
            insert newUser;
            System.runAs(newUser) {
                newUserMgr = EDGE_UtilityTestClass.runAsUser('qualitymgr', 'Quality Manager');
                insert newUserMgr;
                newUserMgr.IsActive = False;
                update newUserMgr;
            }
            
            Product__c testProduct = EDGE_UtilityTestClass.getProd();
            testProduct.UPIID__c='12345';
            insert testProduct;
            Market_Assortment_Product__c testMAP = new Market_Assortment_Product__c(Market_Assortment__c=COUNTRYID,Product__c=testProduct.Id);
            insert testMAP;
            
            Product__c testProduct1 = new Product__c(Name='Johnny Walker Black');
            testProduct1.Product_Full_Name__c = 'Product Test';
            testProduct1.Country__c =  COUNTRYID;
            testProduct1.UPIID__c='12346';
            insert testProduct1;
            Market_Assortment_Product__c testMAP1 = new Market_Assortment_Product__c(Market_Assortment__c=COUNTRYID,Product__c=testProduct1.Id);
            insert testMAP1;
            
            Master_Asset__c masterAsst = new Master_Asset__C();
            masterAsst.Name = 'Test Master Asset1';
            masterAsst.GUID__c = 'TWRFSHJAKSVGB';
            masterAsst.Short_Description__c = 'test';
            masterAsst.Country__c = COUNTRYID;
            masterAsst.Priority_Assets__c = TRUE;
            masterAsst.Active__c = TRUE;
            masterAsst.COP__c = FALSE;
            masterAsst.Serialized__c = FALSE;
            insert masterAsst;
            System.assert(masterAsst.id!=null,'masterAsst must be null');
            
            Asset asst1 = new Asset();
            asst1.Name = 'Test_Asset1';
            asst1.GUID__c = 'TWRFSHJAKSVG1';
            asst1.AccountId = outlet.Id;
            asst1.Country__c = COUNTRYID;
            asst1.Quantity = 1;
            asst1.Master_Asset__c = masterAsst.Id;
            asst1.InstallDate = null;
            asst1.Asset_Removed__c = false;
            asst1.Asset_Location__c = 'Bar';
            asst1.Product__c=testMAP1.Name;
            insert asst1;
            
            Asset asst2 = new Asset();
            asst2.Name = 'Test_Asset2';
            asst2.GUID__c = 'TWRFSHJAKSVG2';
            asst2.AccountId = outlet.Id;
            asst2.Country__c = COUNTRYID;
            asst2.Quantity = 1;
            asst2.Master_Asset__c = masterAsst.Id;
            asst2.InstallDate = null;
            asst2.Asset_Removed__c = true;
            asst2.Asset_Location__c = 'Bar';
            asst2.Is_OffsetDay_Changed__c=True;
            assetList.add(asst1);
            assetList.add(asst2);
            Test.stopTest();
        }
    }
   
    
}