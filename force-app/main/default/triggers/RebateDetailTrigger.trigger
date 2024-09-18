/**********************************************************************
    Name: RebateDetailTrigger
    =======================================================================
    Purpose: This is to handle Rebate Detail Trigger Events
    =======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR          DATE           DETAIL
    1.0      Dipanjan D      12/07/2019     ES20-2984 : SFDC_Rebate record NEW to APPROVED
***********************************************************************/

    trigger RebateDetailTrigger on Rebate_Detail__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
        TriggerDispatcher.run(new RebateDetailTriggerHandler());
    }