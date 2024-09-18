/**
* @description EDGE_PostStoreToTraxBatch 
* @history                                                            
                                                           
VERSION     AUTHOR                  DATE              DETAIL
1.0         Monalisa Halder       03/06/2019         ES20-1583
1.1         Ankit Das             24/12/2019         ES20-6593
1.2         Kapil Baliyan         30/12/2019         Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
1.3         Monalisa Halder       17/08/2020         ES20-8424 - Adding the field as additional attribute
1.4         Debolina Saha         19/05/2022         ES20-12790 

**/
global with sharing class EDGE_PostStoreToTraxBatch implements Database.Batchable<sObject>,Database.AllowsCallouts,Database.Stateful,Database.RaisesPlatformEvents,BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string countryCode ;
    string responseMsg = '';
    Id marketBatchJobId;//Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    global  Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        countryCode = batchSetting.Country_Code__c;
        datetime dt = System.now()-1;
        
        String queryString = 'SELECT Id, Name,Global_Channel__c, Country_Code__c, BillingState, BillingStreet, BillingCity, ' +
            'Region__c, Region__r.Name,Area__c, Area__r.Name,Status__c, BillingPostalCode, BillingLatitude, BillingLongitude, Parent.Name,Fascia__r.Name, ' +
            'Local_Segment2__r.Name, Local_Segment1__r.Name, Global_Sub_channel__c, Global_Segment__c,'+
            'Global_Sub_Segment__c, Consumer_Segmentation__r.Name, Outlet_Visit_Prioritisation_Grade__r.Name, Send_To_Trax__c,Store_Size__r.Name,Local_Segment_Advanced_Analytics__c,'+
            '(SELECT Id , Distributor_Wholesaler__c,Distributor_Wholesaler__r.Name, Outlet__c FROM Supplier_Outlets1__r where isPrimary__c = true LIMIT 1) FROM Account '+
            'WHERE Last_Modify_Data_Master__c >=:dt and Country_Code__c =:countryCode and Send_To_Trax__c = true';
        
        return Database.getQueryLocator(queryString);                
    }   
    
    global void execute(Database.BatchableContext bc, list<Account> outletList){
        try{
            List<EDGE_GenerateStoreJSON> outlets = new List<EDGE_GenerateStoreJSON>();
            set<Id> outletIdset=new set<Id>();
            List<Trax_User_Update__c> traxUserUpdate=new List<Trax_User_Update__c>();
            System.debug('Execute EDGE_PostStoreToTraxBatch ');
            
            if(outletList !=null){ 
                for(Account outlet: outletList){
                    EDGE_GenerateStoreJSON store = new EDGE_GenerateStoreJSON(outlet, batchSetting.Country_Code__c);
                    outlets.add(store);
                    outletIdset.add(outlet.id);
                }
                System.debug('outlets = '+ outlets);
                if(!outlets.isEmpty()){
                    if(!Test.isRunningTest()){
                        responseMsg+=EDGE_TraxLinkConnector.uploadFile(JSON.serializePretty(outlets),countryCode, 'Outlet File','store');
                        system.debug('@@JSONrequest' +JSON.serializePretty(outlets));
                    }  
                }
                
                List<Outlet_Member__c> outletMemberList=[select Outlet__c,user__c,User__r.Default_Country__c,User__r.Available_Countries__c from Outlet_Member__c where outlet__c=:outletIdset and user__r.Trax_User__c=true];
                if(outletMemberList.size()>0){
                    for(Outlet_Member__c member : outletMemberList){
                        //traxUserUpdate.add(new Trax_User_Update__c(name=member.User__c,Country_Code__c=batchSetting.Country_Code__c));
                        if(null != member.User__c){
                            String countryCode = EDGE_BatchUtilityClass.getUserCountryCode(member.User__r.Default_Country__c, member.User__r.Available_Countries__c);
                            if(countryCode != null && countryCode != ''){
                                traxUserUpdate.add(new Trax_User_Update__c(name=member.User__c,Country_Code__c=countryCode));    
                            }    
                        }  
                    }
                    if(traxUserUpdate.size()>0){
                        Database.insert(traxUserUpdate,false);
                    }    
                }
            }  
        }
        catch(Exception ex){
            system.debug('@@Exception = ' + ex.getMessage());
            system.debug('@@ExceptionLine Number = ' + ex.getLineNumber());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
    }
    
    global void finish(Database.BatchableContext bc){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_PostStoreToTraxBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){                       //Added the check as a part of ES20-12790
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}