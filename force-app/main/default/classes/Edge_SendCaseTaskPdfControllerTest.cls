/*
Class name : Edge_SendCaseTaskPdfController

Author				Version			Date				Detail
Debolina Saha       V1.0            08/12/2021          ES20-11518 - Case Task PDF Body generator
Swaraj Samanta   	V2.0			18/02/2022     		ES20-11832 - Addition of Account Unique Record Id
*/

@isTest
public class Edge_SendCaseTaskPdfControllerTest {
    final static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    final static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    final static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    @isTest
    public static void fetchCasetaskPdfTest(){
        Id gegraphyid = EDGE_UtilityTestClass.setupCountry('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(gegraphyid,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        //outlet creation
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Name = 'Great Britain Outlet';
        outlet.BillingStreet = 'Flat 701 Middleton Court 4/2 Middleton Street';
        outlet.BillingPostalCode = '700071';
        outlet.BillingCity = 'TELFORD';
        //outlet.BillingState = 'London';
        //outlet.BillingCountry = 'United Kingdom';
        outlet.Phone__c = '12345678910';
        outlet.Legacy_Front_Office_Account_No__c = '345689';
        insert outlet;
        
        
        /*Account outlet2 = EDGE_UtilityTestClass.getOutletRecord();
        outlet2.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet1.Name = 'Test Outlet 2';
        outlet1.BillingStreet = 'Street 2';
        outlet1.BillingCity = 'Scotland';
        insert outlet2; */
        
        //quality user creation
        User qualityMgr = EDGE_UtilityTestClass.runAsUser('TestQualityMgr', 'Quality Manager');
        qualityMgr.Trax_User__c = true;
        qualityMgr.Available_Countries__c = 'GB';
        qualityMgr.Contractor__c=True;
        insert qualityMgr; 
        
        Quality_Case_Configuration__c caseConfig = new Quality_Case_Configuration__c();
        caseConfig.Name = 'Test Case Configuration';
        caseConfig.Description__c = 'Test Case Configuration Record';
        caseConfig.RecordTypeId = caseTaskTypeRecTypeId;
        insert caseConfig;
        
        Quality_Case_Configuration__c caseConfigType = new Quality_Case_Configuration__c();
        caseConfigType.Name = 'No Serve Gas CO2';
        caseConfigType.Description__c = 'Test Case Type Configuration Record';
        caseConfigType.RecordTypeId = caseTypeRecTypeId;
        insert caseConfigType;
        
        Quality_Case_Configuration__c caseConfigSubType = new Quality_Case_Configuration__c();
        caseConfigSubType.Name = 'Case Sub Type';
        caseConfigSubType.Description__c = 'Test Case Sub Type Configuration Record';
        caseConfigSubType.RecordTypeId = caseTaskSubTypeRecTypeId;
        insert caseConfigSubType;
        Test.startTest();
        
        //case record creation
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj.Case_Notes__c='Test Case Notes';
        caseObj.Due_Date_Time__c = Date.newInstance(2022,2,1);
        insert caseObj;
        
        //casetask record creation
        Case_Task__c casetask = new Case_Task__c();
        casetask.Case__c = caseObj.Id;
        casetask.Case_Task_Type__c = caseConfig.Id;
        casetask.Achievement_Status__c = 'Open';
        casetask.Actioned_Within_SLA__c = false;
        casetask.Account__c = outlet.Id;
        casetask.Case_Task_Notes__c='Test Notes';
        //casetask.Contractor__c=True;
        casetask.Contractor_Name__c=qualityMgr.Id;
        casetask.Line_Cleaning_Due_Date__c = datetime.now(); 
        insert casetask;
      	
        System.debug('casetaskId : '+casetask.Id);
        
        PageReference pgref = Page.Edge_SendCaseTaskPDFVisualPage;
        Test.setCurrentPage(pgref);
        
        ApexPages.currentPage().getParameters().put('taskId',casetask.id);
        Edge_SendCaseTaskPdfController sc = new Edge_SendCaseTaskPdfController();
        system.assert(sc.caseTaskId != null);
        
		test.stopTest();   
    }

}