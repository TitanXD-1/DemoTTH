/*
* Class Name: ECM_ApprovalLogUtility
* Author: 
* Brief Description: This class is used to create approval logs.
* Created Date: 
* History: 
VERSION    AUTHOR                DATE              DETAIL
1.0		Veerendra Billakurthi	01-02-2021		ECM-3647 Tech Debt - ECM_ApprovalLogUtility 
1.1		Chandrakanth			03/06/2021		ECM-4194 Delegations Contract Approvals_SFDC_GLO_Contract Creation 
1.2 	Anivesh Muppa			07/06/2021      ECM-4520
1.3		Saurav Prasad			25/06/2021		ECM-4565 SD Extra approval_Global_SFDC_Approval revamp
1.4		Anivesh Muppa			27/06/2021      ECM-4564 SD logic to trigger Mail for SD EA Records
1.5		Saurav Prasad			26/07/2021		ECM-4639 Legal Approval for Product level investment exceeding x amount_SFDC_Ireland MVP
1.6		Saurav Prasad			12/08/2021		ECM-4689 Email Templates for Product level investment exceeding threshold
1.7		Saurav Prasad			12/08/2021		ECM-4690 Approval Email consolidation: Contract approval+ SD+SD Item Approval mails
1.8     Keshav	                13/01/2022      ECM-4644: Attach Contract PDF to Approvals mail_GLO 
1.9		Saurav Prasad			21/01/2022		ECM-5090: FastTrack_Logic for Approval Mail Attachment_Glo
2.0		Saurav Prasad			24/03/2022		ECM-5358: Contract rejection email to Sales Rep_SFDC_GLO
2.1     Tanishq Banerjee        29/04/2022      ECM-5486: Approval flow of Recalled Group Contract_SFDC_EU_Recall
2.2		Manikandan.T			17/05/2022		ECM-5586: Revamped and moved the logic to ECm_ApprovalTriggerHelper
2.3     Vinay Tummala           07/06/2022      ECM-5649: SFDC to handle the Approval request Email to be sent to Extra Approver_Approval request for sales manager
2.4		Saurav Prasad			02/08/2022		ECM-5867: Approval flow for Addendum (Prim+Contract)_SFDC_EU
2.5     Anand Uppalapati        08/08/2022      ECM-5905: Approval flow for Addendum (SD+Legal)_SFDC_EU
2.6		Saurav Prasad			16/08/2022		ECM-6032: Approval flow for Addendum (Prim+Contract+SD+SDI)_SFDC_EU
2.7		Saurav Prasad			24/08/2022		ECM-6069: QA Defect : Logic change for the addendum Extra Approvals with type=Contract
2.8     Pratap Sen              26/08/2022      ECM-5816: Added E&S contract approval logic in updatePrimaryApprovalLog_AU,updateExtraApprovalLog_AU & validateAutoApproval
2.9     Anand Uppalapati        09/01/2022      ECM-6075:   Addendum PDF in Addendum Approval Email_SFDC_EU
3.0     Suvendu Roy             02/09/2022      ECM-6074: Logic for "Type" field on Template Agreement_Addendum_SFDC_EU
3.1     Pratap Sen              22/10/2022      ECM-6264: Logic to add parent contract attachments and amended contract PDF for Extra approver emails
3.2     Joshraj Sen             29/01/2024      150507  : Added the Field CRG_Total_Investment__c
3.3		Saurav Prasad			05/02/2024		148916	: CRG: Contract Approval email template_SFDC
3.4     Saurav Prasad           26/02/2024      151029  : Test the Business Roles with CRG permissions end to end_SFDC   
3.5     Saurav Prasad/Joshraj Sen 04/03/2024    151701  : Removed Attachments for Cold Room Grant Contracts
3.6		Shivam Chauhan		    20/03/2024		151377	: CRG Enhancements_No validation for number of attachments in "Approval mail attachments"_ SFDC 

*/
public class ECM_ApprovalLogUtility {
    
    public static boolean updatePrimaryApprovalLog(Contract con,list<ECM_Approval_Log__c> existingApprovalLogs, ECM_ApprovalLogWrapper approvalLogWrapper){
        Boolean isExtraApproval =false;
        string DelegatedUser = System.Label.ECM_Delegated_Approver;
        list<ECM_Approval_Log__c>ecmApprovalLogsList = new list<ECM_Approval_Log__c>();
        set<String>extraApprovalEmails = new set<String>();
        list<Decimal>extraApprovalLowerLimit = new list<Decimal>();
        set<String>nameOfExistingApprovalLogs ;
        //Id recordIdOutlet = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('Outlet').getRecordTypeId();
        Integer noofApprovalCount = 0;
        
        //Added part of ECM-4565
        map<String,Decimal> salesDriverMap = new map<String,Decimal>();
        set<String> extraApprovalSDEmails = new set<String>();
        set<String>nameOfExistingApprovalLogsSD;
        
        //Added as a part of ECM-4639
        List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailList = new List<ECM_Sales_Driver_Item_Detail__c>();
        set<String> nameOfExistingApprovalLogsSDID;
        set<String> extraApprovalSDIDEmails = new set<String>();
        Boolean createSDIDApprovalLog = false;
        
        //Added as a part of ECM-4689 & ECM-4690
        Map<String,set<string>> nameOfExistingApprovalLogsMap = new Map<String,set<string>>();
        Map<String,List<ECM_Approval_Log__c>> approvalLogMap = new map<string,List<ECM_Approval_Log__c>>();
        Map<String,set<String>> extraApprovalEmailsMap = new Map<String,set<String>>();
        
        
        if(existingApprovalLogs!=null && !existingApprovalLogs.isEmpty() && existingApprovalLogs.size()>0){
            for(ECM_Approval_Log__c existingAl : existingApprovalLogs){
                //Updated as part of ECM-4690
                List<String> typeList = existingAl.ECM_Type__c.split(';');
                for(Integer i=0;i<typeList.size();i++){
                    if(!nameOfExistingApprovalLogsMap.containsKey(typeList[i])){
                        nameOfExistingApprovalLogsMap.put(typeList[i],new set<String>{existingAl.Name});
                    }else{
                        nameOfExistingApprovalLogsMap.get(typeList[i]).add(existingAl.Name);
                    }
                }// end of ECM-4690
                noofApprovalCount = integer.valueof(existingAl.ECM_No_of_Approval_Cycles__c);
            }
        }
        system.debug(LoggingLevel.Debug,'nameOfExistingApprovalLogsMap-->'+nameOfExistingApprovalLogsMap);
        //Updated as part of ECM-4690
        nameOfExistingApprovalLogsSDID = nameOfExistingApprovalLogsMap.containsKey('Contract Sales Driver Item')?nameOfExistingApprovalLogsMap.get('Contract Sales Driver Item'):new set<String>();
        nameOfExistingApprovalLogsSD = nameOfExistingApprovalLogsMap.containsKey('Contract Sales Driver')?nameOfExistingApprovalLogsMap.get('Contract Sales Driver'):new set<String>();
        nameOfExistingApprovalLogs = nameOfExistingApprovalLogsMap.containsKey('Contract')?nameOfExistingApprovalLogsMap.get('Contract'):new set<String>();
        
        System.debug(LoggingLevel.Debug,'@@noofApprovalCount' +noofApprovalCount);
        if(con !=null && con.ECM_Agreement_Type__c !=null && approvalLogWrapper.agreementTypeMap.containsKey(con.ECM_Agreement_Type__c)){
            ECM_Contract_Type__c agreementType = approvalLogWrapper.agreementTypeMap.get(con.ECM_Agreement_Type__c);
            //Added part of ECM-4565 & ECM-4564
            if(approvalLogWrapper.ContractSalesDriverItemMap.containsKey(con.Id)){
                salesDriverMap=approvalLogWrapper.ContractSalesDriverItemMap.get(con.Id);				
            }
            System.debug(LoggingLevel.Debug,'salesDriverMap------->'+salesDriverMap);
            
            if(approvalLogWrapper.ContractSalesDriverItemDetailMap.containsKey(con.Id)){
                salesDriverItemDetailList=approvalLogWrapper.ContractSalesDriverItemDetailMap.get(con.Id);				
            }
            System.debug(LoggingLevel.Debug,'salesDriverItemDetailList------>'+salesDriverItemDetailList);
            
            
            if(agreementType !=null && agreementType.Agreement_Approvals__r!=null && agreementType.Agreement_Approvals__r.size()>0){
                
                for(ECM_Agreement_Approval__c aa: agreementType.Agreement_Approvals__r){
                    system.debug(LoggingLevel.Debug,aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c+'low and upper '+aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c);
                    system.debug(LoggingLevel.Debug,con.RecordType.DeveloperName+'Extra==='+aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c);
                    if(con.RecordType.DeveloperName =='Outlet'){
                        if(aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c!=null){
                            system.debug(LoggingLevel.Debug, con.ECM_Territory__r.Sales_Area__c+'Extra contract= '+con.ECM_Territory__r.Region__c);
                            system.debug(LoggingLevel.Debug, aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c+'Extra Territory= '+aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c);
                            if(!(con.ECM_Territory__c !=null && 
                                 (con.ECM_Territory__r.Region__c == aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c 
                                  || con.ECM_Territory__r.Sales_Area__c==aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c)) ){
                                      continue;
                                  }                                
                        }  
                    }else if(con.RecordType.DeveloperName =='Group'){
                        if(aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c!=null){
                            continue;
                        }
                    }
                    system.debug(LoggingLevel.Debug,aa.ECM_Extra_Approval__r.ECM_Type__c+'aa== '+aa);
                    system.debug(LoggingLevel.Debug,'con =='+con.ECM_Overall_Investment_Figure__c);
                    
                    //ECM-5100-Start
                    Map<String,ECM_Approval_Log__c> parentApprovallogMap= new Map<String,ECM_Approval_Log__c>();
                    parentApprovallogMap=validateAutoApproval(con,false);
                    //ECM-5100-End
                    if(con.ECM_Overall_Investment_Figure__c !=null &&         
                       aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract' && //Added part of ECM-4565
                       aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && 
                       aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null){
                           //check Contract's overall investment amount in range of upper and lower limit of extra approval
                           if((con.ECM_Overall_Investment_Figure__c >=aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c && 
                               con.ECM_Overall_Investment_Figure__c <=aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c)){ 
                                   boolean temp = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                                       if(temp){
                                           //ECM-5100-Start
                                           if((con.ECM_Recalled__c && !parentApprovallogMap.containskey(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)) || !(con.ECM_Recalled__c)){
                                               //ECM-5100-End
                                               ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                               ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                               ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;//ECM-4639
                                               ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                               ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                               Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                               if(String.isNotEmpty(recordIdApprovalLog)){
                                                   ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                               }
                                               if(String.isNotEmpty(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == False){
                                                   ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                                   extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                                   if(aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c!=null){
                                                       ecmExtraApprovalLog.ECM_Approver_s_Position__c = aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;   
                                                   }
                                               }else if(aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == True && aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c != Null){
                                                   ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c;
                                                   ecmExtraApprovalLog.ECM_Approver_s_Position__c=DelegatedUser+' '+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;
                                                   extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                                               }
                                               ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                               if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                                   approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                               }else{
                                                   approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                               }
                                               if(con.ECM_Overall_Investment_Figure__c < aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c){ 
                                                   extraApprovalLowerLimit.add(aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c);
                                               }
                                               
                                           }
                                       }
                               }
                           
                       }
                    
                    //Added part of ECM-4565 & ECM-4564
                    else if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract Sales Driver' &&
                            salesDriverMap.containsKey(aa.ECM_Extra_Approval__r.ECM_Sales_Driver__c) &&
                            aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && 
                            aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null ){
                                Decimal totalInvestmentAmount = salesDriverMap.get(aa.ECM_Extra_Approval__r.ECM_Sales_Driver__c);
                                if(totalInvestmentAmount >=aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c &&
                                   totalInvestmentAmount <=aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c && 
                                   !nameOfExistingApprovalLogsSD.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)){
                                       ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                       ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                       ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;//ECM-4639
                                       ecmExtraApprovalLog.ECM_Sales_Driver__c = aa.ECM_Extra_Approval__r.ECM_Sales_Driver__c;
                                       ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                       ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                       Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                       if(String.isNotEmpty(recordIdApprovalLog)){
                                           ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                       }
                                       ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                       
                                       extraApprovalSDEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                       ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                       
                                       //ECM-4690
                                       if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                           approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                       }else{
                                           approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                       }
                                       //END of ECM-4690
                                   }
                            }
                    //End of ECM-4565 & ECM-4564
                    
                    //Added as a part of ECM-4639
                    else if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract Sales Driver Item' && 
                            aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null ){
                                for(ECM_Sales_Driver_Item_Detail__c sdid: salesDriverItemDetailList){
                                    if(sdid.ECM_Investment_Amount__c >= aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c){
                                        System.debug(LoggingLevel.Debug,'Investment amount--->'+sdid.ECM_Investment_Amount__c);
                                        System.debug(LoggingLevel.Debug,'Upper Limit --->'+aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c);
                                        createSDIDApprovalLog = true;
                                        break;
                                    }
                                }
                                System.debug(LoggingLevel.Debug,'createSDIDApprovalLog-->'+createSDIDApprovalLog);
                                if(createSDIDApprovalLog && 
                                   !nameOfExistingApprovalLogsSDID.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)){
                                       ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                       ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                       ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;//ECM-4639
                                       ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                       ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                       Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                       if(String.isNotEmpty(recordIdApprovalLog)){
                                           ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                       }
                                       ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                       
                                       extraApprovalSDIDEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                       ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                       createSDIDApprovalLog=false;
                                       //ECM-4690
                                       if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                           approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                       }else{
                                           approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                       }
                                       //END of ECM-4690
                                   }
                            }
                    //End of ECM-4639
                }
            }
        }
        //Added as part of ECM-4690
        System.debug(LoggingLevel.Debug,'approvalLogMap-->'+approvalLogMap);
        list<ECM_Approval_Log__c> ecmApprovalLogsListNew = new list<ECM_Approval_Log__c>();
        for(String str:approvalLogMap.keySet()){
            ECM_Approval_Log__c temp = new ECM_Approval_Log__c();
            String approvalLogType = '';
            for(ECM_Approval_Log__c ecmApprovalLog:approvalLogMap.get(str)){
                temp.ECM_Contract__c = ecmApprovalLog.ECM_Contract__c;
                temp.ECM_Type__c =  temp.ECM_Type__c == Null?ecmApprovalLog.ECM_Type__c:temp.ECM_Type__c+';'+ecmApprovalLog.ECM_Type__c;
                approvalLogType = String.isNotEmpty(approvalLogType)?approvalLogType+';'+ecmApprovalLog.ECM_Type__c:ecmApprovalLog.ECM_Type__c;
                temp.ECM_Status__c = ecmApprovalLog.ECM_Status__c;
                temp.ECM_No_of_Approval_Cycles__c = ecmApprovalLog.ECM_No_of_Approval_Cycles__c;
                temp.RecordTypeId = String.isNotEmpty(ecmApprovalLog.RecordTypeId)?ecmApprovalLog.RecordTypeId:Null;
                temp.Name = ecmApprovalLog.Name;
                if(ecmApprovalLog.ECM_Sales_Driver__c!=Null){
                    temp.ECM_Sales_Driver__c = ecmApprovalLog.ECM_Sales_Driver__c;
                }
                if(ecmApprovalLog.ECM_Approver_s_Position__c !=Null){
                    temp.ECM_Approver_s_Position__c = ecmApprovalLog.ECM_Approver_s_Position__c;
                }
            }
            if(!extraApprovalEmailsMap.containsKey(temp.ECM_Type__c)){
                extraApprovalEmailsMap.put(temp.ECM_Type__c,new Set<String>{temp.Name});
            }else{
                extraApprovalEmailsMap.get(temp.ECM_Type__c).add(temp.Name);
            }
            ecmApprovalLogsListNew.add(temp);
        }
        //End of ECM-4690
        system.debug(LoggingLevel.Debug,'@@ecmApprovalLogsListNew-->' +ecmApprovalLogsListNew);
        system.debug(LoggingLevel.Debug,'@@ecmApprovalLogsList' +ecmApprovalLogsList);
        system.debug(LoggingLevel.Debug,'@@extraApprovalEmails' +extraApprovalEmails);
        system.debug(LoggingLevel.Debug,'@@extraApprovalEmailsMap-->'+extraApprovalEmailsMap);
        if(ecmApprovalLogsListNew!=null && !ecmApprovalLogsListNew.isEmpty() && ecmApprovalLogsListNew.size()>0){
            isExtraApproval = true;
            approvalLogWrapper.ApprovalLogList.addAll(ecmApprovalLogsListNew);
            if(extraApprovalEmailsMap.size()>0){
                sendEmailToUser_Multi(extraApprovalEmailsMap,con,approvalLogWrapper);
            }
        }
        if((ecmApprovalLogsList==null || ecmApprovalLogsList.isEmpty() || ecmApprovalLogsList.size()==0) && 
           (extraApprovalLowerLimit==null || extraApprovalLowerLimit.isEmpty() || extraApprovalLowerLimit.size()==0)){
               ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
               ecmExtraApprovalLog.Name='Record not found';
               ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
               if(con !=null && con.ECM_Agreement_Type__c !=null){
                   ecmExtraApprovalLog.ECM_Contract__c = con.Id;
               }
               Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
               if(String.isNotEmpty(recordIdApprovalLog)){
                   ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
               }
               approvalLogWrapper.ApprovalLogList.add(ecmExtraApprovalLog);
           }
        return isExtraApproval;
    }
    
    //for AU
    public static boolean updatePrimaryApprovalLog_AU(Contract con,list<ECM_Approval_Log__c> existingApprovalLogs, ECM_ApprovalLogWrapper approvalLogWrapper){
        Boolean isExtraApproval =false;
        string DelegatedUser = System.Label.ECM_Delegated_Approver;
        list<ECM_Approval_Log__c>ecmApprovalLogsList = new list<ECM_Approval_Log__c>();
        set<String>extraApprovalEmails = new set<String>();
        list<Decimal>extraApprovalLowerLimit = new list<Decimal>();
        list<Decimal>extralowerPercentagelimit = new list<Decimal>();
        set<String>nameOfExistingApprovalLogs = new set<String>();
        Integer noofApprovalCount = 0;
        ECM_Approval_Log__c cuurentapprover= new ECM_Approval_Log__c();
        boolean findNextApprover=false;
        Boolean isEnS = (con.RecordTypeId == Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId()); //ECM-5816
        Decimal invTocompare;
        
        if(existingApprovalLogs!=null && !existingApprovalLogs.isEmpty() && existingApprovalLogs.size()>0){
            for(ECM_Approval_Log__c existingAl : existingApprovalLogs){
                nameOfExistingApprovalLogs.add(existingAl.Name);
                noofApprovalCount = integer.valueof(existingAl.ECM_No_of_Approval_Cycles__c);
            }
        }
        //ECM-5100-Start
        Map<String,ECM_Approval_Log__c> parentApprovallogMap= new Map<String,ECM_Approval_Log__c>();
        parentApprovallogMap=validateAutoApproval(con,true);
        system.debug(LoggingLevel.Debug,'parentApprovallogMap_primary-->'+parentApprovallogMap);
        //ECM-5100-End
        
        if(con !=null && con.ECM_Agreement_Type__c !=null){
            ECM_Contract_Type__c agreementType = approvalLogWrapper.agreementTypeMap.get(con.ECM_Agreement_Type__c);
            if(agreementType !=null && agreementType.Agreement_Approvals__r!=null && agreementType.Agreement_Approvals__r.size()>0){
                
                invTocompare = (isEnS)? con.ECM_Indicative_Total_Funding__c : con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c;
                for(ECM_Agreement_Approval__c aa: agreementType.Agreement_Approvals__r){
                    if((invTocompare !=null &&
                        aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && 
                        aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null) ||
                       (!isEnS && con.ECM_Hybrid_CustInvest_Total_PercentGP__c !=null &&
                        aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c !=null && 
                        aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c !=null)){
                            //check Contract's overall investment amount in range of upper and lower limit of extra approval
                            if(aa==agreementType.Agreement_Approvals__r[0]){
                                if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract'){ //Added part of ECM-4565
                                    if(( invTocompare >=aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c || invTocompare <=aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c)
                                       || ((con.ECM_Hybrid_CustInvest_Total_PercentGP__c >=aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c 
                                            || con.ECM_Hybrid_CustInvest_Total_PercentGP__c <=aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c) && !isEnS )){
                                                Boolean temp = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                                                    if(temp){
                                                        //ECM-5100-Start
                                                        if((con.ECM_Recalled__c && !parentApprovallogMap.containskey(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)) || !(con.ECM_Recalled__c)){
                                                            //ECM-5100-End
                                                            ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                                            ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                                            //ECM-4639 approval type = extra approver
                                                            ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;
                                                            ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                                            ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                                            
                                                            Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                                            if(String.isNotEmpty(recordIdApprovalLog)){
                                                                ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                                            }
                                                            //Start ECM-4194
                                                            if(String.isNotEmpty(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == False){
                                                                ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                                                extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                                                if(aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c!=null){
                                                                    ecmExtraApprovalLog.ECM_Approver_s_Position__c = aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;   
                                                                }
                                                            }else if(aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == True && aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c != Null){
                                                                ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c;
                                                                ecmExtraApprovalLog.ECM_Approver_s_Position__c=DelegatedUser+' '+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;
                                                                extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                                                            }
                                                            //End ECM-4194
                                                            ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                                        }else if(con.ECM_Recalled__c && parentApprovallogMap.containskey(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)){
                                                            findNextApprover=true;
                                                            cuurentapprover=parentApprovallogMap.get(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                                        }
                                                    }
                                            }
                                }
                            }
                            //Check Contract's overall investment amount is lower than lower limit of extra approval
                            if(invTocompare < aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c){
                                extraApprovalLowerLimit.add(aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c);
                            }
                            if(!isEnS && con.ECM_Hybrid_CustInvest_Total_PercentGP__c < aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c){
                                extralowerPercentagelimit.add(aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c);
                            }
                            
                        }
                }
                if(findNextApprover){
                    existingApprovalLogs.add(cuurentapprover);
                    ECM_ApprovalLogUtility.updateExtraApprovalLog_AU(con,existingApprovalLogs,cuurentapprover,approvalLogWrapper);
                }
            }
        }
        if(ecmApprovalLogsList!=null && !ecmApprovalLogsList.isEmpty() && ecmApprovalLogsList.size()>0){
            isExtraApproval = true;
            approvalLogWrapper.ApprovalLogList.addAll(ecmApprovalLogsList);
            if(extraApprovalEmails!=null && !extraApprovalEmails.isEmpty() && extraApprovalEmails.size()>0){
                sendEmailToUser(extraApprovalEmails,con,approvalLogWrapper);
            }
        }
        if((extraApprovalLowerLimit!=null && !extraApprovalLowerLimit.isEmpty() && extraApprovalLowerLimit.size()>0) &&
           (!isEnS && extralowerPercentagelimit!=null && !extralowerPercentagelimit.isEmpty() && extralowerPercentagelimit.size()>0)){
               extraApprovalLowerLimit.sort();
               extralowerPercentagelimit.sort();
               if(invTocompare < extraApprovalLowerLimit[0] && 
                  con.ECM_Hybrid_CustInvest_Total_PercentGP__c <extralowerPercentagelimit[0]) {
                      // Commented these lines regarding ECM-4183 - INC20139564
                      /*con.status='Activated - Approved';
isExtraApproval = false;*/
                      //End of comment
                  }
           }
        
        if((ecmApprovalLogsList==null || ecmApprovalLogsList.isEmpty() || ecmApprovalLogsList.size()==0) && 
           (extraApprovalLowerLimit==null || extraApprovalLowerLimit.isEmpty() || extraApprovalLowerLimit.size()==0) &&
           (!isEnS && (extralowerPercentagelimit==null || extralowerPercentagelimit.isEmpty() || extralowerPercentagelimit.size()==0))){
               ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
               ecmExtraApprovalLog.Name='Record not found';
               ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
               if(con !=null && con.ECM_Agreement_Type__c !=null){
                   ecmExtraApprovalLog.ECM_Contract__c = con.Id;
               }
               Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
               if(String.isNotEmpty(recordIdApprovalLog)){
                   ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
               }
               approvalLogWrapper.ApprovalLogList.add(ecmExtraApprovalLog);
           }
        return isExtraApproval;
    }
    
    //for AU's Extra approvers
    public static boolean updateExtraApprovalLog_AU(Contract con,list<ECM_Approval_Log__c> existingApprovalLogs,ECM_Approval_Log__c currentApprover, ECM_ApprovalLogWrapper approvalLogWrapper){
        Boolean isExtraApproval =false;
        string DelegatedUser = System.Label.ECM_Delegated_Approver;
        list<ECM_Approval_Log__c>ecmApprovalLogsList = new list<ECM_Approval_Log__c>();
        set<String>extraApprovalEmails = new set<String>();
        //list<Decimal>extraApprovalLowerLimit = new list<Decimal>();
        //list<Decimal>extralowerPercentagelimit = new list<Decimal>();
        set<String>nameOfExistingApprovalLogs = new set<String>();
        Integer noofApprovalCount = 0;
        ECM_Agreement_Approval__c preAA = new ECM_Agreement_Approval__c();
        ECM_Approval_Log__c cuurentapprover= new ECM_Approval_Log__c();
        boolean findNextApprover=false;
        Boolean isEnS = (con.RecordTypeId == Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId()); //ECM-5816
        Decimal invTocompare;
        
        if(existingApprovalLogs!=null && !existingApprovalLogs.isEmpty() && existingApprovalLogs.size()>0){
            for(ECM_Approval_Log__c existingAl : existingApprovalLogs){
                nameOfExistingApprovalLogs.add(existingAl.Name);
                noofApprovalCount = integer.valueof(existingAl.ECM_No_of_Approval_Cycles__c);
            }
        }
        //ECM-5100-Start
        Map<String,ECM_Approval_Log__c> parentApprovallogMap= new Map<String,ECM_Approval_Log__c>();
        parentApprovallogMap=validateAutoApproval(con,true);
        //ECM-5100-End
        
        if(con !=null && con.ECM_Agreement_Type__c !=null && String.isNotEmpty(currentApprover.Name)){
            
            ECM_Contract_Type__c agreementType = approvalLogWrapper.agreementTypeMap.get(con.ECM_Agreement_Type__c);
            if(agreementType !=null && agreementType.Agreement_Approvals__r!=null && agreementType.Agreement_Approvals__r.size()>0){
                
                invTocompare = (isEnS)? con.ECM_Indicative_Total_Funding__c : con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c;
                for(ECM_Agreement_Approval__c aa: agreementType.Agreement_Approvals__r){
                    
                    if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract'){//Added as a part of ECM-4565
                        if((invTocompare !=null && aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null)
                           || (!isEnS && con.ECM_Hybrid_CustInvest_Total_PercentGP__c !=null && aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c !=null 
                               && aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c !=null)){
                                   //Start ECM-4194
                                   if(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c.equalsIgnoreCase(currentApprover.Name) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == False){
                                       preAA = aa;
                                   }else if(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c.equalsIgnoreCase(currentApprover.Name) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == True){
                                       preAA = aa;
                                   }
                                   //End of ECM-4194
                               }
                    }
                }
                if(preAA !=null){
                    for(ECM_Agreement_Approval__c aa: agreementType.Agreement_Approvals__r){
                        if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract'){//Added as a part of ECM-4565
                            
                            if((invTocompare !=null && aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null)
                               || (!isEnS && con.ECM_Hybrid_CustInvest_Total_PercentGP__c !=null && aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c !=null
                                   && aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c !=null)){
                                       
                                       if(aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c >= preAA.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c ||
                                          (!isEnS && aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c >= preAA.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c)){
                                              
                                              //check Contract's overall investment amount in range of upper and lower limit of extra approval
                                              if((invTocompare >=aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c && invTocompare <= aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c)
                                                 || (!isEnS && con.ECM_Hybrid_CustInvest_Total_PercentGP__c >= aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Lower_Limit__c
                                                     && con.ECM_Hybrid_CustInvest_Total_PercentGP__c <= aa.ECM_Extra_Approval__r.ECM_Re_Investment_Rate_Upper_Limit__c)){
                                                         Boolean temp = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                                                             system.debug(LoggingLevel.Debug,'nameOfExistingApprovalLogs-->'+nameOfExistingApprovalLogs);
                                                         
                                                         if(temp){
                                                             system.debug(LoggingLevel.Debug,'Extra_approval_log_temp-->'+temp);
                                                             //ECM-5100-Start
                                                             if((con.ECM_Recalled__c && !parentApprovallogMap.containskey(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)) || !(con.ECM_Recalled__c)){
                                                                 system.debug(LoggingLevel.Debug,'recalled-->'+parentApprovallogMap);
                                                                 //ECM-5100-End
                                                                 ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                                                 ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                                                 ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                                                 ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                                                 ecmExtraApprovalLog.ECM_Type__c = aa.ECM_Extra_Approval__r.ECM_Type__c;
                                                                 Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                                                 if(String.isNotEmpty(recordIdApprovalLog)){
                                                                     ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                                                 }
                                                                 //Start ECM-4194
                                                                 if(String.isNotEmpty(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == False){
                                                                     ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                                                     extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                                                     if(aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c!=null){
                                                                         ecmExtraApprovalLog.ECM_Approver_s_Position__c = aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;   
                                                                     }
                                                                 }else if(aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == True && aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c != Null){
                                                                     ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c;
                                                                     ecmExtraApprovalLog.ECM_Approver_s_Position__c=DelegatedUser+' '+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;
                                                                     extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                                                                 }
                                                                 //End ECM-4194
                                                                 ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                                                 break;
                                                             }else if(con.ECM_Recalled__c && parentApprovallogMap.containskey(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)){
                                                                 findNextApprover=true;
                                                                 cuurentapprover=parentApprovallogMap.get(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                                             }
                                                         }
                                                     }
                                          }
                                   }
                        }
                    }
                }
            }
        }
        
        if(ecmApprovalLogsList!=null && !ecmApprovalLogsList.isEmpty() && ecmApprovalLogsList.size()>0){
            isExtraApproval = true;
            approvalLogWrapper.ApprovalLogList.addAll(ecmApprovalLogsList);
            if(extraApprovalEmails!=null && !extraApprovalEmails.isEmpty() && extraApprovalEmails.size()>0){
                sendEmailToUser(extraApprovalEmails,con,approvalLogWrapper);
            }
        }
        system.debug(LoggingLevel.Debug,'findNextApprover-->'+findNextApprover);
        if(findNextApprover){
            existingApprovalLogs.add(cuurentapprover);
            ECM_ApprovalLogUtility.updateExtraApprovalLog_AU(con,existingApprovalLogs,cuurentapprover,approvalLogWrapper);
        }
        return isExtraApproval;
    }
    
    Public static void sendEmailToUser(set<String>recipentUserEmails, Contract ContractRecord, ECM_ApprovalLogWrapper approvalLogWrapper){
        system.debug(LoggingLevel.Debug,'recipentUserEmails-->'+recipentUserEmails);     
        system.debug(LoggingLevel.Debug,'ContractRecord-->'+ContractRecord);
        Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
        list<String>toAddresses = new list<String>(recipentUserEmails);
        system.debug(LoggingLevel.Debug,'toAddresses-->'+toAddresses);
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Map<String,EmailTemplate> emailTemplateMap = new  Map<String,EmailTemplate>();
        try{
            Market_Setting__c  marketObj = new Market_Setting__c();
            system.debug(LoggingLevel.Debug,'marketObj-->'+marketObj);
            if(approvalLogWrapper.marketSettingMap.containsKey(ContractRecord.Account.Country__c)){
                marketObj = approvalLogWrapper.marketSettingMap.get(ContractRecord.Account.Country__c);						
            }
            
            if(approvalLogWrapper.emailTemplateMap.containsKey(marketObj.ECM_Contract_Approval_Template__c)){
                emailTemplateMap.put(approvalLogWrapper.emailTemplateMap.get(marketObj.ECM_Contract_Approval_Template__c).DeveloperName,approvalLogWrapper.emailTemplateMap.get(marketObj.ECM_Contract_Approval_Template__c));
            }
            
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();   
            blob excel = blob.valueOf(ECM_contractexcel.generateExcel(ContractRecord.Id));
            
            system.debug(LoggingLevel.Debug,'Contract Details---->'+excel);
            attach.setBody(excel); 
            attach.setFileName('Contract Details.xls');
            
            email.setTargetObjectId(userinfo.getuserid());
            email.setTreatTargetObjectAsRecipient(false);
            email.setWhatId(ContractRecord.Id);
            email.setOrgWideEmailAddressId(approvalLogWrapper.OrgWideEmailAddressId);
            email.setTemplateID(emailTemplateMap.get(marketObj.ECM_Contract_Approval_Template__c).Id);
            email.setSaveAsActivity(false);
            email.setReplyTo(Label.ECM_ContractApproverManagerEmailId);
            email.setToAddresses(toAddresses);
            //Start of ECM-5090
            List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();
            allAttachments.add(attach);
            Messaging.EmailFileAttachment approvalMailAttachment = getApprovalMailAttachment(contractRecord.Id,approvalLogWrapper);
            system.debug(LoggingLevel.Debug,'approvalMailAttachment@'+approvalMailAttachment);
            if(approvalMailAttachment != null){
                allAttachments.add(approvalMailAttachment);
            }
            //end of ECM-5090
            //ECM-4644
            //Modified from ECM-5090
            if(marketObj.ECM_Contract_pdf_to_Approval_Mails__c){
                String Status = 'Draft';
                Messaging.EmailFileAttachment attachPdf = contractPdf(ContractRecord,Status,approvalLogWrapper);
                if(attachPdf !=null){
                    allAttachments.add(attachPdf);
                }
                
            }
            //ECM-5090
            email.setFileAttachments(allAttachments);
            system.debug(LoggingLevel.Debug,'email-->'+email);
            //Messaging.SingleEmailMessage[] emailsinglemsg = new Messaging.SingleEmailMessage[]{email};
            mails.add(email);
            system.debug(LoggingLevel.Debug,'email list-->'+mails);
            if(mails.size()>0){
                approvalLogWrapper.multiuserEmailList.addAll(mails);
            }
        }catch(Exception ex){
            system.debug(LoggingLevel.Debug,'Error Exception'+ex.getStackTraceString());
        }       
    }
    
    
    /*
    * Description	:	ECM-4690 Approval Email consolidation: Contract approval+ SD+SD Item Approval mails
    * Developer	:	Saurav Prasad
    * Date			:	12/08/2021
    * Method		:	sendEmailToUser_Multi
    * return		:	void
    * params		:	map<String,set<String>,Contract
    * 
    */
    Public static void sendEmailToUser_Multi(Map<String,Set<String>> recipentUserEmails, Contract conRec, ECM_ApprovalLogWrapper approvalLogWrapper){
        system.debug(LoggingLevel.Debug,'recipentUserEmails--> '+recipentUserEmails);     
        system.debug(LoggingLevel.Debug,'ContractRecord--> '+conRec);
        
        //151029
        String crgRecordTypeId = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByDeveloperName().get(System.Label.CRG_RecordType_DevName).getRecordTypeId();
        
        List<Messaging.SingleEmailMessage> mailS = new List<Messaging.SingleEmailMessage>();
        Map<String,EmailTemplate> emailTemplateMap = new  Map<String,EmailTemplate>();
        Market_Setting__c  marketObj = new Market_Setting__c();
        //ECM-6032
        String objName = '%'+conRec.Id.getsobjecttype()+'%';
        //148916 - made changes in query to check with record type
        String recordTypeName = '%'+conRec.RecordType.DeveloperName+'%';
        Map<String, String> mailTemplateTrigger = new Map<String, String>();
        for(ECM_Email_Template_Setting__mdt EmailTemp : [SELECT Id,Masterlabel,DeveloperName,ECM_Related_to_Object__c,ECM_Type__c,ECM_Record_Type__c  
                                                         FROM ECM_Email_Template_Setting__mdt 
                                                         WHERE ECM_Related_to_Object__c LIKE:objName AND ECM_Record_Type__c LIKE: recordTypeName])
        {
            mailTemplateTrigger.put(EmailTemp.ECM_Type__c,EmailTemp.Masterlabel);
        }
        try{
            //148916 - map contains check
            if(approvalLogWrapper.marketSettingMap.containsKey(conRec.Account.Country__c) && !mailTemplateTrigger.containsKey('Contract')){
                marketObj = approvalLogWrapper.marketSettingMap.get(conRec.Account.Country__c);						
                mailTemplateTrigger.put('Contract',marketObj.ECM_Contract_Approval_Template__c);
            }
            system.debug(LoggingLevel.Debug,'emailTemplateMap-->'+emailTemplateMap); //Template name based on Country
            //Modified for ECM-5090
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment(); 
            //151029
            blob excel = conRec.RecordTypeId != crgRecordTypeId ?blob.valueOf(ECM_contractexcel.generateExcel(conRec.Id)):blob.valueOf('Test Data');
            system.debug(LoggingLevel.Debug,'Contract Details---->'+excel);
            attach.setBody(excel);
            attach.setFileName('Contract Details.xls');
            
            Messaging.EmailFileAttachment approvalMailAttachment = conRec.RecordTypeId != crgRecordTypeId?
                getApprovalMailAttachment(conRec.Id,approvalLogWrapper):NULL;
            
            List<Messaging.EmailFileAttachment> approvalMailAttachmentList = conRec.RecordTypeId == crgRecordTypeId?//151377
                getApprovalMailAttachmentCRG(conRec.Id):new List<Messaging.EmailFileAttachment>();
            
                            
            Messaging.EmailFileAttachment attachPdf = new Messaging.EmailFileAttachment();
            //151029
            if(!conRec.ECM_Amended__c && marketObj.ECM_Contract_pdf_to_Approval_Mails__c && conRec.RecordTypeId != crgRecordTypeId){
                String status = 'Draft';
                attachPdf = contractPdf(conRec, status, approvalLogWrapper);
            }
            //151029
            if(conRec.ECM_Amended__c && conRec.RecordTypeId != crgRecordTypeId){
                attachPdf = addendumPdf(conRec, approvalLogWrapper, null);
            }
            List<Messaging.EmailFileAttachment> parentAttch = new List<Messaging.EmailFileAttachment>();
            //151029
            if(conRec.ECM_Amended__c && conRec.ECM_Parent_Contract__c != null &&
               marketObj.ECM_Contract_pdf_to_Approval_Mails__c && conRec.RecordTypeId != crgRecordTypeId){
                parentAttch = fetchParentDocs(conRec.ECM_Parent_Contract__c);
            }
            //End of ECM-5090
            
            for(String str:recipentUserEmails.keySet()){ 
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                list<String>toAddresses = new list<String>(recipentUserEmails.get(str));
                system.debug(LoggingLevel.Debug,'toAddresses-->'+toAddresses);
                email.setTargetObjectId(userinfo.getuserid());
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(conRec.Id);
                email.setOrgWideEmailAddressId(approvalLogWrapper.OrgWideEmailAddressId);
                //email.setTemplateID(approvalLogWrapper.emailTemplateMap.get(marketObj.ECM_Contract_Approval_Template__c).Id);
                email.setTemplateID(approvalLogWrapper.emailTemplateMap.get(mailTemplateTrigger.get(str)).Id);
                email.setSaveAsActivity(false);
                email.setReplyTo(Label.ECM_ContractApproverManagerEmailId);
                email.setToAddresses(toAddresses);
                
                //Start of ECM-5090
                List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();
                //151029
                if(conRec.RecordTypeId != crgRecordTypeId){
                    allAttachments.add(attach);
                }
                if(approvalMailAttachment != null){
                    allAttachments.add(approvalMailAttachment);
                }
                else if(!approvalMailAttachmentList.isEmpty()){//151377
                	allAttachments.addAll(approvalMailAttachmentList);
            	}

                //end of ECM-5090
                //ECM-4644
                //Modified from ECM-5090
                //if(marketObj.ECM_Contract_pdf_to_Approval_Mails__c){ - commented for ECM-6264
                if(attachPdf.body != null ){
                    allAttachments.add(attachPdf);
                }
                if(!parentAttch.isEmpty()){
                    allAttachments.addAll(parentAttch); 
                }
                //ECM-5090
                //151029
                if(!allAttachments.isEmpty()){
                    email.setFileAttachments(allAttachments);
                }
                system.debug(LoggingLevel.Debug,'email-->'+email);
                mails.add(email);
                
            }
            system.debug(LoggingLevel.Debug,'email list-->'+mails);
            if(mails.size()>0){   
                approvalLogWrapper.multiuserEmailList.addAll(mails);
            }
        }catch(Exception ex){
            system.debug(LoggingLevel.Debug,'Error Exception'+ex.getStackTraceString());
        }       
    }
    
    /*
    * Description	:	ECM-4644 Attach Contract PDF to Approvals mail_GLO
    * Developer		:	Keshav
    * Date			:	13/01/2022
    * Method		:	contractPdf : Generates contract pdf for contract approval and post contract approval mails
    * return		:	Messaging.EmailFileAttachment
    * params		:	Contract,String
    *
    */
    public static Messaging.EmailFileAttachment contractPdf(Contract ContractRecord,String Status, ECM_ApprovalLogWrapper approvalWrapper){
        Messaging.EmailFileAttachment attachPdf = new Messaging.EmailFileAttachment();
        PageReference pref = page.ECm_PDF_generation;
        pref.getParameters().put('Id',ContractRecord.Id);
        pref.getParameters().put('isApproval','false');
        pref.getParameters().put('addendumId','');
        pref.setRedirect(true);
        Blob b;
        
        //ECM-5649
        if(trigger.isExecuting){
            if(approvalWrapper!=null){
                Map<Id,ContentDocumentLink> contentDocumentMap = approvalWrapper.contentDocumentLinkMap;
                system.debug(LoggingLevel.Debug,'primaryApprovalLogMap1-->'+approvalWrapper.primaryApprovalLogMap.get(ContractRecord.Id));
                system.debug(LoggingLevel.Debug,'primaryApprovalLogMap2-->'+contentDocumentMap.keySet());
                
                if(approvalWrapper.primaryApprovalLogMap.containsKey(ContractRecord.Id) && contentDocumentMap.containsKey(approvalWrapper.primaryApprovalLogMap.get(ContractRecord.Id))){
                    ContentDocumentLink conDoc = contentDocumentMap.get(approvalWrapper.primaryApprovalLogMap.get(ContractRecord.Id));
                    b = conDoc.ContentDocument.LatestPublishedVersion.VersionData;
                }
            }  
        }
        //ECM-5649
        else{
            try{
                b = !test.isRunningTest()?pref.getContent():blob.valueOf('Unit.Test');
            }
            catch(Exception ex){//ECM-6264
                System.debug(LoggingLevel.Debug,'@@@method:contractPdf\nException in PDF generation: ' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
        }
        if(Status=='Draft'){
            attachPdf.setFileName(system.label.ECM_Contract_Approval_Email_PDF_Name);
        }else if(Status=='Approved'){
            attachPdf.setFileName(system.label.ECM_Attachment_File_Name);
        }else{
            attachPdf.setFileName(system.label.ECM_Contract_Approval_Email_PDF_Name);
        }
        if(b != null){
            attachPdf.setBody(b);
        }
        return attachPdf;		
    }
    
    /*
    * Description	:	ECM-5090 - FastTrack_Logic for Approval Mail Attachment_Glo
    * Developer		:	Saurav Prasad
    * Date			:	21/01/2022
    * Method		:	getApprovalMailAttachment : retrives the attachment from contract which is of Content Type:Approval Mail Attachment
    * return		:	Messaging.EmailFileAttachment
    * params		:	String
    * 
    */
    public static Messaging.EmailFileAttachment getApprovalMailAttachment(String conId,ECM_ApprovalLogWrapper approvalLogWrapper){ 
        ContentDocumentLink existConDoc= new ContentDocumentLink();		
        if(approvalLogWrapper!=null && approvalLogWrapper.ContentDocumentLinkMap.containsKey(conId)){
            existConDoc=approvalLogWrapper.ContentDocumentLinkMap.get(conId);
            Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
            attach.setFileName(existConDoc.ContentDocument.Title+'.'+existConDoc.ContentDocument.FileExtension);
            attach.setBody(existConDoc.ContentDocument.LatestPublishedVersion.VersionData);
            return attach;				 
        }else{
            for(ContentDocumentLink  ConDoc : 
                [SELECT Id, LinkedEntityId, ContentDocumentId, 
                 ContentDocument.FileExtension, ContentDocument.Title,
                 ContentDocument.LatestPublishedVersion.Content_Type__c,
                 ContentDocument.LatestPublishedVersion.VersionData
                 FROM ContentDocumentLink 
                 WHERE LinkedEntityId =: conId]){
                     if(Label.ECM_ContentTypeApprovalMail.contains(ConDoc.ContentDocument.LatestPublishedVersion.Content_Type__c)){ 
                         Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                         attach.setFileName(ConDoc.ContentDocument.Title+'.'+ConDoc.ContentDocument.FileExtension);
                         attach.setBody(ConDoc.ContentDocument.LatestPublishedVersion.VersionData);
                         return attach;
                     }
                 }
        }
        return null;
    }
    
    /*
    * Description	:	151377
    * Developer		:	Shivam Chauhan
    * Date			:	21/03/2024
    * Method		:	getApprovalMailAttachmentCRG : retrives the list of attachment from contract which is of Content Type:Approval Mail Attachment
    * return		:	List<Messaging.EmailFileAttachment>
    * params		:	String
    * 
    */
      public static List<Messaging.EmailFileAttachment> getApprovalMailAttachmentCRG(String conId){
        List<Messaging.EmailFileAttachment> attachList = new List<Messaging.EmailFileAttachment>();
        for(ContentDocumentLink  conDoc : 
                [SELECT Id, LinkedEntityId, ContentDocumentId, 
                 ContentDocument.FileExtension, ContentDocument.Title,
                 ContentDocument.LatestPublishedVersion.Content_Type__c,
                 ContentDocument.LatestPublishedVersion.VersionData
                 FROM ContentDocumentLink 
                 WHERE LinkedEntityId =: conId]){
                     if(Label.ECM_ContentTypeApprovalMail.contains(conDoc.ContentDocument.LatestPublishedVersion.Content_Type__c)){ 
                         Messaging.EmailFileAttachment attach = new Messaging.EmailFileAttachment();
                         attach.setFileName(conDoc.ContentDocument.Title+'.'+conDoc.ContentDocument.FileExtension);
                         attach.setBody(conDoc.ContentDocument.LatestPublishedVersion.VersionData);
                         attachList.add(attach);
                     }
                 }
        return attachList;
    }
    
    public static Map<String,ECM_Approval_Log__c> validateAutoApproval(contract con,boolean isAustralianContract){ 
        Map<String,ECM_Approval_Log__c> parentApprovallogMap= new Map<String,ECM_Approval_Log__c>();
        boolean isSDItemValid=true;
        boolean isproductValid=true;
        boolean isContractvalid=false;
        Boolean isEnS = (con.RecordTypeId == Contract.sObjectType.getDescribe().getRecordTypeInfosByName().get('E&S').getRecordTypeId()); //ECM-5816
        Map<Id,ECM_Contract_Item__c> parentContractMap= new Map<Id,ECM_Contract_Item__c>();
        Map<Id,ECM_Contract_Item__c> childContractMap= new Map<Id,ECM_Contract_Item__c>();
        Map<Id,ECM_Sales_Driver_Item__c> parentSDItemMap= new Map<Id,ECM_Sales_Driver_Item__c>();
        Map<Id,ECM_Sales_Driver_Item__c> childSDItemMap= new Map<Id,ECM_Sales_Driver_Item__c>();
        
        List<Market_Setting__c> marketList = [SELECT Id,Enable_Auto_Approvals__c,Geography__c FROM Market_Setting__c WHERE Geography__c = : con.Account.country__c];
        //ECM-5100-Start
        if(!marketList.isEmpty() && marketList[0].Enable_Auto_Approvals__c && con.ECM_Recalled__c && con.ECM_Parent_Contract__c!=null){
            
            if((con.StartDate == con.ECM_Parent_Contract__r.StartDate) && (con.ECM_Duration__c == con.ECM_Parent_Contract__r.ECM_Duration__c)){
                
                if(isAustralianContract){
                    if(!isEnS && (con.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c <= con.ECM_Parent_Contract__r.ECM_Hybrid_Upfront_Payment_Loan_Over_Ter__c) && (con.ECM_Hybrid_CustInvest_Total_PercentGP__c <= con.ECM_Parent_Contract__r.ECM_Hybrid_CustInvest_Total_PercentGP__c)){
                        isContractvalid=true;
                    }
                    else if(isEnS && con.ECM_Indicative_Total_Funding__c <= con.ECM_Parent_Contract__r.ECM_Indicative_Total_Funding__c){
                        isContractvalid=true;
                    }
                }else{
                    if((con.ECM_of_the_total_investment_vs_NSV__c <= con.ECM_Parent_Contract__r.ECM_of_the_total_investment_vs_NSV__c)&&(con.ECM_Overall_investments__c <= con.ECM_Parent_Contract__r.ECM_Overall_investments__c)){
                        isContractvalid=true;
                    }
                }
            }
            
        }
        
        if(isContractvalid){
            
            for(ECM_Contract_Item__c conItem: [select id,Name,ECM_Product__c,ECM_Investment__c,ECM_Contract__c,ECM_Contract__r.ECM_Recalled__c from ECM_Contract_Item__c where (ECM_Contract__c =:con.Id or ECM_Contract__c =:con.ECM_Parent_Contract__c)]){
                if(!conItem.ECM_Contract__r.ECM_Recalled__c){
                    parentContractMap.put(conItem.ECM_Product__c,conItem);
                }else{
                    childContractMap.put(conItem.ECM_Product__c,conItem);
                }
            }
            
            if(childContractMap.size()==parentContractMap.size()){
                for(Id productId:childContractMap.keySet()){
                    /*
if(parentContractMap.containsKey(productId)){
ECM_Contract_Item__c childItem=childContractMap.get(productId);
ECM_Contract_Item__c parentItem=parentContractMap.get(productId);

if((parentItem.ECM_Investment__c!=null && childItem.ECM_Investment__c!=null) && !(parentItem.ECM_Investment__c>=childItem.ECM_Investment__c)){
isproductValid=false;
break;
}									
}
*/
                    if(!(parentContractMap.containsKey(productId))){
                        isproductValid=false;
                        break;
                    }
                    /*
else{
isproductValid=false;
break;
}
*/
                }
            }else{
                isproductValid=false;
            }
            
        }
        
        if(isproductValid){
            
            for(ECM_Sales_Driver_Item__c sDItem: [select id,Name,ECM_Sales_Driver__c,ECM_1st_Prepayment_Amount__c,ECM_Total_Investment_Amount__c,ECM_Payment_Frequency__c,ECM_Payment_Frequency_Type__c,Contract__c,Contract__r.ECM_Recalled__c from ECM_Sales_Driver_Item__c where (Contract__c =:con.Id or Contract__c =:con.ECM_Parent_Contract__c) /*and ECM_Payment_Frequency_Type__c like '%Prepayment%'*/]){
                if(!sDItem.Contract__r.ECM_Recalled__c){
                    parentSDItemMap.put(sDItem.ECM_Sales_Driver__c,sDItem);
                }else{
                    childSDItemMap.put(sDItem.ECM_Sales_Driver__c,sDItem);
                }
            }
            
            if(childSDItemMap.size()==parentSDItemMap.size()){
                for(Id sdId:childSDItemMap.keySet()){
                    if(parentSDItemMap.containsKey(sdId)){
                        ECM_Sales_Driver_Item__c childItem=childSDItemMap.get(sdId);
                        ECM_Sales_Driver_Item__c parentItem=parentSDItemMap.get(sdId);
                        /*
if(((parentItem.ECM_Total_Investment_Amount__c!=null && childItem.ECM_Total_Investment_Amount__c!=null ) && (!(parentItem.ECM_Total_Investment_Amount__c>=childItem.ECM_Total_Investment_Amount__c))) && (parentItem.ECM_Payment_Frequency_Type__c==childItem.ECM_Payment_Frequency_Type__c)){
isSDItemValid=false;
break;
}
*/
                        //Start of ECM-5486
                        if((parentItem.ECM_Total_Investment_Amount__c!=null && childItem.ECM_Total_Investment_Amount__c!=null ) && (parentItem.ECM_1st_Prepayment_Amount__c!=null && childItem.ECM_1st_Prepayment_Amount__c!=null ) && (parentItem.ECM_Payment_Frequency_Type__c==childItem.ECM_Payment_Frequency_Type__c) && (!(parentItem.ECM_1st_Prepayment_Amount__c >=childItem.ECM_1st_Prepayment_Amount__c ))){
                            isSDItemValid=false;
                            break;
                        }
                        //End of ECM-5486
                    }else{
                        isSDItemValid=false;
                        break;
                    }
                }
            }else{
                isSDItemValid=false;
            }			
            
        }
        
        if(isContractvalid && isproductValid && isSDItemValid){	                
            list<ECM_Approval_Log__c> ecmApprovalLogs = [Select Id, Name, ECM_Status__c, ECM_Comment__c, ECM_Approver_s_Position__c,
                                                         recordTypeId,recordType.Name,ECM_Time_Date_Log__c,ECM_No_of_Approval_Cycles__c,
                                                         ECM_Sales_Driver__c,ECM_Type__c
                                                         From ECM_Approval_Log__c 
                                                         Where ECM_Contract__c=:con.ECM_Parent_Contract__c and ECM_Status__c='Approved'  order by createdDate DESC];
            
            for(ECM_Approval_Log__c currentlog:ecmApprovalLogs){
                
                parentApprovallogMap.put(currentlog.Name,currentlog);
                
            }	
            
        }
        return parentApprovallogMap;
    }
    
    /*
    * Description	:	ECM-5358: Contract rejection email to Sales Rep_SFDC_GLO
    * Developer		:	Saurav Prasad
    * Date			:	24/03/2022
    * Method		:	sendRejectionEmailToSalesRep
    * return		:	void
    * params		:	Id, Contract
    * 
    */ 
    public static void sendRejectionEmailToSalesRep(Id approvalLogId, Contract conRec, ECM_ApprovalLogWrapper approvalLogWrapper){
        try{
            
            if(approvalLogWrapper.marketSettingMap.containsKey(conRec.Account.Country__c) && approvalLogWrapper.marketSettingMap.get(conRec.Account.Country__c).ECM_Rejection_Email_to_Sales_Rep__c){
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                email.setToAddresses(new List<String>{conRec.Owner.Email});
                email.setTargetObjectId(userinfo.getuserid());
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(approvalLogId);
                email.setOrgWideEmailAddressId(approvalLogWrapper.OrgWideEmailAddressId);
                email.setTemplateID(approvalLogWrapper.rejectionEmailTemplateId);
                email.setSaveAsActivity(false);
                email.setReplyTo(Label.ECM_ContractApproverManagerEmailId);
                
                approvalLogWrapper.multiuserEmailList.add(email);
                
                //Messaging.SendEmailResult[] r = Messaging.sendEmail(new List<Messaging.SingleEmailMessage>{email});              }
            }
        }catch(Exception e){
            system.debug(LoggingLevel.Debug,'Exception Caught in method:sendRejectionEmailToSalesRep for class:ECM_ApprovalLogUtility at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    /*
    * @description : Method to handle the extra approval process for Addendum for EU 
    * @param : Contract, list<ECM_Approval_Log__c> , ECM_ApprovalLogWrapper
    * @story : ECM-5867,ECM-5905
    * @return : Boolean
    */
    public static boolean updatePrimaryApprovalLogAddendum(Contract con,list<ECM_Approval_Log__c> existingApprovalLogs, ECM_ApprovalLogWrapper approvalLogWrapper){
        Boolean isExtraApproval =false;
        string DelegatedUser = System.Label.ECM_Delegated_Approver;
        list<ECM_Approval_Log__c>ecmApprovalLogsList = new list<ECM_Approval_Log__c>();
        set<String>extraApprovalEmails = new set<String>();
        list<Decimal>extraApprovalLowerLimit = new list<Decimal>();
        set<String>nameOfExistingApprovalLogs ;
        Integer noofApprovalCount = 0;
        
        map<String,Decimal> salesDriverMap = new map<String,Decimal>();
        set<String> extraApprovalSDEmails = new set<String>();
        set<String>nameOfExistingApprovalLogsSD;
        
        List<ECM_Sales_Driver_Item_Detail__c> salesDriverItemDetailList = new List<ECM_Sales_Driver_Item_Detail__c>();
        set<String> nameOfExistingApprovalLogsSDID;
        set<String> extraApprovalSDIDEmails = new set<String>();
        Boolean createSDIDApprovalLog = false;
        
        Map<String,set<string>> nameOfExistingApprovalLogsMap = new Map<String,set<string>>();
        Map<String,List<ECM_Approval_Log__c>> approvalLogMap = new map<string,List<ECM_Approval_Log__c>>();
        Map<String,set<String>> extraApprovalEmailsMap = new Map<String,set<String>>();
        
        //ECM-6069
        set<String> conEAEmails = new Set<String>();
        set<String> sdEAEmails = new Set<String>();
        set<String> sdidEAEmails = new Set<String>();
        
        if(existingApprovalLogs!=null && !existingApprovalLogs.isEmpty() && existingApprovalLogs.size()>0){
            for(ECM_Approval_Log__c existingAl : existingApprovalLogs){
                List<String> typeList = existingAl.ECM_Type__c != NULL?existingAl.ECM_Type__c.split(';'):new List<String>();
                for(Integer i=0;i<typeList.size();i++){
                    if(!nameOfExistingApprovalLogsMap.containsKey(typeList[i])){
                        nameOfExistingApprovalLogsMap.put(typeList[i],new set<String>{existingAl.Name});
                    }else{
                        nameOfExistingApprovalLogsMap.get(typeList[i]).add(existingAl.Name);
                    }
                }
                noofApprovalCount = integer.valueof(existingAl.ECM_No_of_Approval_Cycles__c);
            }
        }
        system.debug(LoggingLevel.Debug,'nameOfExistingApprovalLogsMap-->'+nameOfExistingApprovalLogsMap);
        
        nameOfExistingApprovalLogsSDID = nameOfExistingApprovalLogsMap.containsKey('Contract Sales Driver Item')?nameOfExistingApprovalLogsMap.get('Contract Sales Driver Item'):new set<String>();
        nameOfExistingApprovalLogsSD = nameOfExistingApprovalLogsMap.containsKey('Contract Sales Driver')?nameOfExistingApprovalLogsMap.get('Contract Sales Driver'):new set<String>();
        nameOfExistingApprovalLogs = nameOfExistingApprovalLogsMap.containsKey('Contract')?nameOfExistingApprovalLogsMap.get('Contract'):new set<String>();
        
        System.debug(LoggingLevel.Debug,'@@noofApprovalCount' +noofApprovalCount);
        if(con !=null && con.ECM_Agreement_Type__c !=null && approvalLogWrapper.agreementTypeMap.containsKey(con.ECM_Agreement_Type__c)){
            ECM_Contract_Type__c agreementType = approvalLogWrapper.agreementTypeMap.get(con.ECM_Agreement_Type__c);
            
            if(approvalLogWrapper.ContractSalesDriverItemMap.containsKey(con.Id)){
                salesDriverMap=approvalLogWrapper.ContractSalesDriverItemMap.get(con.Id);				
            }
            System.debug(LoggingLevel.Debug,'salesDriverMap------->'+salesDriverMap);
            
            if(approvalLogWrapper.ContractSalesDriverItemDetailMap.containsKey(con.Id)){
                salesDriverItemDetailList=approvalLogWrapper.ContractSalesDriverItemDetailMap.get(con.Id);				
            }
            System.debug(LoggingLevel.Debug,'salesDriverItemDetailList------>'+salesDriverItemDetailList);
            
            
            if(agreementType !=null && agreementType.Agreement_Approvals__r!=null && agreementType.Agreement_Approvals__r.size()>0){
                
                for(ECM_Agreement_Approval__c aa: agreementType.Agreement_Approvals__r){
                    system.debug(LoggingLevel.Debug,aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c+'low and upper '+aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c);
                    system.debug(LoggingLevel.Debug,con.RecordType.DeveloperName+'Extra==='+aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c);
                    
                    if(con.RecordType.DeveloperName =='Outlet'){
                        if(aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c!=null){
                            system.debug(LoggingLevel.Debug, con.ECM_Territory__r.Sales_Area__c+'Extra contract= '+con.ECM_Territory__r.Region__c);
                            system.debug(LoggingLevel.Debug, aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c+'Extra Territory= '+aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c);
                            if(!(con.ECM_Territory__c !=null && 
                                 (con.ECM_Territory__r.Region__c == aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c 
                                  || con.ECM_Territory__r.Sales_Area__c==aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c)) ){
                                      continue;
                                  }                                
                        }  
                    }else if(con.RecordType.DeveloperName =='Group'){
                        if(aa.ECM_Extra_Approval__r.ECM_Territory_Hierarchy__c!=null){
                            continue;
                        }
                    }
                    system.debug(LoggingLevel.Debug,aa.ECM_Extra_Approval__r.ECM_Type__c+'aa== '+aa);
                    
                    Map<String,ECM_Approval_Log__c> parentApprovallogMap= new Map<String,ECM_Approval_Log__c>();
                    parentApprovallogMap=validateAutoApproval(con,false);
                    if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract' && aa.ECM_Extra_Approval__r.ECM_Legal_Related__c
                       && approvalLogWrapper.legalApprovalLog.containsKey(con.Id) ){
                           System.debug(LoggingLevel.Debug,'Legal@'+approvalLogWrapper.legalApprovalLog.get(con.Id));
                           System.debug(LoggingLevel.Debug,'isdelegated@'+aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c);
                           System.debug(LoggingLevel.Debug,'delegate@'+aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                           boolean temp = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(approvalLogWrapper.legalApprovalLog.get(con.Id).contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(approvalLogWrapper.legalApprovalLog.get(con.Id).contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                               System.debug(LoggingLevel.Debug,'conEAEmails@'+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c);
                           boolean notDuplicate = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(!conEAEmails.contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(!conEAEmails.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                               if(temp && notDuplicate){
                                   ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                   ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                   ecmExtraApprovalLog.ECM_Addendum__c = approvalLogWrapper.currentApprovalLog.ECM_Addendum__c;
                                   ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;
                                   ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                   ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                   Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                   if(String.isNotEmpty(recordIdApprovalLog)){
                                       ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                   }System.debug(LoggingLevel.Debug,'conEAEmails@ 1084'+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c);
                                   System.debug(LoggingLevel.Debug,'ECM_Enable_Delegation__c 1085'+aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c);
                                   System.debug(LoggingLevel.Debug,'ECM_Enable_Delegation__c email'+aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                                   if(String.isNotEmpty(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == False){
                                       ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                       extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                       if(aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c!=null){
                                           ecmExtraApprovalLog.ECM_Approver_s_Position__c = aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;   
                                       }
                                   }else if(aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == True && aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c != Null){
                                       ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c;
                                       ecmExtraApprovalLog.ECM_Approver_s_Position__c=DelegatedUser+' '+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;
                                       extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                                   }
                                   ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                   if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                       approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                   }else{
                                       approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                   }
                                   conEAEmails.add(ecmExtraApprovalLog.Name);
                               }
                       }
                    
                    else if(
                        aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract' && 
                        aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && 
                        aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null){
                            System.debug(LoggingLevel.Debug,'@@1086'+approvalLogWrapper.newInvestmentConItemAddendum);
                            System.debug(LoggingLevel.Debug,'@@1087'+String.valueOf(con.Id+'-'+approvalLogWrapper.currentApprovalLog.ECM_Addendum__c));
                            Decimal newInvestments = approvalLogWrapper.newInvestmentConItemAddendum.containsKey(String.valueOf(con.Id+'-'+approvalLogWrapper.currentApprovalLog.ECM_Addendum__c))?
                                approvalLogWrapper.newInvestmentConItemAddendum.get(String.valueOf(con.Id+'-'+approvalLogWrapper.currentApprovalLog.ECM_Addendum__c)):0;
                            //check Contract's overall investment  Indirect Inv amount in range of upper and lower limit of extra approval
                            System.debug(LoggingLevel.Debug,'@@1091'+aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c+'---'+aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c+'---'+aa);
                            if(newInvestments >=aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c && newInvestments<=aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c){
                                boolean temp = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(!nameOfExistingApprovalLogs.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                                    System.debug(LoggingLevel.Debug,'conEAEmails@'+conEAEmails);
                                boolean notDuplicate = aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c ?(!conEAEmails.contains(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c)):(!conEAEmails.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c));
                                    if(temp && notDuplicate){
                                        
                                        if((con.ECM_Recalled__c && !parentApprovallogMap.containskey(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)) || !(con.ECM_Recalled__c)){
                                            system.debug(LoggingLevel.Debug,'Addendum:'+approvalLogWrapper.currentApprovalLog.ECM_Addendum__c);
                                            ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                            ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                            ecmExtraApprovalLog.ECM_Addendum__c = approvalLogWrapper.currentApprovalLog.ECM_Addendum__c;
                                            ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;
                                            ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                            ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                            Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                            if(String.isNotEmpty(recordIdApprovalLog)){
                                                ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                            }
                                            if(String.isNotEmpty(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) && aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == False){
                                                ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                                extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                                if(aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c!=null){
                                                    ecmExtraApprovalLog.ECM_Approver_s_Position__c = aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;   
                                                }
                                            }else if(aa.ECM_Extra_Approval__r.ECM_Enable_Delegation__c == True && aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c != Null){
                                                ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c;
                                                ecmExtraApprovalLog.ECM_Approver_s_Position__c=DelegatedUser+' '+aa.ECM_Extra_Approval__r.ECM_Approver_Position_Name__c;
                                                extraApprovalEmails.add(aa.ECM_Extra_Approval__r.ECM_Delegated_Approver_Email_Address__c);
                                            }
                                            ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                            if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                                approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                            }else{
                                                approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                            }
                                            if(newInvestments < aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c){
                                                extraApprovalLowerLimit.add(aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c);
                                            }
                                            conEAEmails.add(ecmExtraApprovalLog.Name);
                                        }
                                    }
                            }
                        }
                    
                    else if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract Sales Driver' &&
                            salesDriverMap.containsKey(aa.ECM_Extra_Approval__r.ECM_Sales_Driver__c) &&
                            aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c !=null && 
                            aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null ){
                                Decimal totalInvestmentAmount = salesDriverMap.get(aa.ECM_Extra_Approval__r.ECM_Sales_Driver__c);
                                List<ECM_Sales_Driver_Item_Detail__c> sdidList = approvalLogWrapper.ContractSalesDriverItemDetailMap.get(con.Id);
                                for(ECM_Sales_Driver_Item_Detail__c sdi:sdidList){
                                    if(sdi.ECM_Addendum__c !=null &&
                                       sdi.ECM_Addendum__c==approvalLogWrapper.currentApprovalLog.ECM_Addendum__c){
                                           totalInvestmentAmount += sdi.ECM_Investment_Amount__c;
                                       }
                                    
                                }
                                System.debug(LoggingLevel.Debug,'sdEAEmails@'+sdEAEmails);
                                if(totalInvestmentAmount >=aa.ECM_Extra_Approval__r.ECM_Lower_Limit_Amount__c &&
                                   totalInvestmentAmount <=aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c && 
                                   !nameOfExistingApprovalLogsSD.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) &&
                                   !sdEAEmails.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)){
                                       ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                       ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                       ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;
                                       ecmExtraApprovalLog.ECM_Sales_Driver__c = aa.ECM_Extra_Approval__r.ECM_Sales_Driver__c;
                                       ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                       ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                       ecmExtraApprovalLog.ECM_Addendum__c = approvalLogWrapper.currentApprovalLog.ECM_Addendum__c;
                                       Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                       if(String.isNotEmpty(recordIdApprovalLog)){
                                           ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                       }
                                       ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                       
                                       extraApprovalSDEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                       ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                       
                                       if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                           approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                       }else{
                                           approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                       }
                                       sdEAEmails.add(ecmExtraApprovalLog.Name);
                                   }
                            }
                    
                    else if(aa.ECM_Extra_Approval__r.ECM_Type__c == 'Contract Sales Driver Item' && 
                            aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c !=null ){
                                for(ECM_Sales_Driver_Item_Detail__c sdid: salesDriverItemDetailList){
                                    if(sdid.ECM_Addendum__c!=null && sdid.ECM_Addendum__c==approvalLogWrapper.currentApprovalLog.ECM_Addendum__c){
                                        if(sdid.ECM_Investment_Amount__c >= aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c){
                                            System.debug(LoggingLevel.Debug,'Investment amount--->'+sdid.ECM_Investment_Amount__c);
                                            System.debug(LoggingLevel.Debug,'Upper Limit --->'+aa.ECM_Extra_Approval__r.ECM_Upper_Limit_Amount__c);
                                            createSDIDApprovalLog = true;
                                            break;
                                        }
                                    }
                                }
                                System.debug(LoggingLevel.Debug,'createSDIDApprovalLog-->'+createSDIDApprovalLog);
                                System.debug(LoggingLevel.Debug,'sdidEAEmails@'+sdidEAEmails);
                                if(createSDIDApprovalLog && 
                                   !nameOfExistingApprovalLogsSDID.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c) && 
                                   !sdidEAEmails.contains(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c)){
                                       ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
                                       ecmExtraApprovalLog.ECM_Contract__c = con.Id;
                                       ecmExtraApprovalLog.ECM_Type__c =  aa.ECM_Extra_Approval__r.ECM_Type__c;
                                       ecmExtraApprovalLog.ECM_Status__c = 'Requested';
                                       ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
                                       ecmExtraApprovalLog.ECM_Addendum__c=approvalLogWrapper.currentApprovalLog.ECM_Addendum__c;
                                       Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
                                       if(String.isNotEmpty(recordIdApprovalLog)){
                                           ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
                                       }
                                       ecmExtraApprovalLog.Name= aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c;
                                       
                                       extraApprovalSDIDEmails.add(aa.ECM_Extra_Approval__r.ECM_Approver_s_Email_Address__c);
                                       ecmApprovalLogsList.add(ecmExtraApprovalLog);
                                       createSDIDApprovalLog=false;
                                       
                                       if(!approvalLogMap.containsKey(ecmExtraApprovalLog.Name)){
                                           approvalLogMap.put(ecmExtraApprovalLog.Name,new List<ECM_Approval_Log__c>{ecmExtraApprovalLog});
                                       }else{
                                           approvalLogMap.get(ecmExtraApprovalLog.Name).add(ecmExtraApprovalLog);
                                       }
                                       sdidEAEmails.add(ecmExtraApprovalLog.Name);
                                   }
                            }
                }
            }
        }
        
        System.debug(LoggingLevel.Debug,'approvalLogMap-->'+approvalLogMap);
        list<ECM_Approval_Log__c> ecmApprovalLogsListNew = new list<ECM_Approval_Log__c>();
        for(String str:approvalLogMap.keySet()){
            ECM_Approval_Log__c temp = new ECM_Approval_Log__c();
            String approvalLogType = '';
            for(ECM_Approval_Log__c ecmApprovalLog:approvalLogMap.get(str)){
                temp.ECM_Contract__c = ecmApprovalLog.ECM_Contract__c;
                temp.ECM_Addendum__c = ecmApprovalLog.ECM_Addendum__c;
                temp.ECM_Type__c =  temp.ECM_Type__c == Null?ecmApprovalLog.ECM_Type__c:temp.ECM_Type__c+';'+ecmApprovalLog.ECM_Type__c;
                approvalLogType = String.isNotEmpty(approvalLogType)?approvalLogType+';'+ecmApprovalLog.ECM_Type__c:ecmApprovalLog.ECM_Type__c;
                temp.ECM_Status__c = ecmApprovalLog.ECM_Status__c;
                temp.ECM_No_of_Approval_Cycles__c = ecmApprovalLog.ECM_No_of_Approval_Cycles__c;
                temp.RecordTypeId = String.isNotEmpty(ecmApprovalLog.RecordTypeId)?ecmApprovalLog.RecordTypeId:Null;
                temp.Name = ecmApprovalLog.Name;
                if(ecmApprovalLog.ECM_Sales_Driver__c!=Null){
                    temp.ECM_Sales_Driver__c = ecmApprovalLog.ECM_Sales_Driver__c;
                }
                if(ecmApprovalLog.ECM_Approver_s_Position__c !=Null){
                    temp.ECM_Approver_s_Position__c = ecmApprovalLog.ECM_Approver_s_Position__c;
                }
            }
            if(!extraApprovalEmailsMap.containsKey(temp.ECM_Type__c)){
                extraApprovalEmailsMap.put(temp.ECM_Type__c,new Set<String>{temp.Name});
            }else{
                extraApprovalEmailsMap.get(temp.ECM_Type__c).add(temp.Name);
            }
            ecmApprovalLogsListNew.add(temp);
        }
        
        system.debug(LoggingLevel.Debug,'@@ecmApprovalLogsListNew-->' +ecmApprovalLogsListNew);
        system.debug(LoggingLevel.Debug,'@@ecmApprovalLogsList' +ecmApprovalLogsList);
        system.debug(LoggingLevel.Debug,'@@extraApprovalEmails' +extraApprovalEmails);
        system.debug(LoggingLevel.Debug,'@@extraApprovalEmailsMap-->'+extraApprovalEmailsMap);
        if(ecmApprovalLogsListNew!=null && !ecmApprovalLogsListNew.isEmpty() && ecmApprovalLogsListNew.size()>0){
            isExtraApproval = true;
            approvalLogWrapper.ApprovalLogList.addAll(ecmApprovalLogsListNew);
            if(extraApprovalEmailsMap.size()>0){
                sendEmailToUserForAddendum_Multi(extraApprovalEmailsMap,con,approvalLogWrapper);
            }
        }
        if((ecmApprovalLogsList==null || ecmApprovalLogsList.isEmpty() || ecmApprovalLogsList.size()==0) && 
           (extraApprovalLowerLimit==null || extraApprovalLowerLimit.isEmpty() || extraApprovalLowerLimit.size()==0)){
               ECM_Approval_Log__c ecmExtraApprovalLog = new ECM_Approval_Log__c();
               ecmExtraApprovalLog.Name='Record not found';
               ecmExtraApprovalLog.ECM_No_of_Approval_Cycles__c = noofApprovalCount;
               if(con !=null && con.ECM_Agreement_Type__c !=null){
                   ecmExtraApprovalLog.ECM_Contract__c = con.Id;
               }
               ecmExtraApprovalLog.ECM_Addendum__c = approvalLogWrapper.currentApprovalLog.ECM_Addendum__c;
               Id recordIdApprovalLog = Schema.SObjectType.ECM_Approval_Log__c.getRecordTypeInfosByDeveloperName().get('ECM_Extra_approver').getRecordTypeId();
               if(String.isNotEmpty(recordIdApprovalLog)){
                   ecmExtraApprovalLog.RecordTypeId = recordIdApprovalLog;
               }
               approvalLogWrapper.ApprovalLogList.add(ecmExtraApprovalLog);
           }
        return isExtraApproval;
    }
    /*
    * Description	:	ECM-6032 - Approval flow for Addendum (Prim+Contract+SD+SDI)_SFDC_EU/ECM-5955 - Addendum Approval Email template_SFDC_EU
    * Developer		:	Saurav Prasad/Anand Uppalapati
    * Date			:	17/08/2022
    * Method		:	sendEmailToUserForAddendum_Multi
    * return		:	void
    * params		:	map<String,set<String>,Contract,ECM_ApprovalLogWrapper
    */
    public static void sendEmailToUserForAddendum_Multi(map<String,set<String>>recipentUserEmails, Contract conRec, ECM_ApprovalLogWrapper approvalLogWrapper){
        system.debug(LoggingLevel.Debug,'recipentUserEmails-->'+recipentUserEmails);     
        system.debug(LoggingLevel.Debug,'ContractRecord-->'+conRec);
        
        Market_Setting__c marSetRec = new Market_Setting__c(); //Added for ECM-6264
        if(approvalLogWrapper.marketSettingMap.containsKey(conRec.Account.Country__c)){
            marSetRec = approvalLogWrapper.marketSettingMap.get(conRec.Account.Country__c);						
        }        
        List<Messaging.SingleEmailMessage> mails = new List<Messaging.SingleEmailMessage>();
        Map<String,EmailTemplate> emailTemplateMap = new  Map<String,EmailTemplate>();
        //ECM-6032
        String objName = '%'+approvalLogWrapper.currentApprovalLog.ECM_Addendum__c.getsobjecttype()+'%';
        Map<String, String> mailTemplateTrigger = new Map<String, String>();
        for(ECM_Email_Template_Setting__mdt EmailTemp:[SELECT Id,Masterlabel,DeveloperName,ECM_Related_to_Object__c, ECM_Type__c  
                                                       FROM ECM_Email_Template_Setting__mdt 
                                                       WHERE ECM_Related_to_Object__c LIKE:objName]){
                                                           mailTemplateTrigger.put(EmailTemp.ECM_Type__c,EmailTemp.Masterlabel);
                                                       }
        try{
            system.debug(LoggingLevel.Debug,'emailTemplateMap-->'+emailTemplateMap);
            //Template name based on Country
            for(String str:recipentUserEmails.keySet()){
                List<Messaging.EmailFileAttachment> allAttachments = new List<Messaging.EmailFileAttachment>();
                
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                list<String>toAddresses = new list<String>(recipentUserEmails.get(str));
                system.debug(LoggingLevel.Debug,'toAddresses-->'+toAddresses);
                email.setTargetObjectId(userinfo.getuserid());
                email.setTreatTargetObjectAsRecipient(false);
                email.setWhatId(approvalLogWrapper.currentApprovalLog.ECM_Addendum__c);
                email.setOrgWideEmailAddressId(approvalLogWrapper.OrgWideEmailAddressId);
                //email.setTemplateID(approvalLogWrapper.emailTemplateMap.get(marketObj.ECM_Contract_Approval_Template__c).Id);
                email.setTemplateID(approvalLogWrapper.emailTemplateMap.get(mailTemplateTrigger.get(str)).Id);
                email.setSaveAsActivity(false);
                email.setReplyTo(Label.ECM_ContractApproverManagerEmailId);
                email.setToAddresses(toAddresses);
                /*commented for ECM-6264
                Messaging.EmailFileAttachment attachPdf = contractPdf(ContractRecord,ContractRecord.Status,approvalLogWrapper);
                if(attachPdf !=null){
                allAttachments.add(attachPdf);
                }
                */
                List<Messaging.EmailFileAttachment> parentAttch = new List<Messaging.EmailFileAttachment>();
                if(marSetRec.ECM_Contract_pdf_to_Approval_Mails__c){
                    parentAttch = fetchParentDocs(conRec.Id);
                    if(!parentAttch.isEmpty()){
                        allAttachments.addAll(parentAttch);
                    }
                }
                Messaging.EmailFileAttachment attachAddnmPdf = addendumPdf(conRec,approvalLogWrapper,approvalLogWrapper.currentApprovalLog.ECM_Addendum__c);
                if(attachAddnmPdf !=null){
                    allAttachments.add(attachAddnmPdf);
                }
                system.debug(LoggingLevel.Debug,'email-->'+email);
                system.debug(LoggingLevel.Debug,'allAttachments-->'+allAttachments);
                email.setFileAttachments(allAttachments);
                mails.add(email);   
            }
            system.debug(LoggingLevel.Debug,'email list-->'+mails);
            if(mails.size()>0){  
                approvalLogWrapper.multiuserEmailList.addAll(mails);
            }
        }catch(Exception ex){
            system.debug(LoggingLevel.Debug,'Error Exception'+ex.getStackTraceString());
        }       
    }
    
    /*   
    * Description	:   ECM-6075 Addendum PDF in Addendum Approval Email_SFDC_EU
    * Developer		:	Anand Uppalapati
    * Date			:	01/09/2022
    * Method		:	addendumPdf
    * return		:	Messaging.EmailFileAttachment
    * params		:	Contract ContractRecord,ECM_ApprovalLogWrapper,Id addndmId
    */
    public static Messaging.EmailFileAttachment addendumPdf(Contract ContractRecord,ECM_ApprovalLogWrapper approvalWrapper,Id addndmId){
        Messaging.EmailFileAttachment attachPdf = new Messaging.EmailFileAttachment();
        PageReference pref = page.ECm_PDF_generation;
        pref.getParameters().put('Id',ContractRecord.Id);
        pref.getParameters().put('addendumId', (addndmId == null)? '' : addndmId);//added null check for ECM-6264
        pref.getParameters().put('isApproval','true');
        pref.setRedirect(true);
        Blob b;
        if(trigger.isExecuting){
            if(approvalWrapper!=null){
                Map<Id,ContentDocumentLink> contentDocumentMap = approvalWrapper.contentDocumentLinkMapAddendum;
                system.debug(LoggingLevel.Debug,'@@@primaryApprovalLogMap1-->'+approvalWrapper.primaryApprovalLogMap.get(ContractRecord.Id));
                system.debug(LoggingLevel.Debug,'@@@primaryApprovalLogMap2-->'+contentDocumentMap.keySet());
                
                if(approvalWrapper.primaryApprovalLogMap.containsKey(ContractRecord.Id) && contentDocumentMap.containsKey(approvalWrapper.primaryApprovalLogMap.get(ContractRecord.Id))){
                    ContentDocumentLink conDoc = contentDocumentMap.get(approvalWrapper.primaryApprovalLogMap.get(ContractRecord.Id));
                    b = conDoc.ContentDocument.LatestPublishedVersion.VersionData;
                }
            }
        }
        //ECM-5649
        else{
            try{
                b = !test.isRunningTest()?pref.getContent():blob.valueOf('Unit.Test');
            }
            catch(Exception ex){//ECM-6264
                System.debug(LoggingLevel.Debug,'@@@method:addendumPdf\nException in PDF generation: ' + ex.getLineNumber() +'\n'+ ex.getMessage() +'\n'+ ex.getCause());
            }
        }
        attachPdf.setFileName(system.label.ECM_Addendum_Approval_File_Name);
        if(b != null){
            attachPdf.setBody(b);
        }
        return attachPdf;		
    }
    
    /*   
    * @description	: 	ECM-6264 - fetches signed contract attachments of a contract
    * @developer	:	Pratap Sen
    * @date			:	22/10/2022
    * @return		:	List<Messaging.EmailFileAttachment>
    * @param		:	Id - Contract Id
    */
    public static List<Messaging.EmailFileAttachment> fetchParentDocs(Id conId){
        Id recordIdContentVersion = Schema.SObjectType.ContentVersion.getRecordTypeInfosByDeveloperName().get('Contracts').getRecordTypeId();
        List<Messaging.EmailFileAttachment> atchList = new List<Messaging.EmailFileAttachment>();
        for(ContentDocumentLink  parentDoc : [SELECT Id, LinkedEntityId, ContentDocumentId,ContentDocument.FileExtension,ContentDocument.Title,
                                              ContentDocument.LatestPublishedVersion.Content_Type__c,ContentDocument.LatestPublishedVersion.RecordTypeId,
                                              ContentDocument.LatestPublishedVersion.VersionData
                                              FROM ContentDocumentLink 
                                              WHERE LinkedEntityId =: conId
                                              AND ContentDocument.LatestPublishedVersion.RecordTypeId =: recordIdContentVersion
                                              AND ContentDocument.LatestPublishedVersion.Content_Type__c =: Label.ECM_ContentTypeSignedContract])
        {
            Messaging.EmailFileAttachment attPrnt = new Messaging.EmailFileAttachment();
            attPrnt.setFileName(parentDoc.ContentDocument.Title +'.'+ parentDoc.ContentDocument.FileExtension);
            attPrnt.setBody(parentDoc.ContentDocument.LatestPublishedVersion.VersionData);
            atchList.add(attPrnt);
        }
        return atchList;
    }
}