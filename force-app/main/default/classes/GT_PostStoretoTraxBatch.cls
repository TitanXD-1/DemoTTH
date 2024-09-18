/**
* @description : GT_PostStoretoTraxBatch
* @history                                                            
.
VERSION     AUTHOR               DATE              DETAIL
1.0         Joshraj Sen          08/06/2023        GT-140 The outlets are executed based on the hub level for GT Market
2.0         Tanishq/Anuja        08/09/2023        143573 Integration: Batch GT Outlets from EDGE TO TRAX to another TRAX end point
*/
public with sharing class GT_PostStoretoTraxBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful,Database.RaisesPlatformEvents {
      
    public  Database.QueryLocator start(Database.BatchableContext bc){
        Datetime dt = System.now()-1;
        String formatDate = dt.format('yyyy-MM-dd\'T\'HH:mm:ss.SSSZ');
    	String queryString = 'SELECT Id, Name,Global_Channel__c, Country_Code__c, Hub_Code__c,BillingCountry,Operator__r.Name,BillingState, BillingStreet, BillingCity, ' +
            'Region__c, Region__r.Name,Area__c, Area__r.Name,Status__c, BillingPostalCode, BillingLatitude, BillingLongitude, Parent.Name,Fascia__r.Name, ' +
            'Local_Segment2__r.Name, Local_Segment1__r.Name, Global_Sub_channel__c, Global_Segment__c,'+
            'Global_Sub_Segment__c, Consumer_Segmentation__r.Name, Outlet_Visit_Prioritisation_Grade__r.Name, Send_To_Trax__c,Store_Size__r.Name,Local_Segment_Advanced_Analytics__c '+
            'FROM Account WHERE Last_Modify_Data_Master__c >='+formatDate+' AND Hub_Code__c =\''+ Label.GT_Global_Travel_Hub_Code+'\' AND Send_To_Trax__c = true';
        
        return Database.getQueryLocator(queryString);                
    }   
    
    public void execute(Database.BatchableContext bc, list<Account> outletList){
        String responseMsgAT = '';
        String responseMsgIR = '';
        try{
            List<EDGE_GenerateStoreJSON > outlets = new List<EDGE_GenerateStoreJSON>();
            if(outletList != null && !outletList.isEmpty()){ 
                for(Account outlet: outletList){
                    EDGE_GenerateStoreJSON store = new EDGE_GenerateStoreJSON(outlet,Label.GT_Global_Travel_Hub_Code);
                    outlets.add(store);
                }
                System.debug(LoggingLevel.DEBUG,'@@outlets = '+ outlets);
                if(!outlets.isEmpty() && !Test.isRunningTest()){                  
                    System.debug(LoggingLevel.DEBUG,'@@JSONrequest = ' +JSON.serializePretty(outlets));
                    responseMsgAT = EDGE_TraxLinkConnector.uploadFile(JSON.serializePretty(outlets),Label.GT_Global_Travel_Hub_Code, 'Outlet File','store');
                    responseMsgIR = EDGE_TraxLinkConnector.uploadFile(JSON.serializePretty(outlets),Label.GT_Global_Travel_Image_Recognition_Code, 'Outlet File','store');
					System.debug(LoggingLevel.DEBUG,'@@responseMsgAT = ' +responseMsgAT);  
                    System.debug(LoggingLevel.DEBUG,'@@responseMsgIR = ' +responseMsgIR); 
                }               
            }  
        }catch(Exception ex){
            System.debug(LoggingLevel.DEBUG,'@@Exception = ' + ex.getMessage());
            System.debug(LoggingLevel.DEBUG,'@@ExceptionLine Number = ' + ex.getLineNumber());
            EventsLog_Utility.createBatchLog('GT_PostStoretoTraxBatch', 'execute',ex.getMessage(),0, 'Batch job exception',ex.getStackTraceString(),'Account');
        }
    }
    
    public void finish(Database.BatchableContext bc){
        //Get Batch Job
        AsyncApexJob job = [SELECT Id, Status,ExtendedStatus, NumberOfErrors, JobItemsProcessed, TotalJobItems, CreatedBy.Email 
                            FROM AsyncApexJob 
                            WHERE Id = :bc.getJobId()]; 
        System.debug(System.LoggingLevel.INFO, '@@ finish GT_PostStoretoTraxBatch = ' + job.Status);
        if(job.Status == 'Failed' || job.Status == 'Aborted' || job.ExtendedStatus != null){
            EventsLog_Utility.createBatchLog('GT_PostStoretoTraxBatch', 'finish', 'Batch job failure', 0, String.valueOf(job.Status), 'Job ID -'+String.valueOf(job.Id),String.valueOf(job.ExtendedStatus));
        }        
    }
}