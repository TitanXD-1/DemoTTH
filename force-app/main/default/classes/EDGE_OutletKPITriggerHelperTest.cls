/**
* @Name: EDGE_OutletKPITriggerHelperTest

* @Req: 
* @ES20-6944 : SFDC SOS Target update

* @History                                                            
                                                            
* @VERSION   	AUTHOR            DATE              DETAIL
	1.0       Shahbaz Khan		21/02/2020		  Test class for EDGE_OutletKPITriggerHelper
	1.1		  Supriya Galinde   23/11/2021        updated testclass for EDGE_OutletKPITriggerHelper
	1.2		  Doman Murmu		20/09/2023		  145439
**/
@isTest
public class EDGE_OutletKPITriggerHelperTest {
    @isTest
    public static void outletKPIAchievementTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        system.assert(countryId!=null,'CountryId should not be null');
        
        String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        String accterrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        
        Territory_Hierarchy__c terrHirBU = new Territory_Hierarchy__c();
        terrHirBU.RecordTypeId =terrHierBURecordTypeId;
        terrHirBU.Name = 'Australia Territory Hierarchy';
        terrHirBU.Geography__c = countryId;
        insert terrHirBU;
        
        Territory_Hierarchy__c terrHirSA = new Territory_Hierarchy__c();
        terrHirSA.RecordTypeId =terrHierSARecordTypeId;
        terrHirSA.Name = 'Australia Territory Hierarchy';
        terrHirSA.Geography__c = countryId;
        terrHirSA.Parent_BU__c = terrHirBU.Id;
        terrHirSA.Pending_For_Batch__c = false;
        insert terrHirSA;
        
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'Australia Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        terrHirRG.Pending_For_Batch__c = false;
        insert terrHirRG;
        
        Territory_Hierarchy__c acrterrHirRG = new Territory_Hierarchy__c();
        acrterrHirRG.RecordTypeId =accterrHierRGRecordTypeId;
        acrterrHirRG.Name = 'Australia Activation Territory Hierarchy';
        acrterrHirRG.Geography__c = countryId;
        acrterrHirRG.Parent_BU__c = terrHirSA.Id;
        acrterrHirRG.Pending_For_Batch__c = false;
        insert acrterrHirRG;
        
        
        
        List<Territory__c> lstTerritory = new List<Territory__c>();
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Territory_Type__c = 'Sales';
        territory.Region__c = terrHirRG.id;
        territory.Pending_For_Batch__c = true;
        territory.Activation_Territory__c = acrterrHirRG.Id;
		lstTerritory.add(territory);
        
        /*
        Territory__c territory1 = EDGE_UtilityTestClass.getTerritoryRec();
        territory1.Territory_Type__c = 'Sales';
        territory1.Region__c = terrHirRG.id;
        territory1.Activation_Territory__c = acrterrHirRG.Id;
		lstTerritory.add(territory1);
        */
        insert lstTerritory;
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        
        Test.startTest();         
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        outlet.Primary_Sales_Territory__c = territory.id;
        insert outlet;
        
        Outlet_Territory__c ot = new Outlet_Territory__c();
        ot.Territory__c = territory.id;
        ot.Outlet__c =   outlet.Id;
        outlet.Status__c = 'Active';
        insert ot; 
        
        List<KPIs_Target__c> lstKPITarget = new List<KPIs_Target__c>();
        KPIs_Target__c kpiTarget = new KPIs_Target__c();
        kpiTarget.Territory__c = territory.id;
        kpiTarget.Segment__c = 'Hypermarket';
        kpiTarget.Name = 'Sample';
        kpiTarget.Target__c = 89;
        kpiTarget.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget);
        
        KPIs_Target__c kpiTarget1 = new KPIs_Target__c();
        kpiTarget1.Territory__c = territory.id;
        kpiTarget1.Segment__c = 'Hypermarket';
        kpiTarget1.Name = 'SampleHypermarket';
        kpiTarget1.Target__c = 85;
        kpiTarget1.Category__c= 'Wine';
        lstKPITarget.add(kpiTarget1);
        
        KPIs_Target__c kpiTarget2 = new KPIs_Target__c();
        kpiTarget2.Territory__c = territory.id;
        kpiTarget2.Segment__c = 'Hypermarket';
        kpiTarget2.Name = 'Test Hypermarket';
        kpiTarget2.Target__c = 33;
        kpiTarget2.Category__c= 'Rum';
        lstKPITarget.add(kpiTarget2);
        insert lstKPITarget;
        
        List<Outlet_KPI_Achievement__c> lstOutletKPIAchvmnt = new List<Outlet_KPI_Achievement__c>();
        Outlet_KPI_Achievement__c outKPIAch = new Outlet_KPI_Achievement__c();
        outKPIAch.Target__c= 89;
        outKPIAch.KPI_Type__c = 'Volume';
        outKPIAch.Actual_Numerator__c = 400;
        outKPIAch.Total_Denominator__c = 20;
        outKPIAch.Date_Of_Execution__c = Date.newInstance(2020, 04, 14);
        outKPIAch.Last_Compliant_Call_Date__c = Date.newInstance(2020, 04, 14);
        outKPIAch.Valid__c = true;
        outKPIAch.Volume_Category__c = 'Deluxe';
        outKPIAch.Outlet__c = outlet.id;
        lstOutletKPIAchvmnt.add(outKPIAch);
        
        Outlet_KPI_Achievement__c outKPIAch2 = new Outlet_KPI_Achievement__c();
        outKPIAch2.Target__c= 85;
        outKPIAch2.KPI_Type__c = 'SoS';
        outKPIAch2.Actual_Numerator__c = 200;
        outKPIAch2.Total_Denominator__c = 22;
        outKPIAch2.Valid__c = true;
        outKPIAch2.Volume_Category__c = 'Reserve';
        outKPIAch2.Outlet__c = outlet.id;
        lstOutletKPIAchvmnt.add(outKPIAch2);
        
        Outlet_KPI_Achievement__c outKPIAch3 = new Outlet_KPI_Achievement__c();
        outKPIAch3.Target__c= 33;
        outKPIAch3.KPI_Type__c = 'Coverage for Sales';
        outKPIAch3.Actual_Numerator__c = 100;
        outKPIAch3.Total_Denominator__c = 12;
        outKPIAch3.Valid__c = true;
        outKPIAch3.Volume_Category__c = 'Premium Core';
        outKPIAch3.Outlet__c = outlet.id;
        lstOutletKPIAchvmnt.add(outKPIAch3);
        insert lstOutletKPIAchvmnt;
        
        //outlet.Primary_Sales_Territory__c = territory1.id;
        //update outlet;

        outKPIAch.Target__c = 80;
        outKPIAch.Volume_Category__c = 'RTD';
        outKPIAch2.Target__c = 70;
        outKPIAch2.Volume_Category__c = 'Deluxe';
        outKPIAch3.Target__c = 50;
        outKPIAch3.Volume_Category__c = 'Liqueur';
        
        update lstOutletKPIAchvmnt;
        
        Test.stopTest();
    }

}