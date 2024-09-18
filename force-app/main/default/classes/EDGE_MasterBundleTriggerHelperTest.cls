/**

* @Description : EDGE_MasterBundleTriggerHelperTest

* @Purpose : Test EDGE_MasterBundleTriggerHelper

* @History:

* @Version   Developer         Date            User Story	        

*   1.1		  Shivam      07/12/2022		 ES20-13531(Access to Master Bundle Object_SFDC_Quality Equipments)

*/
@istest
public class EDGE_MasterBundleTriggerHelperTest {
    
    /**
* @description checkSharingTest : To check the sharing of object
* @return void
* @param 
*/
    @isTest
    public static void checkLCCSharingTest(){
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'GB';
        insert testAdminUser;
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB'); 
        Master_Bundle__c mb = new Master_Bundle__c();
        mb.Name = 'Master Bundle';
        mb.Active__c = true;
        mb.Country__c = countryId;
        mb.Description__c = 'Test Description';
        insert mb;
        Assert.areEqual(mb.Country__c,countryId,'Working Fine');
        Test.startTest();
       	Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Great Britain Country1';
        secCountry.Code__c = 'GB1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        mb.Country__c = secCountry.Id;
        update mb; 
        Assert.areEqual(mb.Country__c,secCountry.Id,'Working Fine');         
        delete mb;
        undelete mb;
        Test.stopTest();
        
    }
}