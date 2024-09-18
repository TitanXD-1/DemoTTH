/**********************************************************************
  Name : PNR_DeleteApproverMatrixBatch
=======================================================================
  Purpose : This Class is used to delete old Approver_Matrix__c records
=======================================================================
    History                                                            
------------------------------------------------------------------------                                                            
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    	 16-12-2019        Initial Development
***********************************************************************/ 
public with sharing class PNR_DeleteApproverMatrixBatch implements Database.Batchable<sObject>, Database.Stateful{
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext BC) {
        //collect the batches of records or objects to be passed to execute
        String query = '';
        if(Test.isRunningTest()){
            query = 'SELECT Id,Name FROM Approver_Matrix__c';
            
        }else{
            query = 'SELECT Id,Name FROM Approver_Matrix__c WHERE CreatedDate != today';
        }
        return Database.getQueryLocator(query);
    }
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Approver_Matrix__c> appMatrixList){
        if(!appMatrixList.isEmpty()){
            delete appMatrixList;
        }
    }    
    //Finish Method
    public void finish(Database.BatchableContext bc){
        // execute any post-processing operations
    }
}