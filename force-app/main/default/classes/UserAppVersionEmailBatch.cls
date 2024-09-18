global class UserAppVersionEmailBatch implements Database.Batchable<sobject>,Database.AllowsCallouts, Database.Stateful{

	global Database.Querylocator start (Database.BatchableContext BC) {
        return Database.getQueryLocator('Select Id, Name from Sync_Stat__c LIMIT 1');
    }
    
	global void execute(Database.BatchableContext BC, List<sobject> scope) {
	try{
	 //Get Email Id from Custom Setting

			UserAppVersionSetting__c userappversionreportSetting = UserAppVersionSetting__c.getOrgDefaults();

 			//Get Email Template
			EmailTemplate emailTemplate = [select Id, Body from EmailTemplate where DeveloperName = 'App_Version_Status_Template'];

	//Set Subject
			string emailSubject = 'Market App Version Details' + ' - ' + Date.Today().format();

			System.debug('@@emailTemplate' +emailTemplate ); 

			if(userappversionreportSetting != null){
                	List<string> emailIds = new List<string>();
                	string tempStr = '';
                	if(userappversionreportSetting.Email__c != null && userappversionreportSetting.Email__c != '')
                    	tempStr += userappversionreportSetting.Email__c;
                	if(userappversionreportSetting.Email1__c != null && userappversionreportSetting.Email1__c != '')
                    	tempStr += userappversionreportSetting.Email1__c;
 					//Creating Email Ids List
                	if(tempStr != '')
                    	emailIds = tempStr.split(';');
      				//Email
                	if(emailIds.size()>0){
                    	Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    	email.setToAddresses(emailIds);
                    	email.setTemplateId(emailTemplate.Id);
                    	email.setTargetObjectId(UserInfo.getUserId());
                    	//email.setSubject(emailSubject);
                    	email.saveAsActivity = false;
                     	Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
                    	Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    	if (results[0].success) {
                        	system.debug('@@Email has been sent successfully');
                    	}
                    	else {
                        	system.debug('@@Email failed to send: ' + results[0].errors[0].message);	
                    	}              

				}
			}
		}
		catch(Exception ex){
     		system.debug('@@Exception' + ex);
 		}
 	}
    
 	global void finish(Database.BatchableContext BC){
 
                
 	}
 
}