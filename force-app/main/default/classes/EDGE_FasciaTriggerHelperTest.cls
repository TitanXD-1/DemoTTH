/**********************************************************************
Name: EDGE_FasciaTriggerHelperTest
=======================================================================
Purpose: Trigger Helper Class for FasciaTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-1615
2.0       Swaraj Samanta       05/09/2022        ES20-13284
3.0       Sakshi Shah          15/05/2024        PMD Fix 152943
***********************************************************************/
@isTest
public class EDGE_FasciaTriggerHelperTest {
    
    /*******************************************************************
    Method  : checkSharingTest
    Purpose : To check the sharing of object
    ********************************************************************/
    @isTest
    public static void checkSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
         //Creating Business Role Record
        Fascia__c fascia = EDGE_UtilityTestClass.getFascia(countryId);
        insert fascia;
        system.assert(fascia.Id != null,'Fascia Id should not be null.');
        Test.startTest();
        /*
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AUS';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        */
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        fascia.Country__c =  secCountry.Id;
        update fascia;        
        delete fascia;
        undelete fascia;
        Test.stopTest();
    }

}