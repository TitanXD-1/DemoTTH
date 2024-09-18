/**********************************************************************
Name: ECM_ScheduleBatchPromoPrePytPS
=======================================================================
Purpose: This is Class for scheduling a batch class ECM_BatchPromoPrePaymentPSGeneration
Test Class: ECM_ScheduleBatchPromoPrePytPS_Test
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Pradeep Kumar Reddy    03/11/2020       ECM-2252: Promo-Prepayment PS auto-generation for PF=Partial prepayment_SFDC_Logic_EU_Payment management
***********************************************************************/
global class ECM_ScheduleBatchPromoPrePytPS implements Schedulable{
    global void execute(SchedulableContext SC) {
        /*ECM_BatchPromoPrePaymentPSGeneration b = new ECM_BatchPromoPrePaymentPSGeneration();
        database.executeBatch(b);*/
    }
}