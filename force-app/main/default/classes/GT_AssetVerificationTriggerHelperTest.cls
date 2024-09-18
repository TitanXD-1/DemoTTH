/**
* @Name: GT_AssetVerificationTriggerHelperTest
* @Purpose: Test class for GT_AssetVerificationTriggerHandler and GT_AssetVerificationTriggerHelper
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     26/07/2023  140748 : [GT-134] Asset Verification Automations
*/
@isTest
public class GT_AssetVerificationTriggerHelperTest {
    
    @isTest
    public static void testAssetVerf() {
        
        Id hubId = EDGE_UtilityTestClass.setupHubGT('GTH');
        System.Assert(hubId != null, 'Success');
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
        
        Asset assetObj = createGTAsset(accObj);
        insert assetObj;
        
        GT_Asset_Verification__c verfRec1 = createVerification(assetObj.Id, Date.newInstance(2023, 7, 12));
        insert verfRec1;
        
        verfRec1.GT_Asset_TAG_Number__c = '73927';
        update verfRec1;
        
        delete verfRec1;
    }
    
    public static GT_Asset_Verification__c createVerification(Id asstName, Date verfDt) {
        GT_Asset_Verification__c verfRec = new GT_Asset_Verification__c();
        verfRec.GT_Asset_Name__c = asstName;
        verfRec.GT_Verification_Date__c = verfDt;
        verfRec.GT_Asset_Removal_Date__c = System.today();
        verfRec.GT_Asset_TAG_Changed__c = true;
        verfRec.GT_Asset_TAG_Number__c = '2745';
        
        return verfRec;
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