/**                                                           
* @description EDGE_LicenseTriggerHelperTest
* @purpose Test class for EDGE_LicenseTriggerHelper
* @history

VERSION     AUTHOR           DATE            DETAIL
1.0         Sandeep Sahoo    23/04/2019     Test Class for EDGE_LicenseTriggerHelper
2.0         Preyanka Ghosh   12/07/2019     ES20-2947
**/

@isTest
public class EDGE_LicenseTriggerHelperTest{
    /**
    @Description  : testAllowDuplicateLicense
    @Purpose : To check the duplicate license
    **/
    @isTest
    public static void testAllowDuplicateLicense(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        Test.startTest();
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        Account newOutlet = EDGE_UtilityTestClass.getOutletRecord(); 
        newOutlet.Name = 'Test_Outlet1';
        newOutlet.BillingStreet = '17 Asian Highway 451';
        newOutlet.BillingCity = 'Sydney';
        newOutlet.BillingState = 'Tasmania';
        newOutlet.BillingPostalCode = '700157';
        newOutlet.BillingCountry = 'Australia';
        newOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert newOutlet;
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= countryId,Allow_Duplicate_Licence_Number__c=False);
        insert newMs;
        Test.stopTest();
        License__c newLicense =new License__c(Outlet_Id__c=outlet.Id,License_Number__c='123456789',License_Type__c='Wine');
        insert newLicense;
        system.assertNotEquals(newLicense.Id, '','');
        
        try{
            License__c license =new License__c(Outlet_Id__c=newOutlet.Id,License_Number__c='123456789',License_Type__c='Wine');
            insert license;
            system.assertNotEquals(License.Id, '','');            
            
        } catch (Exception ex){
            System.debug(LoggingLevel.Debug,'Error '+ex.getCause());    
        }
        newLicense.License_Number__c = '908789';
        update newLicense;

    }
    
     @isTest
    public static void testCreateFCR(){
        Id contId;
        Pick_Up_Options__c pickupOption;
        User salesRep;
        Account outlet;
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AU'); 
        System.assert(contId != null,'cont Id should not be null');
         
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= contId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        System.assert(newMs != null,'newMs id should not be null');
        
        Field_Permission_set__c fieldperSet = new Field_Permission_set__c();
        fieldperSet.Market_Setting__c = newMs.Id;
        fieldperSet.Type__c = 'Outlet';
        insert fieldperSet;
        
        test.startTest();
        Field_Permission__c fieldPermission = new Field_Permission__c();
        fieldPermission.Field_Permission_Set__c = fieldperSet.Id;
        fieldPermission.Field__c = 'License_Number__c';
        fieldPermission.Related_Object__c = 'License__c';
        fieldPermission.Permission__c = 'Editable - MDM Approval Required';
        insert fieldPermission;
        
        Business_Role__c bRole = new Business_Role__c();
        bRole.Field_Permission_Set_Outlet__c = fieldperSet.Id;
        bRole.Name = 'Sales Rep';
        bRole.Global_Equivalent__c = 'Sales Rep';
        bRole.Call_Type__c = 'Measure and Sell';
        bRole.Country__c = contId;
        bRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;New_Product_Distribution__c;Volume_YOY_uplift__c;#of Kegs;OPPS OPEN;OPPS CLOSED;Last_Visit_Sales__c;Outlet_Visit_Priority__c;Actual_Physical_Call_Market_Cycle__c;Total_Virtual_Calls__c;Primary_Sales_Territory__r.Name;Primary_Sales_Rep__r.name';
        insert bRole;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        insert pickupOption;
        
        outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active'; 
        outlet.BillingCity = 'Austria';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter'; 
        outlet.Country__c = contId;
        insert outlet; 
        System.assert(outlet.Id != null,'outlet Id should not be null');
       
        License__c licenseRec = new License__c();
        licenseRec.Outlet_Id__c = outlet.Id;
        licenseRec.License_Number__c = '1000023';
        licenseRec.License_Type__c='Wine';
        insert licenseRec;
        delete licenseRec;
        undelete licenseRec;
        
        system.runAs(testAdminUser){
            salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = testAdminUser.Id;
            insert salesRep; 
            System.assert(salesRep.Id!=null,'salesRep Id should not be null');
            
            User_Business_Role__c userBRole = new User_Business_Role__c();
            userBRole.Business_Role__c = bRole.Id;
            userBRole.User__c = salesRep.Id;
            insert userBRole;
           
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = contId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Edit';
            Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = bRole.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Edit';
            Database.insert(brs,false);
                      
            AccountTeamMember newAccTeamMember = new AccountTeamMember();
            newAccTeamMember.AccountId = outlet.Id;
            newAccTeamMember.UserId = salesRep.Id;
            newAccTeamMember.AccountAccessLevel = 'Edit';
            newAccTeamMember.OpportunityAccessLevel = 'Edit';
            newAccTeamMember.ContactAccessLevel = 'Edit';
            insert newAccTeamMember;
            System.assert(newAccTeamMember.Id!=null,'new Acc Team Member Id should not be null');
        } 
        test.stopTest();
        System.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
           
            License__c testSO1 = [Select ID,License_Number__c from License__c where ID =: licenseRec.Id Limit 1];
            testSO1.License_Number__c = '3002598';
            try{
            update testSO1; 
                
            }catch(Exception ex){
                System.debug(LoggingLevel.Debug,'Error '+ex.getCause());
                
            }
        }
    }
}