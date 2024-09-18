/**********************************************************************
    Name: CartTrigger
=======================================================================
    Purpose: This is to handle Account Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Darshi Arpitha    11/01/2021       Initial Development
***********************************************************************/
trigger CartTrigger on WebCart (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    TriggerDispatcher.run(new CartTriggerHandler());         
}