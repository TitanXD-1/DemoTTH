global class scheduledUserAppReport implements Schedulable {
    
    global void execute(SchedulableContext sc) {
        try{
            //Get Email Id from Custom Setting
            
            UserAppVersionSetting__c userappversionSetting = UserAppVersionSetting__c.getOrgDefaults();
            Integer Size = Integer.valueOf(userappversionSetting.Size__c);
            if(size!= Null){
                EDGE_UserAppSyncVersionBatch uac = new EDGE_UserAppSyncVersionBatch();
        		Database.executeBatch(uac,size);
            }
            /*
            
            //Get Email Template
            EmailTemplate emailTemplate = [select Id, Body from EmailTemplate where DeveloperName = 'App_Version_Status_Template'];
            
            //Set Subject
            string emailSubject = 'Market App Version Details' + ' - ' + Date.Today().format();
            
            
            
            if(userappversionSetting != null){
                List<string> emailIds = new List<string>();
                string tempStr = '';
                if(userappversionSetting.Email__c != null && userappversionSetting.Email__c != '')
                    tempStr += userappversionSetting.Email__c;
                
                if(userappversionSetting.Email1__c != null && userappversionSetting.Email1__c != '')
                    tempStr += userappversionSetting.Email1__c;
                
                //Creating Email Ids List
                if(tempStr != '')
                    emailIds = tempStr.split(';');
                //Email
                if(emailIds.size()>0){
                    //Newly Added
                    Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                    blob csvBlob = UserAppVersionController.sendEmailAttach();
                    string csvname= 'Users Not On Latest Version.csv';
                    csvAttc.setFileName(csvname);
                    csvAttc.setBody(csvBlob);
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(emailIds);
                    email.setTemplateId(emailTemplate.Id);
                    email.setTargetObjectId(UserInfo.getUserId());
                    email.saveAsActivity = false;
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
                    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    if (results[0].success) {
                        system.debug('@@Email has been sent successfully');
                        EDGE_UtilityClass.printGovLimits(48);
                    }
                    else {
                        system.debug('@@Email failed to send: ' + results[0].errors[0].message);
                    }              
                    
                    
                }
            }*/
        }
        catch(Exception ex){
            system.debug('@@Exception' + ex);
        }
    }
}