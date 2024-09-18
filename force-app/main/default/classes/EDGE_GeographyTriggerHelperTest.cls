/**********************************************************************
Name: EDGE_GeographyTriggerHelperTest
=======================================================================
Req: This is the test class for GeographyTrigger,GeographyTriggerHandler,
EDGE_GeographyTriggerHelper
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0         Preyanka Ghosh     16/05/2019      Initial Development
***********************************************************************/
@isTest
public class EDGE_GeographyTriggerHelperTest {
    
    @isTest
    public static void createUpdateGeography(){
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU2'); 
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c, Parent_Geography__r.Id, Parent_Geography__r.Parent_Geography__r.Id FROM Geography__c WHERE Id = :geographyId];
        Id hubId = country.Parent_Geography__r.Parent_Geography__r.Id;
        country.name= 'Updated Name';
        update country;
        
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Australia Cluster1';
        cluster.Code__c = 'AUC1';
        cluster.Parent_Geography__c = hubId;
        insert cluster; 
        System.assert(cluster != null);
        
        country.Parent_Geography__c = cluster.Id;
        update country;
        
        Test.stopTest();
        
        //create MDM User
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('Adminuser','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser;
        
        System.runAs(testAdminUser) {
            delete country;
        }
    }

}