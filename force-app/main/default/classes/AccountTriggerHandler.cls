/**	

 * @name : AccountTriggerHandler
 * @description : Trigger Handler Class for AccountTrigger
 * @history
 * VERSION      AUTHOR          DATE            DETAIL
 * 1.0          Kapil Baliyan   06/02/2019      Initial Development
 * 2.0          Dipanjan Das    22/02/2019      ES20-195
 * 3.0          Dipanjan Das    06/03/2019      ES20-380
 * 4.0          Monalisa Halder 07/03/2019      ES20-377
 * 5.0          Tomas Harte     17/07/2019      (Geography Automation)
 * 6.0          Monalisa Halder 01/02/2019      ES20-9212
 * 7.0          Abhishek Jethi  15/02/2021		NCP-1584(preventAccountDelete)
 * 8.0          Anamika Shukla  28/04/2021      ES20-10036
 * 9.0          Gaurav          26/07/2021      NCP-3897 (updateContactPointAddresses)
 * 10.0         Amar Deep       25/08/2021      NCP-
 * 11.0          Gaurav         30/08/2021      NCP-3076
 * 12.0			Sayan Mullick	30/11/2021		CST-385
* 13.0           Saurav Paul     07/03/2022      CM-5275-Value Population in the new Fields_Account Report
*  14.0			Rajarshi Lahiri	20/09/2022		ES20-12998
 * 15.0         Wribhu Bose     26/06/2023      140680 (GT-57) - Update GT Project and Asset fields when operator of linked outlet changes (afterUpdate)
 * 16.0         Sneha/Stuti		11/07/2023		142256 -  update currency account

 */

public with sharing class AccountTriggerHandler implements TriggerHandler{	
    // Allows unit tests (or other code) to disable this trigger for the transaction	
    public static Boolean triggerDisabled = false;	
    public static string triggerName = 'AccountTrigger';	
    //ES20-9080	
    final static List<AccountTeamMember> exisAccountMembersList = new List<AccountTeamMember>();	
    	
    // Checks to see if the trigger has been disabled either by custom setting or by code	
    public Boolean isDisabled(){     	
        if(!triggerDisabled){	
            triggerDisabled = EDGE_UtilityClass.isTriggerDisabled(triggerName);	
        }	
        	
        return triggerDisabled;	
    }	
    	
    //Before Insert Trigger Handler	
    public void beforeInsert(List<SObject> newItems) {	
        
        EDGE_AccountTriggerHelper.setGeographyTree( newItems, null);  	
        EDGE_AccountTriggerHelper.validatePhoneNumber(newItems, null);	
        EDGE_UtilityClass.populateGUID(newItems);	
        EDGE_AccountTriggerDataHelper.prospectApprovalProcess(newItems);	
        EDGE_AccountTriggerHelper.updateOutletExecutionScore(newItems, null);	
        EDGE_AccountTriggerHelper.updateHybridFlag(newItems,null,false);	
        EDGE_AccountTriggerHelper.updateReportingUnit(newItems,null);	
        EDGE_AccountTriggerHelper.updateExpectedVisit(newItems,null);	
        PNR_AccountTriggerHelper.updateProductEnabled(newItems); //Added for Pioneer	
        EDGE_AccountTriggerExtendedHelper.productEnableUpdate(newItems ,null);	
        EDGE_AccountTriggerHelper.updateMarketAccountOwner(newItems,null);	
        EDGE_AccountTriggerExtendedHelper.setPhysicalAndVirtualFreq(newItems,null);	
        D1_AccountTriggerHelper.setDirectCustomer(newItems);//DiageoOne changes	
        CST_SharingUtil.updateSalesOrganization(newItems, null,'Sales_Org__c');//CST-385
        ECM_AccountTriggerPersonRespHelper.updateSalesAreaAndTerritory(newItems,null);//ECM-5275
		EDGE_AccountTriggerHelper.updateAcctCurrency(newItems);
    }	
    	
    
    //Before Update Trigger Handler	
    public void beforeUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        EDGE_AccountTriggerExtendedHelper.sendPushNotifRejectProspects(newItems.values(), oldItems);//ES20-12998
        EDGE_AccountTriggerHelper.setGeographyTree(newItems.values(), oldItems.values());        	
        EDGE_AccountTriggerHelper.checkMandatoryFields(newItems.values());	
        EDGE_AccountTriggerHelper.validatePhoneNumber(newItems.values(), oldItems);	
        //EDGE_AccountTriggerHelper.validateOwner(newItems.values(), oldItems);	
        EDGE_AccountTriggerHelper.updateAccountGeoCodes(newItems);	
        EDGE_AccountTriggerHelper.updateOutletExecutionScore(newItems.values(), oldItems);	
        EDGE_AccountTriggerHelper.updateTemporaryDate(newItems.values(),oldItems);	
        	
        EDGE_AccountTriggerHelper.updateHybridFlag(newItems.values(),oldItems,true);	
        EDGE_AccountTriggerHelper.updateReportingUnit(newItems.values(),oldItems);	
        //ES20-9212 	
        EDGE_AccountTriggerHelper.validateFieldsPerFS(newItems, oldItems);	
        EDGE_AccountTriggerExtendedHelper.UpdateLastModMasterFld(newItems, oldItems);	
        //for approval process	
        EDGE_AccountTriggerExtendedHelper.createFieldChangeRequest(newItems,oldItems);	
        EDGE_AccountTriggerHelper.changeContractAssignment(newItems.values(),oldItems);	
        EDGE_AccountTriggerHelper.convertProspectToOutlet(newItems,oldItems,exisAccountMembersList);	
        EDGE_AccountTriggerHelper.updateExpectedVisit(newItems.values(),oldItems);	
        EDGE_AccountTriggerHelper.updateStatusMarkedForDeletion(newItems.values(),oldItems);	
        //ES20-9437 	
        EDGE_AccountTriggerDataHelper.updateAccountStatusToClose(newItems.values(), oldItems);	
        EDGE_AccountTriggerExtendedHelper.cleanClosedOutlet(newitems.values() ,oldItems);	
        EDGE_AccountTriggerExtendedHelper.productEnableUpdate(newItems.values() , oldItems);	
        EDGE_AccountTriggerExtendedHelper.setPhysicalAndVirtualFreq(newItems.values() , oldItems);	
        EDGE_AccountTriggerDataHelper.manageContactsOfClosedOutlet(newItems.values(),oldItems);	
        //ES20-9194	
        EDGE_AccountTriggerHelper.flagOutletsForKPITargets(newItems.values(), oldItems);	
        //Changes for Diageo One	
        D1_AccountTriggerHelper.populateConvDate(newItems,oldItems);	
        D1_AccountTriggerHelper.setDirectCustomer(newItems, oldItems);	
        D1_AccountTriggerHelper.updateSAPDeletionDate(newItems, oldItems);                               // NCP - 4205 
        CST_SharingUtil.updateSalesOrganization(newItems.values(), oldItems.values(), 'Sales_Org__c');//CST-385
        //Changes for Diageo One	
          ECM_AccountTriggerPersonRespHelper.updateSalesAreaAndTerritory(newItems.values(),oldItems);//ECM-5275	
   }	
    	
    //Before Delete Trigger Handler	
    public void beforeDelete(Map<Id, SObject> oldItems) {	
        D1_AccountTriggerHelper.preventAccountDelete(oldItems); //NCP-1584	
    }	
    	
    //After Insert Trigger Handler	
    public void afterInsert(Map<Id, SObject> newItems) {	
        EDGE_Constant.HAS_ACCOUNT_INSERT_RUN = true; //NCP-
        EDGE_AccountTriggerHelper.checkMandatoryFields(newItems.values());        	
        EDGE_AccountTriggerHelper.changeContractAssignment(newItems.values(),null);	
        EDGE_AccountTriggerHelper.segmentDependencyValidation(newItems,null);	
        EDGE_ProspectAccountSharing.prospectSharingSalesManager(newItems.values());	
        EDGE_AccountTriggerHelper.upsertOutletExHistoric(newItems,null); 	
        EDGE_AccountTriggerPersonRespHelper.shareOutletsToPersonResp(newItems.values(), null);	
        EDGE_AccountTriggerPersonRespHelper.shareDistToPersonResp(newItems.values(),null);	// ES20-10036
        EDGE_AccountTriggerHelper.checkAndGenerateSharing(newItems.values());
        PNR_AccountTriggerHelper.accountSharingUsingApex(newItems,null,'insert');//PION-1824 change
    }	
    //After Update Trigger Handler	
    public void afterUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {	

        EDGE_AccountTriggerDataHelper.createAccTeamMemberOnProspectConversion(null, null,exisAccountMembersList);	
        EDGE_AccountTriggerHelper.segmentDependencyValidation(newItems,oldItems);        	
        EDGE_AccountTriggerHelper.autoAddToTerritory(newItems,oldItems);	
        EDGE_AccountTriggerHelper.upsertOutletExHistoric(newItems,oldItems); 	
        EDGE_AccountTriggerHelper.unlockProspectRecord(newItems,oldItems);	
        EDGE_AccountTriggerHelper.updateOutletKPITargets(newItems.values(), oldItems);	
        EDGE_AccountTriggerExtendedHelper.enableForPendingBatch(newItems.values(),oldItems);	
        EDGE_AccountTriggerPersonRespHelper.shareOutletsToPersonResp(newItems.values(), oldItems);	
		
        EDGE_AccountTriggerPersonRespHelper.shareDistToPersonResp(newItems.values(),oldItems);
        D1_AccountTriggerHelper.deactivateContactOnCustomerDelete(newItems,oldItems);
        D1_AccountTriggerHelper.updateContactPointAddresses(newItems,oldItems);
        D1_AccountTriggerHelper.removeOrdersForDeletedFromSAP(newItems,oldItems);

        D1_AccountTriggerHelper.anonymizeContactsForDeletedAccounts(newItems,oldItems);
        EDGE_AccountTriggerHelper.validateAndReGenerateSharing(newItems.values(), oldItems);
	    PNR_AccountTriggerHelper.accountSharingUsingApex(newItems,oldItems,'update');//PION-1824 change
        D1_AccountTriggerHelper.updateSapAddressOnCpa(newItems,oldItems);

        GT_AccountTriggerHelper.updateGTObjectFields(newItems, oldItems); //GT-57
    }	
    	
    //After Delete Trigger Handler	
    public void afterDelete(Map<Id, SObject> oldItems) {	
       	
    }	
    	
    //After Undelete Trigger Handler	
    public void afterUndelete(Map<Id, SObject> oldItems) {	
        	
    }	
}