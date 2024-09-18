/**
* @Description: EDGE_CoachingReportBatch

* @Purpose: Batch Class for generate report of Coaching Survey

* @History:                                                           
                                                           
* @VERSION         AUTHOR                  DATE              DETAIL
*   1.0         Preyanka Ghosh			17/09/2019		  Intial Development
*   2.0	        Kapil Baliyan			30/12/2019		  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*   3.0         Divya Bansal			29/01/2021		  ES20-9513 Added Translation Language Logic
**/
public class EDGE_CoachingReportBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass {
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    Market_Setting__c mrktSetting; //ES20-9513
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        string countryCode = batchSetting.Country_Code__c;
        Date yesterdayDate = (Date.today()).addDays(-1);   
        
        //ES20-9513
        List<Market_Setting__c> marketSettingRecords = [SELECT id,language__c from Market_Setting__c WHERE Geography__r.Code__c = :countryCode LIMIT 1] ;
        if(marketSettingRecords != null && marketSettingRecords.size() > 0){
            mrktSetting = marketSettingRecords[0];
        }	

        String strQuery = 'Select Id, Content_Document_Id__c, Content_Version_Id__c, Current_Sales_Manager__c, ' + 
            ' Original_Sales_Manager__c, Report_Date__c, Sales_Representative__c, Score__c, Status__c, Survey__c FROM Coaching_Report__c' +
            ' WHERE Report_Date__c = :yesterdayDate AND Country__r.Code__c = :countryCode AND Status__c != \'Report Generated\'';
        return Database.getQueryLocator(strQuery);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Coaching_Report__c> lstCoachingReport){
        List<ContentVersion> lstContentVersion = new List<ContentVersion>();
        Map<Id, ContentVersion> mapContentDocLink = new Map<Id, ContentVersion>();
        List<ContentDocumentLink> lstContentDocLink = new List<ContentDocumentLink>();
        
        //ES20-9513
        String languageName;
        if(mrktSetting != null){
            languageName = mrktSetting.language__c;
        }
        System.debug('languageName = '+ languageName);
        
        if(lstCoachingReport != null && lstCoachingReport.size()>0){
            for(Coaching_Report__c coachingReport : lstCoachingReport){
                //Call the VF page ES20-9513
                PageReference coachingPage = Page.EDGE_CoachingReportPDF;
     			coachingPage.getParameters().put('id',coachingReport.Id);
                coachingPage.getParameters().put('isUpdate','Yes');
                coachingPage.getParameters().put('label_lang',languageName);
                
                //PageReference coachingPage = New PageReference('/apex/EDGE_CoachingReportPDF?id=' + coachingReport.Id + '&isUpdate=Yes');
                
                //Create the Content Version and put the VF page as Version Data
                ContentVersion contentVersion = new ContentVersion();                
                contentVersion.Title = 'Coaching Report';
                contentVersion.PathOnClient = 'CoachingReport.pdf';
                contentVersion.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Coaching Report').getRecordTypeId();
                contentVersion.Content_Type__c = 'Coaching Report';
                if(!Test.isRunningTest()){
                    contentVersion.VersionData = coachingPage.getContentAsPdf();
                } else {
                    contentVersion.VersionData = Blob.valueOf('abc');
                }
                
                lstContentVersion.add(contentVersion);
                
                //Create a link so that we can create the content version link later once content version inserted in syatem
                mapContentDocLink.put(coachingReport.Id,contentVersion);           
            }
        }
        
        if(lstContentVersion != null && lstContentVersion.size()>0){
            insert lstContentVersion;
            
            //Used to retrieve the Content Document Id that has been created
            List<ContentVersion> lstUpdateContentVer= [SELECT ID, ContentDocumentId, VersionData FROM ContentVersion WHERE ID IN :lstContentVersion];
            
            //Create the content version link depend on Content version
            for(ContentVersion contentVersion : lstUpdateContentVer){
                for(String linkedId : mapContentDocLink.keySet()){
                    ContentVersion contentVersionLink = mapContentDocLink.get(linkedId);
                    if(contentVersionLink.Id == contentVersion.Id){
                        ContentDocumentLink conDocLnkObj = new ContentDocumentLink ();
                        conDocLnkObj.LinkedEntityId = linkedId;
                        conDocLnkObj.ContentDocumentId = contentVersion.ContentDocumentId;
                        conDocLnkObj.shareType = 'V';
                        lstContentDocLink.add(conDocLnkObj);
                    }                    
                }                
            }
            
            //Insert Content version link
            if(lstContentDocLink != null && lstContentDocLink.size()>0){
                insert lstContentDocLink;
            }            
        }
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_CoachingReportBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
        EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}