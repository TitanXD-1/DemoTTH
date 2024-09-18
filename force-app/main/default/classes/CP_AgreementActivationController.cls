public class CP_AgreementActivationController {
	
    @InvocableMethod(label='Activate Scheduled Agreement')
    public static void doScheduledActivation(List<String> agreementIdList) {
        System.debug('CP - in Activate Scheduled Agreement method');
        
        if(agreementIdList.size() > 0) {
            CP_AgreementActivationController.doActivation(agreementIdList.get(0));
        }
    }
    
    @AuraEnabled
    public static String doActivation(String agreementId) {
        System.debug('CP - in CP_AgreementActivationController.doActivation() method. agreementId: ' + agreementId);
        MD_JSONResponse response = new MD_JSONResponse();

        try {

            String activationResult = performAgreementActivation(agreementId);
            if(String.isEmpty(activationResult)) {
                response.status = true;
                response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
                response.message = 'Agreement activated successfully';
            }else {
                throw new AgreementException(activationResult);
            }
            
        }catch(Exception e) {
            response.status = false;
            response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            response.message = e.getMessage();
        }

        return JSON.serialize(response);
    }
	
    @AuraEnabled
    public static String doClone(String agreementId) {
        System.debug('CP - in CP_AgreementActivationController.doClone() method. agreementId: ' + agreementId);
        MD_JSONResponse response = new MD_JSONResponse();

        try {
            String newAgreementId = performAgreementClone(agreementId);
            
            response.status = true;
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            response.message = newAgreementId;
            
        }catch(Exception e) {
            response.status = false;
            response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            response.message = e.getMessage();
        }

        return JSON.serialize(response);
    }
    
    @TestVisible
    private static String performAgreementActivation(String agreementId) {
        String result = null;

        List<CP_Agreement__c> agreementsForUpdate = new List<CP_Agreement__c>();

        Id activeAgreementRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Active').getRecordTypeId();
        Id draftAgreementRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Draft').getRecordTypeId();
        Id scheduledAgreementRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Scheduled').getRecordTypeId();
        Id archivedAgreementRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Archived').getRecordTypeId();

        CP_Agreement__c agreement = [SELECT Id, AgreementBody__c, Type__c, Cluster__c, Cluster__r.Name, Portal__c, RecordTypeId
                                        FROM CP_Agreement__c WHERE Id = :agreementId];
        
        System.debug('CP - in CP_AgreementActivationController.performAgreementActivation() method. agreement: ' + agreement);
		
        if(agreement.RecordTypeId != draftAgreementRtId && agreement.RecordTypeId != scheduledAgreementRtId) {
            result = 'This Agreement cannot be activated because is not a Draft nor Scheduled type';
        }else {
        	if(String.isNotEmpty(agreement.AgreementBody__c)) {
                /** Archiving Previous Versions - BEGIN */
                Set<String> toArchiveAgreementIds = new Set<String>();
    
                List<CP_Agreement__c> toArchiveAgreements = [SELECT Id, Version__c
                                                                FROM CP_Agreement__c 
                                                                WHERE RecordTypeId = :activeAgreementRtId 
                                                                    AND Type__c = :agreement.Type__c
                                                                    AND Cluster__c = :agreement.Cluster__c
                                                                    AND Portal__c = :agreement.Portal__c
                                                             		AND RecordTypeId = :activeAgreementRtId
                                                                ORDER BY Version__c DESC];
    
                System.debug('CP - in CP_AgreementActivationController.performAgreementActivation() method. toArchiveAgreements: ' + toArchiveAgreements);
    
                for(CP_Agreement__c toArchiveAgreement : toArchiveAgreements) {
                    toArchiveAgreement.RecordTypeId = archivedAgreementRtId;
                    toArchiveAgreementIds.add(toArchiveAgreement.Id);
                }
    
                agreementsForUpdate.addAll(toArchiveAgreements);
                /** Archiving Previous Versions - END */
    
                agreement.RecordTypeId = activeAgreementRtId;
    
                if(toArchiveAgreements.size() > 0) {
                    agreement.Version__c = (toArchiveAgreements.get(0).Version__c + 1);
                    agreement.PreviousVersion__c = toArchiveAgreements.get(0).Id;
                }else {
                    agreement.Version__c = 1;
                }
    
                agreement.Name = agreement.Portal__c + ' - ' + agreement.Cluster__r.Name + ' - ' + agreement.Type__c + ' - ' + 'v' + agreement.Version__c;
                agreement.PublishedDate__c = DateTime.now();
                System.debug('CP - in CP_AgreementActivationController.performAgreementActivation() method. updated agreement: ' + agreement);
    
                agreementsForUpdate.add(agreement);
    
                update agreementsForUpdate;
                
                /** Update Previous Contact Agreements - BEGIN */
                List<CP_ContactAgreement__c> toUpdateContactAgreements = new List<CP_ContactAgreement__c>();
    			
                System.debug('CP - in CP_AgreementActivationController.performAgreementActivation() method. toArchiveAgreementIds: ' + toArchiveAgreementIds);
                
                List<CP_ContactAgreement__c> toDeprecateContactAgreements = [SELECT Id, Acceptance__c, CurrentAgreement__c
                                                                                FROM CP_ContactAgreement__c 
                                                                                WHERE CurrentAgreement__c IN :toArchiveAgreementIds];
                for(CP_ContactAgreement__c dca : toDeprecateContactAgreements) {
                    CP_ContactAgreement__c ndca = new CP_ContactAgreement__c();
                    ndca.Id = dca.Id;
                    ndca.PreviousAcceptance__c = dca.Acceptance__c;
                    ndca.PreviousAgreement__c = dca.CurrentAgreement__c;
                    ndca.CurrentAgreement__c = null;
                    ndca.Acceptance__c = null;
    
                    toUpdateContactAgreements.add(ndca);
                }
    
                update toUpdateContactAgreements;
                /** Update Previous Contact Agreements - END */
    
            }else {
                result = Label.CP_AgreementEmptyBodyError;
            }
        }

        return result;
    }
	
    @TestVisible
    private static String performAgreementClone(String agreementId) {
        String result = null;

        List<CP_Agreement__c> agreementsForUpdate = new List<CP_Agreement__c>();

        Id draftAgreementRtId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByName().get('Draft').getRecordTypeId();
		
        try {
            CP_Agreement__c agreement = [SELECT Id, AgreementBody__c, Type__c, Cluster__c, Portal__c, Order__c
                                     	FROM CP_Agreement__c 
                                     	WHERE Id = :agreementId];
        
            System.debug('CP - in CP_AgreementActivationController.performAgreementClone() method. agreement: ' + agreement);
            
            CP_Agreement__c newAgreement = new CP_Agreement__c();
            newAgreement.RecordTypeId = draftAgreementRtId;
            newAgreement.AgreementBody__c = agreement.AgreementBody__c;
            newAgreement.Type__c = agreement.Type__c;
            newAgreement.Cluster__c = agreement.Cluster__c;
            newAgreement.Portal__c = agreement.Portal__c;
            newAgreement.Order__c = agreement.Order__c;
            
            insert newAgreement;
            result = newAgreement.Id;
        }catch(Exception e) {
            System.debug('CP - in CP_AgreementActivationController.performAgreementClone() method. Exception - e.getMessage(): ' + e.getMessage());
            result = e.getMessage();
        }
        
        return result;
    }

    @AuraEnabled
    public static String doSchedule(CP_Agreement__c record) {
        System.debug('CP - in CP_AgreementActivationController.doSchedule() method. record.Id: ' + record.Id);
        MD_JSONResponse response = new MD_JSONResponse();
		
        CP_Agreement__c agreement = new CP_Agreement__c(
            Id = record.Id,
            PublishDate__c = record.PublishDate__c,
            RecordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByDeveloperName().get('Scheduled').getRecordTypeId(),
            Scheduled__c = true
        );
        try {

            update agreement;

            response.status = true;
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            response.message = 'Agreement scheduled successfully';
            
        }catch(Exception e) {
            response.status = false;
            response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            response.message = e.getMessage();
        }

        return JSON.serialize(response);
    }
    
    public class AgreementException extends Exception {
        
    }
}