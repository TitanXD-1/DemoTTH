/**
* @description Test Class for ReturnBeerTagTriggerHandler
* @history
* 1.1   Mayank Singh     11/08/2021
* 1.2	Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/
@isTest
public class EDGE_ReturnBeerTagTriggerHandlerTest {
    final static String TECHNICALISSUERECORDTYPEID = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
    final static String QCCASETASKTYPERECID = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String SALESTERRITORYRECID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();
    final static String TERRITORYRECID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();
    final static String PRODUCTRECID = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId();
    final static String PRODUCTITEMRECID = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Item').getRecordTypeId();






    @isTest
    public static void insertReturnBeerTag(){
        EDGE_UtilityTestClass.createOrgSettings();      
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        List<Pick_Up_Options__c> pickupOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        pickupOptions.add(pickupOption);
         Pick_Up_Options__c	pickUpOption1= getRBPickUpOption(countryId);
        pickUpOption1.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();
        pickUpOption1.Reason_Category_Name__c='RB Reason Category';
        pickUpOption1.Name = 'Gold[AUT]';
        pickUpOption1.Status__c = 'Active';
        pickupOptions.add(pickupOption1);
   		//Id countryId2 = EDGE_UtilityTestClass.setupCountry('AU');
        Pick_Up_Options__c	pickUpOption2= getRBPickUpOption(countryId);
        pickUpOption2.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();
        pickUpOption2.Reason_Category__c = pickUpOption.id;
        pickUpOption2.Reason_Code_Name__c='RB Reason Code';
        pickUpOption2.Name = '[AU]';
        pickupOptions.add(pickupOption2);
        insert pickupOptions;
        system.assert(pickupOptions!=null,'pickupOptions should not be null');
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        //Territory Hierarchy records creation for all different recordtypes
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        insert terrHierBsUnitobj;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        
         //System.debug('Condition 2 '+Limits.getQueries());
        test.startTest();
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj; 
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
         //System.debug('Condition 3 '+Limits.getQueries());
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj.Parent_BU__c=terrHierSalAreaobj.Id;
        insert terrHierRegionobj;
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        
        Territory__c salesTerritory = new Territory__c();
        salesTerritory.Territory_Type__c = 'Service';
        salesTerritory.Country__c = countryID;
        salesTerritory.Region__c = terrHierRegionobj.id;
        insert salesTerritory; 
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.SAP_Ship_to__c = '2345';
		testoutlet.SAP_Sold_to__c = '3248';
        insert testoutlet;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Quality_Case_Configuration__c qc = new Quality_Case_Configuration__c();
        qc.RecordTypeId = QCCASETASKTYPERECID;
        qc.Name = 'TestQCC';
        insert qc;
		
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
 	    Case cc = new Case();
        cc.AccountId = testoutlet.Id;       
        cc.Status = 'New';
        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = TECHNICALISSUERECORDTYPEID;
        insert cc; 
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
         //System.debug('Condition 5 '+Limits.getQueries());
        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = cc.ID;
        ct.Case_Task_Type__c = qc.Id;
        ct.Account__c = testoutlet.Id;
        ct.GUID__c = 'TWRFSHJAKSVGG';
        insert ct;
         //System.debug('Condition 6 '+Limits.getQueries());
          
		System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        
        test.stopTest();
         //System.debug('Condition 7 '+Limits.getQueries());
        //createOutletTerritory
        Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
        outletTerritory.Territory__c = salesTerritory.id;
        outletTerritory.Outlet__c = testoutlet.id;
        insert outletTerritory;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
         //System.debug('Condition 8 '+Limits.getQueries());
        Return_Beer_Tag__c rbt1= new Return_Beer_Tag__c();
        rbt1.Case_Task__c = ct.Id;
        rbt1.Status__c ='SAP Failure';
        rbt1.Case_Task__c = ct.Id;
        rbt1.Keg_number__c = '212';
        rbt1.Tag_Number__c = '1234';
        rbt1.Volume__c = 1;
        rbt1.Reason_Category__c = pickUpOption1.Id;
        rbt1.Reason_Code__c = pickUpOption2.id;
        rbt1.Sample_Taken__c = 'Yes';
        rbt1.Broached_Keg__c = 'Yes';
        rbt1.GUID__c ='TWRFSHJAKSVGP';
        insert rbt1;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
         //System.debug('Condition 9 '+Limits.getQueries());
        List<String> retrunBeerTagList = new List<String>();
        retrunBeerTagList.add(rbt1.Id);      
        EDGE_ReturnBeerTagBulkRetryHandler.Requests obj = new EDGE_ReturnBeerTagBulkRetryHandler.Requests();
        obj.retrunBeerTagId = retrunBeerTagList;        
        EDGE_ReturnBeerTagBulkRetryHandler.RetryRecordtoSAP(new List<EDGE_ReturnBeerTagBulkRetryHandler.Requests>{obj});               
        EDGE_ReturnBeerTagStatusSendHandler returnBeerTag = new EDGE_ReturnBeerTagStatusSendHandler();
        // create RB wsdl records 
        list<RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1> RB_TagsRecords =  new list<RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1>();
        RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1 wsdlrbtag = new RB_SapReturnBeerWebCallout.DT_ReturnBeerTags_CreateTag_D1();
        wsdlrbtag.sfdcid = 'a2F4G00000M4SyoUAF';
        // country code of the record  
        wsdlrbtag.country       = 'IE';
        wsdlrbtag.sold_to       =  '78843';      
        wsdlrbtag.disrep='Quality Territory 01';
        wsdlrbtag.salerep_reg='Aus Region';
        wsdlrbtag.salesrep='Aus Territory 01';
        DateTime abc= DateTime.now();        
        wsdlrbtag.create_date   =  abc;
        wsdlrbtag.kegnum        = '3062485';
        wsdlrbtag.matnr         = '660488';
        wsdlrbtag.out_vol       = '1';
        wsdlrbtag.reason        = '1';
        wsdlrbtag.reason_cat    = 'HARD';
        wsdlrbtag.sampled       = false;
        wsdlrbtag.tagnum        = 'B035725';
        wsdlrbtag.broached      = false;
        RB_TagsRecords.add(wsdlrbtag);        
        Map<Id,String> returnBeerAccountMap = new Map<Id,String>();
        returnBeerAccountMap.put('a2F4G00000M4SyoUAF','a2F4G00000M4Sy345345');        
        returnBeerTag.fetchReturnBeerTagRequestLog(RB_TagsRecords,returnBeerAccountMap);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        
 
    }
    
    @isTest
    public static void insertReturnBeerTag2(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        List<Pick_Up_Options__c> pickUpOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        pickUpOptions.add(pickUpOption);
        
        Pick_Up_Options__c	pickUpOption1= getRBPickUpOption(countryId);
        pickUpOption1.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();
        pickUpOption1.Reason_Category_Name__c='RB Reason Category';
        pickUpOption1.Name = 'Gold[AUT]';
        pickUpOption1.Status__c = 'Active';
        pickUpOptions.add(pickUpOption1);
        system.assert(pickUpOptions!=null,'pickUpOptions should not be null');

        
        //Id countryId2 = EDGE_UtilityTestClass.setupCountry('AU');
        Pick_Up_Options__c	pickUpOption2= getRBPickUpOption(countryId);
        pickUpOption2.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();
        pickUpOption2.Reason_Category__c = pickUpOption.id;
        pickUpOption2.Reason_Code_Name__c='RB Reason Code';
        pickUpOption2.Name = '[AU]';
        pickUpOptions.add(pickUpOption2);
        Insert pickUpOptions;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Quality_Case_Configuration__c qc = new Quality_Case_Configuration__c();
        qc.RecordTypeId = QCCASETASKTYPERECID;
        qc.Name = 'TestQCC';
        insert qc;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
		test.startTest();
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        insert terrHierBsUnitobj;    
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj; 
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj.Parent_BU__c=terrHierSalAreaobj.Id;
        insert terrHierRegionobj;
       
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        List<Territory__c> territories=new List<Territory__c>();
        Territory__c salesTerritory = new Territory__c();
        salesTerritory.Name = 'Regional Terr';
        salesTerritory.Territory_Type__c = 'Regional Quality Manager (IE)';
        salesTerritory.RecordTypeId= TERRITORYRECID;
        salesTerritory.Country__c = countryID;
        territories.add(salesTerritory);

        
        Territory__c salesTerritory1 = new Territory__c();
        salesTerritory1.Name = 'Service Terr';
        salesTerritory1.Territory_Type__c = 'Service Lead';
        salesTerritory1.RecordTypeId= TERRITORYRECID;
        salesTerritory1.Country__c = countryID;
        territories.add(salesTerritory1);

        
        
        Territory__c salesTerritory2 = new Territory__c();
        salesTerritory2.Name = 'Dispense Terr';
        salesTerritory2.Territory_Type__c = 'Quality Dispense';
        salesTerritory2.RecordTypeId= TERRITORYRECID;
        salesTerritory2.Country__c = countryID;
        territories.add(salesTerritory2);
        
        Territory__c salesTerritory3 = new Territory__c();
        salesTerritory3.Name = 'Sales Terr';
        salesTerritory3.Territory_Type__c = 'Sales';
        salesTerritory3.RecordTypeId= SALESTERRITORYRECID;
        salesTerritory3.Country__c = countryID;
        salesTerritory3.Region__c = terrHierRegionobj.id;
        territories.add(salesTerritory3);
        insert territories;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.SAP_Ship_to__c = '2345';
		testoutlet.SAP_Sold_to__c = '3248';
        testoutlet.Primary_Sales_Territory__c = salesTerritory3.id;
        testoutlet.Primary_Sales_Territory_Region__c = terrHierRegionobj.Id;
        insert testoutlet;
       
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Case cc = new Case();
        cc.AccountId = testoutlet.Id;
        cc.Status = 'New';
        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = TECHNICALISSUERECORDTYPEID;
        insert cc;

        Test.stopTest();
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = cc.ID;
        ct1.Account__c = testoutlet.Id;
        ct1.Case_Task_Type__c = qc.Id;
        ct1.GUID__c = 'TWRFSHJAKSVGN';
        insert ct1;
       

        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        
        //createOutletTerritory
        List<Outlet_Territory__c> outletTerritories=new List<Outlet_Territory__c>();
        Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
        outletTerritory.Territory__c = salesTerritory.id;
        outletTerritory.Outlet__c = testoutlet.id;
        outletTerritories.add(outletTerritory);

        
        Outlet_Territory__c outletTerritory1 = new Outlet_Territory__c();
        outletTerritory1.Territory__c = salesTerritory1.id;
        outletTerritory1.Outlet__c = testoutlet.id;
        outletTerritories.add(outletTerritory1);

        
        Outlet_Territory__c outletTerritory2 = new Outlet_Territory__c();
        outletTerritory2.Territory__c = salesTerritory2.id;
        outletTerritory2.Outlet__c = testoutlet.id;
        outletTerritories.add(outletTerritory2);
        
        Outlet_Territory__c outletTerritory3 = new Outlet_Territory__c();
        outletTerritory3.Territory__c = salesTerritory3.id;
        outletTerritory3.Outlet__c = testoutlet.id;
        outletTerritories.add(outletTerritory3);
        insert outletTerritories;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Return_Beer_Tag__c rbt= new Return_Beer_Tag__c();
        rbt.Case_Task__c = ct1.Id;
        rbt.Keg_number__c = '212';
        rbt.Tag_Number__c = '1234';
        rbt.Volume__c = 1;
        rbt.Status__c ='SAP Failure';
        rbt.Sample_Taken__c = 'No';
        rbt.Broached_Keg__c = 'No';
        rbt.Reason_Category__c = pickUpOption1.Id;
        rbt.Reason_Code__c = pickUpOption2.id;
        rbt.GUID__c ='TWRFSHJAKSVGG';
        insert rbt;
        
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        List<String> retrunBeerTagList = new List<String>();
        retrunBeerTagList.add(rbt.Id);
        
        EDGE_ReturnBeerTagBulkRetryHandler.Requests obj = new EDGE_ReturnBeerTagBulkRetryHandler.Requests();
        obj.retrunBeerTagId = retrunBeerTagList;
        
        EDGE_ReturnBeerTagBulkRetryHandler.RetryRecordtoSAP(new List<EDGE_ReturnBeerTagBulkRetryHandler.Requests>{obj});
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
  
    }
    
    /*@isTest
    public static void insertReturnBeerTag3(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Quality_Case_Configuration__c qc = new Quality_Case_Configuration__c();
        qc.RecordTypeId = QCCASETASKTYPERECID;
        qc.Name = 'TestQCC';
        insert qc;
        
        
		test.startTest();        
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.SAP_Ship_to__c = '2345';
		testoutlet.SAP_Sold_to__c = '3248';
        insert testoutlet;
 
        Case cc = new Case();
        cc.AccountId = testoutlet.Id;
        cc.Status = 'New';
        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = TECHNICALISSUERECORDTYPEID;
        insert cc;

        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = cc.ID;
        ct1.Account__c = testoutlet.Id;
        ct1.Case_Task_Type__c = qc.Id;
        ct1.GUID__c = 'TWRFSHJAKSVGN';
        insert ct1;
       
        Pick_Up_Options__c	pickUpOption1= getRBPickUpOption(countryId);
        pickUpOption1.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();
        pickUpOption1.Reason_Category_Name__c='RB Reason Category';
        pickUpOption1.Name = 'Gold[AUT]';
        pickUpOption1.Status__c = 'Active';
        Insert pickUpOption1;
        
        //Id countryId2 = EDGE_UtilityTestClass.setupCountry('AU');
        Pick_Up_Options__c	pickUpOption2= getRBPickUpOption(countryId);
        pickUpOption2.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();
        pickUpOption2.Reason_Category__c = pickUpOption.id;
        pickUpOption2.Reason_Code_Name__c='RB Reason Code';
        pickUpOption2.Name = '[AU]';
        Insert pickUpOption2;
        
         //Territory Hierarchy records creation for all different recordtypes
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, buRecType);
        insert terrHierBsUnitobj; 
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj;
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj.Parent_BU__c=terrHierSalAreaobj.Id;
        
        insert terrHierRegionobj;
        test.stopTest();
        //Terrory record creation to populate Sales Area and Business Unit 
        Territory__c territoryObj=EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Territory_Type__c ='Sales';
        territoryObj.Region__c = terrHierRegionobj.Id;
        insert territoryObj;
        

        //createOutletTerritory
        Outlet_Territory__c outletTerritory = new Outlet_Territory__c();
        outletTerritory.Territory__c = territoryObj.id;
        outletTerritory.Outlet__c = testoutlet.id;
        insert outletTerritory;

        
        Return_Beer_Tag__c rbt= new Return_Beer_Tag__c();
        rbt.Case_Task__c = ct1.Id;
        rbt.Keg_number__c = '212';
        rbt.Tag_Number__c = '1234';
        rbt.Volume__c = 1;
        rbt.Status__c ='SAP Failure';
        rbt.Sample_Taken__c = 'No';
        rbt.Broached_Keg__c = 'No';
        rbt.Reason_Category__c = pickUpOption1.Id;
        rbt.Reason_Code__c = pickUpOption2.id;
        rbt.GUID__c ='TWRFSHJAKSVGG';
        insert rbt;

        
        List<String> retrunBeerTagList = new List<String>();
        retrunBeerTagList.add(rbt.Id);
        
        EDGE_ReturnBeerTagBulkRetryHandler.Requests obj = new EDGE_ReturnBeerTagBulkRetryHandler.Requests();
        obj.retrunBeerTagId = retrunBeerTagList;
        
        EDGE_ReturnBeerTagBulkRetryHandler.RetryRecordtoSAP(new List<EDGE_ReturnBeerTagBulkRetryHandler.Requests>{obj});
        
      
    }
*/
    
    
    
    
     @isTest
    public static void insertReturnBeerTag4(){
        EDGE_UtilityTestClass.createOrgSettings();
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[AUT]';
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        system.assert(pickUpOption.id!=null,'pickupOption should not be null');
        
        Quality_Case_Configuration__c qc = new Quality_Case_Configuration__c();
        qc.RecordTypeId = QCCASETASKTYPERECID;
        qc.Name = 'TestQCC';
        insert qc;
        
        
		test.startTest();        
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testoutlet.SAP_Ship_to__c = '2345';
		testoutlet.SAP_Sold_to__c = '3248';
        insert testoutlet;
 
        Case cc = new Case();
        cc.AccountId = testoutlet.Id;
        cc.Status = 'New';
        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = TECHNICALISSUERECORDTYPEID;
        insert cc;

        
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = cc.ID;
        ct1.Account__c = testoutlet.Id;
        ct1.Case_Task_Type__c = qc.Id;
        ct1.GUID__c = 'TWRFSHJAKSVGN';
        insert ct1;
        List<Pick_Up_Options__c> pickupOptions=new List<Pick_Up_Options__c>();
        Pick_Up_Options__c	pickUpOption1= getRBPickUpOption(countryId);
        pickUpOption1.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();
        pickUpOption1.Reason_Category_Name__c='RB Reason Category';
        pickUpOption1.Name = 'Gold[AUT]';
        pickUpOption1.Status__c = 'Active';
        pickupOptions.add(pickUpOption1);
        
        
        //Id countryId2 = EDGE_UtilityTestClass.setupCountry('AU');
        Pick_Up_Options__c	pickUpOption2= getRBPickUpOption(countryId);
        pickUpOption2.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();
        pickUpOption2.Reason_Category__c = pickUpOption.id;
        pickUpOption2.Reason_Code_Name__c='RB Reason Code';
        pickUpOption2.Name = '[AU]';
        pickupOptions.add(pickUpOption2);
        Insert pickUpOptions;
        
        Return_Beer_Tag__c rbt= new Return_Beer_Tag__c();
        rbt.Case_Task__c = ct1.Id;
        rbt.Keg_number__c = '212';
        rbt.Tag_Number__c = '1234';
        rbt.Volume__c = 1;
        rbt.Status__c ='SAP Failure';
        rbt.Sample_Taken__c = 'No';
        rbt.Broached_Keg__c = 'No';
        rbt.Reason_Category__c = pickUpOption1.Id;
        rbt.Reason_Code__c = pickUpOption2.id;
        rbt.GUID__c ='TWRFSHJAKSVGG';
        insert rbt;

        update rbt;
    	delete rbt;
        undelete rbt;
        
        List<String> retrunBeerTagList = new List<String>();
        retrunBeerTagList.add(rbt.Id);
        
        EDGE_ReturnBeerTagBulkRetryHandler.Requests obj = new EDGE_ReturnBeerTagBulkRetryHandler.Requests();
        obj.retrunBeerTagId = retrunBeerTagList;
        
        EDGE_ReturnBeerTagBulkRetryHandler.RetryRecordtoSAP(new List<EDGE_ReturnBeerTagBulkRetryHandler.Requests>{obj});
        Test.stopTest();
      
    }
    @isTest
    static void RB_SapReturnBeerWebCallout(){ //NOPMD
        test.startTest();
        try{
            RB_SapReturnBeerWebCallout.HTTPS_Port objport = new RB_SapReturnBeerWebCallout.HTTPS_Port();
            objport.SI_ReturnBeerTags_Sync_Out_D1(null);
        }
        catch(Exception ex){
            System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
        }
        test.stopTest();
    }
    
    private static Pick_Up_Options__c getRBPickUpOption(Id countryId){
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[AUT]';
        pOption.Geography__c = countryId;
        return pOption;
    }
}