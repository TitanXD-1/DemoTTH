/*
*Name: ECM_CustomLookUpSearchController_Test

*Purpose: This class is used to cover testclass for the - ECM_CustomLookUpSearchController

*History                                                            
                                                            
*VERSION    AUTHOR                   DATE              DETAIL
1.0      Saurav Kumar Prasad      14/04/2020        Initial Development
            
*/
@isTest
public class ECM_CustomLookUpSearchController_Test {
@testSetup static void setup() {
    Test.startTest();
    Account acc=EDGE_UtilityTestClass.getOwnerOperatorAccount();
    acc.Person_Responsible__c=UserInfo.getUserId();
    Insert acc;  
    Test.stopTest();
}
@isTest 
static void fetchLookUpValuesTestNegative() {
    Test.startTest();
    List<Sobject> lookUpList = new List<Sobject>();
    lookUpList = ECM_CustomLookUpSearchController.fetchLookUpValues('TestAcct','Account');
    Test.stopTest();
System.assert(lookUpList!=null,'lookUpList should not be null');
}
@isTest 
static void fetchLookUpValuesTestPostive() {
    Test.startTest();
    List<Sobject> lookUpSearchList = new List<Sobject>();
    lookUpSearchList = ECM_CustomLookUpSearchController.fetchLookUpValues('Test_OwnerAccount','Account');
    Test.stopTest();
    System.assert(lookUpSearchList!=null,'lookUpSearchList should not be null'); 
}
}