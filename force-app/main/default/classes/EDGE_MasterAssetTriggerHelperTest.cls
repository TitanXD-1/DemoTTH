/**

* @description :  EDGE_MasterAssetTriggerHelperTest

* @purpose : Test Class for EDGE_MasterAssetTriggerHelper

* @history :

* Version   Developer         Date         User Story/Purpose

*  1.1     Dinesh Sharma     02/08/2021     Initial Development
*  1.2     Joshraj Sen       12/11/2021     ES20-11439 



*/

@isTest
public class EDGE_MasterAssetTriggerHelperTest {
    
    @isTest
    public static void testMasterAssetSharing(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Master_Asset__c masObj = new Master_Asset__C();
        masObj.Name = 'Test';
        masObj.Part_Number__c = '123CHSGT';
        masObj.Priority_Assets__c = True;
        masObj.GUID__c = 'TWRFSHJAKSVGG';
        masObj.Short_Description__c = 'short description';
        masObj.Country__c = countryId;
        insert masObj;

        Master_Asset__c masObj1 = new Master_Asset__C();
        masObj1.Name = 'Test1';
        masObj1.Part_Number__c = '123CHSGL';
        masObj1.Priority_Assets__c = False;
        masObj1.GUID__c = 'TWRFSHJAKSVGH';
        masObj1.Short_Description__c = 'short description1';
        masObj1.Country__c = countryId;
        insert masObj1;

        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'AU Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;

        masObj1.Country__c = secCountry.Id;
        masObj1.Priority_Assets__c = True;
  		Test.startTest();
        update masObj1;
        delete masObj1;
        undelete masObj1;
        Test.stopTest();   
    }
    
    @isTest
    public static void testPendingForBatchActive()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        String qualityRecordTypeId=Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
        EDGE_UtilityTestClass.createOrgSettings(); 
        
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        terriHierBU.Pending_For_Batch__c=false;
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        terriHierSA.Pending_For_Batch__c=false;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Pending_For_Batch__c=false;
        insert terriHier;
        
        Territory__c  territory1 = EDGE_UtilityTestClass.getTerritoryRec();
        territory1.Current_OES_Rank__c= 12.0;
        territory1.Country__c = countryId;
        territory1.Current_OES_Score__c = 10.0;
        territory1.Current_OES_Rank__c = 11.0;
        territory1.Territory_Type__c = 'Sales';
        territory1.Sales_Area__c = terriHierSA.Id; 
        territory1.Region__c = terriHier.Id;
        territory1.Status__c = 'Active';     
        insert territory1;
        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
        insert pickupOption; 
        
        //create outlet record             
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outletAccount;
        
        Outlet_Territory__c outletTerritory1 = new Outlet_Territory__c();
        outletTerritory1.Territory__c = territory1.id;
        outletTerritory1.Outlet__c = outletAccount.id;
        insert outletTerritory1;
         
        Master_Asset__c masObj = new Master_Asset__C();
        masObj.Name = 'Test';
        masObj.Active__c=true;
        masObj.Part_Number__c = '123CHSGT';
        masObj.Priority_Assets__c = True;
        masObj.GUID__c = 'TWRFSHJAKSVGG';
        masObj.Short_Description__c = 'short description';
        masObj.Country__c = countryId;
        insert masObj;
        
        Master_Asset__c masObj1 = new Master_Asset__C();
        masObj1.Name = 'Test1';
        masObj1.Active__c=true;
        masObj1.Part_Number__c = '123CHSGL';
        masObj1.Priority_Assets__c = False;
        masObj1.GUID__c = 'TWRFSHJAKSVGH';
        masObj1.Short_Description__c = 'short description1';
        masObj1.Country__c = countryId;
        insert masObj1; 
        
        Test.startTest();
            Asset asset=new Asset();
            asset.AccountId=outletAccount.Id;
            asset.Master_Asset__c=masObj1.Id;
            asset.Quantity=1;
            asset.Name='Test Asset';
            asset.RecordTypeId=qualityRecordTypeId;
            insert asset;
            
            masObj1.Priority_Assets__c = True;
            update masObj1;
        Test.stopTest();   
    }
}