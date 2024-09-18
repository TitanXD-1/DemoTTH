/***********************************************************************************
Apex Class Name  :  CP_AgreementUtil 
Version          :  1.0
Created Date     :  07/08/2019
Release          :  R1
Function         :
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Hernan Arakaki			07/08/2019				ECOM 3408: EDGE - Agreements versioning
******************************************************************************/
public without sharing class CP_AgreementUtil {
	
	public static Boolean userHasUnacceptedAgreements (User u, String portalName) {
        System.debug('CP - in CP_AgreementUtil.userHasUnacceptedAgreements() method. u: ' + u);
        
        Set<String> activeAgreementsIds = new Set<String>();

        List<CP_AgreementUtil.AgreementWrapper> clusterActiveAgreements = getClusterActiveAgreements(u, portalName);
        
        for(CP_AgreementUtil.AgreementWrapper aa : clusterActiveAgreements) {
            if(aa.portal == portalName) {
                activeAgreementsIds.add(aa.agreementId);
            }
        }

        List<CP_ContactAgreement__c> contactAcceptedAgreements = getContactAcceptedAgreements(u, activeAgreementsIds, portalName);
        
        if(contactAcceptedAgreements.size() < clusterActiveAgreements.size()) {
            return true;
        }else {
            return false;
        }
    }

    public static List<CP_Agreement__c> getAgreementsToAccept(User u, String portalName) {
        System.debug('CP - in CP_AgreementUtil.userHasUnacceptedAgreements() method. u: ' + u);
        Set<String> toAcceptAgreements = new Set<String>();

        Set<String> activeAgreementsIds = new Set<String>();

        List<CP_AgreementUtil.AgreementWrapper> clusterActiveAgreements = getClusterActiveAgreements(u, portalName);
        
        for(CP_AgreementUtil.AgreementWrapper aa : clusterActiveAgreements) {
            if(aa.portal == portalName) {
                activeAgreementsIds.add(aa.agreementId);
            }
        }

        List<CP_ContactAgreement__c> contactAcceptedAgreements = getContactAcceptedAgreements(u, activeAgreementsIds, portalName);

        for(CP_AgreementUtil.AgreementWrapper clusterActiveAgreement : clusterActiveAgreements) {
            Boolean founded = false;

            for(CP_ContactAgreement__c contactAcceptedAgreement : contactAcceptedAgreements) {
                if(contactAcceptedAgreement.CurrentAgreement__c == clusterActiveAgreement.agreementId) {
                    founded = true;
                }
            }

            if(!founded) {
                toAcceptAgreements.add(clusterActiveAgreement.agreementId);
            }
        }

        List<CP_Agreement__c> agreements = [SELECT Id, Type__c, Version__c FROM CP_Agreement__c WHERE Id IN :toAcceptAgreements ORDER BY Order__c ASC];

        return agreements;
    }
    
    @TestVisible
    private static List<CP_ContactAgreement__c> getContactAcceptedAgreements(User u, Set<String> clusterActiveAgreementsIds, String portal) {
        List<CP_ContactAgreement__c> contactAcceptedAgreements = [SELECT Id, CurrentAgreement__c
                                                                    FROM CP_ContactAgreement__c 
                                                                    WHERE Contact__c = :u.ContactId 
                                                                        AND CurrentAgreement__r.Portal__c = :portal
                                                                        AND CurrentAgreement__c IN :clusterActiveAgreementsIds];
		
        System.debug('CP - in CP_AgreementUtil.userHasUnacceptedAgreements() method. contactAcceptedAgreements: ' + contactAcceptedAgreements);

        return contactAcceptedAgreements;
    }

    @TestVisible
    private static List<CP_AgreementUtil.AgreementWrapper> getClusterActiveAgreements(User u, String portalName) {
        
        List<CP_AgreementUtil.AgreementWrapper> response = new List<CP_AgreementUtil.AgreementWrapper>();
        
        DiageoCMS__CMSUserSettings__c cmsSettings = DiageoCMS.CMSUserSettingsUtils.getUserSettings(u.Id);
        
        if(cmsSettings != Null){
            
        	System.debug('CP - in CP_AgreementUtil.userHasUnacceptedAgreements() method. cmsSettings: ' + cmsSettings);
        
        	DiageoCMS__Cluster__c userCluster = [SELECT Id, CP_ActiveAgreements__c FROM DiageoCMS__Cluster__c WHERE Id = :cmsSettings.DiageoCMS__Cluster__c];
        
        	System.debug('CP - in CP_AgreementUtil.userHasUnacceptedAgreements() method. userCluster: ' + userCluster);
        
        	List<CP_AgreementUtil.AgreementWrapper> clusterActiveAgreements = new List<CP_AgreementUtil.AgreementWrapper>();

        	if(userCluster.CP_ActiveAgreements__c != null) {
            	clusterActiveAgreements = (List<CP_AgreementUtil.AgreementWrapper>)JSON.deserialize(userCluster.CP_ActiveAgreements__c, List<CP_AgreementUtil.AgreementWrapper>.class);
        	}

        	for(CP_AgreementUtil.AgreementWrapper aa : clusterActiveAgreements) {
            	if(aa.portal == portalName) {
                	response.add(aa);
            	}
        	}
        	System.debug('CP - in CP_AgreementUtil.userHasUnacceptedAgreements() method. clusterActiveAgreements: ' + clusterActiveAgreements);
        	}
        	return response;
    }

    public class AgreementWrapper {
        public String agreementId {get;set;}
        public String type {get;set;}
        public String portal {get;set;}
        public Decimal version {get;set;}
    }
}