/*
 * @Name: ECM_PaymentAgreementTriggerHelperTest
 * @Description: This is the test class for PaymentAgreementTrigger
 * @History                                                            
                                                         
 VERSION    AUTHOR                DATE              DETAIL
 1.0        Subhrojit Majumdar    14/09/2021        Initial Development for ECM-4416
 1.1		Subhrojit Majumdar	  20/12/2021		Technical Debt Changes against ECM-5068		
*/ 
@isTest
public class ECM_PaymentAgreementTriggerHelperTest 
{
   /**
    * @Name : paymentAgreementValidationTest
	* @description : This method is used to test the PaymentAgreementDuplicateCheck() method of the ECM_PaymentAgreementTriggerHelper class
	*/
	@isTest
    public static void paymentAgreementValidationTest()
    {
        WrapperInst wrapobj = createData();
        ECM_Payment_Agreement__c paymentAggObj = ECM_UtilityTestClass.createPaymentAgreement(wrapobj.aggTypeObj,wrapobj.paymentFreqObj);
        Test.startTest();
        try
        {
            insert paymentAggObj;
        }catch(Exception ex)
        {
            String errorMessage = Label.ECM_Payment_Agreement_Error_Message;
            errorMessage = errorMessage.split('\\.')[0];
            String expectedError = ex.getMessage().split('\\,')[1].split('\\.')[0].trim();
            System.assertEquals(errorMessage,expectedError,ex.getMessage());
        }
        Test.stopTest();
    }
   /**
    * @Name : paymentAgreementValidationTest
	* @description : This method is used to test the PaymentAgreementDuplicateCheck() method of the ECM_PaymentAgreementTriggerHelper class
	*/
    @isTest
    public static void updatePaymentAgreementValidationTest()
    {
        WrapperInst wrapObj = createData();
        ECM_Payment_Frequency__c paymentFreqObj = ECM_UtilityTestClass.getPayFre(wrapObj.countryIdVal);
		insert paymentFreqObj;
        ECM_Payment_Agreement__c paymentAggObj = ECM_UtilityTestClass.createPaymentAgreement(wrapObj.aggTypeObj,paymentFreqObj.Id);
        insert paymentAggObj;
        paymentAggObj.ECM_Payment_Frequency__c = wrapObj.paymentFreqObj;
        Test.startTest();
        try
        {
            update paymentAggObj;
        }catch(Exception ex){
            String errorMessage = Label.ECM_Payment_Agreement_Error_Message;
            errorMessage = errorMessage.split('\\.')[0];
            String expectedError = ex.getMessage().split('\\,')[1].split('\\.')[0].trim();
            System.assertEquals(errorMessage,expectedError,ex.getMessage());
        }
        Test.stopTest();
    }
   /**
    * @Name : createData()
	* @description : This method is used to create test data for PaymentAgreementDuplicateCheck() method of the ECM_PaymentAgreementTriggerHelper class
    * @return : returns a Wrapper with payment frequency,agreement type & geography Id
	*/
    public static WrapperInst createData()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
		ECM_Payment_Frequency__c paymentFreqObj = ECM_UtilityTestClass.getPayFre(countryId);
		insert paymentFreqObj;
        ECM_Contract_Type__c aggTypeObj = ECM_UtilityTestClass.getAgreementType(countryId);
        insert aggTypeObj;
        ECM_Payment_Agreement__c paymentAggObj = ECM_UtilityTestClass.createPaymentAgreement(aggTypeObj.Id,paymentFreqObj.Id);
        insert paymentAggObj;
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.paymentFreqObj = paymentFreqObj.Id;
        wrapObj.aggTypeObj = aggTypeObj.Id;
        wrapObj.countryIdVal = countryId;
        return wrapObj;
    }
    class WrapperInst
    {
        String paymentFreqObj{get;set;}
        String aggTypeObj{get;set;}
        String countryIdVal{get;set;}
    }
}