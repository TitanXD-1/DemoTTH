/*
  Name : EDGE_CSVFileProcessBatch
  Purpose : This Class is used to Process a CSV File
    History                                                                                                                    
    VERSION    AUTHOR            DATE              DETAIL
     1.0      Saurav K Paul    21-02-2019        Initial Development
	 1.1	  Shivam Chauhan	 18/07/2023		142554 - EDGE static code violation for the classes_SFDC_Tech Debt
*/ 
public with sharing class EDGE_CSVFileProcessBatch implements Database.Batchable<string>, Database.Stateful {
	private String csvFile;
    private Integer startRow;
    public String objType;
    private Boolean isCreate;
    public Integer rowCount;
    public Integer successRowCount;
    public Integer failureRowCount;
    public String csvSuccessFileString;
    public String csvErrorFileString;
    public boolean firstRun;
    public boolean isFirstCall;
    public boolean isSuccess;
   	public string msg;
    
	//Constructor
    public EDGE_CSVFileProcessBatch(blob csvBlob, String objType, Boolean isCreate){
    	this.objType = objType;
    	this.isCreate = isCreate;
        csvFile = csvBlob.toString();
        rowCount = 0;
        successRowCount = 0;
        failureRowCount = 0;
        firstRun = true;
        isFirstCall = true;
        isSuccess = true;
        msg = 'Success';
        // Adding Success and Error Header Name to CSV file
        if(objType.equalsIgnoreCase('Territory')){
        	csvSuccessFileString = 'Outlet Id, Territory Id, Status\n';
        	csvErrorFileString = 'Outlet Id, Territory Id, Error, Status\n';
        }else if(objType.equalsIgnoreCase('TargetList')){
        	csvSuccessFileString = 'Outlet Id, Target Member Id, Status\n';
        	csvErrorFileString = 'Outlet Id, Target Member Id, Error, Status\n';
        }
    }
    //Start Method
    public Iterable<String> start(Database.BatchableContext bc){
        return new EDGE_CSVRowIterator(csvFile);
    }
    //Execute Method
    public void execute(Database.BatchableContext bc, List<String> scope){
        try{
            //Variable
            String csvFile = '';
            List<List<String>> csvLines;
            Set<Id> outletIdSet = new Set<Id>();
            Set<Id> terOrTargetLstMbrIdSet = new Set<Id>();
            EDGE_CSVFileProcessBatchWrapper csvFileProcessBatchWrapper = new EDGE_CSVFileProcessBatchWrapper();
            
            //Variable
            for(String row : scope){
                csvFile += row + '\n';
            }
        
            //Parse CSV File
            EDGE_CSVFileParser csvFileUploader = new EDGE_CSVFileParser();
            csvLines = csvFileUploader.getResults(csvFile);
            
            if(csvLines.size()>0){
                Map<Integer,List<String>> csvLinesMap = new Map<Integer,List<String>>();
                Integer j=0;
                //Skip CSV Header
                if(firstRun){
                    j = 1;
                    firstRun = false;    
                }
                
                //Iterate over every line of csv
                for(Integer i = j; i<csvLines.size();i++){
                    List<String> currentRow = csvLines[i];
                    csvLinesMap.put(i,csvLines[i]);
                    //rowCount++;
                    String outltIdStrng = string.valueOf(currentRow[0]).trim();
                    String terIdStrng = string.valueOf(currentRow[1]).trim();
                    if((outltIdStrng.length() == 15 || outltIdStrng.length() == 18)
                       &&(terIdStrng.length() == 15 || terIdStrng.length() == 18) ){
                       	Id outletId = outltIdStrng;
                       	Id terOrTargetLstMbrId = terIdStrng;  
                       	outletIdSet.add(outletId);
                    	terOrTargetLstMbrIdSet.add(terOrTargetLstMbrId);
                    }
                    /*Id outletId = string.valueOf(currentRow[0]).trim();
                    Id terOrTargetLstMbrId = string.valueOf(currentRow[1]).trim();
                    outletIdSet.add(outletId);
                    terOrTargetLstMbrIdSet.add(terOrTargetLstMbrId);*/
                }
                if(isCreate && objType.equalsIgnoreCase('Territory')){
                    //Calling createOutltTerritory method
                    csvFileProcessBatchWrapper = EDGE_CSVFileProcessBatchHelper.createOutltTerritory(outletIdSet,terOrTargetLstMbrIdSet,csvLines,isFirstCall);
                }else if(!isCreate && objType.equalsIgnoreCase('Territory')){
                    //Calling deleteOutltTerritory method
                    csvFileProcessBatchWrapper = EDGE_CSVFileProcessBatchHelper.deleteOutltTerritory(outletIdSet,terOrTargetLstMbrIdSet,csvLines,isFirstCall);
                }else if(isCreate && objType.equalsIgnoreCase('TargetList')){
                    //Calling createTargtListMembr method
                    csvFileProcessBatchWrapper = EDGE_CSVFileProcessBatchHelper.createTargtListMembr(outletIdSet,terOrTargetLstMbrIdSet,csvLines,isFirstCall);
                }else if(!isCreate && objType.equalsIgnoreCase('TargetList')){
                    //Calling deleteTargtListMembr method
                    csvFileProcessBatchWrapper = EDGE_CSVFileProcessBatchHelper.deleteTargtListMembr(outletIdSet,terOrTargetLstMbrIdSet,csvLines,isFirstCall);
                }
                if(isFirstCall){
                    isFirstCall = false;
                }
            }
            
            //Get Data from Wrapper Class and put in batch variables
            rowCount = rowCount + csvFileProcessBatchWrapper.rowCount;
            successRowCount = successRowCount + csvFileProcessBatchWrapper.successRowCount;
            failureRowCount = failureRowCount + csvFileProcessBatchWrapper.failureRowCount;
            csvSuccessFileString = csvSuccessFileString + csvFileProcessBatchWrapper.csvSuccessFileString;
            csvErrorFileString = csvErrorFileString + csvFileProcessBatchWrapper.csvErrorFileString;
            
        }catch(Exception ex){
            isSuccess = false;
            msg = Label.Error + Label.Line_Number + ' ' + ex.getLineNumber() + '\n' + Label.Error + ex.getMessage();
        }
	}
    
    //Finish Method
    public void finish(Database.BatchableContext bc){
    	AsyncApexJob job = [SELECT Id, Status, CreatedBy.Email FROM AsyncApexJob WHERE Id =:bc.getJobId()];
    	String bId = string.valueof(bc.getJobId());
    	if(job.Status == 'Completed') {
    		Bulk_Data_Import_Tracker__c bLog = new Bulk_Data_Import_Tracker__c();
            bLog = EDGE_BulkDataImportTrackerDML.generateBulkDataImportLog(objType, msg, UserInfo.getUserId(), rowCount, SuccessRowCount, FailureRowCount, bId);
            try {
                insert bLog;
            } 
            catch(Exception ex){
                System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
            }
            //Generating Success and Error Blob from Success and error String.
            Blob csvSuccessBlob = Blob.valueOf(csvSuccessFileString);
            Blob csvErrorBlob = Blob.valueOf(csvErrorFileString);
            List<Attachment> attchList = new List<Attachment>();
            //Attaching Success and Error CSV File.
            Attachment attachmentSuccessObj = new Attachment(Body = csvSuccessBlob, Name = objType+'_Success_' + System.now().format('yyyy-MMM-dd') + '.csv', parentId = bLog.Id);
            Attachment attachmentErrorObj = new Attachment(Body = csvErrorBlob, Name = objType+'_Error_' + System.now().format('yyyy-MMM-dd') + '.csv', parentId = bLog.Id);
            
            attchList.add(attachmentSuccessObj);
            attchList.add(attachmentErrorObj);
            if(attchList.size() > 0){
            	try{
            		insert attchlist;
            		String htmlEmailBody = Label.CSV_Upload_Job_Email_Body;
            		htmlEmailBody += '<br/>' + '<br/>';
            	 	htmlEmailBody += '<b>' + Label.Total_Number_of_Records + '</b>' + ' ' + rowCount + '<br/>';
            	 	htmlEmailBody += '<b>' + Label.Total_Number_of_Success_Records + '</b>' + ' ' + SuccessRowCount + '<br/>';
                    htmlEmailBody += '<b>' + Label.Total_Number_of_Failure_Records + '</b>' + ' ' + FailureRowCount + '<br/> <br/>';
                    htmlEmailBody += Label.Log_File_Link + ' ';
                    htmlEmailBody += URL.getSalesforceBaseUrl().toExternalForm() + '/' + bLog.Id;
                    //Trigger Email
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    String[] toAddresses = new String[]{job.CreatedBy.Email};
                    String subject = Label.CSV_Upload_Status_Email_Subject;
                    email.setSubject(subject);
                    email.setToAddresses(toAddresses);
                    email.setHtmlBody(htmlEmailBody);
                    Messaging.SendEmailResult[] r;
                    r = Messaging.sendEmail(new Messaging.SingleEmailMessage[]{email});
            	}catch(Exception ex){
                    System.debug(LoggingLevel.Debug,'excption::::'+ex.getMessage());
                }
            }   
    	}
    	
    }     
}