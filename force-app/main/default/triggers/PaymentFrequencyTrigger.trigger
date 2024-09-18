/**********************************************************************
  Name: PaymentFrequencyTrigger
=======================================================================
  Purpose: This is to handle Payment Frequency Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR                 DATE              DETAIL
    1.0 -    Manikandan.T          10/12/2020      Initial Development
***********************************************************************/
trigger PaymentFrequencyTrigger on ECM_Payment_Frequency__c (before insert, before update,after insert, after update) {
    TriggerDispatcher.run(new ECM_PaymentFrequencyTriggerHandler());
}