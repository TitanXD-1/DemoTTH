/**********************************************************************
Name: EDGE_ExternalLinksTriggerHelperTest
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE			DETAIL
1.0         Amar Deep       04/03/2020      Initial Development
2.0         Sakshi Shah     15/05/2024      PMD Fix 152943
***********************************************************************/
@isTest
public class EDGE_ExternalLinksTriggerHelperTest {
    @isTest
    public static void externalLinksTriggerTest(){
        Id countryid= EDGE_UtilityTestClass.setupCountry('AU');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id clusterId = geoMap.get('Cluster');
        Geography__c country = createGeography('Country');
        country.Name = 'Australia1';
        country.Code__c = 'AUT1';
        country.Parent_Geography__c = clusterId;
        insert country;
        
        EDGE_UtilityTestClass.createOrgSettings();
        External_Links__c extLink = new External_Links__c();
        extLink.Country__c = countryid;
        extLink.Order__c = 2.0;
        insert extLink;
        system.assert(extLink.Id != null,'External Link Id should not be null.');
        
        extLink.Order__c = 5.0;
        extLink.Country__c = country.Id;
        update extLink;
        delete extLink;
        undelete extLink;
        
    }
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }

}