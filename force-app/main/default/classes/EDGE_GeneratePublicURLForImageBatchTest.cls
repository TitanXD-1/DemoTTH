/**

* @description :  EDGE_GeneratePublicURLForImageBatchTest

* @history :

* Version   Developer      Date       User Story	  Purpose
* 1.1       Aparajita    17/08/2021   ES20-10903      Test EDGE_GeneratePublicURLForImageBatch
* 1.2       Prasanth     23/09/2022   ES20-13324      Test Class Correction due to Failure
* 1.3       Sakshi       15/05/2024                   PMD Fix 152943
*/

@isTest
public class EDGE_GeneratePublicURLForImageBatchTest 
{ 
    @isTest
    public static void testGeneratePublicURLForImageBatch()
    {   
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
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
        insert salesTerritory;
        
        Test.startTest();

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
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        survey.Name = 'test_survey_1';
        insert survey;
        
        Outlet_Survey__c outletSurvey = EDGE_UtilityTestClass.getOutletSurvey(survey.Id,outlet.Id);
        insert outletSurvey;
            
        Survey_Question__c surveyQues = EDGE_UtilityTestClass.getSurveyQuestion(survey.Id);
        insert surveyQues;
        
        ContentVersion cv = EDGE_UtilityTestClass.gerConVerRec('Test.jpeg');
        cv.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Outlet-Survey Response').getRecordTypeId();
        cv.Content_Type__c = 'Outlet-Survey Response';
        cv.Title = 'Test.jpeg';
        insert cv;
        Id conDocId = [Select ContentDocumentId from ContentVersion where Id =:cv.Id].ContentDocumentId;
        
        Outlet_Survey_Response__c otSurveyRes = EDGE_UtilityTestClass.getOutletSurveyRes(outletSurvey.Id,surveyQues.Id);
        otSurveyRes.Content_Version_ID__c = cv.Id;
        otSurveyRes.Content_Document_ID__c = conDocId;
		insert otSurveyRes;
      
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_GeneratePublicURLForImageBatch' AND Country_Code__c ='AU'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Market Batch Setting should not be null.');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
    	Test.stopTest();
    }
}