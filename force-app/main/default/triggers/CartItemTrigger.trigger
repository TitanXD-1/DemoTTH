/**********************************************************************
    Name: CartItemTrigger
=======================================================================
    Purpose: This is to handle Account Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Darshi Arpitha    06/02/2019      Initial Development
***********************************************************************/
trigger CartItemTrigger on CartItem (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    TriggerDispatcher.run(new CartItemTriggerHandler()); 
    /*if(Trigger.isBefore && Trigger.isInsert){
    CartItemTriggerHelper.updateOrdersplit(Trigger.New);
    }*/                              
}