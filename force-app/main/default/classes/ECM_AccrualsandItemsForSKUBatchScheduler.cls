global class ECM_AccrualsandItemsForSKUBatchScheduler implements schedulable{


    global void execute(schedulableContext sc){
    
        database.executebatch(new ECM_AccrualsAndItemsInsertForSKU_Batch(),50);
        database.executebatch(new ECM_AccrualsAndItemsInsertForPort_Batch(),50);
    
    }


}