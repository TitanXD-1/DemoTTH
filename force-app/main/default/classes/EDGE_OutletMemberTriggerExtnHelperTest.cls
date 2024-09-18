/**
* @Name: EDGE_OutletMemberTriggerExtnHelperTest

* @Purpose: Test Class for EDGE_OutletMemberTriggerExtnHelper

* @History                                                            
* @VERSION       AUTHOR                 DATE              DETAIL
*  1.0	         Anand Uppalapati      03/08/2021	 	  ES20-10707
*/
@isTest
public class EDGE_OutletMemberTriggerExtnHelperTest {
    
    final static String OutletRecordTypeId = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    @isTest
    public static void accTeamMember(){
        EDGE_UtilityTestClass.createOrgSettings();
        Id CountryId = EDGE_UtilityTestClass.setupCountry('AU');
        Test.startTest();
        User salesManager = EDGE_UtilityTestClass.runAsUser('salesRep1','Sales Manager');
        salesManager.Available_Countries__c = 'AU';
        insert salesManager;  
        System.assert(salesManager.Id!=null);
        
        User salesRep = EDGE_UtilityTestClass.runAsUser('salesRep2','System Administrator');
        salesRep.Available_Countries__c = 'AU';
        salesRep.ManagerId = salesManager.id;
        salesRep.Business_Role__c = 'Test Business Role';
        insert salesRep; 
        User salesRep2 = EDGE_UtilityTestClass.runAsUser('salesRep2','System Administrator');
        salesRep2.Available_Countries__c = 'AU';
        salesRep2.ManagerId = salesManager.id;
        salesRep2.Business_Role__c = 'Test Business Role';
        insert salesRep2;
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
       
        Account outletAcc = EDGE_UtilityTestClass.getOutletRecord();
        outletAcc.Country__c=CountryId;
        outletAcc.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outletAcc;
        
        Outlet_Member__c  obj=new Outlet_Member__c();
        obj.country__c=CountryId;
        obj.outlet__c=outletAcc.id;
        obj.user__c=salesRep.id;
        obj.Outlet_Role__c='Dispense Rep';
        Insert obj;
        delete obj;
        Outlet_Member__c  obj1=new Outlet_Member__c();
        obj1.country__c=CountryId;
        obj1.outlet__c=outletAcc.id;
        obj1.user__c=salesRep.id;
        obj1.Outlet_Role__c='Dispense Rep';
        insert obj1;
        Test.stopTest();
    }
}