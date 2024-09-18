/*
 * Class Name : SalesOrganisationTrigger
 * @description: This is Sales Organisation Trigger
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
 * 1.0        CST Team  		19/05/2021        Initial Development
*/

trigger SalesOrganisationTrigger on Sales_Organisation__c (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
   TriggerDispatcher.run(new SalesOrganisationTriggerHandler());
}