/**
* @Description: ECM_AccountTriggerPersonRespHelperTest
* @Purpose: 
* @History:                                                            
* @VERSION    AUTHOR               			DATE           		DETAIL
*	1.0       Tanishq and Anshu       		07/03/2022      	ECM-5275
*/
@isTest
public class ECM_AccountTriggerPersonRespHelperTest {
	/*
    @Description: Test method of updateSalesAreaAndTerritory
	@Param : NewItems, OldItemMap
	*/
    @isTest
    public static void updateSalesAreaAndTerritoryTest(){
        
        Org_Setting__c orgSetting = new Org_Setting__c();
        orgSetting.Run_Triggers__c = true;
        insert orgSetting;
        system.assert(orgSetting.Id != null,'orgSetting id should not be null');
        
        Id terrRecId = Schema.SObjectType.Territory__c.getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
        
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        
        Territory_Hierarchy__c region2 = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Business Unit');
        insert region2;
        
        
        Territory_Hierarchy__c region1 = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Sales Area');
        region1.Parent_BU__c = region2.Id;
        insert region1;
        
        Territory_Hierarchy__c region = EDGE_UtilityTestClass.getTerritoryHierarchy(geographyId,'Region');
        region.Parent_BU__c = region1.Id;
        insert region;
        
        Pick_Up_Options__c pOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pOption.Name='LI[ES]';
        insert pOption;
       
        Test.startTest();
        User usr1 = ECM_UtilityTestClass.createUser('usr1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        usr1.Username = 'salesRepUser11234@test.com';
        insert usr1;
        
        User usr2 = ECM_UtilityTestClass.createUser('usr2',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        usr2.Username = 'salesRepUser211234@test.com';
        insert usr2;
        
        Territory__c terr1 = EDGE_UtilityTestClass.getTerritoryRec();
        terr1.RecordTypeId = terrRecId;
        terr1.Primary_Sales_Rep__c = usr2.Id;
        terr1.Region__c = region.Id;
        terr1.Business_Unit__c = region2.Id;
        terr1.Sales_Area__c = region1.Id;
        terr1.Territory_Type__c = 'Sales';
        terr1.Status__c = 'Active';
        insert terr1;
        
        Account opAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        opAccount.Person_Responsible__c = usr2.Id;
        opAccount.country__c = geographyId;
        opAccount.IsOperator__c = true;
        opAccount.IsOwner__c = false;
        insert opAccount;
              
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.RecordTypeId = terrRecId;
        terr.Primary_Sales_Rep__c = usr1.Id;
        terr.Region__c = region.Id;
        terr.Business_Unit__c = region2.Id;
        terr.Sales_Area__c  = region1.Id;
        terr.Territory_Type__c = 'Sales';
        terr.Status__c = 'Active';
        insert terr;
        
        opAccount.Person_Responsible__c = usr1.Id;
        update opAccount;
        //opAccount.Person_Responsible__c = '';
        //update opAccount;
        Test.stopTest();
    }
}