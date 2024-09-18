/*
 * @Class Name : ECM_PaymentSummarySendEmailBatchTest
 * @description : Test Class for ECM_PaymentSummarySendEmailBatch
 * @history:
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.1       Saurav Paul      	   20-08-2021       Initial Development    
 * 1.2       Joshraj Sen           11/06/2024       PMD Fix     		  
*/


@isTest
public class ECM_PaymentSummarySendEmailBatchTest {

    /*
     * @name : validatePSSendEmailBatch
	 * @description : Test coverage method of batch
	 * @return : void
	 * @param : void
	*/
    @isTest
    public static void validatePSSendEmailBatch() {
        createData();
        Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt where Batch_Class__c = 'ECM_PaymentSummarySendEmailBatch'
                                                  and Country_Code__c ='ES' ];
        String className = batchSetting.Batch_Class__c;   
        System.assert(className!=null,'Batch Exists');
        Type t = Type.forName(className);
        BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
        job.getBatchDetails(batchSetting);
        Test.startTest();
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        Test.stopTest();
        
    }
    /** 
     * @name : createData
	 * @description  Test coverage method of batch
	**/
    public static void createData(){
        Id contId;
        Geography__c marketObj;
        List<ECM_Payment_Summary__c> paySumList = new List<ECM_Payment_Summary__c>();
        contId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        String conOutletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        Territory__c  territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        insert territoryObj;
        
        Account outletAccount = EDGE_UtilityTestClass.getOutletRecord();
        outletAccount.SAP_Sold_to__c='3984021';
        outletAccount.VAT_Number__c='TAXID123';
        outletAccount.ECM_Legal_Name__c='Legal';
        outletAccount.Email_for_contracts_payments__c='testUser@diageo.com';
        outletAccount.IsOperator__c = true;
        insert outletAccount;
        
        ECM_Contract_Type__c agreementType = ECM_UtilityTestClass.createContractType(contId);
        insert agreementType;
        ECM_Payment_Frequency__c paymfreq = ECM_UtilityTestClass.getPayFre(contId);
        insert paymfreq;
        
        Contract conObj =  EDGE_UtilityTestClass.getContract(outletAccount.Id, conOutletRecTypeId);
        conObj.ECM_Territory__c = territoryObj.Id;
        conObj.ECM_Payment_Frequency_type__c = paymFreq.Id;
        conObj.Contract_End_Date__c = System.today().addDays(360);
        insert conObj;
        
        ECM_Payment_Summary__c paymentSummary1 = ECM_UtilityTestClass.getPaymentSummary(conObj.Id);
        paymentSummary1.ECM_Evidence_Attachment__c = False;
        paymentSummary1.ECM_Invoice_Attachment__c = False;
        paySumList.add(paymentSummary1);
        
        ECM_Payment_Summary__c paymentSummary2 = ECM_UtilityTestClass.getPaymentSummary(conObj.Id);
        paymentSummary2.ECM_Evidence_Attachment__c = False;
        paymentSummary2.ECM_Invoice_Attachment__c = True;
        paySumList.add(paymentSummary2);
        
        ECM_Payment_Summary__c paymentSummary3 = ECM_UtilityTestClass.getPaymentSummary(conObj.Id);
        paymentSummary3.ECM_Evidence_Attachment__c = True;
        paymentSummary3.ECM_Invoice_Attachment__c = False;
        paySumList.add(paymentSummary3);
        insert paySumList;
        
    }
}