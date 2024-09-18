/*
* @description :  EDGE_DeliveryPartnerTriggerHelperTest

* @purpose : Trigger Helper Class for DeliveryPartnerTrigger

* @history : 
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0        Amar Deep         17/06/2019         ES20-2230
2.0        Sakshi Shah       24/08/2024         PMD Fix
*/

@isTest
public class EDGE_DeliveryPartnerTriggerHelperTest{

        /**
 * @description To check the sharing of object
 */
    @isTest
    public static void checkSharingTest(){ //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        Map <String,Schema.RecordTypeInfo> mapGeographyRecordTypes = Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id countryRecTypeId = mapGeographyRecordTypes.get('Country').getRecordTypeId();
       
        
        //Creating Delivery Partner Record
        Delivery_Partner__c deliveryPartner = EDGE_UtilityTestClass.getDeliveryPartner(countryId);
        insert deliveryPartner;
        system.assert(deliveryPartner.Id != null,'Delivery Partner Id should not be null.');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        Id clusterId = geoMap.get('Cluster');
        Geography__c country = createGeography('Country');
        country.Name = 'Australia1';
        country.Code__c = 'AUT1';
        country.Parent_Geography__c = clusterId;
        country.RecordTypeId=CountryRecTypeId;
        insert country;
        
        System.assert(country.id != null,'Country Id should not be null.');
        
        deliveryPartner.Country__c = geoMap.get('Country');
        deliveryPartner.Country__c = country.Id ;
        deliveryPartner.Vendor_Number__c  =  256;
        update deliveryPartner;        
        delete deliveryPartner ;
        undelete deliveryPartner ;
        System.assert(deliveryPartner != null,'Delivery Partner should not be null.');
        Test.stopTest();
    }
        /**
 * @description create geography method
 * @return Geography__c
 * @param recordtypeName
 */
    public static Geography__c createGeography(String recordtypeName){
        Geography__c geography = new Geography__c();
        geography.RecordTypeId =  Geography__c.sObjectType.getDescribe().getRecordTypeInfosByName().get(recordtypeName).getRecordTypeId();
        return geography;
    }
    
}