/************************
* Class Name : EDGE_UserStoreAssignmentToTraxBatch
* Description : it'll send the Outlet assigned to users to TRAX end     

History                                                            
-------------------------------------------------------------------------------                                                            
VERSION     AUTHOR                  DATE              DETAIL
1.0         Srutadeba Chanda    06/04/2019        Initial Development - send User Store Assignment to 
Trax(ES20-1582,ES20-162)
2.0			Kapil Baliyan	    30/12/2019	  Updated Error Handling to implement Database.RaisesPlatformEvents (ES20-6594)
3.0			Aparajita			15/03/2021	  Updated inactive user deletion from TRAX(ES20-9820)
***********************************************************************/
public class  EDGE_UserStoreAssignmentToTraxBatch implements Database.Batchable<SObject>, Database.Stateful, Database.RaisesPlatformEvents,Database.AllowsCallouts, BatchJobManagementInterfaceClass{
    Market_Batch_Setting__mdt batchSetting;
    boolean hasError = false ;
    string exceptionMsg = '';
    string responseMsg = '';
    Id marketBatchJobId; //Update ES20-6594
    
    //Interface Class Method
    public void getBatchDetails(Market_Batch_Setting__mdt batchSetting){
        this.batchSetting = batchSetting;
    }
    
    //Start Method
    public Database.QueryLocator start(Database.BatchableContext bC){
        //Upsert Market Batch Job Data
        marketBatchJobId = EDGE_BatchUtilityClass.upsertMarketBatchJob(batchSetting, bc.getJobId()); //Update ES20-6594
        
        string countryCode = batchSetting.Country_Code__c;
        set<Id> userIdSet= new set<Id>();
        for(Trax_User_Update__c userSetting :[select name,country_code__c from Trax_User_Update__c where country_code__c=:countryCode ]){
            userIdSet.add(userSetting.name);
        }
        
        string queryString ='SELECT Id,isActive,firstName,lastName,mobilePhone, email,createddate,Trax_User__c FROM User WHERE id in :userIdSet';
        return Database.getQueryLocator(queryString);   
    }
    
    //Execute Method
    public void execute(Database.BatchableContext bC,  List<User> scope){
        try{
            
            Map<Id,set<Id>> userOutletMemberMap =new Map<Id,set<Id>>();
            Set<Id> userIdSet = new Set<Id>();
            List<User> inactiveUserList = new List<User>();
            List<User> finalUserList = new List<User>(); 
            for(User uObj : scope){
                userIdSet.add(uobj.id);
                if(!uObj.isActive){//change for ES20-9820 
                    inactiveUserList.add(uObj);
                }
            }
            System.debug('scope' +scope);
            System.debug('inactiveUserList' +inactiveUserList);
            for(Outlet_Member__c outletMember: [SELECT Id, Outlet__c, User__c,user__r.Trax_User__c FROM Outlet_Member__c WHERE 
                                                Outlet__r.Status__c= 'Active' and User__c IN:userIdSet and Outlet__r.Send_To_Trax__c=true])
            {
                
                If(UserOutletMemberMap.ContainsKey(outletMember.User__c)){
                    UserOutletMemberMap.get(outletMember.User__c).add(outletMember.outlet__c);
                }else{
                    UserOutletMemberMap.put(outletMember.User__c, new set<Id> { outletMember.outlet__c} );
                }   
            }
            System.debug('@@UserOutletMemberMap' +UserOutletMemberMap);
            if(!UserOutletMemberMap.isEmpty()){
                EDGE_SendUserDetailsToTrax traxExtension= new EDGE_SendUserDetailsToTrax();
                responseMsg +=traxExtension.sendUserStoreAssignment(scope, UserOutletMemberMap,batchSetting.Country_Code__c );
            }
            
            if(!inactiveUserList.isEmpty())    //change for ES20-9820
            {
                for(User userRec : inactiveUserList)
                {
                    if(!UserOutletMemberMap.containsKey(userRec.Id))
                        finalUserList.add(userRec); 
                }
                
                EDGE_SendUserDetailsToTrax traxExtension= new EDGE_SendUserDetailsToTrax();
                responseMsg +=traxExtension.sendUserStoreAssignment(finalUserList, null,batchSetting.Country_Code__c );
            }
            
        }catch(Exception ex){
            system.debug('@@Exception' + ex.getMessage());
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';    
        }
    }
    
    //Update ES20-6594
    public void finish(Database.BatchableContext bC){
        //Get Batch Job
        Country_Batch_Job_Log__c batchJobLog = EDGE_BatchUtilityClass.getBatchJob(batchSetting, marketBatchJobId);
        
        //Check whether Batch Job has been updated by Batch Platform Event or Not
        if(!hasError && batchJobLog.Is_Updated_By_Platform_Event__c && batchJobLog.Status__c == 'Failed'){
            hasError = true;
        }
        
        try{
            if(!hasError){
                List<Trax_User_Update__c > userListtoDelete=new  List<Trax_User_Update__c >();
                UserListtoDelete = [select Id from Trax_User_Update__c  where country_code__c=:batchSetting.Country_Code__c];
                if(UserListtoDelete.size()>0 && !UserListtoDelete.isEmpty()){
                    delete UserListtoDelete;
                }
            }
        }
        catch(Exception ex){
            hasError = true;
            exceptionMsg += 'Line# ' + ex.getLineNumber() + ' Message : ' + ex.getMessage() + '\n';   
        }
        
        //Update Batch Job Status
        if(hasError){
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Failed', 'EDGE_UserStoreAssignmentToTraxBatch', exceptionMsg);
        }else{    
            EDGE_BatchUtilityClass.updateBatchJobStatus(batchSetting, marketBatchJobId, batchJobLog, 'Successful', '', responseMsg );
        }
        
        //Schedule Next Batch from Batch Utility Class
        if(!Test.isRunningTest()){
            EDGE_BatchUtilityClass.scheduleNextBatch(batchSetting,hasError);
        }
    }
}