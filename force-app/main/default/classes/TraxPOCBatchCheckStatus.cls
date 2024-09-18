public class TraxPOCBatchCheckStatus implements Database.Batchable<SObject>, Database.AllowsCallouts, Database.Stateful {

    private List<String> importIdList;

    // Constructor to accept importId list
    public TraxPOCBatchCheckStatus(List<String> importIdList) {
        this.importIdList = importIdList;
        System.debug(importIdList);
    }

    // Implement start method
    public Database.QueryLocator start(Database.BatchableContext bc) {
        system.debug('@@-Inside Start: ');
        return Database.getQueryLocator('SELECT Id FROM Account LIMIT 1');
    }

    // Implement execute method
    public void execute(Database.BatchableContext bc, List<SObject> scope) {
        system.debug('@@-Inside Execute: ');
        List<Custom_Log__c> logsToInsert = new List<Custom_Log__c>();
        String ilRecordTypeID = Schema.SObjectType.Custom_Log__c.getRecordTypeInfosByName().get('Integration Log').getRecordTypeId();


        for (String importId : importIdList) {
            
            
            String boundary = '--------------------------848953448533366555074091';
            String accessToken = 'mcFlwQHtVIvspk8JdZsjPqfezs2wJOcKLPpaDQ94iLCCc76iHkolQxQPa4haDxqCki0ydtaJ1yPrI8FDVLICL3eQVIG02TuUy3gkKCKRfCfaezyGvoYOsZO6eTMAt4jz9wn5fT7LhfzTAZxYez2vUxBc';
            String targetURL = 'https://services.traxretail.com/api/v5/diageoga1-sand/store-import/'+importID;
            String responseBody='';
            // Send HTTP request
            HttpRequest request = new HttpRequest();
            request.setHeader('Content-Type', 'multipart/form-data; boundary='+boundary);
            request.setHeader('Authorization', 'Auth-Token '+accessToken);
            request.setMethod('GET');
            system.debug('@@targetURL' + targetURL);    
            request.setEndpoint(targetURL);
            //request.setBody(BodyPayload);
            request.setCompressed(false);
            request.setTimeout(120000); 
            
            Custom_Log__c logEntry = new Custom_Log__c();
            logEntry.RecordTypeId = ilRecordTypeID;
            logEntry.OS__c = 'Desktop';
            logEntry.Class_Name__c = 'TraxPOCBatchCheckStatus';
            logEntry.Method_Name__c = 'execute';
            logEntry.Interface_Name__c = importId+System.now().getTime();
            logEntry.API_Request__c = request.toString();
            
            

            try {
                // Get HTTP response
                Http http = new Http();
                HttpResponse res = http.send(request);
                responseBody= res.getBody();
                Integer responseCode = res.getStatusCode();
                system.debug('@@responseBody: ' + responseBody);
                system.debug('@@responseCode: ' + responseCode);
                logEntry.Error_Code__c = res.getStatusCode();
                Map<String, Object> responseMap = (Map<String, Object>) JSON.deserializeUntyped(res.getBody());

                if (res.getStatusCode() == 200 && (Integer) responseMap.get('errored')>0) {
                    // Process the response to check the status
                    String status = (String) responseMap.get('status');

                    // Create a new Custom_Log__c record
                    
                    logEntry.GUID__c = importId;
                    logEntry.Status__c = status;
                    logEntry.API_Response__c = res.getBody();

                } else {
                    // Handle non-200 responses (e.g., log errors)
                    logEntry.GUID__c = importId;
                    logEntry.Status__c = 'Error';
                    logEntry.API_Response__c = res.getBody();

                }
            } catch (Exception e) {
                // Handle callout errors
                logEntry.GUID__c = importId;
                logEntry.Status__c = 'Exception';
                logEntry.API_Response__c = e.getMessage();
                
            }
            
            logsToInsert.add(logEntry);
        }
        system.debug('@@-Custom Log: '+ logsToInsert);

        // Insert the logs into the Custom_Log__c object
        if (!logsToInsert.isEmpty()) {
            try {
                insert logsToInsert;
            } catch (DmlException dmlEx) {
                System.debug('DML Error: ' + dmlEx.getMessage());
                // Handle DML exceptions (e.g., log errors)
            }
        }
    }

    // Implement finish method
    public void finish(Database.BatchableContext bc) {
        // Logic after the second batch completes
        System.debug('Second batch completed with ' + importIdList.size() + ' import IDs processed.');
    }
}