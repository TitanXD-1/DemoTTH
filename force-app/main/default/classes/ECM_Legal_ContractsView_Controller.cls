/*
 * @Name: ECM_Legal_ContractsView_Controller
 * @Description: This is the controller class for fetching details on Legal Contract view and Edit Page
 * @History                                                            

	VERSION    	AUTHOR                		DATE				DETAIL
	1.0        	Veerendra Billakurthi    	10/09/2020        	Initial Development
	1.1			Chandrakanth Suram			19/01/2021			Added saveDraftAddendum,FilesCheck methods for ECM-3603
	1.2			Subhrojit Majumdar			09/02/2022			Development of Reject Addendum logic against ECM-4963
*/
public class  ECM_Legal_ContractsView_Controller {
    /*
    * @Name : getAddendumRecs
	* @description : This method is used to get Addendum records
	* @return : List<ECM_Addendum__c>
	* @param : none
	*/
    @AuraEnabled
    public static List<ECM_Addendum__c> getAddendumRecs(){
        String countryName;
        list<ECM_Addendum__c> tobereturned=New List<ECM_Addendum__c>();
        User usrobj=[Select Id,Name,Available_Countries__c from User where id=:Userinfo.getUserId()];
        
        
        List<ECM_Addendum__c>  addendumList=[Select Id, Name,ECM_Contract__c,ECM_Contract__r.Account.Name,ECM_Contract__r.ContractNumber,ECM_New_T_C__c,
                                             ECM_Contract__r.StartDate,ECM_Contract__r.ECM_Agreement_Type__r.Name,ECM_Addendum_Type__c,ECM_Status__c,ECM_Contract__r.Owner.Name,
                                             ECM_Legal_Person_Responsible__c,ECM_Legal_Person_Responsible__r.Name,ECM_Contract__r.ECM_Agreement_Type__r.Geography__r.Code__c from ECM_Addendum__c where ECM_Status__c NOT IN ('Approved','Cancelled')];
        
        for(ECM_Addendum__c ad:addendumList){
            
            tobereturned.add(ad);
            
        }
        
        if(tobereturned.size()>0){
            return tobereturned;
        }
        else{
            return null;
        }
    }
    /*
    * @Name : FilesCheck
	* @description : This method is used to get attached files against addendum records
	* @return : String
	* @param : Addendum ID
	*/
    @AuraEnabled
    public static string FilesCheck(string addenId){
        ContentDocumentLink ContentDoc = new ContentDocumentLink();
        
        ContentDoc= [Select ContentDocumentId,LinkedEntityId from ContentDocumentLink where LinkedEntityId=: addenId];
        String ContentId = ContentDoc.ContentDocumentId;
        
        String fullFileURL = URL.getSalesforceBaseUrl().toExternalForm();
        String URlDownload = fullFileURL+'/sfc/servlet.shepherd/document/download/'+ContentId+'?operationsContext=S1';
        
        
        return URlDownload;
    }
    /*
    * @Name : updateAddendum
	* @description : This method is used to update ECM_Legal_Person_Responsible__c field for addendum records
	* @return : ECM_Addendum__c
	* @param : Addendum ID, User ID
	*/
    @AuraEnabled
    public static ECM_Addendum__c updateAddendum(String addenId, String userId){
        ECM_Addendum__c addenObj = new ECM_Addendum__c();
        try{
            addenObj= [Select Id, Name,ECM_Legal_Person_Responsible__c from ECM_Addendum__c where id=: addenId Limit 1];
            if(userId!=''){
                addenObj.ECM_Legal_Person_Responsible__c = userId;
            }else{                
                addenObj.ECM_Legal_Person_Responsible__c = null;
            }
            update addenObj;
        }catch(exception ex ){
            system.debug('update'+ex);
        }
        return addenObj;
    }
    /*
    * @Name : legalContractvalues
	* @description : This method is used to return addendum record against respective contract records
	* @return : ECM_Addendum__c
	* @param : Contract ID
	*/
    @AuraEnabled
    public static ECM_Addendum__c legalContractvalues(string contractId)
    {
        ECM_Addendum__c legalList=[Select Id,ECM_Notes_to_Legal__c, Name,ECM_Contract__c,ECM_Contract__r.Id,ECM_Contract__r.Account.Name,ECM_Contract__r.ContractNumber,ECM_New_T_C__c,
                                   ECM_Contract__r.StartDate,ECM_Contract__r.ECM_Agreement_Type__r.Name,ECM_Addendum_Type__c,ECM_Status__c,ECM_Contract__r.Owner.Name,
                                   ECM_Legal_Person_Responsible__c,ECM_Legal_Person_Responsible__r.Name from ECM_Addendum__c where Id=:contractId];
        
        return  legalList;
    }
    /*
    * @Name : submitLegalViews
	* @description : This method is used to approve and submit addendums
	* @return : list<ContentDocumentLink>
	* @param : Addendum ID
	*/
    @AuraEnabled
    public static list<ContentDocumentLink> submitLegalViews(ECM_Addendum__c LegalId){
        system.debug('LegalId'+LegalId);
        //list<ContentDocumentLink> ContentDoc = new list <ContentDocumentLink>();
        list<ContentDocumentLink> ContentDoc = [SELECT ContentDocumentId FROM ContentDocumentLink WHERE LinkedEntityId=:LegalId.Id];
        system.debug('ContentDoc'+ContentDoc.size());
        if(ContentDoc.size()==1){
            system.debug('ContentDoc2'+ContentDoc);
            string Conid = LegalId.ECM_Contract__r.Id;
			ECM_UtilityClass.updateContractInSystemMode(Conid);
            
            ECM_Addendum__c legrec=[Select Id,ECM_Contract__c,ECM_New_T_C__c,ECM_Contract__r.Name,ECM_Contract__r.Owner.Email,ECM_Status__c,ECM_Contract__r.Status from ECM_Addendum__c where Id=:LegalId.Id];
            legrec.ECM_Status__c='Approved';
            ECM_UtilityClass.updateAddendumInSystemMode(legrec);
            system.debug('legrec.ECM_Status__c'+legrec.ECM_Status__c);
            System.debug('Email ID: ' + legrec.ECM_Contract__r.Owner.Email);
            if(legrec.ECM_Contract__r.Owner.Email !=null){
				System.debug('Inside if');
                string emailstr=legrec.ECM_Contract__r.Owner.Email;
                Messaging.SingleEmailMessage mail = new Messaging.SingleEmailMessage();
                String[] toAddresses = new String[] {emailstr}; 
                    mail.setToAddresses(toAddresses);
                mail.setSubject('Contract : ' +legrec.ECM_Contract__r.Name +'   has Terms & Conditions completed by Legal.');
                mail.setPlainTextBody('Contract : ' +legrec.ECM_Contract__r.Name +'   has Terms & Conditions completed by Legal.');
                Messaging.sendEmail(new Messaging.SingleEmailMessage[] { mail });
                System.debug('Email sent successfully');
            }
        }
        
        return ContentDoc;
    }
    /*
    * @Name : saveDraftAddendum
	* @description : This method is used to save addendum records in Draft stage
	* @return : void
	* @param : Addendum object record
	*/
    @AuraEnabled
    public static void saveDraftAddendum(ECM_Addendum__c addenObj){
        try{
            string NewTandC = addenObj.ECM_New_T_C__c;
            ECM_Addendum__c addenRec = [Select Id,ECM_Contract__c,ECM_New_T_C__c,ECM_Contract__r.Name,ECM_Contract__r.Owner.Email,ECM_Status__c,ECM_Contract__r.Status from ECM_Addendum__c where Id=:addenObj.Id];
            addenRec.ECM_Status__c = 'Draft';
            addenRec.ECM_New_T_C__c = NewTandC;  
            update addenRec;
        }catch(Exception e){
            System.debug('Exception Caught in ECM_Legal_ContractsView_Controller class at Line: '+e.getLineNumber()+' Error: '+e.getMessage());
        }
    }
    /*
    * @Name : deleteFile
	* @description : This method is used to delete attached files for a addendum record
	* @return : String
	* @param : LinkedEntityId
	*/
    @AuraEnabled  
    public static string deleteFile(String LinkEntiId){ 
       /* string result;
        List<ContentDocumentLink> conDocLst = new List<ContentDocumentLink>();
        List<String> conIdLst = new List<String>();
        conDocLst=[select ContentDocumentId FROM ContentDocumentLink where LinkedEntityId=:LinkEntiId];
        if(conDocLst.size()>0){
            for(ContentDocumentLink con : conDocLst){
                conIdLst.add(con.ContentDocumentId); 
            }
            if(conIdLst.size()>0){
                delete [SELECT Id,Title from ContentDocument WHERE Id IN: conIdLst];
                result = 'success';
            }
        }else{
            result = 'NoFile';
        }
        return result;*/
        string result =ECM_DeleteExistingFiles.deleteFile(LinkEntiId);
     
        return result;
     
    }
    /*
    * @Name : rejectAddendum
	* @description : This method is used to reject addendum requests
	* @return : void
	* @param : Addendum object record
	*/
    @AuraEnabled 
    public static void rejectAddendum(ECM_Addendum__c addendum)
	{
        addendum.ECM_Status__c='Cancelled';
        try
        {
            update addendum;
        	Contract conrec=[Select Id,Status from Contract where Id=:addendum.ECM_Contract__r.Id];
        	conrec.Status='Approved';
            update conrec;
        }catch(Exception e){
            System.debug(e.getMessage());
            System.debug(e.getLineNumber());
        }
    }
}