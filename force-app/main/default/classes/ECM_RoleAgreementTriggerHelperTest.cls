/*
 @Name: ECM_RoleAgreementTriggerHelperTest
 @Description: This is the Test class for ECM_RoleAgreementTriggerHelper
 @History                                                            
                                                        
 VERSION    AUTHOR       DATE                 DETAIL
  1.0     Pratap Sen  13-09-2021  Initial Development for ECM-4416
  2.0     Pratap Sen  22-12-2021  Technical Debt Changes against ECM-4994
*/ 
@isTest
public class ECM_RoleAgreementTriggerHelperTest {
   /**
    * @Name : insertRoleAgreementValidationTest
	* @description : This method is used to test the RoleAgreementDuplicateCheck() method of the ECM_RoleAgreementTriggerHelper class
	*/
    @isTest
    public static void insertRoleAgreementValidationTest()
    {
        WrapperInst wrapobj = createData();
        ECM_Role_Agreement__c roleAggObj = ECM_UtilityTestClass.createRoleAgreement(wrapobj.businessRoleObj,wrapobj.aggTypeObj);
        Test.startTest();
        try
        {
            insert roleAggObj;
        }
        catch(DmlException ex)
        {
            System.assert(ex.getMessage().contains(String.valueof(Label.ECM_Duplicate_Role_Agreement_Error_Msg).split('\\:')[0]),'Exception Caught');
        }
        Test.stopTest();
        
    }
   /**
    * @Name : updateRoleAgreementValidationTest
	* @description : This method is used to test the RoleAgreementDuplicateCheck() method of the ECM_RoleAgreementTriggerHelper class
	*/
    @isTest
    public static void updateRoleAgreementValidationTest()
    {
        WrapperInst wrapobj = createData();
        ECM_Role_Agreement__c roleAggObj = ECM_UtilityTestClass.createRoleAgreement(wrapobj.businessRoleObj,wrapobj.aggTypeObj);
        Test.startTest();
        try
        {
            update roleAggObj;
            system.assert([SELECT id FROM ECM_Role_Agreement__c WHERE Agreement_Type__c =: wrapobj.aggTypeObj
                          LIMIT 1].id != NULL,'role agreement record exists');
        }
        catch(DmlException ex)
        {
            system.debug(LoggingLevel.WARN,'Exception caught '+ex);
        }
        Test.stopTest();
    }
   /**
    * @Name : createData()
	* @description : This method is used to create test data for RoleAgreementDuplicateCheck() method of the ECM_RoleAgreementTriggerHelper class
    * @return : Returns Wrapper with agreement type & business role
	*/
    public static WrapperInst createData()
    {
        Id countryId = EDGE_UtilityTestClass.setupCountry('ES');
        EDGE_UtilityTestClass.createOrgSettings();
        
		Business_Role__c businessRoleObj = ECM_UtilityTestClass.businessRole(countryId,'test');
		insert businessRoleObj;
        ECM_Contract_Type__c aggTypeObj = ECM_UtilityTestClass.getAgreementType(countryId);
        insert aggTypeObj;
        ECM_Role_Agreement__c roleAggObj = ECM_UtilityTestClass.createRoleAgreement(businessRoleObj.Id,aggTypeObj.Id);
        insert roleAggObj;
        
        WrapperInst wrapObj = new WrapperInst();
        wrapObj.businessRoleObj= businessRoleObj.Id;
        wrapObj.aggTypeObj = aggTypeObj.Id;
        return wrapObj;
    }
    class WrapperInst
    {
        String businessRoleObj{get;set;}
        String aggTypeObj{get;set;}
    }
}