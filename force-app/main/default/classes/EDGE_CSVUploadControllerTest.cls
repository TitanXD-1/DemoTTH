/**********************************************************************
  Name : EDGE_CSVUploadControllerTest
=======================================================================
  Purpose : Test Class for below Classes:
                    EDGE_CSVUploadController
                    EDGE_CSVRowIterator
                    EDGE_CSVFileParser
                    EDGE_CSVFileProcessBatch
                    EDGE_CSVFileProcessBatchHelper
                    EDGE_BulkDataImportTrackerDML
                    EDGE_CSVFileProcessBatchWrapper
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    21-02-2019        Initial Development
***********************************************************************/ 
@isTest
public with sharing class EDGE_CSVUploadControllerTest {
    //This method is used to Create Outlet Territory Record
    @isTest
    public static void testNewOutletTerriCreate(){
        EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active';      
        insert outlet;  
        System.assert(outlet.Id != null,'outlet inserted');
        Account outletNew = EDGE_UtilityTestClass.getOutletRecord(); 
        outletNew.Name = 'Test CSV Upload';
        outletNew.Status__c = 'New';      
        insert outletNew;  
        System.assert(outletNew.Id != null,'outletNew inserted');
        Account ownrAccObj = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        insert ownrAccObj;  
        System.assert(ownrAccObj.Id != null,'ownrAccObj inserted');
        Territory__c territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        insert territoryObj;
        System.assert(territoryObj.Id != null,'territoryObj inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Territory Id\n';
        csvVal = outlet.Id + ',' + territoryObj.Id + '\n';
        csvVal = csvVal +ownrAccObj.Id+ ',' + territoryObj.Id + '\n';
        csvVal = csvVal +outletNew.Id+ ',' + territoryObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('Territory', base64value, true);
        Test.stopTest();
        List<Outlet_Territory__c> outLetTerriObj = [SELECT Id,Active__c FROM Outlet_Territory__c 
                                                    WHERE Outlet__c =:outlet.Id 
                                                        AND Territory__c =:territoryObj.Id];
        System.assertEquals('Waiting Activation', outLetTerriObj[0].Active__c,'Waiting Activation should match');
    }
    //This method is used to Delete Outlet Territory Record
    @isTest
    public static void testOutletTerriDelete(){
        EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();       
        insert outlet;  
        System.assert(outlet.Id != null,'outlet inserted');
        Account outletNew = EDGE_UtilityTestClass.getOutletRecord(); 
        outletNew.Name = 'Test CSV Upload';
        outletNew.Status__c = 'New';      
        insert outletNew;  
        System.assert(outletNew.Id != null,'outletNew inserted');
        Territory__c territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        insert territoryObj;
        System.assert(territoryObj.Id != null,'territoryObj inserted');
        Outlet_Territory__c getOutltTerritory = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id,territoryObj.Id);
        insert getOutltTerritory;
        System.assert(getOutltTerritory.Id != null,'getOutltTerritory inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Territory Id\n';
        csvVal = outlet.Id + ',' + territoryObj.Id + '\n';
        csvVal = csvVal + outletNew.Id + ',' + territoryObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('Territory', base64value, false);
        Test.stopTest();
        List<Outlet_Territory__c> outLetTerriObj = [SELECT Id,Active__c FROM Outlet_Territory__c 
                                                    WHERE Outlet__c =:outlet.Id 
                                                        AND Territory__c =:territoryObj.Id];
        System.assertEquals('Waiting Removal', outLetTerriObj[0].Active__c,'Waiting Removal should match');
    }
    //This method is used to check Existing Outlet Territory Record
    @isTest
    public static void testExistingOutletTerriCreate(){
        EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        outlet.Status__c = 'Active';       
        insert outlet;  
        System.assert(outlet.Id != null,'outlet inserted');
        Territory__c territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        insert territoryObj;
        System.assert(territoryObj.Id != null,'territoryObj inserted');
        Outlet_Territory__c getOutltTerritory = EDGE_UtilityTestClass.getOutltTerritory(outlet.Id,territoryObj.Id);
        insert getOutltTerritory;
        System.assert(getOutltTerritory.Id != null,'getOutltTerritory inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Territory Id\n';
        csvVal = outlet.Id + ',' + territoryObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('Territory', base64value, true);
        Test.stopTest();
    }
    //This method is used to Create Target List Member Record
    @isTest
    public static void testNewTrgtLstMemCreate(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet;
        System.assert(outlet.Id != null,'outlet inserted');
        Account ownrAccObj = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        insert ownrAccObj;
        System.assert(ownrAccObj.Id != null,'ownrAccObj inserted');
        Id stcRecordTypeId = Schema.SObjectType.Target_List__c.getRecordTypeInfosByName().get('Static Target List').getRecordTypeId();
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        trgtLstObj.RecordTypeId = stcRecordTypeId;
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null,'trgtLstObj inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Target Member Id\n';
        csvVal = outlet.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvVal + ownrAccObj.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, true);
        Test.stopTest();
        List<Target_List_Member__c> trgtLstMemObj = [SELECT Id,Assignment_Status__c FROM Target_List_Member__c 
                                                        WHERE Outlet__c =:outlet.Id 
                                                        AND Target_List__c =:trgtLstObj.Id];
        System.assertEquals('Waiting Activation', trgtLstMemObj[0].Assignment_Status__c,'Waiting Activation should match');
    }
    //This method is used to Delete Target List Member Record
    @isTest
    public static void testTrgtLstMemDelete(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet;  
        System.assert(outlet.Id != null,'outlet inserted');
        Account outletNew = EDGE_UtilityTestClass.getOutletRecord(); 
        outletNew.Name = 'Test CSV Upload';
        outletNew.Status__c = 'New';      
        insert outletNew;
        System.assert(outletNew.Id != null,'outletNew inserted');
        Id stcRecordTypeId = Schema.SObjectType.Target_List__c.getRecordTypeInfosByName().get('Static Target List').getRecordTypeId();
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        trgtLstObj.RecordTypeId = stcRecordTypeId;
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null,'trgtLstObj inserted');
        
        Target_List_Member__c trgtLstMbrObj = EDGE_UtilityTestClass.getTargetMemList(outlet.Id,trgtLstObj.Id);
        insert trgtLstMbrObj;
        System.assert(trgtLstMbrObj.Id != null,'trgtLstMbrObj inserted');
        
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Target Member Id\n';
        csvVal = outlet.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvVal + outletNew.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, false);
        Test.stopTest();
        List<Target_List_Member__c> trgtLstMemObj = [SELECT Id,Assignment_Status__c FROM Target_List_Member__c 
                                                        WHERE Outlet__c =:outlet.Id 
                                                        AND Target_List__c =:trgtLstObj.Id];
        System.assertEquals('Waiting Removal', trgtLstMemObj[0].Assignment_Status__c,'Waiting Removal should match');
    }
    //This method is used to Check Existing Target List Member Record
    @isTest
    public static void testExstngTrgtLstMemCreate(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet; 
        System.assert(outlet.Id != null,'outlet inserted');
        
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null,'trgtLstObj inserted');
        Target_List_Member__c trgtLstMbrObj = EDGE_UtilityTestClass.getTargetMemList(outlet.Id,trgtLstObj.Id);
        insert trgtLstMbrObj;
        System.assert(trgtLstMbrObj.Id != null,'trgtLstMbrObj inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Target Member Id\n';
        csvVal = outlet.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, true);
        Test.stopTest();
    }
    //This method is used to Check CSV Format
    @isTest
    public static void testCSVFormat(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet; 
        System.assert(outlet.Id != null,'outlet inserted');
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null,'trgtLstObj inserted');
        Target_List_Member__c trgtLstMbrObj = EDGE_UtilityTestClass.getTargetMemList(outlet.Id,trgtLstObj.Id);
        insert trgtLstMbrObj;
        System.assert(trgtLstMbrObj.Id != null,'trgtLstMbrObj inserted');
        String csvVal;
        String csvHeaderVal = '"Outlet Id",Target Member Id\n';
        csvVal = outlet.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, true);
        Test.stopTest();
    }
    //This method is used to Check CSV Format
    @isTest
    public static void testCSVFormatEndDBLQT(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet; 
        System.assert(outlet.Id != null,'outlet inserted');
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null,'trgtLstObj inserted');
        Target_List_Member__c trgtLstMbrObj = EDGE_UtilityTestClass.getTargetMemList(outlet.Id,trgtLstObj.Id);
        insert trgtLstMbrObj;
        System.assert(trgtLstMbrObj.Id != null,'trgtLstMbrObj inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id",Target Member Id\n';
        csvVal = outlet.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, true);
        Test.stopTest();
    }
    //This method is used to Check CSV Format
    @isTest
    public static void testCSVFormatStrtDBLQT(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet; 
        System.assert(outlet.Id != null,'outlet inserted'); 
        Target_List__c trgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        insert trgtLstObj;
        System.assert(trgtLstObj.Id != null,'trgtLstObj inserted');
        Target_List_Member__c trgtLstMbrObj = EDGE_UtilityTestClass.getTargetMemList(outlet.Id,trgtLstObj.Id);
        insert trgtLstMbrObj;
        System.assert(trgtLstMbrObj.Id != null,'trgtLstMbrObj inserted');
        String csvVal;
        String csvHeaderVal = 'Outlet Id,"Target Member Id\n';
        csvVal = outlet.Id + ',' + trgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, true);
        Test.stopTest();
    }
    //This method is used to EncodingUtil
    public static String encode64Data(String csvString){
        Blob blobCSVVal = Blob.valueOf(csvString);
        string base64value = EncodingUtil.base64Encode(blobCSVVal);
        return base64value;
    }
    @isTest
    public static void testCSVRowIterator(){
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Territory Id\n';
        csvVal = 'Outlet Id, Territory Id\n';
        csvVal = csvHeaderVal+csvVal;
        System.assert(csvVal!= null,'csvVal should not be null');

    }
    @isTest
    public static void testGetCSVTemp(){
        String docuName = 'Test Document';
        Document docuObj = EDGE_UtilityTestClass.getDocument(docuName);
        insert docuObj;
        System.assert(docuObj.Id != null,'docuObj inserted');
        Id docuId = EDGE_CSVUploadController.getCSVTemp(docuName);
        System.assert(docuId != null,'docuId should match');
    }
    @isTest
    public static void testDynamicTrgtListCreate(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert outlet; 
        System.assert(outlet.Id != null,'outlet inserted');
        Id dynaRecordTypeId = Schema.SObjectType.Target_List__c.getRecordTypeInfosByName().get('Dynamic Target List').getRecordTypeId();
        Target_List__c dynaTrgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        dynaTrgtLstObj.RecordTypeId = dynaRecordTypeId;
        insert dynaTrgtLstObj;
        System.assert(dynaTrgtLstObj.Id != null,'dynaTrgtLstObj inserted');
        
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Target Member Id\n';
        csvVal = outlet.Id + ',' + dynaTrgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, true);
        Test.stopTest();
        
    }
    @isTest
    public static void testDynamicTrgtListDelete(){
        ID countryId   = EDGE_UtilityTestClass.setupCountry('AUS');
        Account outlet = EDGE_UtilityTestClass.getOutletRecord(); 
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        insert pickupOption;
        outlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        outlet.Country__c = countryId;
        insert outlet;  
        System.assert(outlet.Id != null,'outlet inserted');
        Id dynaRecordTypeId = Schema.SObjectType.Target_List__c.getRecordTypeInfosByName().get('Dynamic Target List').getRecordTypeId();
        Target_List__c dynaTrgtLstObj = EDGE_UtilityTestClass.getTargetList(countryId);
        dynaTrgtLstObj.RecordTypeId = dynaRecordTypeId;
        insert dynaTrgtLstObj;
        System.assert(dynaTrgtLstObj.Id != null,'dynaTrgtLstObj inserted');
        
        Target_List_Member__c trgtLstMbrObj = EDGE_UtilityTestClass.getTargetMemList(outlet.Id,dynaTrgtLstObj.Id);
        insert trgtLstMbrObj;
        System.assert(trgtLstMbrObj.Id != null,'trgtLstMbrObj inserted');
        
        String csvVal;
        String csvHeaderVal = 'Outlet Id, Target Member Id\n';
        csvVal = outlet.Id + ',' + dynaTrgtLstObj.Id + '\n';
        csvVal = csvHeaderVal+csvVal;
        string base64value = EDGE_CSVUploadControllerTest.encode64Data(csvVal);
        Test.startTest();
        EDGE_CSVUploadController.processData('TargetList', base64value, false);
        Test.stopTest();
    }
}