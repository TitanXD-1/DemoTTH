/*
*@Name: ECM_ContractNotifcationMailHelper
*@Purpose: This batch is to send email notification to the owner of a contract when the expiry period for the contract starts
*
*@History                                                                                                                     
*VERSION		AUTHOR				DATE				DETAIL
*1.0		Subhodeep Sarkar	23/06/2022			Initial Development (ECM-5539)
*2.0		Anand U				11/22/2022			ECM-6384 Translation_Contract Expiration Email_German
*3.0		Saurav Prasad		10/07/2023			142555	:	CM static code violation for the classes_SFDC_Technical Debt
*4.0        Saurav/Doman        05/10/2023          146648 -  CM static code violation for the classes_SFDC_Global
*/

public without sharing class ECM_ContractNotifcationMailHelper {
    
    
    
    /*
* @description : get the lis of contracts and send mail to owner if notification date is today 
* @return : void
* @param : List<Contract>
*/
    public static void sendNotificationMail(List<Contract> contractList, String countryCode){
        List<Messaging.SingleEmailMessage> sendEmailList = new List<Messaging.SingleEmailMessage>();
        Map<Id,string> contractVsEmailMap = new Map<Id,String>();   //NOPMD
        String folderName = Label.ECM_Email_Temp_Folder_Name;
        //List<String> en_us_countries = Label.ECM_En_US_countries.split(',');//GB,IE
        List<String> esCountry = Label.ECM_ES_Countries.split(',');//ES
        String templateName = '';
        EmailTemplate empTemp = new EmailTemplate();
        
        if (esCountry.contains(countryCode)){
            templateName = Label.ECM_Contract_End_Date_Notification_ES;
        }else{
            templateName = Label.ECM_Contract_Exp_Template_Name;
        }
        
        empTemp = [SELECT Id,Name,DeveloperName, FolderId, FolderName, IsActive, Body, Subject, Description 
                                     FROM EmailTemplate 
                                     WHERE Folder.Name =:folderName 
                                     AND name =: templateName WITH SECURITY_ENFORCED];
        for(Contract contractRec: contractList){
            List<String> emailList = new List<String>();
            Date notificationDate = contractRec.Contract_End_Date__c.addMonths(-Integer.valueOf(contractRec.ECM_Agreement_Type__r.ECM_Expiration_Start_Date_Rule_in_Months__c));
            if(notificationDate == System.today() && (contractRec.ECM_Duration__c > contractRec.ECM_Agreement_Type__r.ECM_Expiration_Start_Date_Rule_in_Months__c )){
                if(String.isNotBlank(contractRec.Owner.email)){
                    emailList.add(contractRec.Owner.email);
		            contractRec.ECM_Expiration_Notification_sent__c = true;
                }
                Messaging.SingleEmailMessage emailInstance = getRenderEmail(empTemp,contractRec);       //146648
                emailInstance.setToAddresses(emailList);
                emailInstance.setSaveAsActivity(false);
                sendEmailList.add(emailInstance);
                emailList.clear();
            }
        }
        if(!sendEmailList.isEmpty()){
            Messaging.sendEmail(sendEmailList);
        }
        
        if(!contractList.isEmpty()){
            Database.update(contractList);
        }
    }
    public static Messaging.SingleEmailMessage getRenderEmail(EmailTemplate empTemp, Contract contractRec){         //146648
        return Messaging.renderStoredEmailTemplate(empTemp.id,contractRec.OwnerId, contractRec.Id);
    }
}