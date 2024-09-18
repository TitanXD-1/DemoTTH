/**

* @description :  EDGE_GeneratePublicURLForImageBatch

* @history :

* Version   Developer      Date       User Story	  Purpose
* 1.1       Aparajita    17/08/2021   ES20-10903      Generate Public URL when files are uploaded in Outlet Survey Response

*/

public class EDGE_GeneratePublicURLForImageBatch implements Database.Batchable<sobject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass 
{
    DateTime batchRundate = system.now();
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting)
    {
        this.batchSetting=batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bc)
    {
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        Date today = System.today();
		Date dateLimit = today-Integer.valueOf(label.EDGE_DateLimitForPublicImageURLBatch);
        String query = '';
        string countryCode = batchSetting.Country_Code__c;
        query = 'SELECT Id, Content_Document_ID__c, Content_Version_ID__c, Image__c, Image_public_URL__c, Outlet_Survey__r.Outlet__r.Country_Code__c FROM Outlet_Survey_Response__c WHERE Content_Document_ID__c!=NULL AND Content_Version_ID__c!=NULL AND Outlet_Survey__r.Outlet__r.Country_Code__c =:countryCode AND LastModifiedDate>=:dateLimit';
        return Database.getQueryLocator(query);
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bc, List<Outlet_Survey_Response__c> outletSurveyResponseList)
    {
        String latestContentVersionId = '';
        Set<Id> outletSurveyRespIdSet = new Set<Id>();
        Map<Id,Id> contentVersionVsOutletSurveyRespMap =  new Map<Id,Id>();
        Map<Id,String> contentVersionVsContentDownloadUrlMap =  new Map<Id,String>();
        Map<Id,String> OutletSurveyRespVsContentDownloadUrlMap =  new Map<Id,String>();
        List<ContentDistribution> contentDistributionList = new List<ContentDistribution>();
		List<Outlet_Survey_Response__c> outletSurveyRespListToUpdate = new List<Outlet_Survey_Response__c>();
        try{
            
            if(outletSurveyResponseList != null && outletSurveyResponseList.size() > 0)
            {   
                for(Outlet_Survey_Response__c outletSurResp : outletSurveyResponseList)
                    outletSurveyRespIdSet.add(outletSurResp.Id);
            }

            if(outletSurveyRespIdSet!=null && outletSurveyRespIdSet.size()>0)
            {
                for(Outlet_Survey_Response__c outletSurveyRespObj : [SELECT Id,Content_Version_ID__c FROM Outlet_Survey_Response__c WHERE Id IN : outletSurveyRespIdSet])
                {    
                    String[] contentVersionList = outletSurveyRespObj.Content_Version_ID__c.split(';');
                    latestContentVersionId = contentVersionList.get(contentVersionList.size()-1);
                    if(!contentVersionVsOutletSurveyRespMap.containsKey(latestContentVersionId))
                        contentVersionVsOutletSurveyRespMap.put(latestContentVersionId,outletSurveyRespObj.Id);
                }
            }

            if(contentVersionVsOutletSurveyRespMap!=null && contentVersionVsOutletSurveyRespMap.size()>0)
            {
                for(ContentVersion file : [SELECT Id, Title FROM ContentVersion WHERE Id IN : contentVersionVsOutletSurveyRespMap.keySet()])
                {    
                    ContentDistribution contDist = new ContentDistribution();
                    contDist.Name = file.Title;
                    contDist.ContentVersionId = file.Id;
                    contDist.PreferencesAllowViewInBrowser = true;
                    contentDistributionList.add(contDist);
                }
            }
            
            if(contentDistributionList!=null && contentDistributionList.size()>0)
                Database.insert(contentDistributionList,false);
            
            for(ContentDistribution condist :  [SELECT Id, ContentDownloadUrl,ContentVersionId FROM ContentDistribution WHERE ContentVersionId IN :contentVersionVsOutletSurveyRespMap.keySet()]) 
            {
                if(!contentVersionVsContentDownloadUrlMap.containsKey(condist.ContentVersionId))
                    contentVersionVsContentDownloadUrlMap.put(condist.ContentVersionId,condist.ContentDownloadUrl);
            }

            if(contentVersionVsContentDownloadUrlMap!=null && contentVersionVsContentDownloadUrlMap.size()>0 && contentVersionVsOutletSurveyRespMap!=null && contentVersionVsOutletSurveyRespMap.size()>0)
            {
                for(Id contentVersionId : contentVersionVsContentDownloadUrlMap.keySet())
                {
                    Id outletSurveyRespId = contentVersionVsOutletSurveyRespMap.get(contentVersionId);
                    String contentDownloadUrl = contentVersionVsContentDownloadUrlMap.get(contentVersionId);
                    if(!outletSurveyRespVsContentDownloadUrlMap.containsKey(outletSurveyRespId))
                        outletSurveyRespVsContentDownloadUrlMap.put(outletSurveyRespId,contentDownloadUrl);             
                }    
            }	
            
            if(outletSurveyRespVsContentDownloadUrlMap!=null && outletSurveyRespVsContentDownloadUrlMap.size()>0)
            {
                for(Outlet_Survey_Response__c outletSurveyRespObj : [SELECT Id, Image_public_URL__c FROM Outlet_Survey_Response__c WHERE Id IN : outletSurveyRespVsContentDownloadUrlMap.keySet()])
                {
                    outletSurveyRespObj.Image_public_URL__c = outletSurveyRespVsContentDownloadUrlMap.get(outletSurveyRespObj.Id);
                    outletSurveyRespListToUpdate.add(outletSurveyRespObj);
                }                                                     
            }
            
            if(outletSurveyRespListToUpdate!=null && outletSurveyRespListToUpdate.size()>0)
                Database.update(outletSurveyRespListToUpdate,false);
        }
        catch(Exception ex)
        {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';  
        }   
    }
    
    //Finish Method - Update ES20-6594
    public void finish(Database.BatchableContext bc)
    {
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed')
            hasError = true;
        
        //Update Batch Job Status
        if(hasError)
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_GeneratePublicURLForImageBatch', exceptionMsg);
        else
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest())
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
    }
}