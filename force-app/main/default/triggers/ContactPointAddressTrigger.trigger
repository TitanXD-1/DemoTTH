/**
* @description This is to handle ContactPointAddress trigger events
* @history
* 1.1     Indranil Roychowdhury       22/06/2022
*/

trigger ContactPointAddressTrigger on ContactPointAddress (before insert, before update, before delete, after insert, after update, after delete, after undelete) {
    TriggerDispatcher.run(new ContactPointAddressHandler());
}