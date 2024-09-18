/**********************************************************************
Name: StrategyCategoriesTrigger
=======================================================================
Purpose: This is to handle Strategy_Categories__c Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION      AUTHOR             DATE              DETAIL
1.0          Manikant Prasad   01/07/2019         ES20-2869     
***********************************************************************/
trigger StrategyCategoriesTrigger on Strategy_Categories__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    
  TriggerDispatcher.run(new StrategyCategoriestriggerHandler());
}