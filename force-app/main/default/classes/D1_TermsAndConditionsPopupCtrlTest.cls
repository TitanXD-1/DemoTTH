/**
 * @name D1_TermsAndConditionsPopupCtrlTest
 * @purpose Test Class for D1_TermsAndConditionsPopupCtrl
 * @history
 * VERSION     AUTHOR           DATE        DETAIL
 * 1.0			  -		   	      -				-
 * 2.0			Divya		   	30/06/2021	Test Class Refractor [NCP-3786]
 * 3.0			Sayan			07/09/2021	NCP-4399
 * 4.0			Sayan			31/01/2022	NCP-5435
**/
@istest
public with sharing class D1_TermsAndConditionsPopupCtrlTest {
    /*Declare RecordType Ids*/
    private static final Id D1TC_JMLRECID = D1_TestDataUtility.getRecordTypeIdByName('D1_Terms_Conditions__c', 'JML');
    private static final Id D1TC_ORDERRECID = D1_TestDataUtility.getRecordTypeIdByName('D1_Terms_Conditions__c', 'Order Terms and Condition');
    
    /**
    * @name : setupData
    * @description : This method is used to create test data for D1_TermsAndConditionsPopupCtrl
    */  
    @testSetup
    public static void setupData(){
        //Setup Country
        Id countryId = D1_TestDataUtility.setupCountry('GB');
        
        //Setup Pickup Option
        Pick_Up_Options__c pickupOption = D1_TestDataUtility.getPickUpOption(countryId,'Outlet Prioritization','Outlet Visit Prioritization','Gold[GB]');
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        //Setup D1 Customer Account
        Account testOutlet = D1_TestDataUtility.getD1Customer();
        testOutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
        testOutlet.Direct_Customer__c = false;
        insert testOutlet;
        
        //Setup External User - Also adds Primary Contact, Sales Area, D1 Settings
        D1_TestDataUtility.setUpExternalUser(testOutlet,'Outlet/Retailers');
        
        //Set up Order Split
        OrderSplit__c oSpilt = D1_TestDataUtility.insertOrderSplit();
        Assert.isNotNull(oSpilt.Id, 'ORDER SPLIT NOT FOUND');
        
        //Query D1 Settings, Sales Areaa and Set up Terms_Conditions of Record Types 'JML' & 'Order Terms and Condition'
        D1_Setting__c d1Sttng = [SELECT Id FROM D1_Setting__c LIMIT 1];
        Id salesAreaId = [SELECT Id, Sales_Area__c FROM OrderSplit__c WHERE Market_Description__c = 'Keg' LIMIT 1].Sales_Area__c;
        
        D1_Terms_Conditions__c termsCondRecJML = D1_TestDataUtility.insertD1TermsConditions(d1Sttng);
        termsCondRecJML.RecordTypeId = D1TC_JMLRECID;
        termsCondRecJML.Sales_Area__c = null;
        termsCondRecJML.Status__c = 'Active';
        
        D1_Terms_Conditions__c termsCondRecORDR = D1_TestDataUtility.insertD1TermsConditions(d1Sttng);
        termsCondRecORDR.Version__c = 10;
        termsCondRecORDR.Sales_Area__c = salesAreaId;
        termsCondRecORDR.Status__c = 'Active';
        
        List<D1_Terms_Conditions__c> termsCondList = new List<D1_Terms_Conditions__c>{termsCondRecJML, termsCondRecORDR};
        insert termsCondList;
		
        //Set Up D1 Contact Agreement For Both D1_Terms_Conditions__c
        Contact prmCon = [SELECT Id FROM Contact WHERE Contact_Type__c = 'Primary' AND AccountId =: testOutlet.Id LIMIT 1];
        
        D1_Contact_Agreement__c conAgree = D1_TestDataUtility.getContactAgreement(termsCondRecORDR);             
        conAgree.JML_Accepted_Time__c = System.now();
        conAgree.Account__c = testOutlet.Id;
        conAgree.Contact__c = prmCon.Id;          
        insert conAgree;
    }
    
    /**
    * @name : testGetD1TermsAndConditions
	* @Description : This method is used to test the getJMLConditionsForFirstTimeLogin() & getJMLOrderConditions() method of the D1_TermsAndConditionsPopupCtrl class
	*/
    @isTest
    public static void testGetD1TermsAndConditions(){
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        OrderSplit__c oSpilt = [SELECT Id FROM OrderSplit__c WHERE Market_Description__c = 'Keg' LIMIT 1];
        D1_Terms_Conditions__c termsCondORDR;
        
        System.runAs(testUser){
            Test.startTest();
                D1_TermsAndConditionsPopupCtrl.getJMLConditionsForFirstTimeLogin();//NCP-4399
            
                D1_TermsAndConditionsPopupCtrl.getJMLOrderConditions('JML', null);                       
                termsCondORDR = D1_TermsAndConditionsPopupCtrl.getJMLOrderConditions('Order Terms and Condition', oSpilt.Id);   
            Test.stopTest();
            
            System.Assert(termsCondORDR != NULL, 'ORDER NOT FOUND');
            Assert.isNotNull(termsCondORDR, 'ORDER NOT FOUND');
        }
    }
    
    /**
	* @name : testSetD1TermsAndConditions
	* @Description : This method is used to test the setJMLConditions() method of the D1_TermsAndConditionsPopupCtrl class
	*/
    @isTest
    public static void testSetD1TermsAndConditions(){
        User testUser = [SELECT Id FROM User WHERE Profile.Name = 'DiageoOne External User' AND UserName = 'testclassextuser1@testdomain.com' LIMIT 1];
        D1_Terms_Conditions__c termsCondRecJML = [SELECT Id FROM D1_Terms_Conditions__c WHERE RecordTypeId =: D1TC_JMLRECID LIMIT 1];
        D1_Terms_Conditions__c termsCondRecORDR = [SELECT Id FROM D1_Terms_Conditions__c WHERE RecordTypeId =: D1TC_ORDERRECID LIMIT 1];
        Boolean setJML = False;
        
        System.runAs(testUser){
            Test.startTest();
                setJML = D1_TermsAndConditionsPopupCtrl.setJMLConditions(termsCondRecJML.Id);
                D1_TermsAndConditionsPopupCtrl.setJMLConditions(termsCondRecORDR.Id);
                D1_TermsAndConditionsPopupCtrl.setJMLConditions(null);  
            Test.stopTest();
            
            System.Assert(setJML = True, 'JML NOT SET');
            Assert.isTrue(setJML, 'JML NOT SET');
        }
    }
}