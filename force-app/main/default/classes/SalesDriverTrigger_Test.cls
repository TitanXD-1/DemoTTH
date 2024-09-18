/**********************************************************************
Name: SalesDriverTrigger_Test
=======================================================================
Req: Test Class for  SalesDriverTrigger_Test 
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Veerendra           11-12-2020         ECM-3573

***********************************************************************/
@isTest
public class SalesDriverTrigger_Test {
	/*******************************************************************
Method  : checkSharingTest
Purpose : To check the sharing of object
********************************************************************/
    @isTest
    public static void checkSharingTest(){
        //Creating Org setting
        EDGE_UtilityTestClass.createOrgSettings();
        Test.startTest();
        Id countryId = EDGE_UtilityTestClass.setupCountry('AUT');
        //Creating Pickup Option Record
 
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        Geography__c secCountry_2 = EDGE_UtilityTestClass.createGeography('Country');
        secCountry_2.Name = 'Spain';
        secCountry_2.Code__c = 'ES1';
        secCountry_2.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry_2;
               
        ECM_Sales_Driver__c Salesdrive=new ECM_Sales_Driver__c();
        Salesdrive.Name='Promotional';
        Salesdrive.Geography__c=secCountry.Id;
        Salesdrive.ECM_Is_Range__c=true;
        insert Salesdrive;
        system.assert(Salesdrive.Id != null);
        
        Salesdrive.Geography__c = secCountry_2.Id;
        update Salesdrive;        
        
        delete Salesdrive;
        undelete Salesdrive;
        
        Test.stopTest();
    }
}