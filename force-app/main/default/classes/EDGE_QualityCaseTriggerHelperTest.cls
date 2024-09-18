/**

* @Description: EDGE_QualityCaseTriggerHelperTest

* @Purpose : Test Class for EDGE_CaseMilestoneUtils and EDGE_Quality_CaseTriggerHelper

* @History:

* @Version     Developer		  Date			    Story/Purpose

*    1.0       Aparajita		17/09/2021		   ES20-11127(Method:testSendPushNotification)                
*	 1.1	   Prasanth T	    14/10/2021		   ES20-10893(Push Notification)

*	 1.2	   Anamika   	    07/04/2022		   ES20-12361(restrictCaseStatusUpdateTest)
*    1.3       Joshraj          17/01/2023         ES20-13734(Increase Coverage)




*/
@isTest
public class EDGE_QualityCaseTriggerHelperTest 
{
    
    static String qualityCaseRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    static String entitlementProcessName ='Quality Entitlement Process[IE&NIR] - Set1 24/7';
    static String entitlementProcessNameGB = 'Quality Entitlement Process[GB] - Set2 24/5';
    static String qualityConfigName='X - CS 1 Hr SLA';
    static String caseTaskTypeRecordId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    static String caseSubTypeRecordId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    static String qualityCaseConfigRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();     
    
    @isTest
    public static void testSendPushNotification()
    {
        //Set<Id> accountIds = new Set<Id>();
        //Set<Id> allowedAtmIds = new Set<Id>();
        //String allowedRoles = System.label.EDGE_RolesForQualityPushNotification;
        String allowedCountries = System.label.EDGE_CountriesForQualityPushNotification;
        //List<String> listOfRoles = allowedRoles.split(';');
        List<String> listOfCountries = allowedCountries.split(';');
        listOfCountries.add('GB');
        //List<String> usersToNotifyList = new List<String>();
        //Map<Id,List<Id>> accIdVsUserIdMap = new Map<Id,List<Id>>();
        
        
        Id countryId = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold[GB]';
        pickOp.RecordTypeId = pickupRecordType;
        pickOp.Status__c = 'Active';
        insert pickOp;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Country__c=countryId;
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickOp.Id;
        insert outlet;
        
        List<User> usersList=new List<User>();
        
        User newUser1 = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        usersList.add(newUser1);
        //insert newUser1;
        User newUser2 = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        usersList.add(newUser2);
        insert usersList;
        
        Map<Id,List<Id>> accIdVsUserIdMapTest = new Map<Id,List<Id>>();
        List<AccountTeamMember> accTeammembersList=new List<AccountTeamMember>();
        List<Id> accountIdList = new List<Id>();
        AccountTeamMember atm1 = new AccountTeamMember();
        atm1.AccountId = outlet.Id;
        atm1.UserId = newUser1.Id;
        atm1.TeamMemberRole = 'Service Rep/Quality Executive';
        atm1.AccountAccessLevel = 'Edit';
        atm1.OpportunityAccessLevel = 'Edit';
        atm1.ContactAccessLevel = 'Edit';
        insert atm1;
        accTeammembersList.add(atm1);
        accountIdList.add(atm1.UserId);
        accIdVsUserIdMapTest.put(atm1.id,accountIdList);
        
        AccountTeamMember atm2 = new AccountTeamMember();
        atm2.AccountId = outlet.Id;
        atm2.UserId = newUser2.Id;
        atm2.TeamMemberRole = 'RQM Ireland';
        atm2.AccountAccessLevel = 'Edit';
        atm2.OpportunityAccessLevel = 'Edit';
        atm2.ContactAccessLevel = 'Edit';
        insert atm2;
        accTeammembersList.add(atm2);
        insert accTeammembersList;
        accountIdList.add(atm2.UserId);
        accIdVsUserIdMapTest.put(atm2.id,accountIdList);
        Test.startTest();
        
        Quality_Case_Configuration__c caseType = new Quality_Case_Configuration__c();
        caseType.Name ='Test Case Type';
        caseType.RecordTypeId = qualityCaseConfigRecTypeId;
        caseType.Active__c= True;
        caseType.Country__c = countryId;
        insert caseType;
        
        Quality_Case_Configuration__c caseSubType = new Quality_Case_Configuration__c();
        caseSubType.Name ='Test Case Sub Type';
        caseSubType.RecordTypeId = caseSubTypeRecordId;
        caseSubType.Active__c= True;
        caseSubType.Case_Type__c=caseType.Id;
        caseSubType.Country__c = countryId;
        insert caseSubType;
        
        List<Case> casesToUpdate= new List<Case>();
        Case tCase = new Case();
        tCase.RecordTypeId = qualityCaseRecordTypeId;
        tCase.Origin = 'EDGE365';
        tCase.Status = 'Open';
        tCase.Due_Date_Time__c = DateTime.now();
        tCase.AccountId = outlet.Id;
        
        tCase.Case_Type__c= caseType.Id;
        tCase.Case_Sub_Type__c= caseSubType.Id;
        insert tcase;
        tCase.Status = 'On Hold';
        casesToUpdate.add(tCase);
        Set<Id> idCases=new Set<Id>();
        idCases.add(tCase.Id);
        EDGE_QualityCaseMilestoneUtils.sendPushNotification(casesToUpdate);
        System.enqueueJob(new EDGE_QualityCaseMilestoneUtils(idCases));
        Test.stopTest();
        AccountTeamMember atm = [SELECT Id, UserId, TeamMemberRole, AccountId FROM AccountTeamMember WHERE Id =: atm1.Id];
        System.assertEquals(atm1.Id, atm.Id,'Matches Equally');
    }
    
    
    
    
    @isTest
    public static void testpushNotificationMethodforCase()
    {
        
        User newUser = EDGE_UtilityTestClass.runAsUser('TestUser', 'Quality Manager');
        
        insert newUser;
        System.assert(newUser.Id!=null,'User Added');
        List<Id> userList = new List<Id>();
        userList.add(newUser.Id);
        Map<String,Object> custom = new Map<String,Object>();
        String msgBody = 'Test Message';
        custom.put('User ID', newUser.Id); 
        EDGE_QualityCaseTriggerHelper.pushNotificationMethodforCase(userList, msgBody, custom);
    }
    
    @isTest
    public static void populateSLAMetForCaseTest()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User newUser1 = EDGE_UtilityTestClass.runAsUser('TestUser1', 'Quality Manager');
        insert newUser1;
        System.assert(newUser1.Id!=null,'User Added');
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold[AUT]';
        insert pickOp;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickOp.Id;
        insert outlet;
        
        Map<Id,Case> newItems = new Map<id,Case>();
        Map<Id,Case> oldItems = new Map<id,Case>();
        
        Quality_Case_Configuration__c qualityConfig = new Quality_Case_Configuration__c();
        qualityConfig.Name = qualityConfigName;
        qualityConfig.Active__c = True;
        qualityConfig.Country__c = countryId;
        qualityConfig.RecordTypeId = qualityCaseConfigRecTypeId;
        insert qualityConfig;
        
        List<SLAProcess> entitlementProcess = [Select Id,Name from SLAProcess Where Name =: entitlementProcessName];
        
        Entitlement entitle = new Entitlement();
        
        entitle.name=entitlementProcessName;
        
        entitle.accountId = outlet.Id;
        for(SLAProcess eIdSLA : entitlementProcess){
            entitle.SlaProcessId = eIdSLA.id;
        }
        
        
        entitle.StartDate = system.today();
        entitle.EndDate = system.today().addDays(365);
        insert entitle;
        
        List<SLAProcess> entitlementProcessGBList = [Select Id,Name from SLAProcess Where Name =:entitlementProcessNameGB];
        Entitlement entitle1 = new Entitlement();
        entitle1.name=entitlementProcessNameGB;
        entitle1.accountId = outlet.Id;
        for(SLAProcess eIdSLA : entitlementProcessGBList){
            entitle1.SlaProcessId = eIdSLA.id;
        }
        entitle1.StartDate = system.today();
        entitle1.EndDate = system.today().addDays(365);
        insert entitle1;
        
        test.startTest();
        
        Quality_Case_Configuration__c caseType = new Quality_Case_Configuration__c();
        caseType.Name ='Test Case Type';
        caseType.RecordTypeId = qualityCaseConfigRecTypeId;
        caseType.Active__c= True;
        caseType.Country__c = countryId;
        insert caseType;
        
        Quality_Case_Configuration__c caseSubType = new Quality_Case_Configuration__c();
        caseSubType.Name ='Test Case Sub Type';
        caseSubType.RecordTypeId = caseSubTypeRecordId;
        caseSubType.Active__c= True;
        caseSubType.Case_Type__c=caseType.Id;
        caseSubType.Country__c = countryId;
        insert caseSubType;
        
        Quality_Case_Configuration__c caseTaskType = new Quality_Case_Configuration__c();
        caseTaskType.Name ='Test Case Task Type';
        caseTaskType.RecordTypeId = caseTaskTypeRecordId;
        caseTaskType.Active__c= True;
        caseTaskType.Case_Type__c=caseType.Id;
        caseTaskType.Case_Sub_Type__c=caseSubType.Id;
        caseTaskType.Country__c = countryId;
        insert caseTaskType;
        
        
        
        Case newCase = new Case();
        newCase.RecordTypeId = qualityCaseRecordTypeId;
        newCase.Status= 'Open';
        newCase.Case_SLA_Met__c = False;
        newCase.Manual_SLA_Extension__c = false;
        newCase.Case_Type__c = qualityConfig.Id;
        newCase.Due_Date_Time__c = system.now().addhours(1);
        newCase.EntitlementId= entitle.Id;
        newCase.AccountId = outlet.Id;
        newCase.Case_Type__c = caseType.Id;
        newCase.Case_Sub_Type__c = caseSubType.Id;
        
        insert newCase;
        oldItems.put(newCase.id, newCase);
        
        Case_Task__c newcaseTask = new Case_Task__c();
        
        newcaseTask.User_Assigned_To__c = newUser1.Id;
        newcaseTask.Case_Task_Type__c= caseTaskType.Id;
        
        newcaseTask.Actioned_Within_SLA__c = False;
        newcaseTask.Achievement_Status__c = 'Achieved';
        newcaseTask.Case__c = newCase.id;
        newcaseTask.Account__c = outlet.id;
        insert newcaseTask;
        //test.startTest();
        newCase.Status = 'Closed';
        //newCase.Case_SLA_Met__c = True;
        update newCase;
        newItems.put(newCase.id,newCase);
        EDGE_QualityCaseTriggerHelper.populateSLAMetForCase(newItems,oldItems);
        test.stopTest();
    }
    
    @isTest
    public static void pauseMilestoneTest()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        EDGE_UtilityTestClass.createOrgSettings();
        
        User newUser2 = EDGE_UtilityTestClass.runAsUser('TestUser2', 'Quality Manager');
        insert newUser2;
        System.assert(newUser2.Id!=null,'User Added');
        Pick_Up_Options__c pickOp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        pickOp.Name = 'Gold[AUT]';
        insert pickOp;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickOp.Id;
        insert outlet;
        
        //Map<Id,Case> newItems = new Map<id,Case>();
        Map<Id,Case> oldItems = new Map<id,Case>();
        test.startTest();
        Quality_Case_Configuration__c qualityConfig1 = new Quality_Case_Configuration__c();
        qualityConfig1.Name = 'X - CS 1 Hr SLA';
        qualityConfig1.Active__c = True;
        qualityConfig1.Country__c = countryId;
        qualityConfig1.RecordTypeId = qualityCaseConfigRecTypeId;
        insert qualityConfig1;
        
        Quality_Case_Configuration__c caseType = new Quality_Case_Configuration__c();
        caseType.Name ='Test Case Type';
        caseType.RecordTypeId = qualityCaseConfigRecTypeId;
        caseType.Active__c= True;
        caseType.Country__c = countryId;
        insert caseType;
        
        Quality_Case_Configuration__c caseSubType = new Quality_Case_Configuration__c();
        caseSubType.Name ='Test Case Sub Type';
        caseSubType.RecordTypeId = caseSubTypeRecordId;
        caseSubType.Active__c= True;
        caseSubType.Case_Type__c=caseType.Id;
        caseSubType.Country__c = countryId;
        insert caseSubType;
        
        Quality_Case_Configuration__c caseTaskType = new Quality_Case_Configuration__c();
        caseTaskType.Name ='Test Case Task Type';
        caseTaskType.RecordTypeId = caseTaskTypeRecordId;
        caseTaskType.Active__c= True;
        caseTaskType.Case_Type__c=caseType.Id;
        caseTaskType.Case_Sub_Type__c=caseSubType.Id;
        caseTaskType.Country__c = countryId;
        insert caseTaskType;
        
        Case newCase1 = new Case();
        newCase1.RecordTypeId = qualityCaseRecordTypeId;
        newCase1.Status= 'Open';
        
        newCase1.IsStopped = False;
        newCase1.Case_Type__c = qualityConfig1.Id;
        newCase1.AccountId = outlet.id;
        newCase1.Manual_SLA_Extension__c = false;
        newCase1.Case_Type__c=caseType.Id;
        newCase1.Case_Sub_Type__c=caseSubType.Id;
        newCase1.Due_Date_Time__c = system.now().addhours(1);
        insert newCase1;
        oldItems.put(newCase1.id, newCase1);
        
        Case_Task__c newcaseTask1 = new Case_Task__c();
        //newcaseTask1.Actioned_Within_SLA__c = False;
        newcaseTask1.Achievement_Status__c = 'Achieved';
        newcaseTask1.User_Assigned_To__c = newUser2.Id;
        newcaseTask1.Case__c = newCase1.id;
        newcaseTask1.Case_Task_Type__c= caseTaskType.Id;
        newcaseTask1.Account__c = outlet.id;
        
        insert newcaseTask1;
        
       // newCase1.Status = 'On Hold';
       // newCase1.IsStopped = True;
       // update newCase1;
        test.stopTest();
        //newItems.put(newCase1.id,newCase1);
        //EDGE_QualityCaseTriggerHelper.pauseMilestone(newItems,oldItems);        
    }
    

    @isTest
    public static void restrictCaseStatusUpdateTest(){
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB');
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet1 = EDGE_UtilityTestClass.getOutletRecord();
        outlet1.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 1';
        outlet1.BillingStreet = 'Street 1';
        outlet1.BillingCity = 'London';
        insert outlet1;
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration1';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecordId;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'Test Case Type Configuration1';
        caseConfigType.Description__c = 'Test Case Configuration Record';
        caseConfigType.RecordTypeId = qualityCaseConfigRecTypeId;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Test Case Sub Task Configuration1';
        caseConfigSubType.Description__c = 'Test Case Configuration Record';
        caseConfigSubType.RecordTypeId = caseSubTypeRecordId;
        
        List<Quality_Case_Configuration__c> qccList = new List<Quality_Case_Configuration__c>();
        qccList.add(caseConfig);
        qccList.add(caseConfigType);
        qccList.add(caseConfigSubType);
        insert qccList;
        
        User qualityRep1 = EDGE_UtilityTestClass.runAsUser('TestQualityRep1', 'Quality Representative');
        qualityRep1.Available_Countries__c = 'GB';
        insert qualityRep1;
        System.assert(qualityRep1.Id!=null,'User Added');
        Test.startTest();
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityCaseRecordTypeId;
        caseObj.AccountId = outlet1.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        insert caseObj;
        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = caseObj.Id;
        ct1.Case_Task_Type__c = caseConfig.Id;
        ct1.Achievement_Status__c = 'Open';
        ct1.Actioned_Within_SLA__c = false;
        ct1.Account__c = outlet1.Id;
        ct1.User_Assigned_To__c = qualityRep1.Id;
        insert ct1;  
        
        System.runAs(qualityRep1) {
            try{
                caseObj.Status = 'Closed';
                update caseObj;
            }catch(Exception e){
                System.debug(LoggingLevel.Debug,'@Exception:'+e.getMessage()); 
                String message=e.getMessage();
                System.assert(message.contains(System.label.EDGE_CaseWithOpenCTCannotBeClosed),'Values Matched');
            }
        }
        Test.stopTest();
    }

}