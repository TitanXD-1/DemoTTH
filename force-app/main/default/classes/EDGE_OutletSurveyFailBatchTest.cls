/*
*@Name: EDGE_OutletSurveyFailBatchTest 
*@Description: This class is test class of EDGE_OutletSurveyFailureRecoveryBatch.
*@History                                                            
*
*VERSION		AUTHOR					DATE				DETAIL
*1.0			Shivam Chauhan			22/04/2024			Initial Development - 152835 Outlet Survey Batch_SFDC_Techdebt
*/
@isTest
public class EDGE_OutletSurveyFailBatchTest {
    private static Boolean isPrintFlagON = true;
    private static Integer govLimitDebugCount = 1;
    
    @testSetup
    public static void createData(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c market = EDGE_UtilityTestClass.getMarketSetting(countryId);
        market.Threshold_Format__c = 'Percent'; //was commented before
        market.A_P_Threshold__c = 100.00; //100
        market.Display_Transfer_Order_Comments__c = True;
        market.Outlet_survey_batch_close__c = 2;
        insert market; 
        printGovnLimits();
        
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
        printGovnLimits();
        
        Test.startTest();
        //Creating Territory record(s)
        Territory__c salesTerritory = new Territory__c();
        salesTerritory.Territory_Type__c = 'Sales';
        salesTerritory.Status__c = 'Active';
        salesTerritory.Country__c = countryID;
        salesTerritory.Region__c = terriHierRegion.Id;
        salesTerritory.Pending_For_Batch__c = true;
        insert salesTerritory;
        
        printGovnLimits();
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pOption.Name = 'Gold[AU]';
        insert pOption;
        
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        marc.Start_Date__c= System.today() - 25;
        marc.End_Date__c = marc.Start_Date__c.addDays(25);
        insert marc;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'outlet_1';
        outlet.Outlet_Visit_Prioritisation_Grade__c = pOption.Id;
        outlet.Primary_Sales_Territory__c = salesTerritory.Id;
        insert outlet;
        printGovnLimits();
        
        Outlet_Territory__c soutletTer1 = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, salesTerritory.Id);
        soutletTer1.Active__c='Active';
        insert soutletTer1;
        
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        survey.Name = 'test_survey_1';
        survey.Global_Equivalent_Business_Roles__c = 'Sales Rep';
        insert survey;
        printGovnLimits();
        Survey_Question__c surveyQues = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        surveyQues.Question__c = 'Whisky Pouring Survey QS1';
        surveyQues.Response_Type__c = 'RadioButton';
        surveyQues.Active__c = true;
        insert surveyQues;
        printGovnLimits();
        test.stoptest();
    }
    
    
    @isTest
    public static void testOutletSurveyRecordCompletion(){
        printGovnLimits();
        Test.starttest();
        Account outlet = [Select Id from Account where Name = 'outlet_1' LIMIT 1];
        Survey__c survey= [Select id from Survey__c where Name = 'test_survey_1'];
        Survey_Question__c surveyQues = [Select id from Survey_Question__c where Question__c = 'Whisky Pouring Survey QS1' Limit 1];
        
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Call_Completed_in_Mobile__c = true;
        callObj.End_Date__c = System.today().addDays(-3);
        
        callObj.Last_Visit_from_Mobile__c  = true;
        
        callObj.Status__c = 'Completed';
        insert callObj;
        
        Outlet_Survey__c otSurveyTest = EDGE_UtilityTestClass.getOutletSurvey(surveyQues.Id, outlet.Id);
        otSurveyTest.Survey_Valid_From__c = system.today() - 10;
        otSurveyTest.Call__c=callObj.id;
        otSurveyTest.Survey__c = survey.id;
        insert otSurveyTest;
        
        printGovnLimits();
        Test.stoptest();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OutletSurveyFailureRecoveryBatch'
                                                  and Country_Code__c ='AU' ];
        system.assert(batchSetting.Id != null,'batchSetting should not be null');
        system.debug(LoggingLevel.Debug,'batchSetting = '+ batchSetting);
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Database.executeBatch((Database.Batchable<SObject>)job,200); 
        
    }
    
    @isTest
    public static void testOutletSurveyRecordCompletionNext(){
        printGovnLimits();
        Test.starttest();
        Account outlet = [Select Id from Account where Name = 'outlet_1' LIMIT 1];
        Survey__c survey= [Select id from Survey__c where Name = 'test_survey_1'];
        Survey_Question__c surveyQues = [Select id from Survey_Question__c where Question__c = 'Whisky Pouring Survey QS1' Limit 1];
        
        Call__c callObj = EDGE_UtilityTestClass.getCallRec(outlet.Id);
        callObj.Call_Completed_in_Mobile__c = true;
        callObj.End_Date__c = System.today().addDays(-3);
        
        callObj.Last_Visit_from_Mobile__c  = true;
        
        callObj.Status__c = 'Completed';
        insert callObj;
        
        Outlet_Survey__c otSurveyTest = EDGE_UtilityTestClass.getOutletSurvey(surveyQues.Id, outlet.Id);
        otSurveyTest.Survey_Valid_From__c = system.today() - 10;
        otSurveyTest.Call__c=callObj.id;
        otSurveyTest.Survey__c = survey.id;
        insert otSurveyTest;
        
        
        Outlet_Survey_Response__c otSurveyRes1 = EDGE_UtilityTestClass.getOutletSurveyRes(otSurveyTest.Id,surveyQues.Id);
        insert otSurveyRes1;
        
        printGovnLimits();
        Test.stoptest();
        
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_OutletSurveyFailureRecoveryBatch'
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