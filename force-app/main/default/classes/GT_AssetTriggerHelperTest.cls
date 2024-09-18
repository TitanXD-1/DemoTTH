/*

* @Name: GT_AssetTriggerHelperTest
* @Created: 8 August 2023
* @Description: Test class for GT_AssetTriggerHelper
* 
* @History
* Version  Author          Date        Description
* 1.0      Wribhu Bose     08/08/2023  GT-143681 :  Last TRAX Outbound data Updated Date field logic in Global Travel Asset

*/

@isTest
public class GT_AssetTriggerHelperTest {

    @isTest
    public static void createAsset(){
        
        Id hubId = EDGE_UtilityTestClass.setupHubGT('GTH');
        System.Assert(hubId!=null,'Success');
        EDGE_UtilityTestClass.createOrgSettings();
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        String gtAssetRecType = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Global Travel Asset').getRecordTypeId();
        
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
        
        Asset newAst = new Asset();
        newAst.Name = 'TestAsset1';
        newAst.GT_Production_Vendor__c= 'SIGNACTION';
        newAst.Status = 'Installed';
        newAst.GT_Brand__c='Zacapa';
        newAst.InstallDate = System.today();
        newAst.GT_Toolkit__c = 'F22_Z2_Clouds';
        newAst.GT_Type_of_Fixture__c= 'Wallbay';
        newAst.GT_Retail_Format__c = 'Freestanding Store';
        newAst.AccountId= accObj.ID;
        newAst.GT_SAP_Asset_Number__c = '1657903';
        newAst.GT_Asset_Tag_Number__c = '16734590';
        newAst.RecordTypeId = gtAssetRecType;
        
        test.startTest();
        insert newAst;
        
        AssetTriggerHandler.isFirstTime = true;
        newAst.GT_SAP_Asset_Number__c = '78953245';
        update newAst;
        
        delete newAst;
        
        test.stopTest();
    }	
}