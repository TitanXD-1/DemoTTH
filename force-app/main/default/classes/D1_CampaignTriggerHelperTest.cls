/**
* @name   
* @description Test Class for D1_CampaignTriggerHelper
* @history
* VERSION     AUTHOR         DATE            DETAIL
* 1.0         Rithika    	06/12/21     	NCP-5443
**/
@isTest
public with sharing class D1_CampaignTriggerHelperTest {
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        D1_TestDataUtility.createOrgSettings();
        Test.startTest();
        Id countryId = D1_TestDataUtility.setupCountry('AUS');
        system.assert(countryId!=null, 'country id not found');
        
        //Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c globalRec = D1_TestDataUtility.createGeography('Country');
        globalRec.Name = 'Great Britain';
        globalRec.Code__c = 'GB';
        insert globalRec;
        
        try{
            Campaign objTargetList = new Campaign();
            objTargetList.Name = 'Target List 1';
            objTargetList.Country__c = countryId;
            objTargetList.Campaign_Category__c = 'Newsletter';
            insert objTargetList;
            system.assert(objTargetList.Id!=null, 'campaign not found');
            
            objTargetList.Country__c = globalRec.Id;  
            update objTargetList;
            
            delete objTargetList;
            undelete objTargetList;  
        }catch(Exception ex){
            System.debug(LoggingLevel.ERROR, ex.getMessage());
        }
        Test.stopTest();
    }
}