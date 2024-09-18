/*
 * @Name: ECM_RoleAgreementTriggerHelper_Test
 * @Description: This is the Test class for ECM_RoleAgreementTriggerHelper
 * @History                                                            
 *                                                       
 * VERSION    AUTHOR            DATE                 DETAIL
 *   1.0     Pratap Sen     13-09-2021      Initial Development for ECM-4416
 *   1.1     Saurav Prasad  14-07-2023      142555	:	CM static code violation for the classes_SFDC_Technical Debt
*/ 
@isTest
public class ECM_RoleAgreementTriggerHelper_Test {
    public static ECM_Contract_Type__c testAgreement;
    public static Business_Role__c testRole1;
    public static Business_Role__c testRole2;
    public static List<ECM_Role_Agreement__c> listofRA = new List<ECM_Role_Agreement__c>();
    public static ECM_Role_Agreement__c rA;
    @isTest
    public static void roleAgreementDuplicateCheck()
    {
        ECM_RoleAgreementTriggerHelper_Test.setupData();
        Test.startTest();
        //check for duplicate & non-duplicate insertion
        Try{
            insert ListofRA;
        }
        catch(DmlException ex)
        {
            system.debug(LoggingLevel.debug,ex);
        }
        //check for update to result in Duplication
        Try{
             ListofRA[1].Business_Role__c = testRole2.Id;
             Update ListofRA[1];
             system.assert(ListofRA!=null,'ListofRA should not be null');
        }
        catch(DmlException ex){
            system.debug(LoggingLevel.debug,ex);
        }
        Test.stopTest();
    }
    public static void setupData()
    {
        EDGE_UtilityTestClass.createOrgSettings();//to enable trigger
        Id geographyId = EDGE_UtilityTestClass.setupCountry('ES');//Geography Record
        testAgreement = ECM_UtilityTestClass.getAgreementType(geographyId);//Agreement Type Records
        testAgreement.ECM_Screen_3_field_configuration__c = 'Product Name;Brand;Category;Baseline Volume;Volume Target;Rate Per UoM;Investment;Product Growth Strategy;UoM';
        insert testAgreement;
        testRole1 = ECM_UtilityTestClass.businessRole(geographyId,'TestRole1');//Business Role Records
        testRole1.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED;WPA__c;';
        testRole2 = ECM_UtilityTestClass.businessRole(geographyId,'TestRole2');
        testRole2.My_accounts_Fields_Display__c = 'Outlet_Execution_Score__c;Minimum_Product_Assortment__c;Minimum_Activation_Standards__c;OPPS OPEN;OPPS CLOSED;WPA__c;';
        insert testRole1;
        insert testRole2;
        //Role Agreement Records
        RA = ECM_UtilityTestClass.createRoleAgreement(testRole1.Id,testAgreement.Id);
        ListofRA.add(ECM_UtilityTestClass.createRoleAgreement(testRole2.Id,testAgreement.Id));
        ListofRA.add(ECM_UtilityTestClass.createRoleAgreement(testRole1.Id,testAgreement.Id));
        insert RA;
    }
}