/**********************************************************************
  Name: PartnerFunctionTrigger
=======================================================================
  Purpose: 
=======================================================================
    History                                                            
    -------                                                            
 VERSION  	  AUTHOR            DATE              DETAIL
  
***********************************************************************/
trigger PartnerFunctionTrigger on PNR_Partner_Function__c (before insert, before update, before delete, after insert, after update, after delete, after undelete ) {
    TriggerDispatcher.run(new PartnerFunctionHandler());
}