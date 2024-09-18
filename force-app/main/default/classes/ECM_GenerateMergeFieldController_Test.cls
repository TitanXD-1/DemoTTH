/*
@Name: public class ECM_GenerateMergeFieldController_Test 
@Purpose: Class with all handler methods of ECM_GenerateMergeFieldController.
@History                                                                                                                      
@VERSION  	AUTHOR              DATE              	DETAIL
1.0        	
2.0			Saurav Prasad		14/07/2023			142555	: CM static code violation for the classes_SFDC_Technical Debt
*/
@isTest
public class ECM_GenerateMergeFieldController_Test {
    @isTest
    public static void testECMGenerateMergeFieldController(){
        Test.startTest();
        ECM_GenerateMergeFieldController.getSobjects();
        list<ECM_GenerateMergeFieldController.fieldsWrapper> fieldList = ECM_GenerateMergeFieldController.getFields('Account');
        system.assertNotEquals(fieldList.size(), 0,'Not 0 ');
        Assert.areNotEqual(fieldList.size(), 0,'Not 0');
        Test.stopTest();
    }
}