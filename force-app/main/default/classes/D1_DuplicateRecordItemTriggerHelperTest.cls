/*
* @name: D1_DuplicateRecordItemTriggerHelperTest
* @discription : Test Class for D1_DuplicateRecordItemTriggerHelper
* @history                                                                                                                        
* VERSION    AUTHOR              DATE              DETAIL
* 1.0        Saurav Paul         05/03/2021			-
* 2.0		 Rubeena			 29/06/2021		Test Class Refractor [NCP-3781]	
* */

@isTest
public class D1_DuplicateRecordItemTriggerHelperTest {

    @isTest
    public static void testPopulateRecordType(){

        Id countryId = D1_TestDataUtility.setupCountry('IE');
        
		Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[IE]');
        insert pickupOption;
        
        D1_TestDataUtility.createOrgSettings();
        
        Account testOutlet = D1_TestDataUtility.getD1Customer();
        testOutlet.Name = 'Sample outlet 1';
        testOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        insert testOutlet;
        
        DuplicateRule dR = [SELECT Id FROM DuplicateRule WHERE DeveloperName = :Label.D1_Account_Duplicate_Exclusion  LIMIT 1];
        DuplicateRecordSet dupRS = new DuplicateRecordSet(DuplicateRuleId = dR.id);
        insert dupRS;
        
        testOutlet.name='sample';
        testOutlet.KUNNR__c = '987965';
        update testOutlet;

        Test.startTest();
        Account testDupOutlet = D1_TestDataUtility.getD1Customer();
        testDupOutlet.Name = 'Sample outlet 1';
        testDupOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id; 
        
        Database.DMLOptions insertDML = new Database.DMLOptions(); 
        insertDML.DuplicateRuleHeader.AllowSave = true; 
        Database.insert(testDupOutlet, insertDML);
        DuplicateRecordItem dup = new DuplicateRecordItem(DuplicateRecordSetId = dupRS.id, RecordId=testDupOutlet.id);
        insert dup;
        dup.RecordType_Name__c = 'Test';
        update dup;
        delete dup;
        undelete dup;
        Test.stopTest();
        List<DuplicateRecordItem> dupList = new List<DuplicateRecordItem>();
        dupList = [SELECT Id,RecordType_Name__c FROM DuplicateRecordItem WHERE Id =: dup.Id];
        System.assertEquals('Test', dupList[0].RecordType_Name__c, 'duplicate record item found');
    }
    
}