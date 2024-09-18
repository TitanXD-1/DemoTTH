/*
Name: EDGE_OperatorKPIAchievementBatchTest

Author          Version    Date           Detail
Sandip Ghosh    V1.0       15/09/2020     [ES20-8500]
Prasanth T      V2.0       23/09/2022     [ES20-13324]
*/
@isTest
public class EDGE_OperatorKPIAchievementBatchTest {
    public static Map<Id,Integer> virtualCallsCountMap = new Map<Id,Integer>(); 
    public static Map<Id,Integer> telephoneCallsCountMap = new Map<Id,Integer>();
    public static Map<Id,Integer> physicalCallsCountMap = new Map<Id,Integer>();
    
    @testSetup
    public static void createTestData(){
      List<Call__c> callList = new List<Call__c>();
     
        List<Account> accountListNew = new List<Account>();  
        EDGE_UtilityTestClass.createOrgSettings();
        // added setupCountryCO by Anamika
        Id countryId = EDGE_UtilityTestClass.setupCountryCO('CO');
        
        
        String pickupRecordType = Pick_Up_Options__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet Prioritization').getRecordTypeId();
        Pick_Up_Options__c pickupOption = EDGE_UtilityTestClass.getPickUpOption(countryId,'Outlet Visit Prioritization');
        pickupOption.Name = 'Gold[CO]';
        pickupOption.RecordTypeId = pickupRecordType;
        pickupOption.Status__c = 'Active';
        insert pickupOption;
        
        Market_Cycle__c marCycle = EDGE_UtilityTestClass.getMarketCycle(countryId);
        marCycle.Number_of_Week__c = 52;
        marCycle.Start_Date__c = Date.Today();
        marCycle.End_Date__c = Date.Today().addDays(360);
        insert marCycle;
        
        
        Account operator = EDGE_UtilityTestClass.getOwnerOperatorAccount();
        operator.Person_Responsible__c = UserInfo.getUserId();//salesRep1.Id;
        operator.IsOperator__c = true;
        insert operator;
        //printGovLimits();
        
        for(Integer count = 1; count <= 3; count++){ //for(Integer count = 1; count <= 100; count++)
            Account testoutlet=EDGE_UtilityTestClass.getOutletRecord();
            testoutlet.Outlet_Visit_Prioritisation_Grade__c =  pickupOption.Id;
            testoutlet.Independent_of_Operator__c = false;
            testoutlet.Operator__c = operator.Id;
            testoutlet.Name = 'Outlet-00' + count;
            testoutlet.MobilePrefix__c ='+61';
            testoutlet.Mobile__c = '512 123 123';
            testoutlet.PhonePrefix__c = '+61';
            testoutlet.Phone__c = '1 2222 3333';
            accountListNew.add(testoutlet);
        }
        Test.startTest();
        Database.insert(accountListNew);
        //printGovLimits();
        List<Call_Type__c> callTypes = new List<Call_Type__c>();
        
        Call_Type__c virtualCallType = EDGE_UtilityTestClass.getCallType(countryId);
        virtualCallType.Global_Equivalent_Call_Type__c = 'Virtual';
        virtualCallType.Name = 'Prospect and Fact Finding';
        callTypes.add(virtualCallType);
        
        Call_Type__c physicalCallType = EDGE_UtilityTestClass.getCallType(countryId);
        physicalCallType.Global_Equivalent_Call_Type__c = 'Physical';
        physicalCallType.Name = 'Sales Manager Call';
        callTypes.add(physicalCallType);
        
        Call_Type__c telephoneCallType = EDGE_UtilityTestClass.getCallType(countryId);
        telephoneCallType.Global_Equivalent_Call_Type__c = 'Telephone';
        telephoneCallType.Name = 'Sales Measure';
        callTypes.add(telephoneCallType);
        
        Database.insert(callTypes);
        
        for(Account outlet : accountListNew){
            Integer count = 1;
            for(Integer countOfCalls = 1; countOfCalls <=10 ; countOfCalls++){ //for(Integer countOfCalls = 1; countOfCalls <=20 ; countOfCalls++)
                Integer remindValue = math.mod(countOfCalls, 3);
                Call__c callObj = new Call__c();
                switch on remindValue {
                    when 0 {
                        callObj = getCallRecord(outlet, callObj, virtualCallType.Id);
                    }
                    when 1 {
                        callObj = getCallRecord(outlet, callObj, physicalCallType.Id);
                    }
                    when 2 {
                        callObj = getCallRecord(outlet, callObj, telephoneCallType.Id);
                    }
                }
                if(Call__c.Account__c != null){
                	callList.add(callObj);
                }
            }
            
            count++;
        }
        
       EDGE_UtilityClass.printGovLimits(136);    
        Database.insert(callList);
        for(Call__c callObj :callList){
            if(callObj.Type_of_Call__r.Global_Equivalent_Call_Type__c =='Virtual'){
               virtualCallsCountMap.put(callObj.Account__c,2); 
            }
        }
        for(Call__c callObj :callList){
            if(callObj.Type_of_Call__r.Global_Equivalent_Call_Type__c =='Physical'){
               physicalCallsCountMap.put(callObj.Account__c,2); 
            }
        }
        for(Call__c callObj :callList){
            if(callObj.Type_of_Call__r.Global_Equivalent_Call_Type__c =='Telephone'){
               telephoneCallsCountMap.put(callObj.Account__c,2); 
            }
        }
        
        
        Test.stopTest();
       
    }
    
    @isTest
    public static void testCalls(){
        
        Test.startTest();
        printGovLimits();
        //Market_Batch_Setting__mdt batchSetting = new Market_Batch_Setting__mdt();
		testOperatorKPIBatch();
        //system.assert(batchSetting.Id != null,'batch setting should not be null');
        printGovLimits();
        Test.stopTest();
    }
    
    private static Call__c getCallRecord(Account outlet, Call__c callObj, Id callTypeId){
         Integer currentMonth  = Date.Today().Month();
        callObj.Account__c = outlet.Id;
        //callObj.Start_Date__c = System.today();
        if(currentMonth <= 6){
            callObj.Start_Date__c = Date.newinstance(system.today().year()-1, 7, 1);
            callObj.End_Date__c = Date.newinstance(system.today().year(), 6, 30);
        }else{
            callObj.Start_Date__c = Date.newinstance(system.today().year(), 7, 1);
            callObj.End_Date__c = Date.newinstance(system.today().year() +1, 6, 30);
        }
        callObj.Status__c = 'Completed';
        //callObj.Call_Performed_By__c=testMDMUser.Id;
        callObj.Type_of_Call__c = callTypeId;
        callObj.Plan_Start_Date__c = System.today();
        return callObj;
    }
    
    private static void printGovLimits(){
        system.debug(LoggingLevel.Debug,'***getCpuTime() : '+ System.now() + ' = ' + Limits.getCpuTime());
    }
    
     @isTest
    public static void testOperatorKPIBatch(){
        //Test.startTest();
        List<EDGE_BatchSObjectWrapper> wrapperList = new List<EDGE_BatchSObjectWrapper>();
        EDGE_BatchSObjectWrapper wrapper = new EDGE_BatchSObjectWrapper();
        wrapper.virtualCallsCountMap = virtualCallsCountMap ;
        wrapper.telephoneCallsCountMap = telephoneCallsCountMap ;
        wrapper.physicalCallsCountMap = physicalCallsCountMap ;
        wrapperList.add(wrapper);
        
        Market_Batch_Setting__mdt batchSetting = [Select MasterLabel, Batch_Class__c, Country_Code__c,
                                                  Market_Order__c, Serial_Number__c, Scope__c, Job_Group__c, Region__c 
                                                  from Market_Batch_Setting__mdt 
                                                  where Batch_Class__c = 'EDGE_OperatorKPIAchievementBatch'
                                                  and Country_Code__c ='CO'];
        system.assert(batchSetting.Id != null,'batch setting should not be null');
        String className = batchSetting.Batch_Class__c;         
        Type t = Type.forName(className);
        BatchJobManagementInterfaceExtended job = (BatchJobManagementInterfaceExtended)t.newInstance();
        job.getBatchDetails(batchSetting,wrapperList);
        Database.executeBatch((Database.Batchable<SObject>)job,integer.valueOf(batchSetting.Scope__c));
        //Database.executeBatch((Database.Batchable<SObject>)job,10000);//10000
        
        //Test.stopTest();
    }
}