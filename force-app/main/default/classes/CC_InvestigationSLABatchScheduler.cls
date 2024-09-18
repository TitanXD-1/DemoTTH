/************************************************************************
Name: CC_MilestoneMinutesCalculator
=========================================================================
Purpose: This class is used to schedule CC_InvestigationSLABatch class
=========================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                   DATE              DETAIL
1.0      Jayashree               10-04-2021        Initial Development

*************************************************************************/

public class CC_InvestigationSLABatchScheduler implements Schedulable {
    public void execute(SchedulableContext ctx) {
        CC_InvestigationSLABatch invSLABatch = new CC_InvestigationSLABatch();
        Id batchId = Database.executeBatch(invSLABatch);
        
    }
}