/**

* @description :  EDGE_TerritoryProcessRepDeleteBatch

* @purpose : Batch Class for deleting outlet reps

* @history :

* Version    Developer                Date             User Story/Purpose

*  1.1      Anuja Chattopadhyay     21/02/2019        Initial Development
*  1.2	    Kapil Baliyan			30/12/2019		  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*  1.3      Mayukh S Roy            28/12/2022        ES20-13681
*/

public class EDGE_TerritoryProcessRepDeleteBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    /*Constant Final Strings*/
    private final static String WAITING_REMOVAL = 'Waiting Removal';
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    Date currentDate = Date.today();
    Date yesterdayDate = currentDate.addDays(-1); 
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    /*Start Method*/
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        string countryCode = '';
        countryCode = batchSetting.Country_Code__c;
        
        String strQuery = 'Select Id, Start_Date__c, End_Date__c, Territory__c, Type__c, User__c,User__r.Trax_User__c,User__r.Available_Countries__c,User__r.Default_Country__c from Territory_Member__c'+ 
            ' where Start_Date__c <= :currentDate AND (End_Date__c >= :yesterdayDate OR End_Date__c=null) AND Territory__r.Country__r.Code__c=:countryCode';
        
        return Database.getQueryLocator(strQuery);
    }
    
    /*Execute Method*/
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        Set<id> outletIdSet = new Set<id>();
        Set<Id> userIdsToUpdate = new Set<Id>();
        List<User> userListToUpdate = new List<User>();
        Set<id> territoryIdSet = new Set<id> ();
        Set<id> userIdSet = new Set<id>(); 
        //Map<String,Territory_Member__c> territoryMemMap = new Map<String,Territory_Member__c>();
        Set<Id> territoryMemToRemoveSet = new Set<Id>();
        Map<String,Outlet_Member__c > outletTeamMap = new Map<String,Outlet_Member__c >();
        //List<Outlet_Member__c> outletTeamToUpdateList = new List<Outlet_Member__c>();
        List<Trax_User_Update__c> traxUserUpdate=new List<Trax_User_Update__c>();
        Map<String,List<Territory_Member__c>> allTerritoryMemMap = new Map<String,List<Territory_Member__c>>();
        Set<String> outletUserSet = new Set<String>();
        
        try{
            for(sObject sObj: scope){
                Territory_Member__c objTerrMem = (Territory_Member__c) sObj;
                territoryIdSet.add(objTerrMem.Territory__c);
                userIdSet.add(objTerrMem.User__c);
                //System.debug('userIdSet : '+ userIdSet);
                Date yesterdayDate = Date.today().addDays(-1);
                
                //ES20-13681 - Get TerritoryMemberMap for each territory
                if(allTerritoryMemMap.containsKey(objTerrMem.Territory__c)){
                    allTerritoryMemMap.get(objTerrMem.Territory__c).add(objTerrMem); 
                }
                else{
                    allTerritoryMemMap.put(objTerrMem.Territory__c,new List<Territory_Member__c>{objTerrMem});
                }
                //System.debug('allTerritoryMemMap : '+ allTerritoryMemMap);
                //Create Territory Map where Territory rep End Date is set as previuos date
                if(objTerrMem.End_Date__c == yesterdayDate && objTerrMem.User__c!=Null) {
                    if(objTerrMem.Type__c == 'Primary'){
                        //Populate User Ids for Manager Removal
                        userIdsToUpdate.add(objTerrMem.User__c);
                    }                       
                    //territoryMemMap.put(objTerrMem.Territory__c, objTerrMem);
                    territoryMemToRemoveSet.add(objTerrMem.Territory__c);
                    String countryCode = EDGE_BatchUtilityClass.getUserCountryCode(objTerrMem.User__r.Default_Country__c, objTerrMem.User__r.Available_Countries__c);                     
                    if(objTerrMem.User__r.Trax_User__c && countryCode != null && countryCode != ''){
                        //traxUserUpdate.add(new Trax_User_Update__c(name=objTerrMem .User__c,Country_Code__c=batchSetting.Country_Code__c));
                        traxUserUpdate.add(new Trax_User_Update__c(name=objTerrMem.User__c,Country_Code__c=countryCode));
                    }   
                }
            }
            //System.debug('userIdsToUpdate : '+ userIdsToUpdate);
            //System.debug('traxUserUpdate : '+ traxUserUpdate);
            //Create Outlet Id Set where Territory Member End Date is matched & Outlet Territory Status is Waiting Removal
            for(Outlet_Territory__c  oT : [Select Id, Active__c, Outlet__c,Territory__c from Outlet_Territory__c 
                                           WHERE Territory__c in :territoryIdSet])
            {
                if((territoryMemToRemoveSet != Null && territoryMemToRemoveSet.size() > 0 && territoryMemToRemoveSet.contains(oT.Territory__c)) || (oT.Active__c == WAITING_REMOVAL)){ //ES20-13681
                    outletIdSet.add(oT.Outlet__c);
                    //ES20-13681
                    for(Territory_Member__c tm :allTerritoryMemMap.get(oT.Territory__c)){
                        String outletUser = tm.User__c+'-'+oT.Outlet__c;
                        if(oT.Active__c == WAITING_REMOVAL || tm.End_Date__c == yesterdayDate){
                            outletUserSet.add(outletUser);
                        }
                    }
                }
            }
            //System.debug('outletUserSet : '+ outletUserSet);
            
            //List to fetch all the outlet member where User is present in the scope and outlet is marked above to remove the users from 
            for(Outlet_Member__c om : [Select Id, Flag_For_Deletion__c, User__c,User__r.Name, Outlet__c,Outlet__r.Name from Outlet_Member__c 
                                       WHERE User__c in:userIdSet AND Outlet__c in :outletIdSet and OutletUser__c in :outletUserSet]) //ES20-13681 - Added OutletUser Key to get specific OutletMember Records
            {
                om.Flag_For_Deletion__c = true; 
                outletTeamMap.put(om.Id, om);
            } 
            //System.debug('outletTeamMap : '+ outletTeamMap);
            //Updating Users to Clear Manager
            for(User salesRep : [SELECT Id FROM User WHERE Id IN :userIdsToUpdate]){
                salesRep.managerId = null;
                userListToUpdate.add(salesRep);
            }
            //System.debug('userListToUpdate : '+ userListToUpdate);
            if(userListToUpdate != null && userListToUpdate.size() > 0){
                update userListToUpdate;
            }               
            
            if(!outletTeamMap.isEmpty()){
                update outletTeamMap.values();
            }
            
            if(!traxUserUpdate.isEmpty() && traxUserUpdate.size()>0){
                database.upsert(traxUserUpdate,false);
            }
        }
        catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex){
            system.debug(LoggingLevel.DEBUG,'@@Exception' + ex.getMessage());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TerritoryProcessRepDeleteBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
}