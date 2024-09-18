/*
@Name: ECM_PaymentSummaryController_Test 
@Description: This class is used to cover test data for the class - ECM_GetSignedContractDetails.
@History                                                                                                                       
VERSION         AUTHOR                     DATE              DETAIL
1.0             Wribhu Bose                15/04/2020        Initial Development
*/

@istest
public class ECM_GetSignedContractDetailsTest {
    @isTest
    static void getSummaryDetailsTest(){
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Name = 'Test Account';
        outletAccount.Person_Responsible__c = null;
        outletAccount.Email_for_contracts_payments__c = 'test@abc.com';
        insert outletAccount;
        System.assert(outletAccount!=null,'outletAccount should not be null');
        
        Profile prof = [SELECT Id FROM Profile WHERE Name =:'Sales Representative'];
        User conOwner = new User();
        conOwner.firstName = 'test1';
        conOwner.lastName = 'test2';
        conOwner.profileId = prof.Id;        
        conOwner.email = 'test@test.com';
        conOwner.Username ='conowner@test.com';
        conOwner.Alias='test';
        conOwner.Timezonesidkey='America/Los_Angeles';
        conOwner.LocaleSidKey='en_US';
        conOwner.LanguageLocaleKey='en_US';
        conOwner.EmailEncodingKey='UTF-8';
        conOwner.Available_Countries__c='GB';
        conOwner.Title='Legal';
        insert conOwner;
        
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.ECM_Type_of_Contract__c = 'Outlet';
        objContract.OwnerId = conOwner.Id;
        objContract.AccountId = outletAccount.Id;
        insert objContract;
        
        ECM_GetSignedContractDetails getSignedContractDetails = new ECM_GetSignedContractDetails();
        getSignedContractDetails.targetObjectId = objContract.Id;
        getSignedContractDetails.getContractDetails();
    }
}