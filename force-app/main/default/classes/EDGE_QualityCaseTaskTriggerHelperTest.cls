/**
* @Description: EDGE_QualityCaseTaskTriggerHelperTest
* @Purpose : Test Class for EDGE_QualityCaseTaskTriggerHelper
* @History:
* @Version     Developer		     Date			   Story/Purpose
*  1.1		   Saurav Paul			 29/09/2021		   ES20-10803(Temporarily Assigned Logic)	
*  1.2		   Aparajita			 23/11/2021        ES20-11513(Method:testBulkCTAssignmentPushNotif)
*/

@isTest
public class EDGE_QualityCaseTaskTriggerHelperTest {
    final static String OUTLETRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String CASETASKTYPERECTYPEID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String CASETYPERECTYPEID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    final static String CASETASKSUBTYPERECTYPEID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    final static String QUALITYRECORDTYPEID = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String ASSETQUALITYRECORDTYPEID = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    /**
    * @description : Creating test data
	* @return : WrapData
	* @param : void
	*/
    public static WrapData createData(){
        //Create Geography
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB'); 
        //Create Pickup Option
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        insert pickupOption;
        //Create Outlet
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c = pickupOption.Id; 
        outletAccount.Name = 'Test Outlet';
        outletAccount.BillingStreet = 'Street xyz';
        outletAccount.BillingCity = 'London';
        outletAccount.Person_Responsible__c = UserInfo.getUserId();
        insert outletAccount;
        //Create Business Role
        Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj.Country__c = countryId;
        //businessRoleObj.Global_Equivalent__c = 'Dispense Manager';
        insert businessRoleObj;
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = CASETASKTYPERECTYPEID;
        insert caseConfig;

        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = CASETYPERECTYPEID;
        insert caseConfigType;

        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = CASETASKSUBTYPERECTYPEID;
        insert caseConfigSubType;
                
        //Create Case
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = QUALITYRECORDTYPEID;
        caseObj.AccountId = outletAccount.Id;
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;
        
        WrapData wrapObj = new WrapData();
        wrapObj.countryId = countryId;
        wrapObj.caseId = caseObj.Id;
        wrapObj.businessRole = businessRoleObj.Id;
        wrapObj.outletId = outletAccount.Id;
        wrapObj.caseConfig = caseConfig.Id;
        System.debug(LoggingLevel.Debug,'@M1'+Limits.getQueries());

        return wrapObj;
    }
    
    /**
    * @description : Test coverage for Create Case_Task
	* @return : void
	* @param : void
	*/
    @isTest
    public static void createAccessTest1(){
        User qualityMamagerUser = EDGE_UtilityTestClass.runAsUser('TestActivationSpecialist', 'Quality Manager');
        qualityMamagerUser.Trax_User__c = true;
        qualityMamagerUser.Available_Countries__c = 'GB';
        insert qualityMamagerUser; 
        system.assert(qualityMamagerUser.Id != null,'qualityMamagerUser should not be null');
        User qualityMamagerUser1 = EDGE_UtilityTestClass.runAsUser('TestActivationSpecialist', 'Quality Manager');
        qualityMamagerUser1.Trax_User__c = true;
        qualityMamagerUser1.Available_Countries__c = 'GB';
        insert qualityMamagerUser1; 
        
		WrapData wrapObj = createData();        
        Outlet_Member__c omTest = EDGE_UtilityTestClass.getOutletMemberRecord(wrapObj.outletId, qualityMamagerUser.id, 'Primary');
        insert omTest;
        Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj.Country__c = wrapObj.countryId;
        //businessRoleObj.Global_Equivalent__c = 'Dispense Manager';
        insert businessRoleObj;
        User_Business_Role__c userBusinessObj = EDGE_UtilityTestClass.getuserBusinessRole(qualityMamagerUser, businessRoleObj);
        insert userBusinessObj;

        User_Business_Role__c userBusinessObj1 = EDGE_UtilityTestClass.getuserBusinessRole(qualityMamagerUser1, businessRoleObj);
        insert userBusinessObj1;
        
        EDGE_UtilityTestClass.createOrgSettings();
       	Case_Task__c ct = new Case_Task__c();
        ct.Case__c = wrapObj.caseId;
        ct.Account__c = wrapObj.outletId;
        ct.User_Assigned_To__c = qualityMamagerUser.Id;
        ct.Case_Task_Type__c = wrapObj.caseConfig;
        ct.Achievement_Status__c = 'Open';

        Test.startTest();
        
        insert ct;
        ct.User_Assigned_To__c = qualityMamagerUser1.Id;
        update ct;
        
        Test.stopTest();
        
        //List<Outlet_Member__c> outMemList = [SELECT Id FROM Outlet_Member__c WHERE User__c =:qualityMamagerUser.Id];
        System.debug(LoggingLevel.Debug,'@M3'+Limits.getQueries());

       // System.assertEquals(1, outMemList.size());
    }
    
    /**
    * @description : Test coverage for update Case_Task
	* @return : void
	* @param : void
	*/
    @isTest
    public static void deleteAccessTest(){
        User qualityMamagerUser = EDGE_UtilityTestClass.runAsUser('TestActivationSpecialist', 'Quality Manager');
        qualityMamagerUser.Trax_User__c = true;
        qualityMamagerUser.Available_Countries__c = 'GB';
        insert qualityMamagerUser; 
        system.assert(qualityMamagerUser.Id != null,'qualityMamagerUser should not be null');
        User qualityMamagerUser1 = EDGE_UtilityTestClass.runAsUser('TestActivationSpecialist', 'Quality Manager');
        qualityMamagerUser1.Trax_User__c = true;
        qualityMamagerUser1.Available_Countries__c = 'GB';
        insert qualityMamagerUser1; 
		WrapData wrapObj = createData();        
        
        Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj.Country__c = wrapObj.countryId;
        insert businessRoleObj;
        User_Business_Role__c userBusinessObj = EDGE_UtilityTestClass.getuserBusinessRole(qualityMamagerUser, businessRoleObj);
        insert userBusinessObj;
        
        User_Business_Role__c userBusinessObj1 = EDGE_UtilityTestClass.getuserBusinessRole(qualityMamagerUser1, businessRoleObj);
        insert userBusinessObj1;
        
        EDGE_UtilityTestClass.createOrgSettings();
       	Case_Task__c ct = new Case_Task__c();
        ct.Case__c = wrapObj.caseId;
        ct.Account__c = wrapObj.outletId;
        ct.User_Assigned_To__c = qualityMamagerUser.Id;
        ct.Achievement_Status__c = 'Open';
        ct.Case_Task_Type__c = wrapObj.caseConfig;
        insert ct;
        
        Test.startTest();
        
        ct.Achievement_Status__c = 'Achieved';
        ct.User_Assigned_To__c = qualityMamagerUser1.Id;
        update ct;
        
        Test.stopTest();
        
        //List<Outlet_Member__c> outMemList = [SELECT Id FROM Outlet_Member__c WHERE User__c =:qualityMamagerUser1.Id];
        AccountTeamMember newAccTeamMember = new AccountTeamMember();
        newAccTeamMember.AccountId = wrapObj.outletId;
        newAccTeamMember.UserId = qualityMamagerUser.Id;
        newAccTeamMember.AccountAccessLevel = 'Edit';
        newAccTeamMember.OpportunityAccessLevel = 'Edit';
        newAccTeamMember.ContactAccessLevel = 'Edit';
        insert newAccTeamMember;
        List<AccountTeamMember> listAccTeamMem = new List<AccountTeamMember>();
        listAccTeamMem.add(newAccTeamMember);
        
        EDGE_OutletMemberExtnUtility.deleteAccTeam(listAccTeamMem);
        System.debug(LoggingLevel.Debug,'@M4'+Limits.getQueries());

    }
    
    /**
    * @description : Wrapper Class
	*/
    public class WrapData{
        String countryId;
        String caseId;
        String businessRole;
        String outletId;
        String caseConfig;
    }
       
    @isTest
    public static void testBulkCTAssignmentPushNotif(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'pickupOption should not be null');
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        insert outlet1;
        
        Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 2';
        outlet1.BillingStreet = 'Street 2';
        outlet1.BillingCity = 'Scotland';
        insert outlet2;
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration Record';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = CASETASKTYPERECTYPEID;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration1';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = CASETYPERECTYPEID;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration1';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = CASETASKSUBTYPERECTYPEID;
        insert caseConfigSubType;
        
        User qualityMgr = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr.Trax_User__c = true;
        qualityMgr.Available_Countries__c = 'GB';
        insert qualityMgr; 
        
        User qualityMgr1 = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr1.Trax_User__c = true;
        qualityMgr1.Available_Countries__c = 'GB';
        insert qualityMgr1; 
        
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = QUALITYRECORDTYPEID;
        caseObj.AccountId = outlet1.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;
        
        Test.startTest();
                
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.User_Assigned_To__c = qualityMgr.Id;
        ctList.add(ct1);
        
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj.Id;
        ct2.Case_Task_Type__c = caseConfig.Id;
        ct2.Achievement_Status__c = 'Open';
        ct2.Actioned_Within_SLA__c = true;
        ct2.Account__c = outlet1.Id;
        ct2.User_Assigned_To__c = qualityMgr.Id;
        ctList.add(ct2);
        
        Case_Task__c ct3 = new Case_Task__c();
        ct3.Case__c = caseObj.Id;
        ct3.Case_Task_Type__c = caseConfig.Id;
        ct3.Achievement_Status__c = 'Open';
        ct3.Actioned_Within_SLA__c = false;
        ct3.Account__c = outlet1.Id;
        ct3.User_Assigned_To__c = qualityMgr.Id;
        ctList.add(ct3);
        
        Case_Task__c ct4 = new Case_Task__c();
        ct4.Case__c = caseObj.Id;
        ct4.Case_Task_Type__c = caseConfig.Id;
        ct4.Achievement_Status__c = 'Not Achieved';
        ct4.Actioned_Within_SLA__c = true;
        ct4.Account__c = outlet1.Id;
        ct4.User_Assigned_To__c = qualityMgr.Id;
        ctList.add(ct4);
        
        Case_Task__c ct5 = new Case_Task__c();
        ct5.Case__c = caseObj.Id;
        ct5.Case_Task_Type__c = caseConfig.Id;
        ct5.Achievement_Status__c = 'Open';
        ct5.Actioned_Within_SLA__c = false;
        ct5.Account__c = outlet1.Id;
        ct5.User_Assigned_To__c = qualityMgr1.Id;
        ctList.add(ct5);
        
        Case_Task__c ct6 = new Case_Task__c();
        ct6.Case__c = caseObj.Id;
        ct6.Case_Task_Type__c = caseConfig.Id;
        ct6.Achievement_Status__c = 'Cancelled';
        ct6.Actioned_Within_SLA__c = false;
        ct6.Account__c = outlet1.Id;
        ct6.User_Assigned_To__c = qualityMgr.Id;

        ctList.add(ct6);
        
        Database.insert(ctList);
        
        Test.stopTest();
    }
    

@isTest
    public static void testAssetUpdate(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'pickupOption should not be null');
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        insert outlet1;
        
        
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test';
        masterAsst.GUID__c = 'TWRFSHJAKSVGG';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = geographyId;
        masterAsst.Priority_Assets__c = TRUE;
        masterAsst.Active__c = TRUE;
        insert masterAsst;
        EDGE_UtilityClass.printGovLimits(363);
        Master_Bundle__c mBundObj = new Master_Bundle__c();
        mBundObj.Country__c = geographyId;
        mBundObj.Name = 'Asset Creation Bundle';
        mBundObj.Active__c = true;
        insert mBundObj;
        
        Master_Asset_Master_Bundle__c masmbun = new Master_Asset_Master_Bundle__c();
        masmbun.Master_Asset__c = masterAsst.id;
        masmbun.Master_Bundle__c = mBundObj.id;
        insert masmbun;
        
        Bundle__c bundleObj = new Bundle__c();
        bundleObj.Name = 'Bundle';
        bundleObj.Account__c = outlet1.Id;
        bundleObj.Master_Bundle__c = mBundObj.id;
        bundleObj.Description__c = 'Created to test asset insert';
        Insert bundleObj;
        
        Asset asst = new Asset();
        asst.Name = 'Test_Asset';
        asst.GUID__c = 'TWRFSHJAKSVGG';
        asst.AccountId = outlet1.Id;
        asst.Country__c = geographyId;
        asst.Quantity = 1;
        asst.Master_Asset__c = masterAsst.Id;
        asst.InstallDate = null;
        asst.Asset_Removed__c = false;
        asst.RecordTypeId = ASSETQUALITYRECORDTYPEID;
        Insert asst;
        

        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Clean Lines';
        caseConfig.Description__c = 'Clean Lines';
        caseConfig.RecordTypeId = CASETASKTYPERECTYPEID;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration1';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = CASETYPERECTYPEID;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration1';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = CASETASKSUBTYPERECTYPEID;
        insert caseConfigSubType;
        
        User qualityMgr = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr.Trax_User__c = true;
        qualityMgr.Available_Countries__c = 'GB';
        insert qualityMgr; 
        
        User qualityMgr1 = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr1.Trax_User__c = true;
        qualityMgr1.Available_Countries__c = 'GB';
        insert qualityMgr1; 
        Test.startTest();
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = QUALITYRECORDTYPEID;
        caseObj.AccountId = outlet1.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;
                        
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        List<Case_Task__c> updateCTList = new List<Case_Task__c>();
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.User_Assigned_To__c = qualityMgr.Id;
        ct1.Line_Cleaning_Asset__c = asst.Id;
        ctList.add(ct1);
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj.Id;
        ct2.Case_Task_Type__c = caseConfig.Id;
        ct2.Achievement_Status__c = 'Open';
        ct2.Actioned_Within_SLA__c = true;
        ct2.Account__c = outlet1.Id;
        ct2.User_Assigned_To__c = qualityMgr.Id;
        ct2.Line_Cleaning_Asset__c = asst.Id;
        ctList.add(ct2);
        Database.insert(ctList);
        /*ct1.Achievement_Status__c = 'Open';
        updateCTList.add(ct1);
        ct2.Achievement_Status__c = 'Achieved';
        updateCTList.add(ct2);
        Database.update(updateCTList);
        ct1.Achievement_Status__c = 'Open';
        update ct1;*/
		Test.stopTest();
        
    }
    @isTest
    public static void testCaseTaskUpdate(){
        Id geographyId = EDGE_UtilityTestClass.setupCountryGB('GB');

        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickupOption.Id != null,'pickupOption should not be null');
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        insert outlet1;
        
        
        Master_Asset__c masterAsst = new Master_Asset__C();
        masterAsst.Name = 'Test';
        masterAsst.GUID__c = 'TWRFSHJAKSVGG';
        masterAsst.Short_Description__c = 'test';
        masterAsst.Country__c = geographyId;
        masterAsst.Priority_Assets__c = TRUE;
        masterAsst.Active__c = TRUE;
        insert masterAsst;
        EDGE_UtilityClass.printGovLimits(363);
        Test.startTest();
        Asset asst = new Asset();
        asst.Name = 'Test_Asset';
        asst.GUID__c = 'TWRFSHJAKSVGG';
        asst.AccountId = outlet1.Id;
        asst.Country__c = geographyId;
        asst.Quantity = 1;
        asst.Master_Asset__c = masterAsst.Id;
        asst.InstallDate = null;
        asst.Asset_Removed__c = false;
        asst.RecordTypeId = ASSETQUALITYRECORDTYPEID;
        Insert asst;
        

        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Clean Lines';
        caseConfig.Description__c = 'Clean Lines';
        caseConfig.RecordTypeId = CASETASKTYPERECTYPEID;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration1';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = CASETYPERECTYPEID;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration1';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = CASETASKSUBTYPERECTYPEID;
        insert caseConfigSubType;
        
        User qualityMgr = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr.Trax_User__c = true;
        qualityMgr.Available_Countries__c = 'GB';
        insert qualityMgr; 
        

        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = QUALITYRECORDTYPEID;
        caseObj.AccountId = outlet1.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;
                        
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        List<Case_Task__c> updateCTList = new List<Case_Task__c>();
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.User_Assigned_To__c = qualityMgr.Id;
        ct1.Line_Cleaning_Asset__c = asst.Id;
        ctList.add(ct1);
        Case_Task__c ct2 = new Case_Task__c();
        ct2.Case__c = caseObj.Id;
        ct2.Case_Task_Type__c = caseConfig.Id;
        ct2.Achievement_Status__c = 'Open';
        ct2.Actioned_Within_SLA__c = true;
        ct2.Account__c = outlet1.Id;
        ct2.User_Assigned_To__c = qualityMgr.Id;
        ct2.Line_Cleaning_Asset__c = asst.Id;
        ctList.add(ct2);
        EDGE_UtilityTestClass.createOrgSettings();
        Database.insert(ctList);

        ct1.Achievement_Status__c = 'Open';
        updateCTList.add(ct1);
        ct2.Achievement_Status__c = 'Achieved';
        updateCTList.add(ct2);
        Database.update(updateCTList);
		Test.stopTest();
        
    }
}