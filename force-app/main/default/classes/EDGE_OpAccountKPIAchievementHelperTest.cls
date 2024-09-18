/**********************************************************************
Name: EDGE_OpAccountKPIAchievementHelperTest
=======================================================================
Req: Test class of EDGE_OperatorAccountKPIAchievementHelper
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR				DATE			DETAIL
1.0			Juned Khan		 01/10/2020		Initial Development				
***********************************************************************/
@istest
public class EDGE_OpAccountKPIAchievementHelperTest {
    @istest
    public static void testOperatorAccKPIAchievement(){

        Account operator;
        Account operator1;
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        system.assert(countryId!=null,'country Id should not be null');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        String defaultPickUpOption = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Survey KPI');
        pickUpOption.Name = 'Survey[AU]';
        pickUpOption.Type__c = 'Survey KPI';
        pickUpOption.RecordTypeId = defaultPickUpOption;
        insert pickUpOption;
        
        Pick_Up_Options__c accPickUpOption = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Activation Type');
        accPickUpOption.Name = 'ActivationType[AU]';
        accPickUpOption.Type__c = 'Activation Type';
        accPickUpOption.RecordTypeId = defaultPickUpOption;
        insert accPickUpOption;	
        
        Pick_Up_Options__c pickUpOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption1.Name = 'Gold[AU]';
        insert pickUpOption1;
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;
        
        Test.startTest();         
       /* User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        System.assert(salesManager.Id!=null);*/
        List<Account> operatorList = new List<Account>();
        	operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator.Person_Responsible__c = UserInfo.getUserId();
            operator.IsOperator__c = true;
            insert operator;
        operatorList.add(operator);
        operator1 = EDGE_UtilityTestClass.getOwnerOperatorAccount();
            operator1.Person_Responsible__c = UserInfo.getUserId();
            operator1.IsOperator__c = true;
            insert operator1;
         operatorList.add(operator1);
        
        Account_KPI_Achievement__c accKPIAch = new Account_KPI_Achievement__c();
        accKPIAch.KPI_Type__c = 'Activation Survey KPI';
        accKPIAch.Target__c = 60;
        accKPIAch.Actual_Numerator__c = 400;
        accKPIAch.Total_Denominator__c = 20;
        accKPIAch.Account__c = operator.Id;
        accKPIAch.Activation_Survey_KPI__c = accPickUpOption.Id;
        insert accKPIAch;
        
        Account_KPI_Achievement__c surKPIAch = new Account_KPI_Achievement__c();
        surKPIAch.KPI_Type__c = 'Survey KPI';
        surKPIAch.Target__c = 60;
        surKPIAch.Actual_Numerator__c = 400;
        surKPIAch.Total_Denominator__c = 20;
        surKPIAch.Account__c = operator.id;
        surKPIAch.Activation_Survey_KPI__c = pickUpOption.Id;
        insert surKPIAch;
        Account_KPI_Achievement__c totalKPIAch = new Account_KPI_Achievement__c();
        totalKPIAch.KPI_Type__c = 'Total Activation';
        totalKPIAch.Target__c = 60;
        totalKPIAch.Actual_Numerator__c = 400;
        totalKPIAch.Total_Denominator__c = 20;
        totalKPIAch.Account__c = operator.id;
        totalKPIAch.Activation_Survey_KPI__c = pickUpOption.Id;
        insert totalKPIAch;
       EDGE_OperatorAccountKPIAchievementHelper.createAccountKPIAchievementWrapList(operatorList);
        
    }

}