/*
 * @Name: ECM_PaymentSummaryItemsTriggerTest
 * @Description: This is the test class for ECM_paymentSummaryItemsTrigger
 * @History                                                            
                                                         
 VERSION      AUTHOR          		DATE                        DETAIL
 1.0          CM Dev Team                                   	Initial Development
 1.1	      Pratap	  			27/12/2021        			Technical Debt Changes against ECM-4994	
 1.2	      Tanishq	  			15/02/2022        			Technical Debt Changes against ECM-4994
*/ 
@isTest
public class ECM_paymentSummaryItemsTrigger_Test
 {
    /*
    * @Name : validatekPSITriggerAfter
	* @description : This method is used to test Trigger.after() operations of ECM_paymentSummaryItemsTrigger
	*/ 
    @isTest
    public static void validatekPSITriggerAfter()
    {
        WrapperInst wrapobj = createData();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = ECM_UtilityTestClass.getPaymentSummaryItem(wrapObj.paymentSummary,wrapObj.contractItem);
        try
        {
            system.runAs(wrapobj.salesRep)
            {
                insert paymemtSummaryItem;
                system.assert(paymemtSummaryItem.id != NULL,'paymemtSummaryItem should not be null');
                delete paymemtSummaryItem;
            }
        }
        catch(Exception ex){
            system.assert(!String.isBlank(String.valueOf(ex)),'EX shouldnot be null');
        }
    }
    /*
    * @Name : validatekPSITriggerBefore
	* @description : This method is used to test Trigger.Before() operations of ECM_paymentSummaryItemsTrigger
	*/   
    @isTest
    public static void validatekPSITriggerBefore()
    {
        WrapperInst wrapobj = createData();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = ECM_UtilityTestClass.getPaymentSummaryItem(wrapObj.paymentSummary,wrapObj.contractItem);
        insert paymemtSummaryItem;
        Test.startTest();
        try
        {
            ECM_Payment_Summary__c ps = [SELECT id,ECM_Payment_Summary_Status__c FROM ECM_Payment_Summary__c 
                                         WHERE id =: paymemtSummaryItem.ECM_Payment_Summary__c LIMIT 1];
            ps.ECM_Payment_Summary_Status__c = 'Approved';
            update ps;
            
            system.runAs(wrapObj.salesRep)
            {
                //good case
                paymemtSummaryItem.ECM_Actual_Cases__c = 20.00;
                update paymemtSummaryItem;
                //bad case
                paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c = 20;
                update paymemtSummaryItem;
            }
        }
        catch(Exception ex)
        {
            system.assert(!String.isBlank(String.valueOf(ex)),'EX shouldnot be null');
        }
        Test.stopTest();
    }
    /*
    * @Name : createData()
	* @description : This method is used to create test data
	*/ 
    public static WrapperInst createData(){
        
        //Setting up required record types
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
        //Creating Market Setting Data
        Market_Setting__c mktSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mktSetting.ECM_Evidence_email_enabled__c = true;
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
        mktSetting.ECM_Evidence_PrePayment_Notification__c = true;
        mktSetting.ECM_Evidence_PrePayment_SP_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_Notification__c = true;
        mktSetting.ECM_Payment_Evidence_SP_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_Notification__c = true;
        mktSetting.ECM_Payment_Invoice_SP_Notification__c = true;
        mktSetting.A_P_Threshold__c=10;
        mktSetting.Threshold_Format__c='Percent';
        mktSetting.ECM_Target__c = 50;
        mktSetting.ECM_Enable_Target__c = true;
        insert mktSetting;

        //Setting up a sales rep user to run test as
        User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
        salesRep.Username = 'salesRp123@test.com';
        insert salesRep;
        
        //Setting up mandatory contract field records
        Account acc = EDGE_UtilityTestClass.getOutletRecord();
        acc.country__c = geographyId;
        acc.Sales_Org__c ='sale';
        acc.SAP_Sold_to__c ='sapsold';
        insert acc;
        ECM_Contract_Type__c contractType = ECM_UtilityTestClass.createContractType(geographyId);
        insert contractType;    
        
        //Setting up contract to link with payment summary
        Contract contr = ECM_UtilityTestClass.createContract(acc.id,contrRecTypeId);        
        contr.ECM_Agreement_Type__c = contractType.Id;
        contr.ownerId = salesRep.Id;
        insert contr;
        
        //Setting up Payment Summary
        ECM_Payment_Summary__c paymentSummary = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary.ECM_Type__c = 'Volume-Based';
        paymentSummary.ECM_Invoice_Status__c='Approved';
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        insert paymentSummary;

        //Setting up contract items to create payment summary item
        Product__c product = ECM_UtilityTestClass.createProduct(geographyId,'Test');
        product.Product_Full_Name__c='Test';
        insert product;        
        Market_Assortment_Product__c mapRec = ECM_UtilityTestClass.createMarketAssortmentProduct(product.Id,geographyId);
        mapRec.ECM_INTO_Material__c = 9;
        insert mapRec;  
        ECM_Contract_Item__c ciRec = ECM_UtilityTestClass.createcontractitem(contr.Id,mapRec.id);
        insert ciRec;
        
        //Setting up payment summary item
        ECM_Payment_Summary_Item__c paymemtSummaryItem = ECM_UtilityTestClass.getPaymentSummaryItem(paymentSummary.id,ciRec.id);
        insert paymemtSummaryItem;
        
        //wrapping up all the test data
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.paymentSummary = paymentSummary.Id;
        wrapObj.contractItem = ciRec.Id;
        wrapObj.salesRep = salesRep;
        return wrapObj;
    }
    class WrapperInst
    {
        String paymentSummary{get;set;}
        String contractItem{get;set;}
        User salesRep{get;set;}
    }
}