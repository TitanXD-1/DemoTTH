/**********************************************************************
Name: Product2Trigger
=======================================================================
Purpose: This is to handle Product2 Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Kapil Baliyan      16/12/2020        NCP-1403 
***********************************************************************/
trigger Product2Trigger on Product2 (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new Product2TriggerHandler());
    
}