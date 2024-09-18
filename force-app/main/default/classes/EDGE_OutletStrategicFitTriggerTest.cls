/**

* @description : EDGE_OutletStrategicFitTriggerTest

* @purpose : 

* @history :                                                           

*VERSION    AUTHOR              DATE              DETAIL

*1.0       Monalisa Halder     05/12/2023      Initial Development
*2.0       Shivam Chauhan      11/12/2023      148432 - Validation checks on Outlet-Strategic Fit Junction Object Record creation
*3.0       Shivam Chauhan	   27/12/2023	   148622 - Define Approvers in Approval Flow for Strategic Fit updates based on FPS Setting
*4.0       Sakshi Shah         24/06/2024      US-153963 
*/
@isTest
public class EDGE_OutletStrategicFitTriggerTest {
    @isTest
    public static void populateGuidTest(){
	User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1', 'Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesRep.Id;
        insert salesRep;

	EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        //Insert Pick_Up_Options__c
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Strategic Fit').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = new Pick_Up_Options__c();
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Strategic_Fit_Name__c='testStr1';
        pickUpOption.Geography__c=countryId;
        pickUpOption.Status__c='Active';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        insert pickUpOption;
        
        //Insert Pick_Up_Options__c
        String pickUpOptionRecordType1 = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption1.Name = 'Gold[AU]';
        pickUpOption1.Type__c = 'Outlet Visit Prioritization';
        pickUpOption1.RecordTypeId = pickUpOptionRecordType1;
        insert pickUpOption1;

	Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOption1.Id;
        outlet.Independent_of_Owner__c = true;
        outlet.Primary_Sales_Rep__c = salesRep.Id;
        Test.startTest();
        insert outlet;
           
        //Creating a Outlet-Strategic Fit record with is_primary__c as true
        Outlet_Strategic_Fit__c outletStrategicFitPrimary = new Outlet_Strategic_Fit__c(is_Primary__c = true,
                                                                                 Strategic_Fit_Option__c=pickupOption.Id,Outlet__c=outlet.Id  );
        
        insert outletStrategicFitPrimary;
        System.assert(outletStrategicFitPrimary.id!=null , 'Outlet Strategic Fit record not created');
        
        Outlet_Strategic_Fit__c outletStrategicFitPrimary1 = new Outlet_Strategic_Fit__c(is_Primary__c = true,
                                                                                        Strategic_Fit_Option__c=pickupOption.Id,Outlet__c=outlet.Id  );
        
        Boolean hasException=false;
        try{
            insert outletStrategicFitPrimary1;
            
        }
        catch (DmlException e){
            hasException=true;
        }
        
        System.assert(hasException , 'Duplicate primary record should not be allowed');
                

        outletStrategicFitPrimary.is_Primary__c=false;
        update outletStrategicFitPrimary;
        delete outletStrategicFitPrimary;
        undelete outletStrategicFitPrimary;
        Test.stopTest();
        
    }

    @istest
    public static void testGenerateFCR(){
         
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        testAdminUser.Available_Countries__c = 'AU';
        insert testAdminUser; 
        
        User salesManager=EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep1', 'Sales Representative');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.Id;
        insert salesRep;
       
        
        //Insert Pick_Up_Options__c
        List<Pick_Up_Options__c> pickUpOptionsList = new List<Pick_Up_Options__c>();
        
        String pickUpOptionRecordType = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Strategic Fit').getRecordTypeId();
        Pick_Up_Options__c pickUpOption = new Pick_Up_Options__c();
        pickUpOption.Name = 'Gold[AU]';
        pickUpOption.Strategic_Fit_Name__c='testStr1';
        pickUpOption.Geography__c=countryId;
        pickUpOption.Status__c='Active';
        pickUpOption.RecordTypeId = pickUpOptionRecordType;
        pickUpOptionsList.add(pickUpOption);
        //insert pickUpOption;
      
        
        
        //Insert Pick_Up_Options__c
        
        
        String pickUpOptionRecordType1 = Pick_Up_Options__c.sObjectType.getdescribe().getrecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickUpOption1 = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickUpOption1.Name = 'Gold[AU]';
        pickUpOption1.Type__c = 'Outlet Visit Prioritization';
        pickUpOption1.RecordTypeId = pickUpOptionRecordType1;
        pickUpOption1.OwnerId = testAdminUser.id;
        pickUpOptionsList.add(pickUpOption1);
        //insert pickUpOption1;
        insert pickUpOptionsList;
        
         
        
        Market_Setting__c newMs = new Market_Setting__c(Name='Australia MS',Geography__c= countryId, Status__c='Editable & Mandatory - Manager Approval Required');
        insert newMs;
        
        Field_Permission_set__c fieldperSet = new Field_Permission_set__c();
        fieldperSet.Market_Setting__c = newMs.Id;
        fieldperSet.Type__c = 'Outlet';
        insert fieldperSet;
        
        
		Field_Permission__c fieldPermission = new Field_Permission__c();
        fieldPermission.Field_Permission_Set__c = fieldperSet.Id;
        fieldPermission.Field__c = 'Strategic_Fit_Option__c';
        fieldPermission.Related_Object__c = 'Outlet_Strategic_Fit__c';
        fieldPermission.Permission__c = 'Editable & Mandatory - Manager Approval Required';
        insert fieldPermission;
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOptionsList[1].Id;
        outlet.Independent_of_Owner__c = true;
        outlet.Primary_Sales_Rep__c = salesRep.Id;
        outlet.OwnerId = salesRep.id;
        Test.startTest();
        insert outlet;
        
        Outlet_Strategic_Fit__c osf1 = new Outlet_Strategic_Fit__c();
        osf1.Outlet__c = outlet.id;
        osf1.Strategic_Fit_Option__c = pickUpOptionsList[0].id;
        osf1.is_Primary__c = false;
        insert osf1;
        system.assert(osf1.Id != null,'Outlet Strategic Fit can not be null');
        
        Business_Role__c bRole = new Business_Role__c();
        bRole.Field_Permission_Set_Outlet__c = fieldperSet.Id;
        bRole.Name = 'Sales Rep';
        bRole.Global_Equivalent__c = 'Sales Rep';
        bRole.Call_Type__c = 'Measure and Sell';
        bRole.Country__c = countryId;
        bRole.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;New_Product_Distribution__c;Volume_YOY_uplift__c;#of Kegs;OPPS OPEN;OPPS CLOSED;Last_Visit_Sales__c;Actual_Physical_Call_Market_Cycle__c;Total_Virtual_Calls__c;Primary_Sales_Territory__r.Name;Primary_Sales_Rep__r.name';
        insert bRole;
        system.runAs(testAdminUser){
        
            User_Business_Role__c userBRole = new User_Business_Role__c();
            userBRole.Business_Role__c = bRole.Id;
            userBRole.User__c = salesRep.Id;
            insert userBRole;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
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
        }
        
        system.runAs(salesRep){
            EDGE_UtilityClass.stopTriggerToRun = false;
            
            Outlet_Strategic_Fit__c osfSR1= [Select id,Strategic_Fit_Option__c from Outlet_Strategic_Fit__c where id =: osf1.Id Limit 1];
            osfSR1.Strategic_Fit_Option__c = null;
            update osfSR1;
           
            
        }
        test.stopTest();
        
    }
}