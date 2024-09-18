/**
********************
* @Name: GT_AccountTriggerHelperTest
* @Created: 26 June 2023
* @Description: Test class for GT_AccountTriggerHelper
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     26/06/2023  140680 (GT-57) - Initial development
********************
*/

@isTest
public class GT_AccountTriggerHelperTest {

    @isTest
    public static void testUpdateGTFields() {

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
        
        Account operatorObj = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operatorObj.Name = 'Test Operator One';
        operatorObj.Person_Responsible__c = UserInfo.getUserId();
        operatorObj.IsOperator__c = true;
        insert operatorObj;
        
        Account altOperatorObj = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        altOperatorObj.Name = 'Test Operator Two';
        altOperatorObj.Person_Responsible__c = UserInfo.getUserId();
        altOperatorObj.IsOperator__c = true;
        insert altOperatorObj;
        
        GT_Project__c projObj = createProject(accObj);
        insert projObj;
        
        Test.startTest();
        accObj.Independent_of_Operator__c = false;
        accObj.Operator__c = operatorObj.Id;
        update accObj;
        
        Asset assetObj = createGTAsset(accObj);
        insert assetObj;
        
        accObj.Operator__c = altOperatorObj.Id;
        update accObj;
        
        projObj.GT_Phase__c = 'Completion';
        update projObj;
        
        accObj.Operator__c = operatorObj.Id;
        update accObj;
        
        System.assert(projObj.GT_Customer__c != operatorObj.Id,'Success');
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
    
    public static Asset createGTAsset(Account outletRec) {
        
        string gtAssetRecType = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Global Travel Asset').getRecordTypeId();
        
        Asset asset = new Asset();
        asset.name = 'Test Asset';
        asset.Status = 'Installed';
        asset.GT_Production_Vendor__c = 'SIGNACTION';
        asset.GT_Brand__c = 'Zacapa';
        asset.InstallDate = System.today();
        asset.GT_Type_of_Fixture__c = 'Gondola';
        asset.AccountId = outletRec.Id;
        asset.GT_SAP_Asset_Number__c = '12345';
        asset.GT_Asset_Tag_Number__c = '67890';
        asset.RecordTypeId = gtAssetRecType;
        return asset;
    }
}