/**

* @Description :  EDGE_TerritoryProcessRepInsertBatch

* @Purpose : Batch Class for inserting outlet reps

* @History :

* @Version    Developer                Date             User Story/Purpose

* 	1.1       Anuja Chattopadhyay     25/02/2019        Initial Development
* 	1.2       Srutadeba Chanda        22/05/2019        ES20-1783 Update Primary sales rep name on territory
* 	1.3       Anuja Chattopadhyay     24/09/2019        ES20-4482 Introduce two separate list updateTerritoryListForAddition and updateTerritoryListForAddition since batch was failing as updateTerritoryList was having duplicate Id.
* 	1.4       Kapil Baliyan           30/12/2019        Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
* 	1.5	      Juned Khan			  11/11/2020		ES20-8865 11-Nov-2020 to include new territory member created today
* 	1.6	      Juned Khan			  03/12/2020		ES20-9079	to include current active territory member
* 	1.7		  Monalisa Halder		  25/02/2021		ES20-9804
* 	1.8       Dinesh Sharma           19/05/2021        ES20-9768 Insert Quality Rep to Account Team and Outlet Member
* 	1.9	      Prasanth T		      22/06/2021		ES20-9851 - Null Check
*	2.0		  Aparajita/Rajarshi/     11/03/2022		ES20-12216,12231,12213
Subhodeep

*	2.1	      Subhodeep Sarkar		  13/05/2022		ES20-12254  - Added if block for Activation Specialist population in AT
*   2.2       Mayukh S Roy            28/12/2022        ES20-13681 
*	2.3		  Shivam Chauhan		  23/02/2024		149988 - New Primary SR is assigned to Territory_Contract Owner Update_SFDC
*	2.4		  Shivam Chauhan		  23/02/2024		149989 - New Activation Specialist assigned to Activation territory_Contract Owner Update for AS_SFDC
*	2.5		  Suvendu Roy			  21/06/2024		154642 - EDGE Classes_Fix Static Code Analysis Error_Story_4
*   2.6       Joshraj Sen             28/06/2024        154642 - Fixed the SCA ApexDoc
*/
/**
 * @description Populates the Reps to the Territory EDGE_TerritoryProcessRepInsertBatch
*/
public class EDGE_TerritoryProcessRepInsertBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    final static String SALESRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Sales Territory').getRecordTypeId();     
    final static String QUALITYRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Quality Territory').getRecordTypeId();  
    final static String ACTIVATIONRECORDTYPEID = Territory__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Activation Territory').getRecordTypeId(); //ES20-12216,12231,12213 
    List<EDGE_BatchSObjectWrapper> wrapperRecords = new List<EDGE_BatchSObjectWrapper>();
    
    //Interface Class Method
    /**
     * @Name : getBatchDetails
	 * @description : This method to return values EDGE_BatchSObjectWrapper List and TraxUserUpdate List to the batch class as a EDGE_BatchSObjectOutputWrapper
     * @param batchSetting
	 */
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    /**
     * @Name : start
	 * @description : This method starts the Batch
     * @param bc
     * @return Database.QueryLocator
	 */
    public Database.QueryLocator start(Database.BatchableContext bc){
        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); 
        
        string countryCode = '';
        countryCode = batchSetting.Country_Code__c;
        Date currentDate = Date.today();
        Date yesterdayDate;
        yesterdayDate = currentDate.addDays(-1);    
        String strQuery = 'Select Id, Start_Date__c,End_Date__c, Territory__c,Territory__r.Last_Primary_Sales_Rep__c, Type__c, User__c,User__r.Trax_User__c,User__r.Default_Country__c,User__r.Available_Countries__c from Territory_Member__c' +
            ' where Start_Date__c <= :currentDate AND (End_Date__c >= :yesterdayDate OR End_Date__c=null) AND Territory__r.Country__r.Code__c=:countryCode';
        return Database.getQueryLocator(strQuery);
        
    }
    
    //Execute Method
    /**
     * @Name : start
	 * @description : This method performs the logical operations
     * @param bc
     * @param terrMemList
	 */
    public void execute(Database.BatchableContext bc, List<Territory_Member__c> terrMemList){
        //Assignment
        List<Contract> updatedContractRecord = new List<Contract>();//149988
        //Get All needed Maps And Lists in combinedWraapper
        EDGE_BatchSObjectCombinedWrapper combinedWraapper =EDGE_TerritoryProcessInsertHelper.getCombinedWrapper(terrMemList);
        //Get Maps And Lists for Territory Addition And Removal in mapWrapper
        EDGE_BatchSObjectMapWrapper mapWrapper = getListForTerritoryAdditionAndRemoval(terrMemList, combinedWraapper);
        
        EDGE_BatchSObjectOutputWrapper outputWrapper = EDGE_TerritoryProcessInsertExtHelper.getWrapperRecordsAndTraxUsers(combinedWraapper,mapWrapper.userTerritoryMemberMap);
        wrapperRecords.addAll(outputWrapper.wrapperRecords);
        updatedContractRecord = updateContractOwner(terrMemList,combinedWraapper.territoryMap);//149988
        
        if(!mapWrapper.updateTerritoryListForRemoval.isEmpty()){
            update mapWrapper.updateTerritoryListForRemoval;
        }
        
        //EDGE_UtilityClass.printGovLimits(189);
        if(!mapWrapper.updateTerritoryListForAddition.isEmpty()){
            update mapWrapper.updateTerritoryListForAddition;
        }
        
        if(!updatedContractRecord.isEmpty()){//149988
            update updatedContractRecord;
        }
        
        //EDGE_UtilityClass.printGovLimits(196);
        
        if(!outputWrapper.traxUserUpdate.isEmpty()){
            database.upsert(outputWrapper.traxUserUpdate,false);
        }  
        
        //EDGE_UtilityClass.printGovLimits(216);
        
    }
    
    //Finish Method - Update ES20-6594
    /**
     * @Name : start
	 * @description : This method schedules the Next Batch
     * @param bc
	 */
    public void finish(Database.BatchableContext bc){
        //EDGE_UtilityClass.printGovLimits(234);
        
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TerritoryProcessRepInsertBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        /*for(EDGE_BatchSObjectWrapper wrapper:wrapperRecords)
        {
            System.debug(LoggingLevel.Debug,'Wrapper '+wrapper);
        }*/
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError, wrapperRecords);
        }
        //EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError, outletMemberForNextBatch);
        //EDGE_UtilityClass.printGovLimits(252);
    }

     /**
     * @ADO Number : 149988
     * @Name : updateContractOwner
	 * @description : This method is used to get Contract details whose Owner Id is updated as per current primary Sales Rep.
     * @param terrMemList
     * @param territoryMap
     * @return List<Contract>
	 */
    public static List<contract> updateContractOwner (List<Territory_Member__c> terrMemList, Map<Id,Territory__c> territoryMap){
        Date todaysDate = Date.today();
        Map<Id,Id> mapTerritoryNewPrimaryUser = new Map<Id,Id>();
        Map<Id,Id> mapTerritoryOldPrimaryUser = new Map<Id,Id>();
        String outletcontractrecordtype = Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('Outlet').getRecordTypeId();
        List<Contract> updatedContractRecord = new List<Contract>();
        
        for(Territory_Member__c terrMem : terrMemList){
            Territory__c territoryObj = territoryMap.get(terrMem.Territory__c);
            Boolean temp = territoryObj != null && (territoryObj.RecordTypeId == SALESRECORDTYPEID || territoryObj.RecordTypeId == ACTIVATIONRECORDTYPEID) && terrMem.Type__c == 'Primary';
            if(temp && terrMem.Start_Date__c == todaysDate){//149989 - Check for Activation
                mapTerritoryNewPrimaryUser.put(terrMem.Territory__c,terrMem.User__c);
            }
            if(temp && terrMem.Territory__r.Last_Primary_Sales_Rep__c != null){
                mapTerritoryOldPrimaryUser.put(terrMem.Territory__c,terrMem.Territory__r.Last_Primary_Sales_Rep__c);
            }
        }

        Boolean flag = !mapTerritoryNewPrimaryUser.isEmpty() && !mapTerritoryOldPrimaryUser.isEmpty();
        
        if(flag){
            for(Contract contractRec : [select id,OwnerId,ECM_Territory__c from Contract where RecordTypeId =: outletcontractrecordtype and ECM_Territory__c IN: mapTerritoryNewPrimaryUser.keyset() and OwnerId IN: mapTerritoryOldPrimaryUser.values() and Status != 'Cancelled']){
                contractRec.OwnerId = mapTerritoryNewPrimaryUser.get(contractRec.ECM_Territory__c);
                updatedContractRecord.add(contractRec);
            }
        }
        return updatedContractRecord;
    }
    
    /**
     * @ADO Number : 149989
     * @Name : AssignLastPrimarySalesRep
	 * @description : This method is used to populate Last primary Sales ReL in terrMemList.
     * @param terrMemList
     * @param terrMem
	 */
    public static void assignLastPrimarySalesRep (List<Territory_Member__c> terrMemList,Territory_Member__c terrMem){
       Integer indexOfTerrMem = terrMemList.indexOf(terrMem);
       if(terrMemList[indexOfTerrMem] != null && terrMemList[indexOfTerrMem].Territory__c != null){
           terrMemList[indexOfTerrMem].Territory__r.Last_Primary_Sales_Rep__c = terrMem.User__c;
         }
    }

    /**
     * @ADO Number : 154642
     * @Name : getListForTerritoryAdditionAndRemoval
	 * @description : This method is used to modify List of Territory.
     * @param terrMemList
     * @param combinedWraapper
     * @return mapWrapper
     * @throws Exception
	 */
    public static EDGE_BatchSObjectMapWrapper getListForTerritoryAdditionAndRemoval (List<Territory_Member__c> terrMemList,EDGE_BatchSObjectCombinedWrapper combinedWraapper){
        EDGE_BatchSObjectMapWrapper mapWrapper = new EDGE_BatchSObjectMapWrapper();
        Map<String, List<Territory_Member__c>> userTerritoryMemberMap = new Map<String, List<Territory_Member__c>>();
        List<Territory__c> updateTerritoryListForAddition= new List<Territory__c>(); 
        List<Territory__c> updateTerritoryListForRemoval= new List<Territory__c>(); 
        Date yesterdayDate = Date.today().addDays(-1);

        String salesAndQuality = SALESRECORDTYPEID+QUALITYRECORDTYPEID;
        //Create User & Outlet Map by using userTerritoryMap & territoryOutletMap
        for(Territory_Member__c terrMem : terrMemList){
            //ES20-12216,12231,12213
            Territory__c territoryObj = combinedWraapper.territoryMap.get(terrMem.Territory__c);
            //ES20-1783 change start
            Boolean isSalesTerrWithEndDayNotYesterday = territoryObj != null && salesAndQuality.contains(territoryObj.RecordTypeId) && (terrMem.End_Date__c > yesterdayDate || terrMem.End_Date__c==null) && terrMem.Type__c == 'Primary';
            Boolean isSalesTerrWithEndDayYesterday  = territoryObj != null && salesAndQuality.contains(territoryObj.RecordTypeId) && terrMem.End_Date__c == yesterdayDate &&  terrMem.Type__c == 'Primary';
            Boolean isActivationTerrWithEndDayNotYesterday = territoryObj != null && ACTIVATIONRECORDTYPEID == territoryObj.RecordTypeId && (terrMem.End_Date__c > yesterdayDate || terrMem.End_Date__c==null) && terrMem.Type__c == 'Primary';
            Boolean isActivationTerrWithEndDayYesterday = territoryObj != null && ACTIVATIONRECORDTYPEID == territoryObj.RecordTypeId && terrMem.End_Date__c == yesterdayDate &&  terrMem.Type__c == 'Primary';

            if(isSalesTerrWithEndDayNotYesterday){
                updateTerritoryListForAddition.add(new Territory__c(id=terrMem.Territory__c,Primary_Sales_Rep__c=terrMem.User__c));
            }
            else if(isSalesTerrWithEndDayYesterday){
                updateTerritoryListForRemoval.add(new Territory__c(id=terrMem.Territory__c,Primary_Sales_Rep__c=null,Last_Primary_Sales_Rep__c = terrMem.User__c));
                assignLastPrimarySalesRep(terrMemList,terrMem); //149988
            }
            else if(isActivationTerrWithEndDayNotYesterday){
                updateTerritoryListForAddition.add(new Territory__c(id=terrMem.Territory__c,Activation_Specialist__c=terrMem.User__c));
            }
            else if(isActivationTerrWithEndDayYesterday){
                updateTerritoryListForRemoval.add(new Territory__c(id=terrMem.Territory__c,Activation_Specialist__c=null,Last_Primary_Sales_Rep__c = terrMem.User__c));
                assignLastPrimarySalesRep(terrMemList,terrMem); //149988
            }
            //ES20-1783 change end 
            userTerritoryMemberMap.putAll(EDGE_TerritoryProcessInsertHelper.getUserTerritoryMemberMap(terrMem, combinedWraapper.territoryOutletMap));
             
                   
        }

        mapWrapper.userTerritoryMemberMap = userTerritoryMemberMap;
        mapWrapper.updateTerritoryListForAddition = updateTerritoryListForAddition;
        mapWrapper.updateTerritoryListForRemoval = updateTerritoryListForRemoval;
        return mapWrapper;
     }

    /**
     * @ADO Number : 154642
     * @Name : EDGE_BatchSObjectMapWrapper
	 * @description : This Wrapper class to return values from getListForTerritoryAdditionAndRemoval method.
	 */
     public class EDGE_BatchSObjectMapWrapper {
           /**
     * @description User and Territory Member Details
     * @return Map<String, List<Territory_Member__c>> 
     */
        public Map<String, List<Territory_Member__c>> userTerritoryMemberMap{get;set;}
         /**
     * @description Territories to add the Rep
     * @return List<Territory__c>
     */
        public List<Territory__c> updateTerritoryListForRemoval{get;set;}
         /**
     * @description Territories to remove the Rep
     * @return List<Territory__c>
     */
        public List<Territory__c> updateTerritoryListForAddition{get;set;}
    }
}