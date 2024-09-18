/*
 * Class Name : EDGE_SalesOrganisationTriggerHelperTest
 * @description: This is Sales Organisation Trigger Helper Test
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  		19/05/2021        Initial Development
*/
@isTest
public class EDGE_SalesOrganisationTriggerHelperTest {
    
	/*
	* @description : checkGenerateSharingTest
	* @return : void
	* @param : 
	*/

    @isTest
    public static void checkGenerateSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c geoCountry = EDGE_UtilityTestClass.createGeography('Country');
        geoCountry.Name = 'Spain1';
        geoCountry.Code__c = 'SE1';
        geoCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert geoCountry;
        Test.startTest();
         //Creating sales organisation Record
        Sales_Organisation__c salesorg = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Code__c = 'SEU';
        insert salesorg;
        system.assert(salesorg.Id != null);
        
        
        salesorg.Country__c = geoCountry.Id;
        delete salesorg;
        undelete salesorg;
        Test.stopTest();
    }

 @isTest
    public static void checkGenerateSalesOrgSharingTest(){
         //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();       
        Map<Id,SObject> salesOrgLst = new Map<Id,SObject>();
        List<Sales_Organisation__c> salesOrgNewlst = new List<Sales_Organisation__c>();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c geoCountry = EDGE_UtilityTestClass.createGeography('Country');
        geoCountry.Name = 'Spain1';
        geoCountry.Code__c = 'SE1';
        geoCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert geoCountry;
        
         //Creating sales organisation Record
        Test.startTest();
        Sales_Organisation__c salesorg = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        salesorg.Code__c = 'SEU';
        insert salesorg;
        system.assert(salesorg.Id != null);        
        salesOrgNewlst.add(salesorg);
        
        Sales_Organisation__c salesorg1 = EDGE_UtilityTestClass.getsalesorgRecord(geoCountry.Id);
        salesorg1.Code__c ='SE1';
        insert salesorg1;
        
        salesOrgLst.put(salesorg1.id,(SObject)salesorg1);
        
        EDGE_SalesOrganisationTriggerHelper.checkAndGenerateSharing(salesOrgNewlst);  
        EDGE_SalesOrganisationTriggerHelper.validateAndReGenerateSharing(salesOrgNewlst,salesOrgLst);
        EDGE_SalesOrganisationTriggerHelper.createSalesOrgPublicGroup(salesOrgLst);
        EDGE_SalesOrganisationTriggerHelper.deleteSalesOrgPublicGroup(salesOrgLst);
        
        //undelete salesorg;
        Test.stopTest();
    }
  
}