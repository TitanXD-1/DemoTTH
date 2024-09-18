/*
@Name: ECM_ContractAnniversaryNotiMailHelper
@Purpose: This batch is to send email notification to the customer on each Anniversary year completion of contracts 

@History                                                                                                                     
VERSION    AUTHOR        		DATE              DETAIL
1.0        Subhodeep Sarkar     18/07/2022        Initial Development (ECM-5903)
1.1        Priya Soni           18/07/2022        Initial Development (ECM-5903)
1.2        Anand Uppalapati     16/09/2022        ECM-6025 Anniversary email to Sales Rep/Customer_SFDC_EU
												  Email will be sent only when Contract Owner is Active
1.3        Anand Uppalapati     23/09/2022        ECM-6163/ECM-6158 Anniversary Email template is not matching
1.4		   Sagnik && Nidhi	    13/10/2022		  ECM-6236 Anniversary email for Ireland (before 2 months and based on Lead Brand)	
1.5        Wribhu Bose          05/12/2022        ECM-6457: Updation on Criteria for Anniversary email to Sales Rep/Customer (GB only) + changed variable idToContractDraought -> idToContractDraught
1.6        Wribhu Bose          12/12/2022        ECM-6555 (BUG): Added PGD map check
*/
public class ECM_ContractAnniversaryNotiMailHelper {
    
    public static Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();
    /*
    * @description : this list contains email instance corresponding to each contract which are satisfying condition, i.e, 1 Month before anniversary
    * @return : List<Messaging.SingleEmailMessage>
    * @param : List<Contract>,EmailTemplate
    */
    public static void createEmailListForAnniversary(List<Contract> contractList,String countryCode,Map<String,EmailTemplate> emailTmpMap){//pass map-emailTemplateMap
        
        List<Messaging.SingleEmailMessage> sendEmailListpour = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> sendEmailListdrgt = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> sendEmailListboth = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        List<String> emailList = new List<String>();
        List<String> ccEmailList = new List<String>();
        Set<Id> idToContractDraught = new Set<Id>();
        Set<Id> idToContractPouring = new Set<Id>();
        Set<Id> idToContractBoth = new Set<Id>();
        List<String> countryNames = Label.ECM_Anniv_Default_Template.split(','); // GB, ES
        Map<String,Pick_Up_Options__c> productGrowthDriverMap = new Map<String,Pick_Up_Options__c>();
        String pgdCategory = '';
        
        String eTemplate = Label.ECM_Email_Template_String+'ES';
        if(contractList !=null && !contractList.isEmpty()){
            Map<Id,Contract> contractMap = new Map<Id,Contract>(contractList);
            if(emailTmpMap!=null && !emailTmpMap.isEmpty()) {
                emailTemplateMap.putAll(emailTmpMap);
            }
            
            for(ECM_Sales_Driver_Item_Detail__c sdid : [SELECT ECM_Sales_Driver_Item__c,ECM_Product__r.ECM_Lead_Brand__c,ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c,
                                                        ECM_Sales_Driver_Item__r.Contract__c
                                                        FROM ECM_Sales_Driver_Item_Detail__c
                                                        WHERE ((ECM_Product__r.ECM_Lead_Brand__c = true
                                                               AND ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c =: System.Label.ECM_Anniv_Pouring_Status) 
                                                               OR (ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c =: System.Label.ECM_Anniv_Draught_Cocktail_Status))
                                                        AND ECM_Sales_Driver_Item__r.Contract__c in:contractList])
            {
                Boolean isPouring = false;
                Boolean isDraught = false;
                if(sdid.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c == System.Label.ECM_Anniv_Pouring_Status && sdid.ECM_Product__r.ECM_Lead_Brand__c) {
                    isPouring = true;
                }
                if(sdid.ECM_Sales_Driver_Item__r.ECM_Sales_Driver__r.ECM_Category__c == System.Label.ECM_Anniv_Draught_Cocktail_Status) {
                    isDraught = true;
                }
                if(isPouring && !idToContractDraught.contains(sdid.ECM_Sales_Driver_Item__r.Contract__c) && !idToContractBoth.contains(sdid.ECM_Sales_Driver_Item__r.Contract__c)) {
                    idToContractPouring.add(sdid.ECM_Sales_Driver_Item__r.Contract__c);
                } else if(isDraught && !idToContractPouring.contains(sdid.ECM_Sales_Driver_Item__r.Contract__c) && !idToContractBoth.contains(sdid.ECM_Sales_Driver_Item__r.Contract__c)) {
                    idToContractDraught.add(sdid.ECM_Sales_Driver_Item__r.Contract__c);
                } else {
                    idToContractBoth.add(sdid.ECM_Sales_Driver_Item__r.Contract__c);
                    if(idToContractPouring.contains(sdid.ECM_Sales_Driver_Item__r.Contract__c)) {
                        idToContractPouring.remove(sdid.ECM_Sales_Driver_Item__r.Contract__c);
                    }
                    if(idToContractDraught.contains(sdid.ECM_Sales_Driver_Item__r.Contract__c)) {
                        idToContractDraught.remove(sdid.ECM_Sales_Driver_Item__r.Contract__c);
                    }
                }
            }
            
            // ECM-6457 start
            for(Pick_Up_Options__c pickupOption: [SELECT Id, Name, Geography__r.Code__c, ECM_Product_Growth_Driver_Category__c FROM Pick_Up_Options__c WHERE Geography__r.Code__c =: countryCode])
            {
                productGrowthDriverMap.put(pickupOption.Name.subStringBefore('['),pickupOption);
            }
            
            for(ECM_Contract_Item__c conItem : [SELECT ECM_Product_growth_driver__c, ECM_Lead_Brand__c, ECM_Contract__c
                                                        FROM ECM_Contract_Item__c
                                                        WHERE ECM_Contract__c in:contractList])
            {
                if (productGrowthDriverMap.containsKey(conItem.ECM_Product_growth_driver__c)) {
                    pgdCategory = productGrowthDriverMap.get(conItem.ECM_Product_growth_driver__c).ECM_Product_Growth_Driver_Category__c;
                    
                    Boolean isPouring = false;
                    Boolean isDraught = false;
                    
                    if(pgdCategory == System.Label.ECM_Anniv_Pouring_Status && conItem.ECM_Lead_Brand__c) {
                        isPouring = true;
                    }
                    if(pgdCategory == System.Label.ECM_Anniv_Draught_Cocktail_Status) {
                        isDraught = true;
                    }
                    
                    /* If it is of pouring kind and not present in Draught list and in "both" list, and is also not already added from SDID check, add to Pouring list
* If it is of draught kind and not present in Pouring list and in "both" list, and is also not already added from SDID check, add to Draught list
* If it is neither draught nor pouring and not already added from SDID check,
* check if it is a pouring kind of PGD and there is a draught kind added from SD (or vice versa) and then add in both if not already there
* If above condition is not satisfied, it means there is a pouring kind of PGD as well as pouring kind of SD (or draught)
* So we need not go into "both" */
                    
                    if(isPouring && !idToContractPouring.contains(conItem.ECM_Contract__c) && !idToContractDraught.contains(conItem.ECM_Contract__c) && !idToContractBoth.contains(conItem.ECM_Contract__c)) {
                        idToContractPouring.add(conItem.ECM_Contract__c);
                    } else if(isDraught && !idToContractDraught.contains(conItem.ECM_Contract__c) && !idToContractPouring.contains(conItem.ECM_Contract__c) && !idToContractBoth.contains(conItem.ECM_Contract__c)) {
                        idToContractDraught.add(conItem.ECM_Contract__c);
                    } else {
                        if((isPouring && idToContractDraught.contains(conItem.ECM_Contract__c) && !idToContractBoth.contains(conItem.ECM_Contract__c)) ||
                           (isDraught && idToContractPouring.contains(conItem.ECM_Contract__c) && !idToContractBoth.contains(conItem.ECM_Contract__c)))
                        {
                            idToContractBoth.add(conItem.ECM_Contract__c);
                            if(idToContractPouring.contains(conItem.ECM_Contract__c)) {
                                idToContractPouring.remove(conItem.ECM_Contract__c);
                            }
                            if(idToContractDraught.contains(conItem.ECM_Contract__c)) {
                                idToContractDraught.remove(conItem.ECM_Contract__c);
                            }
                        }
                    }
                }
            }
            // ECM-6457 end
            
             if(idToContractPouring !=null && !idToContractPouring.isEmpty()){
                String str = eTemplate+'Pour';
                sendEmailListpour = prepareMailList(idToContractPouring,contractMap,str,-1);
            }
            if(idToContractDraught !=null && !idToContractDraught.isEmpty()){
                String str = eTemplate+'Drgt';
                sendEmailListdrgt = prepareMailList(idToContractDraught,contractMap,str,-1); 
            }
            if(idToContractBoth !=null && !idToContractBoth.isEmpty()){
                String str = eTemplate+'DrgtPour';
                sendEmailListboth = prepareMailList(idToContractBoth,contractMap,str,-1); 
            }
        
            if(sendEmailListpour != null && !sendEmailListpour.isEmpty()){
                sendEmailList.addAll(sendEmailListpour);
            }
            if(sendEmailListdrgt != null && !sendEmailListdrgt.isEmpty()){
                sendEmailList.addAll(sendEmailListdrgt);
            }
            if(sendEmailListboth != null && !sendEmailListboth.isEmpty()){
                sendEmailList.addAll(sendEmailListboth);
            }
        }
        
        if(!sendEmailList.isEmpty() && sendEmailList!= null && !Test.isRunningTest()){
            Messaging.sendEmail(sendEmailList);
        }
        
    }
    /*
    * @description : This method contains the logic of sending email to Either Rep or Customer
    * @return : Void
    * @param : Set<Id>,Map<ID,Contract>,String
    */
    public static List<Messaging.SingleEmailMessage> prepareMailList(Set<Id> conIds,Map<ID,Contract> contractMap,
                                                                     String str, Integer monthAhead){
        List<String> emailList = new List<String>();
        List<String> ccEmailList =new List<String>();
        String emailTempName = '';
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        if(conIds!=null && !conIds.isEmpty()){
            for(Id conID : conIds){
                if(contractMap.containsKey(conID)){
                    Contract contractRec=contractMap.get(conID);
                    Date sendDate = contractRec.StartDate.addMonths(monthAhead);
                    //if(System.today().year() > sendDate.year() && System.today().month() == sendDate.month() && System.today().day() == sendDate.day() ){
                        if(true){
                        if(contractRec.Owner.isActive && String.isNotBlank(contractRec.Owner.email)){
                            if (contractRec.ECM_Agreement_Type__r.ECM_Anniversary_Email_to_Customer__c == System.Label.ECM_Contract_Ownr_Line_Mgr_Anniversary_Mail && String.isNotBlank(contractRec.Owner.Manager.Email)){
                                emailList.add(contractRec.Owner.email);
                                ccEmailList.add(contractRec.Owner.Manager.Email);
                                emailTempName = str + 'Rep';
                            }else if(contractRec.ECM_Agreement_Type__r.ECM_Anniversary_Email_to_Customer__c == System.Label.ECM_Anniversary_To_Customer_Label && String.isNotBlank(contractRec.Account.Email_for_contracts_payments__c)){
                                emailList.add(contractRec.Account.Email_for_contracts_payments__c);
                                ccEmailList.add(contractRec.Owner.email);
                                emailTempName = str + 'Cust';
                            }
                        }
                        //get emailtemp from map- emailTemplateMap by giving emailTempName
                        //clear emailTempName string
                        if(emailTemplateMap.containsKey(emailTempName)){
                            EmailTemplate empTemp= emailTemplateMap.get(emailTempName);
                            emailTempName ='';
                            if(empTemp!=null){
                                sendEmailList.add(createEmailInstance(empTemp.Id,contractRec.OwnerId, contractRec.Id, emailList,ccEmailList));
                            }
                            emailList.clear();
                            ccEmailList.clear();
                        }
                    }
                }
            }
        }
        if(sendEmailList!=null && !sendEmailList.isEmpty()){
            return sendEmailList;
        }
        return null;
        
    }
    
    
    /*
	* @description : get email template
	* @return : EmailTemplate
	* @param : String, String
	*/
    public static Map<String,EmailTemplate> getEmailTemplate(String countryCode){
        String folderName = Label.ECM_Email_Temp_Folder_Name;
        Map<String,EmailTemplate> emailTemplateMap = new Map<String,EmailTemplate>();
        List<String> countryNames = Label.ECM_Anniv_Default_Template.split(',');
        List<String> countryIENames = Label.ECM_Anniv_Default_Template2.split(',');
        if(countryNames.contains(countryCode)){
            countryCode='ES';
        }
        if(countryIENames.contains(countryCode)){
            countryCode ='IE';
        }
        String templateName =Label.ECM_Contract_Anniv_Notif_Label;
        templateName +=countryCode+'%';
        for(EmailTemplate eT : [SELECT Id,Name,DeveloperName, FolderId, FolderName, IsActive, Body, Subject, Description 
                                FROM EmailTemplate 
                                WHERE Folder.Name =: folderName
                                AND DeveloperName LIKE :templateName]){
                                    if(!emailTemplateMap.containsKey(eT.DeveloperName)){
                                        emailTemplateMap.put(eT.DeveloperName,eT);
                                    }
                                    
                                }
        if(emailTemplateMap!=null && !emailTemplateMap.isEmpty()){
            return emailTemplateMap;
        }
        return null;
    }
    
    
    /*
    * @description : get email Instance
    * @return : Messaging.SingleEmailMessage
    * @param : String, String, String,List<String>
    */
    public static Messaging.SingleEmailMessage createEmailInstance(String empTempId, String contractOwnerId, String contractId,List<String> emailList,List<String> ccEmailList){
        Messaging.SingleEmailMessage emailInstance = Messaging.renderStoredEmailTemplate(empTempId,contractOwnerId, contractId);
        emailInstance.setReplyTo(Label.ECM_CustomerResponseEmailServiceAddress);
        emailInstance.setToAddresses(emailList);
        emailInstance.setCcAddresses(ccEmailList);    
        emailInstance.setSaveAsActivity(false);
        return emailInstance;
    }
    /*
    * @description : this list contains email instance corresponding to each contract which are satisfying condition, i.e, 2 Months before anniversary and Lead brand
    * @return : List<Messaging.SingleEmailMessage>
    * @param : List<Contract>,EmailTemplate
    */
    public static void createEmailListForAnniversaryIE (List<Contract> contractList,String countryCode, Map<String,EmailTemplate> emailTmpMap){
        Set<Id> conEmailList = new Set<Id>();
        List<String> countryIENames = Label.ECM_Anniv_Default_Template2.split(',');
        List<Messaging.SingleEmailMessage> sendConEmailList = new List<Messaging.SingleEmailMessage>();
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        String eTemplate = Label.ECM_Email_Template_String+'IE'+'Pour';
        if(contractList !=null && !contractList.isEmpty()){
            Map<Id,Contract> contractMap = new Map<Id,Contract>(contractList);
            Map<Id,ECM_Contract_Item__c> conWithConItemMap = new Map<Id,ECM_Contract_Item__c>();
            List<ECM_Contract_Item__c> conitem=new List<ECM_Contract_Item__c>();
            if(emailTmpMap!=null && !emailTmpMap.isEmpty()){
                emailTemplateMap.putAll(emailTmpMap);
            }
            for(ECM_Contract_Item__c conItemObj : [SELECT Id, ECM_Contract__c,ECM_Contract__r.ECM_ContractCountry__c 
                                                   FROM ECM_Contract_Item__c  
                                                   WHERE ECM_Lead_Brand__c =true
                                                   AND ECM_Contract__c IN : contractMap.keySet()]) 
            {
                conWithConItemMap.put(conItemObj.ECM_Contract__c,conItemObj);
            }
            for(Id conObjId : contractMap.keySet()){
                if(conWithConItemMap.containsKey(conObjId)){
                    Contract conObj = contractMap.get(conObjId);
                    if(conObj!= null && String.isNotBlank(conObj.ECM_Agreement_Type__r.ECM_Anniversary_Email_to_Customer__c)){
                        conEmailList.add(conObjId);
                    }
                }
            }
            if(!conEmailList.isEmpty()){
                String emailTempStr = eTemplate;
                sendConEmailList = prepareMailList(conEmailList,contractMap,emailTempStr,-2);
            }
            
        }
        if(sendConEmailList != null && !sendConEmailList.isEmpty()){
            sendEmailList.addAll(sendConEmailList);
        }
        if(sendEmailList!= null && !sendEmailList.isEmpty() && !Test.isRunningTest()){
            Messaging.sendEmail(sendEmailList);
        }
    }
}