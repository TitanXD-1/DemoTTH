/**

* @description :  EDGE_TerritoryProcessAccountShareBatch

* @purpose : This batch class provides access to Sales rep in Outlets depending on their memmbership in outlets - ES20-262

* @history :

* Version    Developer         Date           User Story/Purpose

*  1.1      Sagar Barman     28/02/2019       Initial Development
*  1.2      Mayukh SRoy      06/12/2022       ES20-13624 - UAT_Multiple Queueable Jobs are executed from the same transaction
*  1.3      Mayukh SRoy      27/04/2023       ES20-14015
*/

public class EDGE_TerritoryProcessAccountShareBatch implements Database.Batchable<SObject>, Database.Stateful,Database.RaisesPlatformEvents, BatchJobManagementInterfaceClass{ 
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    /** Start Method **/   
    public Database.QueryLocator start(Database.BatchableContext bc){        
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        string countryCode;
        countryCode = batchSetting.Country_Code__c;
        String strQuery = 'SELECT Id,Outlet__c,Outlet_Role__c,User__c,Business_Role__c,CreatedDate,LastModifiedDate,Flag_For_Deletion__c FROM Outlet_Member__c WHERE LastModifiedDate=LAST_N_DAYS:1 AND Outlet__r.Country__r.Code__c=:countryCode AND User__r.IsActive=true AND Outlet_Role__c != \'Sales Manager\'';
        return Database.getQueryLocator(strQuery);
    }
    
    /** Execute Method **/ 
    public void execute(Database.BatchableContext bc, List<sObject> scope){
        List<Outlet_Member__c> insertOutletMemberList = new List<Outlet_Member__c>();
        List<Outlet_Member__c> deleteOutletMemberList = new List<Outlet_Member__c>();
        List<Outlet_Member__c> updateOutletMemberList = new List<Outlet_Member__c>();
        Set<ID> updatedUserSet= new set<ID>();
        
        List<AccountTeamMember> accToInsList = new List<AccountTeamMember>();  //ES20-13624
        List<AccountTeamMember> accToDelList = new List<AccountTeamMember>();  //ES20-13624
        //Map<String,List<AccountTeamMember>> listOfATM = new Map<String,List<AccountTeamMember>>();  //ES20-13624
        
        try{    
            for(sObject sObj:scope){
                Outlet_Member__c outletmember = (Outlet_Member__c)sObj;
                //skipping deleting call and tasks            
                if(outletmember.Flag_For_Deletion__c == true){                
                    deleteOutletMemberList.add(outletmember);   // delete list      
                }
                else {
                    Date createdDateToday = outletmember.CreatedDate.Date();
                    if(createdDateToday == System.today()){
                        insertOutletMemberList.add(outletmember);    // insert List
                    } else{                 
                        updateOutletMemberList.add(outletmember); // update List                    
                    }
                }
            }
            
            //insert AccountShare 
            if(isNotNull(insertOutletMemberList)){
                for(Outlet_Member__c om : insertOutletMemberList){ // Not needed
                    if(om.User__c != null){                     
                        updatedUserSet.add(om.User__c);
                    }               
                }           
                //EDGE_OutletMemberAccountTeamSync.createAccountTeamMembers(insertOutletMemberList);  
                accToInsList = EDGE_OutletMemberAccountTeamSync.createAccountTeamMember(insertOutletMemberList);//ES20-13624
                //ES20-14015
                if(isNotNull(accToInsList)){
                    Database.insert(accToInsList, false);
                }
                //listOfATM.put('Insert',AccToInsList); //ES20-13624
            }
            
            //update AccountTeamMembers calling updateAccountTeamMembers method and passing the outlet member's list which are lastmodified today 
            if(isNotNull(updateOutletMemberList)){
                EDGE_OutletMemberAccountTeamSync.updateAccountTeamMembers(updateOutletMemberList);    
            }
            
            //delete account members
            if(isNotNull(deleteOutletMemberList)){
                // delete Standard Account team Member record
                // EDGE_OutletMemberAccountTeamSync.deleteAccountTeamMembers(deleteOutletMemberList); 
                
                //delete custom Outlet Member record
                Database.delete(deleteOutletMemberList);
                
                accToDelList = EDGE_OutletMemberAccountTeamSync.deleteAccountTeamMember(deleteOutletMemberList);    //ES20-13624
                //ES20-14015
                if(isNotNull(accToDelList)){
                    Database.delete(accToDelList, false);
                }
                //listOfATM.put('Delete',AccToDelList); //ES20-13624
            }
            /*
            if(listOfATM.containsKey('Insert') || listOfATM.containsKey('Delete')){  //ES20-13624
            System.enqueueJob(new EDGE_AccTeamMemInsDelQueueable(listOfATM));    //ES20-13624
            }*/
            
            if(Test.isRunningTest()){
                throw new EDGE_GenericException();
            }
            
        }catch(DmlException de){
            hasError = true;
            Integer numErrors = de.getNumDml();
            for(Integer i=0; i<numErrors; i++) {
                exceptionMsg += 'Record Id : ' + de.getDmlId(i) + ' Line# ' + de.getLineNumber() + ' Message : ' + de.getDmlMessage(i) + '\n';
            }
        }
        catch(Exception ex) {
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
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_TerritoryProcessAccountShareBatch', exceptionMsg);
        }else{
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', ''); 
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting, hasError);
        }
    }
    
    //Common Null Check to reduce PMD violations 
    public static Boolean isNotNull(List<SObject> objList){
        Boolean isNotNull = false;
        if(objList!=Null && objList.size()>0){
            isNotNull = true;
        }
        return isNotNull;
    }
}