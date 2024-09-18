/**
 * @description: This is the test class for D1_ProductRecommendationTriggerHelper
 * @name: D1_ProductRecommriggerHelperTest
 * @history
 * @version     Developer           Date            		Detail
 * 1.0          Pratap Sen     	  22-02-2023       NCP-7904 - Initial Development
*/
@isTest
public class D1_ProductRecommriggerHelperTest {
	/**
    * @name : setupData
    * @description : This method is used to create test data
    */
    @testSetup
    public static void setupData(){
        //Set up Admin User to Create Test Data
        UserRole userRole   =   [Select Id From UserRole Where Name = 'Global' Limit 1];
        User testAdminUser = D1_TestDataUtility.runAsUser('testAdmin','System Administrator');        
        testAdminUser.userRoleId = userRole.Id;
        insert testAdminUser; 
        
        System.runAs(testAdminUser){
            //Set Up Two Countries
            Id countryId = D1_TestDataUtility.setupCountry('GB');
            
            Geography__c countryGB = [SELECT Name, Code__c, Parent_Geography__c, isDiageoOneEnabled__c, RecordTypeId
                                      FROM Geography__c
                                      WHERE Id =: countryId LIMIT 1];
            Geography__c newCountry = countryGB.clone(false,false,false,false);
            newCountry.Name = 'Great Britain New';
            newCountry.Code__c = 'GB1';
            newCountry.isDiageoOneEnabled__c = true;
            insert newCountry;
            
            //Set Up Product Records
            Product2 masterProduct1 = D1_TestDataUtility.getProduct();
            masterProduct1.name = 'MasterProd1';
            masterProduct1.SAP_Material_Id__c = '0000012345';
            
            Product2 masterProduct2 = D1_TestDataUtility.getProduct();
            masterProduct2.name = 'MasterProd2';
            masterProduct2.SAP_Material_Id__c = '0000012346';
            
            Product2 recommProduct1 = D1_TestDataUtility.getProduct();
            recommProduct1.name = 'recommProduct1';
            recommProduct1.SAP_Material_Id__c = '0000012347';
            
            Product2 recommProduct2 = D1_TestDataUtility.getProduct();
            recommProduct2.name = 'recommProduct2';
            recommProduct2.SAP_Material_Id__c = '0000012348';
            
            List<Product2> prodList = new List<Product2>{masterProduct1, masterProduct2, recommProduct1, recommProduct2};
            insert prodList;
            
            D1_TestDataUtility.createOrgSettings();
        }
    }
    
    /**
    * @name : testUniqueKeyPopulation
    * @description : This method is used to test the populateUniqueKey() of the D1_ProductRecommendationTriggerHelper class
    */
    @isTest
    public static void testUniqueKeyPopulation(){
        //Add Product Recommendation Record to Insert
        Id recommProdRec = [SELECT Id FROM Product2 WHERE Name = 'recommProduct2' LIMIT 1].Id;
        Id masterProductRec = [SELECT Id FROM Product2 WHERE Name = 'MasterProd1' LIMIT 1].Id;
        Id countryRec = [SELECT Id FROM Geography__c WHERE Code__c = 'GB' LIMIT 1].Id;
        D1_Product_Recommendation__c prodRecommToInsert = D1_TestDataUtility.getProductRecomm(masterProductRec, recommProdRec, countryRec);
        
        //Add a duplicate Record to Insert
        D1_Product_Recommendation__c duplicateRec = prodRecommToInsert.clone(false, false, false, false);
        
        Test.startTest();
        	//Insert
        	insert prodRecommToInsert;

        	System.Assert([SELECT Unique_Key__c FROM D1_Product_Recommendation__c WHERE Id =: prodRecommToInsert.Id LIMIT 1].Unique_Key__c != NULL, 'UNIQUE KEY NOT POPULATED');
            Assert.isTrue([SELECT Unique_Key__c FROM D1_Product_Recommendation__c WHERE Id =: prodRecommToInsert.Id LIMIT 1].Unique_Key__c != NULL, 'UNIQUE KEY NOT POPULATED');
        	
        	//Update
        	prodRecommToInsert.Is_Active__c = false;
        	update prodRecommToInsert;

        	System.Assert([SELECT Unique_Key__c FROM D1_Product_Recommendation__c WHERE Id =: prodRecommToInsert.Id LIMIT 1].Unique_Key__c != NULL, 'UNIQUE KEY NOT POPULATED');
            Assert.isTrue([SELECT Unique_Key__c FROM D1_Product_Recommendation__c WHERE Id =: prodRecommToInsert.Id LIMIT 1].Unique_Key__c != NULL, 'UNIQUE KEY NOT POPULATED');

        	//Duplicate Restriction on Insert
        	try{
                insert duplicateRec;
            }
            Catch(Exception ex){
                System.Assert(duplicateRec.Id == NULL, 'UNIQUE KEY DOESNOT RESTRICT DUPLICATE INSERTION');
                Assert.isTrue(duplicateRec.Id == NULL, 'UNIQUE KEY DOESNOT RESTRICT DUPLICATE INSERTION');
            }
        Test.stopTest();
    }
    
    /**
    * @name : testSharing
    * @description : This method is used to test the checkAndGenerateSharing() of the D1_ProductRecommendationTriggerHelper class
    */
    @isTest
    public static void testSharing(){
        //Add Product Recommendation Record to Insert
        Id recommProdRec = [SELECT Id FROM Product2 WHERE Name = 'recommProduct2' LIMIT 1].Id;
        Id masterProductRec = [SELECT Id FROM Product2 WHERE Name = 'MasterProd1' LIMIT 1].Id;
        Id countryGB = [SELECT Id FROM Geography__c WHERE Code__c = 'GB' LIMIT 1].Id;
        D1_Product_Recommendation__c prodRecommRec = D1_TestDataUtility.getProductRecomm(masterProductRec, recommProdRec, countryGB);
        
        //Fetch Different Country
        Id countryGB1 = [SELECT Id FROM Geography__c WHERE Code__c = 'GB1' LIMIT 1].Id;
        
        Test.startTest();
        	//Sharing on Insert
        	insert prodRecommRec;

        	System.Assert([SELECT Id FROM D1_Product_Recommendation__Share  WHERE parentId =: prodRecommRec.Id LIMIT 1].Id != NULL, 'SHARING FAILED ON INSERT');
            Assert.isTrue([SELECT Id FROM D1_Product_Recommendation__Share  WHERE parentId =: prodRecommRec.Id LIMIT 1].Id != NULL, 'SHARING FAILED ON INSERT');
        	
        	//Remove Previous Sharing on Geography Update
        	prodRecommRec.Country__c = countryGB1;
        	update prodRecommRec;
        Test.stopTest();
    }
}