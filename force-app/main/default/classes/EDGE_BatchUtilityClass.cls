/********************************************************************************************
Class Name: EDGE_BatchUtilityClass

Author              Version     Date           Detail
Srutadeba Chanda    V1.0        18/03/2019     Utility class for Market Batch Job
Kapil Baliyan		V2.0		30/12/2019	   Updated upsertMarketBatchJob, updateBatchJobStatus, getBatchJob (ES20-6594)
*********************************************************************************************/
public without sharing class EDGE_BatchUtilityClass {
    
    //This method will check the next batch inside any country and execute it  and if no next job is 
    //found for that market proces next market in same region
    public static void scheduleNextBatch(Market_Batch_Setting__mdt batchSetting, boolean hasError){
        //Get Next Batch
        Market_Batch_Setting__mdt nextBatchSetting = getNextBatch(batchSetting, hasError);
        system.debug('@@@@ nextBatchSetting '+nextBatchSetting );
        if(nextBatchSetting != null ){
            String className = nextBatchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceClass job = (BatchJobManagementInterfaceClass)t.newInstance();
            job.getBatchDetails(nextBatchSetting);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(nextBatchSetting.Scope__c));
        }
    }
    
    //This method will check the next batch inside any country and execute it  and if no next job is 
    //found for that market proces next market in same region
    public static void scheduleNextBatch(Market_Batch_Setting__mdt batchSetting, boolean hasError, List<Object> scopeRecords){
        //Get Next Batch
        Market_Batch_Setting__mdt nextBatchSetting = getNextBatch(batchSetting, hasError);
        system.debug('@@@@ nextBatchSetting '+nextBatchSetting );
        if(nextBatchSetting != null ){
            String className = nextBatchSetting.Batch_Class__c;
            Type t = Type.forName(className);
            BatchJobManagementInterfaceExtended job = (BatchJobManagementInterfaceExtended)t.newInstance();
            //job.getBatchDetails(nextBatchSetting);
            job.getBatchDetails(nextBatchSetting, scopeRecords);
            Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(nextBatchSetting.Scope__c));
        }
    }
    
    //Method to get Batch Frequency
    public static boolean getBatchFrequency(Market_Batch_Setting__mdt batchSetting){
        Date currentDate = system.today();
        Date firstDayOfMonth =currentDate.toStartOfMonth();
        boolean runBatch = false;
        integer currentday = currentDate.day();
        Date lastDateOfMonth = firstDayOfMonth.addDays(date.daysInMonth(Date.today().year() , Date.today().month())  - 1);
        Set<Integer> quaterMonths = new Set<Integer> {1, 4, 7, 10};
            
            /*String batchFrequency = batchSetting.Frequency__c;

if(batchSetting.Check_From_Market_Setting__c){
String fieldName = batchSetting.Market_Setting_Field_To_Check__c;
String queryString = 'Select Id, '+ fieldName + ' from Market_Setting__c where Geography__r.Code__c = \'' + batchSetting.Country_Code__c + '\' LIMIT 1';
List<Market_Setting__c> mkSettingList = Database.query(queryString);
batchFrequency = (String)mkSettingList[0].get(fieldName);
}

switch on batchFrequency {*/
            switch on batchSetting.Frequency__c {
                
                when 'Daily'{
                    runBatch = true;
                }
                when 'Weekly'{
                    if( batchSetting.Day_of_Week__c == system.now().format('EEEE') ){
                        runBatch = true;
                    }
                }
                when 'Bi-Weekly'{
                    if(currentday == 1 || currentday == 15 ){
                        runBatch = true;
                    }				
                }
                when 'Monthly'{
                    if(Integer.ValueOf(batchSetting.Day_of_Month__c) == currentday){
                        runBatch = true;
                    }else if(Integer.ValueOf(batchSetting.Day_of_Month__c) > lastDateOfMonth.Day() && currentday == lastDateOfMonth.Day()){
                        runBatch = true;
                    }
                }
                when 'Quarterly'{
                    if(quaterMonths.contains(system.Today().Month())){
                        if(Integer.ValueOf(batchSetting.Day_of_Month__c) == currentday){
                            runBatch = true;
                        }else if(Integer.ValueOf(batchSetting.Day_of_Month__c) > lastDateOfMonth.Day() && currentday == lastDateOfMonth.Day()){
                            runBatch = true;
                        }					
                    }
                }
                
            }
        return runBatch;
    }
    
    //Method to get next batch class name from custom metadata
    public static Market_Batch_Setting__mdt getNextBatch(Market_Batch_Setting__mdt batchSetting, boolean hasError){
        
        List<Market_Batch_Setting__mdt> nextJob = new List<Market_Batch_Setting__mdt>();
        Market_Batch_Setting__mdt upcomingJob;
        decimal marketOrder = batchSetting.Market_Order__c;
        decimal serialOrder = batchSetting.Serial_Number__c + 1;
        if(Schema.sObjectType.Market_Batch_Setting__mdt.isAccessible()){
            nextJob = [select MasterLabel, Batch_Class__c,Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, 
                       Job_Group__c, Region__c,Frequency__c, Day_of_Month__c, Day_of_Week__c from Market_Batch_Setting__mdt where 
                       Region__c =:batchSetting.Region__c and Market_Order__c =:marketOrder
                       and Serial_Number__c =:serialOrder and Job_Group__c =:batchSetting.Job_Group__c];
        }
        System.debug('1. nextJob = '+ nextJob);        
        if(nextJob != null && nextJob.size() == 1 && !hasError){
            boolean runBatch = getBatchFrequency(nextJob[0] );
            
            if(!runBatch){
                upcomingJob = getNextBatch(nextJob[0], hasError);
            }
            else{
                return nextJob[0];
            }
            return upcomingJob;
        }
        else{
            marketOrder = batchSetting.Market_Order__c + 1;
            serialOrder = 1;
            if(Schema.sObjectType.Market_Batch_Setting__mdt.isAccessible()){
                nextJob = [select MasterLabel, Batch_Class__c,Country_Code__c, Market_Order__c, Serial_Number__c, Scope__c, 
                           Job_Group__c, Region__c,Frequency__c, Day_of_Month__c, Day_of_Week__c from Market_Batch_Setting__mdt where
                           Region__c =:batchSetting.Region__c and Market_Order__c =:marketOrder
                           and Serial_Number__c =:serialOrder and Job_Group__c =:batchSetting.Job_Group__c];
            }
            System.debug('2. nextJob = '+ nextJob);
            if(!nextJob.isEmpty() && nextJob.size()==1){
                boolean runBatch = getBatchFrequency(nextJob[0]);
                if(!runBatch){
                    upcomingJob = getNextBatch(nextJob[0],hasError);
                }
                else{
                    return nextJob[0];
                }
                return upcomingJob;
            }
            else{
                return null;
            }
        }
    }
    
    //Upsert Market Batch Job. This method is called from every batch start method
    public static Id upsertMarketBatchJob(Market_Batch_Setting__mdt batchSetting, string jobId){
        Market_Batch_Job__c batchJob = new Market_Batch_Job__c();
        string batchJobName = batchSetting.Job_Group__c + '[' + batchSetting.Region__c + ']';
        System.debug('batchJobName = '+ batchJobName);
        //Upsert Market Batch Job Record
        if(Schema.sObjectType.Geography__c.isAccessible()){
            System.debug('batchSetting Region='+batchSetting.Region__c);
            Geography__c geography = [select Id from Geography__c where Name = :batchSetting.Region__c LIMIT 1];
            //Geography__c geography = [select Id from Geography__c where Code__c = :batchSetting.Region__c LIMIT 1];
            Geography__c country = [select Id from Geography__c where Code__c = :batchSetting.Country_Code__c LIMIT 1];
            
            if(Schema.sObjectType.Market_Batch_Job__c.isAccessible()) {
                List<Market_Batch_Job__c> marketBatchJobList = [select Id, Name, Geography__c, Status__c, Type__c, Current_Market_Order__c, 
                                                                Current_Batch_Class_Name__c, Last_Run_Start__c, Last_Run_Finish__c, External_Id__c 
                                                                from Market_Batch_Job__c where Type__c =:batchSetting.Job_Group__c AND Geography__c =:geography.Id];        
                
                if(marketBatchJobList != null && marketBatchJobList.size()>0 && Schema.sObjectType.Market_Batch_Job__c.isAccessible()){
                    batchJob = marketBatchJobList[0];
                }
                batchJob.Name = batchJobName;
                batchJob.Geography__c = geography.Id;
                if(batchJob.Status__c != 'Failed' && Schema.sObjectType.Market_Batch_Job__c.isAccessible()){
                    batchJob.Status__c = 'In Progress';
                }
                batchJob.Type__c = batchSetting.Job_Group__c;
                batchJob.Current_Market_Order__c = batchSetting.Market_Order__c;
                batchJob.Current_Batch_Class_Name__c = batchSetting.Batch_Class__c;
                if(batchJob.Last_Run_Start__c == null || (batchJob.Last_Run_Start__c.date() != (system.now().date())) && Schema.sObjectType.Market_Batch_Job__c.isAccessible()){
                    batchJob.Last_Run_Start__c = system.now();
                }
                batchJob.Last_Run_Finish__c = null;
                batchJob.External_Id__c = batchJobName + geography.Id;
                if(Schema.sObjectType.Market_Batch_Job__c.IsCreateable() && Schema.sObjectType.Market_Batch_Job__c.IsUpdateable()){
                    upsert batchJob External_Id__c;        
                }
                
                //Insert Country Batch Job Log
                Country_Batch_Job_Log__c batchJobLog = new Country_Batch_Job_Log__c();
                batchJobLog.Market_Batch_Job__c = batchJob.Id;
                batchJobLog.Name = batchSetting.Batch_Class__c + '[' + batchSetting.Country_Code__c + ']';
                batchJobLog.Country__c = country.Id;
                batchJobLog.Market_Order__c = batchSetting.Market_Order__c;
                batchJobLog.Serial_Number__c = batchSetting.Serial_Number__c;
                batchJobLog.Batch_Class_Name__c = batchSetting.Batch_Class__c;
                batchJobLog.Status__c = 'In Progress';
                batchJobLog.Start__c = system.now();
                batchJobLog.Finish__c = null;
                batchJobLog.Batch_Job_Id__c = jobId;
                if(Schema.sObjectType.Country_Batch_Job_Log__c.IsCreateable()){
                    insert batchJobLog;
                }
            }
        }
        
        return batchJob.Id;
    }
    
    //Method to update batch status & batch log. This method is called from catch & finish block of every batch
    public static void updateBatchJobStatus(Market_Batch_Setting__mdt batchSetting, Id marketBatchJobId, Country_Batch_Job_Log__c batchJobLog, string status, string exceptionBlock, string exceptionMsg){
        
        //Update Market Batch Job Status
        Market_Batch_Job__c batchJob = new Market_Batch_Job__c(Id = marketBatchJobId);
        
        //If Batch Job status was set as Failed by other batch dont update status
        if(batchJob.Status__c != 'Failed'){
            batchJob.Status__c = status;
        }
        batchJob.Last_Run_Finish__c = system.now();
        if(Schema.sObjectType.Market_Batch_Job__c.IsUpdateable()){
            update batchJob;
        }
        
        //Update Batch Job Log
        if(batchJobLog.Status__c != 'Failed'){
            batchJobLog.Status__c = status;
        }
        //Update Exception only if Exception is not updated by Platform Event Trigger
        if(!batchJobLog.Is_Updated_By_Platform_Event__c){
            batchJobLog.Exception__c = exceptionMsg;
        }
        batchJobLog.Finish__c = system.now();
        batchJobLog.Exception_Block__c = exceptionBlock;
        if(Schema.sObjectType.Country_Batch_Job_Log__c.IsUpdateable()){
            update batchJobLog;
        }
    }
    
    //Method to get Batch Job - ES20-6594
    public static Country_Batch_Job_Log__c getBatchJob(Market_Batch_Setting__mdt batchSetting, Id marketBatchJobId){
        Country_Batch_Job_Log__c batchJobLog = new Country_Batch_Job_Log__c();
        
        //Get Country Batch Job Log
        if(Schema.sObjectType.Country_Batch_Job_Log__c.isAccessible()){
            batchJobLog = [select Id, Status__c, Start__c, Finish__c, Is_Updated_By_Platform_Event__c from Country_Batch_Job_Log__c where Market_Batch_Job__c =:marketBatchJobId AND Batch_Class_Name__c =:batchSetting.Batch_Class__c Order By CreatedDate DESC LIMIT 1];
        }
        
        return batchJobLog;
    }
    //method to get User Country Code based on default country and assigned country
    public static String getUserCountryCode(String userDefaultCountry,String userAssignedCountry){
        String countryCode='';
        List<String> tempCountryList = new List<String>();                
        if(null != userAssignedCountry){
            tempCountryList = userAssignedCountry.split(';');
            countryCode = tempCountryList.size() > 1 && null != userDefaultCountry ? userDefaultCountry :tempCountryList[0];  
        }   
        return countryCode;
    }
}