/**********************************************************************
Name: EDGE_CallTypeTriggerHelperTest
=======================================================================
Purpose: Trigger Helper Class for CallTypeTrigger
=======================================================================
History                                                            
-------                                                            
VERSION       AUTHOR            DATE              DETAIL
1.0       Preyanka Ghosh       20/05/2019        ES20-1615
2.0       Swaraj Samanta       06/09/2022        ES20-13284
***********************************************************************/
@isTest
public class EDGE_CallTypeTriggerHelperTest {
    
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
         //Creating Business Role Record
        Call_Type__c callType = EDGE_UtilityTestClass.getCallType(countryId);
        callType.Global_Equivalent_Call_Type__c='Virtual';
        insert callType;
        system.assert(callType.Id != null,'callType Id should not be null');
        
        Geography__c country = [SELECT Id, Code__c, Parent_Geography__c FROM Geography__c WHERE Id = :countryId];
        Geography__c secCountry = EDGE_UtilityTestClass.createGeography('Country');
        secCountry.Name = 'Australia Country1';
        secCountry.Code__c = 'AU1';
        secCountry.Parent_Geography__c = country.Parent_Geography__c;
        insert secCountry;
        
        
        callType.Country__c = secCountry.Id;
        update callType;        
        delete callType;
        undelete callType;
        Test.stopTest();
    }

}