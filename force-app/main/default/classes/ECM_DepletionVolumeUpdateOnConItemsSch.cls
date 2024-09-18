global class ECM_DepletionVolumeUpdateOnConItemsSch implements Schedulable{
    global void execute(SchedulableContext sc)
    {
        ECM_DepletionVolumeUpdateOnConItemsBatch depvolupdatebatch = new ECM_DepletionVolumeUpdateOnConItemsBatch(); 
        database.executebatch(depvolupdatebatch);
    }
    
}