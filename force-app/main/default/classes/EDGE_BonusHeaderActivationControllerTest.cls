/**********************************************************************
Name: EDGE_BonusHeaderActivationControllerTest
=======================================================================
Req: 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0		 Sagar Barman 		10/01/2020		 ES20-4583(Activate Bonus header record)
***********************************************************************/
@isTest
public class EDGE_BonusHeaderActivationControllerTest {
    @isTest
    public static void testValidateBonusHeader(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId != null,'country Id should not be null');
        
        //Insert Market_Cycle__c
        Market_Cycle__c marketCycle = new Market_Cycle__c();
        marketCycle.Name = 'AusMarket';
        marketCycle.Start_Date__c = Date.today();
        marketCycle.End_Date__c = Date.today().addMonths(3);
        marketCycle.Geography__c = countryId;
        insert marketCycle;
        
        //Insert Bonus_Header__c
        Bonus_Header__c bonusHeader = new Bonus_Header__c();
        bonusHeader.Country__c = countryId;
        bonusHeader.Status__c = 'Draft';
        insert bonusHeader;
        
        //Insert Bonus_Cycle__c
        Bonus_Cycle__c bonusCycle1 = new Bonus_Cycle__c();
        bonusCycle1.Bonus_Header__c = bonusHeader.Id;
        bonusCycle1.Market_Cycle__c = marketCycle.Id;
        insert bonusCycle1;
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
        
        //Insert Pick_Up_Options__c
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Survey KPI');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        //Insert Bonus_Detail__c
        String bonusDetailRecordType;
        bonusDetailRecordType = Bonus_Detail__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Survey').getRecordTypeId();
        Bonus_Detail__c bonusDetail = new Bonus_Detail__c();
        bonusDetail.Bonus_Header__c = bonusHeader.Id;
        bonusDetail.KPI_Type__c = 'Survey';
        bonusDetail.Survey_KPI__c = pickupOption.Id;
        bonusDetail.Weight__c = 20;
        insert bonusDetail;
        
        //Insert Territory_Hierarchy__c
        Territory_Hierarchy__c terriHierBU = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Business Unit');
        insert terriHierBU;
        
        Territory_Hierarchy__c terriHierSA = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Sales Area');
        terriHierSA.Parent_BU__c = terriHierBU.Id;
        insert terriHierSA;
        
        Territory_Hierarchy__c terriHier = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, 'Region');
        terriHier.Parent_BU__c = terriHierSA.Id;
        terriHier.Pending_For_Batch__c = false;
        insert terriHier;
        
        //Insert Territory__c
        Territory__c terr= EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Sales';
        terr.Region__c = terriHier.Id;
        terr.Country__c = countryId;
        terr.Pending_For_Batch__c = false;
        insert terr;
        
        //Insert Bonus_Assignment__c
        String bonusAssginmentRecorType = Bonus_Assignment__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Bonus Header').getRecordTypeId();
        Bonus_Assignment__c bonusAssginment = new Bonus_Assignment__c();
        bonusAssginment.Bonus_Header__c = bonusHeader.Id;
        bonusAssginment.Territory__c = terr.Id;
        bonusAssginment.RecordTypeId=bonusAssginmentRecorType;
        bonusAssginment.Global_Percentage__c = 10;
        bonusAssginment.Territory_Percentage__c = 55;
        bonusAssginment.Total__c = 65;
        insert bonusAssginment;
        
        EDGE_BonusHeaderActivationController.validateBonusHeader(bonusHeader.Id);
        bonusAssginment.Global_Percentage__c =  Null;
        bonusAssginment.Total__c = 55;
        update bonusAssginment;
        EDGE_BonusHeaderActivationController.validateBonusHeader(bonusHeader.Id);
        
        bonusAssginment.Global_Percentage__c = 60;
        bonusAssginment.Territory_Percentage__c = Null;
        bonusAssginment.Total__c = 60;
        update bonusAssginment;
        EDGE_BonusHeaderActivationController.validateBonusHeader(bonusHeader.Id);
        
        bonusAssginment.Territory_Percentage__c = 40;
        bonusAssginment.Total__c = 100;
        update bonusAssginment;
        EDGE_BonusHeaderActivationController.validateBonusHeader(bonusHeader.Id);
        
        Bonus_Header__c bonusHeader1 = new Bonus_Header__c();
        bonusHeader1.Country__c = countryId;
        bonusHeader1.Status__c = 'Draft';
        insert bonusHeader1;
        EDGE_BonusHeaderActivationController.validateBonusHeader(bonusHeader1.Id);
        
        Bonus_Header__c bonusHeader2 = new Bonus_Header__c();
        bonusHeader2.Country__c = countryId;
        bonusHeader2.Status__c = 'Active';
        insert bonusHeader2;
        EDGE_BonusHeaderActivationController.validateBonusHeader(bonusHeader2.Id);
        
    }
    
    
}