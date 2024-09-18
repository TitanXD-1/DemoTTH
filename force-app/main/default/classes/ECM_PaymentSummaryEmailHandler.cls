/*
* Class Name: ECM_PaymentSummaryEmailHandler
* Author: Keshava Murthy M
* Brief Description: This class is used to send Email based on Payment Summary fields updated by "ECM Payment Summary Process" Process.
* Created Date: 03/04/2020
* History: 
Keshav 	- ECM-103 SFDC_GLO_Logic: email request for evidence generation
Amit   - ECM-92 SFDC_GLO_Logic: email request for invoice generation 
Veerendra  Billakurthi- ECM-3680 Tech Debt - ECM_PaymentSummaryEmailHandler - 01-02-2021
Keshav 	ECM-3974 Email for payments requests (evidence/invoices)_GLO_payment management 10-04-2021
Pratik & Tanishq  - ECM-6351 - Regression_Defect : Request for evidence mail is triggering twice
*/

public class ECM_PaymentSummaryEmailHandler {
    @InvocableMethod(label='Payment Summary Emails Apex Class' description='Sends an email')
    public static void sendEmail(List<Id> paySumId)
    {   
        try{
            String body;            
            Set<Id> accIds = new Set<Id>();
            Set<Id> geoCountry = new Set<Id>();
            Set<String> geoCountryName=new Set<String>();
            Map<Id,String>psToGeoCode = new Map<Id,String>();
            Map<String,Boolean> countToTech =new Map<String,Boolean>();
            List<ECM_Payment_Summary__c> paySumIds = new List<ECM_Payment_Summary__c>();
            //set<Id> payIds = new set<Id>();
            List<AccountContactRelation> accConObj = new List<AccountContactRelation>();
            List<Market_Setting__c> marketObj = new List<Market_Setting__c>();
            List<Market_Setting__c> marketObj1 = new List<Market_Setting__c>();
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            
            Map<Id,List<String>> payManageMap = new Map<Id,List<String>>();
            Map<Id,Id> conIdMap = new Map<Id,Id>();
            Map<Id,List<String>> accPayEmailMap = new Map<Id,List<String>>();
            //ECM-6351
            Set<String> psStatus = new Set<String>{'Approved','Submitted','Completed','In Approval process'};
            List<ECM_Payment_Summary__c> updtPaySum = new List<ECM_Payment_Summary__c>();
            //Payment Summary List
            paySumIds = [SELECT id, Name,ECM_Invoice_Status__c,ECM_Country_Code__c,ECM_Type__c,
                        ECM_Contract__r.Owner.email,ECM_Contract__r.Account.Country_Code__c,
                        ECM_Payment_Summary_Status__c, ECM_Email_Sent__c, ECM_SAP_payment_Reference_Number__c, 
                        ECM_Contract__r.Name, ECM_Contract__r.AccountId, ECM_Contract__r.Account.Country__c,
                        ECM_Contract__r.Account.Country__r.Name,ECM_No_Invoice_Required__c,
                        ECM_Contract__r.Account.Email_for_contracts_payments__c,ECM_Evidence_Attachment__c 
                        FROM ECM_Payment_Summary__c 
                        WHERE id IN:paySumId];
            
            for(ECM_Payment_Summary__c payRecords : paySumIds)
            {
                accIds.add(payRecords.ECM_Contract__r.AccountId); //Customer linked to Payment Summary
                geoCountry.add(payRecords.ECM_Contract__r.Account.Country__c); //Customer country
                geoCountryName.add(payRecords.ECM_Contract__r.Account.Country__r.Name);
                if(payRecords.ECM_Contract__r.Account.Country_Code__c!=null&&!psToGeoCode.containsKey(payRecords.Id)){
                    psToGeoCode.put(payRecords.Id,payRecords.ECM_Contract__r.Account.Country_Code__c);
                }
                /* ECM-3974 */
                if(payRecords.ECM_Contract__r.Account.Email_for_contracts_payments__c!=null){
                    if(!accPayEmailMap.containsKey(payRecords.ECM_Contract__r.AccountId)){
                        accPayEmailMap.put(payRecords.ECM_Contract__r.AccountId,new List<String>{payRecords.ECM_Contract__r.Account.Email_for_contracts_payments__c});
                    }
                    else{
                        accPayEmailMap.get(payRecords.ECM_Contract__r.AccountId).add(payRecords.ECM_Contract__r.Account.Email_for_contracts_payments__c);
                    }
                }
            }
            
            List<String> countryCheck= new List<String>();
            
            // Market Setting Related to Payment Summary
            marketObj = [SELECT Id, Name__c,ECM_Evidence_email_enabled__c, ECM_Payment_Evidence_Pre_Payment_SP__c,ECM_Payment_Evidence_Pre_Payment__c,ECM_Payment_Evidence_SP_template__c,
                         ECM_Payment_Evidence_template__c,ECM_Payment_Invoice_SP_template__c,ECM_Payment_Invoice_template__c, ECM_Payment_Management_Email__c, Geography__c,Geography__r.Code__c, Geography__r.Name FROM Market_Setting__c WHERE Geography__c IN : geoCountry AND ECM_Evidence_email_enabled__c =true];
                        
            for(Market_Setting__c marketCountry : marketObj){
                countryCheck.add(marketCountry.Geography__r.Code__c);
            }
            // Market Setting Email Map
            if(marketObj.size()>0){
                for(Market_Setting__c marketEmail : marketObj){                
                    if(!payManageMap.containsKey(marketEmail.Geography__c)){
                        payManageMap.put(marketEmail.Geography__c,new List<String>{marketEmail.ECM_Payment_Management_Email__c});
                    }
                    else{
                        payManageMap.get(marketEmail.Geography__c).add(marketEmail.ECM_Payment_Management_Email__c);
                    }
                }
            }
            map<string,id> tempmap = new map<string,id>();
            list<string> templatelist = new list<string>();
            if(marketObj.size()>0){
                for(Market_Setting__c marketEmail : marketObj){ 
                    templatelist.add(marketEmail.ECM_Payment_Evidence_Pre_Payment_SP__c);
                    templatelist.add(marketEmail.ECM_Payment_Evidence_Pre_Payment__c);
                    templatelist.add(marketEmail.ECM_Payment_Evidence_template__c);
                    templatelist.add(marketEmail.ECM_Payment_Evidence_SP_template__c);
                    templatelist.add(marketEmail.ECM_Payment_Invoice_SP_template__c);
                    templatelist.add(marketEmail.ECM_Payment_Invoice_template__c);                    
                }
            }
            
            //templatelist.add();
            OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where Address =: Label.ECM_OrgWideEmailAddress limit 1];
            list<EmailTemplate> emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where DeveloperName in : templatelist ];
            for( EmailTemplate temp : emailTemplate){
                tempmap.put(temp.DeveloperName, temp.id)  ;              
            }
            
            //Logic to send email for each Payment Summary record
            List<ECM_Technical_Market_Setting__mdt> techMarkets = [SELECT Id,ECM_Invoice_Request__c,ECM_Country__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_Country__c IN:psToGeoCode.values()];
            for(ECM_Technical_Market_Setting__mdt market : techMarkets){
                if(!countToTech.containsKey(market.ECM_Country__c)){
                    countToTech.put(market.ECM_Country__c,market.ECM_Invoice_Request__c);
                }
            }
            
            for(ECM_Payment_Summary__c mailPS : paySumIds)
            {
                if(countryCheck.contains(mailPS.ECM_Country_Code__c)){
                    
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setOrgWideEmailAddressId(owa.id);      
                    
                    if(accPayEmailMap.values().size() > 0 && accPayEmailMap.containsKey(mailPS.ECM_Contract__r.AccountId)){
                        mail.setToAddresses(accPayEmailMap.get(mailPS.ECM_Contract__r.AccountId));                        
                    }                    
                    else if(payManageMap.containsKey(mailPS.ECM_Contract__r.Account.Country__c) && payManageMap.size()>0){
                        mail.setToAddresses(payManageMap.get(mailPS.ECM_Contract__r.Account.Country__c));
                    } 
                   if(payManageMap.size()>0){
                        mail.setReplyTo(payManageMap.get(mailPS.ECM_Contract__r.Account.Country__c)[0]);
                    } 
                    
                    Boolean invoiceRequest = countToTech.get(mailPS.ECM_Contract__r.Account.Country_Code__c);
                    if(mailPS.ECM_Payment_Summary_Status__c == 'Submitted' && mailPS.ECM_Email_Sent__c == false && invoiceRequest){//For AU market setting flag=true                
                        id templeteid = tempmap.get(marketObj[0].ECM_Payment_Invoice_template__c);
                        id templeteidSP =  tempmap.get(marketObj[0].ECM_Payment_Invoice_SP_template__c);                    
                        if (templeteid!=null){
                            mail.setTemplateID(templeteid);
                        }
                        else {
                            mail.setTemplateID(templeteidSP);                                
                        }  
                    }
                    else if(mailPS.ECM_Payment_Summary_Status__c == 'Approved' && mailPS.ECM_Email_Sent__c == false && mailPS.ECM_No_Invoice_Required__c == false  && mailPS.ECM_Type__c == 'Non-Volume'){
                        mail.setTemplateID(tempmap.get(marketObj[0].ECM_Payment_Invoice_template__c));
                        //payIds.add(mailPS.Id);
                    } 
                    //ECM-6351
                    else if(mailPS.ECM_Type__c == 'Promo-Standard' && !mailPS.ECM_Email_Sent__c && psStatus.contains( mailPS.ECM_Payment_Summary_Status__c)
                    && !(mailPS.ECM_Evidence_Attachment__c)){
                        
                        id templeteid = tempmap.get(marketObj[0].ECM_Payment_Evidence_template__c);  
                        id templeteidSP = tempmap.get(marketObj[0].ECM_Payment_Evidence_SP_template__c);  
                        
                        if (templeteid!=null){
                            mail.setTemplateID(templeteid);
                        }
                        else{
                            mail.setTemplateID(templeteidSP);
                        }
                        mailPS.ECM_Email_Sent__c = true;
                        updtPaySum.add(mailPS);
                    } 
                    //ECM-6351
                    else if(mailPS.ECM_Type__c == 'Promo-PrePayment' && mailPS.ECM_SAP_payment_Reference_Number__c!= null
                    && !(mailPS.ECM_Evidence_Attachment__c)){
                        
                        id templeteid = tempmap.get(marketObj[0].ECM_Payment_Evidence_Pre_Payment__c);
                        id templeteidSP = tempmap.get(marketObj[0].ECM_Payment_Evidence_Pre_Payment_SP__c);
                        if (templeteid!=null){
                            mail.setTemplateID(templeteid);
                        }
                        else{
                            mail.setTemplateID(templeteidSP); 
                            mail.setSaveAsActivity(false);
                        }                        
                    }
                    //mail.setReplyTo(Label.ECM_CustomerResponseEmailServiceAddress);
                    mail.setTargetObjectId(userinfo.getuserid());
                    mail.setTreatTargetObjectAsRecipient(false);                    
                    mail.setWhatId(mailPS.Id);                    
                    mail.setHtmlBody(body);
                    allmsg.add(mail);
                    system.debug('allmsg-->'+allmsg);
                }
            }
            if(!allmsg.isEmpty()){
                Messaging.sendEmail(allmsg);
                //ECM-6351
                if(!updtPaySum.isEmpty()){
                    updatePS(updtPaySum);
                } 
            }                   
        }catch(Exception e){
            System.debug('Exception Caught in sendEmail method in ECM_PaymentSummaryEmailHandler class at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
	//ECM-6351
    public static void updatePS(List<ECM_Payment_Summary__c> updtPaySum){
        update updtPaySum;
    }
    
    public static void sendInvEmail(List<Id> paySumId){
        try{
            String body;
            
            Set<Id> accIds = new Set<Id>();
            Set<Id> geoCountry = new Set<Id>();
            Set<String> geoCountryName=new Set<String>();
            Map<Id,String>psToGeoCode = new Map<Id,String>();
            Map<String,Boolean> countToTech =new Map<String,Boolean>();
            List<ECM_Payment_Summary__c> paySumIds = new List<ECM_Payment_Summary__c>();
            //set<Id> payIds = new set<Id>();
            List<AccountContactRelation> accConObj = new List<AccountContactRelation>();
            List<Market_Setting__c> marketObj = new List<Market_Setting__c>();
            List<Market_Setting__c> marketObj1 = new List<Market_Setting__c>();
            List<Messaging.SingleEmailMessage> allmsg = new List<Messaging.SingleEmailMessage>();
            
            Map<Id,List<String>> payManageMap = new Map<Id,List<String>>();
            Map<Id,Id> conIdMap = new Map<Id,Id>();
            Map<Id,List<String>> accPayEmailMap = new Map<Id,List<String>>();
            List<string> setCCaddress = new List<string>();//ECM-5870
            Map<Id,String> newcontractOwnerEmailId =  new Map<Id,String>();
            
            //Payment Summary List
            paySumIds = [SELECT id, Name,ECM_Invoice_Status__c,ECM_Country_Code__c,ECM_Type__c,ECM_Contract__r.Owner.email,ECM_Contract__r.Account.Country_Code__c, ECM_Payment_Summary_Status__c, ECM_Email_Sent__c, ECM_SAP_payment_Reference_Number__c, ECM_Contract__r.Name, ECM_Contract__r.AccountId, ECM_Contract__r.Account.Country__c,ECM_Contract__r.Account.Country__r.Name,ECM_No_Invoice_Required__c,ECM_Contract__r.Account.Email_for_contracts_payments__c FROM ECM_Payment_Summary__c where id IN:paySumId];
            
            for(ECM_Payment_Summary__c payRecords : paySumIds)
            {
                accIds.add(payRecords.ECM_Contract__r.AccountId); //Customer linked to Payment Summary
                //contractOwnerEmailId = payRecords.ECM_Contract__r.Owner.email;//ECM-5870
                newcontractOwnerEmailId.put(payRecords.Id,payRecords.ECM_Contract__r.Owner.email);
                geoCountry.add(payRecords.ECM_Contract__r.Account.Country__c); //Customer country
                geoCountryName.add(payRecords.ECM_Contract__r.Account.Country__r.Name);
                if(payRecords.ECM_Contract__r.Account.Country_Code__c!=null&&!psToGeoCode.containsKey(payRecords.Id)){
                    psToGeoCode.put(payRecords.Id,payRecords.ECM_Contract__r.Account.Country_Code__c);
                }
                /* ECM-3974 */
                if(payRecords.ECM_Contract__r.Account.Email_for_contracts_payments__c!=null){
                    if(!accPayEmailMap.containsKey(payRecords.ECM_Contract__r.AccountId)){
                        accPayEmailMap.put(payRecords.ECM_Contract__r.AccountId,new List<String>{payRecords.ECM_Contract__r.Account.Email_for_contracts_payments__c});
                    }
                    else{
                        accPayEmailMap.get(payRecords.ECM_Contract__r.AccountId).add(payRecords.ECM_Contract__r.Account.Email_for_contracts_payments__c);
                    }
                }
            }            
            List<String> countryCheck= new List<String>(); 
            //Map<String,Market_Setting__c> marktGeog = new Map<String,Market_Setting__c>();
            // Market Setting Related to Payment Summary
            marketObj = [SELECT Id, Name__c,ECM_Evidence_email_enabled__c, ECM_Payment_Evidence_Pre_Payment_SP__c,ECM_Payment_Evidence_Pre_Payment__c,ECM_Payment_Evidence_SP_template__c,
                         ECM_Payment_Evidence_template__c,ECM_Payment_Invoice_SP_template__c,ECM_Payment_Invoice_template__c, ECM_Payment_Management_Email__c, Geography__c,Geography__r.Code__c, Geography__r.Name FROM Market_Setting__c WHERE Geography__c IN : geoCountry ];            
            for(Market_Setting__c marketCountry : marketObj){
                countryCheck.add(marketCountry.Geography__r.Code__c);
                //marktGeog.put(marketCountry.Geography__r.Code__c,marketCountry);
            }
            
            // Market Setting Email Map
            if(marketObj.size()>0){
                for(Market_Setting__c marketEmail : marketObj){                
                    if(!payManageMap.containsKey(marketEmail.Geography__c)){
                        payManageMap.put(marketEmail.Geography__c,new List<String>{marketEmail.ECM_Payment_Management_Email__c});
                    }
                    else{
                        payManageMap.get(marketEmail.Geography__c).add(marketEmail.ECM_Payment_Management_Email__c);
                    }
                }
            }
            map<string,id> tempmap = new map<string,id>();
            list<string> templatelist = new list<string>();
            if(marketObj.size()>0){
                for(Market_Setting__c marketEmail : marketObj){ 
                    templatelist.add(marketEmail.ECM_Payment_Evidence_Pre_Payment_SP__c);
                    templatelist.add(marketEmail.ECM_Payment_Evidence_Pre_Payment__c);
                    templatelist.add(marketEmail.ECM_Payment_Evidence_template__c);
                    templatelist.add(marketEmail.ECM_Payment_Evidence_SP_template__c);
                    templatelist.add(marketEmail.ECM_Payment_Invoice_SP_template__c);
                    templatelist.add(marketEmail.ECM_Payment_Invoice_template__c);                    
                }
            }            
            //templatelist.add();
            OrgWideEmailAddress owa = [select id, Address, DisplayName from OrgWideEmailAddress where Address =: Label.ECM_OrgWideEmailAddress limit 1];
            list<EmailTemplate> emailTemplate = [Select Id, Subject, Description, HtmlValue, DeveloperName, Body from EmailTemplate where DeveloperName in : templatelist ];
            for( EmailTemplate temp : emailTemplate){
                tempmap.put(temp.DeveloperName, temp.id)  ;              
            }            
            //Logic to send email for each Payment Summary record
            List<ECM_Technical_Market_Setting__mdt> techMarkets = [SELECT Id,ECM_Invoice_Request__c,ECM_Country__c FROM ECM_Technical_Market_Setting__mdt WHERE ECM_Country__c IN:psToGeoCode.values()];
            for(ECM_Technical_Market_Setting__mdt market : techMarkets){
                if(!countToTech.containsKey(market.ECM_Country__c)){
                    countToTech.put(market.ECM_Country__c,market.ECM_Invoice_Request__c);
                }
            }
            for(ECM_Payment_Summary__c mailPS : paySumIds){
                if(countryCheck.contains(mailPS.ECM_Country_Code__c)){
                    Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                    mail.setOrgWideEmailAddressId(owa.id);                          
                    if(accPayEmailMap.values().size() > 0 && accPayEmailMap.containsKey(mailPS.ECM_Contract__r.AccountId)){
                        mail.setToAddresses(accPayEmailMap.get(mailPS.ECM_Contract__r.AccountId));                        
                    }                    
                    else if(payManageMap.containsKey(mailPS.ECM_Contract__r.Account.Country__c) && payManageMap.size()>0){
                        mail.setToAddresses(payManageMap.get(mailPS.ECM_Contract__r.Account.Country__c));
                    } 
                    if(payManageMap.size()>0){
                        mail.setReplyTo(payManageMap.get(mailPS.ECM_Contract__r.Account.Country__c)[0]);
                    } 
                    Boolean invoiceRequest = countToTech.get(mailPS.ECM_Contract__r.Account.Country_Code__c);
                    if(!invoiceRequest && mailPS.ECM_Invoice_Status__c == 'Requested'){
                        if(!payManageMap.isEmpty() && payManageMap.get(mailPS.ECM_Contract__r.Account.Country__c)!=null ){                     
                            setCCaddress.addAll(payManageMap.get(mailPS.ECM_Contract__r.Account.Country__c));
                        }
                        //ECM-5870
                        if(newcontractOwnerEmailId.containsKey(mailPS.Id) && newcontractOwnerEmailId.get(mailPS.Id) != null){
                            setCCaddress.add(newcontractOwnerEmailId.get(mailPS.Id));
                        }                        
                        id templeteid = tempmap.get(marketObj[0].ECM_Payment_Invoice_template__c);
                        id templeteidSP =  tempmap.get(marketObj[0].ECM_Payment_Invoice_SP_template__c); 
                        //id templeteid = tempmap.get(marktGeog.get(mailPS.ECM_Contract__r.Account.Country__c).ECM_Payment_Invoice_template__c);
                        //id templeteidSP =  tempmap.get(marktGeog.get(mailPS.ECM_Contract__r.Account.Country__c).ECM_Payment_Invoice_SP_template__c);                        
                        if (templeteid!=null && mailPS.ECM_Type__c=='Volume-Based'){
                            mail.setTemplateID(templeteid);
                        }
                        else if(templeteidSP!=null && (mailPS.ECM_Type__c == 'Promo-Standard' || mailPS.ECM_Type__c == 'Promo-PrePayment')){
                            mail.setTemplateID(templeteidSP);                                
                        }
                    }
                    mail.setReplyTo(Label.ECM_CustomerResponseEmailServiceAddress);
                    mail.setTargetObjectId(userinfo.getuserid());
                    mail.setTreatTargetObjectAsRecipient(false);                    
                    mail.setWhatId(mailPS.Id);
                    if(setCCaddress!=null){
                        mail.setCcAddresses(setCCaddress);//ECM-5870
                    }                    
                    mail.setHtmlBody(body);
                    allmsg.add(mail);
                    system.debug('allmsg-->'+allmsg);
                }
            }
            if(!allmsg.isEmpty()){
                Messaging.sendEmail(allmsg);
            }
        }catch(Exception e){
            System.debug('Exception Caught in sendInvEmail method in ECM_PaymentSummaryEmailHandler class at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }        
    }
    
}