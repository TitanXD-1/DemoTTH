public with sharing class MiscellaneousBatchJobScheduler implements Schedulable{
    
    public void execute(SchedulableContext sc) {
        Batch_Job_Current_Region__c currentRegion = Batch_Job_Current_Region__c.getValues('Current Region');
        //string currentBatchClassSetting = currentRegion.Region__c + 'Miscellaneous' + '11';
        string currentBatchClassSetting = currentRegion.Region__c + 'Miscellaneous' + '438';
        
        System.debug('--currentBatchClassSetting--'+currentBatchClassSetting);
        if( Schema.sObjectType.Market_Batch_Setting__mdt.isAccessible()){
            Market_Batch_Setting__mdt batchSetting = [select MasterLabel, Batch_Class__c,Country_Code__c,
                                                      Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c,Frequency__c from Market_Batch_Setting__mdt
                                                      where MasterLabel =:currentBatchClassSetting];
            
            boolean runBatch= EDGE_BatchUtilityClass.getBatchFrequency(batchSetting);
            if(Test.isRunningTest()){
                runBatch = false;
            }
            if(runBatch){
                String className = batchSetting.Batch_Class__c;
                Type t = Type.forName(className);
                BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
                job.getBatchDetails(batchSetting);
                Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
            }
            else{
                Market_Batch_Setting__mdt  nextBatch= EDGE_BatchUtilityClass.getNextBatch(batchSetting,false);
                String className = nextBatch.Batch_Class__c;
                Type t = Type.forName(className);
                BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
                job.getBatchDetails(nextBatch);
                Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(nextBatch.Scope__c));
            }  
            
            // Clean up the scheduled class
            System.abortJob(sc.getTriggerId());
        }
    }
}