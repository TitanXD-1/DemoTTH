/**********************************************************************
Name: EDGE_TargetListHelperTest
=======================================================================
Purpose: Trigger Helper Class for TargetListTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-1615
***********************************************************************/
@isTest
public class EDGE_TargetListHelperTest {
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
         //Creating Business Role Record
        Target_List__c targetList = EDGE_UtilityTestClass.getTargetList(countryId);
        insert targetList;
        system.assert(targetList.Id != null);
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        targetList.Country__c = secCountry.Id;
        update targetList;        
        delete targetList;
        undelete targetList;
        Test.stopTest();
    }

}