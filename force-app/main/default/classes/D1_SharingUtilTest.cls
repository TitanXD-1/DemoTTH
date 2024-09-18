/**
 * @name : D1_SharingUtilTest
 * @description : Test class for D1_SharingUtil
 * @history
 * VERSION      AUTHOR             DATE            DETAIL
 * 1.0         D1 Dev Team
**/
@isTest
public class D1_SharingUtilTest {
    /**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');
        testAdminUser.isActive = true;
        testAdminUser.userRoleId = [SELECT Id FROM UserRole WHERE Name = 'Global' LIMIT 1].Id;
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            //set up two country under same parent geography
            Id countryId = EDGE_UtilityTestClass.setupCountry('AUT3');                                                
            Geography__c countryGB = [SELECT Name, Code__c, Parent_Geography__c, Extended_Country_Code__c, isDiageoOneEnabled__c,
                                      Enable_E_Commerce__c, RecordTypeId, Flag_Content_Document_ID__c, Flag_Content_Version_Id__c
                                      FROM Geography__c
                                      WHERE Name = 'Australia' LIMIT 1];
            Geography__c newCountry = countryGB.clone(false,false,false,false);
            newCountry.Name = 'Great Britain New';
            newCountry.Code__c = 'GB1';
            newCountry.isDiageoOneEnabled__c = true;
            insert newCountry;
            
            //Set up Object to test sharing
            Master_Bundle__c masterBundle = new Master_Bundle__c();
            masterBundle.Name = 'Test Master Bundle';
            masterBundle.Description__c = 'Test description';
            masterBundle.Country__c = countryId;
            masterBundle.Active__c = TRUE;
            insert masterBundle;
            
            //Set up Org Settings to Enable Trigger
            EDGE_UtilityTestClass.createOrgSettings();
        }
    }
    
    /**
    * @name : sharingOnInsertTest
    * @description : This method is used to test generateSharingFromGeography() from D1_SharingUtil
    */
    @isTest
    public static void sharingOnInsertTest(){
        Test.startTest();
        Geography__c country=[Select Id,D1_External_Group_Name__c,isDiageoOneEnabled__c,RecordType.Name from Geography__c where Name = 'Australia' AND Code__c = 'AUT3' LIMIT 1];
        country.isDiageoOneEnabled__c = true;
        update country;
        KPI_RAG_Threshold__c objKPIRAG = EDGE_UtilityTestClass.getOutletKPIRAG(country.Id);
        insert objKPIRAG;
        System.assert(objKPIRAG != null,'assertion failed');
        
        List<KPI_RAG_Threshold__c> newItems = new List<KPI_RAG_Threshold__c>();       
        newItems.add(objKPIRAG);        
        
        D1_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Edit');
        D1_SharingUtil.updateSharingRecords(newItems, newItems, 'Country__c');
        
        List<Master_Bundle__Share> sharingList = new List<Master_Bundle__Share>();
        Master_Bundle__c masterBundle = [SELECT Id, Name, Description__c, Country__c, Active__c FROM Master_Bundle__c LIMIT 1];
        Master_Bundle__c masterBundleToInsert = masterBundle.clone(false, false, false, false);
        insert masterBundleToInsert;
                
        sharingList = [Select Id from Master_Bundle__Share WHERE ParentId =: masterBundleToInsert.Id ];
        System.Assert(sharingList.size() != 0 , 'SHARING NOT CREATED ON INSERT');
        Assert.isTrue(sharingList.size() != 0 , 'SHARING NOT CREATED ON INSERT');
        
        Test.stopTest();
        
    }
    
     /**
    * @name : sharingOnUpdateTest
    * @description : This method is used to test updateSharingRecords() from D1_SharingUtil
    */
    @isTest
    public static void sharingOnUpdateTest(){
        List<Master_Bundle__Share> sharingList = new List<Master_Bundle__Share>();
        Id newGeography = [SELECT Id FROM Geography__c WHERE Name = 'Great Britain New' AND Code__c = 'GB1' LIMIT 1].Id;                               
        Test.startTest();               
        Master_Bundle__c masterBundle = [SELECT Id, Name, Description__c, Country__c, Active__c FROM Master_Bundle__c LIMIT 1];
        masterBundle.Country__c = newGeography;
        update masterBundle;            
        Test.stopTest();        
        sharingList = [Select Id from Master_Bundle__Share WHERE ParentId =: masterBundle.Id ];
        System.Assert(sharingList.size() != 0 , 'SHARING NOT CREATED ON UPDATE');
        Assert.isTrue(sharingList.size() != 0 , 'SHARING NOT CREATED ON UPDATE');
    }
    
    
}