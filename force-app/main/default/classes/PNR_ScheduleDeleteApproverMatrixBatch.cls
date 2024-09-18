/**********************************************************************
  Name : PNR_ScheduleDeleteApproverMatrixBatch
=======================================================================
  Purpose : This is the Scheduler class for PNR_DeleteApproverMatrixBatch
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    	 16-12-2019        Initial Development
***********************************************************************/ 
public with sharing class PNR_ScheduleDeleteApproverMatrixBatch implements Schedulable {
   public void execute(SchedulableContext sc) {
      PNR_DeleteApproverMatrixBatch batchInst = new PNR_DeleteApproverMatrixBatch(); 
      Database.executebatch(batchInst,200);
   }
}