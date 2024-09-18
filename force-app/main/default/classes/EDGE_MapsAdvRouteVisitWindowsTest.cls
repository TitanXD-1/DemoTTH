/**********************************************************************
Name: EDGE_MapsAdvRouteVisitWindowsTest
=======================================================================

History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0       Amar Deep        29/06/2020        
***********************************************************************/
@isTest
public class EDGE_MapsAdvRouteVisitWindowsTest {
    @isTest
    public static void mapsAdvRouteVisitWindowsTest(){
         Id countryId= EDGE_UtilityTestClass.setupCountry('AU');
                
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AU]';
        insert pickupOption;
        System.assert(pickupOption.Name!= Null);// Added by Divya
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        outlet.BillingStreet = '17 Asian Highway 45';
        outlet.BillingCity = 'Tasmania';
        outlet.BillingCountry = 'Australia';
        outlet.BillingState = 'Tasmania';
        outlet.BillingPostalCode = '5668';
        outlet.BillingCountryCode = 'AU';
        
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet;
        
        maps__AdvRouteVisitWindows__c mapAdv = new maps__AdvRouteVisitWindows__c();
        mapAdv.maps__VW_Account__c = outlet.id;
        mapAdv.maps__VisitWindowStrictness__c = 'Strict';
        mapAdv.maps__DaysOfWeek__c = 'Monday';
        insert mapAdv;
        update mapAdv;
        delete mapAdv;
        undelete mapAdv;
       
    }
}