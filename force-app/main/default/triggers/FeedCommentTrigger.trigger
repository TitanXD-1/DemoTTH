/**********************************************************************
Name: FeedCommentTrigger
=======================================================================
Purpose: This is to handle FeedComment Trigger Events
=======================================================================
History                                                            
-------                                                            
VERSION  AUTHOR            DATE              DETAIL
1.0 -    Amar Deep	       10/02/2021      Initial Development(ES20-9704)
***********************************************************************/
trigger FeedCommentTrigger on FeedComment (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
TriggerDispatcher.run(new FeedCommentTriggerHandler());
}