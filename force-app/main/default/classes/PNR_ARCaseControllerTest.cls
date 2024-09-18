/**********************************************************************
Name: PNR_ARCaseControllerTest
=======================================================================
Req: This is the test class for PNR_ARCaseController. 
=======================================================================
History                                                            
------------------------------------------------------------------------                                                          
VERSION   AUTHOR            DATE              DETAIL
1.0  	  Saurav Paul	    07/12/2019      Initial Development

***********************************************************************/
@isTest
public class PNR_ARCaseControllerTest {
    @isTest
    public static void testFunc(){
        Case caseObj = PNR_TestDataUtility.getCaseData();
        insert caseObj;
        System.assert(caseObj.Id != null);
        List<String> caseType = PNR_ARCaseController.getCaseTypeLst('Account Receivable Cases');
        String hlpText = PNR_ARCaseController.getHelpTextMsg('Account Receivable Cases','Billing Request');
        String caseTypeVal = PNR_ARCaseController.setCaseType(caseObj.Id);
        String recTypeName = PNR_ARCaseController.getRecTypeName(caseObj.Id);
    }
}