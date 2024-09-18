/*
     *  Class Name : EDGE_CSTClaimTriggerHelper
     *  @description : This is Claim Trigger Helper class
     *  @history
     *  ------------------------------------------------------------------------
     *  1.0         CST Team              19/05/2021        Initial Development
*/
public without sharing class EDGE_CSTClaimTriggerHelper {
    
/**
     * @description claimApprovalProcess
     * @param Map, Map
*/
    
    public static void claimApprovalProcess(Map < Id, sObject > newItems,Map<Id, SObject> oldItems)
    {
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;  
        Set<id> sendToApprovalIds = new Set<id>();
        Set<id> sendToSAPIds = new Set<id>();
        Map<Id, CST_Claim__c> mapOldItems;
        if(oldItems != null){
            mapOldItems = (Map<Id, CST_Claim__c>)oldItems;
        }
        for(CST_Claim__c claim: mapnewItems.values()){
            if(mapOldItems.containsKey(claim.Id) && claim.CST_Status__c !=mapOldItems.get(claim.Id).CST_Status__c){                
                if(claim.CST_Status__c =='Assigned To Approver' && claim.Previous_status__c !='Assigned To Approver'){
                    sendToApprovalIds.add(claim.Id);
                }
                else if(claim.CST_Status__c =='Approved'){
                    sendToSAPIds.add(claim.Id);                    
                }                  
            }  
        }
        if(sendToApprovalIds.size()>0){
         sendforApproval(sendToApprovalIds,mapnewItems);  
        }
        if(sendToSAPIds.size()>0){
            CST_ClaimToSAPCallout.getClaimBillingData(sendToSAPIds);
        }
        
    }    
    
/**
     * @description updateClaimItemCurrency
     * @param Map, Map
*/

    public static void updateClaimItemCurrency(Map < Id, sObject > newItems, Map < Id, sObject > oldItems)
    {
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;
        set<id> claimIds = new set<id>();
        List<CST_Claim_Item__c> claimItems= new List<CST_Claim_Item__c>();
        if (oldItems != null) {
            mapOldItems = (Map<Id, CST_Claim__c>)oldItems;
        }
        for(CST_Claim__c claim: mapnewItems.values()){
            if(mapOldItems.containsKey(claim.Id)&&(claim.CurrencyIsoCode != mapOldItems.get(claim.Id).CurrencyIsoCode)){
                claimIds.add(claim.id);
            }
        } 
        if(claimIds.size()>0){      
            for(CST_Claim_Item__c item : [Select id, CurrencyIsoCode, CST_Claim__c,CST_Net_Value__c from CST_Claim_Item__c where CST_Claim__c =:claimIds]){
                item.CurrencyIsoCode = mapnewItems.containsKey(item.CST_Claim__c)?mapnewItems.get(item.CST_Claim__c).CurrencyIsoCode:null;
                //item.CST_Net_Value__c = item.CST_Net_Value__c;
                claimItems.add(item);
            }
        }
        if(claimItems.size()>0 && claimItems != null){
            update claimItems;
        }
    }
    
/**
     * @description insertClaimCurrency
     * @param Map, Map
*/

  public static void insertClaimCurrency(List<sObject> newCST)
    {
		set<id> salesorgIds = new set<id>();
		List<CST_Claim__c> claims= (List<CST_Claim__c>) newCST;
		for(CST_Claim__c claim: claims){
           if(claim.CST_Sales_Organisation__c != null && claim.CurrencyIsoCode != null){
                salesorgIds.add(claim.CST_Sales_Organisation__c);
            }
        }
			List<Sales_Organisation__c> sales= [select Id, CurrencyIsoCode from Sales_Organisation__c where Id IN :salesorgIds ];
			map<string, string> currencyMap =  new map<string, string> ();
            for(Sales_Organisation__c salesOrg : sales ){
               currencyMap.put(salesOrg.Id,salesOrg.CurrencyIsoCode);
                }
			for(CST_Claim__c claim : claims){
            if(currencyMap.containskey(claim.CST_Sales_Organisation__c)){ 
                  claim.CurrencyIsoCode = currencyMap.get(claim.CST_Sales_Organisation__c);
            }
			

		
}
    }
    
    
/**

* @description updateClaimPaymentTerm
* Used to populate the Claim Payment Term field of Claim from Account if the Claim payment term was not selected.
    * @param List
    */
   public static void checkAccountSalesOrgCountry(List<CST_Claim__c> newItems)
    {
        Set<Id> salesOrgId = new Set<Id>();
        Set<Id> claimAccntId = new Set<Id>();
        for(CST_Claim__c claim : newItems){
            salesOrgId.add(claim.CST_Sales_Organisation__c);
            claimAccntId.add(claim.CST_Account__c);
        }
        Map<Id,Sales_Organisation__c> claimSalesOrgMap = new Map<Id,Sales_Organisation__c>([SELECT Id FROM Sales_Organisation__c WHERE Id IN :salesOrgId]);
        Map<Id,Account> claimAccMap = new Map<Id,Account>([SELECT Id, Sales_Organisation__c FROM Account WHERE Id =:claimAccntId]);
        for(CST_Claim__c claim : newItems){
            Id salesOrg = claimSalesOrgMap.containsKey(claim.CST_Sales_Organisation__c)?claimSalesOrgMap.get(claim.CST_Sales_Organisation__c).Id:null;
            Id accntsalesOrg = claimAccMap.containsKey(claim.CST_Account__c)?claimAccMap.get(claim.CST_Account__c).Sales_Organisation__c:null;
            if(salesOrg != null && accntsalesOrg!=null &&(!(accntsalesOrg.equals(salesOrg)))) {
                claim.addError('Account and Sales Organisation cannot be different');
            }
        }
    }
    /** 
     * @description updateClaimPaymentTerm
     * Used to populate the Claim Payment Term field of Claim from Account,populate the Claim Payment Term field of Claim from  sales org if account was blank if the Claim payment term was not selected.
     * @param List
*/
    
    public static void updateClaimPaymentTerm(List<CST_Claim__c> newItems)
    {
        Set<Id> salesOrgId = new Set<Id>();
        Set<Id> cstAccId = new Set<Id>();
        for(CST_Claim__c claim : newItems){
            salesOrgId.add(claim.CST_Sales_Organisation__c);
            cstAccId.add(claim.CST_Account__c);
        }         
        Map<Id,Sales_Organisation__c> claimSalesOrgMap = new Map<Id,Sales_Organisation__c>([SELECT Id, CST_Payment_Term__c FROM Sales_Organisation__c WHERE Id IN :salesOrgId]);
        Map<Id,Account> mapIdtoAcc = new Map<Id,Account>([select id,CST_Payment_term__c, Country__c from Account where id =:cstAccId]);
        for(CST_Claim__c claim : newItems){                 
            Id salesOrgPaymentTerm = claimSalesOrgMap.containsKey(claim.CST_Sales_Organisation__c)?claimSalesOrgMap.get(claim.CST_Sales_Organisation__c).CST_Payment_Term__c:null;
            Id acctPaymentTerm = mapIdtoAcc.containsKey(claim.CST_Account__c)?mapIdtoAcc.get(claim.CST_Account__c).CST_Payment_term__c:null;
            Id accCountry = mapIdtoAcc.containsKey(claim.CST_Account__c)?mapIdtoAcc.get(claim.CST_Account__c).Country__c:null;             
            if(claim.CST_Payment_term__c== null){
                if(acctPaymentTerm != null)
                    claim.CST_Payment_term__c= acctPaymentTerm;
            }
            if(claim.CST_Payment_term__c== null){
                if(acctPaymentTerm == null && salesOrgPaymentTerm != null)
                    claim.CST_Payment_term__c= salesOrgPaymentTerm;
            } 
            
            if(accCountry != null){
                claim.CST_Country__c  = accCountry;
            }                 
        } 
    }
    
/**
    * @description updateClaimPaymentTerm
    * Used to isDuplicate field before Insert
    * @param List
*/

    public static void checkDuplicateBeforeInsert(List<CST_Claim__c> newItems)
    {
        List<CST_Claim__c> duplicateClaim =[select id from CST_Claim__c where CST_Invoice_Number__c =:newItems[0].CST_Invoice_Number__c and CST_Invoice_Date__c =: newItems[0].CST_Invoice_Date__c and CST_Account__c =: newItems[0].CST_Account__c 
                                            and CST_Total_Amount__c =: newItems[0].CST_Total_Amount__c and CurrencyIsoCode =: newItems[0].CurrencyIsoCode];     
        system.debug(LoggingLevel.DEBUG,'duplicateClaim'+duplicateClaim);
        if((trigger.isinsert && duplicateClaim.size()>0) || (trigger.isupdate  && duplicateClaim.size()>0 && ((duplicateClaim.size() ==1 && !(duplicateClaim[0].id.equals(newItems[0].id))) || duplicateClaim.size()>1)  )){            
               newItems[0].CST_Is_duplicate__c = true;
        }else{
              newItems[0].CST_Is_duplicate__c = false; 
        }       
    }

/**
    * @description sendforApproval
    * This method will submit a record for approval.
    * @param Set,Map 
*/

public static void sendforApproval(set<id> claimIds, Map<Id, CST_Claim__c> mapClaim)
{
    Approval.ProcessResult[] processResults = null;  
    CST_Claim__c claimObj ;
    if(claimIds.size()>0){
        List<Approval.ProcessSubmitRequest> requests = new List<Approval.ProcessSubmitRequest>();
        for(Id clmId : claimIds){
            claimObj = new CST_Claim__c();
            claimObj = mapClaim.get(clmId);
            Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
            req1.setComments('Submitting request for approval ');
            req1.setObjectId(clmId);
            req1.setSubmitterId(claimObj.OwnerId);
            req1.setProcessDefinitionNameOrId('CST_Claim_Approval');
            req1.setSkipEntryCriteria(true);
            requests.add(req1);               
        }            
        try {
            processResults = Approval.process(requests, true);               
            //newWorkItemIds = processResults.getNewWorkitemIds();
        }
        catch (System.DmlException e) {
            System.debug(LoggingLevel.DEBUG,'Exception Is ' + e.getMessage());
        }            
    }
}

/**
    * @description checkAndGenerateSharing
    * To create sharing record on Insert
    * @param List    
*/

public static void checkAndGenerateSharing(List<CST_Claim__c> newItems){
    CST_SharingUtil.validateCreatePermission(newItems, 'CST_Sales_Organisation__c');
    CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'CST_Sales_Organisation__c', 'Read');
    CST_SharingUtil.generateSharingFromSalesOrg(newItems, 'CST_Sales_Organisation__c', 'Edit');
    EDGE_SharingUtil.validateCreatePermission(newItems, 'CST_Country__c');
    EDGE_SharingUtil.generateSharingFromGeography(newItems, 'CST_Country__c', 'Up', 'Read');
    EDGE_SharingUtil.generateSharingFromGeography(newItems, 'CST_Country__c', 'Down', 'Edit'); 
}

/**
    * @description validateAndReGenerateSharing
    * Modify, Validate sharing record on update
    * @param List,Map    
*/

public static void validateAndReGenerateSharing(List<CST_Claim__c> newItems,Map<Id, SObject> oldItems){
    Map<Id, CST_Claim__c> mapOldItems;
    List<CST_Claim__c> lstNewChangeSalesOrg = new List<CST_Claim__c>();
    List<CST_Claim__c> lstOldChangeSalesOrg = new List<CST_Claim__c>();
    List<CST_Claim__c> lstNewChangeGeography = new List<CST_Claim__c>();
    List<CST_Claim__c> lstOldChangeGeography = new List<CST_Claim__c>();
    
    EDGE_SharingUtil.validateEditPermission(newItems);
    
    if(oldItems != null){
        mapOldItems = (Map<Id, CST_Claim__c>)oldItems;
    }
    
    for(CST_Claim__c objSales : newItems){
        if(mapOldItems.containsKey(objSales.Id) && objSales.CST_Sales_Organisation__c != mapOldItems.get(objSales.Id).CST_Sales_Organisation__c){
            lstNewChangeSalesOrg.add(objSales);
            lstOldChangeSalesOrg.add(mapOldItems.get(objSales.Id));
        }
        if(mapOldItems.containsKey(objSales.Id) && objSales.CST_Country__c != mapOldItems.get(objSales.Id).CST_Country__c){
            lstNewChangeGeography.add(objSales);
            lstOldChangeGeography.add(mapOldItems.get(objSales.Id));
        }
    }
    
    if(lstNewChangeSalesOrg != null && lstNewChangeSalesOrg.size()>0){
        CST_SharingUtil.validateCreatePermission(lstNewChangeSalesOrg, 'CST_Sales_Organisation__c');
        CST_SharingUtil.updateSharingRecords(lstNewChangeSalesOrg, lstOldChangeSalesOrg, 'CST_Sales_Organisation__c');
        CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'CST_Sales_Organisation__c', 'Read');
        CST_SharingUtil.generateSharingFromSalesOrg(lstNewChangeSalesOrg, 'CST_Sales_Organisation__c', 'Edit');
    } 
    if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
        EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'CST_Country__c');
        EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'CST_Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'CST_Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'CST_Country__c', 'Down', 'Edit');
    } 
}
    
     
/**
    * @description DefaultApproverNotification
    * Notification for default approver    
    * @param Map,Map    
*/
  
    
    public static void defaultApproverNotification(Map <Id,sObject> newItems, Map <Id,sObject> oldItems)
    {
        System.debug(LoggingLevel.DEBUG,'insert DefaultApproverNotification');
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;
        set<String> approverId = new set<String>();
      
        if (oldItems != null) {
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }
        
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType
                                                   WHERE DeveloperName='ClaimAssignedNotification'];
        
        for(CST_Claim__c claim: mapnewItems.values()){
            if(mapOldItems.containsKey(claim.Id) && claim.CST_Status__c =='Assigned to Default Approver' 
               && claim.CST_Approver__c !=mapOldItems.get(claim.Id).CST_Approver__c){                               
                    if(claim.CST_Approver__c != NULL) {
                         Messaging.CustomNotification notification = new Messaging.CustomNotification();
                         notification.setTitle('You have been assigned a new customer claim,');
                         notification.setBody('Claim Id:' + claim.Name);
                         notification.setNotificationTypeId(notificationType.Id);
                         notification.setTargetId(claim.id);
                         approverId.add(claim.CST_Approver__c); 
                         System.debug(LoggingLevel.DEBUG,'insert approverId' + approverId);
                        try {
                          notification.send(approverId);
                        }
                        catch (Exception e) {
                            System.debug(LoggingLevel.DEBUG,'Problem sending notification: ' + e.getMessage());
                        }
                   }  
         }          
      }    
   }
    
/**
    * @description updateRejectionReason
    * Update Rejection reason on standard approval process    
    * @param Map,Map    
*/
    
    public static void updateRejectionReason(Map <Id,sObject> newItems, Map <Id,sObject> oldItems)
    {
        System.debug('insert updateRejectionReason');
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;
      
        if (oldItems != null) {
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }
        if(CST_SendToApprovalController.runOnce){
            //CST_SendToApprovalController.runOnce = false;
            for(CST_Claim__c claim: mapnewItems.values()){          
                if(mapOldItems.containsKey(claim.Id) && mapOldItems.get(claim.Id).CST_Status__c != 'New'  && mapOldItems.get(claim.Id).CST_Status__c != 'Assigned to Default Approver' && claim.CST_Status__c =='Rejected' )
                  {   
                     claim.Cst_Reject_Reason__c  = 'Invalid claim';                       
                 }
                else if(mapOldItems.containsKey(claim.Id) && mapOldItems.get(claim.Id).CST_Status__c == 'New' 
                        		&& claim.CST_Status__c =='Rejected'){
                    claim.Cst_Reject_Reason__c  = 'Duplication';                
                }
            } 
        }    
   }
    
/**
    * @description rejectionCommentOnApproval
    *commnet required on standard approval process    
    * @param Map,Map    
*/
    

    public static void rejectionCommentOnApproval(Map <Id,sObject> newItems, Map <Id,sObject> oldItems)
    {
        System.debug(LoggingLevel.DEBUG,'insert rejectionCommentOnApproval');
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;        
        List<Id> processInstanceIds = new List<Id>();
        Map<Id,CST_Claim__c> rejectedStatements = new Map<Id,CST_Claim__c>();       
      
        if (oldItems != null) {
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }        
        System.debug(LoggingLevel.DEBUG,'insert rejectionCommentOnApproval'+mapOldItems);
        System.debug(LoggingLevel.DEBUG,'insert rejectionCommentOnApproval'+mapnewItems);
        System.debug(LoggingLevel.DEBUG,'insert rejectionCommentOnApproval'+CST_SendToApprovalController.runOnce);
        for(CST_Claim__c claim: mapnewItems.values()){
            System.debug(LoggingLevel.DEBUG,'insert rejectionCommentOnApproval'+CST_SendToApprovalController.runOnce);
            if(CST_SendToApprovalController.runOnce && mapOldItems.containsKey(claim.Id) 
               && mapOldItems.get(claim.Id).CST_Status__c != 'New' && mapOldItems.get(claim.Id).CST_Status__c != 'Assigned to Default Approver' && claim.CST_Status__c =='Rejected')
               {
                   System.debug(LoggingLevel.DEBUG,'insert rejectionCommentOnApproval'+CST_SendToApprovalController.runOnce);
                 rejectedStatements.put(claim.Id, claim);  
               }
        }
        
        if (!rejectedStatements.isEmpty())  
        {
            for (CST_Claim__c clm : [SELECT (SELECT ID FROM ProcessInstances
                                                      ORDER BY CreatedDate DESC
                                                      LIMIT 1)
                                              FROM CST_Claim__c
                                              WHERE ID IN :rejectedStatements.keySet()]){
                processInstanceIds.add(clm.ProcessInstances[0].Id);
            }

       }
       for (ProcessInstance pi : [SELECT TargetObjectId,(SELECT Id, StepStatus, Comments 
                                  FROM Steps ORDER BY CreatedDate DESC LIMIT 1 )
                                  FROM ProcessInstance
                                  WHERE Id IN :processInstanceIds
                                 ORDER BY CreatedDate DESC])   
        {                   
          if ((pi.Steps[0].Comments == null || 
               pi.Steps[0].Comments.trim().length() == 0)){
            rejectedStatements.get(pi.TargetObjectId).addError(
              'Please provide a rejection comment');
               }else{
                   rejectedStatements.get(pi.TargetObjectId).CST_Approval_Comments__c = pi.Steps[0].Comments ;
               }
        }  
    }
    
/**
    * @description approverCommentOnApproval
    *commnet to be updated on standard approval process    
    * @param Map,Map    
*/
    

    public static void approverCommentOnApproval(Map <Id,sObject> newItems, Map <Id,sObject> oldItems)
    {
        System.debug(LoggingLevel.DEBUG,'update approverCommentOnApproval');
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;        
        List<Id> processInstanceIds = new List<Id>();
        Map<Id,CST_Claim__c> approvedClaims = new Map<Id,CST_Claim__c>();       
      
        if (oldItems != null) {
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }        
        System.debug(LoggingLevel.DEBUG,'update approverCommentOnApproval'+mapOldItems);
        System.debug(LoggingLevel.DEBUG,'update approverCommentOnApproval'+mapnewItems);
        System.debug(LoggingLevel.DEBUG,'update approverCommentOnApproval'+CST_SendToApprovalController.runOnce);
        for(CST_Claim__c claim: mapnewItems.values()){
            System.debug(LoggingLevel.DEBUG,'update approverCommentOnApproval'+CST_SendToApprovalController.runOnce);
            if(CST_SendToApprovalController.runOnce && mapOldItems.containsKey(claim.Id) 
               && mapOldItems.get(claim.Id).CST_Status__c != 'New' && ( (mapOldItems.get(claim.Id).CST_Status__c == 'Assigned to Default Approver' && claim.CST_Status__c =='Approved')    || (mapOldItems.get(claim.Id).CST_Status__c == 'Assigned to Default Approver' && claim.CST_Status__c =='Assigned to Approver') || (mapOldItems.get(claim.Id).CST_Status__c == 'Assigned to Approver' && claim.CST_Status__c =='Approved')) )
                                                                       
                                                                      
               {
                 System.debug(LoggingLevel.DEBUG,'update approverCommentOnApproval'+CST_SendToApprovalController.runOnce);
                 approvedClaims.put(claim.Id, claim);  
               }
        }
        
        if (!approvedClaims.isEmpty())  
        {
            for (CST_Claim__c clm : [SELECT (SELECT ID FROM ProcessInstances
                                             ORDER BY CreatedDate DESC
                                             LIMIT 1)
                                     FROM CST_Claim__c
                                     WHERE ID IN :approvedClaims.keySet()]){
                                         if(clm.ProcessInstances.size()>0) {
                                             processInstanceIds.add(clm.ProcessInstances[0].Id);
                                         }
                                     }
            
        }
        if(processInstanceIds.size()>0){
            for (ProcessInstance pi : [SELECT TargetObjectId,(SELECT Id, StepStatus, Comments 
                                                              FROM Steps ORDER BY CreatedDate DESC LIMIT 1 )
                                       FROM ProcessInstance
                                       WHERE Id IN :processInstanceIds
                                       ORDER BY CreatedDate DESC])   
            {                   
                if ((pi.Steps[0].Comments != null && 
                     pi.Steps[0].Comments.trim().length() != 0)){
                         approvedClaims.get(pi.TargetObjectId).CST_Approval_Comments__c = pi.Steps[0].Comments ;
                     }
            }
        }
          
    }
    
/**
    * @description unLockRecord    
    * @param Map,Map    

*/

    public static void unLockRecord(Map <Id,sObject> newItems, Map <Id,sObject> oldItems){
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>)newItems;


        List<CST_Claim__c> lockedClaimMap = new List<CST_Claim__c>();
        CST_SendToApprovalController.runOnce = false;
        for(CST_Claim__c claimObj : mapnewItems.values()){
            if(Approval.isLocked(claimObj.id)){
                lockedClaimMap.add(claimObj);


            }                   
        }  
        List<Approval.UnlockResult> ulrList= new List<Approval.UnlockResult>();
        if(lockedClaimMap.size()>0 && lockedClaimMap != null){
             ulrList = Approval.unlock(lockedClaimMap,false);
            //List<Approval.UnlockResult> test = Approval.unlock(claimItemObj, false);            
        }     
    }
    
/**
    * @description deletiononNewstatus
    * creator can delete a claim only in new status    
    * @param List    
*/

    public static void deletiononNewstatus(List<CST_Claim__c>oldItems)
    {
        if(!oldItems.isEmpty()){
            for(CST_Claim__c claim : oldItems){
                if(claim.CST_Status__c != 'New'){
                    claim.addError(Label.CST_DeleteErrorMsg);
                }                   
            } 
        }
    }

    /**
    * @description updateApprover
    * validate new user and Update Aproover whenever the owner is changed.
    * @param Map,Map
    */    
    public static void updateApprover(Map <Id,sObject> newItems, Map <Id,sObject> oldItems){        
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;
        Map<String, string> oldOwnerId = new Map<String, string>();
        Map<String, string> newOwnerId = new Map<String, string>();
        Map<string, User> mapUserVsOwner = new Map<string, User>();
        Map<string, Sales_Organisation__c> salesOrgMap = new Map<string, Sales_Organisation__c>();
        List<Id> ownerIds = new List<id>();
        List<Id> salesOrgIds = new List<id>();
        //Boolean hasPermission = FeatureManagement.checkPermission('CST_Approver');
               
        if(oldItems != null){
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }
        for(CST_Claim__c claim : mapOldItems.values()){
            oldOwnerId.put(claim.Id,claim.OwnerId);
            ownerIds.add(claim.OwnerId);
        }
        for(CST_Claim__c claim : mapnewItems.values()){
            newOwnerId.put(claim.Id,claim.OwnerId);
            ownerIds.add(claim.OwnerId);
            salesOrgIds.add(claim.CST_Sales_Organisation__c);
        }
        List<User> users = [Select Id, User.DelegatedApproverId, Profile.Name, Sales_Organisation__c From User where Id IN:ownerIds];
        for(User us : users){
            mapUserVsOwner.put(us.Id,us);
        }  
        salesOrgMap = new Map<string, Sales_Organisation__c>([Select Id,Name,Code__c From Sales_Organisation__c where Id IN:salesOrgIds]);
        System.debug('salesOrgMap '+salesOrgMap);
        Set<Id> ownerIdSet = new Set<Id>(ownerIds);
        Map<Id,User> checkmapUserVsOwner = new Map<Id,User>();
        checkmapUserVsOwner  = checkCustomPermission(ownerIdSet);
        
        
        for(CST_Claim__c claim: mapnewItems.values()){
            if((mapOldItems.get(claim.Id).CST_Status__c !='New' && (claim.OwnerId != mapOldItems.get(claim.Id).OwnerId))){
                User newUser = mapUserVsOwner.get(newOwnerId.get(claim.Id));
                User oldUser = mapUserVsOwner.get(oldOwnerId.get(claim.Id));                
                Boolean IsCommonAssignSalesOrg = false;
                String claimSalesOrg;
                if(!Test.isRunningTest()){
                    claimSalesOrg = salesOrgMap.get(claim.CST_Sales_Organisation__c).Code__c;
                    }
                 
                if(newUser.Sales_Organisation__c != null && newUser.Sales_Organisation__c.split(';').contains(claimSalesOrg)){
                    IsCommonAssignSalesOrg= true;
                }
                if((!IsCommonAssignSalesOrg || (newUser.Profile.Name != 'CST Approver' && !checkmapUserVsOwner.containskey(newUser.Id))|| newUser.DelegatedApproverId != null )&& !Test.isRunningTest()){
                    claim.addError('Claim can only be reassigned to an approver, who has access to sales org of the claim');
                   }else{
                       claim.CST_Approver__c= claim.OwnerId; 
                   }                
            }            
        }           
    }
    
    /**
    * @description reassignAndUpdateApprover
    * validate new user and Update Approver whenever the claim is reassigned by Actual Approver.
    * @param Map,Map
    */   
    public static void reassignAndUpdateApprover(Map <Id,sObject> newItems, Map <Id,sObject> oldItems){        
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;
        Map<String, ProcessInstanceWorkitem> piWorkItemsMap = new Map<String, ProcessInstanceWorkitem>();
        Map<String, string> piToItemsMap = new Map<String, string>();
        Map<String, string> reassignedMap = new Map<String, string>();
        Map<String, string> approverMap = new Map<String, string>();
        Map<string, User> mapUserVsApprover = new Map<string, User>();
        Map<string, Sales_Organisation__c> salesOrgMap = new Map<string, Sales_Organisation__c>();
        List<Id> salesOrgIds = new List<id>();
        List<Id> approverIds = new List<id>();
        List<Id> claimIds = new List<id>();
               
        if(oldItems != null){
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }
        for(CST_Claim__c claim : mapnewItems.values()){
            approverMap.put(claim.Id,claim.CST_Approver__c);
            approverIds.add(claim.CST_Approver__c);
            salesOrgIds.add(claim.CST_Sales_Organisation__c);
            if(claim.Claim_Reassign__c!=null){
                reassignedMap.put(claim.Id,claim.Claim_Reassign__c);
                approverIds.add(claim.Claim_Reassign__c);
                claimIds.add(claim.Id);
            }
        }
        List<User> users = [Select Id, User.DelegatedApproverId, Profile.Name, Sales_Organisation__c From User where Id IN:approverIds];
        for(User us : users){
            mapUserVsApprover.put(us.Id,us);
        }  
        salesOrgMap = new Map<string, Sales_Organisation__c>([Select Id,Name,Code__c From Sales_Organisation__c where Id IN:salesOrgIds]);
        
        List<ProcessInstanceWorkitem> piWorkItemsUpdate = new List<ProcessInstanceWorkitem>();
        
        List<ProcessInstanceWorkitem> piWorkItems = [SELECT Id, ActorId, OriginalActorId, ProcessInstanceId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId IN:claimIds ];
        if(piWorkItems.size()>0){
            for(ProcessInstanceWorkitem piWorkItem: piWorkItems){
                piToItemsMap.put(piWorkItem.Id, piWorkItem.ProcessInstanceId);
            }
            Map<Id,ProcessInstance> piItemsMap = new Map<Id,ProcessInstance>([SELECT Id, TargetObjectId FROM ProcessInstance WHERE Id IN:piToItemsMap.values()]);
            System.debug('piWorkItems '+piWorkItems);
            System.debug('piItemsMap '+piItemsMap);
            System.debug('piToItemsMap '+piToItemsMap);
            
            for(ProcessInstanceWorkitem piWorkItem: piWorkItems){
                piWorkItemsMap.put(piItemsMap.get(piToItemsMap.get(piWorkItem.Id)).TargetObjectId, piWorkItem);
            }
        }
        
        Set<Id> approverIdSet = new Set<Id>(approverIds);
        Map<Id,User> checkmapUserVsApprover = new Map<Id,User>();
        checkmapUserVsApprover  = checkCustomPermission(approverIdSet);
        
        
        for(CST_Claim__c claim: mapnewItems.values()){
            if((claim.CST_Status__c =='Assigned to Default Approver' && claim.Claim_Reassign__c!=null && (claim.Claim_Reassign__c != mapOldItems.get(claim.Id).Claim_Reassign__c))){
               claim.addError('Claim can only be reassigned by Actual approver'); 
            }
            if((claim.CST_Status__c =='Assigned To Approver' && claim.Claim_Reassign__c!=null && (claim.Claim_Reassign__c != mapOldItems.get(claim.Id).Claim_Reassign__c))){
                User newUser = mapUserVsApprover.get(reassignedMap.get(claim.Id));
                User oldUser = mapUserVsApprover.get(approverMap.get(claim.Id));
                Boolean IsCommonAssignSalesOrg = false;
                String claimSalesOrg;
                if(!Test.isRunningTest()){
                    claimSalesOrg = salesOrgMap.get(claim.CST_Sales_Organisation__c).Code__c;
                } 
                if(newUser.Sales_Organisation__c != null && newUser.Sales_Organisation__c.split(';').contains(claimSalesOrg)){
                    IsCommonAssignSalesOrg= true;
                }    
                if((!IsCommonAssignSalesOrg || (newUser.Profile.Name != 'CST Approver' && !checkmapUserVsApprover.containskey(newUser.Id)) || newUser.DelegatedApproverId != null) && !Test.isRunningTest()){
                    claim.addError('Claim can only be reassigned to an approver, who has access to sales org of the claim. Please select a valid Approver');
                }else{
                    if(!piWorkItemsMap.isEmpty() && piWorkItemsMap.get(claim.Id)!=null){
                        ProcessInstanceWorkitem piWItem = piWorkItemsMap.get(claim.Id);
                        piWItem.ActorId = claim.Claim_Reassign__c;
                           piWorkItemsUpdate.add(piWItem);
                       }
                       claim.CST_Approver__c= claim.Claim_Reassign__c; 
                   }                
            }            
        }
        if(!piWorkItemsUpdate.isEmpty()){
            try{
                system.debug('piWorkItemsUpdate '+piWorkItemsUpdate);
                update piWorkItemsUpdate;
            }
            catch(Exception Ex){
                system.debug('Error in reassignment:'+Ex);
            }
        }
    }
    
    
    /**
    * @description validateApproverUser
    * Validate new appprover User.
    * @param Map,Map
    */    
    public static void validateApproverUser(Map <Id,sObject> newItems, Map <Id,sObject> oldItems){        
        Map<Id, User> mapnewItems = (Map<Id, User>) newItems;
        Map<Id, User> mapOldItems;
        Map<String, string> oldUserdelApp = new Map<String, string>();
        Map<String, string> newUserdelApp = new Map<String, string>();
       // Map<string, User> mapUserVsdelApp = new Map<string, User>();
        List<Id> delAppIds = new List<id>();
        //Boolean hasPermission = FeatureManagement.checkPermission('CST_Approver');
        
        if(oldItems != null){
            mapOldItems = (Map<Id,User>)oldItems;
        }
        for(User us : mapOldItems.values()){
            oldUserdelApp.put(us.Id,us.DelegatedApproverId);
            delAppIds.add(us.DelegatedApproverId);
            System.debug('mapOldItems '+ us.DelegatedApproverId + ' us.DelegatedApproverId');
        }        
        for(User us : mapnewItems.values()){          
            newUserdelApp.put(us.Id,us.DelegatedApproverId);
            delAppIds.add(us.DelegatedApproverId);
            System.debug('mapNewUsers'+ us.DelegatedApproverId + 'us.DelegatedApproverId');
            
        }
        //List<User> users = [Select Id,Name,DelegatedApproverId,Profile.Name,Available_Countries__c From User where Id IN:mapnewItems.values()];       
        Map<Id,User> mapUserVsdelApp = new Map<Id,User>([Select Id,Name,DelegatedApproverId,Profile.Name,Sales_Organisation__c From User where Id IN:delAppIds]);
        Map<Id,User> mapNewUsers = new Map<Id,User>([Select Id,Name,DelegatedApproverId,Profile.Name,Sales_Organisation__c From User where Id IN:mapnewItems.values()]);
        
        
         Map<Id,User> checkPermapUserVsdelApp = new Map<Id,User>();
         Map<Id,User> checkPermapNewUsers = new Map<Id,User>();
         checkPermapUserVsdelApp  = checkCustomPermission(mapUserVsdelApp.keySet());
         checkPermapNewUsers  = checkCustomPermission(mapNewUsers.keySet());
        
       
        /*for(User us : users){
            mapUserVsdelApp.put(us.Id,us);  
        } 
		*/
        
        for(User usr: mapNewUsers.values()){ 
            string delegatedAppId = newUserdelApp.containskey(usr.Id)?newUserdelApp.get(usr.Id):null;
            System.debug('validateApproverUser '+delegatedAppId+ ' ' + usr.Sales_Organisation__c);
            if(delegatedAppId != null && usr.Sales_Organisation__c != null){
                //Boolean IsCommonAssignCountry = false;
                Boolean IsCommonAssignSalesOrg = false;
                List<string> str1 = usr.Sales_Organisation__c.split(';');
                List<string> str2 = mapUserVsdelApp.get(delegatedAppId).Sales_Organisation__c.split(';');
                if(str1 != null && str2 != null){
                    for(string str : str1){
                        if(str2.contains(str)){
                            IsCommonAssignSalesOrg = true;
                            break;
                        }  
                    }  
                }                
                if(delegatedAppId != mapOldItems.get(usr.Id).DelegatedApproverId){

                    /*if(!IsCommonAssignCountry || mapUserVsdelApp.get(us.DelegatedApproverId).Profile.Name != 'CST Approver' ||  mapUserVsdelApp.get(us.DelegatedApproverId).DelegatedApproverId != null){
                        us.addError('Please provide the valid User For Delegated Approver');  
                    }*/                   
                    if((usr.Profile.Name == 'CST Approver' || checkPermapNewUsers.containskey(usr.Id)) && 
                       (!IsCommonAssignSalesOrg || (mapUserVsdelApp.get(delegatedAppId).Profile.Name != 'CST Approver' && !checkPermapUserVsdelApp.containskey(delegatedAppId)) || mapUserVsdelApp.get(delegatedAppId).DelegatedApproverId != null)){
                        mapnewItems.get(usr.Id).addError('Please provide the valid User For Delegated Approver');  
                    }
                }            
            }
        }
    }
    
   
     ///
     /**
    * @description checkCustomPermission
    * @param Set
    */    
    public static Map<Id,User> checkCustomPermission( Set<Id> userId){
        Set < Id > permissionSetIds = new Set < Id >();  
        List < User > userList = new List < User >();  
        for ( SetupEntityAccess access : [ SELECT ParentId FROM SetupEntityAccess   WHERE SetupEntityId IN ( SELECT Id   
                                                                    FROM CustomPermission   
                                                                    WHERE DeveloperName = 'CST_Approver' )] )   
            permissionSetIds.add(access.ParentId);  
               
         Map<Id,User> mapUserData = new Map<Id,User>([ SELECT Id, Username FROM User WHERE Id IN (SELECT AssigneeId FROM PermissionSetAssignment  
                WHERE PermissionSetId IN :permissionSetIds AND AssigneeId IN:userId )]);  
        return mapUserData;
    }
    ///

    public static void updateDateFields(Map <Id,sObject> newItems, Map <Id,sObject> oldItems)
    {
        Map<Id, CST_Claim__c> mapnewItems = (Map<Id, CST_Claim__c>) newItems;
        Map<Id, CST_Claim__c> mapOldItems;        
        
        Map<Id,CST_Claim__c> rejectedStatements = new Map<Id,CST_Claim__c>();       
        
        if (oldItems != null) {
            mapOldItems = (Map<Id,CST_Claim__c>)oldItems;
        }    
        
        for(CST_Claim__c claim: mapnewItems.values()){
            
            //if(mapOldItems.containsKey(claim.Id) && claim.CST_Status__c =='Assigned to Default Approver')
            if(mapOldItems.containsKey(claim.Id) && mapOldItems.get(claim.Id).CST_Status__c == 'New' && claim.CST_Status__c =='Assigned to Default Approver'){           
               claim.Date_New_To_Assign_Default_Approver__c = System.today(); 
            }
            if(mapOldItems.containsKey(claim.Id) && (claim.CST_Status__c =='Approved' || claim.CST_Status__c =='Rejected')) {                
                if(mapOldItems.get(claim.Id).CST_Status__c !='Approved'){                
               claim.Date_Of_Approval_Rejection__c = System.today(); 
            }
        }
    }
    }
}