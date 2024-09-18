/**********************************************************************
  Name: EDGE_OutletExHistoricTriggerHelperTest
=======================================================================
  Purpose: Test Class for EDGE_OutletExHistoricTriggerHelper
=======================================================================
    History                                                            
    -------                                                            
    VERSION    AUTHOR                   DATE              DETAIL
     1.0       Manikant Prasad       12/06/2019        Initial Development 
***********************************************************************/
@isTest
public class EDGE_OutletExHistoricTriggerHelperTest {
    
    @isTest
    public static void updateVolumeOnContractTest(){
        Map <String,Schema.RecordTypeInfo> mapContractRecordTypes = Contract.sObjectType.getDescribe().getRecordTypeInfosByName();
        Id contractRecTypeId = mapContractRecordTypes.get('A&P').getRecordTypeId();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        
        Test.startTest();
        Account acc1 = EDGE_UtilityTestClass.getOutletRecord();
        acc1.Outlet_Visit_Prioritisation_Grade__c = pickupOption.id;
        acc1.Last_Update_TRAX__c=system.today();
        insert acc1;
        
        Contract contrct = EDGE_UtilityTestClass.getContract(acc1.Id, contractRecTypeId);
        insert contrct;
        
        Outlet_Contract__c oCC = new Outlet_Contract__c();
        oCC.Contract__c = contrct.Id;
        oCC.Outlet__c = acc1.id;
        insert oCC;
        System.assert(oCC.Id != null);
        
        
        Outlet_Execution_Historic__c oEH = new Outlet_Execution_Historic__c();
        oEH.Name = 'Test_Historic';
        oEH.RecordTypeId = Outlet_Execution_Historic__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Contract Volume').getRecordTypeId();
        oEH.Outlet__c = acc1.id;
        oEH.Contract__c=contrct.Id;
        oEH.Volume_UoS__c=125.51;
        oEH.Date_of_Execution__c=System.today()+4;
        insert oEH;
        System.assert(oEH.Id != null);
        
        update oEH;
        delete oEH;
        undelete oEH;
        
        Test.stopTest();
        
    }
}