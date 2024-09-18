/**********************************************************************
  Name: BatchApexErrorEventTrigger
=======================================================================
  Purpose: This is to handle BatchApexErrorEvent
=======================================================================
    History                                                            
    -------                                                            
    VERSION  AUTHOR            DATE              DETAIL
    1.0 -    Kapil Baliyan	   29/12/2019		 Initial Development ES20-6594
***********************************************************************/

trigger BatchApexErrorEventTrigger on BatchApexErrorEvent (after insert) {
    TriggerDispatcher.run(new BatchApexErrorEventHandler());
}