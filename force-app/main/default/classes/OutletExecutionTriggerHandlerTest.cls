@isTest
public class OutletExecutionTriggerHandlerTest {
 
    public static Map <String,Schema.RecordTypeInfo> mapOutExeRecordTypes = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    // Get the record type id of from the Map based on the Name
    public static Id productRecTypeId = mapOutExeRecordTypes.get('Product').getRecordTypeId();
    public static Id activationRecTypeId = mapOutExeRecordTypes.get('Activation').getRecordTypeId();
    public static String pickupRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
    
    @isTest
	public static void testOutletExecution(){
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null);
        List<Opportunity_Template__c> oppTempList = new List<Opportunity_Template__c>();
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null);
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c ='Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null);

        
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;

        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        
        outExecObj.NPA__c = 'No';
        update outExecObj;
    }

}