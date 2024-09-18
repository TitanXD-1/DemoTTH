/*
Name: CRG_ContractApprovalHelper
*
Purpose: Contract Record approval with Cold Room Grant Record Type
*
History                                                            
*                                                            
VERSION     AUTHOR                       DATE                DETAIL
1.0         Sudipta/Joshraj            27/12/2023          Contract Record approval with Cold Room Grant Record Type
2.0         Joshraj                    11/01/2023          Correction email should go to Line Manager 149907
3.0         Saurav Prasad              26/01/2024          149936 - CRG: Editing Draft Contract_SFDC
*/
public without sharing class CRG_ContractApprovalHelper {
    public static string submitForApproval (Contract newContractRecord){
        String str = 'Submit Failed';
        //Contract newContractRecord = new Contract ();
        
        if(Schema.sObjectType.ECM_Approval_Log__c.isAccessible())
        {
            AggregateResult cycleCount = [SELECT MAX(ECM_No_of_Approval_Cycles__c) FROM ECM_Approval_Log__c where ECM_Contract__c=:newContractRecord.Id ];
            
            integer approvalcount = integer.valueOf(cycleCount.get('expr0')==Null?0:cycleCount.get('expr0'));
            //string emailId = '';
            //string delegatedUser = System.Label.ECM_Delegated_Approver;
            User recipentUserEmail = new User();
            //System.debug('Value of Contract ID '+newContractRecord.Id);  
            ECM_Contract_Type__c ecmContractType =new ECM_Contract_Type__c();
            if(Schema.sObjectType.ECM_Contract_Type__c.isAccessible())
            {
                ecmContractType = [SELECT id,ECM_Aggrement_Duration__c,Geography__r.Code__c,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Automatic_approval_amount_threshold__c ,
                                   ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Contract_Approval_mail_to_Customer__c,
                                   ECM_Mandatory_Fields_Check__c FROM ECM_Contract_Type__c where Id=: newContractRecord.ECM_Agreement_Type__c];
            }
            
            if(newContractRecord.ECM_Overall_Investment_Figure__c < ecmContractType.ECM_Automatic_approval_amount_threshold__c && Schema.sObjectType.Contract.isUpdateable()){
                newContractRecord.status = 'Approved';// earlier Approved';
                update newContractRecord;
                str = 'Approved';
            }else if((newContractRecord.ECM_Overall_Investment_Figure__c >= ecmContractType.ECM_Automatic_approval_amount_threshold__c)
                     || (newContractRecord.ECM_Overall_Investment_Figure__c==Null)){
                         system.debug(LoggingLevel.debug,newContractRecord.ECM_Overall_Investment_Figure__c);
                         newContractRecord.status = 'In Approval Process';
                         //create Approval Log                    
                         str = generateApprovalLog(newContractRecord,approvalcount,recipentUserEmail);
                     }  
            
        }
        return str;
    }
    public static String  generateApprovalLog(Contract newContractRecord,Integer approvalcount,User recipentUserEmail)
    {
        String str = '';
        ECM_Approval_Log__c approvLog = new ECM_Approval_Log__c();
        approvLog.ECM_Time_Date_Log__c	 = system.now();
        approvLog.Name = newContractRecord.ContractNumber;
        approvLog.ECM_No_of_Approval_Cycles__c = approvalcount+1;
        approvLog.RecordTypeId =Schema.getGlobalDescribe().get('ECM_Approval_Log__c').getDescribe().getRecordTypeInfosByName().get('Primary approver').getRecordTypeId();
        //System.debug('Owner Id '+newContractRecord.OwnerId);
        User mgr=new User();
        String ownerId=userinfo.getuserid();
        if(Schema.sObjectType.User.isAccessible())
        {
            mgr=[Select Id,ManagerId,Manager.DelegatedApproverId,Manager.Email from User where id=:ownerId limit 1];
        }   
        if(!Test.isRunningTest())
        {
            if(mgr.Manager.DelegatedApproverId == Null){
                recipentUserEmail = ECM_CreateContractController.getUser(mgr.ManagerId);
            }else{
                //Delegation Approval Log
                recipentUserEmail = ECM_CreateContractController.getUser(mgr.Manager.DelegatedApproverId);
            }
            
        }
        else
        {         
            recipentUserEmail=[Select Id,Name,Email,Title from User where Name like '%AdminManager%' limit 1];
        }
        
        String emailId = recipentUserEmail.Email;
        approvLog.ECM_Approver_s_Position__c= recipentUserEmail!=Null?recipentUserEmail.Title:'';
        newContractRecord.status = emailId!=''?'In Approval Process':'Approved';
        approvLog.ECM_Status__c = newContractRecord.status=='In Approval Process'?'Requested':newContractRecord.status=='Approved'?'Approved':'Rejected';
        approvLog.Name= EmailId!=''?emailId:approvLog.Name;
        approvLog.ECM_Type__c = 'Contract';
        approvLog.ECM_Contract__c = newContractRecord.Id;
        updateContractCreateApproval(approvLog,newContractRecord);
        str = emailandnotify(approvLog,recipentUserEmail,newContractRecord);
        return str;
        
    }
    public static void updateContractCreateApproval(ECM_Approval_Log__c approvLog, Contract newContractRecord)
    {
        upsert newContractRecord;
        insert approvLog;    
    }
    public static string emailandnotify(ECM_Approval_Log__c approvLog,User recipentUserEmail,Contract newContractRecord)
    {
        String str = 'No manager assigned';
        if(recipentUserEmail.email !=''){  
            //ECM_CreateContractController.sendPushNotificationForApprovalLog(approvLog.Id,recipentUserEmail.Id);
            ECM_CreateContractController.aSyncsendEmailToUser(recipentUserEmail.Id,newContractRecord.Id,approvLog.Id);
            str = 'Submitted for Approval';
        }
        return str;
    }
}