@isTest
public class LookupSearchComponentController_Test {
    public static testMethod void lookupSearchCtrlTest(){
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        Territory__c territory = EDGE_UtilityTestClass.getTerritoryRec();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES'); 
        territory.Country__c = geographyId;
        insert territory;
        outletAccount.Primary_Sales_Territory__c = territory.Id;
        insert outletAccount;
        
        String BannerRecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Tax Code').getRecordTypeId();
        Pick_Up_Options__c budgetTypeTI= new Pick_Up_Options__c();
        budgetTypeTI.Name='Reduced Rate - Canarias-A&P [ES]';
        budgetTypeTI.Geography__c=geographyId;
        budgetTypeTI.RecordTypeId=BannerRecordTypeId;
        insert budgetTypeTI;
        
        Pick_Up_Options__c budgetTypePortfolioRebates= new Pick_Up_Options__c();
        budgetTypePortfolioRebates.Name='Reduced Rate - Canarias-TI [ES]';
        budgetTypePortfolioRebates.Geography__c=geographyId;
        budgetTypePortfolioRebates.Status__c = 'Active';
        budgetTypePortfolioRebates.RecordTypeId=BannerRecordTypeId;
        insert budgetTypePortfolioRebates; 
        
        Test.startTest();
        LookupSearchComponentController.getResults('Account','Name','Test_Outlet');
        LookupSearchComponentController.getResults('User','Name','Test AS ROI');
        LookupSearchComponentController.getAccountsResult('Test_Outlet',territory.Id);
        LookupSearchComponentController.getResults('Pick_Up_Options__c','Name','Gold[IE]');
        ECM_TaxCodeSearchComponentController.getResults('Pick_Up_Options__c','Name','Reduced','Tax Code');

        ECM_TaxCodeDropdownComponentController.getPickUpOptionType('Pick_Up_Options__c','Tax Code');

        Test.stopTest();
        
    }

}