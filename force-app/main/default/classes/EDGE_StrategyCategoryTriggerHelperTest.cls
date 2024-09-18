/**********************************************************************
Name: EDGE_StrategyCategoryTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Manikant Prasad   02/07/2019      Test Class for EDGE_StrategyCategoryTriggerHelper
2.0         Swaraj Samanta    05/09/2022      Test Class Correction due to Failure(ES20-13284)
***********************************************************************/
@isTest
public class EDGE_StrategyCategoryTriggerHelperTest {
    @isTest 
    public static void updateAccountrecordTest(){
       
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        List<Account> operatorOwnerAccounts =new List<Account>();
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Outlet_Visit_Prioritisation_Grade__c =  oultlVstPriPkUp.Id;
        operator.Status__c='Active';
        operator.IsOperator__c=true;
        operatorOwnerAccounts.add(operator);
      
        
        Account owner = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        owner.Outlet_Visit_Prioritisation_Grade__c =  oultlVstPriPkUp.Id; 
        owner.Status__c='Active';
        owner.IsOwner__c=true;
        operatorOwnerAccounts.add(owner);
        insert operatorOwnerAccounts;
        Test.startTest();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        outlet.Independent_of_Operator__c = False;
        outlet.Independent_of_Owner__c = False;
        outlet.Operator__c = operator.Id;
        outlet.ParentId = owner.Id;
        insert outlet;
        
        System.assert(outlet.id!= null);
        List <Strategy_Categories__c> stratCategories=new List<Strategy_Categories__c>();
        Strategy_Categories__c stratCateg = new Strategy_Categories__c();
        stratCateg.Execution_Date__c = system.today();
        stratCateg.Outlet__c = outlet.id;
        stratCateg.Category__c = 'Deluxe';
        stratCateg.FRP_Points__c = 152;
        stratCategories.add(stratCateg);
        Strategy_Categories__c stratCateg1 = new Strategy_Categories__c();
        stratCateg1.Execution_Date__c = system.today();
        stratCateg1.Outlet__c = outlet.id;
        stratCateg1.Category__c = 'RTD';
        stratCateg1.FRP_Points__c = 142;
        stratCategories.add(stratCateg1);
        insert stratCategories;
        stratCateg.Actual_Cases__c = 458;
        stratCateg1.Actual_Cases__c = 558;
        update stratCategories;
        delete stratCategories;
        undelete stratCategories;        
        Test.stopTest();
       
    }
}