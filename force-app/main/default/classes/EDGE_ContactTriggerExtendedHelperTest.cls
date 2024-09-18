/**********************************************************************
Name: EDGE_ContactTriggerExtendedHelperTest
=======================================================================

History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Shahbaz Khan      07/12/2020        ES20-8738   
***********************************************************************/
@isTest
public class EDGE_ContactTriggerExtendedHelperTest {
    @isTest
    public static void testUpdateUserFields(){
        User mdm;
        Contact contact;
        Account outlet;
        Id countryId;
        UserRole role = [Select Id,  DeveloperName FROM UserRole where DeveloperName = 'Global' Limit 1];
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.UserRoleId = role.Id;
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
        System.runAs(adminUser){
            countryId = EDGE_UtilityTestClass.setupCountry('AU');
            Market_Setting__c markSet = EDGE_UtilityTestClass.getMarketSetting(countryId);
            insert markSet;
            
            EDGE_UtilityTestClass.createOrgSettings();            
            Pick_Up_Options__c outVisitPrior= EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
            outVisitPrior.Name = 'Priot [AU]';
            insert outVisitPrior;
            
            //Creating Sales Rep 
            mdm= EDGE_UtilityTestClass.runAsUser('MDM','Master Data Manager');
            mdm.Available_Countries__c = 'AU';
            insert mdm;
            System.assert(mdm.Id!=null,'mdm should not be null'); 
            
            outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet.Name = 'Outlet First';
            insert outlet;
            
            contact = EDGE_UtilityTestClass.getContact(outlet.Id);
            contact.FirstName = 'test';
            contact.LastName = 'contact';
            contact.OwnerId=mdm.Id;
            insert contact;
            Test.startTest();
            
            User commUser = EDGE_UtilityTestClass.runAsUser('test', 'Customer Community User');
            commUser.ContactId = contact.Id;
            commUser.PortalRole = 'Manager';
            insert commUser;
            system.assert(commUser.Id!=null,'commUser should not be null');
            Test.stopTest();
        }
        System.runAs(mdm){
            contact.FirstName = 'test3';
            update contact;            
        }
    } 
}