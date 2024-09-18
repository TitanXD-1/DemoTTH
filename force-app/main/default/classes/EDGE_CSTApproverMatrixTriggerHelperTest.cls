/*
 * Class Name : EDGE_CSTApproverMatrixTriggerHelperTest
 * @description: This is to handle CST Approver Matrix test class
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        Sayan Mullick   		19/05/2021        Initial Development
*/



@isTest
public class EDGE_CSTApproverMatrixTriggerHelperTest {
    

	/*
	* @description : updateApproverUserTest
	* @return : void
	* @param : 
	*/ 

     @isTest
    public static void updateApproverUserTest()
    {
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Profile prof = [select id from profile where name=: 'System Administrator'];
        User usrmngr = new User();
        usrmngr.firstName = 'testManager';
        usrmngr.lastName = 't2';
        usrmngr.profileId = prof.id;        
        usrmngr.email = 'test.Manager@test.com';
        usrmngr.Username ='testcmMngr1@test.com';
        usrmngr.Alias='test';
        usrmngr.Timezonesidkey='America/Los_Angeles';
        usrmngr.LocaleSidKey='en_US';
        usrmngr.LanguageLocaleKey='en_US';
        usrmngr.EmailEncodingKey='UTF-8';
        usrmngr.Available_Countries__c='ES';
        insert usrmngr;
        Test.startTest();
        Sales_Organisation__c salesOrgTest1 = EDGE_UtilityTestClass.getsalesorgRecord(countryId);
        insert salesOrgTest1;
        
        Sales_Organisation__c salesOrgTest2 = EDGE_UtilityTestClass.getsalesorgRecord(null);
        insert salesOrgTest2;
        
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        appmatrix.CST_Sales_Organisation__c = salesOrgTest1.Id;
        appmatrix.Sales_Org__c = 'SEU';
        insert appmatrix;
        
        appmatrix.Approver_Email__c =  'test.Manager@test.com';
        appmatrix.CST_Sales_Organisation__c = salesOrgTest2.Id;
        update appmatrix;
        
        List<Approver_Matrix__c> listnewItems = new List<Approver_Matrix__c>();
        listnewItems.add(appmatrix);
        delete appmatrix;
        undelete appmatrix;
        Test.stopTest(); 
    }
    
    
     /*@isTest
     public static void sharingApproverMatrixTest()
     {
        EDGE_UtilityTestClass.createOrgSettings();
        Id countryId = EDGE_UtilityTestClass.setupCountry('SEU');
        Profile prof = [select id from profile where name=: 'System Administrator'];
       
        
         
        Test.startTest();
        Approver_Matrix__c appmatrix = EDGE_UtilityTestClass.getApproverMatrixRecord(countryId);
        Sales_Organisation__c salesOrgTest = EDGE_UtilityTestClass.getsalesorgRecord(countryId); //CST-315
        appmatrix.CST_Sales_Organisation__c = salesOrgTest.id; //CST-315
        
        
        insert appmatrix;
        appmatrix.Approver_Email__c =  'test.Mamager@test.com';
        Sales_Organisation__c salesOrgTest1 = EDGE_UtilityTestClass.getsalesorgRecord(countryId); //CST-315
        
        salesOrgTest1.Code__c='PL01'; //CST-315
        appmatrix.CST_Sales_Organisation__c = salesOrgTest1.id;//CST-315
        //appmatrix.Approval_Category__c = 'Customer Spend approval';
         
        update appmatrix;
        List<Approver_Matrix__c> listnewItems = new List<Approver_Matrix__c>();
        listnewItems.add(appmatrix);
       
        delete appmatrix;
        undelete appmatrix;
       
        Test.stopTest(); 
     }*/
}