/**

* @Description: EDGE_OutletSurveyKPIRollupBatchTest

* @Purpose : This is the test class for EDGE_OutletSurveyKPIRollupBatch

* @History:

* @Version     Developer		   	 Date			    Story/Purpose

*   1.1        Sandip Ghosh        	22/01/2020        Initial Development
*	1.2		   Rajarshi Lahiri		03/08/2022		  [ES20-13190]

*/

@isTest
public class EDGE_OutletSurveyKPIRollupBatchTest {
    
    private static Boolean isPrintFlagON = true;
    private static Integer govLimitDebugCount = 1;
    private static String dfltPickupRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
    public static Map<String,Id> geoMap = new Map<String,Id>();
    
    @testSetup
    public static void createData(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        /*Id countryId = setupCountry('ES');
Id plCountryId = setupCountryPL('PL'); //plCountryId
Id ieCountryId = setupCountryIE('IE');
Id nirCountryId = setupCountryNIR('NIR');
System.debug('countryId = '+ countryId);*/
        List<Territory__c> terrList=new List<Territory__c>();
        
        //Creating Territory Hierarchy BU
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        
        //Creating Territory Hierarchy Sales Area
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        
        //Creating Territory Hierarchy Region
        Territory_Hierarchy__c terriHierRegion = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHierRegion.Parent_BU__c = terriHierSA.Id;
        insert terriHierRegion;
        
        
        
        //Creating Territory record(s)
        Territory__c salesTerritory = new Territory__c();
        salesTerritory.Territory_Type__c = 'Sales';
        salesTerritory.Status__c = 'Active';
        salesTerritory.Country__c = countryID;
        salesTerritory.Region__c = terriHierRegion.Id;
        salesTerritory.Pending_For_Batch__c = true;
        terrList.add(salesTerritory);
        
        Territory__c actTerritory = new Territory__c();
        actTerritory.Territory_Type__c = 'Activation Territory';
        actTerritory.Status__c = 'Active';
        actTerritory.RecordTypeId=Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();
        actTerritory.Country__c = countryID;
        actTerritory.Pending_For_Batch__c = true;
        terrList.add(actTerritory);
        
        Territory__c qualityTerritory = new Territory__c();
        qualityTerritory.Territory_Type__c = 'Quality Dispense';
        qualityTerritory.Status__c = 'Active';
        qualityTerritory.RecordTypeId=Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
        qualityTerritory.Country__c = countryID;
        qualityTerritory.Pending_For_Batch__c = true;
        terrList.add(qualityTerritory);
        insert terrList;
        
        Test.startTest();
        List<Pick_Up_Options__c> pickupOptions = new List<Pick_Up_Options__c>();
        
      //  Test.startTest();
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pOption.Name = 'Gold[AU]';
        pickupOptions.add(pOption);
        
        Pick_Up_Options__c whiskPrOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        whiskPrOption.RecordTypeId = dfltPickupRecTypeId;
        whiskPrOption.Name = 'Whisky Pouring[AU]';
        pickupOptions.add(whiskPrOption);
        //insert whiskPrOption;
        
        
        Pick_Up_Options__c beerPrOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        beerPrOption.RecordTypeId = dfltPickupRecTypeId;
        beerPrOption.Name = 'Beer Pouring [AU]';
        pickupOptions.add(beerPrOption);
        
        Pick_Up_Options__c barTenderPckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        barTenderPckOption.RecordTypeId = dfltPickupRecTypeId;
        barTenderPckOption.Name = 'Bartender training [AU]';
        pickupOptions.add(barTenderPckOption);
        
        Pick_Up_Options__c pouringPckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        pouringPckOption.RecordTypeId = dfltPickupRecTypeId;
        pouringPckOption.Name = 'Pouring [AU]';
        pickupOptions.add(pouringPckOption);
		
		//ES20-12217        
         Pick_Up_Options__c actterrPckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        actterrPckOption.RecordTypeId = dfltPickupRecTypeId;
        actterrPckOption.Name = 'Bartender training1 [AU]';
        actterrPckOption.Applicable_Business_Role__c='Activation Specialist';
        pickupOptions.add(actterrPckOption);
        
        Pick_Up_Options__c surveyOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        surveyOption.RecordTypeId = dfltPickupRecTypeId;
        surveyOption.Name = 'Beer Pouring1 [AU]';
        //SurveyOption.Applicable_Business_Role__c='Activation Specialist';
        pickupOptions.add(surveyOption);
        
        insert pickupOptions;
       
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        marc.Start_Date__c= System.today() - 25;
        marc.End_Date__c = marc.Start_Date__c.addDays(25);
        insert marc;
        printGovnLimits();
        
        List<Account> outlets = new List<Account>();
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'outlet_1';
        outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet.Primary_Sales_Territory__c = salesTerritory.Id;
        outlets.add(outlet);
        //insert outlet;
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Name = 'outlet_2';
        outlet2.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet2.Primary_Sales_Territory__c = salesTerritory.Id;
        //insert outlet2;
        outlets.add(outlet2);
        
        //ES20-12217
        Account outlet3 = EDGE_UtilityTestClass.getOutletRecord();
        outlet3.Name = 'outlet_3';
        outlet3.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet3.Activation_Territory_LT__c = actTerritory.Id;
        //insert outlet2;
        outlets.add(outlet3);
        
        Database.insert(outlets);
        
        List<Outlet_Territory__c> outletTeList = new List<Outlet_Territory__c>();
            
            Outlet_Territory__c soutletTer1 = EDGE_UtilityTestClass.getOutltTerritory(outlets[0].Id, salesTerritory.Id);
        	soutletTer1.Active__c='Active';
            //insert soutletTer;
            outletTeList.add(soutletTer1);
            Outlet_Territory__c soutletTer2 = EDGE_UtilityTestClass.getOutltTerritory(outlets[1].Id, salesTerritory.Id);
        	soutletTer2.Active__c='Active';
            //insert soutletTer;
            outletTeList.add(soutletTer2);
            Outlet_Territory__c qoutletTer1 = EDGE_UtilityTestClass.getOutltTerritory(outlets[2].Id, actTerritory.Id);
        	qoutletTer1.Active__c='Active';
            //insert qoutletTer1;
            outletTeList.add(qoutletTer1);
        	
        	Outlet_Territory__c qualTer1 = EDGE_UtilityTestClass.getOutltTerritory(outlets[0].Id, qualityTerritory.Id);
        	qualTer1.Active__c='Active';
            //insert qoutletTer1;
            outletTeList.add(qualTer1);
        
        	Outlet_Territory__c qualTer2 = EDGE_UtilityTestClass.getOutltTerritory(outlets[1].Id, qualityTerritory.Id);
        	qualTer2.Active__c='Active';
            //insert qoutletTer1;
            outletTeList.add(qualTer2);
            
            Database.insert(outletTeList);
        
        printGovnLimits();
        
        //Test.startTest();
        List<Survey__c> surveyLst = new List<Survey__c>();
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        survey.Name = 'test_survey_1';
        survey.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        //insert survey;
        surveyLst.add(survey);
        
        Survey__c survey2 = EDGE_UtilityTestClass.getSurvey(countryId);
        survey2.Name = 'test_survey_2';
        survey2.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        //insert survey2;
        surveyLst.add(survey2);
        
        //ES20-11893 STARTS
        Survey__c surveyTest = EDGE_UtilityTestClass.getSurvey(countryID);
        surveyTest.Name = 'test_survey';
        surveyTest.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        //insert surveyTest;
        surveyLst.add(surveyTest);
        
        insert surveyLst;
        
        Survey_Question__c surveyQues = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQues.Question__c = 'Whisky Pouring Survey QS1';
        surveyQues.Response_Type__c = 'RadioButton';
        surveyQues.Active__c = true;
        surveyQues.Survey_KPI__c = whiskPrOption.Id;
        //insert surveyQues;
        
        
        
        List<Survey_Question__c> sQLst = new List<Survey_Question__c>();
        sQLst.add(surveyQues);
        
        Survey_Question__c surveyQues21 = EDGE_UtilityTestClass.getSurveyQuestion(survey2.Id);
        surveyQues21.Question__c = 'BarTending Survey QS211';
        surveyQues21.Response_Type__c = 'Number';
        surveyQues21.Active__c = true;
        surveyQues21.Activation_Type__c = barTenderPckOption.Id;
        //insert surveyQues21;
        sQLst.add(surveyQues21);
        
        Survey_Question__c surveyQues22 = EDGE_UtilityTestClass.getSurveyQuestion(survey2.Id);
        surveyQues22.Question__c = 'BarTending Survey QS212';
        surveyQues22.Response_Type__c = 'Number';
        surveyQues22.Active__c = true;
        surveyQues22.Activation_Type__c = pouringPckOption.Id;
        //insert surveyQues22;
        sQLst.add(surveyQues22);
        
        printGovnLimits();
        
        
        
        
        Survey_Question__c surveyQuesA = EDGE_UtilityTestClass.getSurveyQuestion(surveyTest.Id);
        surveyQuesA.Question__c = 'Whisky Pouring Survey Test';
        surveyQuesA.Response_Type__c = 'RadioButton';
        surveyQuesA.Active__c = true;
        surveyQuesA.Survey_KPI__c = whiskPrOption.Id;
        //insert surveyQuesA;
        SQLst.add(surveyQuesA);
        
        Survey_Question__c surveyQuesB = EDGE_UtilityTestClass.getSurveyQuestion(surveyTest.Id);
        surveyQuesB.Question__c = 'BarTending Survey Test';
        surveyQuesB.Response_Type__c = 'Number';
        surveyQuesB.Active__c = true;
        surveyQuesB.Activation_Type__c = barTenderPckOption.Id;
        //insert surveyQuesB;
        sQLst.add(surveyQuesB);
        insert sQLst;
        
        Outlet_Survey__c otSurveyTest = EDGE_UtilityTestClass.getOutletSurvey(surveyTest.Id, outlet.Id);
        otSurveyTest.Survey_Valid_From__c = system.today() - 10;
        insert otSurveyTest;
        
        Survey_Answer__c srvyAnswerA = new Survey_Answer__c();
        srvyAnswerA.Bonus_Applicable_Response__c = true;
        srvyAnswerA.Option_Value__c = 'Whisky Pouring Survey A';
        srvyAnswerA.Survey_Question__c = surveyQuesA.Id;
        insert srvyAnswerA;
        
        otSurveyTest.Achievement_status__c = 'Complete';
        otSurveyTest.Completion_Date__c = system.today();
        update otSurveyTest;
        
        List<Outlet_Survey_Response__c> osrLst = new List<Outlet_Survey_Response__c>();
        Outlet_Survey_Response__c otSurveyResB = EDGE_UtilityTestClass.getOutletSurveyRes(otSurveyTest.Id,surveyQuesB.Id);
        otSurveyResB.Response__c = '10';
        //insert otSurveyResB;
        osrLst.add(otSurveyResB);
        
        Outlet_Survey_Response__c otSurveyResA = EDGE_UtilityTestClass.getOutletSurveyRes(otSurveyTest.Id,surveyQuesA.Id);
        otSurveyResA.Response__c = 'Whisky Pouring Survey TestAns';
        //insert otSurveyResA;
        osrLst.add(otSurveyResA);
        insert osrLst;
        
        Map<String, KPI_Achivement__c> kpiAchievementMap = new Map<String, KPI_Achivement__c>();
        Map<String, KPI_Achivement__c> kpiAchievementNullMap = new Map<String, KPI_Achivement__c>();
        Map<Id, Territory__c> territoryMap = new Map<Id, Territory__c>();
        
        Decimal outletResp = 0;
        Integer numberOfOutlets = 1;
        
        KPI_Achivement__c kpiRecTotal = new KPI_Achivement__c();
        kpiRecTotal.RecordTypeId = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
        kpiRecTotal.KPI_Type__c = 'Total Activation Survey';
        kpiRecTotal.Country__c = countryID;
        kpiRecTotal.Total_Denominator__c = 20;
        kpiRecTotal.Actual_Numerator__c = 1;
        kpiRecTotal.Achievement__c = 5;  
        kpiRecTotal.Territory__c = salesTerritory.Id;
        kpiRecTotal.Region__c = terriHierRegion.Id;
        insert kpiRecTotal;
                
        kpiAchievementMap.put(salesTerritory.Id,kpiRecTotal);
        kpiAchievementNullMap.put('test', kpiRecTotal);
        
        territoryMap.put(salesTerritory.Id, salesTerritory);
        
        EDGE_OutletSurveyKPIRollupBatchHelper.calcTotalAcvSrvyKPI(salesTerritory.Id, kpiRecTotal, outletResp, kpiAchievementMap, numberOfOutlets, territoryMap);
        EDGE_OutletSurveyKPIRollupBatchHelper.calcTotalAcvSrvyKPI(salesTerritory.Id, kpiRecTotal, outletResp, kpiAchievementNullMap, numberOfOutlets, territoryMap);       
        EDGE_OutletSurveyKPIRollupBatchHelper.isNumeric('1');
        EDGE_OutletSurveyKPIRollupBatchHelper.isNumeric('A');
      
        //ES20-11893 ENDS
        Test.stopTest();
        
        printGovnLimits();
    }
    
    @isTest
    public static void testOutletSurveyKPIRollupBatch(){
        
        //createData();
        
        
        Survey__c survey1 = [Select Id from Survey__c where Name = 'test_survey_1' LIMIT 1];
        Survey__c survey2 = [Select Id from Survey__c where Name = 'test_survey_2' LIMIT 1];
        Test.startTest();
        List<Account> outlets = [Select Id from Account where Name in ('outlet_1', 'outlet_2')];
        Survey_Question__c surveyQues = [Select id from Survey_Question__c where Question__c = 'Whisky Pouring Survey QS1' LIMIT 1];
        
        Survey_Question__c bartendingSurveyQues = [Select id from Survey_Question__c where Question__c = 'BarTending Survey QS211' LIMIT 1];
        
        Outlet_Survey__c otSurvey1 = EDGE_UtilityTestClass.getOutletSurvey(survey1.Id, outlets[0].Id);
        otSurvey1.Survey_Valid_From__c = System.today() - 10;
        Outlet_Survey__c otSurvey2 = EDGE_UtilityTestClass.getOutletSurvey(survey1.Id, outlets[0].Id);
        otSurvey2.Survey_Valid_From__c = System.today() - 8;
        Outlet_Survey__c otSurvey3 = EDGE_UtilityTestClass.getOutletSurvey(survey1.Id, outlets[1].Id);
        otSurvey3.Survey_Valid_From__c = System.today() - 8;
        
        Outlet_Survey__c otSurvey21 = EDGE_UtilityTestClass.getOutletSurvey(survey2.Id, outlets[0].Id);
        otSurvey21.Survey_Valid_From__c = System.today() - 10;
        
        List<Outlet_Survey__c> otSurveys = new List<Outlet_Survey__c>();
        otSurveys.add(otSurvey1);
        otSurveys.add(otSurvey2);
        otSurveys.add(otSurvey3);
        otSurveys.add(otSurvey21);
        Database.insert(otSurveys);
        System.debug(LoggingLevel.Debug,' 307 : Limits.getQueries() = ' + Limits.getQueries());
        List<Survey_Answer__c> srvyAnswers = new List<Survey_Answer__c>();
        
        Survey_Answer__c srvyAnswer1 = new Survey_Answer__c();
        srvyAnswer1.Bonus_Applicable_Response__c = true;
        srvyAnswer1.Option_Value__c = 'Whisky Pouring Survey QS1A1';
        srvyAnswer1.Survey_Question__c = surveyQues.Id;
        srvyAnswers.add(srvyAnswer1);
        
        Survey_Answer__c srvyAnswer2 = new Survey_Answer__c();
        srvyAnswer2.Option_Value__c = 'Whisky Pouring Survey QS1A2';
        srvyAnswer2.Survey_Question__c = surveyQues.Id;
        srvyAnswers.add(srvyAnswer2);
        
        Survey_Answer__c srvyAnswer3 = new Survey_Answer__c();
        srvyAnswer3.Option_Value__c = 'Whisky Pouring Survey QS1A3';
        srvyAnswer3.Survey_Question__c = surveyQues.Id;        
        srvyAnswers.add(srvyAnswer3);
        
        Database.insert(srvyAnswers);
        System.debug(LoggingLevel.Debug,' 327 : Limits.getQueries() = ' + Limits.getQueries());
       // Test.startTest();
        List<Outlet_Survey__c> otSurveysUpdate = new List<Outlet_Survey__c>();
        
        otSurvey1.Achievement_status__c = 'Complete';
        otSurvey1.Completion_Date__c = system.today() - 5;
        otSurveysUpdate.add(otSurvey1);
       // update otSurvey1;
        
        otSurvey2.Achievement_status__c = 'Complete';
        otSurvey2.Completion_Date__c = system.today();
      //  update otSurvey2;       
        otSurveysUpdate.add(otSurvey2);

        otSurvey3.Achievement_status__c = 'Complete';
        otSurvey3.Completion_Date__c = system.today() - 3;
        //update otSurvey3; 
        otSurveysUpdate.add(otSurvey3);
        
        otSurvey21.Achievement_status__c = 'Complete';
        otSurvey21.Completion_Date__c = system.today();
        //update otSurvey21;
        otSurveysUpdate.add(otSurvey21);
        
        Database.update(otSurveysUpdate);
        
        Outlet_Survey_Response__c otSurveyRes1 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey1.Id,surveyQues.Id);
        otSurveyRes1.Response__c = 'Whisky Pouring Survey QS1A2';
        
        //This response is recent for outlet 1
        Outlet_Survey_Response__c otSurveyRes2 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey2.Id,surveyQues.Id);
        otSurveyRes2.Response__c = 'Whisky Pouring Survey QS1A2';
        
        //This is the only response for outlet 2
        Outlet_Survey_Response__c otSurveyRes3 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey3.Id,surveyQues.Id);
        otSurveyRes3.Response__c = 'Whisky Pouring Survey QS1A2';
        
        //This response is a Activation KPI Type survey for outlet 1
        Outlet_Survey_Response__c otSurveyRes21 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey21.Id,bartendingSurveyQues.Id);
        otSurveyRes21.Response__c = '10';
        
        /*Outlet_Survey_Response__c otSurveyRes22 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey21.Id,surveyQues.Id);
otSurveyRes22.Response__c = '3';*/
        
        List<Outlet_Survey_Response__c> otletSrvyResponses = new List<Outlet_Survey_Response__c>();
        otletSrvyResponses.add(otSurveyRes1);
        otletSrvyResponses.add(otSurveyRes2);
        otletSrvyResponses.add(otSurveyRes3);
        otletSrvyResponses.add(otSurveyRes21);
        
        Database.insert(otletSrvyResponses);

        Test.stopTest();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OutletSurveyKPIRollupBatch'
                                                  and Country_Code__c ='AU' ];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        system.debug(LoggingLevel.Debug,'batchSetting = '+ batchSetting);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        Database.executeBatch((Database.Batchable<SObject>)job,200); 

    }
    
    private static void printGovnLimits(){
        if(isPrintFlagON){
            System.debug(LoggingLevel.Debug,govLimitDebugCount++ + '. ' +System.now() + ' : Limits.getQueries() = ' + Limits.getQueries());
        }        
    }
}