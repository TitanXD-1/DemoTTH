/**********************************************************************
Name: EDGE_TerritoryCycleTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Sagar Barman  29/05/2019     Test Class for EDGE_TerritoryCycleTriggerHelper

***********************************************************************/
@isTest
public class EDGE_TerritoryCycleTriggerHelperTest {
    
    
    @isTest
    Public static void testCheckTerritoryCycleInsert(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId != null);
        EDGE_UtilityTestClass.createOrgSettings();
        
        Map <String,Schema.RecordTypeInfo> mapPickupoptionRecordTypes = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id defRecTypeId = mapPickupoptionRecordTypes.get('Default Pickup').getRecordTypeId();        

        
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Territory Cycle');
        pickupOption.Name = 'Gold[AU]';
        pickupOption.Type__c = 'Reporting Unit';
        pickupOption.RecordTypeId = defRecTypeId;
        insert pickupOption;
        System.assert(pickupOption.Id != null);
        
        Market_Cycle__c marc = EDGE_UtilityTestClass.getMarketCycle(countryId) ;
        insert marc;
        
        Territory__c terr = EDGE_UtilityTestClass.getTerritoryRec();
        terr.Territory_Type__c = 'Service';
        insert terr;
        
        Territory_Cycle__c tercyc = new Territory_Cycle__c();
        tercyc.Market_Cycle__c = marc.id;
        tercyc.Territory__c = terr.Id;
        
        Test.startTest();        
        insert tercyc;
        System.assert(tercyc.Id != null);
        tercyc.Market_Cycle__c = marc.id;
        update tercyc; 
        delete tercyc ;
        undelete tercyc;
        Test.stopTest();
        
    }
}