/**********************************************************************
  Name : PNR_DeleteApproverMatrixBatchTest
=======================================================================
  Purpose : This is the test class for PNR_DeleteApproverMatrixBatch and PNR_ScheduleDeleteApproverMatrixBatch
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    	 16-12-2019        Initial Development
***********************************************************************/
@isTest
public class PNR_DeleteApproverMatrixBatchTest {
	@isTest
    public static void validateBatch(){
        Approver_Matrix__c createAppMatObj = PNR_TestDataUtility.getApproverMatrix();
        insert createAppMatObj;
        System.assert(createAppMatObj.Id != null);
        Test.startTest();
        PNR_DeleteApproverMatrixBatch batchInst = new PNR_DeleteApproverMatrixBatch(); 
        Database.executebatch(batchInst,200);
        Test.stopTest();
        List<Approver_Matrix__c> appMatList = [SELECT Id FROM Approver_Matrix__c];
        System.assertEquals(0, appMatList.size());
    }
    @isTest
    public static void validateSchedule(){
        Approver_Matrix__c createAppMatObj = PNR_TestDataUtility.getApproverMatrix();
        insert createAppMatObj;
        System.assert(createAppMatObj.Id != null);
        Test.startTest();
        PNR_ScheduleDeleteApproverMatrixBatch shlrCls = new PNR_ScheduleDeleteApproverMatrixBatch();
        String sch = '0 0 23 * * ?'; 
        system.schedule('Test Territory Check', sch, shlrCls); 
        Test.stopTest();
    }
}