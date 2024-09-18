/**
 * @name : D1_VFLoginFlowControllerTest
 * @description : Test class for D1_VFLoginFlowController
 * @author : Gaurav Singh
 * @since 
 * @history
 * VERSION      AUTHOR                  DATE            DETAIL
 * 1.0          Gaurav Singh                            Initial Development(NCP-)
 * 2.0          Sayan Samaddar          12/07/2022      NCP-7157
 * 3.0          Kapil Baliyan           30/10/2022      NCP-7563
 */

@isTest
public class D1_VFLoginFlowControllerTest {

    /**
     * @description : Method to setup Test Data
     */
	@testSetup 
    public static void dataSetup(){
        Test.startTest();
        Account account = D1_TestDataUtility.getDirectCustomer();
        D1_TestDataUtility.setUpExternalUser(account, 'Direct Buyer');
        User externalUser11 = [SELECT Id, Username, ContactId, Available_Countries__c,LanguageLocaleKey 
                               FROM User WHERE username ='testclassextuser1@testdomain.com' LIMIT 1];
        
        D1_Setting__c d1S = [SELECT Id,Language__c FROM D1_Setting__c WHERE Market__r.Code__c = 'GB' AND 
                             Language__c = :externalUser11.LanguageLocaleKey LIMIT 1]; 
        d1S.Language__c = externalUser11.LanguageLocaleKey;
        d1S.D1_Lite_Version__c = true;
        update d1S;
        Test.stopTest();
    }
    
    /**
     * @description : Method to test login flow
     */
    @isTest
    public static void loginTest(){
        User externalUser1 = [SELECT Id,Username,Profile_Name__c FROM User where Profile_Name__c ='DiageoOne External User'
                              AND IsActive = true AND username ='testclassextuser1@testdomain.com' LIMIT 1];
        system.runAs(externalUser1){
            try {
                D1_VFLoginFlowController loginFlow = new D1_VFLoginFlowController();
                
                Test.startTest();
                PageReference pageRef = Page.D1_VFLoginFlow;
                Test.setCurrentPage(pageRef);
                PageReference pg = loginFlow.FinishLoginFlowHome();
                
                Test.stopTest();
                System.assertEquals(true, pg != null, 'PageReference is null');
            } catch(Exception ex) {
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
    }
    
    /**
     * @description : Method to test login lite flow
     */
    @isTest
    public static void loginLiteTest(){
        User externalUser1 = [SELECT Id,Username,Profile_Name__c FROM User where Profile_Name__c ='DiageoOne External User'
                              AND IsActive = true AND username ='testclassextuser1@testdomain.com' LIMIT 1];
        
        //Assign Permission Set
        List<PermissionSetAssignment> psaList = new List<PermissionSetAssignment>();
        for(PermissionSet ps : [SELECT Id FROM PermissionSet WHERE Name = 'B2B_Commerce_User']){
        	PermissionSetAssignment psa = new PermissionSetAssignment();
            psa.AssigneeId = externalUser1.Id;
            psa.PermissionSetId = ps.Id;
            
            psaList.add(psa);
        }
        
        insert psaList;
        
        system.runAs(externalUser1){
            try {
                D1_VFLoginFlowController loginFlow = new D1_VFLoginFlowController();
                Test.startTest();
                PageReference pageRef = Page.D1_VFLoginFlow;
                Test.setCurrentPage(pageRef);
                ApexPages.currentPage().getParameters().put('retURL', '/CommunitiesLanding');
                PageReference pg = loginFlow.FinishLoginFlowHome();
                Test.stopTest();
                System.assertEquals(true, pg != null, 'PageReference is null');
                
                //String d1LiteURL = D1_VFLoginFlowController.setStartURLForLite();
                //d1LiteURL = D1_VFLoginFlowController.setStartURLForLite();
            } catch(Exception ex) {
                System.debug(LoggingLevel.ERROR, ex.getMessage());
            }
        }
    }
    /**
     * @description : Method to test login lite flow
     */
    @isTest
    public static void startUrlLiteTest(){
        String linkText = D1_VFLoginFlowController.setStartURLForLite();
        Assert.isNotNull(linkText,'Link Test Data');
    }
    
}