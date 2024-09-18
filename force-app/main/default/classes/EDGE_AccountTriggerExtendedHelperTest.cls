/**
* @description EDGE_AccountTriggerExtendedHelperTest
* @history
                                                           
VERSION   AUTHOR                   DATE              DETAIL
1.0                             04/02/2020        Test class to cover EDGE_AccountTriggerExtendedHelper class.
1.1      Rajarshi Lahiri		20/09/2022		  ES20-12998
*/

@isTest
public class EDGE_AccountTriggerExtendedHelperTest {
    
    final static String OUTLETRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String OPERATORRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Owner/Operator').getRecordTypeId();
    final static String DISTRIBUTORRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Distributor/Wholesaler').getRecordTypeId();
    
    @isTest
    public static void testCleanClosedOutlet(){
        Set<Id> countryIdSet = new Set<Id>();
        Set<Id> outletIdset  = new set<Id>();
        list<Field_Permission__c> fpsList = new list<Field_Permission__c>();
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        countryIdSet.add(countryId);
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        marketsetting.Local_Segmentation_Validation__c = false;
        insert marketsetting;
        System.assert(marketsetting.Id!=null,'Market Setting Record Inserted');
        
       /* Market_Cycle__c marCycle = new Market_Cycle__c();
        marCycle.Geography__c = countryId;
        marCycle.Start_Date__c = Date.today();
        marCycle.End_Date__c = Date.today().adddays(20);
        insert marCycle;*/
        
        //Field permission set
        Field_Permission_Set__c fps = new Field_Permission_Set__c();
        fps.Type__c = 'Outlet';
        fps.Market_Setting__c = marketsetting.id;
        insert fps;
        
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Permission__c = 'Editable - MDM Approval Required';
        fp.Field__c = 'Centrally_Managed__c';
        fp.Field_Permission_Set__c = fps.id;
        fpsList.add(fp);
        
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Permission__c = 'Editable - MDM Approval Required';
        fp1.Field__c = 'Centrally_Managed_Note__c';
        fp1.Field_Permission_Set__c = fps.id;
        fpsList.add(fp1);
        
        Field_Permission__c fp2 = new Field_Permission__c();
        fp2.Related_Object__c = 'Account';
        fp2.Permission__c = 'Editable - MDM Approval Required';
        fp2.Field__c = 'Website';
        fp2.Field_Permission_Set__c = fps.id;
        fpsList.add(fp2);
        
        insert fpsList;
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
        User salesRep;
        System.runAs(adminUser){
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            insert salesRep;
            
            //Create Business Role
            Business_Role__c br = new Business_Role__c();
            br.Name = 'Sales Rep AU';
            br.Global_Equivalent__c = 'Sales Rep';
            br.Country__c = countryId;
            br.Field_Permission_Set_Outlet__c = fps.Id;
            br.Call_Type__c = 'Measure and Sell';
            br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            insert br;
            
            //user business role 
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.Id;
            ubr.User__c = salesRep.id;
            insert ubr;
            System.assert(salesRep.Id!=null,'salesRep Inserted');    
        }
        
                
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        System.debug(LoggingLevel.Debug,'1--'+Limits.getQueries());
        
        EDGE_UtilityClass.printGovLimits(107);
        
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier;    
        System.debug(LoggingLevel.Debug,'--2--'+Limits.getQueries());
        List<Territory__c> terrList=new List<Territory__c>();
        Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Region__c = terriHier.Id;
        terr.Sales_Area__c = terriHierSA.Id;
        terr.Business_Unit__c = terriHierBU.Id;
        terr.Country__c = countryId;
        terrList.add(terr);  
        System.debug(LoggingLevel.Debug,'--127--'+Limits.getQueries());
		Test.startTest();        
        EDGE_UtilityClass.printGovLimits(132);
        Territory__c terr1= EDGE_UtilityTestClass.getTerritoryRec();
        terr1.Territory_Type__c = 'Sales';
        terr1.Region__c = terriHier.Id;
        terr1.Sales_Area__c = terriHierSA.Id;
        terr1.Business_Unit__c = terriHierBU.Id;
        terr1.Country__c = countryId;
        terrList.add(terr1);
        insert terrList;
        System.debug(LoggingLevel.Debug,'--3--'+Limits.getQueries());
        
        List<Account> accList=new List<Account>();
        Account acc = new Account();
        acc =  EDGE_UtilityTestClass.getOutletRecord();
        acc.RecordTypeId = OUTLETRECORDTYPEID;
        acc.BillingStreet ='17 Asian Highway 45';
        acc.BillingCity =  'Tasmania';
        acc.BillingPostalCode = '5668';
        acc.BillingState = 'Tasmania';
        acc.BillingPostalCode = '5668';
        acc.BillingCountryCode = 'AU';
        acc.Status__c = 'Active';
        acc.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 
        acc.primary_sales_territory__c = terr.Id;
        acc.Primary_Sales_Territory_Region__c = terriHier.Id;
        accList.add(acc);
        Account acc1 = new Account();
        
        acc1 =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.Name='Test Outlet 1';
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.BillingStreet ='17 Asian Highway 45';
        acc1.BillingCity =  'Tasmania';
        acc1.BillingPostalCode = '5668';
        acc1.BillingState = 'Tasmania';
        acc1.BillingPostalCode = '5668';
        acc1.BillingCountryCode = 'AU';
        System.debug(LoggingLevel.Debug,'--5--'+Limits.getQueries());
        acc1.Status__c = 'Active';
        acc1.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 
        acc1.primary_sales_territory__c = terr.Id;
        acc1.Primary_Sales_Rep__c = salesRep.id;
        acc1.Primary_Sales_Territory_Region__c = terriHier.Id;
        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Total_Virtual_Calls__c = 3;
        accList.add(acc1);
        insert accList;
        
        
        Outlet_Territory__c outletTerr = new Outlet_Territory__c();
        outletTerr.Territory__c = terr.Id;
        outletTerr.Outlet__c = acc.Id;
        
        insert outletTerr;
        System.debug(LoggingLevel.Debug,'--4--'+Limits.getQueries());
        //create Target List
       /* Target_List__c targetList = EDGE_UtilityTestClass.getTargetList(countryId);
        insert targetList;
        
        //Creating Record of Target List Member 
        Target_List_Member__c targetListMember = EDGE_UtilityTestClass.getTargetMemList(acc.Id, targetList.Id);
        targetListMember.Assignment_Status__c = 'Active';
        
        insert targetListMember;*/
        
        acc.primary_sales_territory__c = terr1.Id;
        acc.Status__c = 'Closed';
        acc.Called_on__c = false;
        acc.Send_To_Trax__c = false;  
        update acc;
        outletIdset.add(acc.id);
        
        
        System.debug(LoggingLevel.Debug,'--199--'+Limits.getQueries());
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = acc1.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        System.debug(LoggingLevel.Debug,'--214--'+Limits.getQueries());
        EDGE_UtilityClass.printGovLimits(213);
        System.runAs(salesRep){
            //updating outlet
            acc1.Centrally_Managed_Note__c = 'test comment';
            acc1.Centrally_Managed__c = true;
            acc1.Website = 'www.test.com';
            acc1.Total_Virtual_Calls__c = 4;
            update acc1;     
        }
        // EDGE_AccountTriggerExtendedHelper.removeClosedOutlet(countryIdSet,outletIdset);
        System.debug(LoggingLevel.Debug,'--6--'+Limits.getQueries());
       Test.stopTest();
    }   
    
    @isTest
    public static void createFieldChangeRequestTest(){
        User salesRep;
        List<User> users = new List<User>();
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        users.add(adminUser1);
        
        insert users;
        System.debug(LoggingLevel.Debug,'--1--'+Limits.getQueries());
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        
        insert marketsetting;
		System.debug(LoggingLevel.Debug,'--2--'+Limits.getQueries());        
        System.assert(marketsetting.Id!=null,'Market Seting Inserted');
        Test.startTest();
        //Field permission set
        Field_Permission_Set__c fps = new Field_Permission_Set__c();
        fps.Type__c = 'Outlet';
        fps.Market_Setting__c = marketsetting.id;
        insert fps;
        System.debug(LoggingLevel.Debug,'--3--'+Limits.getQueries());
        Field_Permission_Set__c fps1 = new Field_Permission_Set__c();
        fps1.Type__c = 'Prospect';
        fps1.Market_Setting__c = marketsetting.id;
        insert fps1;
        
        System.debug(LoggingLevel.Debug,'--4--'+Limits.getQueries());
        
        List<Field_Permission__c> fpList = new List<Field_Permission__c>();
        //field permission
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp.Field__c = 'Centrally_Managed__c';
        fp.Dependent_Fields__c = 'Centrally_Managed_Note__c';
        fp.Field_Permission_Set__c = fps.id;
        fpList.add(fp);
        //insert fp;
        
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Permission__c = 'Editable - MDM Approval Required';
        fp1.Field__c  = 'Centrally_Managed_Note__c';
        fp1.Field_Permission_Set__c = fps.id;
        fpList.add(fp1);
        //insert fp1;
        
        Field_Permission__c fp2 = new Field_Permission__c();
        fp2.Related_Object__c = 'Account';
        fp2.Permission__c = 'Editable ';
        fp2.Field__c  = 'Local_Segment_Advanced_Analytics__c';
        fp2.Field_Permission_Set__c = fps.id;
        //insert fp2;
        fpList.add(fp2);
        
        Field_Permission__c fp4 = new Field_Permission__c();
        fp4.Related_Object__c = 'Account';
        fp4.Permission__c = 'Editable - MDM Approval Required ';
        fp4.Field__c  = 'Status__c';
        fp4.Field_Permission_Set__c = fps.id;
        //insert fp4;
        fpList.add(fp4);
        
        Field_Permission__c fp3 = new Field_Permission__c();
        fp3.Related_Object__c = 'Account';
        fp3.Permission__c = 'Editable - MDM Approval Required ';
        fp3.Field__c  = 'Outlet_Email_Address__c';
        fp3.Field_Permission_Set__c = fps1.id;
        //insert fp3;
        fpList.add(fp3);
        
        //Editable - Sales Manager Approval Required
        Field_Permission__c fp5 = new Field_Permission__c();
        fp5.Related_Object__c = 'Account';
        fp5.Permission__c = 'Editable - Manager Approval Required';
        fp5.Field__c  = 'BillingCity';
        fp5.Field_Permission_Set__c = fps.id;
        //insert fp5;
        fpList.add(fp5);
        
        insert fpList;
        
        System.debug(LoggingLevel.Debug,'--5--'+Limits.getQueries());
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        System.debug(LoggingLevel.Debug,'--6--'+Limits.getQueries());
        /*Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier; */
        
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'AU_MDM', Type = 'Queue');
            insert grp;        
            QueueSobject mappingObject = new QueueSobject(QueueId = grp.Id, SobjectType = 'Field_Change_Request__c');
            insert mappingObject;
        }
        System.debug(LoggingLevel.Debug,'--7--'+Limits.getQueries());
       /* Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Region__c = terriHier.Id;
        terr.Sales_Area__c = terriHierSA.Id;
        terr.Business_Unit__c = terriHierBU.Id;
        terr.Country__c = countryId;
        insert terr;*/
        
        Account acc1  =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.Status__c = 'Active';       
        acc1.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 
        //acc1.primary_sales_territory__c = terr.Id;
        //acc1.Primary_Sales_Territory_Region__c = terriHier.Id;
        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Website = 'www.test11.com';
        acc1.Total_Virtual_Calls__c = 3;
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        insert acc1; 
        
		System.debug(LoggingLevel.Debug,'--8--'+Limits.getQueries());        
       /* Outlet_Territory__c outletTerr = new Outlet_Territory__c();
        outletTerr.Territory__c = terr.Id;
        outletTerr.Outlet__c = acc1.Id;
        insert outletTerr;*/
        
        System.runAs(adminUser){
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = adminUser1.Id;
            insert salesRep;
            System.assert(salesRep.Id!=null,'Sales Rep Inserted');
            System.debug(LoggingLevel.Debug,'--9--'+Limits.getQueries()); 
            //Create Business Role
            Business_Role__c br = new Business_Role__c();
            br.Name = 'Sales Rep AU';
            br.Global_Equivalent__c = 'Sales Rep';
            br.Country__c = countryId;
            br.Field_Permission_Set_Outlet__c = fps.Id;
            br.Call_Type__c = 'Measure and Sell';
            br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            insert br;
            System.debug(LoggingLevel.Debug,'--10--'+Limits.getQueries()); 
            //user business role 
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.Id;
            ubr.User__c = salesRep.id;
            insert ubr;
            System.debug(LoggingLevel.Debug,'--11--'+Limits.getQueries()); 
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            insert geoShare;
            //Database.SaveResult sr1 = Database.insert(geoShare,false);
            System.debug(LoggingLevel.Debug,'--12--'+Limits.getQueries());
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = br.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            insert brs;
            //Database.SaveResult sr = Database.insert(brs,false);
            System.debug(LoggingLevel.Debug,'--13--'+Limits.getQueries());
        } 
        Test.stopTest();
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = acc1.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        System.debug(LoggingLevel.Debug,'--14--'+Limits.getQueries()); 
        System.runAs(salesRep){
            //updating outlet
            acc1.Centrally_Managed__c = true;
            acc1.Centrally_Managed_Note__c = 'test comment1';
            acc1.Local_Segment_Advanced_Analytics__c = 'Workers';
            try{
                update acc1; 
            } catch(Exception ex){
                System.debug(LoggingLevel.Debug,'error '+ex.getCause()+ex.getLineNumber()+ex.getStackTraceString()+ex.getMessage());
            }
        }
        System.debug(LoggingLevel.Debug,'--15--'+Limits.getQueries());
        
    } 
    // Separated the method due to limit error >> Manikant 
    @isTest
    public static void testchangeRequest(){
        
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        System.assert(pickupOption.Id!=null,'pickupOption Inserted');
        
        
        Account acc1  =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.Status__c = 'Active';       
        acc1.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id;
        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Website = 'www.test11.com';
        acc1.Total_Virtual_Calls__c = 3;
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        Test.startTest();
        insert acc1; 
        
        
        String temp = 'Fax';
        Map<Id,account> newItems = new Map<Id,account>();
        Map<Id,account> oldItems = new Map<Id,account>();
        newItems.put(acc1.id,acc1);
        oldItems.put(acc1.id,acc1);
        
        Field_Change_Request__c  newFieldChangeRequest = new Field_Change_Request__c();
        newFieldChangeRequest.Geography__c  = countryId;
        newFieldChangeRequest.Outlet__c = acc1.id;
        //insert newFieldChangeRequest;
        EDGE_AccountTriggerExtendedHelper.getChildFCRBody(newFieldChangeRequest, newItems, oldItems, temp);
        Test.stopTest();
        
    }
    
    @isTest
    public static void createFieldChangeRequestLookupTest(){
        User salesRep;
        List<User> users = new List<User>();
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        users.add(adminUser1);
        
        insert users;
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
       
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        
        insert marketsetting;
        System.debug(LoggingLevel.Debug,'--519--'+Limits.getQueries());
        System.assert(marketsetting.Id!=null,'Market Setting Inserted');
        Test.startTest();
        //Field permission set
        Field_Permission_Set__c fps = new Field_Permission_Set__c();
        fps.Type__c = 'Outlet';
        fps.Market_Setting__c = marketsetting.id;
        insert fps;
        
        List<Field_Permission__c> fpList=new List<Field_Permission__c>();
        //field permission
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp.Field__c = 'Local_Segment1__c';
        fp.Field_Permission_Set__c = fps.id;
        fpList.add(fp);
        
        /*
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp1.Field__c = 'Status__c';
        fp1.Field_Permission_Set__c = fps.id;
        fpList.add(fp1);

        Field_Permission__c fp2 = new Field_Permission__c();
        fp2.Related_Object__c = 'Account';
        fp2.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp2.Field__c = 'Start_Date__c';
        fp2.Field_Permission_Set__c = fps.id;
        fpList.add(fp2);
		*/
        insert fpList;
       System.debug(LoggingLevel.Debug,'--553--'+Limits.getQueries()); 
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        List <Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        //insert pickupOption;
        pickUpOptionList.add(pickupOption);
        String localSeg1pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c locaLSeg1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg1.Name = 'LocalSegA[AU]';
        locaLSeg1.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg1.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg1);
        
        Pick_Up_Options__c locaLSeg2 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg2.Name = 'LocalSegAB[AU]';
        locaLSeg2.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg2.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg2);
        insert pickUpOptionList;
        System.debug(LoggingLevel.Debug,'--578--'+Limits.getQueries()); 
        


        
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'AU_MDM', Type = 'Queue');
            insert grp;        
            QueueSobject mappingObject = new QueueSobject(QueueId = grp.Id, SobjectType = 'Field_Change_Request__c');
            insert mappingObject;
        }
        
		


        Account acc1  =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.Status__c = 'Active';       
        acc1.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
		acc1.BillingStreet ='17 Asian Highway 45';
        acc1.BillingCity =  'Tasmania';
        acc1.BillingPostalCode = '5668';
        acc1.BillingState = 'Tasmania';
        acc1.BillingPostalCode = '5668';
        acc1.BillingCountryCode = 'AU';

        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Website = 'www.test11.com';
        acc1.Total_Virtual_Calls__c = 3;
        acc1.Local_Segment1__c  = locaLSeg1.Id;
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        insert acc1; 
        
		System.debug(LoggingLevel.Debug,'--612--'+Limits.getQueries()); 

        System.runAs(adminUser){
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = adminUser1.Id;
            insert salesRep;
            System.assert(salesRep.Id!=null,'Sales Rep Inserted');
            
            //Create Business Role
            Business_Role__c br = new Business_Role__c();
            br.Name = 'Sales Rep AU';
            br.Global_Equivalent__c = 'Sales Rep';
            br.Country__c = countryId;
            br.Field_Permission_Set_Outlet__c = fps.Id;
            br.Call_Type__c = 'Measure and Sell';
            br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            insert br;
            
            //user business role 
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.Id;
            ubr.User__c = salesRep.id;
            insert ubr;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            insert geoShare;
            //Database.SaveResult sr1 = Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = br.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            insert brs;
            //Database.SaveResult sr = Database.insert(brs,false);
        }
        System.debug(LoggingLevel.Debug,'--650--'+Limits.getQueries()); 
        Test.stopTest();
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = acc1.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        System.debug(LoggingLevel.Debug,'--660--'+Limits.getQueries()); 
        System.runAs(salesRep){
            //updating outlet
            acc1.Local_Segment1__c  = locaLSeg2.Id;
            acc1.Status__c='Temporarily Closed';
            acc1.Start_Date__c=System.today().addDays(1);
            //System.debug('acc1 Country '+acc1.Country__c);
            //System.debug('salesRep Country '+salesRep.Available_Countries__c);
            try{
                update acc1; 
            } catch(Exception ex){
                System.debug(LoggingLevel.debug,'error '+ex.getCause()+ex.getLineNumber()+ex.getStackTraceString()+ex.getMessage());
            }
        }
        
    } 
    @isTest
    public static void createFieldChangeRequestParentTest(){
        User salesRep;
        List<User> users = new List<User>();
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        users.add(adminUser1);
        
        insert users;
        System.debug(LoggingLevel.Debug,'--1--'+Limits.getQueries()); 
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
       
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        
        insert marketsetting;
        System.debug(LoggingLevel.Debug,'--706--'+Limits.getQueries()); 
        System.assert(marketsetting.Id!=null,'Market Setting Inserted');
        Test.startTest();
        //Field permission set
        Field_Permission_Set__c fps = new Field_Permission_Set__c();
        fps.Type__c = 'Outlet';
        fps.Market_Setting__c = marketsetting.id;
        insert fps;
        
        List<Field_Permission__c> fpList = new List<Field_Permission__c>();
        //field permission
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Permission__c = 'Editable - MDM Approval Required';
        //fp.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp.Field__c = 'Global_Channel__c';
        fp.Field_Permission_Set__c = fps.id;
        //insert fp;
        fpList.add(fp);
        
        Field_Permission__c fp1 = new Field_Permission__c();
        fp1.Related_Object__c = 'Account';
        fp1.Permission__c = 'Editable - Manager Approval Required';
        fp1.Field__c = 'Local_Segment1__c';
        fp1.Field_Permission_Set__c = fps.id;
        fpList.add(fp1);
        insert fpList;
       System.debug(LoggingLevel.Debug,'--733--'+Limits.getQueries()); 
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        List <Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        //insert pickupOption;
        pickUpOptionList.add(pickupOption);
        String localSeg1pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
        Pick_Up_Options__c locaLSeg1 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg1.Name = 'LocalSegA[AU]';
        locaLSeg1.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg1.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg1);
        
        Pick_Up_Options__c locaLSeg2 = EDGE_UtilityTestClass.getPickUpOption(countryId,'Local-Segment1');
        locaLSeg2.Name = 'LocalSegAB[AU]';
        locaLSeg2.RecordTypeId = localSeg1pickupRecordType;
        locaLSeg2.Status__c = 'Active';
        pickUpOptionList.add(locaLSeg2);
        insert pickUpOptionList;
        
		System.debug(LoggingLevel.Debug,'--759--'+Limits.getQueries()); 

        
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'AU_MDM', Type = 'Queue');
            insert grp;        
            QueueSobject mappingObject = new QueueSobject(QueueId = grp.Id, SobjectType = 'Field_Change_Request__c');
            insert mappingObject;
        }
        



        Account acc1  =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.Status__c = 'Active';       
        acc1.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
       // acc1.primary_sales_territory__c = terr.Id;
       // acc1.Primary_Sales_Territory_Region__c = terriHier.Id;
        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Website = 'www.test11.com';
        acc1.Total_Virtual_Calls__c = 3;
        acc1.Local_Segment1__c  = locaLSeg1.Id;
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        insert acc1; 
        
	System.debug(LoggingLevel.Debug,'--786--'+Limits.getQueries()); 

        System.runAs(adminUser){
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = adminUser1.Id;
            insert salesRep;
            System.assert(salesRep.Id!=null,'Sales Rep Inserted');
            
            //Create Business Role
            Business_Role__c br = new Business_Role__c();
            br.Name = 'Sales Rep AU';
            br.Global_Equivalent__c = 'Sales Rep';
            br.Country__c = countryId;
            br.Field_Permission_Set_Outlet__c = fps.Id;
            br.Call_Type__c = 'Measure and Sell';
            br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            insert br;
            
            //user business role 
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.Id;
            ubr.User__c = salesRep.id;
            insert ubr;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            insert geoShare;
            //Database.SaveResult sr1 = Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = br.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            insert brs;
            //Database.SaveResult sr = Database.insert(brs,false);
        }
        System.debug(LoggingLevel.Debug,'--824--'+Limits.getQueries()); 
        Test.stopTest();
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = acc1.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        System.debug(LoggingLevel.Debug,'--834--'+Limits.getQueries()); 
        System.runAs(salesRep){
            //updating outlet
            acc1.Global_Channel__c = 'Route to Market';
            acc1.Global_Sub_Channel__c = 'Wholesaler';
            acc1.Global_Segment__c = 'Wholesaler';
            acc1.Global_Sub_Segment__c = 'Traditional Wholesaler';
            acc1.Local_Segment1__c  = locaLSeg2.Id;
            try{
                update acc1; 
            } catch(Exception ex){
                System.debug(LoggingLevel.debug,'error '+ex.getCause()+ex.getLineNumber()+ex.getStackTraceString()+ex.getMessage());
            }
        }
        System.debug(LoggingLevel.Debug,'--848--'+Limits.getQueries()); 
        
    } 



        @isTest
    public static void statusUpdateFCRTest(){
        User salesRep;
        List<User> users = new List<User>();
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        
        
        User adminUser1= EDGE_UtilityTestClass.runAsUser('sysadminuser1','System Administrator');
        adminUser1.Default_Country__c = 'AU';
        adminUser1.Available_Countries__c = 'AU';
        users.add(adminUser1);
        
        insert users;
        
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
       
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        
        insert marketsetting;
        
        System.assert(marketsetting.Id!=null,'Market Setting Inserted');
        Test.startTest();
        //Field permission set
        Field_Permission_Set__c fps = new Field_Permission_Set__c();
        fps.Type__c = 'Outlet';
        fps.Market_Setting__c = marketsetting.id;
        insert fps;
        
        
        //field permission
        Field_Permission__c fp = new Field_Permission__c();
        fp.Related_Object__c = 'Account';
        fp.Permission__c = 'Editable - Manager & MDM Approval Required';
        fp.Field__c = 'Status__c';
        fp.Field_Permission_Set__c = fps.id;
        insert fp;
       
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        //List <Pick_Up_Options__c> pickUpOptionList = new List<Pick_Up_Options__c>();
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
       
        
        System.runAs(adminUser1){
            Group grp = new Group(Name = 'AU_MDM', Type = 'Queue');
            insert grp;        
            QueueSobject mappingObject = new QueueSobject(QueueId = grp.Id, SobjectType = 'Field_Change_Request__c');
            insert mappingObject;
        }
        
        
        Account acc1  =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.Status__c = 'Active';       
        acc1.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        acc1.Centrally_Managed__c = false;
        acc1.Centrally_Managed_Note__c = '';
        acc1.Website = 'www.test11.com';
        acc1.Total_Virtual_Calls__c = 3;
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        insert acc1; 
        System.debug(LoggingLevel.Debug,'--932--'+Limits.getQueries()); 
        System.runAs(adminUser){
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            salesRep.ManagerId = adminUser1.Id;
            insert salesRep;
            System.assert(salesRep.Id!=null,'Sales Rep Inserted');
            System.debug(LoggingLevel.Debug,'--940--'+Limits.getQueries()); 
            //Create Business Role
            Business_Role__c br = new Business_Role__c();
            br.Name = 'Sales Rep AU';
            br.Global_Equivalent__c = 'Sales Rep';
            br.Country__c = countryId;
            br.Field_Permission_Set_Outlet__c = fps.Id;
            br.Call_Type__c = 'Measure and Sell';
            br.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
            insert br;
            System.debug(LoggingLevel.Debug,'--950--'+Limits.getQueries());
            //user business role 
            User_Business_Role__c ubr = new User_Business_Role__c();
            ubr.Business_Role__c = br.Id;
            ubr.User__c = salesRep.id;
            insert ubr;
            
            Geography__Share geoShare = new Geography__Share();
            geoShare.ParentId = countryId;
            geoShare.UserOrGroupId = salesRep.Id;
            geoShare.AccessLevel = 'Read';
            insert geoShare;
            //Database.SaveResult sr1 = Database.insert(geoShare,false);
            
            Business_Role__Share brs = new Business_Role__Share();
            brs.ParentId = br.Id;
            brs.UserOrGroupId = salesRep.Id;
            brs.AccessLevel = 'Read';
            insert brs;
            //Database.SaveResult sr = Database.insert(brs,false);
        }
        System.debug(LoggingLevel.Debug,'--969--'+Limits.getQueries());
        Test.stopTest();
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = acc1.Id;
        newAccTeamMember.UserId = salesRep.Id;
        newAccTeamMember.TeamMemberRole = 'Primary';
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        newAccTeamMember.CaseAccessLevel = 'Edit';
        insert newAccTeamMember;
        System.debug(LoggingLevel.Debug,'--979--'+Limits.getQueries()); 
        System.runAs(salesRep){
            //updating outlet
            acc1.Status__c  = 'Temporarily Closed';
            try{
                update acc1; 
            } catch(Exception ex){
                System.debug(LoggingLevel.debug,'error '+ex.getCause()+ex.getLineNumber()+ex.getStackTraceString()+ex.getMessage());
            }
        }
        System.debug(LoggingLevel.Debug,'--989--'+Limits.getQueries()); 
        
    } 
        @isTest
    public static void updatePendingForBatchTest(){
        
        List<User> users = new List<User>();
        
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        users.add(adminUser);
        insert users;
        System.debug(LoggingLevel.Debug,'--1002--'+Limits.getQueries()); 
        //Activate the trigger
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        
        Market_Setting__c marketsetting = EDGE_UtilityTestClass.getMarketSetting(countryId);
        marketsetting.Geography__c = countryId;
        marketsetting.Outlet_Closed_Status_Check__c = True;
        marketsetting.Threshold_Format__c = 'Percent';
        
        insert marketsetting;
        System.debug(LoggingLevel.Debug,'--1013--'+Limits.getQueries()); 
        System.assert(marketsetting.Id!=null,'Market Setting Inserted');
        
        
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        System.debug(LoggingLevel.Debug,'--1028--'+Limits.getQueries()); 
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        System.debug(LoggingLevel.Debug,'--1031--'+Limits.getQueries()); 
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        System.debug(LoggingLevel.Debug,'--1037--'+Limits.getQueries());
        Test.startTest();
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        insert terriHier; 
        System.debug(LoggingLevel.Debug,'--1040--'+Limits.getQueries()); 

        
        
        
        List<Territory__c> terrList=new List<Territory__c>();
        Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Region__c = terriHier.Id;
        terr.Sales_Area__c = terriHierSA.Id;
        terr.Business_Unit__c = terriHierBU.Id;
        terr.Country__c = countryId;
        terrList.add(terr);
        
		System.debug(LoggingLevel.Debug,'--1054--'+Limits.getQueries());

         Territory__c asterr= EDGE_UtilityTestClass.getTerritoryRec();
        asterr.Territory_Type__c = 'Sales';
        asterr.Region__c = terriHier.Id;
        asterr.Sales_Area__c = terriHierSA.Id;
        asterr.Business_Unit__c = terriHierBU.Id;
        asterr.Country__c = countryId;
        asterr.Status__c = 'Active';
        terrList.add(asterr);
        
		insert terrList;
        
		List<Account> accList=new List<Account>();
        Account acc1  =  EDGE_UtilityTestClass.getOutletRecord();
        acc1.RecordTypeId = OUTLETRECORDTYPEID;
        acc1.Status__c = 'Active';       
        acc1.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 
        acc1.primary_sales_territory__c = terr.Id;
        acc1.Primary_Sales_Territory_Region__c = terriHier.Id;
        acc1.Number_Of_Planned_Calls__c  = 5;


        acc1.Name = 'Test outlet 1';
     
        acc1.Local_Segment_Advanced_Analytics__c = 'Rurals';
        accList.add(acc1);
        
         Account acc2  =  EDGE_UtilityTestClass.getOutletRecord();
        acc2.RecordTypeId = OUTLETRECORDTYPEID;
        acc2.Status__c = 'Active';       
        acc2.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 

        acc2.Activation_Territory_LT__c = asterr.Id;

        acc2.Local_Segment_Advanced_Analytics__c = 'Rurals';
        acc2.Number_Of_Planned_Calls__c  = 5;
         acc2.Name = 'Test outlet 2';
        accList.add(acc2);
       
		insert accList;

		List<Outlet_Territory__c> otList=new List<Outlet_Territory__c>();
        Outlet_Territory__c outletTerr = new Outlet_Territory__c();
        outletTerr.Territory__c = terr.Id;
        outletTerr.Outlet__c = acc1.Id;
        otList.add(outletTerr);
        


         Outlet_Territory__c outletTerr1 = new Outlet_Territory__c();
        outletTerr1.Territory__c = asterr.Id;
        outletTerr1.Outlet__c = acc2.Id;
        otList.add(outletTerr1);
        
          
         insert otList;
        
        System.runAs(adminUser){
               acc2.Number_Of_Planned_Calls__c  = 6;
            
           acc1.Local_Segment_Advanced_Analytics__c = 'Workers';
            try{
                update acc1; 
                update acc2;


            } catch(Exception ex){
                System.debug(LoggingLevel.debug,'error '+ex.getCause()+ex.getLineNumber()+ex.getStackTraceString()+ex.getMessage());
            }
            
            
        }
        
        
        
        
        Test.stopTest();
    } 
	 @isTest
    public static void prospectNotifTest(){
        
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
        
        List<Account> prospectList=new List<Account>();
        Account prospectAccount1 = EDGE_UtilityTestClass.getProspectRecord(oultlVstPriPkUp.id);
        prospectAccount1.BillingStreet = 'testStreet';
        prospectAccount1.Global_Channel__c = 'off Trade';
        prospectAccount1.Global_Sub_Channel__c = 'Retailer';
        prospectAccount1.Global_Segment__c = 'Hypermarket';
        prospectAccount1.Global_Sub_Segment__c = 'Modern Hypermarket';
        prospectAccount1.Status__c = 'Active';
        prospectAccount1.BillingCity = 'Tasmania';
        prospectAccount1.BillingCountry = 'Australia';
        prospectAccount1.Status__c='Approval In Progress';
        prospectList.add(prospectAccount1);
        
        Account prospectAccount2 = EDGE_UtilityTestClass.getProspectRecord(oultlVstPriPkUp.id);
        prospectAccount2.BillingStreet = 'testStreet';
        prospectAccount2.Global_Channel__c = 'off Trade';
        prospectAccount2.Global_Sub_Channel__c = 'Retailer';
        prospectAccount2.Global_Segment__c = 'Hypermarket';
        prospectAccount2.Global_Sub_Segment__c = 'Modern Hypermarket';
        prospectAccount2.Status__c = 'Active';
        prospectAccount2.BillingCity = 'Tasmania';
        prospectAccount2.BillingCountry = 'Australia';
        prospectAccount2.Status__c='Approval In Progress';
        prospectList.add(prospectAccount2);
        
        Test.startTest();
        System.runAs(newUser1){
            insert prospectList;
            
            prospectAccount1.Status__c = 'Approved';
            prospectAccount2.Status__c = 'Rejected';
            try{
                update prospectList;
            }
            catch(Exception e){
                System.debug(LoggingLevel.debug,'Error '+e.getCause());
            }            
        }
        Test.stopTest();
    }

}