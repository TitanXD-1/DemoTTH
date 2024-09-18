/**********************************************************************
Name: ECM_SchdleBatchPromoPrePytPsfor100PrePyt
=======================================================================
Purpose: This is Class for scheduling a batch class ECM_BatchPromoPrePymntPSfor100PrePymnt
Test Class: ECM_SchdleBchPrmPrPytPSfor100PrPyt_Test
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0      Pradeep Kumar Reddy    03/11/2020       ECM-2251: Promo-Prepayment PS auto-generation for PF=100% prepayment
***********************************************************************/

global class ECM_SchdleBatchPromoPrePytPsfor100PrePyt implements Schedulable{
	global void execute(SchedulableContext SC) {
        ECM_BatchPromoPrePymntPSfor100PrePymnt b = new ECM_BatchPromoPrePymntPSfor100PrePymnt();
        database.executeBatch(b);
    }
}