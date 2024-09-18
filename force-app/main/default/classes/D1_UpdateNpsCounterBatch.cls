/**
 * @name : D1_UpdateNpsCounterBatch
 * @description : Database.update() Counter whenever the survey linked is updated or created in d1 settings
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Narayana        21/06/2022   Initial Development (NCP-6925)
 */
public with sharing class D1_UpdateNpsCounterBatch implements Database.Batchable<SObject>,Schedulable,Database.Stateful,Database.RaisesPlatformEvents {
    List<FlowInputs> request;
    String errormsgs='';
    Boolean hasError=false;
    Country_Batch_Job_Log__c batchJobLog;
    Market_Batch_Job__c markBatch;
    

    public class FlowInputs{
        @InvocableVariable public string countryCode;
        @InvocableVariable public string countryIds;
    }
    public D1_UpdateNpsCounterBatch(List<FlowInputs> request) {
        this.request = request;
    }
    @InvocableMethod(label='Schedule Update Nps Counter')
    public static void scheduleNpsCounterBatch(List<FlowInputs> request){
        String jobName= 'D1_UpdateNpsCounterBatch' + '[' + request[0].countryCode + ']';
        List<CronTrigger> existingJobsList = [SELECT CronJobDetail.Name,state FROM CronTrigger WHERE State NOT IN('DELETED','COMPLETED') AND CronJobDetail.Name=:jobName];
        if(existingJobsList.isEmpty()){
            String cronExp = Datetime.now().addMinutes(30).format('s m H d M ? yyyy');  
            System.schedule(jobName,cronExp,new D1_UpdateNpsCounterBatch(request));
        }  
    }

    public Database.QueryLocator start(Database.BatchableContext bc){
        String countryId = request[0].countryIds; //NOPMD
        String query;
        markBatch = new Market_Batch_Job__c();
        markBatch.Name = 'D1_UpdateNpsCounterBatch' + '[' + request[0].countryCode + ']'+System.now();
        markBatch.Status__c = 'In Progress';
        markBatch.Type__c = 'Miscellaneous';
        markBatch.Last_Run_Start__c = System.now();
        markBatch.Current_Batch_Class_Name__c = 'D1_UpdateNpsCounterBatch';
        if(Schema.sObjectType.Market_Batch_Job__c.IsCreateable()){
            insert markBatch;
        }
        batchJobLog = new Country_Batch_Job_Log__c();
        batchJobLog.Name = 'D1_UpdateNpsCounterBatch' + '[' + request[0].countryCode + ']'+System.now();
        batchJobLog.Status__c = 'In Progress';
        batchJobLog.Start__c = System.now();
        batchJobLog.Finish__c = null;
        batchJobLog.Batch_Job_Id__c = bc.getJobId();
        batchJobLog.Country__c = request[0].countryIds;
        batchJobLog.Market_Batch_Job__c =markBatch.Id;
        batchJobLog.Batch_Class_Name__c ='D1_UpdateNpsCounterBatch';
        if(Schema.sObjectType.Country_Batch_Job_Log__c.IsCreateable()){
            insert batchJobLog;
        }
        query ='SELECT Id,Name,D1_Login_Counter__c FROM Contact WHERE ID IN (SELECT ContactId from AccountContactRelation where Contact.Account.Country__c =:countryId and D1_Active__c =true )';
        return Database.getQueryLocator(query);
    }
    public void execute(SchedulableContext sc) {
        Database.executeBatch(new D1_UpdateNpsCounterBatch(request));
        System.abortJob(sc.getTriggerId());
    }
    public void execute(Database.BatchableContext bc,List<Contact> contactList){
        for(Contact con:contactList){
            con.D1_Login_Counter__c =0;
        }
        Integer contactIndex = 0;
        Database.SaveResult[] results = Database.update(contactList,false);
        for(Database.SaveResult result :results){
            if(!result.isSuccess()){
                hasError = true;
                errormsgs+= 'Contact Record: '+' '+contactList[contactIndex].Id+' '+contactList[contactIndex].Name+' error: '+result.getErrors()[0].getMessage()+'<br/>';
            }
            contactIndex++;
        }

    }
    public void finish(Database.BatchableContext bc){   
        if(hasError){
            batchJobLog.Exception__c = errormsgs;
            batchJobLog.Status__c = 'Failed';   
            markBatch.Status__c = 'Failed';    
        }
        else{
            batchJobLog.Status__c = 'Successful';
            markBatch.Status__c = 'Successful';
        }
        markBatch.Last_Run_Finish__c = System.now();
        batchJobLog.Finish__c = System.now();
        update markBatch;
        update batchJobLog;
    }
}