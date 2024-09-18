/*
* @name: D1_GeographySharingTest
* @discription: D1_GeographySharing Test Class
* @history
* VERSION     AUTHOR         DATE               DETAIL
* 1.0           -        		-                    -
* 2.0		  Rubeena		 25/06/2021		  Test Class Refractor [NCP-3781]
* */

@isTest
public class D1_GeographySharingTest {
	@isTest
    public static void testGeoSharing(){
        D1_TestDataUtility.createOrgSettings();
        Test.startTest();
        Id geographyId = D1_TestDataUtility.setupCountry('GB2'); 
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c, Parent_Geography__r.Id, Parent_Geography__r.Parent_Geography__r.Id FROM Geography__c WHERE Id = :geographyId];
     
        country.name= 'Updated Name';
        update country;
        System.assertEquals(country.name, 'Updated Name', 'Name updated');
        Test.stopTest();
    }
}