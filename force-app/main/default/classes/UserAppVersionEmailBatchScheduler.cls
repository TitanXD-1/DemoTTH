/*
Scheduler class for UserAppVersionEmailBatch 
*/
global class UserAppVersionEmailBatchScheduler implements Schedulable {
    global void execute(SchedulableContext sc) {
        UserAppVersionEmailBatch ar = new UserAppVersionEmailBatch(); 
        database.executebatch(ar,20);
    }
}