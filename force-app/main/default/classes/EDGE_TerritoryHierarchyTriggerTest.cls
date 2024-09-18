/**********************************************************************
Name: EDGE_TerritoryHierarchyTriggerTest
=======================================================================
Purpose: Trigger Helper Class for TerritoryHierarchyTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-1615
***********************************************************************/
@isTest
public class EDGE_TerritoryHierarchyTriggerTest {
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
        
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
         //Creating Business Role Record
        Territory_Hierarchy__c objTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert objTerHierarchy;
        system.assert(objTerHierarchy.Id != null);       
       
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        objTerHierarchy.Geography__c = secCountry.Id;
        update objTerHierarchy;        
        delete objTerHierarchy;
        undelete objTerHierarchy;
        Test.stopTest();
    }

}