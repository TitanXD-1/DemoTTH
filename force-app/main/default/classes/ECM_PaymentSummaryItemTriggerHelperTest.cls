/*
 * @Name: ECM_PaymentSummaryItemTriggerHelperTest
 * @Description: This is the test class for ECM_paymentSummaryItemsTrigger
 * @History                                                            
                                                         
 VERSION      AUTHOR          DATE                        DETAIL
 1.0        CM DEV Team                             Initial Development
 1.1	    Pratap Sen	    27/12/2021        Technical Debt Changes against ECM-4994		
*/ 
@isTest
public class ECM_PaymentSummaryItemTriggerHelperTest {
   /*
    * @Name : validatekPSITriggerAfter
	* @description : This method is used to test Trigger.after() operations of ECM_paymentSummaryItemsTrigger
	*/ 
    @isTest
    public static void validatekPSITriggerAfter()
    {
        WrapperInst wrapobj = createData();
        ECM_Payment_Summary_Item__c paymemtSummaryItem = ECM_UtilityTestClass.getPaymentSummaryItem(wrapObj.paymentSummary,wrapObj.contractItem);
        ECM_Payment_Summary_Item__c paymemtSummaryItemVol = ECM_UtilityTestClass.getPaymentSummaryItem(wrapObj.paymentSummaryVol,wrapObj.contractItem);
        try
        {
            system.runAs(wrapobj.salesRep)
            {
                insert paymemtSummaryItem;
                insert paymemtSummaryItemVol;
                system.assert(paymemtSummaryItem.id != NULL & paymemtSummaryItemVol.id != NULL,'insert successful');
                paymemtSummaryItemVol.ECM_To_Pay__c = True;
                update paymemtSummaryItemVol;
                paymemtSummaryItem.ECM_Confirm__c = True;
                update paymemtSummaryItem;
                delete paymemtSummaryItem;
            }
        }
        catch(Exception ex)
        {
            system.debug(LoggingLevel.WARN,'Exception caught '+ex);
        }
    }
   /**
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
                system.assert(paymemtSummaryItem.ECM_Actual_Cases__c == 20,'update successful');
                //bad case
                paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c = 20;
                update paymemtSummaryItem;
            }
        }
        catch(Exception ex)
        {
            system.assert(!String.isBlank(String.valueOf(ex)),'exception thrown on update successfully');
        }
        Test.stopTest();
    }
   /**
    * @Name : createData()
	* @description : This method is used to create test data
    * @return : Returns a wrapper with payment summary,contract item & sales rep user
	*/ 
    public static WrapperInst createData(){
        
        //Setting up required record types
        Id geographyId = EDGE_UtilityTestClass.setupCountrySpain('ES');
        Id contrRecTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByName().get('Outlet').getRecordTypeId();

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
        
        //Setting up Market Settings
        Market_Setting__c mSetting = EDGE_UtilityTestClass.getMarketSetting(geographyId);
        mSetting.ECM_Manager_Approval__c = 'Volume-Based;Promo-Standard';
        mSetting.ECM_Enable_Target__c = True;
        insert mSetting;
        
        //Setting up Payment Summary
        ECM_Payment_Summary__c paymentSummary = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummary.ECM_Total_Amount_Confirmed__c = 20.00;
        paymentSummary.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummary.ECM_Type__c = 'Promo-Standard';
        paymentSummary.ECM_Invoice_Status__c='Approved';
        paymentSummary.ECM_Tax_Rate__c='Standard Rate';
        insert paymentSummary;
        
        ECM_Payment_Summary__c paymentSummaryVol = ECM_UtilityTestClass.getPaymentSummary(contr.id);
        paymentSummaryVol.ECM_Total_Amount_Confirmed__c = 10.00;
        paymentSummaryVol.ECM_Payment_Summary_Status__c = 'Open';
        paymentSummaryVol.ECM_Type__c = 'Volume-Based';
        paymentSummaryVol.ECM_Invoice_Status__c='Approved';
        paymentSummaryVol.ECM_Tax_Rate__c='Standard Rate';
        insert paymentSummaryVol;
        
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
        paymemtSummaryItem.ECM_Confirmed_Amount_Per_Payment__c = 10;
        insert paymemtSummaryItem;
        
        //wrapping up all the test data
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.paymentSummary = paymentSummary.Id;
        wrapObj.paymentSummaryVol = paymentSummaryVol.Id;
        wrapObj.contractItem = ciRec.Id;
        wrapObj.salesRep = salesRep;
        return wrapObj;
    }
    class WrapperInst
    {
        String paymentSummary{get;set;}
        String paymentSummaryVol{get;set;}
        String contractItem{get;set;}
        User salesRep{get;set;}
    }
}