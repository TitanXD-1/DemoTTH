/**
 * @name: D1_TranslationsTrigger
 * @description: This is to handle D1_TranslationsTrigger Events
 * @history
 * VERSION      AUTHOR              DATE            DETAIL
 * 1.0          Gaurav Singh      18/04/2022        Initial Development
 **/
trigger D1_TranslationsTrigger on D1_Translations__c(before insert, after insert, before update, after update, before delete, after delete) {
    TriggerDispatcher.run(new D1_TranslationsTriggerHandler());
}