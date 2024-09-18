@isTest
private class ECM_AccrualsandItemsForSKUSchedulerTest{
@isTest
private static void testMethodForBatch(){

    Test.startTest();
    
       ECM_AccrualsandItemsForSKUBatchScheduler sch= new ECM_AccrualsandItemsForSKUBatchScheduler();
       String cronexp='0 0 * * * ? *';
       system.schedule('Run Test batch',cronexp,sch);
       System.assert(cronexp!=null,'cronexpshould not be null');
    Test.stopTest();

}




}