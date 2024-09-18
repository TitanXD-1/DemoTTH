/**********************************************************************
Name: EDGE_CategoryPerfrmTriggerHelper
=======================================================================
Purpose: Trigger Helper Class for EDGE_CategoryPerfrmTriggerHelperTest
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-1615
***********************************************************************/
@isTest
public class EDGE_CategoryPerfrmTriggerHelperTest {
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
         //Creating Business Role Record
        Category_Performance__c categoryPerformance = EDGE_UtilityTestClass.getCategoryPerformance(countryId);
        insert categoryPerformance;
        system.assert(categoryPerformance.Id != null,'categoryPerformance should not be null');
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        Test.startTest();        
        categoryPerformance.Country__c = secCountry.Id;
        update categoryPerformance;        
        delete categoryPerformance;
        undelete categoryPerformance;
        Test.stopTest();
    }

}