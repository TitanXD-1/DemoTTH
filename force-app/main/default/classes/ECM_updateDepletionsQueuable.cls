/**********************************************************************
Name: ECM_updateDepletionsQueuable
=======================================================================
Purpose: This Class used to queue the data from "ECM_VolumeInputScreenController"
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Manikandan T         16/07/2021        Initial Development
2.0		 Saurav Prasad		  16/07/2021		Development for ECM-4663

***********************************************************************/

public class ECM_updateDepletionsQueuable implements Queueable {
    
    private List<Depletions__c> depletionList;
    String conId;
    String volumeWrap;

    public ECM_updateDepletionsQueuable(List<Depletions__c> depletionList,String conId,String volumeWrap ) {
        this.depletionList = depletionList;
        this.conId=conId;
            this.volumeWrap= volumeWrap;
    }
    public void execute(System.QueueableContext qc) {
        Upsert(depletionList);
        if(!Test.isRunningTest()){
        system.enqueueJob(new ECM_updatePaymentSummaryItemsQueuable(conId,volumeWrap));
        }
    }
}