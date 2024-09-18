public class CP_AgreementArchivingController {
    
	@auraEnabled
    public static CP_Agreement__c getAgreement(Id recordId){        
		return [SELECT Id, Type__c, Portal__c, Cluster__r.Name FROM CP_Agreement__c WHERE Id =: recordId];
    }    
    
	@auraEnabled
    public static Object doArchive(Id recordId){
        
        Id recordTypeId = Schema.SObjectType.CP_Agreement__c.getRecordTypeInfosByDeveloperName().get('Archived').getRecordTypeId();
        
        MD_JSONResponse response = new MD_JSONResponse();

        CP_Agreement__c agreement = new CP_Agreement__c(
            Id = recordId,
            RecordTypeId = recordTypeId
        );
        
        try{
			update agreement;
            response.status = true;
            response.message = 'Agreement archived succesfully';
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;
            response.title = '';
            
        }catch(DMLException e){
            response.status = false;
            response.message = 'There was an error archiving the agreement. ' + e.getDMLMessage(0);
            response.type = MD_JSONResponse.MD_JSONResponseType.ERROR;
            response.title = '';
        }
        
        return JSON.serialize(response);
    }
    
}