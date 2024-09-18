/**********************************************************************
Name: AgreementTypeTrigger_Test
=======================================================================
Req: Test Class for  AgreementType Trigger 
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Anives Muppa            11-12-2020         ECM-3573
2.0    Joshraj Sen/Sakshi Shah   16-05-2024         PMD Fix 152943
***********************************************************************/
/** 
 *@description Test Class for AgreementType Trigger 
**/
@isTest
public class AgreementTypeTrigger_Test {
	/*******************************************************************
Method  : checkSharingTest
Purpose : To check the sharing of object
********************************************************************/
/** 
 *@description Test Class to check Sharing
**/
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
       
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
         //Creating Pickup Option Record
        ECM_Contract_Type__c contractType=new ECM_Contract_Type__c();
        contractType.Name='Promotional';
        //contractType.Geography__c=geographyId;
        contractType.ECM_Abbreviation__c='POM';
        contractType.ECM_Screen_3_field_configuration__c='Product Name;Brand;UoM;Volume Target;Rate Per UoM;Investment';
        contractType.ECM_Automatic_approval_amount_threshold__c=40.00;
        insert contractType;
        system.assert(contractType.Id != null,'Contract Type ID should not be null.');        

        contractType.Geography__c = secCountry.Id;
        update contractType;        
        delete contractType;
        undelete contractType;
        Test.stopTest();
    }
}