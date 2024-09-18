/**********************************************************************
Name: EDGE_MarketSettingTriggerHelperTest
=======================================================================
Test class for EDGE_MarketSettingTriggerHelper, MarketSettingTriggerHandler & MarketSettingTrigger
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0       Aniket Sen       14/07/2020      Initial Development
2.0       Joshraj Sen      08/04/2024      152305 SCA Fix

***********************************************************************/

@isTest
public class EDGE_MarketSettingTriggerHelperTest 
{
    @isTest
	public static void test1()
    {
        //Creating test records for mandatory lookup fields
        
        //Test Geography records
        Map<String,Schema.RecordTypeInfo> geoRtMapByDevName  = Schema.SObjectType.Geography__c.getRecordTypeInfosByDeveloperName();
        Id globalRecordType = geoRtMapByDevName.get('Global').getRecordTypeId();
        Geography__c globalGeo = new Geography__c(RecordTypeId=globalRecordType,Name='Global',Code__c='GL');
        insert globalGeo;
        Id marketRecordType = geoRtMapByDevName.get('Market').getRecordTypeId();
        Geography__c market = new Geography__c(RecordTypeId=marketRecordType,Name='Test',Code__c='TS',ECM_SAP_Plant_for_Payment_File__c='x',Parent_Geography__c=globalGeo.Id);
        insert market;
        System.assert(globalGeo.Id!=null,'Added Geography');// Added by Divya
        
        //Test Pickup Option - Default Outlet Visit Prioritization record
        Map<String,Schema.RecordTypeInfo> pickUpRtMapByDevName = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByDeveloperName();
        Id outletPrioritizationRt = pickUpRtMapByDevName.get('Outlet_Prioritization').getRecordTypeId();
        Pick_Up_Options__c outPrior = new Pick_Up_Options__c(RecordTypeId=outletPrioritizationRt,Name='TEST [TS]',Geography__c=market.Id,Type__c='Outlet Visit Prioritization',Status__c='Active');
        insert outPrior;
        
        //Insert Test Market Setting record
        Market_Setting__c ms = new Market_Setting__c(Name='Test Market Setting',Language__c='en_US',Geography__c=market.Id,Default_Outlet_Visit_Prioritisation__c=outPrior.Id,POS_Time_Based_Allocation__c=true);
        insert ms;
        system.debug(LoggingLevel.Debug,'After Insert: '+ms);
        Market_Setting__c ms1 = [Select Id, Name, Language__c from Market_Setting__c LIMIT 1];
        //Update the test record
        ms1.Name='Test Marketing Setting 2';
        ms1.Language__c = 'es';
        
        Id allocationRecordType = Schema.SObjectType.Geography__c.getRecordTypeInfosByName().get('Country').getRecordTypeId();
        Geography__c globalGeoRec = new Geography__c(RecordTypeId=allocationRecordType,Name='Great Britain',Code__c='GB');
        insert globalGeoRec;
        Stock__c stockRec = new Stock__c();
        stockRec.Allocated__c =2;
        stockRec.Consumed_Stock__c=1;
        stockRec.RecordTypeId = Schema.SObjectType.Stock__c.getRecordTypeInfosByName().get('Allocation').getRecordTypeId();
        stockRec.Country__c=globalGeoRec.Id;
        insert stockRec;
        try{
        Market_Setting__c msetting = new Market_Setting__c(Name='GB Market Setting',Language__c='en_US',Geography__c=globalGeoRec.Id,Default_Outlet_Visit_Prioritisation__c=outPrior.Id, POS_Time_Based_Allocation__c=true);
        insert msetting;
        }
        catch(Exception e) {
            System.assert(e.getMessage().contains(System.Label.D1_POS_Order_Limit_Error_Msg),'Message Matched');
        }

        Test.startTest();
        update ms1;
        system.debug(LoggingLevel.Debug,'After Update: '+ms1);
        delete ms1;
        Test.stopTest();  
    }
   
  
}