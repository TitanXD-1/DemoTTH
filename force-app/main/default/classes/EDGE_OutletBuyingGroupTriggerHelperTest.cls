/**********************************************************************
Name: EDGE_OutletBuyingGroupTriggerHelperTest
=======================================================================
Req: 
ES20-4584 
=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE           DETAIL
1.0     Shahbaz Khan     08/07/2020        
***********************************************************************/
@isTest
public class EDGE_OutletBuyingGroupTriggerHelperTest {
    @isTest
    public static void outletBuyingGroupTest(){
        Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c	pickUpOption= EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickUpOption.Name = 'Gold[AU]';
        insert pickUpOption;
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.Outlet_Visit_Prioritisation_Grade__c = pickUpOption.Id;
        insert outlet;
        Buying_Group__c buyingGroup = new Buying_Group__c(Name='New Buying Group',Country__c=countryId,Status__c='Active');
        insert buyingGroup;
        system.assert(buyingGroup.Id!=null);
        
        Outlet_Buying_Group__c outBuyGroup = new Outlet_Buying_Group__c();
        outBuyGroup.Outlet__c = outlet.Id;
        outBuyGroup.Buying_Group__c = buyingGroup.id;
        outBuyGroup.Status__c = 'Inactive';
        insert outBuyGroup;
        
        outBuyGroup.Status__c = 'Active';
        update outBuyGroup;
        
        delete outBuyGroup;
        
        undelete outBuyGroup;
        
        
    }
    
   

}