/************************************************************************************
Apex Class Name  :  MD_OutletSelectionComponentController  
Version          :  1.0 
Created Date     :  12/12/2018
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Elena Shwarzböck            12/12/2018              Original Version
******************************************************************************/
public without sharing class MD_OutletSelectionComponentController {

    @AuraEnabled
    public static String navigateAsOutlet(Id outletId) {
        System.debug('in CP_OutletSelectionComponentController.navigateAsOutlet() method. ');
        
        OutletSelectionResponseWrapper response = new OutletSelectionResponseWrapper();
	    MD_LightningLoginFormController.CP_UserLoginWrapper responseMessage = new MD_LightningLoginFormController.CP_UserLoginWrapper();
		
        System.debug('CG - in MD_OutletSelectionComponentController.navigateAsOutlet() method. Code__c:  - outletId: ' + outletId);
        
        MD_UserSessionUtil.navigateAsOutlet(outletId);

        
        if(MD_UserSessionUtil.getOutlet() != null && MD_UserSessionUtil.getOutlet().Country__c != null) {
            DiageoCMS__Cluster__c cluster = [SELECT Id, DiageoCMS__ExternalId__c 
                                                FROM DiageoCMS__Cluster__c 
                                                WHERE DiageoCMS__ExternalId__c = :MD_UserSessionUtil.getOutlet().Country__r.Code__c
                                                LIMIT 1];

            responseMessage.countryCode = MD_UserSessionUtil.getUser().Contact.MD_CurrentOutlet__r.Country__r.Code__c;
            responseMessage.userId = UserInfo.getUserId();
            responseMessage.contactId = MD_UserSessionUtil.getUser().ContactId;
            responseMessage.languageCode = MD_UserSessionUtil.getUser().LanguageLocaleKey;
            responseMessage.outletId = MD_UserSessionUtil.getOutlet().Id;
            responseMessage.softwareVersion = 'v1';
            responseMessage.outletContactId = MD_UserSessionUtil.getUser().Contact.MD_CurrentOutlet__r.Id;
            responseMessage.outletType = MD_UserSessionUtil.getOutletContact(outletId).MD_Role__c;
            
            response.message = JSON.serialize(responseMessage);
            response.clusterId = cluster.Id;
            response.countryCode = cluster.DiageoCMS__ExternalId__c;
            response.status = true;
            response.type = MD_JSONResponse.MD_JSONResponseType.SUCCESS;

        }else {
            response.message = 'GB';
            response.status = true;
            response.type = MD_JSONResponse.MD_JSONResponseType.INFO;
        }

        return JSON.serialize(response);
    }
    
    @AuraEnabled
    public static String getAvailableOutlets(){
        List<AccountContactRelation> availableOutlets = MD_UserSessionUtil.getAvailableOutlets();
        
        MD_UserSessionUtil.OutletInfo currentOutlet = new MD_UserSessionUtil.OutletInfo();

        if(String.IsNotBlank(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c)){
            AccountContactRelation sessionOutlet = MD_UserSessionUtil.availableOutlets.get(MD_UserSessionUtil.getSessionSettings().NavigateAsOutlet__c);
            currentOutlet = new MD_UserSessionUtil.OutletInfo(sessionOutlet.Account.Name, sessionOutlet != null ? String.valueOf(sessionOutlet.Id) : null);
        }

        OutletSelectionWrapper response = new OutletSelectionWrapper(availableOutlets, currentOutlet, MD_UserSessionUtil.getOutlet().Country__c);
        return JSON.serialize(response);
    }
    
    public class OutletSelectionResponseWrapper extends MD_JSONResponse {
        public String countryCode {get;set;}
        public String clusterId {get;set;}
    }

    public class OutletSelectionWrapper {
	
        public List<AccountContactRelation> availableOutlets;
    	public MD_UserSessionUtil.OutletInfo currentOutlet;
        public String country;
        

        public OutletSelectionWrapper(List<AccountContactRelation> availableOutlets, MD_UserSessionUtil.OutletInfo currentOutlet, String country){
            this.availableOutlets = availableOutlets;
            this.currentOutlet = currentOutlet;
            this.country = country;
        }
	
    }
}