/**********************************************************************
    Name: PortfolioItemTrigger
=======================================================================
    Purpose: This is to handle Account Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Darshi Arpitha    08/02/2021       Initial Development
***********************************************************************/
trigger PortfolioItemTrigger on Portfolio_Item__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
	TriggerDispatcher.run(new PortfolioItemTriggerHandler());
}