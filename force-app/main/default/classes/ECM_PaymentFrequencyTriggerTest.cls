/*
 * @Name: ECM_PaymentFrequencyTriggerTest
 * @Description: Test Class for  ECM_PaymentFrequencyTriggerHelper
 * @History                                                            
                                                         
 VERSION    AUTHOR                DATE              DETAIL
 1.0        Manikandan.T    	  11/12/2020        Initial Development
 1.1		Subhrojit Majumdar	  20/12/2021		Technical Debt Changes against ECM-5068		
*/ 

@isTest
public with sharing class ECM_PaymentFrequencyTriggerTest 
{
   /**
    * @Name : checkSharingTest
	* @description : This method is used to test and validate sharing record on insert of Payment Frequency object - checkAndGenerateSharing() and, checkAndGenerateD1Sharing() methods of ECM_PaymentFrequencyTriggerHelper class
	*/
    @isTest
    public static void checkSharingTest()
    {
		WrapperInst wrapobj = createData();
       	ECM_Payment_Frequency__c paymentFreqObj = ECM_UtilityTestClass.getPayFre(wrapobj.secCountry);
       	Test.startTest();
        insert paymentFreqObj;
        Test.stopTest();
        List<ECM_Payment_Frequency__Share> payfreShareList =[SELECT Id, ParentId, RowCause, AccessLevel 
                                 							 FROM ECM_Payment_Frequency__Share 
                                 							 WHERE ParentId =: paymentFreqObj.Id];
        System.assert(payfreShareList!= null,'Share list is not empty');
    }
   /**
    * @Name : updateCheckSharingTest
	* @description : This method is used to test and validate sharing record on update of Payment Frequency object - validateAndReGenerateSharing() and, validateAndReGenerateD1Sharing() methods of ECM_PaymentFrequencyTriggerHelper class
	*/
    @isTest
    public static void updateCheckSharingTest()
    {
        WrapperInst wrapobj = createData();
        ECM_Payment_Frequency__c paymentFreqObj = ECM_UtilityTestClass.getPayFre(wrapobj.secCountry);
        insert paymentFreqObj;
        Test.startTest();
        paymentFreqObj.ECM_Geography__c = wrapObj.secCountry2;
        update paymentFreqObj;
        Test.stopTest();
        List<ECM_Payment_Frequency__Share> payfreShareList =[SELECT Id, ParentId, RowCause, AccessLevel 
                                 							 FROM ECM_Payment_Frequency__Share 
                                 							 WHERE ParentId =: paymentFreqObj.Id];
        System.assert(payfreShareList!= null,'Share list is not empty');
    }
   /**
    * @Name : createData()
	* @description : This method is used to create test data for testing ECM_PaymentFrequencyTriggerHelper class
    * @return : returns a Wrapper with geography Ids
	*/
	public static WrapperInst createData()
	{
        EDGE_UtilityTestClass.createOrgSettings();
       	Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
 		//Creating dummy pickup options   
       	Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
       	Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
       	secCountry.Name = 'Australia Country1';
       	secCountry.Code__c = 'AU1';
       	secCountry.Parent_Geography__c = country.Parent_Geography__c;
       	insert secCountry;
        Geography__c secCountry2 = EDGE_UtilityTestClass.createGeography('Country');
       	secCountry2.Name = 'Spain';
       	secCountry2.Code__c = 'ES1';
       	secCountry2.Parent_Geography__c = country.Parent_Geography__c;
       	insert secCountry2;
      
       	WrapperInst wrapObj = new WrapperInst();
       	wrapObj.secCountry = secCountry.Id;
       	wrapObj.secCountry2 = secCountry2.Id;
       	return wrapObj;
	}
	class WrapperInst
	{
       String secCountry{get;set;}
       String secCountry2{get;set;}
	}
}