/*
*Name: EDGE_UpdateContactCtrlTest

*Req: 

*History                                                            
                                                           
*VERSION   AUTHOR            DATE              DETAIL
*1.0		 Sandip Ghosh 		04/09/2020		 ES20-8427
*2.0      Swaraj Samanta     05/09/2022       ES20-13284
*/
@isTest
public class EDGE_UpdateContactCtrlTest {
    @isTest
    public static void manageContactAccountRelTest(){
        
        user mdm;
        User adminUser;
        Contact cont;
        Contact cont1;
        
        User commUser;
        
        List<Profile> commProfiles = [Select Id from Profile where Name = 'Customer Community User' LIMIT 1];
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
        adminUser = [Select Id,UserRoleId from User where FirstName = 'TestAdmin1' LIMIT 1];
        System.runAs(adminUser){
            Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
            System.assert(countryId != null,'countryId should not be null');
            
            Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= countryId, Status__c='Editable - Manager Approval Required');
            insert newMs;
            System.assert(newMs != null,'newMs should not be null');
            
            String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
            pickupOption.Name = 'Gold [AU]';
            pickupOption.RecordTypeId = pickupRecordType;
            pickupOption.Status__c = 'Active';
            insert pickupOption;
            
            //Creating MDM 
            mdm= EDGE_UtilityTestClass.runAsUser('MDM','Master Data Manager');
            mdm.Available_Countries__c = 'AU';
            insert mdm;
            System.assert(mdm.Id!=null,'mdm should not be null');
            
            Account outlet = EDGE_UtilityTestClass.getOutletRecord();  
            outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;    
            outlet.Global_Channel__c = 'Off Trade';
            outlet.Global_Sub_Channel__c ='Retailer';
            outlet.Global_Segment__c = 'Discounter';
            outlet.Global_Sub_Segment__c = 'Modern Discounter';
            outlet.Status__c ='Active';
            outlet.Country__c = countryId;
            outlet.OwnerId = adminUser.Id;
            Test.startTest();
            insert outlet;
            List<Contact> contacts=new List<Contact>();
            cont = EDGE_UtilityTestClass.getContact(outlet.Id);
            contacts.add(cont);
  
            
            cont1 = EDGE_UtilityTestClass.getContact(outlet.Id);
            contacts.add(cont1);
            insert contacts;
            
            //Creating MDM 
            if(commProfiles != null && commProfiles.size() > 0){
                commUser = new User();
                commUser.firstName = 'commUserFirst';
                commUser.lastName = 'commUserLast';
                commUser.ContactId = cont.Id;
                commUser.Username = 'test-01-Sep-001@test.com';
                commUser.Email = 'test-01-Sep-001@test.com';
                commUser.CommunityNickname = 'test-01-Sep';
                commUser.Alias = '0908001';
                commUser.TimeZoneSidKey = 'America/Phoenix'; // Required
                commUser.LocaleSidKey = 'en_US'; // Required
                commUser.EmailEncodingKey = 'ISO-8859-1'; // Required
                commUser.LanguageLocaleKey = 'en_US'; // Required
                commUser.ProfileId = commProfiles[0].Id;
                commUser.Available_Countries__c = 'AU';
                insert commUser;
            }
        }   
        
        System.runAs(mdm){
            
            EDGE_UpdateContactCtrl.checkContactStatus(cont1.Id);
            EDGE_UpdateContactCtrl.deleteContact(cont1.Id);
            
            EDGE_UpdateContactCtrl.checkContactStatus(cont.Id);
            EDGE_UpdateContactCtrl.deleteContact(cont.Id);
            EDGE_UpdateContactCtrl.getListViews();
            
        }
        Test.stopTest();
    }
    
    @testSetup
    public static void createInitialData(){
        
        UserRole globalRole = [Select Id from UserRole where Name = 'Global' LIMIT 1];
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.FirstName = 'TestAdmin1';
        adminUser.LastName = 'LastName';
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        adminUser.UserRoleId = globalRole.Id;
        insert adminUser;
    }
}