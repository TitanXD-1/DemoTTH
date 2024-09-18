/**********************************************************************
  Name: CorrectionDocumentTrigger
=======================================================================
  Purpose: This is to handle Correction Document Trigger Events
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Saurav Paul       11/08/2019      Initial Development
***********************************************************************/

trigger CorrectionDocumentTrigger on Correction_Document__c (before insert, before update, before delete, 
                                                             after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new CorrDocuTriggerHandler());
}