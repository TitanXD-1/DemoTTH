/**

* @description : FeedItemTrigger

* @purpose : This is to handle FeedItem Trigger Events

* @history  :                                                         
                                                           
* VERSION  AUTHOR            DATE              DETAIL
* 1.0 -    Sandip Ghosh 	19/08/2020      Initial Development(ES20-8463)

*/
trigger FeedItemTrigger on FeedItem (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
  TriggerDispatcher.run(new FeedItemTriggerHandler());
}