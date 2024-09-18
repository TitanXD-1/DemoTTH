/**********************************************************************
Name: EDGE_AccountKPIAchievementHelperTest
=======================================================================
Req: 
ES20-8587 : Unique ID in Object creation Activation_KPI_Achievement_US1c_SFDC_Operator View

======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Juned Khan		15/09/2020		  Test class for EDGE_AccountKPIAchievementHelperTest
***********************************************************************/
@isTest
public class EDGE_AccountKPIAchievementHelperTest {
    
     @isTest
    public static void accountKPIAchievementTest(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        system.assert(countryId!=null,'country Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        String defaultPickUpOption = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpOption.Name = 'Survey[AU]';
        pickUpOption.Type__c = 'Survey KPI';
        pickUpOption.RecordTypeId = defaultPickUpOption;
        insert pickUpOption;
        
        Pick_Up_Options__c pickUpOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption1.Name = 'Gold[AU]';
        insert pickUpOption1;
        
        Test.startTest();         
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Independent_of_Operator__c = True;
        outlet.Independent_of_Owner__c = True;
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickUpOption1.Id;
        insert outlet;
        
        Account_KPI_Achievement__c accKPIAch = new Account_KPI_Achievement__c();
        accKPIAch.KPI_Type__c = 'Activation Survey KPI';
        accKPIAch.Target__c = 60;
        accKPIAch.Actual_Numerator__c = 400;
        accKPIAch.Total_Denominator__c = 20;
        accKPIAch.Account__c = outlet.id;
        accKPIAch.Activation_Survey_KPI__c = pickUpOption.Id;
        insert accKPIAch;
        
        accKPIAch.Target__c = 95;
        
        update accKPIAch;
        delete accKPIAch;
        undelete accKPIAch;
        
        
        Test.stopTest();
        
        
        
    }

}