/**********************************************************************
Name: Edge_ExportToCaseTaskPdfControllerTest

Req: This is the test class for Edge_ExportToCaseTaskPdfController class.
User Story : ES20-11095

History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0   Sayan Samaddar     08/12/2021      Initial Development
2.0   Swaraj Samanta   		18/02/2022     	ES20-11832 (Contracter PDF Name)


***********************************************************************/
@isTest
public class Edge_ExportToCaseTaskPdfControllerTest {
    final static String outletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();  
    final static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    final static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    final static String qualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    
    @isTest
    public static void getPdfFileTest(){
        Id gegraphyid = EDGE_UtilityTestClass.setupCountryGB('GB');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(gegraphyid,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[GB]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        outlet.Name = 'Great Britain Outlet';
        outlet.BillingStreet = 'Flat 801 Middleton Court 4/2 Middleton Street';
        outlet.BillingPostalCode = '700071';
        outlet.BillingCity = 'TELFORD';
        outlet.Phone__c = '12345678987';
        outlet.Legacy_Front_Office_Account_No__c = '345689';
        insert outlet;
              
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
        
        Case caseObj = new Case();
        caseObj.Status = 'New';
        caseObj.Origin = 'EDGE 365 Global';
        caseObj.RecordTypeId = qualityRecordTypeId;
        caseObj.AccountId = outlet.Id;   
        caseObj.Case_Type__c = caseConfigType.Id;
        caseObj.Case_Sub_Type__c = caseConfigSubType.Id;
        caseObj.Case_Notes__c='Test Case Notes';
        insert caseObj;
        
        Case_Task__c caseTask = new Case_Task__c();
        caseTask.Case__c = caseObj.Id;
        caseTask.Case_Task_Type__c = caseConfig.Id;
        caseTask.Achievement_Status__c = 'Open';
        caseTask.Actioned_Within_SLA__c = false;
        caseTask.Account__c = outlet.Id;
        caseTask.Case_Task_Notes__c='Test Notes';
        //caseTask.Contractor__c=True;
        caseTask.Contractor_Name__c=qualityMgr.Id;
        caseTask.Line_Cleaning_Due_Date__c = datetime.now(); 
        insert caseTask;
        
		
        Edge_ExportToCaseTaskPdfController.getPdfFile(caseTask.Id);
        Edge_ExportToCaseTaskPdfController.getCaseTaskNumber(caseTask.Id);
        Test.stopTest();
        
    }
 }