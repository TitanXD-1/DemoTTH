/**
* @description :  ECM_ContractRecallCtrl
* @purpose : This is the controller class of ECM_ContractRecallButton component
* @since :
* Version      Developer            		Date          User Story/Purpose
*  1.1         Anuja Chattopadhyay     	    12/01/2022    ECM-5097 	New field "Enable Recalling" in Agreement type Creation and Logic _Cloning _GLO
*  1.2		   Saurav Paul					30/01/2022	  ECM-5111	Logic for Confirm option on recall Pop-up window_SFDC_GLO
*  1.3		   Vinay Tummala				30/01/2022	  ECM-5140	Validations for "Recall" option in Contract detail page_Recall_GLO
*  1.4         Irfan Ahmed					31/01/2022	  ECM-5143	Notification to Approvers of Parent Contract_Recall_SFDC_GLO	

*  1.5		   Vinay Tummala                09/02/2022    ECM-5147  Logic for Multiple Agreements_Recall_SFDC_GLO
*  1.6		   Keshav                       08/02/2022    ECM-5145  Screen 1 Contract Recall_Validations_SFDC_AU
*  1.7         Pratap Sen                   01/04/2022    ECM-5396  Updated Recall-allowed contract status & modified updateParentContract()

*  1.8         Saurav Prasad                28/04/2022    ECM-5476  Recall of Group contract_Contract Detail Page_SFDC_GLO
*  1.9         Vinay Tummala                28/04/2022    ECM-5483  Approval Mail for Recalled Group Contract_SFDC_GLO_Recall
*  2.0		   Nikhilesh Chandak			13/06/2022	  ECM-5678  Added logic for changing approval log status for Recalled Contracts
*  2.1         Anand Uppalapati             28/09/2022    ECM-6063  Child Contract record creation for Addendum_SFDC_EU
*/
public with sharing class ECM_ContractRecallCtrl {
    //These variables are being used in ECM_Contract_Recall_Noti_Comp vf component
    public static String salesRepName {get; set;}
    public static String accountName {get; set;}
    public static String contractNum {get; set;}
    public static String contractName {get; set;}
    public static String recordTypeName { get; set; }
    /**
* @description : validateRecall - This methods used to check if recall can be done
* @return : String
* @param : Contract Id
*/
    @AuraEnabled
    public static String validateRecall(Id conId){
        String userProfileId = UserInfo.getProfileId();
        String userId=UserInfo.getUserId();
        String errorMessage = '';
        List <Profile> userProfileList =[SELECT Id,Name FROM Profile WHERE Id =:userProfileId];
        List<String> allowedProfileList = Label.ECM_RecalledAllowedProfile.split(';');
        List<String> allowedConStatusList = Label.ECM_RecallAllowedContractStatus.split(';');
        List<String> psStatusList = Label.ECM_PS_Status.split(';');
        List<Contract> conList = [SELECT Id,Status,ECM_Agreement_Type__r.ECM_Enable_Recall_of_Contract__c,OwnerId,
                                  ECM_Agreement_Type__r.Name 
                                  FROM Contract 
                                  WHERE Id=:conId];
        
        
        //Available Profile check
        if(!allowedProfileList.contains(userProfileList[0].name)){
            errorMessage = Label.ECM_Recall_Profile_Error;
            return errorMessage;
        }else if(conList!= null && conList.size()>0&&conList[0].ownerId!=userId){
            errorMessage=Label.ECM_Recall_ContractOwner_Error;
            return errorMessage;
        }else{
            if(conList!= null && !allowedConStatusList.contains(conList[0].Status)){//Allowed status check
                errorMessage = Label.ECM_Recall_Contract_Error;
                return errorMessage;
            }else if(conList!= null && allowedConStatusList.contains(conList[0].Status)){//PS Status Check
                List<ECM_Payment_Summary__c> psList =[SELECT Id FROM ECM_Payment_Summary__c 
                                                      WHERE ECM_Contract__c =:conId 
                                                      AND ECM_Payment_Summary_Status__c IN : psStatusList];
                if(psList!= null && !psList.isEmpty()){
                    errorMessage = Label.ECM_Recall_Contract_Error;
                    return errorMessage;
                }else if(conList!= null && !conList[0].ECM_Agreement_Type__r.ECM_Enable_Recall_of_Contract__c){//Agreement type check
                    errorMessage = Label.ECM_Recall_Agreement_Error;
                    return errorMessage;
                }
            }
        }
        return null;
    }
    /**


* 	@description : validationforAgreementType - This method is used to validate agreement type for parent contract
* 	@return : String
* 	@param : parentContractId
*/
    @AuraEnabled
    public static string validationforAgreementType(Id conId){
        List<Contract>cons=[SELECT ECM_Agreement_Type__c,StartDate,RecordTypeId,AccountId 
                            FROM Contract 
                            WHERE Id=:conId];
        return ECM_CreateContractController.validation_for_Agreement_Type(cons[0], cons[0].AccountId, cons[0].RecordTypeId);
    }
    /**


* @description : updateParentContract - This methods used to update Parent Contract Fields
* @return : None
* @param : Contract,String
*/
    public static void updateParentContract(Contract parentCon, String reasonForRecall){
        parentCon.Status = 'Recalled';//ECM-5396
        parentCon.ECM_Reason_For_Recall__c = reasonForRecall;
        update parentCon;        
    }  
    /**
* @description : createJSON - This methods used to generate the JSON to pass ECM_ContractCloneButtonCtrl
* @return : String
* @param : Contract
*/ 
    public static String createJSON(Contract parentContract){
        List<String> countryList =  Label.ECM_Country_Code.split(';');
        Boolean isAus = countryList.contains(parentContract.Account.Country__r.Code__c)?true:false;
        Map<String,String> jsonMap = new Map<String,String>();
        
        
        jsonMap.put('isAus',String.valueOf(isAus));
        for(ECM_Clone_Contract_ScreenInfo__mdt mdtObj : [SELECT Field_Name__c,Custom_Data_Type__c,Data_Type__c,Required__c,
                                                         Field_API_Name__c,Country_Code__c
                                                         FROM ECM_Clone_Contract_ScreenInfo__mdt ])
        {
            if(mdtObj.Country_Code__c.contains(parentContract.Account.Country__r.Name)|| mdtObj.Country_Code__c.contains('Global')){
                if(mdtObj.Data_Type__c.equals('checkbox')){
                    jsonMap.put(mdtObj.Field_Name__c,'true'); 
                }else if(mdtObj.Data_Type__c.equals('Date') && mdtObj.Field_Name__c.equals('Start Date')){
                    jsonMap.put(mdtObj.Field_Name__c,String.valueOf(parentContract.StartDate)); 
                }else if(mdtObj.Data_Type__c.equals('Number') && mdtObj.Field_Name__c.equals('Duration')){
                    jsonMap.put(mdtObj.Field_Name__c,String.valueOf(parentContract.ECM_Duration__c));
                }else{
                    jsonMap.put(mdtObj.Field_Name__c,'');
                }                                                     
            }        
        }
        
        
        String jsonStr = JSON.serialize(jsonMap);
        return jsonStr;
    }
    /**
* @description : confirmRecall - This methods used to create child contract and related items
* @return : String
* @param : Parentcontract Id,Child Contract,String Reason For Recall
*/ 
    @AuraEnabled
    public static contract confirmRecall(Id parentConId,Contract childContract,String reasonForRecall){
        Contract insertedContractRec = new Contract();
        //ECM-5476
        Set<Id> accIds = new set<Id>();//related to Outlet_Contract__c
        List<Contract> parentConList = [SELECT Id,Status,ECM_Recalled__c,ECM_Parent_Contract__c,ECM_Reason_For_Recall__c,Contract_End_Date__c,Name,Venue_Type__c,
                                        ECM_Duration__c,AccountId,StartDate,Account.Country__r.Code__c,ECM_Territory__c,RecordTypeId,ECM_Agreement_Type__c,
                                        ECM_Channel__c,ECM_Banner__c,ECM_RTD_Discount_Level__c,ECM_Spirits_Discount_Level__c,ECM_Spirits_Pouring_Discount_Level__c,
                                        ECM_Spirits_Premium_Discount_Level__c,ECM_Spirits_Reserve_Discount_Level__c,ECM_Draught_Spirits_Discount_Level__c,
                                        ECM_Distilled_NonAlchlic_Discount_Level__c,Account.Country__r.Name,ECM_Agreement_Type__r.ECM_Generate_Contract_Name__c,Account.Name,ECM_Agreement_Type__r.ECM_Abbreviation__c,
                                        ECM_RTD_Sales_driver__c, ECM_Spirits_Sales_driver__c, ECM_Spirits_Pouring_Sales_driver__c, ECM_Distilled_NonAlchlic_Sales_driver__c, ECM_Spirits_Premium_Sales_driver__c, 
                                        ECM_Spirits_Reserve_Sales_driver__c, ECM_Draught_Spirits_Sales_driver__c FROM Contract WHERE Id=:parentConId];
        //ECM-5476
        for(Outlet_Contract__c outConObj : [Select Id,Outlet__c from Outlet_Contract__c where Contract__c =:parentConId]){
            accIds.add(outConObj.Outlet__c);
        }
        if(parentConList!= null && !parentConList.isEmpty()){
            //ECM-5476
            List<Account> outletList = [SELECT Id,Name FROM Account WHERE Id IN: accIds];//need to check and add Account fields
            if(!String.isEmpty(reasonForRecall)){//ECM-6063
                updateParentContract(parentConList[0],reasonForRecall);
            }
            String jsonStr = createJSON(parentConList[0]);
            
            childContract.StartDate = parentConList[0].StartDate;
            childContract.Contract_End_Date__c = parentConList[0].Contract_End_Date__c;
            childContract.ECM_Duration__c = parentConList[0].ECM_Duration__c;
            childContract.name = parentConList[0].name;
            
            //Added as a part of ECM-5145
            if(parentConList[0].ECM_Agreement_Type__r.ECM_Generate_Contract_Name__c){
                String conStartDate = String.valueOf(parentConList[0].StartDate).removeEnd(' 00:00:00');
                childContract.name = parentConList[0].Account.Name+'_'+ parentConList[0].ECM_Agreement_Type__r.ECM_Abbreviation__c +'_'+conStartDate;                
            }else{
                childContract.name = parentConList[0].name;
            }          
            //Added as a part of ECM-5145
            Map<String,String> countryMap = (Map<String,String>)JSON.deserialize(jsonStr, Map<String,String>.class);
            Boolean isAusCheck = Boolean.valueOf(countryMap.get('isAus'));
            if(isAusCheck){
                childContract.ECM_Channel__c = parentConList[0].ECM_Channel__c;
                childContract.ECM_Banner__c = parentConList[0].ECM_Banner__c;
                childContract.ECM_RTD_Discount_Level__c = parentConList[0].ECM_RTD_Discount_Level__c;
                childContract.ECM_Spirits_Discount_Level__c = parentConList[0].ECM_Spirits_Discount_Level__c;
                childContract.ECM_Spirits_Pouring_Discount_Level__c = parentConList[0].ECM_Spirits_Pouring_Discount_Level__c;
                childContract.ECM_Spirits_Premium_Discount_Level__c = parentConList[0].ECM_Spirits_Premium_Discount_Level__c;
                childContract.ECM_Spirits_Reserve_Discount_Level__c = parentConList[0].ECM_Spirits_Reserve_Discount_Level__c;
                childContract.ECM_Draught_Spirits_Discount_Level__c = parentConList[0].ECM_Draught_Spirits_Discount_Level__c;
                childContract.ECM_Distilled_NonAlchlic_Discount_Level__c = parentConList[0].ECM_Distilled_NonAlchlic_Discount_Level__c;
                
                childContract.ECM_RTD_Sales_driver__c = parentConList[0].ECM_RTD_Sales_driver__c;
                childContract.ECM_Spirits_Sales_driver__c = parentConList[0].ECM_Spirits_Sales_driver__c;
                childContract.ECM_Spirits_Pouring_Sales_driver__c = parentConList[0].ECM_Spirits_Pouring_Sales_driver__c;
                childContract.ECM_Distilled_NonAlchlic_Sales_driver__c = parentConList[0].ECM_Distilled_NonAlchlic_Sales_driver__c;
                childContract.ECM_Spirits_Premium_Sales_driver__c = parentConList[0].ECM_Spirits_Premium_Sales_driver__c;
                childContract.ECM_Spirits_Reserve_Sales_driver__c = parentConList[0].ECM_Spirits_Reserve_Sales_driver__c;
                childContract.ECM_Draught_Spirits_Sales_driver__c  = parentConList[0].ECM_Draught_Spirits_Sales_driver__c ;
                childContract.Venue_Type__c = parentConList[0].Venue_Type__c;
            }
            
            insertedContractRec = ECM_ContractCloneButtonCtrl.processCloneScreenInfo(childContract,parentConList[0].AccountId,
                                                                                     parentConList[0].RecordTypeId,parentConList[0].ECM_Territory__c,
                                                                                     parentConList[0].ECM_Agreement_Type__c,outletList,
                                                                                     jsonStr); 
            if(!String.isEmpty(reasonForRecall)){//ECM-6063
                sendRecallNotification(parentConList[0].Id);
            }
            
        } 
        return insertedContractRec;
    }
    
    /**
* @description : sendRecallNotification - This methods used to send approvers
* @return : None
* @param : Parentcontract Id
*/ 
    public static void sendRecallNotification(Id parentConId){
        List<ECM_Approval_Log__c> approvalLogs = new List<ECM_Approval_Log__c>();
        List<ECM_Approval_Log__c> approvalLogsToBeUpdated = new List<ECM_Approval_Log__c>();
        Set<String> recepientAddress = new Set<String>();
        List<String> recepientAddressList = new List<String>();
        Id userId;
        Id conId;
        
        approvalLogs = [SELECT Id,Name,ECM_Status__c,ECM_Contract__r.RecordType.Name,ECM_Contract__r.Account.Person_Responsible__r.Name,ECM_Contract__c,ECM_Contract__r.OwnerId,ECM_Contract__r.Account.Name,ECM_Contract__r.ContractNumber,ECM_Contract__r.Name,ECM_Contract__r.ECM_Contract_Owner__c
                        FROM ECM_Approval_Log__c WHERE ECM_Contract__c =: parentConId AND ECM_Status__c IN :System.Label.ECM_Recall_Contract_Approval_Log_Status.split(',')];
        
        if(!approvalLogs.isEmpty()){
            contractNum = String.valueOf(approvalLogs[0].ECM_Contract__r.ContractNumber);
            contractName = String.valueOf(approvalLogs[0].ECM_Contract__r.Name);
            
            //ECM-5678 : Changes apporval logs with "Requested" status to "Recalled"
            for(ECM_Approval_Log__c currentApprovalLog:approvalLogs){
                if(currentApprovalLog.ECM_Status__c != 'Approved'){
                    currentApprovalLog.ECM_Status__c = 'Recalled';
                    approvalLogsToBeUpdated.add(currentApprovalLog);
                }
            }
            if(!approvalLogsToBeUpdated.isEmpty()){
                update approvalLogsToBeUpdated;
            }
            
            
            //ECM-5483
            if(approvalLogs[0].ECM_Contract__r.RecordType.Name=='Group' && approvalLogs[0].ECM_Contract__r.Account.Person_Responsible__c!=null){
                
                salesRepName = approvalLogs[0].ECM_Contract__r.Account.Person_Responsible__r.Name;
            }
            else{
                salesRepName = approvalLogs[0].ECM_Contract__r.ECM_Contract_Owner__c;  
            }
            //ECM-5483
            accountName = approvalLogs[0].ECM_Contract__r.Account.Name;
            recordTypeName = approvalLogs[0].ECM_Contract__r.RecordType.Name;
            userId = approvalLogs[0].ECM_Contract__r.OwnerId;
            conId = approvalLogs[0].ECM_Contract__r.Id;
            
            for( ECM_Approval_Log__c appRecs :approvalLogs){
                recepientAddress.add(appRecs.Name);
            }
            if(!recepientAddress.isEmpty()){
                recepientAddressList.addAll(recepientAddress);
                Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                EmailTemplate emailTemplate = [Select Id,Subject,Description,HtmlValue,DeveloperName,Body from EmailTemplate where name = 'ECM_RecallNotificationtoApprovers'];
                email.setOrgWideEmailAddressId([select Id,Address from OrgWideEmailAddress where Address =:Label.ECM_ContractApproverOrgWideEmail].Id);
                email.setTemplateID(emailTemplate.Id);
                email.setTargetObjectId(userId);
                email.setWhatId(conId);
                email.setTreatTargetObjectAsRecipient(false);
                email.setSaveAsActivity(false);  
                email.setToAddresses(recepientAddressList);
                Messaging.SendEmailResult[] resEmail = Messaging.sendEmail(new Messaging.SingleEmailMessage[] { email });
            }
        }
    }
}