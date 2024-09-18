/*
 @Name: ECM_PaymentSummaryStatusChangeBatchTest
 @Description: This is the Test class for ECM_PaymentSummaryStatusChangeBatch
 @History                                                            
                                                        
 VERSION    AUTHOR       DATE                     DETAIL
  1.0     Pravalika   30-03-2020              Initial Development
  2.0     Pratap Sen  28-12-2021        Technical Debt Changes against ECM-4994
*/ 
@isTest
public class ECM_PaymentSummaryStatusChangeBatchTest {
   /**
    * @Name : validatePaymentSummary
	* @description : Test coverage method of the batch ECM_PaymentSummaryStatusChangeBatch
	*/
    @isTest
    public static void validatePSStatusBatch(){
        WrapperInst wrapobj = createData();      
        try
        {
            List<ECM_Payment_Summary__c> psList = wrapobj.psList;
            psList[0].ECM_Type__c = 'Volume-Based';
            psList[1].ECM_Type__c = 'Promo-Standard';
            PsList[1].ECM_Payment_Frequency__c = wrapobj.paymentFreq;
            psList[2].ECM_Type__c = 'Promo-Standard';
            insert psList;
            
            Test.startTest();
            system.assert(psList[0].Id != NULL,'insertion successful');
            
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c, Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c from Market_Batch_Setting__mdt 
                                                      where Batch_Class__c = 'ECM_PaymentSummaryStatusChangeBatch' and Country_Code__c ='ES' ];
            String className = batchSetting.Batch_Class__c;       
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(batchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
            
            ECM_PaymentSummaryStatusChangeBatch.sendPSOpenEmailToSalesRep(psList); 
            Test.stopTest();
        }
        catch(Exception ex)
        {
            system.debug(LoggingLevel.WARN,'Exception caught '+ex);
        }
    }
   /**
    * @Name : createData()
	* @description : this method is to create testdata
    * @return : returns a Wrapper with a List of payment summary & contract id 
	*/
    public static WrapperInst createData()
    {
        Id contId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        String conOutletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Group').getRecordTypeId();
        
        //setting up market geography for EDGE_BatchUtilityClass.upsertMarketBatchJob
        Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
        //setting up market settings to have manager approval per PS type
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(contId);
        mktSetting.Name = 'Market Setting ES';
        mktSetting.Geography__c = contId;
        mktSetting.Minimum_Product_Assortment__c = 'Binary';
        mktSetting.Minimum_Activation_Standards__c = 'Binary';
        mktSetting.Distribution__c = 'Binary';
        mktSetting.New_Product_Distribution__c = 'Progressive';
        mktSetting.Open_Opportunity__c = 'Calculative';
        mktSetting.Closed_Opportunity__c = 'Calculative';
        mktSetting.Outlet_Execution_Score__c = 'Calculative';
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Prospect_Approver__c = 'Sales Manager & MDM Approval Required' ;
        mktSetting.ECM_SAP_Order_Type__c = 'Sap';
        mktSetting.ECM_Evidence_email_enabled__c=true;
        mktSetting.ECM_Payment_Management_Email__c='TEST@test.com';
        mktSetting.ECM_Diageo_Entity_Address_for_Invoicing__c='TEST@test.com';
        mktSetting.ECM_Payment_Evidence_Pre_Payment_SP__c='ECM_PaymentSummaryEvidenceRequestPrePySP';
        mktSetting.ECM_Payment_Evidence_Pre_Payment__c='ECM_PaymentSummaryEvidenceRequestPrePay';
        mktSetting.ECM_Payment_Evidence_template__c='ECM_PaymentSummaryEvidenceRequestStd';
        mktSetting.ECM_Payment_Evidence_SP_template__c='ECM_PaymentSummaryEvidenceRequestStdSP';
        mktSetting.ECM_Payment_Invoice_SP_template__c='ECM_PaymentSummaryInvoiceRequestSP';
        mktSetting.ECM_Payment_Invoice_template__c='ECM_PaymentSummaryInvoiceRequest';
        mktSetting.ECM_Manager_Approval__c = 'Promo-Standard;Volume-Based;Promo-PrePayment';
        mktSetting.ECM_Rejection_Email_to_Sales_Rep__c = true;
        insert mktSetting;
        
        //setting up sales rep & sales manager user
        User salesMg = ECM_UtilityTestClass.createUser('smg',ECM_UtilityTestClass.getProfile('Sales Manager').Id);
        salesMg.Username = 'salesMg123@test.com';
        insert salesMg;        
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp123@test.com';
        salesRep.ManagerId = salesMg.Id;
        insert salesRep;

        
        //setting up mandatory fields of a contract : account,territory,agreement type & payment frequency
        Territory__c  territoryObj = EDGE_UtilityTestClass.getTerritoryRec();
        insert territoryObj;
        Account groupAccount = EDGE_UtilityTestClass.getOwnerOperatorAccount();//ECM_UtilityTestClass.getOutlet();
        groupAccount.IsOperator__c = TRUE;
        groupAccount.BillingCountry = 'Spain';
        groupAccount.Primary_Sales_Rep__c = salesRep.id;
        groupAccount.Email_for_contracts_payments__c = 'test.group@mail.com';
        insert groupAccount;
        ECM_Contract_Type__c agreementType = ECM_UtilityTestClass.createContractType(contId);
        agreementType.ECM_Allow_Multiple_Agreements__c = True;
        insert agreementType;
        ECM_Payment_Frequency__c paymfreq = ECM_UtilityTestClass.getPayFre(contId);
        paymfreq.ECM_Type__c = 'At the End of the Contract';
        insert paymfreq;
        
        //setting up a contract
        Contract conObjMg =  ECM_UtilityTestClass.createContract(groupAccount.Id, conOutletRecTypeId);
        conObjMg.ECM_Territory__c = territoryObj.Id;
        conObjMg.ECM_Payment_Frequency_type__c = paymFreq.Id;
        conObjMg.StartDate = System.today().addMonths(-6);
        conObjMg.Contract_End_Date__c = System.today().addMonths(6);
        conObjMg.OwnerId = salesRep.Id;
        conObjMg.CreatedById = salesRep.Id;
        insert conObjMg;
        
        //setting the payment summary list with contract reference
        List<ECM_Payment_Summary__c> paySumList = new List<ECM_Payment_Summary__c>();
        for(Integer psIt=0;psIt<5;psIt++)
        {
			ECM_Payment_Summary__c paymentSummary = ECM_UtilityTestClass.getPaymentSummary(conObjMg.Id);
            paymentSummary.ECM_Start_Period__c = System.today().addmonths(-1);
            paymentSummary.ECM_End_Period__c = System.today();
            paymentSummary.ECM_Payment_Summary_Status__c = 'Provisional';
            paySumList.add(paymentSummary);            
        }
               
        //wrapping up all data
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.paymentFreq = paymfreq.Id;
        wrapObj.psList = paySumList;
        return wrapObj;
    }
    class WrapperInst
    {
        String paymentFreq{get;set;}
        List<ECM_Payment_Summary__c> psList{get;set;}
    }
}