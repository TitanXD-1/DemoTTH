/**

* @description : This test class is to cover KPIAchivementTrigger and its related helper classes

* @history :

* Version   Developer      Date       User Story	  			Purpose
* 1.1       Manikant   29-Oct-2019    Initial Development      Initial Development
* 1.2       Debolina   23-March-2022  ES20-12219               Modification of target calculation_ SFDC_ Activation Specialist Enhancements
* 1.3   Joshraj/Sakshi 1-April 2024   152305                   152305 Fixed SCA
*/
@istest
public class EDGE_KPIAchivementTriggerHelperTest 
{
    static Id countryId1 = EDGE_UtilityTestClass.setupCountry('AUS');
    static List<KPI_Achivement__c> kpiAchList = new List<KPI_Achivement__c>();
    @isTest
    public static void checkAndValidateSharingTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id countryRecTypeId = mapGeographyRecordTypes.get('Country').getRecordTypeId();
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id clusterId = geoMap.get('Cluster');
        Geography__c country = EDGE_KPIAchivementTriggerHelperTest.getCountry(countryRecTypeId,clusterId);
        Test.startTest();
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId1, 'Business Unit');
        insert terriHierBU; 
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId1, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA; 
        Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId1, 'Region');
        terriHierRegion.Parent_BU__c = terriHierSA.Id;
        insert terriHierRegion;
        Territory__c territory = EDGE_KPIAchivementTriggerHelperTest.getTerritory(terriHierSA,terriHierRegion);
        Territory__c actTerr = EDGE_KPIAchivementTriggerHelperTest.getActTerr(terriHierSA,terriHierRegion);
        Pick_Up_Options__c pickupOption = EDGE_KPIAchivementTriggerHelperTest.getpickupOption1(); 
        Pick_Up_Options__c pickupOption2 = EDGE_KPIAchivementTriggerHelperTest.getpickupOption2(); 
        Pick_Up_Options__c actpickupOption = EDGE_KPIAchivementTriggerHelperTest.getActPickupOption();
        KPI_Achivement__c kpiRec = EDGE_KPIAchivementTriggerHelperTest.getKpiRec();
        KPI_Achivement__c kpiRecAct = new KPI_Achivement__c();
        kpiRecAct=EDGE_KPIAchivementTriggerHelperTest.getKpiRecAct(pickupOption,territory,terriHierRegion);
        KPI_Achivement__c kpiRecAct2 = new KPI_Achivement__c();
        kpiRecAct2=EDGE_KPIAchivementTriggerHelperTest.getKpiRecAct(pickupOption2,territory,terriHierRegion); 
        KPI_Achivement__c kpiSurAct = new KPI_Achivement__c();
        kpiSurAct=EDGE_KPIAchivementTriggerHelperTest.getKpiSurAct(pickupOption,actTerr,terriHierRegion);
        KPI_Achivement__c kpiRecTotal1 = new KPI_Achivement__c();
        kpiRecTotal1=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal1(territory,terriHierRegion);
        KPI_Achivement__c kpiRecTotal2 = new KPI_Achivement__c();
        kpiRecTotal2=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal2(territory,terriHierRegion);
        KPI_Achivement__c actkpiRec = new KPI_Achivement__c();
        actkpiRec=EDGE_KPIAchivementTriggerHelperTest.getActkpiRec(actTerr,terriHierRegion,actpickupOption);
        KPI_Achivement__c kpiRecTotal3 = new KPI_Achivement__c();
        kpiRecTotal3=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal3(territory,terriHierRegion);
        KPI_Achivement__c kpiRecTotal4 = new KPI_Achivement__c();
        kpiRecTotal4=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal4(terriHierRegion);
        //User u = EDGE_UtilityTestClass.runAsUser('salesRep1','System Administrator');
        User u = EDGE_UtilityTestClass.runAsUser('Admin','System Administrator');
        insert u;
        KPI_Achivement__c kpiRecTotal5 = new KPI_Achivement__c();
        kpiRecTotal5=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal5(u);
        KPI_Achivement__c kpiRecTotal6 = new KPI_Achivement__c();
        kpiRecTotal6=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal6(territory,terriHierRegion);
        KPI_Achivement__c kpiRecTotal = new KPI_Achivement__c();
        kpiRecTotal=EDGE_KPIAchivementTriggerHelperTest.getKpiRecTotal(territory,terriHierRegion);
        KPI_Achivement__c actkpiTotal = new KPI_Achivement__c();
        actkpiTotal=EDGE_KPIAchivementTriggerHelperTest.getActkpiTotall(actTerr,terriHierRegion);  
        insert kpiAchList;
        Test.stopTest();
        System.assert(kpiRec.id != null,'kpi Rec Id should not be null'); 
        kpiRec.KPI_Type__c = 'OES';
        kpiRec.Country__c =  country.id;
        update kpiRec;
        delete kpiRec;
        undelete kpiRec;  
    }
    static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
    @isTest
    static void updateKpiAchievementCountryTest(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        //User newUser = EDGE_UtilityTestClass.runAsUser('TestUser1', 'System Administration');
        //insert newUser;
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usr = new User();
        usr.firstName = 'test123';
        usr.lastName = 'test231';
        usr.ProfileId = prof.id;        
        usr.email = 'test@test.com';
        usr.Username ='testcm121232132133@test.com';
        usr.Alias='test';
        usr.Timezonesidkey='America/Los_Angeles';
        usr.LocaleSidKey='en_US';
        usr.LanguageLocaleKey='en_US';
        usr.EmailEncodingKey='UTF-8';
        usr.Available_Countries__c='GB';
        insert usr;
        System.assert(usr.Id!=null,'usr Id should not be null');
        
        system.runAs(usr){
            List <KPI_Achivement__c> kpiAchList1 = new List<KPI_Achivement__c>();
            KPI_Achivement__c kpiAchRec =new KPI_Achivement__c();
            Map<Id, KPI_Achivement__c> oldKpiAchvMap = new Map<Id, KPI_Achivement__c>();
            kpiAchRec.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
            kpiAchRec.User__c = usr.id;
            kpiAchRec.Achievement__c = 25;
            kpiAchRec.Achievement__c = 15;
            kpiAchRec.Total_Denominator__c = 20 ;
            kpiAchList1.add(kpiAchRec); 
            oldKpiAchvMap.put(kpiAchRec.id,kpiAchRec);   
            EDGE_KPIAchivementTriggerHelper.updateKpiAchievementCountry(kpiAchList1,oldKpiAchvMap);
        }
        
    }
    static Geography__c getCountry(Id countryRecTypeId,id clusterId){
        Geography__c country = createGeography('Country');
        country.Name = 'Australia1';
        country.Code__c = 'AUT1';
        //country.Extended_Country_Code__c ='AUT1-AUS';
        country.Parent_Geography__c = clusterId;
        country.RecordTypeId = CountryRecTypeId;
        return country;
    }
    // create Territory 
    static Territory__c getTerritory(Territory_Hierarchy__c terriHierSA,Territory_Hierarchy__c terriHierRegion){
        Territory__c territory =  EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId1;
        territory.Sales_Area__c = terriHierSA.Id;
        territory.Region__c = terriHierRegion.Id;
        territory.Territory_Type__c = 'Sales';
        insert territory;
        return territory;
    }
    // create Activation Territory
    static Territory__c getActTerr(Territory_Hierarchy__c terriHierSA,Territory_Hierarchy__c terriHierRegion){
        Territory__c actTerr = EDGE_UtilityTestClass.getTerritoryRec();
        actTerr.Country__c = countryId1;
        actTerr.Sales_Area__c = terriHierSA.Id;
        actTerr.Region__c = terriHierRegion.Id;
        actTerr.Territory_Type__c = 'Activation Territory';
        actTerr.RecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        insert actTerr;
        return actTerr;
    }
    static Pick_Up_Options__c getpickupOption1(){
        Pick_Up_Options__c pickupOption =  EDGE_UtilityTestClass.getPickUpOption(countryId1,'Activation Type');
        pickupOption.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        pickupOption.Name = 'Act[AUS]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        return pickupOption;
    }
    static Pick_Up_Options__c getpickupOption2(){
        Pick_Up_Options__c pickupOption =  EDGE_UtilityTestClass.getPickUpOption(countryId1,'Activation Type');
        pickupOption.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        pickupOption.Name = 'Act2[AUS]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        return pickupOption;
    }
    static Pick_Up_Options__c getActPickupOption(){
        Pick_Up_Options__c actpickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId1,'Survey KPI');
        actpickupOption.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        actpickupOption.Name = 'Survey[AUS]';
        actpickupOption.Status__c = 'Active';
        actpickupOption.Applicable_Business_Role__c = 'Activation Specialist';
        actpickupOption.Include_in_Total_Activation_Survey_KPI__c = true;
        insert actpickupOption;
        return actpickupOption;
    }
    static KPI_Achivement__c getKpiRec(){
        KPI_Achivement__c kpiRec = new KPI_Achivement__c();
        kpiRec.KPI_Type__c = 'MAS';
        kpiRec.Country__c = countryId1;
        kpiRec.Achievement__c = 15;
        kpiRec.Total_Denominator__c = 20 ;
        kpiAchList.add(kpiRec);
        return kpiRec;
    }
    static KPI_Achivement__c getKpiRecAct( Pick_Up_Options__c pickupOption,Territory__c territory,Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c kpiRecAct = new KPI_Achivement__c();
        kpiRecAct.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiRecAct.KPI_Type__c = 'Activation Survey KPI';
        kpiRecAct.Activation_Type__c = pickupOption.Id;
        kpiRecAct.Country__c = countryId1;
        kpiRecAct.Achievement__c = 15;
        kpiRecAct.Total_Denominator__c = 20 ;
        kpiRecAct.Target_Number__c = 100;
        kpiRecAct.Territory__c = territory.Id;
        kpiRecAct.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecAct);
        return kpiRecAct;
    }
    static KPI_Achivement__c getKpiSurAct(Pick_Up_Options__c pickupOption,Territory__c actTerr,Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c kpiSurAct = new KPI_Achivement__c();
        kpiSurAct.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiSurAct.KPI_Type__c = 'Activation Survey KPI';
        kpiSurAct.Activation_Type__c = pickupOption.Id;
        kpiSurAct.Country__c = countryId1;
        kpiSurAct.Achievement__c = 15;
        kpiSurAct.Total_Denominator__c = 20 ;
        kpiSurAct.Target_Number__c = 100;
        kpiSurAct.Territory__c = actTerr.Id;
        kpiSurAct.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiSurAct);
        return kpiSurAct;
    }
    static KPI_Achivement__c getKpiRecTotal1(Territory__c territory,Territory_Hierarchy__c terriHierRegion){
        Product__c product = ECM_UtilityTestClass.createProduct(countryId1,'Test');
            product.RecordTypeId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();
            product.Product_Full_Name__c='Test';
            insert product;
        KPI_Achivement__c kpiRecTotal1 = new KPI_Achivement__c();
        kpiRecTotal1.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Product KPI').getRecordTypeId();
        kpiRecTotal1.KPI_Type__c = 'NPD';
        kpiRecTotal1.Product__c=product.Id;
        kpiRecTotal1.Country__c = countryId1;
        kpiRecTotal1.Achievement__c = 15;
        kpiRecTotal1.Total_Denominator__c = 20 ;
        kpiRecTotal1.Territory__c = territory.Id;
        kpiRecTotal1.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecTotal1);
        return kpiRecTotal1;
    }
    static KPI_Achivement__c getKpiRecTotal2(Territory__c territory,Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c kpiRecTotal2 = new KPI_Achivement__c();
        kpiRecTotal2.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey KPI').getRecordTypeId();
        kpiRecTotal2.KPI_Type__c = 'Survey';
        kpiRecTotal2.Country__c = countryId1;
        kpiRecTotal2.Achievement__c = 15;
        kpiRecTotal2.Total_Denominator__c = 20 ;
        kpiRecTotal2.Territory__c = territory.Id;
        kpiRecTotal2.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecTotal2);
        return kpiRecTotal2;
    }
    static KPI_Achivement__c getActkpiRec(Territory__c actTerr,Territory_Hierarchy__c terriHierRegion,Pick_Up_Options__c actpickupOption){
        KPI_Achivement__c actkpiRec =  new KPI_Achivement__c();
        actkpiRec.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey KPI').getRecordTypeId();
        actkpiRec.KPI_Type__c = 'Survey';
        actkpiRec.Country__c = countryId1;
        actkpiRec.Achievement__c = 15;
        actkpiRec.Total_Denominator__c = 20 ;
        actkpiRec.Territory__c = actTerr.Id;
        actkpiRec.Region__c = terriHierRegion.Id;
        actkpiRec.Survey_KPI__c = actpickupOption.id;
        actkpiRec.Target__c = 10;
        kpiAchList.add(actkpiRec);
        return actkpiRec;
    }
    static KPI_Achivement__c getKpiRecTotal3(Territory__c territory,Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c kpiRecTotal3 =  new KPI_Achivement__c();
        kpiRecTotal3.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiRecTotal3.KPI_Type__c = 'Volume Category Performance';
        kpiRecTotal3.Country__c = countryId1;
        kpiRecTotal3.Volume_Category__c ='Deluxe';
        kpiRecTotal3.Achievement__c = 15;
        kpiRecTotal3.Total_Denominator__c = 20 ;
        kpiRecTotal3.Territory__c = territory.Id;
        kpiRecTotal3.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecTotal3);
        return kpiRecTotal3;
    }
    static KPI_Achivement__c getKpiRecTotal4(Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c kpiRecTotal4 = new KPI_Achivement__c();
        kpiRecTotal4.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory Hierarchy KPI').getRecordTypeId();
        kpiRecTotal4.KPI_Type__c = 'SoS';
        kpiRecTotal4.Country__c = countryId1;
        kpiRecTotal4.Category__c ='Rum';
        kpiRecTotal4.Achievement__c = 15;
        kpiRecTotal4.Total_Denominator__c = 20 ;
        kpiRecTotal4.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecTotal4);
        return kpiRecTotal4;
    }
    static KPI_Achivement__c getKpiRecTotal5(User u){
        KPI_Achivement__c kpiRecTotal5 = new KPI_Achivement__c();
        kpiRecTotal5.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('User KPI').getRecordTypeId();
        kpiRecTotal5.KPI_Type__c = 'Unique Outlets';
        kpiRecTotal5.User__c = u.id;
        kpiRecTotal5.Achievement__c = 25;       
        kpiRecTotal5.Country__c = countryId1;
        kpiRecTotal5.Achievement__c = 15;
        kpiRecTotal5.Total_Denominator__c = 20;
        kpiAchList.add(kpiRecTotal5);
        return kpiRecTotal5;
    }
    static KPI_Achivement__c getKpiRecTotal6(Territory__c territory,Territory_Hierarchy__c terriHierRegion){
        Master_Asset__c ma=new Master_Asset__c();
        ma.Country__c=countryId1;
        ma.Priority_Assets__c=true;
        ma.Name='Test Master Asset';
        ma.Short_Description__c='Test Description';
        insert ma;
        KPI_Achivement__c kpiRecTotal6 = new KPI_Achivement__c();
        kpiRecTotal6.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiRecTotal6.KPI_Type__c = 'Asset';
        kpiRecTotal6.Country__c = countryId1;
        kpiRecTotal6.Achievement__c = 15;
        kpiRecTotal6.Master_Asset__c=ma.Id;
        kpiRecTotal6.Total_Denominator__c = 20 ;
        kpiRecTotal6.Territory__c = territory.Id;
        kpiRecTotal6.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecTotal6);
        return kpiRecTotal6;
    }
    public static  KPI_Achivement__c getKpiRecTotal(Territory__c territory,Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c kpiRecTotal = new KPI_Achivement__c();
        kpiRecTotal.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiRecTotal.KPI_Type__c = 'Total Activation Survey';
        kpiRecTotal.Country__c = countryId1;
        kpiRecTotal.Achievement__c = 15;
        kpiRecTotal.Total_Denominator__c = 20 ;
        kpiRecTotal.Territory__c = territory.Id;
        kpiRecTotal.Region__c = terriHierRegion.Id;
        kpiAchList.add(kpiRecTotal);
        return kpiRecTotal;
    }
    public static KPI_Achivement__c getActkpiTotall(Territory__c actTerr,Territory_Hierarchy__c terriHierRegion){
        KPI_Achivement__c actkpiTotal = new KPI_Achivement__c();
        actkpiTotal.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        actkpiTotal.KPI_Type__c = 'Total Activation Survey';
        actkpiTotal.Country__c = countryId1;
        actkpiTotal.Achievement__c = 15;
        actkpiTotal.Total_Denominator__c = 20 ;
        actkpiTotal.Territory__c = actTerr.Id;
        actkpiTotal.Region__c = terriHierRegion.Id;
        kpiAchList.add(actkpiTotal);
        return actkpiTotal;
    }
    
}