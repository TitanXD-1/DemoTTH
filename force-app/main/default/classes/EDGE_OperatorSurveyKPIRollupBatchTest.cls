/**
* @Description: EDGE_OperatorSurveyKPIRollupBatchTest

* @Purpose: Test Class for EDGE_OperatorSurveyKPIRollupBatch

* @Version    Developer       Date         Story
*   1.0		 Shahbaz Khan   28/09/2020	  ES20-8503
*   2.0      Joshraj Sen    08/04/2024    152305
*/

@isTest
public class EDGE_OperatorSurveyKPIRollupBatchTest {
 private static String dfltPickupRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
    @testSetup
    public static void createDate(){
        
         List<User> users = new List<User>();
        //Creating Sales Manager
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'GB';
        insert salesManager;
        System.assert(salesManager.Id!=null,'User is Added');
        
        //Creating Sales Rep 1
        User salesRep1 = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Representative');
        salesRep1.FirstName = 'SalesRep001';
        salesRep1.Available_Countries__c = 'GB';
        salesRep1.ManagerId = salesManager.Id;
        users.add(salesRep1);
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'GB';
        testAdminUser.FirstName = 'SalesAdmin001';
        //insert testAdminUser;
        users.add(testAdminUser);
        
        Database.insert(users);
        
        EDGE_UtilityTestClass.createOrgSettings();
        System.runAs(testAdminUser){
        // added setupCountryAU by Anamika
        Id countryId;
        Map<String,Id> geoMap=new Map<String,Id>();
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
        hub.Name = 'Great Britain';
        hub.Code__c = 'GBH';
        hub.Parent_Geography__c = market.Id;
        hub.RecordTypeId=EDGE_UtilityTestClass.HubRecTypeId;
        insert hub;
        geoMap.put('Hub',hub.Id);
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Great Britain';
        cluster.Code__c = 'GBC';
        cluster.Parent_Geography__c = hub.Id;
        cluster.RecordTypeId=EDGE_UtilityTestClass.ClusterRecTypeId;
        insert cluster;
        geoMap.put('Cluster',cluster.Id);
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'Great Britain';
        country.Code__c ='GB';
        country.Parent_Geography__c = cluster.Id;
        country.RecordTypeId=EDGE_UtilityTestClass.CountryRecTypeId;
        insert country;
        geoMap.put('Country',country.Id);
        Geography__c area = EDGE_UtilityTestClass.createGeography('Area');
        area.Name = 'Great Britain';
        area.Code__c = 'GBA';
        area.Parent_Geography__c = country.Id;
        area.RecordTypeId=EDGE_UtilityTestClass.AreaRecTypeId;
        insert area;
        geoMap.put('Area',area.Id);        
        Geography__c region = EDGE_UtilityTestClass.createGeography('Region');
        region.Name = 'Central';
        region.Code__c = 'GB05';
        region.Parent_Geography__c = area.Id;
        region.RecordTypeId=EDGE_UtilityTestClass.RegionRecTypeId;
        insert region;
        geoMap.put('Region',region.Id);
        countryId=country.Id;
      
        List<Pick_Up_Options__c> pickupOptions = new List<Pick_Up_Options__c>();
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pOption.Name = 'Gold[GB]';
        pickupOptions.add(pOption);
        
        Pick_Up_Options__c whiskPrOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        whiskPrOption.RecordTypeId = dfltPickupRecTypeId;
        whiskPrOption.Name = 'Whisky Pouring[GB]';
        whiskPrOption.Applicable_Business_Role__c = 'Sales Rep';
        pickupOptions.add(whiskPrOption);
        //insert whiskPrOption;
        
        Pick_Up_Options__c beerPrOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        beerPrOption.RecordTypeId = dfltPickupRecTypeId;
        beerPrOption.Name = 'Beer Pouring[GB]';
        beerPrOption.Applicable_Business_Role__c = 'Sales Rep';
        pickupOptions.add(beerPrOption);
        
        Pick_Up_Options__c barTenderPckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        barTenderPckOption.RecordTypeId = dfltPickupRecTypeId;
        barTenderPckOption.Name = 'Bartender training[GB]';
        pickupOptions.add(barTenderPckOption);
        
        Pick_Up_Options__c pouringPckOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        pouringPckOption.RecordTypeId = dfltPickupRecTypeId;
        pouringPckOption.Name = 'Pouring[GB]';
        pickupOptions.add(pouringPckOption);
        
        insert pickupOptions;
       
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        marc.Start_Date__c= System.today() - 25;
        marc.End_Date__c = marc.Start_Date__c.addDays(50);
        insert marc;
        
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Person_Responsible__c = salesRep1.Id;
        operator.IsOperator__c = true;
        operator.Country__c = countryId;
        operator.Hub__c = hub.Id;
        operator.Region__c=region.Id;
        operator.Area__c=area.Id;
        operator.Market__c = market.Id;
        operator.Cluster__c= cluster.Id;
        insert operator;
        Test.startTest();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet.Operator__c = operator.Id;
        outlet.Independent_of_Operator__c = False;
        outlet.Country__c = countryId;
        outlet.Hub__c = hub.Id;
        outlet.Region__c=region.Id;
        outlet.Area__c=area.Id;
        outlet.Market__c = market.Id;
        outlet.Cluster__c= cluster.Id;
        insert outlet;
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        survey.Name = 'test_survey_1';
        survey.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        insert survey;
        
        Survey_Question__c surveyQues = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQues.Question__c = 'Whisky Pouring Survey QS1';
        surveyQues.Response_Type__c = 'RadioButton';
        surveyQues.Active__c = true;
        surveyQues.Survey_KPI__c = whiskPrOption.Id;
        insert surveyQues;
        
        Survey_Question__c surveyQues21 = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQues21.Question__c = 'BarTending Survey QS211';
        surveyQues21.Response_Type__c = 'Number';
        surveyQues21.Active__c = true;
        surveyQues21.Activation_Type__c = barTenderPckOption.Id;
        insert surveyQues21;
        
        Outlet_Survey__c otSurvey1 = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outlet.Id);
        otSurvey1.Survey_Valid_From__c = system.today() - 10;
        insert otSurvey1;
        
        Survey_Answer__c srvyAnswer1 = new Survey_Answer__c();
        srvyAnswer1.Bonus_Applicable_Response__c = true;
        srvyAnswer1.Option_Value__c = 'Whisky Pouring Survey QS1A1';
        srvyAnswer1.Survey_Question__c = surveyQues.Id;
        insert srvyAnswer1;
        
        otSurvey1.Achievement_status__c = 'Complete';
        otSurvey1.Completion_Date__c = system.today();
        update otSurvey1;
       
        
        Outlet_Survey_Response__c otSurveyRes21 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey1.Id,surveyQues21.Id);
        otSurveyRes21.Response__c = '10';
        insert otSurveyRes21;
        //This response is recent for outlet 1
        Outlet_Survey_Response__c otSurveyRes2 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurvey1.Id,surveyQues.Id);
        otSurveyRes2.Response__c = 'Whisky Pouring Survey QS1A2';
        insert otSurveyRes2;
        
        //ES20-11893 STARTS
        Map<String, Account_KPI_Achievement__c> accountKpiAchievementMap1 = new Map<String, Account_KPI_Achievement__c>();
        Map<String, Account_KPI_Achievement__c> accountKpiAchievementMap2 = new Map<String, Account_KPI_Achievement__c>();
        Map<String, Account_KPI_Achievement__c> accountKpiAchievementMap = new Map<String, Account_KPI_Achievement__c>();
        Map<Id, Account> operatorMap = new Map<Id, Account>();
        Map<Id, List<Account>> operatorOutletsMap = new Map<Id, List<Account>>();
        Map<Id, List<Outlet_Survey_Response__c>> outletSurveyResponseMap = new Map<Id, List<Outlet_Survey_Response__c>>();
        Map<Id, List<Outlet_Survey_Response__c>> outletActKPIResponseMap = new Map<Id, List<Outlet_Survey_Response__c>>();
        List<Account> outletList = new List<Account>();
        List<Outlet_Survey_Response__c> outletSurRespList = new List<Outlet_Survey_Response__c>();
        Decimal outletResp = 0;
        Integer numberOfOutlets = 1;
        
        outletList.add(outlet);
        operatorOutletsMap.put(operator.Id,outletList);
        
        outletSurRespList.add(otSurveyRes21);
        outletSurRespList.add(otSurveyRes2);
		outletSurveyResponseMap.put(outlet.Id, outletSurRespList);
        
        outletActKPIResponseMap.put(outlet.Id, outletSurRespList);
        
        Account_KPI_Achievement__c accKPIAchvRec1 = EDGE_OperatorSurveyKPIRollupHelper.createAccKpiAch(operator.Id, whiskPrOption.Id, numberOfOutlets, operator, null, 'Survey KPI');
        accKPIAchvRec1.Actual_Numerator__c = 1;
        Account_KPI_Achievement__c accKPIAchvRec2 = EDGE_OperatorSurveyKPIRollupHelper.createAccKpiAch(operator.Id, null, numberOfOutlets, operator, barTenderPckOption.Id, 'Activation Survey KPI');
        accKPIAchvRec2.Actual_Numerator__c = 1;

        accountKpiAchievementMap1.put(String.valueOf(operator.Id),accKPIAchvRec1);
        accountKpiAchievementMap2.put(String.valueOf(operator.Id),accKPIAchvRec2);
        operatorMap.put(operator.Id,operator);

        EDGE_OperatorSurveyKPIRollupHelper.calcTotalAcvSrvyKPI(operator.Id,accKPIAchvRec1,outletResp,accountKpiAchievementMap1,numberOfOutlets,operatorMap);
        EDGE_OperatorSurveyKPIRollupHelper.calcTotalAcvSrvyKPI(operator.Id,accKPIAchvRec2,outletResp,accountKpiAchievementMap2,numberOfOutlets,operatorMap);

        accountKpiAchievementMap = EDGE_OperatorSurveyKPIRollupHelper.calculateSurveyKPI(operatorOutletsMap, outletSurveyResponseMap, null, operatorMap, outletActKPIResponseMap, null);
		
        //ES20-11893 ENDS
        Test.stopTest();
       // System.runAs(testAdminUser){
        testOperatorKPIAch();
       // }
        } 
    }
    @isTest
    public static void testOperatorKPIAch(){
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OperatorSurveyKPIRollupBatch'
                                                  and Country_Code__c ='GB' ];
        system.assert(batchSetting.Id != null,'Batch is Added');
        system.debug(LoggingLevel.Debug,'batchSetting = '+ batchSetting);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    }


}