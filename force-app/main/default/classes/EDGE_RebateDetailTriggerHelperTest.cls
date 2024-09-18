/**********************************************************************
Name: EDGE_RebateDetailTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Dipanjan Das      07/15/2019      Test Class for EDGE_RebateDetailTriggerHelper
***********************************************************************/

@isTest
public class EDGE_RebateDetailTriggerHelperTest{
    
    @isTest
    public static void testverifyAPCost(){
        test.StartTest();
        createData();
        Rebate_Detail__c rebateDetail = [SELECT Id, Status__c FROM Rebate_Detail__c LIMIT 1];
        system.assertEquals(rebateDetail.Status__c, 'Rejected','rebateDetail should match');
        Delete rebateDetail;
        test.StopTest();  
    }       
    
    public static void createData(){
        
                
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        //EDGE_UtilityTestClass.createOrgSettings();
        
        Id contractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        Id rebateRecordTypeId = Schema.SObjectType.Rebate_Detail__c.getRecordTypeInfosByName().get('Rebate').getRecordTypeId();
        Id aPRecordTypeId = Schema.SObjectType.Rebate_Detail__c.getRecordTypeInfosByName().get('A&P Spend').getRecordTypeId();
        
        Contract contractRec = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        contractRec.Opening_AP_Balance__c = 50;
        contractRec.startDate = system.today().addDays(-2);
        contractRec.Contract_End_Date__c = system.today().addDays(5);
        insert contractRec;         
        
        EDGE_UtilityTestClass.createOrgSettings();
        
        Rebate_Detail__c rebate = new Rebate_Detail__c();
        rebate.Contract__c = contractRec.Id;
        rebate.Amount__c =100;
        rebate.Invoice_Date__c = system.Today();
        rebate.Invoice_Number__c = 'INV001';
        rebate.recordTypeId = rebateRecordTypeId;   
        insert rebate;
        
        Rebate_Detail__c rebate1 = new Rebate_Detail__c();
        rebate1.Contract__c = contractRec.Id;
        rebate1.Amount__c =0;
        rebate1.Invoice_Date__c = system.Today();
        rebate1.Invoice_Number__c = 'INV001';
        rebate1.recordTypeId = rebateRecordTypeId;
        insert rebate1;
        
        Rebate_Detail__c rebate2 = new Rebate_Detail__c();
        rebate2.Contract__c = contractRec.Id;
        rebate2.Amount__c =100;
        rebate2.Invoice_Date__c = system.Today();
        rebate2.Invoice_Number__c = 'INV001';
        rebate2.recordTypeId = aPRecordTypeId;  
        insert rebate2;
        
        Rebate_Detail__c rebate3 = new Rebate_Detail__c();
        rebate3.Contract__c = contractRec.Id;
        rebate3.Amount__c =0;
        rebate3.Invoice_Date__c = system.Today();
        rebate3.Invoice_Number__c = 'INV001';
        rebate3.recordTypeId = aPRecordTypeId;
        insert rebate3;     
        
    }       
    
}