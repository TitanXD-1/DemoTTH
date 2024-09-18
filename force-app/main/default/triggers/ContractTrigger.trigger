/**********************************************************************
Name: ContractTrigger
=======================================================================
Purpose: This is to handle ContractTrigger Events
=======================================================================
History                                                            
-------                                                            
VERSION		AUTHOR			DATE              DETAIL
1.0		    Preyanka Ghosh 	07/06/2019      Initial Development
***********************************************************************/
trigger ContractTrigger on Contract (before insert, before update, before delete, after insert, after update, after delete, after undelete) { 
    /*if(ContractTriggerHandler.isFirstTime){
        system.debug('within Trigger');
        ContractTriggerHandler.isFirstTime = false;
        TriggerDispatcher.run(new ContractTriggerHandler());
    }*/
    TriggerDispatcher.run(new ContractTriggerHandler());    
}