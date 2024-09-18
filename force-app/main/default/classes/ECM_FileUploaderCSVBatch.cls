public class ECM_FileUploaderCSVBatch implements Database.Batchable<sObject>, Database.Stateful{
    private String csvFile='';
    private Integer startRow;
    public Integer rowCount;
    public Integer SuccessRowCount;
    public Integer FailureRowCount;
    public String csvSuccessFileString;
    public String csvErrorFileString;
    public boolean firstRun;
    public list<sObject>paymentSummary{get;set;}
    
    public ECM_FileUploaderCSVBatch(List<sObject>lstRecords){
        paymentSummary = lstRecords;
        csvSuccessFileString = 'Salesforce Id, Payment Summary Name,SAP Credit Note #,SAP Credit Note Creation Date, SAP Billing Doc Number, SAP Billing Doc Date, SAP payment Reference Number, SAP Payment Date, Status\n';
        csvErrorFileString = 'Payment Summary Name,SAP Credit Note #,SAP Credit Note Creation Date, SAP Billing Doc Number, SAP Billing Doc Date, SAP payment Reference Number, SAP Payment Date, Error, Status\n';
    
    }
    public Iterable<sObject> start(Database.BatchableContext BC){
        return paymentSummary;
    }
    public void execute(Database.BatchableContext BC, List<ECM_Payment_Summary__c> scope){
        system.debug('Execute==='+scope);
        List<ECM_Payment_Summary__c> paymentSummarysToUpsert = new List<ECM_Payment_Summary__c>();
        paymentSummarysToUpsert = scope;        
        Database.upsert(scope, ECM_Payment_Summary__c.Id);
        
    }
    
    public void finish(Database.BatchableContext BC){
        AsyncApexJob job = [SELECT Id, Status, CreatedBy.Email FROM AsyncApexJob WHERE Id =:BC.getJobId()];
        system.debug('*****1 job****'+job);
        String bId = string.valueof(BC.getJobId());
        system.debug('***2 bId****'+bId);
        if(job.Status == 'Completed') {
            system.debug('**3 if completed****');
            //Email Logic + Data Insert in Custom Object
            ECM_BulkDataImportTrackerDML bDML = new ECM_BulkDataImportTrackerDML();
            Bulk_Data_Import_Tracker__c bLog = new Bulk_Data_Import_Tracker__c();
            bLog = bDML.generateBulkDataImportLog('SAP Number','Success', UserInfo.getUserId(), rowCount, SuccessRowCount, FailureRowCount, bId);
            try {
                insert bLog;
            } 
            catch(Exception ex){
                system.debug('@@Exception' + ex);
            }
            
            //Generating Success and Error Blob from Success and error String.
            Blob csvSuccessBlob = Blob.valueOf(csvSuccessFileString);
            Blob csvErrorBlob = Blob.valueOf(csvErrorFileString);
            List<Attachment> attchList = new List<Attachment>();
            
            //Attaching Success and Error CSV File.
            Attachment AttachmentSuccessObj = new Attachment(Body = csvSuccessBlob, Name = 'SAPNumber_Success_' + System.now().format('yyyy-MMM-dd') + '.csv', parentId = bLog.Id);
            Attachment AttachmentErrorObj = new Attachment(Body = csvErrorBlob, Name = 'SAPNumber_Error_' + System.now().format('yyyy-MMM-dd') + '.csv', parentId = bLog.Id);
            
            attchList.add(AttachmentSuccessObj);
            attchList.add(AttachmentErrorObj);
            
            if(attchList.size() > 0){
                try{
                    insert attchlist;
                    /*string htmlEmailBody = Label.SAP_CSV_Upload_Job_Email_Body;
                    htmlEmailBody += '<br/>' + '<br/>';
                    htmlEmailBody += '<b>' + Label.BeerTag_CSV_Upload_Job_Email_Body_1 + '</b>' + ' ' + rowCount + '<br/>';
                    htmlEmailBody += '<b>' + Label.BeerTag_CSV_Upload_Job_Email_Body_2 + '</b>' + ' ' + SuccessRowCount + '<br/>';
                    htmlEmailBody += '<b>' + Label.BeerTag_CSV_Upload_Job_Email_Body_3 + '</b>' + ' ' + FailureRowCount + '<br/> <br/>';
                    htmlEmailBody += Label.BeerTag_CSV_Upload_Job_Email_Body_4 + ' ';
                    htmlEmailBody += URL.getSalesforceBaseUrl().toExternalForm() + '/' + bLog.Id;*/
                    //Trigger Email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[]{job.CreatedBy.Email};
                    String subject = 'SAP Number Upload Status Mail';
                    email.setSubject(subject);
                    email.setToAddresses(toAddresses);                   
                    string htmlEmailBody = 'Hi';
                    htmlEmailBody += ',<br/>' + '<br/>';
                    htmlEmailBody += 'Your SAP Payment Number file is successfully loaded.'+ '<br/>';
                    htmlEmailBody += '<br/>' + 'Thanks,'+'<br/>'+'Contract management System' ;
                    email.setHtmlBody(htmlEmailBody);
                    Messaging.SendEmailResult[] r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
                }
                catch(Exception ex){
                    system.debug('@@Exception' + ex);
                }
            }
        }
}
}