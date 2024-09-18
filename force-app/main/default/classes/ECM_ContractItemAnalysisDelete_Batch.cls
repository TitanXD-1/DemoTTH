global class ECM_ContractItemAnalysisDelete_Batch implements Database.Batchable<sObject>, Database.Stateful{
    global ECM_ContractItemAnalysisDelete_Batch(){
    }

    global Database.QueryLocator start(Database.BatchableContext BC){
      date AfterNinety =  system.today().adddays(-90);
        return Database.getQueryLocator([
            select Id
            from ECM_Contract_Item_Analysis__c
            where CreatedDate =:AfterNinety 
            ]);
    }

    global void execute(Database.BatchableContext BC, List<ECM_Contract_Item_Analysis__c>scope){
       // delete scope;
        Database.DeleteResult[] drList = Database.delete(scope, false);
        for(Database.DeleteResult dr : drList) {
    if (dr.isSuccess()) {
        // Operation was successful, so get the ID of the record that was processed
        System.debug('Successfully deleted Analysis record with ID: ' + dr.getId());
    }
    else {
        // Operation failed, so get all errors                
        for(Database.Error err : dr.getErrors()) {
            System.debug('The following error has occurred.');                    
            System.debug(err.getStatusCode() + ': ' + err.getMessage());
            System.debug('Analysis record fields that affected this error: ' + err.getFields());
        }
    }
}

    }

    global void finish(Database.BatchableContext BC){
    }
}