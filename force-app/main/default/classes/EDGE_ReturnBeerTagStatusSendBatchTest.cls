/**
Class Name: ECM_OutletExecutionProcessBatchTest
Author                  Version    Date           Detail
Joshraj Sen/Sakshi Shan V3.0  01/04/2024  152305 SCA Violation Reduction
*/
@isTest
public class EDGE_ReturnBeerTagStatusSendBatchTest 
{
     static String technicalIssueRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
     static String qualityCaseConfigRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();     
     static String qccaseTaskTypeRecId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
     static String caseSubTypeRecordId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId(); 
     static Id countryId = EDGE_UtilityTestClass.setupCountryPL('IE');
     static Account testoutlet =new Account();
    private static Pick_Up_Options__c getRBPickUpOption(){
        Pick_Up_Options__c pOption = new Pick_Up_Options__c();
        pOption.Name = 'Gold[IE]';
        pOption.Geography__c = countryId;
        return pOption;
    }
    @isTest
    public static void insertReturnBeerTag3(){
        EDGE_UtilityTestClass.createOrgSettings();
        test.startTest();
        Quality_Case_Configuration__c qc = new Quality_Case_Configuration__c();
        qc = EDGE_ReturnBeerTagStatusSendBatchTest.getQc();
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
         //Territory Hierarchy records creation for all different recordtypes
        Territory_Hierarchy__c terrHierBsUnitobj = new Territory_Hierarchy__c();
        terrHierBsUnitobj = EDGE_ReturnBeerTagStatusSendBatchTest.getTerrHierBsUnitobj();   
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Territory_Hierarchy__c terrHierSalAreaobj = new Territory_Hierarchy__c();
        terrHierSalAreaobj = EDGE_ReturnBeerTagStatusSendBatchTest.getTerrHierSalAreaobj(terrHierBsUnitobj);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Territory_Hierarchy__c terrHierRegionobj = new Territory_Hierarchy__c();
        terrHierRegionobj = EDGE_ReturnBeerTagStatusSendBatchTest.getTerrHierRegionobj(terrHierSalAreaobj);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        //Terrory record creation to populate Sales Area and Business Unit 
        Territory__c territoryObj = new Territory__c();
        territoryObj = EDGE_ReturnBeerTagStatusSendBatchTest.getTerritoryObj(terrHierRegionobj);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        test.stopTest();
        Org_Setting__c org = Org_Setting__c.getOrgDefaults();
        org.Run_Triggers__c = false;
        update org;
        List <Pick_Up_Options__c> pickUpOptionLst = new List <Pick_Up_Options__c>();
        pickUpOptionLst = EDGE_ReturnBeerTagStatusSendBatchTest.getPickUpOptionLst();
        //Id countryId2 = EDGE_UtilityTestClass.setupCountry('AU');
        testoutlet = EDGE_ReturnBeerTagStatusSendBatchTest.getTestOutlet(pickUpOptionLst,territoryObj,terrHierRegionobj);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
		System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        org.Run_Triggers__c = true;
        update org; 
        Case cc = new Case();
        cc = EDGE_ReturnBeerTagStatusSendBatchTest.getCc(testoutlet);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        ctList = EDGE_ReturnBeerTagStatusSendBatchTest.getCtList(cc,qc);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        List<Product__c> prodList = new List<Product__c> (); 
        prodList = EDGE_ReturnBeerTagStatusSendBatchTest.getProdList();
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        List<Product__c> prodUpdate = new List<Product__c>();
        prodUpdate = EDGE_ReturnBeerTagStatusSendBatchTest.getProdUpdate(prodList);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Market_Assortment_Product__c marketproduct= new Market_Assortment_Product__c();
        marketproduct = EDGE_ReturnBeerTagStatusSendBatchTest.getMarketproduct(prodList,pickUpOptionLst);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
        Return_Beer_Tag__c rbt= new Return_Beer_Tag__c();
        rbt = EDGE_ReturnBeerTagStatusSendBatchTest.getRbt(ctList,marketproduct,pickUpOptionLst);
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
         Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,Market_Order__c, Region__c, Serial_Number__c, Scope__c, Job_Group__c from Market_Batch_Setting__mdt where Batch_Class__c = 'EDGE_ReturnBeerTagStatusSendBatch' AND Country_Code__c ='IE'];
        String className = batchSetting.Batch_Class__c;
        system.assert(batchSetting !=null,'Batch Setting should not be null');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);    
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        System.debug(LoggingLevel.Debug,'@@Limit '+Limits.getQueries());
    }
    public static Quality_Case_Configuration__c getQc(){
        Quality_Case_Configuration__c qc = new Quality_Case_Configuration__c();
        qc.RecordTypeId = qccaseTaskTypeRecId;
        qc.Name = 'TestQCC';
        insert qc;
        return qc;
    }
    public static Territory_Hierarchy__c getTerrHierBsUnitobj(){
        string buRecType = 'Business Unit';
        Territory_Hierarchy__c terrHierBsUnitobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId,buRecType);
        insert terrHierBsUnitobj; 
        return terrHierBsUnitobj;
    }
    public static Territory_Hierarchy__c getTerrHierSalAreaobj(Territory_Hierarchy__c terrHierBsUnitobj){
        string saRecType = 'Sales Area';
        Territory_Hierarchy__c terrHierSalAreaobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, saRecType);
        terrHierSalAreaobj.Parent_BU__c=terrHierBsUnitobj.Id;
        insert terrHierSalAreaobj;
        return terrHierSalAreaobj;
    }
    public static Territory_Hierarchy__c getTerrHierRegionobj(Territory_Hierarchy__c terrHierSalAreaobj){
        string reRecType = 'Region';
        Territory_Hierarchy__c terrHierRegionobj = EDGE_UtilityTestClass.getTerritoryHierarchy(countryId, reRecType);
        terrHierRegionobj.Parent_BU__c=terrHierSalAreaobj.Id;
        insert terrHierRegionobj;
        return terrHierRegionobj;
    }
    public static Territory__c getTerritoryObj(Territory_Hierarchy__c terrHierRegionobj){
        Territory__c territoryObj=EDGE_UtilityTestClass.getTerritoryRec();
        territoryObj.Territory_Type__c ='Sales';
        territoryObj.Region__c = terrHierRegionobj.Id;
        insert territoryObj;
        return territoryObj;
    }
    public static List <Pick_Up_Options__c> getPickUpOptionLst(){
        List <Pick_Up_Options__c> pickUpOptionLst = new List <Pick_Up_Options__c>();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[IE]';
        pickupOption.Status__c = 'Active';
        pickUpOptionLst.add(pickupOption);
        Pick_Up_Options__c	pickUpOption1= getRBPickUpOption();
        pickUpOption1.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Category').getRecordTypeId();
        pickUpOption1.Reason_Category_Name__c='RB Reason Category';
        pickUpOption1.Name = 'Gold[IE]';
        pickUpOption1.Status__c = 'Active';
        pickUpOptionLst.add(pickUpOption1);
        Pick_Up_Options__c pickUpOption2 = getRBPickUpOption();
        pickUpOption2.RecordTypeId = Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('Product Strategy').getRecordTypeId();
        pickUpOption2.Name='Range[IE]';
        pickUpOption2.Status__c = 'Active';
        pickUpOptionLst.add(pickUpOption2);
        Pick_Up_Options__c	pickUpOption3= getRBPickUpOption();
        pickUpOption3.RecordTypeId= Schema.SObjectType.Pick_Up_Options__c.getRecordTypeInfosByName().get('RB Reason Code').getRecordTypeId();
        pickUpOption3.Reason_Category__c = pickUpOption.id;
        pickUpOption3.Reason_Code_Name__c='RB Reason Code';
        pickUpOption3.Name = 'Gold[IE]';
        pickUpOptionLst.add(pickUpOption3);
        Insert pickUpOptionLst;
        return pickUpOptionLst;
    }
    public static Account getTestOutlet(List <Pick_Up_Options__c> pickUpOptionLst,Territory__c territoryObj,Territory_Hierarchy__c terrHierRegionobj){
        Account testoutlet = EDGE_UtilityTestClass.getOutletRecord();
        testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickUpOptionLst[0].Id;
        testoutlet.Country__c= countryId;
        testoutlet.SAP_Ship_to__c = '2345';
        testoutlet.SAP_Sold_to__c = '3248';
        testoutlet.Primary_Sales_Territory__c = territoryObj.id;
        testoutlet.Primary_Sales_Territory_Region__c = terrHierRegionobj.Id;
        insert testoutlet;
        return testoutlet;
    }
    public static Case getCc(Account testoutlet){
        Case cc = new Case();
        cc.AccountId = testoutlet.Id;
        cc.Status = 'New';
        cc.Origin = 'EDGE 365 Global';
        cc.RecordTypeId = technicalIssueRecordTypeId;
        insert cc;
        return cc;
    }
    public static List<Case_Task__c> getCtList(Case cc,Quality_Case_Configuration__c qc){
        List<Case_Task__c> ctList = new List<Case_Task__c>();
        Case_Task__c ct = new Case_Task__c();
        ct.Case__c = cc.ID;
        ct.Account__c = testoutlet.Id;
        ct.GUID__c = 'TWRFSHJAKSVGG';
        ct.Case_Task_Type__c = qc.id;
        ctList.add(ct);
        Case_Task__c ct1 = new Case_Task__c();
        ct1.Case__c = cc.ID;
        ct1.Account__c = testoutlet.Id;
        ct1.GUID__c = 'TWRFSHJAKSVGN';
        ct1.Case_Task_Type__c=qc.id;
        ctList.add(ct1);
        insert ctList;
        return ctList;
    }
    public static List<Product__c> getProdList(){
        //Product
       List<Product__c> prodList = new List<Product__c> ();
       Product__c prod3 = new Product__c();
       prod3.Name = 'Johnny Walker1';
       prod3.Product_Full_Name__c = 'Johnny Walker1';
       prod3.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Item').getRecordTypeId();
       prod3.Case_Volume__c = '100';
       prod3.UPIID__c='12345';
       prodList.add(prod3);
       Product__c prod2 = new Product__c();
       prod2.Name = 'Johnny Walker2';
       prod2.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('CRI').getRecordTypeId();
       prod2.Product_Full_Name__c = 'Johnny Walker2';
       prod2.UPIID__c='12345333';
       prodList.add(prod2);
       Product__c prod1 = EDGE_UtilityTestClass.getProd();
       prod1.RecordTypeId = Product__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('SKU').getRecordTypeId(); 
       prod1.Product_Full_Name__c = 'Johnny Walker';
       prod1.Description__c='Johnny Walker';
       prod1.Type__c = 'Diageo Product';
       prod1.SAP_SKU_Code__c = 'Prod123';
       prod1.UPIID__c='44444444444444444';
       prodList.add(prod1);
       insert prodList;
       return prodList;
   }
   public static List<Product__c> getProdUpdate(List<Product__c> prodList){
    List<Product__c> prodUpdate = new List<Product__c>();
    prodList[1].Item__c=prodList[0].id;
    prodList[2].CRI__c=prodList[1].id;
    prodUpdate.add(prodList[1]);
    prodUpdate.add(prodList[2]);
    update prodUpdate;
    return prodUpdate;
}
public static Market_Assortment_Product__c getMarketproduct(List<Product__c> prodList,List <Pick_Up_Options__c> pickUpOptionLst){
    //Market Assortment Product
    Market_Assortment_Product__c marketproduct= new Market_Assortment_Product__c();
    marketproduct.Product__c = prodList[2].id;
    marketproduct.Market_Assortment__c = countryId;
    marketProduct.ECM_Pickup_Option__c = pickUpOptionLst[2].Id;
    marketProduct.Returnable_Product__c = true;
    marketProduct.Quality_Flag__c = true;
    marketProduct.Returnable_Product__c = true;
    insert marketproduct;   
    return marketproduct;
}
public static Return_Beer_Tag__c getRbt(List<Case_Task__c> ctList,Market_Assortment_Product__c  marketproduct,List<Pick_Up_Options__c> pickUpOptionLst){
    Return_Beer_Tag__c rbt= new Return_Beer_Tag__c();
    rbt.Case_Task__c = ctList[1].Id;
    rbt.Keg_number__c = '212';
    rbt.Tag_Number__c = '1234';
    rbt.Product__c = marketproduct.id;
    rbt.Volume__c = 1;
    rbt.Status__c ='New';
    rbt.Sample_Taken__c = 'No';
    rbt.Broached_Keg__c = 'No';
    rbt.Reason_Category__c = pickUpOptionLst[1].Id;
    rbt.Reason_Code__c = pickUpOptionLst[3].id;
    rbt.GUID__c ='TWRFSHJAKSVGG';
    insert rbt;
    return rbt;
}

}