/**
* @description GT_BatchPostStoreToTraxBatchScheduler
* @history                                                            
                                                           
VERSION     AUTHOR                  DATE              DETAIL
1.0         Joshraj Sen          08/06/2023           GT-140 Scheduler Class for GT_PostStoretoTraxBatch
*/
public with sharing class GT_BatchPostStoreToTraxBatchScheduler implements Schedulable {
  
	public void execute(SchedulableContext sc){
        GT_PostStoretoTraxBatch batch = new GT_PostStoretoTraxBatch();
        Database.executeBatch(batch,Integer.valueof(Label.Global_Travel_Trax_Batch_Scheduler));
    }
}