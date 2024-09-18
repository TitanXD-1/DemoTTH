/**
* @Name: EDGE_OutletExecutionTriggerHelperTest
* @History                                                            
* @VERSION     AUTHOR            DATE            DETAIL
* @1.0         Sandeep Sahoo     03/04/2019      Test Class for EDGE_OutletExecutionTriggerHelper
* @1.1         Saurav Paul       23/04/2019      Test class for Create opportunity
* @1.2        Rajarshi Lahiri    07/09/2022       US : ES20-13288(Test Class Corrected and Coverage Increased)
* @1.3        Priya Soni         25/10/2022       US : ES20-13397
* @2.2		 Saurav Prasad		 14/08/2024		  155304 : GB Opportunity Scoring: Auto Closure of Advanced Analytics generated opportunities based on TRAX response (MPA/MAS/WPA)
**/

@isTest
public class EDGE_OutletExecutionTriggerHelperTest{
    
     public static Map <String,Schema.RecordTypeInfo> mapOutExeRecordTypes = Outlet_Execution__c.sObjectType.getDescribe().getRecordTypeInfosByName();
    // Get the record type id of from the Map based on the Name
    public static Id productRecTypeId = mapOutExeRecordTypes.get('Product').getRecordTypeId();
    public static Id activationRecTypeId = mapOutExeRecordTypes.get('Activation').getRecordTypeId();
    public static String pickupRecTypeId = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Default Pickup').getRecordTypeId();
    
    @isTest
    public static void testCreateOpportunityForSubSegTer(){
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
      
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        //155304
        createData(countryId);
        
        Test.startTest();
        List<Product__c> prodObjList = [SELECT Id,Name FROM PRODUCT__c WHERE Type__c='Diageo Product'];
        Territory__c primaryTerr = [SELECT Id,Name FROM Territory__c LIMIT 1];
        List<Fascia__c> fasciaList = [SELECT Id,Name FROM Fascia__c];
        Pick_Up_Options__c masPkUp = [SELECT Id,Name FROM Pick_Up_Options__c WHERE RecordTypeId =:pickupRecTypeId];
        List<Account> accObjList = [SELECT Id,Name FROM Account];

        //Creating Opp Templates        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp1 = createOpportunityTemplate(oppTemp1,'MAS');
        oppTemp1.Territory__c = primaryTerr.Id;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp2 = createOpportunityTemplate(oppTemp2,'MAS');
        oppTemp2.Territory__c = primaryTerr.Id;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp3 = createOpportunityTemplate(oppTemp3,'MAS');
        oppTemp3.Territory__c = primaryTerr.Id;
        oppTemp3.Activation__c = null;
        opportunityTempList.add(oppTemp3);
      
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp4 = createOpportunityTemplate(oppTemp4,'MAS');
        oppTemp4.Territory__c = primaryTerr.Id;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp4);
        
        Opportunity_Template__c oppTemp5 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp5 = createOpportunityTemplate(oppTemp5,'MAS');
        oppTemp5.Product__c=null;
        oppTemp5.Activation__c = masPkUp.Id;
        oppTemp5.Fascia__c=fasciaList[0].Id;
        opportunityTempList.add(oppTemp5);
        
        Opportunity_Template__c oppTemp6 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp6 = createOpportunityTemplate(oppTemp6,'MPA');
        oppTemp6.Activation__c = null;
        oppTemp6.Fascia__c=fasciaList[0].Id;
        opportunityTempList.add(oppTemp6);
        
        Opportunity_Template__c oppTemp7 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObjList[0].Id, primaryTerr.Id, countryId);
        oppTemp7 = createOpportunityTemplate(oppTemp7,'MPA');
        oppTemp7.Activation__c = null;
        oppTemp7.Fascia__c=fasciaList[1].Id;
        oppTemp7.Product__c=prodObjList[1].Id;
        opportunityTempList.add(oppTemp7);
        
        insert opportunityTempList;
        
        createOutletExecutions(accObjList,prodObjList, masPkUp);
        cloneOpportunity();
        updateOutletExecutions();
        
        Test.stopTest();
  }
    //155304
    public static void createOutletExecutions(List<Account> accObjList,List<Product__c> prodObjList, Pick_Up_Options__c masPkUp){
        List<Outlet_Execution__c> outletExecutions=new List<Outlet_Execution__c>();
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObjList[0].Id);
        outExecObj.Product__c = prodObjList[0].Id;
        outExecObj = createOutletExecution(outExecObj);
        outletExecutions.add(outExecObj);

        
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObjList[0].Id);
        String subString = masPkUp.Name.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1 = createOutletExecution(outExecObj1);
        outletExecutions.add(outExecObj1);
        
        Outlet_Execution__c outExecObj2 = EDGE_UtilityTestClass.getOutletExecution(accObjList[1].Id);
        outExecObj2.Product__c = prodObjList[0].Id;
        outExecObj2 = createOutletExecution(outExecObj2);
        outletExecutions.add(outExecObj2);

        
        Outlet_Execution__c outExecObj3 = EDGE_UtilityTestClass.getOutletExecution(accObjList[1].Id);
        outExecObj3.Activation_Reference__c = subString;
        outExecObj3 = createOutletExecution(outExecObj3);
        outletExecutions.add(outExecObj3);
        insert outletExecutions;
    }
    //155304
    public static void createData(Id countryId){
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Market_Setting__c mkt=EDGE_UtilityTestClass.getMarketSetting(countryId);
        mkt.Include_Fascia_in_Opportunity_Generation__c=true;
        mkt.Threshold_Format__c='Percent';
        insert mkt;
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c ='Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        List<Fascia__c> fascias=new List<Fascia__c>();
        Fascia__c fascia=new Fascia__c();
        fascia.Name='Test Fascia1';
        fascia.Country__c=countryId;
        fascias.add(fascia);
        
        Fascia__c fascia1=new Fascia__c();
        fascia1.Name='Test Fascia2';
        fascia1.Country__c=countryId;
        fascias.add(fascia1);
        insert fascias;
        List<Account> accounts=new List<Account>();
        Account accObj = createAccount('Outlet 1',countryId,oultlVstPriPkUp);
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accounts.add(accObj);
        
        Account accObj1 = createAccount('Outlet 2',countryId,oultlVstPriPkUp);
        accObj1.Primary_Sales_Territory__c = null;
        accObj1.Fascia__c=fascia.Id;
        accounts.add(accObj1);
        insert accounts;
        
        List<Outlet_Territory__c> outletTerritories=new List<Outlet_Territory__c>();
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
         outletTerritories.add(outlTer);
        Outlet_Territory__c outlTer1 = EDGE_UtilityTestClass.getOutltTerritory(accObj1.Id, primaryTerr.Id);
         outletTerritories.add(outlTer1);
        insert  outletTerritories;
        List<Product__c> products=new List<Product__c>();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        products.add(prodObj);
               
        Product__c prodObj1 = EDGE_UtilityTestClass.getProd();
        prodObj1.Description__c='Johnny Walker1';
        prodObj1.Type__c = 'Diageo Product';
        prodObj1.UPIID__c='1234567';
        prodObj1.Product_Code__c='222222';
        products.add(prodObj1);
        insert products;
    }
    //155304
    public static Account createAccount(String accName, Id countryId,Pick_Up_Options__c oultlVstPriPkUp){
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Name=accName;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        return accObj;
    }
    //155304
    public static void cloneOpportunity(){
        List<Opportunity> oppList = new List<Opportunity>();
        for(Opportunity opp :
            [SELECT Id,Name,closeDate, Product__c, AccountId, StageName, Type,
             Activation__c, Activation_Name__c, Source__c 
             FROM Opportunity ]){
                 Opportunity cloneOpp = opp.clone(false,false,false,false);
                 oppList.add(cloneOpp);
             }
        
        Insert oppList;
    }
    //155304
    public static void updateOutletExecutions(){
        List<Outlet_Execution__c> outletExList = new List<Outlet_Execution__c>();
        
        for(Outlet_Execution__c outletEx :[SELECT Id,MAS__c,MPA__c,NPA__c,Distribution_TRAX__c FROM Outlet_Execution__c]){
            outletEx.MAS__c = 'Yes';
            outletEx.MPA__c = 'Yes';
            outletEx.NPA__c = 'Yes';
            outletEx.Distribution_TRAX__c = 'Yes';
            outletExList.add(outletEx);
        }
        
        update outletExList;
    }
    //155304
    public static Outlet_Execution__c createOutletExecution(Outlet_Execution__c outExecObj){
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        outExecObj.Distribution_TRAX__c = 'No';
        return outExecObj;
    }
    //155304
    public static Opportunity_Template__c createOpportunityTemplate(Opportunity_Template__c oppTemp, String oppType){
      Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();

        oppTemp.Cluster__c = geoMap.get('Cluster');
        oppTemp.Opportunity_Type__c = OppType ;
        oppTemp.Closing_Method__c = 'Trax';
        oppTemp.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp.Start_Date__c = System.today();
        oppTemp.Action__c = 'TestAction';
        oppTemp.Segment__c = 'Nightclub';
        oppTemp.Sub_Segment__c = 'Modern Nightclub';
        oppTemp.Territory__c = null;
        oppTemp.Channel__c = '';
        oppTemp.End_Date__c = null;
        
        return oppTemp;
    }
    
   
     @isTest
    public static void testCreateOpportunityForSubSeg(){
        //EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
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
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = 'Nightclub';
        oppTemp1.Sub_Segment__c = 'Modern Nightclub';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = 'Nightclub';
        oppTemp2.Sub_Segment__c = 'Modern Nightclub';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = 'Nightclub';
        oppTemp4.Sub_Segment__c = 'Modern Nightclub';
        oppTemp4.Territory__c = null;
        oppTemp4.Channel__c = '';
        oppTemp4.End_Date__c = null;
        oppTemp4.Activation__c = null;
        opportunityTempList.add(oppTemp4);
      
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = 'Nightclub';
        oppTemp3.Sub_Segment__c = 'Modern Nightclub';
        oppTemp3.Territory__c = null;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Product__c = null;
        oppTemp3.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp3);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        outExecObj.Distribution_TRAX__c = 'No';//ES20-13397
        
        insert outExecObj;
        
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        outExecObj.MAS__c = 'Yes';
        outExecObj.MPA__c = 'Yes';
        outExecObj.NPA__c = 'Yes';
        outExecObj.Distribution_TRAX__c = 'Yes';//ES20-13397

        update outExecObj;
        Test.stopTest();
  }
    
    @isTest
    public static void testCreateOpportunityForChannelTer(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
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
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = primaryTerr.Id;
        oppTemp1.Channel__c = 'On Trade';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = primaryTerr.Id;
        oppTemp2.Channel__c = 'On Trade';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);


        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = '';
        oppTemp3.Sub_Segment__c = '';
        oppTemp3.Territory__c = primaryTerr.Id;
        oppTemp3.Channel__c = 'On Trade';
        oppTemp3.End_Date__c = null;
        oppTemp3.Activation__c = null;
        opportunityTempList.add(oppTemp3);
      
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = '';
        oppTemp4.Sub_Segment__c = '';
        oppTemp4.Territory__c = primaryTerr.Id;
        oppTemp4.Channel__c = 'On Trade';
        oppTemp4.End_Date__c = null;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp4);        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
 /* @isTest
    public static void testCreateOpportunityForTer(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        insert accObj;
        
        Test.startTest();
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
      
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Source__c ='Trax';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = primaryTerr.Id;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = primaryTerr.Id;
        oppTemp2.Channel__c = '';
        oppTemp2.Source__c ='Trax';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);
        
         Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = '';
        oppTemp4.Sub_Segment__c = '';
        oppTemp4.Source__c ='Trax';
        oppTemp4.Territory__c = primaryTerr.Id;
        oppTemp4.Channel__c = '';
        oppTemp4.End_Date__c = null;
        oppTemp4.Activation__c = null;
        opportunityTempList.add(oppTemp4);
      
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Source__c ='Trax';
        oppTemp3.Segment__c = '';
        oppTemp3.Sub_Segment__c = '';
        oppTemp3.Territory__c = primaryTerr.Id;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Product__c = null;
        oppTemp3.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp3);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        outExecObj.MAS__c = 'Yes';
        outExecObj.MPA__c = 'Yes';
        outExecObj.NPA__c = 'Yes';
        update outExecObj;
        Test.stopTest();
        
  }  */
    
    @isTest
    public static void testCreateOpportunityForChannel(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
       
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c= 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
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
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = 'On Trade';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = 'On Trade';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);
        
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = '';
        oppTemp3.Sub_Segment__c = '';
        oppTemp3.Territory__c = null;
        oppTemp3.Channel__c = 'On Trade';
        oppTemp3.End_Date__c = null;
        oppTemp3.Activation__c = null;
        opportunityTempList.add(oppTemp3);
      
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = '';
        oppTemp4.Sub_Segment__c = '';
        oppTemp4.Territory__c = null;
        oppTemp4.Channel__c = 'On Trade';
        oppTemp4.End_Date__c = null;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp4);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        test.stopTest();
  }
    
    @isTest
    public static void testCreateOpportunityForCluster(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Region__c = geoMap.get('Region');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        //oppTemp1.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = 'On Trade';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        //oppTemp2.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = '';
        oppTemp3.Sub_Segment__c = '';
        oppTemp3.Territory__c = null;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Activation__c = null;
        //oppTemp1.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp3);
      
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = '';
        oppTemp4.Sub_Segment__c = '';
        oppTemp4.Territory__c = null;
        oppTemp4.Channel__c = 'On Trade';
        oppTemp4.End_Date__c = null;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        //oppTemp2.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp4);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
    
     @isTest
    public static void testCreateOpportunityForCountry(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Region__c = geoMap.get('Region');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Country');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        //oppTemp1.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp1);
      
        
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
    
    @isTest
    public static void testCreateOpportunityForCountryRegion(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c= 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Region__c = geoMap.get('Region');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Country');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        oppTemp1.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp1);
      
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Country');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        oppTemp2.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Country');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = '';
        oppTemp3.Sub_Segment__c = '';
        oppTemp3.Territory__c = null;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Activation__c = null;
        oppTemp3.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp3);
      
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Country');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = '';
        oppTemp4.Sub_Segment__c = '';
        oppTemp4.Territory__c = null;
        oppTemp4.Channel__c = '';
        oppTemp4.End_Date__c = null;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        oppTemp4.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp4);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
    
    @isTest
    public static void testCreateOpportunityForCountryArea(){
      
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c= 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Area__c = geoMap.get('Area');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Country');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        oppTemp1.Area_Region__c = geoMap.get('Area');
        opportunityTempList.add(oppTemp1);
      
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Country');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        oppTemp2.Area_Region__c = geoMap.get('Area');
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Country');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = '';
        oppTemp3.Sub_Segment__c = '';
        oppTemp3.Territory__c = null;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Activation__c = null;
        oppTemp3.Area_Region__c = geoMap.get('Area');
        opportunityTempList.add(oppTemp3);
      
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Country');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = '';
        oppTemp4.Sub_Segment__c = '';
        oppTemp4.Territory__c = null;
        oppTemp4.Channel__c = '';
        oppTemp4.End_Date__c = null;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        oppTemp4.Area_Region__c = geoMap.get('Area');
        opportunityTempList.add(oppTemp4);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
    @isTest
    public static void testCreateOpportunityForHub(){
       
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
       
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c= 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Region__c = geoMap.get('Region');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Hub');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        //oppTemp1.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp1);
        
       Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Country');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        //oppTemp2.Area_Region__c = geoMap.get('Area');
        opportunityTempList.add(oppTemp2);
        
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
    @isTest
    public static void testCreateOpportunityForMarket(){
      
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c= 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Region__c = geoMap.get('Region');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        Test.startTest();
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Market');
        oppTemp1.Opportunity_Type__c = 'MPA';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'Manual Value';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = '';
        oppTemp1.Sub_Segment__c = '';
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        //oppTemp1.Area_Region__c = geoMap.get('Region');
        opportunityTempList.add(oppTemp1);
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Country');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = '';
        oppTemp2.Sub_Segment__c = '';
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        //oppTemp2.Area_Region__c = geoMap.get('Area');
        opportunityTempList.add(oppTemp2);

        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';      
        
        insert outExecObj;
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
  }
   @isTest
    public static void testCreateOpportunitySegmentTerr(){ 
        
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c= 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
        Account accObj = EDGE_UtilityTestClass.getOutletRecord();
        accObj.Country__c = countryId;
        accObj.Outlet_Visit_Prioritisation_Grade__c = oultlVstPriPkUp.Id;
        accObj.Primary_Sales_Territory__c = primaryTerr.Id;
        accObj.Global_Channel__c = 'On Trade';
        accObj.Global_Sub_Channel__c = 'On Trade';
        accObj.Global_Segment__c = 'Nightclub';
        accObj.Global_Sub_Segment__c = 'Modern Nightclub';
        accObj.Region__c = geoMap.get('Region');
        insert accObj;
        
        Outlet_Territory__c outlTer = EDGE_UtilityTestClass.getOutltTerritory(accObj.Id, primaryTerr.Id);
        insert outlTer;
        
        Test.startTest();
        
        Product__c prodObj = EDGE_UtilityTestClass.getProd();
        prodObj.Description__c='Johnny Walker';
        prodObj.Type__c = 'Diageo Product';       
        insert prodObj;
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = 'Nightclub';
        oppTemp1.Sub_Segment__c = null;//'Modern Nightclub'
        oppTemp1.Territory__c = primaryTerr.Id;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = 'Nightclub';
        oppTemp2.Sub_Segment__c = null;
        oppTemp2.Territory__c = primaryTerr.Id;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = 'Nightclub';
        oppTemp3.Sub_Segment__c = null;
        oppTemp3.Territory__c = primaryTerr.Id;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Activation__c = null;
        opportunityTempList.add(oppTemp3);
      
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = 'Nightclub';
        oppTemp4.Sub_Segment__c = null;
        oppTemp4.Territory__c = primaryTerr.Id;
        oppTemp4.Channel__c = '';
        oppTemp4.End_Date__c = null;
        oppTemp4.Product__c = null;
        oppTemp4.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp4);
        
        insert opportunityTempList;
        
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';      
        
        insert outExecObj;
        
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        Test.stopTest();
    }
    
     @isTest
    public static void testCreateOpportunityForSegment(){
        //EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        System.assert(countryId != null,'countryId should not be null');
        
        Map<String,Id> geoMap = EDGE_UtilityTestClass.getGeoMap();
        List<Opportunity_Template__c> opportunityTempList = new List<Opportunity_Template__c>();
        
        EDGE_UtilityTestClass.createOrgSettings();
        Pick_Up_Options__c oultlVstPriPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'Outlet Visit Prioritization');
        insert oultlVstPriPkUp;
        System.assert(oultlVstPriPkUp.Id != null,'oultlVstPriPkUp should not be null');
        
        Pick_Up_Options__c masPkUp = EDGE_UtilityTestClass.getPickUpOption(countryId, 'MAS');
        masPkUp.RecordTypeId =pickupRecTypeId;
        masPkUp.Status__c ='Active';
        insert masPkUp;
        
        Territory__c primaryTerr = EDGE_UtilityTestClass.getTerritoryRec();
        primaryTerr.Territory_Type__c = 'Service';
        insert primaryTerr;
        System.assert(primaryTerr.Id != null,'primaryTerr should not be null');
        
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
        
        Opportunity_Template__c oppTemp1 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp1.Cluster__c = geoMap.get('Cluster');
        oppTemp1.Opportunity_Type__c = 'MAS';
        oppTemp1.Closing_Method__c = 'Trax';
        oppTemp1.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp1.Start_Date__c = System.today();
        oppTemp1.Action__c = 'TestAction';
        oppTemp1.Segment__c = 'Nightclub';
        oppTemp1.Sub_Segment__c = null;
        oppTemp1.Territory__c = null;
        oppTemp1.Channel__c = '';
        oppTemp1.End_Date__c = null;
        oppTemp1.Activation__c = null;
        opportunityTempList.add(oppTemp1);
      
        
        Opportunity_Template__c oppTemp2 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp2.Cluster__c = geoMap.get('Cluster');
        oppTemp2.Opportunity_Type__c = 'MAS';
        oppTemp2.Closing_Method__c = 'Trax';
        oppTemp2.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp2.Start_Date__c = System.today();
        oppTemp2.Action__c = 'TestAction';
        oppTemp2.Segment__c = 'Nightclub';
        oppTemp2.Sub_Segment__c = null;
        oppTemp2.Territory__c = null;
        oppTemp2.Channel__c = '';
        oppTemp2.End_Date__c = null;
        oppTemp2.Product__c = null;
        oppTemp2.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp2);
        
        Opportunity_Template__c oppTemp4 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp4.Cluster__c = geoMap.get('Cluster');
        oppTemp4.Opportunity_Type__c = 'MAS';
        oppTemp4.Closing_Method__c = 'Trax';
        oppTemp4.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp4.Start_Date__c = System.today();
        oppTemp4.Action__c = 'TestAction';
        oppTemp4.Segment__c = 'Nightclub';
        oppTemp4.Sub_Segment__c = null;
        oppTemp4.Territory__c = null;
        oppTemp4.Channel__c = '';
        oppTemp4.End_Date__c = null;
        oppTemp4.Activation__c = null;
        opportunityTempList.add(oppTemp4);
      
        
        Opportunity_Template__c oppTemp3 =  EDGE_UtilityTestClass.getOpportunityTemplate(prodObj.Id, primaryTerr.Id, countryId);
        oppTemp3.Cluster__c = geoMap.get('Cluster');
        oppTemp3.Opportunity_Type__c = 'MAS';
        oppTemp3.Closing_Method__c = 'Trax';
        oppTemp3.Weight_Type__c = 'MAS or MPA Weight';
        oppTemp3.Start_Date__c = System.today();
        oppTemp3.Action__c = 'TestAction';
        oppTemp3.Segment__c = 'Nightclub';
        oppTemp3.Sub_Segment__c = null;
        oppTemp3.Territory__c = null;
        oppTemp3.Channel__c = '';
        oppTemp3.End_Date__c = null;
        oppTemp3.Product__c = null;
        oppTemp3.Activation__c = masPkUp.Id;
        opportunityTempList.add(oppTemp3);
        
        insert opportunityTempList;
        
        Outlet_Execution__c outExecObj = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        outExecObj.Product__c = prodObj.Id;
        outExecObj.MAS__c = 'No';
        outExecObj.MPA__c = 'No';
        outExecObj.NPA__c = 'No';
        
        insert outExecObj;
        
        Outlet_Execution__c outExecObj1 = EDGE_UtilityTestClass.getOutletExecution(accObj.Id);
        String tempString = masPkUp.Name;
        String subString = tempString.substringBefore('[').trim();
        outExecObj1.Activation_Reference__c = subString;
        outExecObj1.MAS__c = 'No';
        outExecObj1.MPA__c = 'No';
        outExecObj1.NPA__c = 'No';
        
        insert outExecObj1;
        outExecObj.MAS__c = 'Yes';
        outExecObj.MPA__c = 'Yes';
        outExecObj.NPA__c = 'Yes';
        update outExecObj;
        Test.stopTest();
  }
    
  
}