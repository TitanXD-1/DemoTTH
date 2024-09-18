/**********************************************************************
Name: EDGE_OutletContractTriggerHelperTest

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR            DATE            DETAIL
1.0         Dipanjan Das      07/02/2019      Test Class for EDGE_OutletContractTriggerHelper
***********************************************************************/

@isTest
public class EDGE_OutletContractTriggerHelperTest{

    @isTest
    public static void testverifyAPCost(){
        test.StartTest();
        createData();
        List<Outlet_Contract__c> outletContractList = [SELECT Id, Contract__c, Outlet__c, Status__c FROM Outlet_Contract__c];
        EDGE_OutletContractTriggerHelper.updateContractOnOutletExecution(outletContractList);
        update outletContractList;
        System.assert(outletContractList.size() != null,'outletContractList should not be null');
        delete outletContractList;
        test.StopTest();              
    }  
    
    public static void createData(){

        
      //  Id geographyID = EDGE_UtilityTestClass.setupCountry('AU');
        
        
        Account outlet = EDGE_UtilityTestClass.getOutletRecord();
        insert outlet;
        
        //EDGE_UtilityTestClass.createOrgSettings();
        
        Id contractRecordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('A&P').getRecordTypeId();
        
        Contract contractRec = EDGE_UtilityTestClass.getContract(outlet.Id, contractRecordTypeId);
        contractRec.Opening_AP_Balance__c = 50;
        contractRec.startDate = system.today().addDays(-2);
        contractRec.Contract_End_Date__c = system.today().addDays(5);
        insert contractRec;
        
        Outlet_Execution_Historic__c outletExHistroric = new Outlet_Execution_Historic__c();
        outletExHistroric.Name = 'TestOutletExHistoric';
        outletExHistroric.Outlet__c = outlet.Id;
        outletExHistroric.Date_of_Execution__c = system.today();
        outletExHistroric.Contract__c = null;
        insert outletExHistroric;   
        
        EDGE_UtilityTestClass.createOrgSettings();
        Outlet_Contract__c outletContract = new Outlet_Contract__c();
        outletContract.Contract__c = contractRec.Id;
        outletContract.Outlet__c = outlet.Id;
        insert outletContract;
        
    }    
}