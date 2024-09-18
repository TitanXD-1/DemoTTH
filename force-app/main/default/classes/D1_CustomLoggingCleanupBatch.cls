/*
 * @name: D1_CustomLoggingCleanupBatch
 * @discription: Clean Custom Logs for exeptions
 * @History
 * VERSION     AUTHOR           DATE       DETAIL
 * 1.0         Gaurav Singh    30/06/20    Initial Development(NCP-3577)
 **/
public class D1_CustomLoggingCleanupBatch implements Database.Batchable<sObject>,Schedulable {
   /**
    * @description 
    * @param SC 
    */   
    public void execute(SchedulableContext sc) {
        D1_CustomLoggingCleanupBatch logCloanup = new D1_CustomLoggingCleanupBatch();
        Database.executeBatch(logCloanup);
    }

    /**
    * @description 
    * @param BC 
    * @return  `Database.QueryLocator`
    */   
    public Database.QueryLocator start(Database.BatchableContext bc){
        Date logClearDate = system.today().addMonths(Integer.valueOf(Label.D1_CustomLoggingCleanupIntervalMonths)*-1);//NOPMD
        String query = 'Select id from Custom_Log__c where CreatedDate < :logClearDate';
        return Database.getQueryLocator(query);
    }

    /**
    * @description 
    * @param BC 
    * @param logs 
    */   
    public void execute(Database.BatchableContext bc, List<sObject> logs){
        Database.delete(logs);
    }

    /**
    * @description 
    * @param BC 
    */
    public void finish(Database.BatchableContext bc){
        System.debug(LoggingLevel.INFO, 'Batch Finish');  
    }
}