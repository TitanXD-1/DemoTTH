/**********************************************************************
Name: EDGE_SurveyTriggerHelperTest
* @description  Test Class for EDGE_SurveyTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR               DATE            DETAIL
1.0         Monalisa Halder     04/04/2019     Test Class for EDGE_SurveyTriggerHelper
2.0         Swaraj Samanta      05/09/2022     Test Class Correction due to Failure(ES20-13284)
3.0         Sakshi Shah         26/07/2024     PMD Fix
***********************************************************************/
@isTest
public class EDGE_SurveyTriggerHelperTest{
    /** 
* @description  Create Survey
**/
    @isTest
    public static void testsurveyFreqChange(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'Pickup Option Id should not be null.');
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        insert outlet;
        system.assert(outlet.Id != null,'Outlet Id should not be null.');
        Test.startTest();
        List<Survey__c> surveys=new List<Survey__c>();
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(geographyId);
        surveys.add(survey);
         Survey__c survey1 = EDGE_UtilityTestClass.getSurvey(geographyId);
        survey1.Reccuring_Type__c = 'Non Recurring';
        survey1.Frequency__c = null;
        surveys.add(survey1);
        insert surveys;
        system.assert(survey.Id != null,'Survey Id should not be null.');
        survey1.Frequency__c = 3;
        update survey1;
        delete survey1;
        List<Outlet_Survey__c> outletSurveys=new List<Outlet_Survey__c>();
        Outlet_Survey__c otSurvey = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outlet.Id);
        otSurvey.Achievement_status__c = 'Complete';
        otSurvey.Completion_Date__c = System.today();
        outletSurveys.add(otSurvey);
        Outlet_Survey__c otSurvey1 = EDGE_UtilityTestClass.getOutletSurvey(survey.Id, outlet.Id);
        otSurvey1.Achievement_status__c = 'In Progress';
        otSurvey1.Survey_Valid_From__c = System.today().addDays(5);
        outletSurveys.add(otSurvey1);
        insert outletSurveys;  
        survey.Frequency__c = 10;
        update survey;
        update otSurvey1;                
        system.assertEquals(otSurvey1.Survey__c, survey.Id,'The survey Id does not match');
        Test.stopTest();
    }
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
      /** 
* @description  To check the sharing of object
**/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Survey__c survey = EDGE_UtilityTestClass.getSurvey(countryId);
        insert survey;
        system.assert(survey.Id != null,'Survey Id should not be null.');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        survey.Country__c = secCountry.Id;
        update survey;        
        delete survey;
        undelete survey;
        Test.stopTest();
    }
}