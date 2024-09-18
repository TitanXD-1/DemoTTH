/**
@name EDGE_LineCleaningCaseTaskCreationHelper
@description Helper class for EDGE_LineCLeaningCaseTaskCreationBatch case task,case,call record Creation from 1st day of cycle.
@history
VERSION     AUTHOR           DATE           DETAIL
1.0          Anand          12/12/2021		ES20-10426
2.0          Prasanth T     12/12/2021		ES20-11718
3.0          Anand          07/01/2021      ES20-11888
4.0          Anand U        04/04/2022      ES20-12343
5.0          Wribhu Bose    28/04/2023      GT-26 in method processLineCaseTask
**/
public with sharing class EDGE_LineCleaningCaseTaskCreationHelper {
    Public static Map<Id, Id> outeltDisRepUser = new Map<Id, Id>(); 
    final static String QualityRecordTypeId = Case.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId();
    final static String caseTaskTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Task Type').getRecordTypeId();
    final static String caseTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Type').getRecordTypeId();
    final static String caseTaskSubTypeRecTypeId = Quality_Case_Configuration__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Case Sub Type').getRecordTypeId();
    public static String Country;
    public static Map<String,Case> caseList = new Map<String,Case>();
    public static Map<String,Call__c> callList = new Map<String,Call__c>();
    public static List<Case_Task__c> caseTaskList = new List<Case_Task__c>();
    public static List<Asset> offSetFlagAssetList = new List<Asset>();
    public static List<String> caseTypes = System.label.EDGE_LineCleaningCaseType.split(',');
    public static List<String> caseSubTypes = System.label.EDGE_LineCleaningCaseSubType.split(','); 
    public static List<String> caseTaskTypes = System.label.EDGE_LineCleaningCaseTaskType.split(',');
    public static String callTypeName = System.label.EDGE_LineCleaningCallType;
    public static String globalEquivalentRole = System.label.Edge_LineCleaningGlobalEquivalentRole;
    public static String datetimeFunction = System.label.EDGE_Date_Time_LC_Conversion;
    public static String qualityAssetRecordTypeId = Asset.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality').getRecordTypeId(); //GT-26
    
    public static void processLineCaseTask(List<Line_Cleaning_Cycle__c> mCycles, List<Account> outlets,Map<Id,List<Line_Cleaning_Holiday__c>> lineHoliday,String CountryCode,Date todaysDate){
        Country = CountryCode;
        Set<Id> accounIds = new Set<Id>();
        Map<String,Id> insertedCallRecordMap = new Map<String,Id>();
        Map<String,Id> insertedCaseRecordMap = new Map<String,Id>();
        Set<Id> caseSet = new Set<Id>();//Taking set to assign case account to case task
        
        if(outlets != null && outlets.size() > 0){
            for(Account thisOutlet : outlets){
                accounIds.add(thisOutlet.Id);
            }
        }
        
        Map<Id,List<Id>> outletToTerritoryMap = new Map<Id,List<Id>>();
        Map<Id,Id> terrToUserMap = new Map<Id,Id>();
        Set<Id> terrIds = new Set<Id>();
        Map<String,String> userToRoleMap = new Map<String,String>();
        
        for(Outlet_Territory__c outletTerr :[SELECT Id,Name,Outlet__c, Territory__c from Outlet_Territory__c WHERE Outlet__c IN:outlets]){
            terrIds.add(outletTerr.Territory__c);
            if(outletToTerritoryMap.containsKey(outletTerr.outlet__c)){
                outletToTerritoryMap.get(outletTerr.outlet__c).add(outletTerr.Territory__c);
            }
            else{
                outletToTerritoryMap.put(outletTerr.outlet__c, new List<Id>{outletTerr.Territory__c});
            }
        }
        for(Territory__c terrInfo :[SELECT Id,Primary_Sales_Rep__c from Territory__c where Id IN :terrIds]){
            terrToUserMap.put(terrInfo.Id, terrInfo.Primary_Sales_Rep__c);
        }
        if(terrToUserMap != null && terrToUserMap.values().size() >0){
            for(User_Business_Role__c userRole : [Select Id, User__c,Business_Role__r.Global_Equivalent__c from User_Business_Role__c 

                                                  where  User__c  IN : terrToUserMap.values() AND Business_Role__r.Global_Equivalent__c =:globalEquivalentRole]){

                                                      userToRoleMap.put(userRole.User__c, userRole.Business_Role__r.Global_Equivalent__c);
                                                  }
        }
        /*
        for(Territory_Member__c userTerr :[SELECT Id,User__c,User__r.Business_Role__c,Type__c,User__r.name,Territory__c from Territory_Member__c 
                                          where  User__r.Business_Role__c ='Dispense Rep' AND Type__c = 'Primary' AND Territory__c IN :terrIds]){
                                              terrToUserMap.put(userTerr.Territory__c,userTerr.User__c);
        }*/
        for(Account acc : outlets){
            if(outletToTerritoryMap.containsKey(acc.Id)){
                List<Id> territories = outletToTerritoryMap.get(acc.Id);
                for(Id ter:territories){
                    if(terrToUserMap.containsKey(ter)){
                        String userId = terrToUserMap.get(ter);
                        if(userToRoleMap.containsKey(userId)){
                        outeltDisRepUser.put(acc.Id, terrToUserMap.get(ter));
                    }
                }
            }
        }
        }
        
        List<Asset> lcAsset = new List<Asset>();
        
        if(accounIds != null && accounIds.size() >0 ){
            lcAsset	= [SELECT Id, AccountId,country__c,country__r.code__c,product__c,Quantity, Account.Country__c, Offset_Day__c
                       FROM Asset 
                       WHERE AccountId In : accounIds
                       AND Offset_Day__c > 0
                       AND Master_Asset__r.Line_Cleaning_Asset__c = true
                       AND Asset_Removed__c = false
                       AND Master_Asset__r.Active__c = true
                       AND RecordTypeId = :qualityAssetRecordTypeId
                       Order By AccountId, Offset_Day__c];
                       // GT-26 added quality asset filter
        }
         if(lcAsset != null && lcAsset.size() >0 ){
            if(mCycles.size() >1 ){
                for(Line_Cleaning_Cycle__c lCycle : mCycles){
                    if(lCycle.Start_Date__c  == todaysDate && lCycle.End_Date__c > todaysDate){
                        reValidatedCaseTask(mCycles[0], lcAsset, lineHoliday);
                        if(mCycles[1].Batch_Processed__c == false){
                            newCreateCaseTaskCreation (mCycles[1], lcAsset, lineHoliday);
                        }
                    }
                }
                
                if(offSetFlagAssetList != null && offSetFlagAssetList.size() > 0){
                    //To make is offset day changed flag to false
                    Database.update(offSetFlagAssetList);
                }
           
                if(callList != null && callList.values().size() >0 ){
                    Database.SaveResult[] srList = Database.insert(callList.values(), false);
                    Integer index = 0;
                    for(call__c callRec : callList.values()){
                        Database.SaveResult sr = srList[index];
                        if(sr.isSuccess()){
                            insertedCallRecordMap.put(callRec.LineCleaningUniqueId__c, sr.id);
                        }
                        index++;
                    }
                }
                if(insertedCallRecordMap !=null && caseList != null && caseList.values().size() > 0){
                    for(Case caseRec : caseList.values()){
                        caseRec.Call__c = insertedCallRecordMap.containsKey(caseRec.LineCleaningUniqueId__c) ? insertedCallRecordMap.get(caseRec.LineCleaningUniqueId__c) : null;
                    }
                    Database.SaveResult[] srList = Database.insert(caseList.values(), false);
                    for(Database.SaveResult cse : srList){
                        caseSet.add(cse.getId());
                    }
                    Integer index = 0;
                    for(Case caseRec : caseList.values()){
                        Database.SaveResult sr = srList[index];
                        if(sr.isSuccess()){
                            insertedCaseRecordMap.put(caseRec.LineCleaningUniqueId__c, sr.id);
                        }
                        index++;
                    }
                }
                if(insertedCallRecordMap !=null && caseTaskList != null && caseTaskList.size() > 0){
                    Integer index = 0;
                    for(Case_task__c caseTaskRec : caseTaskList){
                         caseTaskRec.Call__c = insertedCallRecordMap.containsKey(caseTaskRec.LineCleaningUniqueId__c) ? insertedCallRecordMap.get(caseTaskRec.LineCleaningUniqueId__c) : null;
                         caseTaskRec.Case__c = insertedCaseRecordMap.containsKey(caseTaskRec.LineCleaningUniqueId__c) ? insertedCaseRecordMap.get(caseTaskRec.LineCleaningUniqueId__c) : null;
                        
                        index++;
                    }
                    Database.SaveResult[] srList = Database.insert(caseTaskList, false);
                }
                
            }
        }
    }
    public static void reValidatedCaseTask(Line_Cleaning_Cycle__c mCycle, List<Asset> assetList,Map<Id,List<Line_Cleaning_Holiday__c>> lineCholiday){
        List<Case_Task__c> existingCaseTask = fetchCaseTaskAgainstLC(mCycle,assetList);
        //Create a Map with Asset id and case Task MAP<AssetId,CaseTask>
        Map<Id,List<Case_Task__c>> assetToCtMap = new Map<Id,List<Case_Task__c>>();
        List<Asset> newAssetList = new List<Asset>();
        Set<Id> assetOffSetChangeSet = new Set<Id>();
        
        if(existingCaseTask.size() >0 && existingCaseTask !=null){
            for(Case_Task__c Ct : existingCaseTask){
                if(assetToCtMap.containsKey(Ct.Line_Cleaning_Asset__c)){
                    assetToCtMap.get(Ct.Line_Cleaning_Asset__c).add(ct);
                }
                else{
                    assetToCtMap.put(Ct.Line_Cleaning_Asset__c, new List<Case_Task__c>{ct});
                }
            }
        }
        
        if(assetList.size()>0 && assetList!=null){
            for(Asset assetRec: assetList){
                //check asset id is present in above map or not.Create Map for New Asset which is not present in existingCaseTask.
                //Create Map for AssetOffsetDay Changed
                if(!assetToCtMap.containsKey(assetRec.Id)){
                    newAssetList.add(assetRec);
                }
                
            }
        }
        
        List<Case_Task__C> caseTasktoUpdate = new List<Case_Task__C>();
        Map<Id,Date> caseTaskDueDateMap = new  Map<Id,Date>();
        if(newAssetList !=null && newAssetList.size() >0){
            newCreateCaseTaskCreation(mCycle, newAssetList, lineCholiday);
        }
        if(assetToCtMap !=null && assetToCtMap.size() >0){
            List<Asset> modifiedAssetsList = [SELECT Id,Is_OffsetDay_Changed__c,Offset_Day__c,Quantity,Product__c FROM Asset WHERE Id IN:assetToCtMap.keySet() AND Is_OffsetDay_Changed__c = true];
            for(Asset ChangedAsset : modifiedAssetsList){
                Date updatedDueDate = calculateDueDate(mCycle.Start_Date__c, ChangedAsset.Offset_Day__c, lineCholiday.get(mCycle.Id));
                if(assetToCtMap.containsKey(ChangedAsset.Id)){
                    ChangedAsset.Is_OffsetDay_Changed__c = false;
                    offSetFlagAssetList.add(ChangedAsset);
                    for(Case_Task__c cst :assetToCtMap.get(ChangedAsset.Id)){
                        cst.Quantity__c = ChangedAsset.Quantity;
                        cst.Product__c = ChangedAsset.Product__c;
                        caseTasktoUpdate.add(cst);
                        caseTaskDueDateMap.put(cst.Id,updatedDueDate);
                    }
                }
            }
        }
        updateLineDueDate(caseTasktoUpdate, caseTaskDueDateMap);
    }
    public static void newCreateCaseTaskCreation(Line_Cleaning_Cycle__c mCycle, List<Asset> assetList,Map<Id,List<Line_Cleaning_Holiday__c>> lineCholiday){
        List<Call_Type__c> callTypesList = new List<Call_Type__c>();
        List<Quality_Case_Configuration__c> caseTypesList = new List<Quality_Case_Configuration__c>();
        List<Quality_Case_Configuration__c> caseSubTypesList = new List<Quality_Case_Configuration__c>();
        List<Quality_Case_Configuration__c> caseTaskTypeList = new List<Quality_Case_Configuration__c>();  
        Map<Id,Case> assetToCase = new  Map<Id,Case>();
        
        Call_Type__c callTyp = fetchCallType();
        Quality_Case_Configuration__c caseType = fetchCaseType();
        Quality_Case_Configuration__c caseSubtype = fetchCaseSubType();
        Quality_Case_Configuration__c caseTaskType = fetchCaseTaskType();
        
        if(assetList != null && assetList.size() >0){
            for(Asset assetRec: assetList){
                Date dueDate = calculateDueDate(mCycle.Start_Date__c,assetRec.Offset_Day__c,lineCholiday.get(mCycle.Id));
                String cmpKey = assetRec.AccountId + '_' + mCycle.Id +'_'+ assetRec.Id;
                Call__c call = createCall(assetRec, mCycle, dueDate, callTyp);
                Case cse = createCase(assetRec, mCycle, dueDate, caseType, caseSubtype);
                Case_Task__c casetask = createCaseTask(assetRec, mCycle, dueDate, caseTaskType);
                
                if(!callList.containsKey(cmpKey)){
                    callList.put(cmpKey,call);
                }
                if(!caseList.containsKey(cmpKey)){
                    caseList.put(cmpKey,cse);
                }
                caseTaskList.add(casetask);
                
            }
        }
    }
    Private static Quality_Case_Configuration__c fetchCaseTaskType(){
        Quality_Case_Configuration__c caseConfig = [SELECT Id, Name , country__c,country__r.code__c,Case_Sub_Type__c 
                                                    FROM Quality_Case_Configuration__c WHERE Name IN :caseTaskTypes 
                                                    AND RecordTypeId =:caseTaskTypeRecTypeId 
                                                    AND country__r.code__c=:Country AND Active__c = true LIMIT 1];
        return caseConfig;
        
    }
    
    Private static Quality_Case_Configuration__c fetchCaseType(){
        Quality_Case_Configuration__c caseConfigType = [SELECT Id, Name,Country__c,Country__r.code__c FROM Quality_Case_Configuration__c 
                                                        WHERE Name IN :caseTypes AND RecordTypeId =:caseTypeRecTypeId 
                                                        AND Country__r.code__c=:Country AND Active__c = true LIMIT 1];
        return caseConfigType;
        
    }
    
    Private static Quality_Case_Configuration__c fetchCaseSubType(){
        Quality_Case_Configuration__c caseConfigSubType =[SELECT Id, Name,Country__c,
                                                          Country__r.code__c FROM Quality_Case_Configuration__c
                                                          WHERE Name IN :caseSubTypes 
                                                          AND RecordTypeId =:caseTaskSubTypeRecTypeId 
                                                          AND Country__r.code__c =:Country 
                                                          AND Active__c = true LIMIT 1];
        
        return caseConfigSubType;
        
    }
    
    Private static Case CreateCase(Asset asset, Line_Cleaning_Cycle__c mCycle,Date dueDate,Quality_Case_Configuration__c caseType,Quality_Case_Configuration__c SubType){
        Case cse = new case();
        cse.AccountId = asset.AccountId;
        cse.Case_Type__c = caseType.Id;
        cse.Case_Sub_Type__c = SubType.Id;
        if(datetimeFunction.contains('DateTime.newInstance')){
        cse.Due_Date_Time__c = DateTime.newInstance(dueDate, Time.newInstance(22,00,0,0));
        }else{
            //ES20-11888
        cse.Due_Date_Time__c = DateTime.newInstanceGMT(dueDate, Time.newInstance(22,00,0,0));//ES20-12343
        }
        cse.RecordTypeId = QualityRecordTypeId;
        cse.LineCleaningUniqueId__c = asset.AccountId + '_' + mCycle.Id +'_'+ asset.Id;
        cse.Status = EDGE_Constant.OPEN_QUALITYCASE;
        cse.Batch_Generated__c = true;
        cse.Manual_SLA_Extension__c = true;
        return cse;
        
    }
    
    Private static Call_Type__c fetchCallType(){
        Call_Type__c callTyp=[SELECT Id,Name FROM Call_Type__c WHERE Name =:callTypeName AND country__r.code__c=:Country];
        return callTyp;
    }
    
    Private static Call__c createCall(Asset asset, Line_Cleaning_Cycle__c mCycle,Date dueDate,Call_Type__c callTyp){
        Call__c callRec = new Call__c();
        callRec.Account__c = asset.AccountId;
        callRec.Status__c = 'Planned';
        callRec.Planned_Call_Type__c = callTyp.Id;
        if(datetimeFunction.contains('DateTime.newInstance')){
        callRec.Plan_Start_Date__c = DateTime.newInstance(dueDate, Time.newInstance(8,00,0,0));
        callRec.Plan_End_Date__c   = DateTime.newInstance(dueDate, Time.newInstance(8,05,0,0));
        }else{//ES20-11888
        callRec.Plan_Start_Date__c = DateTime.newInstanceGMT(dueDate, Time.newInstance(8,00,0,0));//ES20-12343
        callRec.Plan_End_Date__c   = DateTime.newInstanceGMT(dueDate, Time.newInstance(8,05,0,0));//ES20-12343
        }
        callRec.Assigned_To__c = outeltDisRepUser.get(asset.AccountId);
        callRec.Line_Cleaning_Cycle__c = mCycle.Id;
        callRec.LineCleaningUniqueId__c = asset.AccountId + '_' + mCycle.Id +'_'+ asset.Id;
        return callRec;
    }
    
    Private static Case_Task__c createCaseTask(Asset asset, Line_Cleaning_Cycle__c mCycle,Date dueDate,Quality_Case_Configuration__c caseTaskType){
        Case_Task__c taskRec = new Case_Task__c();
        taskRec.Country__c = asset.Country__c;
        taskRec.Case_Task_Type__c = caseTaskType.Id;
        taskRec.Product__c = asset.Product__c;
        taskRec.Quantity__c = asset.Quantity;
        taskRec.Batch_Generated__c = true;
        taskRec.User_Assigned_To__c = outeltDisRepUser.get(asset.AccountId);
        taskRec.Achievement_Status__c = 'Open';
        taskRec.Line_Cleaning_Asset__c = asset.Id;
        taskRec.Line_Cleaning_Cycle__c = mCycle.Id;

        taskRec.LineCleaningUniqueId__c = asset.AccountId + '_' + mCycle.Id +'_'+ asset.Id;
        if(datetimeFunction.contains('DateTime.newInstance')){
        taskRec.Line_Cleaning_Due_Date__c = DateTime.newInstance(dueDate, Time.newInstance(22,00,0,0));
        }else{
            //ES20-11888
        taskRec.Line_Cleaning_Due_Date__c = DateTime.newInstanceGMT(dueDate, Time.newInstance(22,00,0,0));//ES20-12343
        }
        taskRec.Suggested_User__c = outeltDisRepUser.get(asset.AccountId);

        return taskRec;
    }
    
    Private static List<Case_Task__c> fetchCaseTaskAgainstLC(Line_Cleaning_Cycle__c mCycle, List<Asset> assetList){
        List<Case_Task__c> taskRecList = new List<Case_Task__c>();
        for(Case_Task__c cst:[SELECT Id,Name,Call__c,Call__r.Plan_Start_Date__c,Case__c,Case__r.Due_Date_Time__c,
                              Line_Cleaning_Asset__c,Line_Cleaning_Cycle__c 
                              FROM Case_Task__c 
                              WHERE Line_Cleaning_Asset__c IN:assetList 
                              AND Line_Cleaning_Cycle__c =:mCycle.Id]){
                                  taskRecList.add(cst);
                              }
        return taskRecList;
    }
    
    public static Date calculateDueDate(Date dateStart, Decimal intOffset, List<Line_Cleaning_Holiday__c> lHolidays){
        //One subtracted to account for day 1 being the start date
        if(intOffSet == null)
            intOffSet = 0;
        else if(intOffSet !=0 )
            intOffset--;
        //Initialize end date with start date and use it for calculations
        Date dateEnd = dateStart;
        
        //For all days between now and the offset
        for(Integer i=0; i < intOffset; i++ ){
            
            dateEnd = dateEnd.addDays(1);
            
            //If the calculated date is a weekend, skip it by increasing intOffset
            if(EDGE_LineCleaningCycleHelper.checkifItisWeekend(dateEnd)){
                intOffset++;
            }
            
        }
        
        if(lHolidays!=null){
            for(Line_Cleaning_Holiday__c hday :lHolidays){
                if(hday.Exclusion_Date__c>=dateStart && hday.Exclusion_Date__c<=dateEnd){
                    dateEnd = dateEnd.addDays(1);
                    //If the calculated date is a weekend, skip it by increasing intOffset
                    while(checkifItisWeekend(dateEnd)){
                        dateEnd = dateEnd.addDays(1);
                    }
                }
            }
        }
        
        //return the calculated day
        return dateEnd;
        
    } 
    
    public static boolean checkifItisWeekend(Date currentDate){                       
        DateTime newCurrentDate = DateTime.newInstance(currentDate.year(), currentDate.month(), currentDate.day());
        if( newCurrentDate.format('E') == 'Sat' || newCurrentDate.format('E') == 'Sun' ){
            return true;
        } else 
            return false;        
    }
    
    public static void updateLineDueDate(List<Case_Task__c> updateCaseTaskList,Map<Id,Date> caseTaskDueDateMap){
        List<Case_Task__c> updateCaseTaskDueDateList = new List<Case_Task__c>();   
        Map<Id,Case> updateCaseDueDateMap = new Map<Id,Case>();
        Map<Id,Call__c> updateCallMap = new Map<Id,Call__c>();
        DateTime caseTaskDueDateTime;
        DateTime caseDueDateTime;
        DateTime planStartDate;
        DateTime planEndDate;
        for(Case_Task__c caseTaskRec: updateCaseTaskList){    
            Date dueDate = caseTaskDueDateMap.get(caseTaskRec.Id);
            
            Case_Task__c caseTaskObj = new Case_Task__c(Id = caseTaskRec.Id);
            if(datetimeFunction.contains('DateTime.newInstance')){
             caseTaskDueDateTime = DateTime.newInstance(dueDate, Time.newInstance(22,00,0,0));  
            }else{//ES20-11888
             caseTaskDueDateTime = DateTime.newInstanceGMT(dueDate, Time.newInstance(22,00,0,0));
            }
            caseTaskObj.Line_Cleaning_Due_Date__c = caseTaskDueDateTime;
            caseTaskObj.Quantity__c = caseTaskRec.Quantity__c;
            caseTaskObj.Product__c = caseTaskRec.Product__c;
            updateCaseTaskDueDateList.add(caseTaskObj);
            
            Case caseObj = new Case(Id=caseTaskRec.Case__c);  
            if(datetimeFunction.contains('DateTime.newInstance')){
            caseDueDateTime = DateTime.newInstance(dueDate, Time.newInstance(22,00,0,0));
            }else{
                //ES20-11888
            caseDueDateTime = DateTime.newInstanceGMT(dueDate, Time.newInstance(22,00,0,0));
            }
            caseObj.Due_Date_Time__c = caseDueDateTime;
            if(!updateCaseDueDateMap.containsKey(caseObj.Id)){
                updateCaseDueDateMap.put(caseObj.Id,caseObj);
            }
            
            if(CaseTaskRec.Call__c != null){
                Call__c callObj = new Call__c(Id= CaseTaskRec.Call__c);
                if(datetimeFunction.contains('DateTime.newInstance')){
                planStartDate = DateTime.newInstance(dueDate, Time.newInstance(8,00,0,0));
                planEndDate = DateTime.newInstance(dueDate, Time.newInstance(8,05,0,0));
                }else{
                    //ES20-11888
                planStartDate = DateTime.newInstanceGMT(dueDate, Time.newInstance(8,00,0,0));
                planEndDate = DateTime.newInstanceGMT(dueDate, Time.newInstance(8,05,0,0));
                }
                callObj.Plan_Start_Date__c = planStartDate;
                callObj.Plan_End_Date__c = planEndDate;
                if(!updateCallMap.containsKey(callObj.Id)){
                    updateCallMap.put(callObj.Id,callObj);
                }
            }
        }
        
        if(updateCaseTaskDueDateList != null && updateCaseTaskDueDateList.size()>0){
            Database.upsert(updateCaseTaskDueDateList,false);
        }
        if(updateCaseDueDateMap != null && updateCaseDueDateMap.size()>0){
            Database.upsert(updateCaseDueDateMap.values(),false);
        }
        if(updateCallMap != null && updateCallMap.size()>0){
            List<Database.UpsertResult> callResult = Database.upsert(updateCallMap.values(),false);
        }
    }
}