/**********************************************************************
Name: EDGE_MapsLocationTriggerTest
=======================================================================
Purpose: Test Class for Maps Location Trigger
=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE              DETAIL
1.0         Sandip Ghosh     06-Mar-2019        Initial Development   
***********************************************************************/ 
@isTest
public with sharing class EDGE_MapsLocationTriggerTest {
    
    
    @isTest
    public static void validateUserLatLongPopulate(){
        User adminUser= EDGE_UtilityTestClass.runAsUser('sysadminuser','System Administrator');
        adminUser.Default_Country__c = 'AU';
        adminUser.Available_Countries__c = 'AU';
        insert adminUser;
        
        //Id countryId  = EDGE_UtilityTestClass.setupCountry('AU');
        EDGE_UtilityTestClass.createOrgSettings();
        User salesRep;
        System.runAs(adminUser){
            //Creating Sales Rep 
            salesRep= EDGE_UtilityTestClass.runAsUser('salesRep2','Sales Representative');
            salesRep.Available_Countries__c = 'AU';
            insert salesRep;
            System.assert(salesRep.Id!=null,'sales Rep Id should not be null');    
        }
        
        Test.startTest(); 
        system.runAs(salesRep){
            maps__Location__c mpsLocation = EDGE_UtilityTestClass.getMapLocation(salesRep);
            insert mpsLocation;  
            
            mpsLocation.maps__Description__c = 'test';
            update mpsLocation;
            
            delete mpsLocation;
            Test.stopTest();
            
            System.assert(mpsLocation.Id!=null,'mps Location Id should not be null');
            
            
        }
    }
}