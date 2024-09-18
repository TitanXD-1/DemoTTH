/**********************************************************************
Name: ScheduleJobEMEA

=======================================================================
History                                                            
-------                                                            
VERSION     AUTHOR           DATE            DETAIL
1.0         Dipanjan Das     25/03/2019      Test Class for ScheduleJobEMEA

***********************************************************************/

public with sharing class ScheduleJobEMEA implements Schedulable{
    
    //Execute method to start the batch job
    public void execute(SchedulableContext sC) {
        if(Schema.sObjectType.Batch_Job_Current_Region__c.isUpdateable()){
        Batch_Job_Current_Region__c currentRegion = Batch_Job_Current_Region__c.getValues('Current Region');
        currentRegion.Region__c ='EMEA';
        update currentRegion;
        
        //Schedule "Activity Management Batch"
        string activityMgmt = 'ActivityManagementBatchJob_Scheduler';
        ActivityManagementBatchJobScheduler activityManagementCls = new ActivityManagementBatchJobScheduler ();
        String strActivityMgmt = Datetime.now().addSeconds(60).format('s m H d M ? yyyy');
        System.schedule('Batch Job - ' + activityMgmt + ' ' + strActivityMgmt, strActivityMgmt, activityManagementCls);
        
        //Schedule "Territory Management Batch"
        string territoryMgmt = 'TerritoryManagementBatchJob_Scheduler';
        TerritoryManagementBatchJobScheduler territoryManagementCls = new TerritoryManagementBatchJobScheduler ();
        String strTerritoryMgmt = Datetime.now().addSeconds(120).format('s m H d M ? yyyy');
        System.schedule('Batch Job - ' + territoryMgmt + ' ' + strTerritoryMgmt, strTerritoryMgmt, territoryManagementCls);
        
        //Schedule "Territory Management Batch"
        string miscellaneous = 'MiscellaneousBatchJob_Scheduler';
        MiscellaneousBatchJobScheduler miscellaneousCls = new MiscellaneousBatchJobScheduler ();
        String strMiscellaneous = Datetime.now().addSeconds(180).format('s m H d M ? yyyy');
        System.schedule('Batch Job - ' + miscellaneous + ' ' + strMiscellaneous, strMiscellaneous, miscellaneousCls);
    }
}
}