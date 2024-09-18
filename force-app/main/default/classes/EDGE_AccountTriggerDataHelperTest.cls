/**
  *@ description : EDGE_AccountTriggerDataHelperTest

  *@ History                                                            

1.0		Shahbaz Khan		04/09/2020		 
**/

@isTest
public class EDGE_AccountTriggerDataHelperTest {
    @isTest
    public static void testManageContacts(){
        List<Account> outList = new List<Account>();
        List<Contact> conList = new List<Contact>();
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
            EDGE_UtilityTestClass.createOrgSettings();            Pick_Up_Options__c outVisitPrior= EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
            outVisitPrior.Name = 'Priot [AU]';
            insert outVisitPrior;
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();
            outlet.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet.Name = 'Outlet First';
            outList.add(outlet);
            Account outlet1= EDGE_UtilityTestClass.getOutletRecord();
            outlet1.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet1.Name = 'Outlet Second';
            outList.add(outlet1);
            Account outlet2= EDGE_UtilityTestClass.getOutletRecord();
            outlet2.Outlet_Visit_Prioritisation_Grade__c = outVisitPrior.Id;
            outlet2.Name = 'Outlet Third';
            outList.add(outlet2);
            insert outList;
            
            Contact contact1 = EDGE_UtilityTestClass.getContact(outlet.Id);
            conList.add(contact1);
            Contact contact2 = EDGE_UtilityTestClass.getContact(outlet1.Id);
            contact2.LastName = 'Jordon';
            contact2.Email = 'jrd@gmail.com';
            conList.add(contact2);
            insert conList;
            
            User commUser = EDGE_UtilityTestClass.runAsUser('test', 'Customer Community User');
            commUser.ContactId = contact1.Id;
            commUser.PortalRole = 'Manager';
            insert commUser;
            system.assert(commUser.Id!=null,'CommUser Inserted');
            AccountContactRelation accConRel1 = new AccountContactRelation();
            accConRel1.AccountId = outlet.Id;
            accConRel1.ContactId = contact2.Id;
            accConRel1.Contact_Type__c = 'Secondary';
            insert accConRel1;
            Test.startTest();
            outlet2.Deletion_Flag_from_SAP__c = true;
            update outList;
            outlet.Status__c = 'Closed';
            update outlet;
            Test.stopTest();
            
        }
        
    }
    
      /** 
    *@  Method : testprospectApprovalProcessExt  
    *@  Req :  Bug - ES20-9409
    *@  Test Class for covering prospectApprovalProcess method on EDGE_AccountTriggerExtHelper class
    **/   
      
    @isTest
    public static void testprospectApprovalProcessExt(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        User newUser = new User();
        newUser.Alias = 'testrest';
        newUser.Email = 'test.rest@edgeorg.com';
        newUser.EmailEncodingKey  = 'UTF-8';
        newUser.LastName = 'Test123';
        newUser.FirstName = 'example';
        newUser.LanguageLocaleKey  = 'en_US';
        newUser.LocaleSidKey = 'en_US';
        newUser.ProfileId = [select Id from Profile where Name ='System Administrator' limit 1].Id;
        newUser.TimeZoneSidKey = 'America/Chicago';
        newUser.Username = 'Test123@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser.Available_Countries__c = 'AU';
        insert newUser;
        
        User newUser1 = new User();    
        newUser1.Alias = 'terest1';
        newUser1.Email = 'test.rest1@edgeorg.com';
        newUser1.EmailEncodingKey  = 'UTF-8';
        newUser1.LastName = 'Test1234';
        newUser1.FirstName = 'example1';
        newUser1.LanguageLocaleKey  = 'en_US';
        newUser1.LocaleSidKey = 'en_US';
        newUser1.ProfileId = [select Id from Profile where Name ='System Administrator' limit 1].Id;
        newUser1.ManagerId = newUser.Id;
        newUser1.TimeZoneSidKey = 'America/Chicago';
        newUser1.Username = 'Test123@test' + Math.round(Math.random() * 10000) + '.com'; 
        newUser1.Available_Countries__c = 'AU';
        insert newUser1;
        
        Market_Setting__c marketSettings = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketSettings.Local_Segmentation_Validation__c = true;
        marketSettings.Auto_Add_to_Territory__c = True;
        marketSettings.Prospect_Approver__c = 'Sales Manager & MDM Approval Required';
        insert marketSettings;
        
        
        
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'VSTPKUP[AU]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        system.assert(oultlVstPriPkUp.id != null,'oultlVstPriPkUp Inserted');
        
        Account prospectAccount = EDGE_UtilityTestClass.getProspectRecord(oultlVstPriPkUp.id);
        prospectAccount.BillingStreet = 'testStreet';
        prospectAccount.Global_Channel__c = 'off Trade';
        prospectAccount.Global_Sub_Channel__c = 'Retailer';
        prospectAccount.Global_Segment__c = 'Hypermarket';
        prospectAccount.Global_Sub_Segment__c = 'Modern Hypermarket';
        prospectAccount.Status__c = 'Active';
        prospectAccount.BillingCity = 'Tasmania';
        prospectAccount.BillingCountry = 'Australia';
        Test.startTest();
        System.runAs(newUser1){
            insert prospectAccount;
            
            prospectAccount.Status__c = 'Approved';
            try{
                update prospectAccount;
            }
            catch(Exception e){
                 System.debug(LoggingLevel.Debug,'Error Faced '+e.getCause());
            }            
        }
        Test.stopTest();
    } 
    
}