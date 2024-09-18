/**    
    * @description CST_SendToApprovalController    
    * @history    
    * 1.0         CST Team              19/05/2021        Initial Development    
    */
public without sharing class CST_SendToApprovalController {
    
    public static boolean runOnce = true;
    /**
    
    * @description checkValidForApproval
    * @return string 
    * @param Id, Boolean  
    
    */
    @AuraEnabled
    public static string checkValidForApproval(Id claimId,Boolean initValue){
        System.debug('CheckValidApproval Line 18');
        String msg= '';
        String serialized=''; 
        Id userId = UserInfo.getUserId();
        List<CST_Claim__c> newClaimList = new List<CST_Claim__c>();
        Map<Id,String> approverList = new Map<Id,String>();
        Map<String,String> result = new Map<String,String>();
        CST_Claim__c claimObj ;
        
        if(String.isNotBlank(claimId)){
            List<CST_Claim__c> claimList = [SELECT Id,CST_Status__c,OwnerId,CST_Approver__c,CST_Sales_Organisation__r.Default_Approver__c,
                                          	CST_Account__r.CST_Default_Approver__c,CreatedById,CST_Sales_Organisation__r.Tax_Code_Mandatory__c
                                            FROM CST_Claim__c
                                            WHERE Id =: claimId];
            if(claimList!= null && !claimList.isEmpty()){
                switch on claimList[0].CST_Status__c{
                    when  'Assigned To Approver'{
                        msg= Label.CST_Send_for_Approval_Error;
                    	result.put('ERROR', msg);
    				}
                    when  'In Query'{
                        msg= 'Please change status, while in query, claim can not be submitted for approval';
                    	result.put('ERROR', msg);
    				}
                    when  'New'{
                        string attachmentValidationMsg = checkForAttachment(claimId);
                        if(claimList[0].CreatedById != userId){
                        	msg= Label.CST_Creator_Error;
                        	result.put('ERROR', msg); 
                    	}
                        
                        else if(attachmentValidationMsg =='AttachmentNotAvailable'){
                             msg=Label.CST_Attachment_Error;
                             result.put('ERROR', msg); 
                         }
                        
                        else if(claimList[0].CST_Sales_Organisation__r.Default_Approver__c == null && claimList[0].CST_Account__r.CST_Default_Approver__c==null){
                        	msg= Label.CST_No_Default_Approver_Error;
                        	result.put('ERROR', msg); 
                    	}
                        /**else if(claimList[0].CST_Manual_Validation__c== False){
                        	msg= Label.CST_Customer_Details_Checkbox_Error;
                        	result.put('ERROR', msg);
                    	}**/
                    	else if(claimList[0].CST_Approver__c==null && claimList[0].CST_Account__r.CST_Default_Approver__c !=null){                       
                            claimObj = new CST_Claim__c();
                            claimObj = createClaim(claimList[0],true);                             
                        	newClaimList.add(claimObj); 
                        	msg=Label.CST_Record_Successfully_Updated;
                        	result.put('SUCCESS', msg);                        
                    	}	
                    	else if(claimList[0].CST_Sales_Organisation__c !=null && claimList[0].CST_Sales_Organisation__r.Default_Approver__c  !=null){                        
                            claimObj = new CST_Claim__c();
                            claimObj = createClaim(claimList[0],false); 
                            newClaimList.add(claimObj);
                        	msg= Label.CST_Record_Successfully_Updated;
                        	result.put('SUCCESS', msg);                        
                    	}
                    	system.debug('status new'+result);
						if(newClaimList.size()>0 && newClaimList != null){
            				update newClaimList;    
                        } 
    				}
                    when  'Assigned to Default Approver'{
                        string validationMsg = checkReadyforApproval(claimId);
                    	if(validationMsg =='AmountMatch' || validationMsg =='AmountApproxMatch'){  
                            if(validationMsg =='AmountApproxMatch'){
                             	msg= Label.CST_Approval_Validation_Warning;                             
                             	result.put('WARNING', msg);                            
                    		}
                       		if(claimList[0].OwnerId != userId){
                             	 msg=Label.CST_Status_Error;
                              	result.put('ERROR', msg);                             
                       		}else if(claimList[0].OwnerId.equals(userId) && claimList[0].CST_Approver__c.equals(userId)){
                            	approverList= getApproverList(claimId);
                            	system.debug('approverList'+approverList);
                                if(approverList != null && !approverList.isEmpty()){
                                    if(approverList.containsKey(claimList[0].CST_Approver__c)){
                                        msg= 'true';
                                        result.put('Default Approver', msg);                                        
                                    }
									else{
										serialized = JSON.serialize(approverList);
					                    return serialized;
									}
                                }else{
                                    msg='No Approver present in this combination';
                                    result.put('ERROR', msg);                                    
                                }
                       		}
                    	}
                        else if (claimList[0].CST_Sales_Organisation__r.Tax_Code_Mandatory__c == True && validationMsg =='AmountNotMatch'){
                             	msg= Label.CST_Approval_Validation_Error;                             
                             	result.put('ERROR', msg);                            
                    	}
                        else if (validationMsg == 'TotalNetItemAmountNotMatch'){
                             	msg= Label.CST_Total_Net_Value_ValidationMsg;                             
                             	result.put('ERROR', msg);
                        }
    				}
                }                
                
				if(!result.isEmpty()){
					serialized = JSON.serialize(result);
                    system.debug('serialized'+serialized);
                    return serialized;
				}							
            }            
        }
      return null;        
    }
    /**
    
    * @description checkReadyforApproval
    * @return string 
    * @param Id
    
    
    */
@AuraEnabled
    public static string checkReadyforApproval(Id claimId){
        System.debug('checkReadyforApproval Line 115');
        list<AggregateResult> claimItemList = new list<AggregateResult>();
        if(String.isNotBlank(claimId))
        {            
            List<CST_Claim__c> claimList = [SELECT Id,Total_value__c,CST_Total_Item_Values__c,CST_Sales_Organisation__r.Tax_Code_Mandatory__c,CST_Total_Amount__c 
                                            FROM CST_Claim__c WHERE Id =: claimId];
            claimItemList = [SELECT CST_Claim__c, SUM(Total_Item_value__c)total FROM CST_Claim_Item__c
                              WHERE CST_Claim__c =: claimId GROUP BY CST_Claim__c];
            if(claimList!= null && !claimList.isEmpty() && claimItemList!= null && !claimItemList.isEmpty()){
                Decimal totalItemVal= (Decimal)claimItemList[0].get('total');
                Decimal roundedVal= totalItemVal.setScale(2);
                Decimal cstTotalAmnt= (Decimal)claimList[0].Total_value__c;
                system.debug('total vals- cstTotalAmnt '+ cstTotalAmnt+' roundedVal '+ roundedVal);
                Decimal cstClaimTotalAmnt= (Decimal)claimList[0].CST_Total_Amount__c;
                Decimal cstClaimTotalItemAmnt= (Decimal)claimList[0].CST_Total_Item_Values__c.setScale(2);
                Decimal variance= 0.0;
                if(claimList[0].CST_Sales_Organisation__r.Tax_Code_Mandatory__c ){
					if(cstTotalAmnt>roundedVal)
						variance= ((cstTotalAmnt-roundedVal)/cstTotalAmnt)*100;
					else
						variance= ((roundedVal-cstTotalAmnt)/cstTotalAmnt)*100;
					if(cstTotalAmnt == roundedVal && variance==0.0){
						return 'AmountMatch';
					}
					else if(variance>0 && variance<=1){
					   return 'AmountApproxMatch' ;                    
					}
					else if(variance>1)
						return 'AmountNotMatch';				
				}
                else {
                    if(claimList[0].CST_Sales_Organisation__r.Tax_Code_Mandatory__c == False && cstClaimTotalAmnt != cstClaimTotalItemAmnt){
                      return 'TotalNetItemAmountNotMatch';
                    }
                    else{
                        return 'AmountMatch';
                    }
                }												
            }           
            else{                
                return 'NoClaimItmFound';
            }            
        }
        return 'NoClaimItmFound';
    }
    /**
    
    * @description getApproverList
    * @return Map 
    * @param Id
    
    
    */  
    @AuraEnabled
    public static Map<Id,String> getApproverList(Id claimId){
        System.debug('getApproverList');
        Map<Id,String> userIdMap = new Map<Id,String>();
        List<Approver_Matrix__c> appMatrixList = new List<Approver_Matrix__c>();
        List<Approver_Matrix__c> appMatrixCovList = new List<Approver_Matrix__c>();
        RecordCurrAmountWrapper recWrap = new RecordCurrAmountWrapper();
        if(String.isNotBlank(claimId)){
            List<CST_Claim__c> claimList = [SELECT Id,CST_Sales_Organisation__c,CST_Sales_Organisation__r.Name,CurrencyIsoCode,
                                            CST_Total_Amount__c,CST_Sales_Organisation__r.Code__c
                                            FROM CST_Claim__c
                                            WHERE Id =: claimId];
            if(claimList!= null && !claimList.isEmpty()){
                /*for(Approver_Matrix__c appMatObj : [SELECT Id,Approver_User__c,Approver_User__r.Name,CurrencyIsoCode,Max_Limit__c,Min_Limit_Amount__c
                                                      FROM Approver_Matrix__c
                                                      WHERE Sales_Org__c = : claimList[0].CST_Sales_Organisation__r.Code__c
                                                      AND Max_Limit__c >= : claimList[0].CST_Total_Amount__c
                                                      AND Min_Limit_Amount__c <= : claimList[0].CST_Total_Amount__c
                                                      AND Matrix_Status__c = 'Enabled'
                                                      AND Approval_Category__c = 'Customer Spend Approval' 
                                                      AND Approver_User__c != null]){
                                                      userIdMap.put(appMatObj.Approver_User__c,appMatObj.Approver_User__r.Name);*/
                //Modified for CST-155
                appMatrixList = [SELECT Id,Approver_User__c,Approver_User__r.Name,CurrencyIsoCode,Max_Limit__c,Min_Limit_Amount__c
                                 FROM Approver_Matrix__c
                                 WHERE Sales_Org__c = : claimList[0].CST_Sales_Organisation__r.Code__c
                                 AND Matrix_Status__c = 'Enabled'
                                 AND Approval_Category__c = 'Customer Spend Approval' 
                                 AND Approver_User__c != null];
                if(!appMatrixList.isEmpty()){
                    recWrap.recAmount = claimList[0].CST_Total_Amount__c;
                    recWrap.recCurrencyCode = claimList[0].CurrencyIsoCode;
                    appMatrixCovList = convertCurrency(recWrap,appMatrixList);
                    if(!appMatrixCovList.isEmpty()){
                        for(Approver_Matrix__c appMatObj :appMatrixCovList){
                            userIdMap.put(appMatObj.Approver_User__c,appMatObj.Approver_User__r.Name);
                        }
                    }
                }
            }
        }     
        if(!userIdMap.isEmpty()){
            return userIdMap;
        }else{
            return null;
        }
    }
    
    /**
    
    * @description toggleQuery
    * @param Id, Boolean, Id
    
    
    */
    @AuraEnabled
    public static void toggleQuery(Id claimId,Boolean stsVal, Id userId)
    {               
        System.debug('toggleQuery');
        List<CST_Claim__c> claimList = new List<CST_Claim__c>();
        for(CST_Claim__c claimObj:[SELECT Id,CST_Status__c,CST_Querier__c,Previous_status__c 
                                   FROM CST_Claim__c 
                                   WHERE Id =: claimId]){
            if(claimObj.CST_Status__c != 'In Query' && stsVal){
                claimObj.Previous_status__c = claimObj.CST_Status__c; 
                claimObj.CST_Status__c = 'In Query';
                claimObj.CST_Querier__c = userId;
                claimList.add(claimObj);
            }
            else if(!stsVal && claimObj.Previous_status__c != null) {
                    claimObj.CST_Status__c = claimObj.Previous_status__c; 
                    claimList.add(claimObj);
            } 
        }
        if(claimList != null && !claimList.isEmpty()) {
                update claimList; 
        }         
    }

    /**
    
    * @description getClaimValidStatus
    * @return string 
    * @param Id
    
    
    */
    @AuraEnabled
    public static string getClaimValidStatus(Id claimId)
    {        
        System.debug('getClaimValidStatus 234');
       List<CST_Claim__c> claimList = [SELECT Id,CST_Status__c,Previous_status__c
                                       FROM CST_Claim__c
                                       WHERE Id =: claimId];
        if(!claimList.isEmpty()){
           return claimList[0].CST_Status__c;
        } 
        else
          return null;  
    }    
    /**
    
    * @description getUser
    * @return Boolean 
    * @param Id, Id
    
    
    */
    @AuraEnabled
    public static Boolean getUser(Id userId, Id claimId)
    {        
        System.debug('getUser 255');
       List<CST_Claim__c> claimList = [SELECT Id,CreatedById,CST_Status__c,CST_Querier__c
                                       FROM CST_Claim__c
                                       WHERE Id =: claimId];
        if(!claimList.isEmpty()){
            if(claimList[0].CreatedById.equals(userId))
                return true;
            else if(claimList[0].CST_Status__c.equals('New') || claimList[0].CST_Status__c.equals('Rejected')  || claimList[0].CST_Status__c.equals('Approved') )
                return true;
            else if(claimList[0].CST_Status__c.equals('In Query') && (claimList[0].CST_Approver__c != userId && claimList[0].OwnerId != userId ))
                return true;
            else
                return false;
        } 
        else
          return false;  
    }    
    
    /**
    
    * @description submitForApprovalRecord
    * @return boolean 
    * @param Id, String, String
    
    
    */   
  @AuraEnabled
    public static boolean submitForApprovalRecord(Id claimId, String comment,String appAction){
         System.debug('submitForApprovalRecord');
        Id userId = UserInfo.getUserId();                                  
        Approval.ProcessSubmitRequest req1 = new Approval.ProcessSubmitRequest();
        req1.setComments('Submitting request for approval ');
        req1.setObjectId(claimId);
        req1.setSubmitterId(userId);                
        req1.setProcessDefinitionNameOrId('CST_Claim_Approval');
        req1.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req1.setSkipEntryCriteria(true);                  
        Approval.ProcessResult processResults =  Approval.process(req1);               
        return processResults.isSuccess();  
    }   
 
    /**
    
    * @description sendforApproval
    * @param Id, String, String, String
    
    
    */   
   @AuraEnabled
   public static void sendforApproval(Id claimId, String comment,String appAction,string rJctReason)
    {        
System.debug('sendforApproval');   
        Id userId = UserInfo.getUserId();
        system.debug('rejectReason'+rJctReason);
        //system.debug('1111111'+comment);
        system.debug('claimId'+claimId);
        system.debug('appAction'+appAction);
        submitForApprovalRecord(claimId,comment,appAction);
        Id workItemId = getWorkItemId(claimId);
        Approval.ProcessWorkitemRequest req2 = new Approval.ProcessWorkitemRequest();       
        req2.setComments(comment);
        req2.setAction(appAction);
        req2.setNextApproverIds(new Id[] {UserInfo.getUserId()});
        req2.setWorkitemId(workItemId);
        Approval.ProcessResult result2 =  Approval.process(req2);
        if(result2.isSuccess() && appAction =='Reject'){
            updateRecjectionReason(claimId,rJctReason,comment); 
        }
        //return result2.isSuccess();
        //return false;
        //return result.isSuccess();                   
    }

    /**
    
    * @description getWorkItemId
    * @return Id 
    * @param Id
    */    
	
    public static Id getWorkItemId(Id targetObjectId)
		{
            System.debug('getWorkItemId');
			Id retVal = null;
			for(ProcessInstanceWorkitem workItem  : [Select p.Id from ProcessInstanceWorkitem p	where p.ProcessInstance.TargetObjectId =: targetObjectId]){
				retVal  =  workItem.Id;
			}
			return retVal;
		}
    /**
    
    * @description updateClaim
    * @return Wrapper 
    * @param Id, Id
    
    
    */
    @AuraEnabled
    public static SaveResultWrapper updateClaim(Id claimId, Id OwnerId){
        SaveResultWrapper wrapObj = new SaveResultWrapper();
        if(!String.isEmpty(claimId) && !String.isEmpty(OwnerId)){
            //sendforApproval(claimId, OwnerId);
            List<CST_Claim__c> claimList = [SELECT Id,CST_Status__c,CST_Approver__c
                                            FROM CST_Claim__c
                                            WHERE Id =: claimId];
            if(claimList!= null && !claimList.isEmpty()){
                claimList[0].CST_Approver__c = OwnerId;
                //claimList[0].OwnerId = OwnerId;
                claimList[0].CST_Status__c = 'Assigned To Approver';
                try{
                    update claimList;   
                    //submitforApproval(claimId);
                    wrapObj.isSuccess = true;
                    wrapObj.message = Label.CST_RecordSaveSuccMsg;
                    return wrapObj;
                }catch(exception ex){
                    wrapObj.isSuccess = false;  
                    wrapObj.message = ex.getMessage();
                    return wrapObj;
                }
                
            }
            wrapObj.isSuccess = false;   
            wrapObj.message = Label.CST_RecordSaveErrMsg1;
            return wrapObj;
        }
        wrapObj.isSuccess = false;   
        wrapObj.message = Label.CST_RecordSaveErrMsg2;
        return wrapObj;
    }
  
    
    /**
    
    * @description updateRecjectionReason
    * @param Id, String, String
    
    
    */
    @AuraEnabled
    public static void updateRecjectionReason(Id claimId,String rejectionReason, String comment)
    {               
        CST_Claim__c claimObj = new CST_Claim__c(Id = claimId);
        claimObj.Cst_Reject_Reason__c = rejectionReason;
        claimObj.CST_Approval_Comments__c = comment;
        //Database.SaveResult sr = Database.update(claimObj);
        try{
            update  claimObj;
        }catch (DmlException ex) {
            throw new AurahandledException('Error Details : ' + ex.getDmlMessage(0));
        } catch (Exception ex) { throw new AurahandledException('Error Details : ' + ex.getMessage());
        }
        
        //update claimObj;
    }
    
    /**
    
    * @description getPickListForRejectionReason
    * @return List 
    
    
    */    

    @AuraEnabled
    public static List<String> getPickListForRejectionReason(){
       List<String> pickListValuesList= new List<String>();
		Schema.DescribeFieldResult fieldResult = CST_Claim__c.Cst_Reject_Reason__c.getDescribe();
		List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
		for( Schema.PicklistEntry pickListVal : ple){
			pickListValuesList.add(pickListVal.getLabel());
		}   
       
		return pickListValuesList;
    }
    /**
    
    * @description toastNotificationCheck
    * @return Boolean 
    * @param Id
    
    
    */  
   @AuraEnabled
    public static Boolean toastNotificationCheck(Id recordId){
        if(String.isNotBlank(recordId)){
            List<CST_Claim__c> claimList = [Select Id, CST_Is_duplicate__c 
                                 FROM CST_Claim__c WHERE Id= :recordId and CST_Status__c = 'New'];
            if(!claimList.isEmpty()){
           		if(claimList[0].CST_Is_duplicate__c)
                    return true;
                else
                    return false;
        	} 
        	else
          		return false;
    	}
        return false;
    }
    
    /**
    
    * @description SaveResultWrapper
    
    * @history
    
    * 1.0         CST Team              19/05/2021        Initial Development
    
    */
    public class SaveResultWrapper{
        @AuraEnabled
        public Boolean isSuccess{get;set;}
        @AuraEnabled
        public String message{get;set;}
    }
    /**
    
    * @description convertCurrency
    * @return List 
    * @param Wrapper, List
    
    
    */
    public static List<Approver_Matrix__c> convertCurrency(RecordCurrAmountWrapper recordVal,List<Approver_Matrix__c> appMatrixList){
        List<Approver_Matrix__c> appMatrixRetList = new List<Approver_Matrix__c>();
        Map<String,Decimal> currConvMap = new Map<String,Decimal>();
        Decimal recordCurrency;
        if(recordVal!= null){
            for(CurrencyType currObj: [SELECT ConversionRate,DecimalPlaces,Id,IsCorporate,IsoCode 
                                      FROM CurrencyType]){
                currConvMap.put(currObj.IsoCode,currObj.ConversionRate);
            }
        }
        if(!appMatrixList.isEmpty()){
            recordCurrency = currConvMap.get(recordVal.recCurrencyCode);
            for(Approver_Matrix__c appMatObj : appMatrixList){
                Decimal appMaxAmount = appMatObj.Max_Limit__c == null? 0: appMatObj.Max_Limit__c;
                Decimal appMinAmount = appMatObj.Min_Limit_Amount__c == null? 0: appMatObj.Min_Limit_Amount__c;
                if(!appMatObj.CurrencyIsoCode.equalsIgnorecase(recordVal.recCurrencyCode)){
                    Decimal appCurrency = currConvMap.get(appMatObj.CurrencyIsoCode);
                    appCurrency = appCurrency == null? 0 : appCurrency;
                    Decimal convertedRecAmnt = recordCurrency==0 ? 0 : (recordVal.recAmount/recordCurrency).setScale(2);
                    Decimal convertedMinAmount = appCurrency==0 ? 0 : (appMinAmount/appCurrency).setScale(2);
                    Decimal convertedMaxAmount = appCurrency==0 ? 0 : (appMaxAmount/appCurrency).setScale(2);
                    if(convertedMinAmount<= convertedRecAmnt && convertedMaxAmount>=convertedRecAmnt){
                        appMatrixRetList.add(appMatObj);
                    }
                }else{
                    if(appMinAmount<= recordVal.recAmount && appMaxAmount>= recordVal.recAmount){
                        appMatrixRetList.add(appMatObj);
                    }
                }
            }
        }
        return appMatrixRetList;
    }
    /**
    
    * @description RecordCurrAmountWrapper
    
    * @history
    
    * 1.0         CST Team              19/05/2021        Initial Development
    
    */
    public class RecordCurrAmountWrapper{
        public Decimal recAmount;
        public String recCurrencyCode;
    }

    /**
    
    * @description Check and delecated and approval and assigned 
    
    * @history
    
    * 1.0         CST Team              19/05/2021        Initial Development
    
    */
    
    Public static CST_Claim__c createClaim(CST_Claim__c claimObj, Boolean isOnAccount){
        CST_Claim__c claimRec = new CST_Claim__c();
        if(isOnAccount){
            User userRec = [Select Id, DelegatedApproverId From User where Id =: claimObj.CST_Account__r.CST_Default_Approver__c];
            if(userRec.DelegatedApproverId != null){
                claimRec.CST_Approver__c= userRec.DelegatedApproverId;
                claimRec.OwnerId= userRec.DelegatedApproverId;
            }else{
                claimRec.CST_Approver__c= claimObj.CST_Account__r.CST_Default_Approver__c;
                claimRec.OwnerId= claimObj.CST_Account__r.CST_Default_Approver__c;
            }            
        }else if(!isOnAccount){
            User userRec = [Select Id, DelegatedApproverId From User where Id =: claimObj.CST_Sales_Organisation__r.Default_Approver__c];
            if(userRec.DelegatedApproverId != null){
                claimRec.CST_Approver__c= userRec.DelegatedApproverId;
                claimRec.OwnerId= userRec.DelegatedApproverId;
            }else{
                claimRec.CST_Approver__c= claimObj.CST_Sales_Organisation__r.Default_Approver__c;
                claimRec.OwnerId= claimObj.CST_Sales_Organisation__r.Default_Approver__c;
            } 
        }        
        claimRec.CST_Status__c='Assigned to Default Approver';        
        claimRec.Id = claimObj.Id;
        return claimRec;        
    }   
    
    
     /**
    * @description checkForAttachment
    * @return string 
    * @param Id
    */
    @AuraEnabled
    public static string checkForAttachment(Id claimId){
        System.debug('checkForAttachment Line 576');
                  
        List<CST_Claim__c> claimList = [SELECT Id,CST_Total_Amount__c,CST_Total_Item_Values__c FROM CST_Claim__c
                                        WHERE Id =: claimId];
        List<ContentDocumentLink> objConDocLink = [SELECT Id,LinkedEntityId,ContentDocumentId FROM ContentDocumentLink
                                                   WHERE LinkedEntityId =: claimId];
        
        if((objConDocLink!= null && !objConDocLink.isEmpty()) || (objConDocLink!= null && objConDocLink.size()>0)){
            return 'AttachmentAvailable';
        }
        else{                
            return 'AttachmentNotAvailable';
        }            
    }
    
}