/*
	@Name: ECM_PDFGenerationMsgControllerTest
	@Purpose: This is test Class for ECM_PDFGenerationMsgController
	@PDF file msg for Amended contract
	@History                                                            
	@VERSION    AUTHOR                   DATE              DETAIL
	1.1      	Saurav Paul      14/11/2021        Added for ECM-6212  
*/
@isTest
public class ECM_PDFGenerationMsgControllerTest {
	@isTest
    public static void checkAction(){
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.Person_Responsible__c= UserInfo.getUserId();
        outletAccount.OwnerId = UserInfo.getUserId();
        //outletAccount.Operator__c=contractType.id;
        insert outletAccount;
        system.assert(outletAccount!= null,'outletAccount should not be null');
        String contractRecordTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        Contract objContract = EDGE_UtilityTestClass.getContract(outletAccount.Id, contractRecordTypeId);
        objContract.ECM_Amended__c = true;
        insert objContract;
		Test.startTest();
        PageReference pageRef = Page.ECM_PDFGenerationMsg;
        Test.setCurrentPage(pageRef);
        pageRef.getParameters().put('Id',objContract.id);
        ApexPages.StandardController sc = new ApexPages.standardController(objContract);
        ECM_PDFGenerationMsgController  controller = new ECM_PDFGenerationMsgController(sc);
        controller.continuePDFGene();
        Test.stopTest();        
    }
}