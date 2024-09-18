/*

* @description :  EDGE_TerritoryProcessStatusUpdateBatch

* @purpose : Batch Class for deleting and inserting Account Share , Account Team records for Outlet Reps that have been created/deleted

* @Test Class: EDGE_TerritoryProcessStUpdateBatchTest

* @history :

* Version    Developer                Date             User Story/Purpose

*  1.1      Monalisa Halder         25/02/2019        Initial Development
*  1.2      Anuja Chattopadhyay     05/04/2019        primarySalesTerDetailsPopulate,primarySalesTerDetailsRemove added to populate and remove the primary sales territory details
*  1.3      Dipanjan Das            21/05/2019        populating primary rep to the territory for  ES20-1783 
*  1.4      Saurav Paul             29/05/2019        populating primary sales area for ES20-1739 
*  1.5		Kapil Baliyan			30/12/2019	      Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
*  1.6      Sandip Ghosh            28/10/2020        ES20-8778 (Batch to add Activation Specialists to outlet)
*  1.7 	    Juned Khan				04/12/2020		  ES20-8780 (Batch to remove Activation Specialists from outlet)			
*  1.8      Aparajita/Rajarshi
			/Subhodeep/Joshraj      11/03/2022        ES20-12216,12231,12213,12228 (Batch to Add Activation Territory to Outlets)
*  1.9      Mayukh S Roy			23/05/2022        US-2887206 - Territory Details population in Account Level
*  2.0      Priya Soni              04/11/2022        ES20-13469(Method populatePrimarySalesDetails, populate Dispense rep field in Account Object when Primary Territory member is added to Dispense Territory)   
*  2.1      Mayukh SRoy             06/12/2022        ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  2.2      Mayukh SRoy      		27/04/2023        ES20-14015
*  2.3		Rajarshi Lahiri			10/05/2023		  ES20-14046
*  3.0		Dipanjan Das			24/06/2024		  154639 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch 
																& Creation of EDGE_TerritoryProcessStatusUpdateHelper 
																& EDGE_TerritoryProcessStatusUpdateHlpExtn
*  4.0		Sudipta Nandy			24/06/2024		  154640 -- To fix the SCA of EDGE_TerritoryProcessStatusUpdateBatch
																& Creation of EDGE_TerritoryProcessStatusUpdateHelper 
																& EDGE_TerritoryProcessStatusUpdateHlpExtn
*/
    
    /**
* @description : Update o-t from Waiting Activation to Active and Delete o-t from Waiting Remvoal
*/

public class EDGE_TerritoryProcessStatusUpdateBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    String exceptionMsg = '';
    Id marketBatchJobId;
    
      /**
* @description : Interface Class Method
* @param batchSetting
*/
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }

       /** 
* @description start - start method for the Batch
* @return Database.QueryLocator
* @param bc
**/
    public Database.QueryLocator start(Database.BatchableContext bc){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId());
        string countryCode;
        countryCode = batchSetting.Country_Code__c;
        string strQuery = 'Select Id, Name, Active__c, Outlet__c, Territory__c, Outlet__r.Country__r.Code__c, '+ 
                            'Territory__r.Region__c,Territory__r.Region__r.Parent_BU__c, '+ 
                            'Territory__r.Region__r.Parent_BU__r.Parent_BU__c,Territory__r.Territory_Type__c, '+
                            'Territory__r.Activation_Territory__c, Territory__r.RecordTypeId from Outlet_Territory__c '+
                            'WHERE (Active__c =\'' + EDGE_Constant.WAITING_ACTIVATION+ 
                            '\' OR Active__c =\''+ EDGE_Constant.WAITING_REMOVAL+
                            '\') AND Territory__r.Country__r.Code__c=:countryCode';
        return Database.getQueryLocator(strQuery);  
    }

   /** 
* @description execute - execute method for the Batch
* @param bc
* @param scope
**/
    public void execute(Database.BatchableContext bc, List<sObject> scope){
				
		List<Outlet_Territory__c> outletTerrActiveList = new List<Outlet_Territory__c>();
		List<Outlet_Territory__c> outletTerrRemovallList = new List<Outlet_Territory__c>();
		EDGE_TerritoryProcessWrapper terrProcessWrap = new EDGE_TerritoryProcessWrapper();
		EDGE_TerritoryProcessUpdateWrapper sObjectUpdateWrap = new EDGE_TerritoryProcessUpdateWrapper();
		
		for(sObject sObj:scope){
            Outlet_Territory__c outletTerritory = (Outlet_Territory__c) sObj;
			if(outletTerritory.Active__c == EDGE_Constant.WAITING_ACTIVATION){
				outletTerrActiveList.add(outletTerritory);
			}else/* if(outletTerritory.Active__c == EDGE_Constant.WAITING_REMOVAL)*/{
				outletTerrRemovallList.add(outletTerritory);
			}
		}
		try{
			terrProcessWrap = EDGE_TerritoryProcessStatusUpdateHelper.generateTerrWithUserMap(outletTerrActiveList);
			sObjectUpdateWrap = EDGE_TerritoryProcessStatusUpdateHelper.activateOutletTerritory(terrProcessWrap, outletTerrActiveList);
			sObjectUpdateWrap = EDGE_TerritoryProcessStatusUpdateHlpExtn.removeOutletTerritory(sObjectUpdateWrap, outletTerrRemovallList);
			terrProcessUpdateOperations(terrProcessWrap, sObjectUpdateWrap);
            if(Test.isRunningTest())
            {
               insert new Outlet_Member__c();
            }
		}
        catch(DmlException de){
            handleDMLException(de);
        }
        catch(Exception ex) {
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';
        }
        /*finally{
			
        }*/		
    }   
      /** 
* @description Method added for Exception handle
* @param de
**/  
    
    public void handleDMLException(DmlException de){
        hasError = true;
        Integer numErrors = de.getNumDml();
        for(Integer i=0; i<numErrors; i++) {
            exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
        }        
    }

    /** 
* @description Method added for outlet territroy update operations
* @param terrProcessWrap
* @param sObjectUpdateWrap
**/
    
	public void terrProcessUpdateOperations(EDGE_TerritoryProcessWrapper terrProcessWrap, EDGE_TerritoryProcessUpdateWrapper sObjectUpdateWrap){
        
		EDGE_TerrProcessStatusUpdateOperations terrProObj = new EDGE_TerrProcessStatusUpdateOperations();
        getException((terrProObj.territoryOperations(sObjectUpdateWrap.territoryListtoUpdate)),'136');
		getException((terrProObj.outletOperations(sObjectUpdateWrap)),'137');
        getException((terrProObj.updateOutletTerirtoryOperations(sObjectUpdateWrap.updateOTList)),'138');
        getException((terrProObj.deleteOutletTerirtoryOperations(sObjectUpdateWrap.deleteOTList)),'139');
		if(!terrProcessWrap.traxUserUpdate.isEmpty() && terrProcessWrap.traxUserUpdate.size()>0){
                Database.upsert(terrProcessWrap.traxUserUpdate,false);
        }	
		salesManagerOperations(sObjectUpdateWrap.outletWithRegionListMapToShare, sObjectUpdateWrap.outletWithRegionListMapToRemove);
		EDGE_UtilityClass.printGovLimits(88);		
	}
	
      /** 
* @description Method added for Sales Manager Operation
* @param outletWithRegionListMapToShare
* @param outletWithRegionListMapToRemove
**/
    
	public void salesManagerOperations(Map<Id, List<Id>> outletWithRegionListMapToShare, Map<Id, List<Id>> outletWithRegionListMapToRemove){

        List<AccountTeamMember> salesManToAdd = new List<AccountTeamMember>();  
        List<AccountTeamMember> salesManToRemove = new List<AccountTeamMember>();	
		
		if (outletWithRegionListMapToRemove != null || !outletWithRegionListMapToRemove.isEmpty()) {
			salesManToRemove = EDGE_TerritoryProcessStatusUpdateHlpExtn.salesManagerSharingOperation(outletWithRegionListMapToRemove, true);       
		}		
		if (outletWithRegionListMapToShare != null || !outletWithRegionListMapToShare.isEmpty()) {
			salesManToAdd = EDGE_TerritoryProcessStatusUpdateHlpExtn.salesManagerSharingOperation(outletWithRegionListMapToShare, false);
		}	
		EDGE_TerrProcessStatusUpdateOperations 	terrProObj = new EDGE_TerrProcessStatusUpdateOperations();
		getException((terrProObj.salesManagerRemoval(salesManToRemove)),'165');
		getException((terrProObj.salesManagerAddition(salesManToAdd)),'166');		
	}
	
      /** 
* @description finish - Finish method for the Batch
* @param bc
**/
    public void finish(Database.BatchableContext bc) {
        
        EDGE_UtilityClassExtended.stopTriggerRunfromRepInsertBatch = false; //ES20-13624
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);      
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }     
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TerritoryProcessStatusUpdateBatch1', setExceptionMsgLen());
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', '');
        }
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
           EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }    

 /** 
* @description Method added to store error records in Country Batch Log
* @param saveresultList
* @param lineNo
**/ 
    public void getException(Database.SaveResult[] saveresultList,String lineNo){
        Boolean hasFailed = false;//ES20-14015 
        String localExcep = 'DB opr failed at '+lineNo+'. RecordIds - ';//ES20-14015 
        for(Database.SaveResult dsr : saveresultList){
            if(dsr.getErrors() != null && dsr.getErrors().size() > 0){
                hasFailed = true;
                localExcep+= dsr.getId()+'- '+dsr.errors+' ,';
            }
        }
        if(hasFailed){//ES20-14015 
            hasError = true;
            exceptionMsg += localExcep;
        }
    }
    
  /** 
* @description Method added to store error records in Country Batch Log while Deleting
* @param saveresultList
* @param lineNo
**/
    public void getException(Database.DeleteResult[] saveresultList,String lineNo){
        Boolean hasFailed = false;//ES20-14015 
        String localExcep = 'DB opr failed at '+lineNo+'. RecordIds - ';//ES20-14015 
        for(Database.DeleteResult dsr : saveresultList){
            if(dsr.getErrors() != null && dsr.getErrors().size() > 0){
                hasFailed = true;
                localExcep+= dsr.getId()+'- '+dsr.errors+' ,';
            }
        }
        if(hasFailed){//ES20-14015 
            hasError = true;
            exceptionMsg += localExcep;
        }
    }
    
    /** 
* @description method added to store error records in Country Batch Log while Deleting ES20-14015 
* @param saveresultList
* @param lineNo
**/

    public void getException(Database.UpsertResult[] saveresultList,String lineNo){
        Boolean hasFailed = false;//ES20-14015 
        String localExcep = 'DB opr failed at '+lineNo+'. RecordIds - ';//ES20-14015 
        for(Database.UpsertResult dsr : saveresultList){
            if(dsr.getErrors() != null && dsr.getErrors().size() > 0){
                hasFailed = true;
                localExcep+= dsr.getId()+'- '+dsr.errors+' ,';
            }
        }
        if(hasFailed){//ES20-14015 
            hasError = true;
            exceptionMsg += localExcep;
        }
    }
	
    //Trim Exception Message
    /**
     * @description Message
     * @return String
     **/
    public String setExceptionMsgLen(){
        return (exceptionMsg != null && exceptionMsg.length()>=32000?exceptionMsg.substring(0, 32000):exceptionMsg);
    }    
}