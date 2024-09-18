/**********************************************************************
Name: EDGE_BusinessRoleTriggerHelperTest
=======================================================================
Purpose: Trigger Helper Class for BusinessRoleTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-1615
2.0       Swaraj Samanta       05/09/2022        ES20-13284
***********************************************************************/
@isTest
public class EDGE_BusinessRoleTriggerHelperTest {
    
    /*******************************************************************
    Method  : checkAndGenerateSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkAndGenerateSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
         //Creating Business Role Record
        Business_Role__c busrole = EDGE_UtilityTestClass.getBusinessRole();
        busrole.My_accounts_Fields_Display__c='Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        busrole.Country__c = countryId;
        insert busrole;
        system.assert(busrole.Id != null,'Bus Role should not be null');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        busrole.Country__c = secCountry.Id;
        update busrole;        
        delete busrole;
        undelete busrole;
        Test.stopTest();
    }
}