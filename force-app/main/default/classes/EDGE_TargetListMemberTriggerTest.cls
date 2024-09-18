/**********************************************************************
Name: EDGE_TargetListMemberTriggerTest
=======================================================================
Req: This is the test class for the  TargetListMemberTrigger trigger
                                     EDGE_TargetListMemberTriggerHelper
                                     TargetListMemberTriggerHandler. 

=======================================================================
History                                                            
-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.1       Saurav Paul       11th-Mar-2019     Validate Country Test Added

***********************************************************************/
@isTest
public with sharing class EDGE_TargetListMemberTriggerTest {
    @isTest
    public static void checkValidateCountry(){
        
        //Create Org Setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUS');
        System.assert(countryId != null);
        
        Pick_Up_Options__c oultlVstPri = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPri.Name = 'Gold[AUS]';
        insert oultlVstPri;
        System.assert(oultlVstPri.Id != null);
    
        //Creating Account Record
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPri.Id;
        
        Test.startTest();
        insert accObj;
        System.assert(accObj.Id != null);
        
        //Create Global 
        Geography__c globalRec = [SELECT Id FROM Geography__c WHERE recordType.Name = 'Global' LIMIT 1];
        System.assert(globalRec != null);
        
        //Create Market 
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'EMEA';
        market.Code__c = 'EME';
        market.Parent_Geography__c = globalRec.Id;
        insert market;
        //Create Hub
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Hub France';
        hub.Code__c = 'FRA';
        hub.Parent_Geography__c = market.Id;
        insert hub;
        //Create Cluster
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Cluster France';
        cluster.Code__c = 'FR';
        cluster.Parent_Geography__c = hub.Id;
        insert cluster;
        //Create Country
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'France';
        country.Code__c = 'FRC';
        country.Parent_Geography__c = cluster.Id;
        insert country;
        
        //Create Target List Record
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(country.Id);
        trgtLstObj.Country__c = country.Id;
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null);
        
        //Creating Target List Member record
        Target_List_Member__c trgtlstMbrObj = EDGE_UtilityTestClass.getTargetMemList(accObj.Id,trgtLstObj.Id);
        
        try{
            insert trgtlstMbrObj;
        }catch(Exception ex){
            //Checking Country Validation Rule
            System.Assert(ex.getMessage().contains(Label.Country_Mismatch_Issue_TargetList));
        }
        System.assertEquals(trgtlstMbrObj.Id, null,'Insert Operation Failed');
        Test.stopTest();
      
    }
    @isTest
    public static void checkValidateCountryUpdate(){
        
        //Create Org Setting
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
        System.assert(countryId != null);
        
        Pick_Up_Options__c oultlVstPri = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        oultlVstPri.Name = 'Gold[AU]';
        insert oultlVstPri;
        System.assert(oultlVstPri.Id != null);
        
        //Creating Account Record
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPri.Id;
        Test.startTest();
        insert accObj;
        System.assert(accObj.Id != null);
        
        //Create Target List Record
        Target_List__c trgtLstObjAus = EDGE_UtilityTestClass.getTargetList(countryId);
        insert trgtLstObjAus;
        System.assert(trgtLstObjAus.Id != null);
        
        //Create Global 
        Geography__c globalRec = [SELECT Id FROM Geography__c WHERE recordType.Name = 'Global' LIMIT 1];
        System.assert(globalRec != null);
        
        //Create Market 
        Geography__c market = EDGE_UtilityTestClass.createGeography('Market');
        market.Name = 'EMEA';
        market.Code__c = 'EME';
        market.Parent_Geography__c = globalRec.Id;
        insert market;
        //Create Hub
        Geography__c hub = EDGE_UtilityTestClass.createGeography('Hub');
        hub.Name = 'Hub France';
        hub.Code__c = 'FRA';
        hub.Parent_Geography__c = market.Id;
        insert hub;
        //Create Cluster
        Geography__c cluster = EDGE_UtilityTestClass.createGeography('Cluster');
        cluster.Name = 'Cluster France';
        cluster.Code__c = 'FR';
        cluster.Parent_Geography__c = hub.Id;
        insert cluster;
        //Create Country
        Geography__c country = EDGE_UtilityTestClass.createGeography('Country');
        country.Name = 'France';
        country.Code__c = 'FRC';
        country.Parent_Geography__c = cluster.Id;
        insert country;
        
        //Create Target List Record
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(country.Id);
        trgtLstObj.Name = 'Target List 3';
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null);

        //Creating Target List Member record
        Target_List_Member__c trgtlstMbrObj = EDGE_UtilityTestClass.getTargetMemList(accObj.Id,trgtLstObjAus.Id);
        insert trgtlstMbrObj;
        trgtlstMbrObj.Target_List__c = trgtLstObj.Id;
        
        try{
            update trgtlstMbrObj;
        }catch(Exception ex){
            //Checking Country Validation Rule
            System.Assert(ex.getMessage().contains(Label.Country_Mismatch_Issue_TargetList));
        }
        
        delete [SELECT Id FROM Target_List_Member__c LIMIT 1];
        
        Test.stopTest();
    }
}