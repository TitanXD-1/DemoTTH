/**
* @Name: EDGE_OutletTerritoryTriggerHelperTest

* @Req: This is the test class for the  EDGE_OutletTerritoryTriggerHelper class. 
     It also covers OutletTerritoryTriggerHandler class.
     User Story : ES20-257

* @History                                                            
                                                            
* @VERSION   AUTHOR            DATE              DETAIL
*  1.0       Sagar Barman     28/02/2019      Initial Development
*  1.1       Saurav Paul      11th-Mar-2019   Validate Country Test Added
*  1.2       Anand Uppalapati 14-02-2022 
**/
@isTest
public class EDGE_OutletTerritoryTriggerHelperTest {
    @isTest
    public static void testOutletAssgnmentInTerritory(){
            Boolean validationError = false;        
            EDGE_UtilityTestClass.createOrgSettings();
                    
            // create Geography record  
            Id countryID = EDGE_UtilityTestClass.setupCountry('AUT');              
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
            insert pickupOption; 
            //create outlet record             
            Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
            outletAccount.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
            insert outletAccount;
        
            //Start the test
            Test.startTest();
            //create custom Territory record
            Territory__c salesTerritory = new Territory__c();
            salesTerritory.Territory_Type__c = 'Service';
            salesTerritory.Country__c = countryID;
            insert salesTerritory;
            
            Territory__c salesTerritory2 = new Territory__c();
            salesTerritory2.Territory_Type__c = 'Service';
            salesTerritory2.Country__c = countryID;
            insert salesTerritory2;
            
            Territory__c dbaTerritory = new Territory__c();
            dbaTerritory.Territory_Type__c = 'DBA';
            dbaTerritory.Country__c = countryID;
            insert dbaTerritory; 
            
            //createOutletTerritory
            Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
            outletTerritory.Territory__c = salesTerritory.id;
            outletTerritory.Outlet__c = outletAccount.id;
            insert outletTerritory; 
            
            //check the validation : one outlet can not be assigned to two Sales Territory
            try{
                Outlet_Territory__c outletTerritory2 = new Outlet_Territory__c();
                outletTerritory2.Territory__c = salesTerritory2.id;
                outletTerritory2.Outlet__c = outletAccount.id;
                insert outletTerritory2;      
            }catch(Exception ex){
                validationError = true;     
            }
            System.assertEquals(TRUE, validationError);            
            //to cover OutletTerritoryTriggerHandler
            update outletTerritory;
            delete outletTerritory;
            
            Test.stopTest();
    }
    /*@isTest
    public static void checkValidateCountry(){
            Test.startTest();
            //Create Org Setting
            EDGE_UtilityTestClass.createOrgSettings(); 
            Id countryID = EDGE_UtilityTestClass.setupCountry('AUT');              
            Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryID,'Outlet Visit Prioritization');
            insert pickupOption; 
            //Create Territory
            Territory__c terrObj = EDGE_UtilityTestClass.getTerritoryRec();
        	terrObj.Territory_Type__c = 'Service';
            insert terrObj;
            System.assert(terrObj.Id != null);
            
            //Create Account Record
            Account accObj = EDGE_UtilityTestClass.getOutletRecord();
            accObj.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            insert accObj;
            System.assert(accObj.Id != null);
            
            
            //Create Outlet Territory
            Outlet_Territory__c outTerrObj = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id,terrObj.Id);
            insert outTerrObj;
            System.assert(outTerrObj.Id != null); 
            Test.stopTest();
    }*/  
}