/**********************************************************************
    Name: TerritoryHierarchyMemberTrigger
=======================================================================
    Purpose: This is to handle TerritoryHierarchyMember Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
       1.0 - Shahbaz Khan     25/07/2019      Initial Development
***********************************************************************/

trigger TerritoryHierarchyMemberTrigger on Territory_Hierarchy_Member__c(before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new TerritoryHierarchyMemberHandler());
}