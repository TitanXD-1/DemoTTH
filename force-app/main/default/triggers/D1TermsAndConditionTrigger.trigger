/**********************************************************************
    Name: D1TermsAndCondtionsTrigger
=======================================================================
    Purpose: This is to handle Account Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Praveen M         27/01/2021       Initial Development
***********************************************************************/
trigger D1TermsAndConditionTrigger on D1_Terms_Conditions__c (before insert, before update, before delete, after insert, after update, after delete, after undelete){
    TriggerDispatcher.run(new D1TermsConditionsHandler());         
}