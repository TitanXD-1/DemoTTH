/**
* @Name: GT_ProjectTriggerHandlerTest
* @Purpose: Test class for GT_ProjectTriggerHelper and GT_ProjectTriggerHandler
* 
* @History
* Version  Author          Date        Description
* 1.0      Tanishq     01/09/2023    140668 [GT-42] Implementation of Auto generation of Predefined Tasks when a project moves through phases
*/

@isTest
public class GT_ProjectTriggerHandlerTest {
	
    @isTest
    public static void insertGTProjectRecord()
    {
        Id hubId = EDGE_UtilityTestClass.setupHubGT('GTH');
        System.Assert(hubId!=null,'Success');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(hubId, 'Outlet Visit Prioritization');
        oultlVstPriPkUp.Name = 'Gold[GTH]';
        oultlVstPriPkUp.RecordTypeId = pickupRecordType;
        oultlVstPriPkUp.Status__c = 'Active';
        insert oultlVstPriPkUp;
        Pick_Up_Options__c localSeg1 = EDGE_UtilityTestClass.getPickUpOption(hubId,'Global Travel Local Segment 1');
        localSeg1.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Local Segment').getRecordTypeId();
		insert localSeg1;
        Pick_Up_Options__c localSeg2 = EDGE_UtilityTestClass.getPickUpOption(hubId, 'Global Travel Local Segment 2');
        localSeg2.RecordTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        insert localSeg2;
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Hub__c = hubId;
        accObj.Local_Segment1__c = localSeg1.Id;
        accObj.Local_Segment2__c = localSeg2.Id;
        insert accObj;
       
        GT_Project__c prjRecord = createProject(accObj);
        
        Test.startTest();
        insert prjRecord;
        
        prjRecord.GT_Budget__c = 100.00;
     	prjRecord.GT_Phase__c = 'Design';
        update prjRecord;
        
        Task taskObject = [SELECT id FROM Task WHERE WhatId =: prjRecord.id AND GT_Task_Phase__c = 'Briefing' LIMIT 1 ];
        if(taskObject != NULL){
        	delete taskObject;
        }
        
        prjRecord.GT_Phase__c = 'Briefing';
        update prjRecord;
     	
        delete prjRecord;
        
        undelete prjRecord;
        
        Test.stopTest();
    }
    
    public static GT_Project__c createProject(Account outletRec) {
        GT_Project__c project = new GT_Project__c();
        project.GT_Outlet__c = outletRec.Id;
        project.GT_Incremental_refresh__c = 'Incremental';
        project.GT_Brand__c = 'Zacapa';
        project.GT_Installed_Date__c = System.today();
        project.GT_Type_of_Fixture__c = 'Gondola';
        project.GT_Budget__c = 50.00;
        project.GT_Cost_Center_Organization__c = 'HL1701 (6500 Diageo Australia)';
        project.GT_Phase__c = 'Briefing';
        project.GT_Owner__c = UserInfo.getUserId();
        project.GT_Capex_Internal_Order__c = '5463';
        project.GT_AUC_Number__c = '9327';
        project.GT_SAP_Asset_Number__c = '1199';
        return project;
    }
    
}