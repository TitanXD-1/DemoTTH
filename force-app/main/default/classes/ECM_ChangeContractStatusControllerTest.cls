/*

*   @Class Name: ECM_ChangeContractStatusControllerTest 

*   @Author                  Version       Date           Detail
    Monalisa Halder		     1.1		01/06/2023       ES20-14083
*/


@isTest
public class ECM_ChangeContractStatusControllerTest {
    final static String OUTLETRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();   
    
    /*
    Method  : getContractStatusTest
    Purpose : This is used to cover getContractStatus method
    */
    @isTest
    public static void getContractStatusTest(){
       // user mdm;
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('AU'); 
      
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [AU]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Test.startTest();
        Account acc = new Account();
        acc =  EDGE_UtilityTestClass.getOutletRecord();
        acc.RecordTypeId = OUTLETRECORDTYPEID;
        acc.BillingStreet ='17 Asian Highway 45';
        acc.BillingCity =  'Tasmania';
        acc.BillingPostalCode = '5668';
        acc.BillingState = 'Tasmania';
        acc.BillingPostalCode = '5668';
        acc.BillingCountryCode = 'AU';
        acc.Status__c = 'Active';
        acc.Outlet_Visit_Prioritisation_Grade__c =pickupOption.Id; 
        insert acc;
        System.assert(acc.Id != null,'acc should not be null');
        
		
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        insert objContract;
        objContract.Status = 'Active';
        objContract.Initial_UOS_Earnt__c=0;
        objContract.Contract_End_Date__c = System.today()+30;
        update objContract;
        
            List<Contract> contractList = [Select Id, Status  from Contract where Id =:objContract.Id ];
            ECM_ChangeContractStatusController.getContractStatus(contractList[0].Id);
      
		Test.stopTest();        
       
        
        
    }

}