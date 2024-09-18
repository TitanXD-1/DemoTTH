/**
* @Name: EDGE_SalesManagerKPIBatchTest

* @Req: Test class of EDGE_SalesManagerKPIAchievementBatch

* @History                                                            

* @VERSION		AUTHOR				DATE			DETAIL
*  1.0			Preyanka Ghosh		29/10/2019		Initial Development	
*  2.0 		    Juned Khan          01/10/2020      updated createtestData to include virtual call data
*  3.0          Aparajita		    09/06/2022      ES20-12821(Commented out virtual & planned call data)
*  4.0          Joshraj Sen         08/04/2024      152305 SCA Fix
**/
@istest
public class EDGE_SalesManagerKPIBatchTest {
    
    @istest
    public static void testSalesManagerKPIBatch(){
        
        //Test.startTest(); 
        createtestData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_SalesManagerKPIAchievementBatch'
                                                  and Country_Code__c ='AU' LIMIT 1];
        system.assert(batchSetting.Id != null,'Batch is Added');
        String className = batchSetting.Batch_Class__c;
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //Test.stopTest();
    }
    
    public static void createtestData(){ 
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = True;
        orgSetting.Run_Validation_Rules__c = False;
        insert orgSetting;
        
        List<Territory__c> lstTerritory = new List<Territory__c>();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id defaultRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();
        Id surveyRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Survey_KPI').getRecordTypeId();// added by juned
        Id territoryRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Territory_KPI').getRecordTypeId();
        Id territoryHierarchyRTId = Schema.SObjectType.KPI_Achivement__c.getRecordTypeInfosByDeveloperName().get('Territory_Hierarchy_KPI').getRecordTypeId();
        
        
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Outlet_Execution_Score__c = 'Binary';
        marketSettings.Minimum_Activation_Standards__c = 'Binary';
        marketSettings.Minimum_Product_Assortment__c = 'Binary';
        marketSettings.Share_Of_Space__c = 'Binary';
        marketSettings.Share_of_Space_Facings__c = 'Facings in number';
        marketSettings.Distribution__c = 'Binary';
        marketSettings.New_Product_Distribution__c = 'Binary';
        marketSettings.Threshold_Format__c='Percent';
        insert marketSettings;
        List<Pick_Up_Options__c> pickupOptions = new List<Pick_Up_Options__c>();
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOptions.add(pickupOption);
        
        Pick_Up_Options__c surveyPickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Survey KPI');
        surveyPickupOption.Name = 'SurveyKPI[AU]';
        surveyPickupOption.Include_in_Total_Activation_Survey_KPI__c=true;
        surveyPickupOption.Applicable_Business_Role__c='Activation Specialist';
        surveyPickupOption.RecordTypeId=defaultRecTypeId;
        pickupOptions.add(surveyPickupOption);
        
        Pick_Up_Options__c activePickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Activation Type');
        activePickupOption.Name = 'activationKPI[AU]';
        activePickupOption.Applicable_Business_Role__c='Activation Specialist';
        activePickupOption.RecordTypeId=defaultRecTypeId;
        pickupOptions.add(activePickupOption);
        
        // survey kpi records not for AS
        Pick_Up_Options__c beerPrOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        beerPrOption.RecordTypeId = defaultRecTypeId;
        beerPrOption.Include_in_Total_Activation_Survey_KPI__c=true;
        beerPrOption.Applicable_Business_Role__c='Sales Rep';
        beerPrOption.Name = 'Beer Pouring[AU]';
        pickupOptions.add(beerPrOption);
        
        //activation kpi records not for AS
        Pick_Up_Options__c barTenderPckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        barTenderPckOption.RecordTypeId = defaultRecTypeId;
        barTenderPckOption.Applicable_Business_Role__c='Sales Rep';
        barTenderPckOption.Name = 'Bartender training[AU]';
        pickupOptions.add(barTenderPckOption);
        
        insert pickupOptions;
        
       
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        marc.Start_Date__c= System.today() - 25;
        marc.End_Date__c = marc.Start_Date__c.addDays(25);
        insert marc;
        Test.startTest();
        /*Set<Id> terrHierActivationSet = new Set<Id>();
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;*/
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
       // terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Pending_For_Batch__c = true;
        insert terriHier;
        system.assert(terriHier.Id != null,'Region is Added'); 
        //Sales terr
        Territory__c territory = new Territory__c();
        territory.Name = 'TAS BDM NORTH';
        territory.Status__c = 'Active';
        territory.Country__c = countryId;
        territory.Territory_Type__c = 'Sales';
        territory.Region__c = terriHier.Id;
        lstTerritory.add(territory);
        
        //region territory
       /* Territory__c terrVIC = new Territory__c();
        terrVIC.Name = 'VIC BDM BALLARAT';
        terrVIC.Status__c = 'Active';
        terrVIC.Country__c = countryId;
        terrVIC.Territory_Type__c = 'Sales';
        terrVIC.Region__c = terriHier.Id;
        lstTerritory.add(terrVIC); */
        
        insert lstTerritory;
        System.debug(LoggingLevel.Debug,'1.Number of Queries used in this apex code so far 134: ' + Limits.getQueries());
          
        //create Sales Mgr User
        User usr = EDGE_UtilityTestClass.runAsUser('Test Mgr', 'Sales Manager');
        usr.Business_Role__c = 'Sales Manager';
        usr.Email = 'testmgr@test.com';
        usr.Username = 'salesmgr@test' + Math.round(Math.random() * 10000) + '.com'; 
        usr.trax_user__c=true;
        insert usr; 
        //create Territory Member
        Territory_Member__c  terrMember = EDGE_UtilityTestClass.getTerrMemberRec();  
        terrMember.User__c = usr.Id;
        terrMember.Territory__c = territory.Id;
        terrMember.Start_Date__c = system.today(); 
        terrMember.End_Date__c = system.today().AddDays(20);
        insert terrMember;
       
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        outlet.Primary_Sales_Territory_Region__c=terriHier.Id;
        Outlet.Primary_Sales_Territory__c=territory.Id;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
          
        List<KPI_Achivement__c> lstKPIAchivement = new List<KPI_Achivement__c>();
        /*KPI_Achivement__c kpiAchivement = new KPI_Achivement__c();
        kpiAchivement.KPI_Type__c = 'Plan Call Compliance';
        kpiAchivement.Country__c = countryId;
        kpiAchivement.Territory__c = territory.Id;
        kpiAchivement.Achievement__c = 50;
        kpiAchivement.Actual_Numerator__c = 50;
        kpiAchivement.Target__c = 80;
        kpiAchivement.Total_Denominator__c = 100;
        kpiAchivement.RecordTypeId = territoryRTId;
        kpiAchivement.Region__c = terriHier.Id;
        lstKPIAchivement.add(kpiAchivement);*/
        
        /*KPI_Achivement__c kpiAchivement1 = new KPI_Achivement__c();
        kpiAchivement1.KPI_Type__c = 'SoS';
        kpiAchivement1.Category__c = 'Beer';
        kpiAchivement1.Country__c = countryId;
        kpiAchivement1.Territory__c = terrVIC.Id;
        kpiAchivement1.Achievement__c = 50;
        kpiAchivement1.Actual_Numerator__c = 50;
        kpiAchivement1.Target_Number__c = 70;
        kpiAchivement1.Total_Denominator__c = 200;
        kpiAchivement1.RecordTypeId = territoryRTId;
        kpiAchivement1.Region__c =terriHier.Id; 
        lstKPIAchivement.add(kpiAchivement1);
        
        KPI_Achivement__c kpiAchivement2 = new KPI_Achivement__c();
        kpiAchivement2.KPI_Type__c = 'SoS';
        kpiAchivement2.Category__c = 'Beer';
        kpiAchivement2.Country__c = countryId;
        kpiAchivement2.Territory__c = terrVIC.Id;
        kpiAchivement2.Achievement__c = 50;
        kpiAchivement2.Actual_Numerator__c = 50;
        kpiAchivement2.Target_Number__c = 70;
        kpiAchivement2.Total_Denominator__c = 200;
        kpiAchivement2.RecordTypeId = territoryRTId;
        kpiAchivement2.Region__c = terriHier.Id; 
        lstKPIAchivement.add(kpiAchivement2);*/
        
        /*KPI_Achivement__c virCallKpiAchivement = new KPI_Achivement__c();
        virCallKpiAchivement.KPI_Type__c = 'Virtual Call Compliance';
        virCallKpiAchivement.Country__c = countryId;
        virCallKpiAchivement.Territory__c = territory.Id;
        virCallKpiAchivement.Achievement__c = 40;
        virCallKpiAchivement.Actual_Numerator__c = 40;
        virCallKpiAchivement.Target__c = 60;
        virCallKpiAchivement.Total_Denominator__c = 100;
        virCallKpiAchivement.RecordTypeId = territoryHierarchyRTId;
        virCallKpiAchivement.Region__c =terriHier.Id; 
        lstKPIAchivement.add(virCallKpiAchivement);*/
        
        KPI_Achivement__c totactKpiAchivement = new KPI_Achivement__c();
        totactKpiAchivement.KPI_Type__c = 'Total Activation Survey';
        totactKpiAchivement.Country__c = countryId;
        totactKpiAchivement.Territory__c = territory.Id;
        totactKpiAchivement.Achievement__c = 30;
        totactKpiAchivement.Actual_Numerator__c = 10;
        totactKpiAchivement.Target__c = 30;
        totactKpiAchivement.Total_Denominator__c = 200;
        totactKpiAchivement.RecordTypeId = territoryRTId;
        totactKpiAchivement.Region__c =terriHier.Id; 
        lstKPIAchivement.add(totactKpiAchivement);
        
        //new
        KPI_Achivement__c volCatKpi = new KPI_Achivement__c();
        volCatKpi.KPI_Type__c = 'Volume Category Performance';
        volCatKpi.Volume_Category__c = 'Deluxe';
        volCatKpi.Total_Denominator__c = 100;
        volCatKpi.Actual_Numerator__c = 50;
        volCatKpi.Achievement__c = 50;
        volCatKpi.Territory__c = territory.Id;
        volCatKpi.Region__c = terriHier.Id;
        volCatKpi.RecordTypeId = territoryRTId;
        volCatKpi.Target__c = 25;
        lstKPIAchivement.add(volCatKpi);
        
        // territory level survey kpi
        KPI_Achivement__c surveyKpiAchivement = new KPI_Achivement__c();
        surveyKpiAchivement.KPI_Type__c = 'Survey';
        surveyKpiAchivement.Survey_KPI__c=surveyPickupOption.Id;
        surveyKpiAchivement.Country__c = countryId;
        surveyKpiAchivement.Territory__c = territory.Id;
        surveyKpiAchivement.Achievement__c = 30;
        surveyKpiAchivement.Actual_Numerator__c = 10;
        surveyKpiAchivement.Target__c = 30;
        surveyKpiAchivement.Total_Denominator__c = 200;
        surveyKpiAchivement.RecordTypeId = surveyRTId;
        //surveyKpiAchivement.Region__c =terriHier.Id; 
        lstKPIAchivement.add(surveyKpiAchivement);
        
        // territory level activation survey kpi
        KPI_Achivement__c actKpiAchivement = new KPI_Achivement__c();
        actKpiAchivement.KPI_Type__c = 'Activation Survey KPI';
        actKpiAchivement.Activation_Type__c=activePickupOption.Id;
        actKpiAchivement.Country__c = countryId;
        actKpiAchivement.Territory__c = territory.Id;
        actKpiAchivement.Achievement__c = 30;
        actKpiAchivement.Actual_Numerator__c = 10;
        //actKpiAchivement.Target__c = 30;
        actKpiAchivement.Total_Denominator__c = 200;
        actKpiAchivement.RecordTypeId = territoryRTId;
        actKpiAchivement.Region__c =terriHier.Id; 
        lstKPIAchivement.add(actKpiAchivement);
        
        //AT level activation kpi
        KPI_Achivement__c atactKpiAchivement = new KPI_Achivement__c();
        atactKpiAchivement.KPI_Type__c = 'Activation Survey KPI';
        atactKpiAchivement.Activation_Type__c=activePickupOption.Id;
        atactKpiAchivement.Country__c = countryId;
        atactKpiAchivement.Achievement__c = 30;
        atactKpiAchivement.Actual_Numerator__c = 10;
        atactKpiAchivement.Total_Denominator__c = 200;
        atactKpiAchivement.RecordTypeId =territoryHierarchyRTId ;
        lstKPIAchivement.add(atactKpiAchivement);
        
        //AT level survey activation kpi
        KPI_Achivement__c atsurveyKpiAchivement = new KPI_Achivement__c();
        atsurveyKpiAchivement.KPI_Type__c = 'Survey';
        atsurveyKpiAchivement.Survey_KPI__c=surveyPickupOption.Id;
        atsurveyKpiAchivement.Country__c = countryId;
        atsurveyKpiAchivement.Achievement__c = 30;
        atsurveyKpiAchivement.Actual_Numerator__c = 10;
        atsurveyKpiAchivement.Target__c = 30;
        atsurveyKpiAchivement.Total_Denominator__c = 200;
        atsurveyKpiAchivement.RecordTypeId = surveyRTId;
        lstKPIAchivement.add(atsurveyKpiAchivement);
        
        
        //AT level total activation kpi
        KPI_Achivement__c totalatactKpiAchivement = new KPI_Achivement__c();
        totalatactKpiAchivement.KPI_Type__c = 'Total Activation Survey';
        totalatactKpiAchivement.Activation_Type__c=activePickupOption.Id;
        totalatactKpiAchivement.Country__c = countryId;
        totalatactKpiAchivement.Achievement__c = 30;
        totalatactKpiAchivement.Actual_Numerator__c =20 ;
        totalatactKpiAchivement.Target__c = 30;
        totalatactKpiAchivement.Total_Denominator__c = 200;
        totalatactKpiAchivement.RecordTypeId =territoryHierarchyRTId ;
        lstKPIAchivement.add(totalatactKpiAchivement);
        
        KPI_Achivement__c assetKpiAchivement = new KPI_Achivement__c();
        assetKpiAchivement.KPI_Type__c = 'Asset';
        assetKpiAchivement.Country__c = countryId;
        assetKpiAchivement.Achievement__c = 15;      
        assetKpiAchivement.Total_Denominator__c = 20 ;
        assetKpiAchivement.Territory__c = territory.Id;
        assetKpiAchivement.Region__c = terriHier.Id;
        assetKpiAchivement.RecordTypeId = territoryHierarchyRTId;
        lstKPIAchivement.add(assetKpiAchivement);
        
        KPI_Achivement__c npdkpiAchivement = new KPI_Achivement__c();
        npdkpiAchivement.KPI_Type__c = 'NPD';
        npdkpiAchivement.Country__c = countryId;
        npdkpiAchivement.Achievement__c = 15;
        npdkpiAchivement.Total_Denominator__c = 20 ;
        npdkpiAchivement.Territory__c = territory.Id;
        npdkpiAchivement.Region__c = terriHier.Id;
        npdkpiAchivement.RecordTypeId = territoryHierarchyRTId;
        lstKPIAchivement.add(npdkpiAchivement);
         
       
       
        
        upsert lstKPIAchivement;
        Test.stopTest(); 
        List<Territory_Hierarchy__c> qualityRegionList = new List<Territory_Hierarchy__c>();
        Territory_Hierarchy__c terrHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId,'Quality Territory Hierarchy');
        qualityRegionList.add(terrHier);
        insert qualityRegionList;
        
       /* Outlet_Member__c outletMem =new Outlet_Member__c();
        outletMem.Outlet__c=outlet.Id;
        outletMem.User__c=UserInfo.getUserId();
        outletMem.Outlet_Role__c='Primary';
        insert  outletMem;*/
        
        
        EDGE_SalesMgrKPIAchievementBatchHelper.calculateTerrHierarchyKPIs(qualityRegionList,true,'Quality');
        
        /* marketSettings.Share_of_Space_Facings__c = 'Facings in %';
        update marketSettings;
        KPI_Achivement__c SOSKpiAchivement = new KPI_Achivement__c();
        SOSKpiAchivement.KPI_Type__c = 'SoS';
        SOSKpiAchivement.Actual_Numerator__c = 10;
        SOSKpiAchivement.Total_Denominator__c = 20;
        SOSKpiAchivement.Achievement__c =30;
        SOSKpiAchivement.Target__c = 40;
        SOSKpiAchivement.Previous_Achievement__c = 50;
        SOSKpiAchivement.Total_Outlets__c = 1;
        SOSKpiAchivement.Country__c = countryId;
        SOSKpiAchivement.Territory__c = territory.Id;
        SOSKpiAchivement.Region__c = terriHier.Id;
        SOSKpiAchivement.RecordTypeId = territoryHierarchyRTId;
        insert SOSKpiAchivement;*/
    }
}