/*

*   @Class Name: ECM_AnPScreenNavigationControllerTest 

*   @Author                  Version       Date           Detail
    Rajarshi Lahiri		     1.0		       
*/
@isTest
public class ECM_AnPScreenNavigationControllerTest {
	final static String OUTLETRECORDTYPEID = Account.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
    @isTest
    public static void validateContractTest(){
        // user mdm;
        EDGE_UtilityTestClass.createOrgSettings();
        Id geographyId = EDGE_UtilityTestClass.setupCountry('GB'); 
      
        //Creating  Pick Up Option
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(geographyId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold [GB]';
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
        
		ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        //contractType.ECM_of_Outlets_Tap_Space_Required__c = 0.8;
        contractType.ECM_Enable_A_P_screen__c=false;
        insert contractType;
        
        EDGE_UtilityClass.stopTriggerToRun = false;
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(acc.Id, contractRecordTypeId);
        objContract.ECM_Agreement_Type__c=contractType.Id;
        objContract.Status = 'Draft';
        objContract.Contract_End_Date__c = System.today()+29;
        insert objContract;
        ECM_AnPScreenNavigationController.validateContract(objContract.Id);
        contractType.ECM_Enable_A_P_screen__c=true;
        update contractType;
        objContract.Status = 'Active';
        objContract.Initial_UOS_Earnt__c=0;
        objContract.Contract_End_Date__c = System.today()+30;
        update objContract;
        
        //List<Contract> contractList = [Select Id, Status  from Contract where Id =:objContract.Id ];
        ECM_AnPScreenNavigationController.validateContract(objContract.Id);
      	objContract.ECM_A_P_Records_Created__c=true;
        update objContract;
        ECM_AnPScreenNavigationController.validateContract(objContract.Id);
		Test.stopTest();        
       
        
        
    }
    
}