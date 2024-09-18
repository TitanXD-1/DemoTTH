/*
@Name: ECM_ContractStatusChangeBatchTest
@Description: This Class is test class for ECM_ContractStatusChangeBatch class.
@History                                                                                                                       
 * VERSION    AUTHOR                    DATE              DETAIL
 * 1.1        Tanishq Banerjee       22/03/2022    ECM-5351 - Contract Status to Expired_SFDC_GLO 
 * 1.2        Anshu Prakash          22/03/2022    ECM-5357 - Contract Status to Closed_SFDC_GLO 
*/

@isTest
public class ECM_ContractStatusChangeBatchTest{
	@isTest
	public static void validateContractStatusChangeBatchES(){
		Id countryId = EDGE_UtilityTestClass.setupCountrySpain('ES');
		system.assert(countryId!= null,'countryId should not be null');
		String conOutletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
		
		Geography__c  marketObj;
        List<Geography__c> marketList = [SELECT Id FROM Geography__c WHERE Name ='Global1'];
        if(!marketList.isEmpty()){
            marketObj = EDGE_UtilityTestClass.createGeography('Market');
            marketObj.Name = 'Europe and Turkey';
            marketObj.Code__c = 'EAT2';
            marketObj.Parent_Geography__c = marketList[0].Id;
            insert marketObj;
        }
        
		User salesRep = ECM_UtilityTestClass.createUser('srp',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
		salesRep.Username= 'sRep134@test.com';
		insert salesRep;
        
		
		Account acc = EDGE_UtilityTestClass.getOutletRecord();
		acc.country__c = countryId;
		acc.Sales_Org__c='sale';
		acc.SAP_Sold_to__c='sapsold';
		acc.Independent_of_Operator__c=true;
		acc.Independent_of_Owner__c=true;
		insert acc;
		
		ECM_Contract_Type__c aggType = ECM_UtilityTestClass.createContractType(countryId);
		insert aggType;
		
		Contract contr = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr.ECM_Agreement_Type__c= aggType.Id;
		contr.ownerId=salesRep.Id;
		contr.StartDate = System.today() - 7;
		contr.Contract_End_Date__c = System.today() - 1;
		contr.Status='Draft';
		insert contr;
		contr.Status='Active';
		update contr;
		
		ECM_Payment_Summary__c ps1 = ECM_UtilityTestClass.getPaymentSummary(contr.Id);
		ps1.ECM_Payment_Summary_Status__c='Completed';
		ps1.ECM_Type__c='Volume-Based';
		insert ps1;
		
		Contract contr1 = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr1.ECM_Agreement_Type__c= aggType.Id;
		contr1.ownerId=salesRep.Id;
		contr1.StartDate = System.today() - 7;
		contr1.Contract_End_Date__c = System.today() - 1;
		contr1.Status='Draft';
		insert contr1;
		contr1.Status='Active';
		update contr1;
		
		ECM_Payment_Summary__c ps2 = ECM_UtilityTestClass.getPaymentSummary(contr1.Id);
		ps2.ECM_Payment_Summary_Status__c='Open';
		ps2.ECM_Type__c='Volume-Based';
		insert ps2;
		Test.startTest();
		Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c,
												  Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_ContractStatusChangeBatch' AND 
												  Country_Code__c = 'ES'];
        String className = batchSetting.Batch_Class__c;
		Type t  = Type.forName(className);
		BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
		job.getBatchDetails(batchSetting);
		Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
		Test.stopTest();		
	}
	
	@isTest
	public static void validateContractStatusChangeBatchAU(){
		Id countryId = EDGE_UtilityTestClass.setupCountry('AU');
		system.assert(countryId!= null,'countryId should not be null');
		String conOutletRecTypeId = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        
		User salesRep = ECM_UtilityTestClass.createUser('srp1',ECM_UtilityTestClass.getProfile('Sales Representative').Id);
		salesRep.Username= 'sRep134@test.com';
		insert salesRep;
        
		Account acc = EDGE_UtilityTestClass.getOutletRecord();
		acc.country__c = countryId;
		acc.Sales_Org__c='sale';
		acc.SAP_Sold_to__c='sapsold';
		acc.Independent_of_Operator__c=true;
		acc.Independent_of_Owner__c=true;
		insert acc;
		
		ECM_Contract_Type__c aggType = ECM_UtilityTestClass.createContractType(countryId);
		insert aggType;
		
		Contract contr = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr.ECM_Agreement_Type__c= aggType.Id;
		contr.ownerId=salesRep.Id;
		contr.StartDate = System.today() - 7;
		contr.Contract_End_Date__c = System.today() - 1;
		contr.Status='Draft';
        contr.UOS_Earnt__c = 80;
		contr.UOS_Target__c=8;
		insert contr;
		contr.Status='Active';
		update contr;
		
		ECM_Payment_Summary__c ps1 = ECM_UtilityTestClass.getPaymentSummary(contr.Id);
		ps1.ECM_Payment_Summary_Status__c='Completed';
		ps1.ECM_Type__c='Volume-Based';
		insert ps1;
		
		Contract contr1 = ECM_UtilityTestClass.createContract(acc.Id,conOutletRecTypeId);
		contr1.ECM_Agreement_Type__c= aggType.Id;
		contr1.ownerId=salesRep.Id;
		contr1.StartDate = System.today() - 7;
		contr1.Contract_End_Date__c = System.today() - 1;
		contr1.Status='Draft';
        contr1.UOS_Earnt__c = 80;
		contr1.UOS_Target__c=8;
		insert contr1;
		contr1.Status='Active';
		update contr1;
		
		ECM_Payment_Summary__c ps2 = ECM_UtilityTestClass.getPaymentSummary(contr1.Id);
		ps2.ECM_Payment_Summary_Status__c='Open';
		ps2.ECM_Type__c='Volume-Based';
		insert ps2;
        
		Test.startTest();
		Market_Batch_Setting__mdt batchSetting = [SELECT MasterLabel, Batch_Class__c, Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c,
												  Region__c FROM Market_Batch_Setting__mdt WHERE Batch_Class__c = 'ECM_ContractStatusChangeBatch' AND 
												  Country_Code__c = 'AU'];
        String className = batchSetting.Batch_Class__c;
		Type t  = Type.forName(className);
		BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
		job.getBatchDetails(batchSetting);
		Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
		Test.stopTest();		
	}
	
}