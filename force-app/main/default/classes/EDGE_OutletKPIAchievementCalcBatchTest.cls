/**
 * @ Purpose: Test Class EDGE_OutletKPIAchievementCalcBatchTest
 * @ History                         
 * @ VERSION      AUTHOR                  DATE              DETAIL
 * 1.0         Monalisa Halder         08/01/2020        ES20-9195
 * 2.0         Rubeena Naaz 		   29/11/2021		 ES20-11036
 * 3.0		   Shivam Chauhan	 		18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
**/
@isTest
public class EDGE_OutletKPIAchievementCalcBatchTest {
    
    @isTest
    public static void testOutletKPIAchievementCalcBatch(){
        Test.startTest();
        createTestData();
        Test.stopTest();
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OutletKPIAchievementCalcBatch'
                                                  and Country_Code__c ='AU'];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }
    @isTest    
    public static void createTestData(){
        Map<Id,Territory__c> terrMap = new  Map<Id,Territory__c>();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        system.assert(countryId!=null,'countryId should not be null');
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Outlet_Execution_Score__c = 'Binary';
        marketSettings.Minimum_Activation_Standards__c = 'Binary';
        marketSettings.Minimum_Product_Assortment__c = 'Binary';
        marketSettings.Share_Of_Space__c = 'Binary';
        marketSettings.Share_of_Space_facings__c = 'Facings in number';
        marketSettings.Distribution__c = 'Binary';
        marketSettings.New_Product_Distribution__c = 'Binary';
        insert marketSettings;
        
        
        String terrHierBURecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Business Unit').getRecordTypeId();
        String terrHierSARecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Area').getRecordTypeId();
        String terrHierRGRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory Hierarchy').getRecordTypeId();
        String terrRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
        String terrHierRegionRecordTypeId = Territory_Hierarchy__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Region').getRecordTypeId();
        String terrAtRecordTypeId = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        
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
        insert terrHirSA;
        
        Territory_Hierarchy__c terrHirRG = new Territory_Hierarchy__c();
        terrHirRG.RecordTypeId =terrHierRGRecordTypeId;
        terrHirRG.Name = 'Australia Territory Hierarchy';
        terrHirRG.Geography__c = countryId;
        terrHirRG.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG;
               
        Territory_Hierarchy__c terrHirRG2 = new Territory_Hierarchy__c();
        terrHirRG2.RecordTypeId =terrHierRegionRecordTypeId;
        terrHirRG2.Name = 'Australia Territory Hierarchy';
        terrHirRG2.Geography__c = countryId;
        terrHirRG2.Parent_BU__c = terrHirSA.Id;
        insert terrHirRG2;
        
        List<Territory__c> terrList=new List<Territory__c>();
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        territory.Country__c = countryId;
        territory.Territory_Type__c = 'Quality Service / Executive';
        territory.Region__c = terrHirRG.id;
        territory.Pending_For_Batch__c = True;
        territory.RecordTypeId = terrRecordTypeId;
        territory.Status__c = 'Active';
        //insert territory;
        terrList.add(territory);
        
        Territory__c territory3 = EDGE_UtilityTestClass.getTerritoryRec();
        territory3.Country__c = countryId;
        territory3.Territory_Type__c = 'Quality Dispense';
        territory3.Region__c = terrHirRG.id;
        territory3.Business_Unit__c=terrHirBU.id;
        territory3.Sales_Area__c=terrHirSA.id;
        territory3.Pending_For_Batch__c = True;
        territory3.RecordTypeId = terrRecordTypeId;
        //i/nsert territory3;
        terrList.add(territory3);
        
        Territory__c territory2 = EDGE_UtilityTestClass.getTerritoryRec();
        territory2.Country__c = countryId;
        territory2.Territory_Type__c = 'Sales';
        territory2.Region__c = terrHirRG2.id;
        territory2.Pending_For_Batch__c = True;
        territory2.Status__c = 'Active';
        //territory2.RecordTypeId = terrRecordTypeId;
        //insert territory2;
        terrList.add(territory2);
        
        Territory__c territory4 = EDGE_UtilityTestClass.getTerritoryRec();
        territory4.Country__c = countryId;
        territory4.Territory_Type__c = 'Activation Territory';
        territory4.Pending_For_Batch__c = True;
        territory4.Status__c = 'Active';
        territory4.RecordTypeId = terrAtRecordTypeId;
        terrList.add(territory4);
        Database.insert(terrList);
        
        
        terrMap.put(territory2.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory2.Id ]);
        //terrMap.put(territory2.Id, [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c WHERE Id =: territory2.Id ]);
        //terrMap.put(territory2.Id, territory2);
        //terrMap.put(territory.Id, territory);
        
        /*for(Territory__c terr : [SELECT ID,Volume_Actual_Points__c, MAS_Target__c, MPA_Target__c, NPD_Target__c, OES_Target__c, Distribution_Target__c,Coverage_Compliance_Target__c, Outlet_Visit_Compliance_Target__c, Plan_Calls_Compliance_Target__c, Region__c FROM Territory__c]){
            terrMap.put(terr.Id,terr);
        }*/
                                 
        system.debug(LoggingLevel.Debug,'terrMap++'+terrMap);
        // create custom Market Cycle
        Market_Cycle__c newMC = new Market_Cycle__c();
        newMC.Start_Date__c = Date.today();
        newMC.End_Date__c = newMC.Start_Date__c.addDays(14);
        newMC.Geography__c = countryId;
        insert newMC;
        
        // create custom Territory Cycle
        Territory_Cycle__c newTC= new Territory_Cycle__c();
        newTC.Market_Cycle__c = newMC.ID;
        newTC.Territory__c = territory.id;
        insert newTC;
        
        Territory_Cycle__c newTC2= new Territory_Cycle__c();
        newTC2.Market_Cycle__c = newMC.ID;
        newTC2.Territory__c = territory2.id;
        insert newTC2;
        
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Type__c = 'Outlet Visit Prioritization';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet.Independent_of_Owner__c = true;
        //outlet.Pending_For_Outlet_KPI_Achievement__c = true;
        //outlet.Primary_Sales_Territory__c = territory.id;
        outlet.Status__c = 'Active';
        insert outlet;
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name = 'Test_Outlet2';
        outlet2.AccountNumber = '90909';
        outlet2.Outlet_Email_Address__c = 'test1@test1.com';
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption.Id;
        outlet2.Independent_of_Owner__c = true;
        //outlet.Pending_For_Outlet_KPI_Achievement__c = true;
        outlet2.Primary_Sales_Territory__c = territory2.id;
        outlet2.Activation_Territory_LT__c = terrList[3].Id;
        outlet2.BillingStreet = '18 South Highway 45';
        outlet2.BillingCity = 'Brisbane';
        outlet2.BillingPostalCode = '5669';
        outlet2.BillingState = 'Queensland';
        outlet2.Status__c = 'Active';
        insert outlet2;
        Set<Id> outletIdSet = new Set<Id>();
        outletIdSet.Add(outlet.Id);
        outletIdSet.Add(outlet2.Id);
        
        Outlet_Territory__c outletTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, terrList[0].Id);
        outletTer.Active__c = 'Active';
        insert outletTer;
        
        Outlet_Territory__c outletTer2 = EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, terrList[2].Id);
        outletTer2.Active__c = 'Active';
        insert outletTer2;
        Outlet_Territory__c outletTer3 = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, terrList[1].Id);
        outletTer2.Active__c = 'Active';
        insert outletTer3;
        Outlet_Territory__c outletTer4 = EDGE_UtilityTestClass.getOutltTerritory(outlet2.Id, terrList[3].Id);
        outletTer4.Active__c = 'Active';
        insert outletTer4;
        
        
        List<KPIs_Target__c> lstKPITarget = new List<KPIs_Target__c>();
        KPIs_Target__c kpiTarget = new KPIs_Target__c();
        kpiTarget.Territory__c = territory.id;
        kpiTarget.Segment__c = 'Hypermarket';
        kpiTarget.Name = 'Sample';
        kpiTarget.Target__c = 89;
        kpiTarget.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget);
        
        KPIs_Target__c kpiTarget2 = new KPIs_Target__c();
        kpiTarget2.Territory__c = territory2.id;
        kpiTarget2.Segment__c = 'Hypermarket';
        kpiTarget2.Name = 'Sample';
        kpiTarget2.Target__c = 89;
        kpiTarget2.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget2);
        
        KPIs_Target__c kpiTarget1 = new KPIs_Target__c();
        kpiTarget1.Territory__c = territory.id;
        kpiTarget1.Segment__c = 'Hypermarket';
        kpiTarget1.Name = 'SampleHypermarket';
        kpiTarget1.Target__c = 85;
        kpiTarget1.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget1);
        
        KPIs_Target__c kpiTarget3 = new KPIs_Target__c();
        kpiTarget3.Territory__c = territory2.id;
        kpiTarget3.Segment__c = 'Hypermarket';
        kpiTarget3.Name = 'SampleHypermarket';
        kpiTarget3.Target__c = 85;
        kpiTarget3.Category__c= 'Beer';
        lstKPITarget.add(kpiTarget3);
        
        insert lstKPITarget; 
        
        List<Outlet_KPI_Achievement__c> outletKPIAcivmtList = new List<Outlet_KPI_Achievement__c>();
        Outlet_KPI_Achievement__c outKPIAch = new Outlet_KPI_Achievement__c();
        outKPIAch.Target__c=91;
        outKPIAch.KPI_Type__c = 'SoS';
        outKPIAch.Category__c = 'Gin';
        outKPIAch.Outlet__c = outlet.id;
        outletKPIAcivmtList.add(outKPIAch);
        
        Outlet_KPI_Achievement__c outKPIAch4 = new Outlet_KPI_Achievement__c();
        outKPIAch4.Target__c=90;
        outKPIAch4.KPI_Type__c = 'SoS';
        outKPIAch4.Category__c = 'Gin';
        outKPIAch4.Outlet__c = outlet2.id;
		outletKPIAcivmtList.add(outKPIAch4);
        
        Outlet_KPI_Achievement__c outKPIAch1 = new Outlet_KPI_Achievement__c();
        outKPIAch1.Target__c=81;
        outKPIAch1.KPI_Type__c = 'SoS';
        outKPIAch1.Category__c = 'Liqueur';
        outKPIAch1.Outlet__c = outlet.id;
        
        Outlet_KPI_Achievement__c outKPIAch3 = new Outlet_KPI_Achievement__c();
        outKPIAch3.Target__c=80;
        outKPIAch3.KPI_Type__c = 'SoS';
        outKPIAch3.Category__c = 'Liqueur';
        outKPIAch3.Outlet__c = outlet2.id;
        
        outletKPIAcivmtList.add(outKPIAch1);
        outletKPIAcivmtList.add(outKPIAch3);
        insert outletKPIAcivmtList;
        
        KPI_Achivement__c kpiAch = new KPI_Achivement__c();
        kpiAch.KPI_Type__c = 'SoS';
        kpiAch.Category__c = 'Gin';
        kpiAch.Total_Denominator__c = 100;
        kpiAch.Actual_Numerator__c = 50;
        kpiAch.Achievement__c = 50;
        kpiAch.Territory__c = territory.Id;
        kpiAch.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch.Unique_Key__c = territory.Id+'_'+'SoS'+'_'+'Gin';
        kpiAch.Total_Outlets__c = 4;
        kpiAch.Target__c = 25;
        kpiAch.Region__c = terrHirRG.Id;
        insert kpiAch;
        
        KPI_Achivement__c kpiAch2 = new KPI_Achivement__c();
        kpiAch2.KPI_Type__c = 'SoS';
        kpiAch2.Category__c = 'Gin';
        kpiAch2.Total_Denominator__c = 100;
        kpiAch2.Actual_Numerator__c = 50;
        kpiAch2.Achievement__c = 50;
        kpiAch2.Territory__c = territory2.Id;
        kpiAch2.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch2.Unique_Key__c = territory2.Id+'_'+'SoS'+'_'+'Gin';
        kpiAch2.Total_Outlets__c = 4;
        kpiAch2.Target__c = 25;
        kpiAch.Region__c = terrHirRG2.Id;
        insert kpiAch2;
        
        
        KPI_Achivement__c kpiAch3 = new KPI_Achivement__c();
        kpiAch3.KPI_Type__c = 'Volume Category Performance';
        kpiAch3.Volume_Category__c = 'RTD';
        kpiAch3.Total_Denominator__c = 100;
        kpiAch3.Actual_Numerator__c = 50;
        kpiAch3.Achievement__c = 50;
        kpiAch3.Territory__c = territory2.Id;
        kpiAch3.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiAch3.Unique_Key__c = territory2.Id+'_'+'Volume'+'_'+'RTD';
        kpiAch3.Total_Outlets__c = 4;
        kpiAch3.Target__c = 25;
        kpiAch3.Region__c = terrHirRG2.Id;
        insert kpiAch3;
        
        
        Map<Id, Territory_Cycle__c> territoryWithCycleMap = new Map<Id, Territory_Cycle__c>();
        //territoryWithCycleMap.put(newTC.Id, newTC);
        territoryWithCycleMap.put(newTC2.Id, newTC2);
        //EDGE_KPIAchivementOperations.calculateSOSandVolumeCategoryKPIAchivements(terrMap,territoryWithCycleMap,outletKPIAcivmtList, 'AU',outletIdSet);
        //EDGE_KPIAchivementOperations.calculateAssetKPIAchivements(terrMap, null, 'AU');
        Outlet_KPI_Achievement__c outKPIAch2 = new Outlet_KPI_Achievement__c();
        outKPIAch2.Target__c=90;
        outKPIAch2.Actual_Numerator__c = 15;
        outKPIAch2.Total_Denominator__c = 20 ; 
        outKPIAch2.Achievement__c = 40;
        outKPIAch2.KPI_Type__c = 'SoS';
        outKPIAch2.Category__c = 'Liqueur';
        outKPIAch2.Outlet__c = outlet.id;
        
        Outlet_KPI_Achievement__c outKPIAch5 = new Outlet_KPI_Achievement__c();
        outKPIAch5.Target__c=90;
        outKPIAch5.Actual_Numerator__c = 15;
        outKPIAch5.Total_Denominator__c = 20 ;
        outKPIAch5.Achievement__c = 40;
        outKPIAch5.KPI_Type__c = 'SoS';
        outKPIAch5.Category__c = 'Liqueur';
        outKPIAch5.Outlet__c = outlet2.id;
        
        
        Outlet_KPI_Achievement__c outKPIAch6 = new Outlet_KPI_Achievement__c();
        outKPIAch6.Target__c=90;
        outKPIAch6.KPI_Type__c = 'Volume';
        outKPIAch6.Volume_Category__c = 'RTD';
        outKPIAch6.Achievement__c = 40;
        outKPIAch6.Actual_Numerator__c = 15;
        outKPIAch6.Total_Denominator__c = 20 ;
        outKPIAch6.Outlet__c = outlet2.id;
        
        List<Outlet_KPI_Achievement__c> outletKpiList = new List<Outlet_KPI_Achievement__c>();
        outletKpiList.add(outKPIAch2);
        outletKpiList.add(outKPIAch5);
        outletKpiList.add(outKPIAch6);
        try{
            insert outletKpiList;
        }catch(Exception e){
            System.debug(LoggingLevel.Debug,'excption::::'+e.getMessage());
        }
        
        
    }
    
}