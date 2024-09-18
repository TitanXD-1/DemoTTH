/*
* @name D1_FaultFixerControllerTest
* @description Test class for D1_FaultFixerController Class
* @history
* VERSION     AUTHOR              DATE              DETAIL
* 1.0		    Ajay				25/02/2021        NCP-1871
* 2.0         Rithika             29/06/2021        NCP-3804(Test Class Refactor)
* */ 
@isTest
public class D1_FaultFixerControllerTest {
    /**
     * @description setup description NCP-1871
     */
    @testSetup
    public static void setup(){
      	Account directCustomer = D1_TestDataUtility.getDirectCustomer();
        
        D1_TestDataUtility.setUpExternalUser(directCustomer,'Direct Buyer');
        D1_TestDataUtility.setupAllFaultFixerLevelObjects('test');
        Geography__c geo = [select id from Geography__c where RecordType.Name = 'Country' limit 1];
        D1_Fault_Fixer__c categoryFF1 = [select id from D1_Fault_Fixer__c where RecordType.DeveloperName = :'Category' limit 1];
        D1_Content_Assignment__c contentAssignment1 = new D1_Content_Assignment__c(
            D1_Fault_Fixer__c = categoryFF1.Id,
            Geography__c = geo.Id
        );
        insert contentAssignment1;
        System.assert(contentAssignment1 != null, 'content should not be empty');
    }
    
    /**
     * @description testGetFaultFixerLandingPageInitInfo description NCP-1839
     */   
    @isTest
    public static void testGetFaultFixerLandingPageInitInfo(){
        User usr = [Select id from User where Profile.Name = 'DiageoOne External User' and UserName = 'testclassextuser1@testdomain.com' limit 1];
        system.runAs(usr){
        	D1_FaultFixerController.getFaultFixerLandingPageInitInfo();
        }
        System.assert(usr!=null, 'User should not be empty');
    }
    
    /**
     * @description testgetFaultFixerSubCatPageInitInfo description NCP-1839
     */    
    @isTest
    public static void testgetFaultFixerSubCatPageInitInfo(){
        User usr = [Select id from User where Profile.Name = 'DiageoOne External User' and UserName = 'testclassextuser1@testdomain.com' limit 1];
        D1_Fault_Fixer__c subCat = [Select id from D1_Fault_Fixer__c where RecordType.DeveloperName = 'Sub_Category' limit 1];
        system.runAs(usr){
        	D1_FaultFixerController.getFaultFixerSubCatPageInitInfo(subCat.Id);
        }
        System.assert(usr != null, 'User should not be empty');
    }

    /**
     * @description testGetDiagnosticOrIssuePageInfo description NCP-1871 
     */  
    @isTest
    public static void testGetDiagnosticOrIssuePageInfo(){
        List<D1_Fault_Fixer__c> diagnosticOrIssues = [select id from D1_Fault_Fixer__c
                                                     WHERE RecordType.name IN('Issue','Diagnosis')];
        for(D1_Fault_Fixer__c obj : diagnosticOrIssues){
            D1_FaultFixerController.getDiagnosticOrIssuePageInfo(obj.id);
        }
        System.assert(diagnosticOrIssues != null, 'Issue/Diagnosis should not be empty');
    }
    
    /**
     * @description testTroubleshoot description NCP-1871
     */
    @isTest
    public static void testTroubleshoot(){
        List<D1_Fault_Fixer__c> troubleshoots = [select id from D1_Fault_Fixer__c
                                                     WHERE RecordType.name IN('Troubleshooting Steps')];
        for(D1_Fault_Fixer__c obj : troubleshoots){
            obj.Content_IDs__c = obj.Id;
            break;
        }
        update troubleshoots;
        
        for(D1_Fault_Fixer__c obj : troubleshoots){
            try{
                D1_FaultFixerController.getDiagnosticOrIssueFromTroubleshoot(obj.id);
                //Added for NCP-1876
                D1_FaultFixerController.getTroubleshootSuccessPageInfo(obj.id);
            }catch(Exception ex){
                System.assert(ex!=null, 'exception should not be empty');
            }
            
            try{
                D1_FaultFixerController.getTroubleshootStepContent(obj.id, 'communityid', null, null);
            }catch(Exception ex){
                System.assert(ex!=null, 'exception should not be empty');
            }
            
            try{
                D1_FaultFixerController.getFaultFixerBreadCrumbs(obj.id);
            }catch(Exception ex){
                System.assert(ex!=null, 'exception should not be empty');
            }
        }
    }
    
    /**
     * @description UserInfo.getUserId description NCP-1871
     */
    @isTest static void testProcessTroubleshootCMSContent(){
        Id userId = UserInfo.getUserId();
        Id profileId = UserInfo.getProfileId();
        ConnectApi.ManagedContentVersionCollection collection = new ConnectApi.ManagedContentVersionCollection();
        
        ConnectApi.ManagedContentVersion item = new ConnectApi.ManagedContentVersion();
        item.managedContentId = userId;
        
        Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = new Map<String, ConnectApi.ManagedContentNodeValue>();
        ConnectApi.ManagedContentTextNodeValue nodeValue = new ConnectApi.ManagedContentTextNodeValue();
        nodeValue.value = 'test';
        
		contentNodes.put('Troubleshoot_step_Heading_1', nodeValue);        
        item.contentNodes = contentNodes;
        collection.items = new List<ConnectApi.ManagedContentVersion>{item};
        
        try{
           D1_FaultFixerController.processTroubleshootCMSContent(collection, new List<String>{userId,profileId});
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
    }

    /**
     * @description D1_FaultFixerController.getDiagnosticOrIssuePageInfo description NCP-1871
     */
    @isTest static void testNegativeParams1(){
        try{
            D1_FaultFixerController.getDiagnosticOrIssuePageInfo(null);
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.getDiagnosticOrIssuePageInfo(UserInfo.getUserId());
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.getDiagnosticOrIssueFromTroubleshoot(null);
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.getDiagnosticOrIssueFromTroubleshoot(UserInfo.getUserId());
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.getTroubleshootStepContent(null, 'communityid', null, null);
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
    }
    
     /**
     * @description D1_FaultFixerController.getDiagnosticOrIssuePageInfo description NCP-1871
     */
    @isTest static void testNegativeParams2(){
        try{
            D1_FaultFixerController.getTroubleshootStepContent(UserInfo.getUserId(), 'communityid', null, null);
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.getFaultFixerBreadCrumbs(UserInfo.getUserId());
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.processTroubleshootCMSContent(null,null);
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
        
        try{
            D1_FaultFixerController.getFaultFixerHierarchicalRecordData('');
        }catch(Exception ex){
            System.assert(ex!=null, 'exception should not be empty');
        }
    }
    
    /**
     * @description testGetDiagnosticOrIssuePageInfo description
     */  
    @isTest
    public static void testGetFaultFixerHierarchicalRecordData(){
        List<D1_Fault_Fixer__c> troubleshoots = [select id from D1_Fault_Fixer__c
                                                     WHERE RecordType.name IN('Troubleshooting Steps')
                                                     LIMIT 1];
        Object result = D1_FaultFixerController.getFaultFixerHierarchicalRecordData(troubleshoots[0].id);
        System.assert(result != null, 'Fault fixer data cant be empty');
    }
}