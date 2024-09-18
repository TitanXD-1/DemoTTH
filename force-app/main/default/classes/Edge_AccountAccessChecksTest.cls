/**

* @Description: Edge_AccountAccessChecksTest

* @Purpose: test Class for Edge_AccountAccessChecksForTask

* @VERSION     AUTHOR          DATE            DETAIL

*   1.1       Sudipta     25/01/2022         ES20-13681
*   1.2       Joshraj     08/04/2024         152305

*/ 

@isTest
public class Edge_AccountAccessChecksTest {
     static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
     static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
     static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
     static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
     static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
     static String assetqualityRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    /**
    * @description : Creating test data
	* @return : WrapData
	* @param : void
	*/
    public static WrapData createTestData(){
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
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        insert caseConfig;

        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        insert caseConfigType;

        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        insert caseConfigSubType;
                
        //Create Case
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityRecordTypeId;
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
    public static void checkAccessTest(){
        User qualityMamagerUser = EDGE_UtilityTestClass.runAsUser('TestNewQEUser', 'Quality Manager');
        qualityMamagerUser.Trax_User__c = true;
        qualityMamagerUser.Available_Countries__c = 'GB';
        insert qualityMamagerUser; 
        
        User qualityMamagerUser1 = EDGE_UtilityTestClass.runAsUser('TestNewQ1EUser', 'Quality Manager');
        qualityMamagerUser1.Trax_User__c = true;
        qualityMamagerUser1.Available_Countries__c = 'GB';
        insert qualityMamagerUser1; 
        
		WrapData wrapObj = createTestData();        
       
        Business_Role__c businessRoleObj = EDGE_UtilityTestClass.getBusinessRole();
        businessRoleObj.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;WPA__c;OPPS OPEN;OPPS CLOSED';
        businessRoleObj.Country__c = wrapObj.countryId;
        insert businessRoleObj;
        User_Business_Role__c userBusinessObj = EDGE_UtilityTestClass.getuserBusinessRole(qualityMamagerUser, businessRoleObj);
        insert userBusinessObj;

        User_Business_Role__c userBusinessObj1 = EDGE_UtilityTestClass.getuserBusinessRole(qualityMamagerUser1, businessRoleObj);
        insert userBusinessObj1;
        
       
        Test.startTest();
        List<Case_Task__c> caseTaskLists = new List<Case_Task__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
       	Case_Task__c ct = new Case_Task__c();
        ct.Case__c = wrapObj.caseId;
        ct.Account__c = wrapObj.outletId;
        ct.User_Assigned_To__c = qualityMamagerUser1.Id;
        ct.Case_Task_Type__c = wrapObj.caseConfig;
        ct.Achievement_Status__c = 'Open';
		caseTaskLists.add(ct);
        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = wrapObj.caseId;
        ct1.Account__c = wrapObj.outletId;
        ct1.User_Assigned_To__c = qualityMamagerUser.Id;
        ct1.Case_Task_Type__c = wrapObj.caseConfig;
        ct1.Achievement_Status__c = 'Open';
		caseTaskLists.add(ct1);
        Database.insert(caseTaskLists);
        
        List<Outlet_Member__c> outMemList = [SELECT Id FROM Outlet_Member__c WHERE User__c =:qualityMamagerUser1.Id];
        if(outMemList != null && outMemList.size()>0){
           Database.delete(outMemList);
        }
        
        
        List<AccountTeamMember> accTeamMember = [SELECT Id FROM AccountTeamMember WHERE UserId =:qualityMamagerUser.Id];
         if(accTeamMember != null && accTeamMember.size()>0){
             Database.delete(accTeamMember);
        }
        
        Test.stopTest();
 		Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'Edge_AccountAccessChecksForTask' AND Country_Code__c ='GB'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch is Added');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));        

        System.debug(LoggingLevel.Debug,'@@@'+Limits.getQueries());

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
     
}