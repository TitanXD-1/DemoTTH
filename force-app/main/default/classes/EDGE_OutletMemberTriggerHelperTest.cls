/**
* @Description : EDGE_OutletMemberTriggerHelperTest

* @History : Test class for EDGE_OutletMemberTriggerHelper                                                           

* @VERSION       AUTHOR                   DATE            DETAIL
*  1.0         Anuja Chattopadhyay      09/07/2019      Test Class for EDGE_OutletMemberTriggerHelper
*  2.0		   Aparajita/Rajarshi		11/03/2022		ES20-12216,12231,12213
				/Subhodeep 
*  2.1		   Priya Soni		        10/11/2022		ES20-13469
   3.0		   Doman Murmu				17/07/2023		142822

*/

@isTest
public class EDGE_OutletMemberTriggerHelperTest {
    final static String QUALITYTERRITORYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
    final static String  ACTIVATIONTERRITORYRECORDTYPEID=Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId();

    @testSetup
    public static void createData(){
        
        //List<Outlet_Member__c> outMemList = new List<Outlet_Member__c>();
        Id contId;
        Pick_Up_Options__c pickupOption;
        EDGE_UtilityTestClass.createOrgSettings();
        contId = EDGE_UtilityTestClass.setupCountry('AU');
        
        pickupOption = EDGE_UtilityTestClass.getPickUpOption(contId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        User admin = EDGE_UtilityTestClass.runAsUser('admin','System Administrator');
        admin.Available_Countries__c = 'AU';
        insert admin;
        Test.StartTest();
        EDGE_UtilityClass.printGovLimits(32);     
                
        Territory_Hierarchy__c buTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Business Unit');
        insert buTerHierarchy;
        
        Territory_Hierarchy__c saTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Sales Area');
        saTerHierarchy.Parent_BU__c = buTerHierarchy.Id;
        insert saTerHierarchy;
        EDGE_UtilityClass.printGovLimits(42);
        
        Territory_Hierarchy__c rgTerHierarchy = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Region');
        rgTerHierarchy.Parent_BU__c = saTerHierarchy.Id;
        insert rgTerHierarchy;
        EDGE_UtilityClass.printGovLimits(47);
        
        //Quality Territory Hierarchy
        Territory_Hierarchy__c quaTerriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(contId, 'Quality Territory Hierarchy');
        quaTerriHier.Parent_BU__c = saTerHierarchy.Id;
        quaTerriHier.Territory_Hierarchy_Type__c = 'Dispense Manager';
        insert quaTerriHier;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Sales';
        primaryTerr.Region__c = rgTerHierarchy.Id;
        insert primaryTerr; 
        EDGE_UtilityClass.printGovLimits(53);     
        
        Territory__c dispenseTerr = EDGE_UtilityTestClass.getTerritoryRec();
        dispenseTerr.Territory_Type__c ='Quality Dispense';
        dispenseTerr.Region__c=quaTerriHier.Id;
        dispenseTerr.RecordTypeId = QUALITYTERRITORYRECORDTYPEID;
        insert dispenseTerr;
        
        /*
        Territory_Member__c  territoryMember1 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(usr1.Id,dispenseTerr.Id);
        territoryMember1.Type__c='Primary';
        insert territoryMember1;*/
        
        Territory__c activationTerr= EDGE_UtilityTestClass.getTerritoryRec();
        activationTerr.Territory_Type__c='Activation Territory';
        activationTerr.RecordTypeId=ACTIVATIONTERRITORYRECORDTYPEID;
        insert activationTerr;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Name = 'Test Outlet11';
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Global_Channel__c = 'Off Trade';
        outlet.Global_Sub_Channel__c ='Retailer';
        outlet.Global_Segment__c = 'Discounter';
        outlet.Global_Sub_Segment__c = 'Modern Discounter';
        //outlet.Country__c = countryId;
        insert outlet;
        EDGE_UtilityClass.printGovLimits(62);
    }
    
    @isTest   
    public static void testOutletMemberTriggerMethods(){
        
        List<Outlet_Member__c> outMemList = new List<Outlet_Member__c>();
        
        //Pick_Up_Options__c pickupOption = [Select Id from Pick_Up_Options__c where Type__c = 'Outlet Visit Prioritization'
        //                                  LIMIT 1];
        Territory__c primaryTerr = [Select Id from Territory__c where Territory_Type__c = 'Sales' LIMIT 1];
        Territory__c dispenseTerr = [Select Id from Territory__c where Territory_Type__c = 'Quality Dispense' LIMIT 1];
        Territory__c activationTerr = [Select Id from Territory__c where Territory_Type__c = 'Activation Territory' LIMIT 1];
		
        
        /*List<Geography__c> countryList = [Select Id from Geography__c where Code__c = 'AU'];
        system.assert(countryList.size() > 0);
        Id countryId = countryList[0].Id;*/
        Account outlet = [Select Id from Account where Name = 'Test Outlet11' LIMIT 1];
        //System.debug('Condition 1 '+Limits.getQueries());
        
        
       
        
        //List<User> users = new List<User>();
        User testAdminUser = EDGE_UtilityTestClass.runAsUser('testAdmin','System Administrator');
        insert testAdminUser; 
        
        
        System.runAs(testAdminUser)
        {
            Org_Setting__c orgSetting = [select Run_Validation_Rules__c,SetUpOwnerId from Org_Setting__c]; 
            orgSetting.Run_Validation_Rules__c = false;
            update orgSetting;
        }
         Test.startTest();
        User userRec = EDGE_UtilityTestClass.runAsUser('TestDummy' , 'Sales Representative');
        userRec.Business_Role__c = 'Sales Representative';

        userRec.ManagerId = testAdminUser.Id;
        insert userRec;        
        System.assert(userRec.id!=null,'userRec should not be null');
        
        Territory_Member__c  territoryMember1 = EDGE_UtilityTestClass.getPrimaryTerrMemberRec(userRec.Id,dispenseTerr.Id);
        territoryMember1.Type__c='Primary';
        territoryMember1.Start_Date__c = Date.today();

        insert territoryMember1;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, primaryTerr.Id);
        outlTer.Active__c='Active';
        insert outlTer; 
        EDGE_UtilityClass.printGovLimits(76);
        
        Outlet_Territory__c disOutlTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, dispenseTerr.Id);
        disOutlTer.Active__c='Active';
        insert disOutlTer; 
        EDGE_UtilityClass.printGovLimits(78);
        
        
        Outlet_Territory__c actOutlTer = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id, activationTerr.Id);
        actOutlTer.Active__c='Active';
        insert actOutlTer; 
        EDGE_UtilityClass.printGovLimits(80);
        
        List<Outlet_Member__c> omTeamUpdateList = new List<Outlet_Member__c>();
        List<Outlet_Member__c> omTeamDeleteList = new List<Outlet_Member__c>();
        List<User> listOfUsers=new List<User>();
        for(Integer i=1;i<=3;i++)
        {
			User userRe = EDGE_UtilityTestClass.runAsUser('TestDummy'+i , 'Sales Representative');
            userRe.Business_Role__c = 'Sales Representative';
            userRe.ManagerId = testAdminUser.Id;
            //insert userRe; 
			listOfUsers.add(userRe);        
        }
        Database.insert(listOfUsers);		//142822
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, listOfUsers[0].Id, 'Primary');
        Outlet_Member__c omTest1 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, listOfUsers[1].Id, 'Secondary');
        Outlet_Member__c omTest2 = EDGE_UtilityTestClass.getOutletMemberRecord(outlet.Id, listOfUsers[2].Id, 'Dispense Rep');
        
        outMemList.add(omTest);
        outMemList.add(omTest1);
        outMemList.add(omTest2);

        insert outMemList;
        EDGE_OutletMemberTriggerHelper.removeContactSharing(outMemList);
        EDGE_UtilityClass.printGovLimits(80);
        omTest1.Outlet_Role__c = 'Activation Specialist';
        omTeamUpdateList.add(omTest);
        omTeamUpdateList.add(omTest1);
        omTeamUpdateList.add(omTest2);

        Database.update(omTeamUpdateList);
        
        omTeamDeleteList.add(omTest);
        omTeamDeleteList.add(omTest1);
        omTeamUpdateList.add(omTest2);

        Database.delete(omTeamDeleteList);
        
        EDGE_UtilityClass.printGovLimits(98);
        Test.StopTest();        
    }
}