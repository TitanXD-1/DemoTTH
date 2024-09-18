/*
Name: D1_CaseTriggerHelper
*
Purpose: Trigger Helper Class for Case
*
History                                                            
*                                                            
VERSION     AUTHOR              DATE                DETAIL
1.0         Shounak Mukherjee   27/04/2021          Initial Development (NCP-3064)
1.1         Sayan Samaddar      25/05/2021          Update Sales Org(NCP-2825)
1.2         Amar Deep           27/07/2021          sendNotificationToCaseCreater( NCP-3815,NCP-3817)
1.3         Gaurav Singh        15/08/2021          updateCaseStatusToOpen( NCP-3865 )
1.4         Amar Deep           01/10/2021          updateCaseOwner(NCP-3791)
1.5         Kapil Baliyan       24/11/2021          NCP-5510
1.6         SaiKiran            08/03/2023          CUS-98
1.7         JoshRaj             08/03/2023          CUS-152
1.8         JoshRaj             12/03/2023          CUS-115
1.9         Suvendu             21/03/2023          CUS-153
2.0         Saurav Prasad       04/04/2023          CUS-254 : Start SLA time on case creation_SFDC
2.1         Sai Kiran           04/04/2023          CUS-255: Completion of milestones when case status is closed
2.2         Saurav Prasad       13/04/2023          CUS-265 : Fast track_Case Agent Assignment_SFDC
2.3         Saurav Prasad       28/04/2023          CUS-332: Sanity Defect_User is unable to Create case Using Correct Ship to account because of Wrong partner function.
2.4         Swagat Shaw         27/06/2023          CUS-404: CASE agent - autofilled with the name of the creator
2.5         Swagat Shaw         10/07/2023          CUS-405: Validate list of case types / Sales Org 
2.6         Suvendu Roy         18/07/2023          CUS-439: Case Visibility for Logistic Users
2.7         Nidhi Jaiswal       25/07/2023         143374: Fasttrack_ SLA with 1hour should be Priority High
2.8         Swagat Shaw         10/08/2023         144104: Sanity_Defect Case Agent is not Populating for created case from Case Management Minimum Access Profile    
2.9         Joshraj Sen         17/08/2023         144407: Stop Sending Case Push Notifications in Mobile to SR/QR on Status and Post Update on Case Un-Follow | Salesforce
2.10		Sneha				07/09/2023			144853:Case Management_ Allow System Validation on Case Agent update in Case Record
2.11        Saikiran            21/09/23           145789: Case Agent Fix during update
2.12        Kapil Baliyan       11/03/2023          151317
2.13       Monalisa Halder      02/05/2024          366449 (372793)
2.14 	    Mukesh Kanth		25/04/2024		    152905: Update case type/subtype/Origin and associated account for case created from Live chat
3.0			Saurav Prasad		14/06/2023			151180: Update 'Associate Account' Population logic for Customer case in Case Mgt Console
*/
public without sharing class D1_CaseTriggerHelper {
    
    //Method to update the Status of Technical Case to Open (NCP-3865)
    public static void updateCaseStatusToOpen(List<SObject> newItems){
        Id recordTypeIdTechnicalIssue = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
        for(Case cs : (List<Case>) newItems){
            if( cs.RecordTypeId == recordTypeIdTechnicalIssue && cs.Status == 'New' && String.isNotBlank(cs.sys_id__c) && cs.Origin == 'Diageo One' ){
                cs.Status = 'Open';
            }
        }
    }
    
    //Method to update the D1 subject field to standard subject
    public static void updateCaseSubjectToStandard(List<SObject> newItems){
        for(Case cs : (List<Case>) newItems){
            if(String.isBlank(cs.subject)){
                cs.subject = cs.D1_Subject__c;
            }
        }
    }
    //Method to Update the Sales Org(NCP-2825)
    public static void updateCaseSalesOrg(List<Case> newItems){
        if(newItems != null){
            Set<Id> accountIdSet = new Set<Id>();
            Map<Id, String> accountWithSalesOrgMap = new Map<Id, String>();
            Map<Id, String> accountWithSalesOrgMapShipTo = new Map<Id, String>();
            Set<Id> recordIdSet = new Set<Id>();
            recordIdSet.add(Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId());
            recordIdSet.add(Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId());
            for(Case cs : newItems){
                accountIdSet.add(cs.AccountId);
            }
            for(PNR_Partner_Function__c partnetFunction : [SELECT Id, PNR_Sales_Org__c, PNR_Sold_To__c
                                                           FROM PNR_Partner_Function__c 
                                                           WHERE PNR_Type__c = 'Sold-To' AND PNR_Sold_To__c IN : accountIdSet]){
                                                               accountWithSalesOrgMap.put(partnetFunction.PNR_Sold_To__c, partnetFunction.PNR_Sales_Org__c);
                                                           }      
            for(Account acc : [SELECT Id, Sales_Org__c 
                               FROM Account WHERE Id IN: accountIdSet AND Account_Type__c includes ('Ship-To')]){
                                   accountWithSalesOrgMapShipTo.put(acc.Id, acc.Sales_Org__c);
                               }
            for(Case cs : newItems){
                //CUS-152 change start
                if (String.isBlank(cs.Sales_Org__c) && recordIdSet.contains(cs.RecordTypeId)) {
                    cs.Sales_Org__c = accountWithSalesOrgMap.containsKey(cs.AccountId) ? accountWithSalesOrgMap.get(cs.AccountId) :
                    accountWithSalesOrgMapShipTo.containsKey(cs.AccountId) && cs.RecordTypeId==Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId() ? accountWithSalesOrgMapShipTo.get(cs.AccountId) : '' ;
                }//CUS-152 change end
            }
            
        }
    }
    //Method to send Quality Case from EDGE to Intouch Org -- Commenting the code as part of 366449
  /*  public static void sendCaseToIntouch(Map<Id, SObject> newItems){
        String networkId = '';
        List<PartnerNetworkRecordConnection> cons = new List<PartnerNetworkRecordConnection>();
        Map<Id, Case> mapNewCase;
        if(newItems != null && newItems.size()>0){
            mapNewCase = (Map<Id, Case>) newItems;
        }
        
        
        List<PartnerNetworkConnection> pnc = [SELECT Id FROM PartnerNetworkConnection 
                                              WHERE ConnectionStatus = 'ACCEPTED' 
                                              AND ConnectionName = 'DIAGEO PLC'
                                              LIMIT 1];
        if(pnc != null && pnc.size()>0){
            networkId = pnc[0].Id;
            
            for(Case cs : mapNewCase.values()){
                if('Quality & Equipment Issues'.equalsIgnoreCase(cs.Type)){
                    PartnerNetworkRecordConnection newConnection = 
                        new PartnerNetworkRecordConnection(
                            ConnectionId = networkId,
                            LocalRecordId = cs.Id,
                            SendClosedTasks = false,
                            SendOpenTasks = false,
                            SendEmails = false);
                    cons.add(newConnection);
                }
            }
        }
        
        //Insert
        if(!Test.isRunningTest() && cons.size()>0){
            insert cons;
        }
    }*/
    
    /*
Purpose: for sending notifications to the case record creater when comment is added by the customer support team 
*/
    
    public static void sendNotificationToCaseCreater(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        Map<Id, Case> oldItemsMap = (Map<Id, Case>)oldItems;
        Map<Id, Case> newItemsMap = (Map<Id, Case>)newItems;
        Set<String> contactIds;        
        String targetId;
        String notificationName = 'D1_Case_Status_Updated';
        String title;
        String body;
        List<String> customLabelValue;
        for(Case caseRecd : newItemsMap.values()){
            if(oldItemsMap != null && oldItemsMap.containsKey(caseRecd.Id) && oldItemsMap.get(caseRecd.Id).Status != 'Closed' && oldItemsMap.get(caseRecd.Id).Status != caseRecd.Status && (caseRecd.Status == 'Closed' || caseRecd.IsClosed) && caseRecd.Origin == 'Diageo One'){  
                if(caseRecd.ContactId != null){
                    contactIds = new Set<String>(); //NCP-5510
                    customLabelValue = new List<String>(); //NCP-5510
                    contactIds.add(caseRecd.ContactId);
                    targetId = caseRecd.Id;
                    if(caseRecd.Type =='Kegs Return'){ 
                        body = 'D1_Kegs_Return_Body';
                        title = 'D1_Kegs_Return_Title';
                        customLabelValue.add(caseRecd.CaseNumber);
                    } else{
                        body = 'D1_CaseBody';
                        title = 'D1_Closed';
                        customLabelValue.add(caseRecd.CaseNumber);
                    }
                    if(!Test.isRunningTest()){
                        D1_CustomNotificationUtility.notifyUsers(contactIds, notificationName, title, body, targetId, null, customLabelValue, null);                   
                    }
                }
            }
        }
    }
    //Method to Update the case Owner(NCP-3791)
    
    public static void updateCaseOwner(List<Case> newItems){
        Map<Case,String> caseContractNumberMap = new Map<Case,String>();
        Map<String,Contract> contractNumberWithContractMap = new Map<String,Contract>();
        Map<String,Id> contractNumberWithTerritoryIdMap = new Map<String,Id>();
        Map<Id,Id> terrIdWithUserMap = new Map<Id,Id>();
        Id diageoOneCasesRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        
        for(Case caseRecord : newItems){
            if(caseRecord.D1_Subject__c == 'Contract terms' && caseRecord.Type == 'Contracts' && caseRecord.RecordTypeId == diageoOneCasesRecordTypeId && String.isNotBlank(caseRecord.D1_Contract_Number__c)){
                caseContractNumberMap.put(caseRecord,caseRecord.D1_Contract_Number__c);
            }
        }
        
        
        if(caseContractNumberMap != null){
            for(Contract contractRecd : [SELECT Id, ContractNumber,AccountId, Account.Primary_Sales_Rep__c,Account.Operator__c,Account.Operator__r.Person_Responsible__c,Account.Independent_of_Operator__c,ECM_Territory__c FROM Contract 
                                         WHERE ContractNumber =: caseContractNumberMap.values()])
            {
                contractNumberWithContractMap.put(contractRecd.ContractNumber, contractRecd);
                contractNumberWithTerritoryIdMap.put(contractRecd.ContractNumber,contractRecd.ECM_Territory__c);
            }
        }
        
        if(contractNumberWithTerritoryIdMap != null){
            for(Territory_Member__c terrMem : [SELECT User__c,Type__c,Territory__c FROM Territory_Member__c WHERE Territory__c IN :contractNumberWithTerritoryIdMap.values() AND Type__c = 'Secondary'  
                                               AND Start_Date__c <= :system.today() Order By Start_Date__c DESC LIMIT 1]){ //KB: This query will give u only 1 result even in case of bulk
                                                   terrIdWithUserMap.put(terrMem.Territory__c,terrMem.User__c);
                                               }
        }
        
        if(caseContractNumberMap != null && contractNumberWithContractMap != null){
            for(Case newCase : caseContractNumberMap.keyset()){
                if(caseContractNumberMap.containsKey(newCase)){
                    String contractNo = caseContractNumberMap.get(newCase);
                    if(contractNumberWithContractMap.containsKey(contractNo)){
                        Contract conRecd = contractNumberWithContractMap.get(contractNo);
                        if(conRecd.Account.Operator__r.Person_Responsible__c != null){
                            newCase.OwnerId = conRecd.Account.Operator__r.Person_Responsible__c;
                        }
                        else if((conRecd.Account.Operator__r.Person_Responsible__c == null || conRecd.Account.Independent_of_Operator__c == true)
                                && conRecd.Account.Primary_Sales_Rep__c != null)
                        {
                            newCase.OwnerId = conRecd.Account.Primary_Sales_Rep__c;
                        }
                        else if(terrIdWithUserMap != null && contractNumberWithTerritoryIdMap.get(contractNo) != null)
                        {
                            Id terrId = contractNumberWithTerritoryIdMap.get(contractNo);
                            newCase.OwnerId = terrIdWithUserMap.get(terrId);
                        }
                    }
                }
            }
        } 
    }
    
    //CUS-98 change -> Start
    /*
* @description: This method checks for ship-to from ACRs that is associated to the contact on the case. Once appriopiate ship-to
* selected this method will autopopulate sold-to
* */
    public static void checkShiptoAccounts(List<SObject> newItems){
        Set<String> contIds  = new Set<String>();
        Set<String> accIds  = new Set<String>();
        Set<String> shipToAccids = new Set<String>();
        Set<String> soldToAccids = new Set<String>();
        Map<String,String> pfMap = new Map<String,String>();
        Map<String,String> pfShipToMap = new Map<String,String>();
        Map<String,String> conVsAccMap = new Map<String,String>();
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get('Diageo_One_Cases').getRecordTypeId();
        map<Id,set<Id>> mapOfAccWithContactIds = new map<Id,set<Id>>();
        
        for(Case cs : (List<Case>) newItems){
            if(cs.RecordTypeId == recordTypeIdD1Case){
                if(cs.AccountId!=null){
                accIds.add(cs.AccountId);
                }
                if(cs.ContactId!=null){
                contIds.add(cs.ContactId);
            }
        }
        }
        //152905
        if(accIds.isEmpty() && !contIds.isEmpty()){
            for(Contact con:[SELECT Id,AccountId from Contact WHERE Id IN:contIds]){
                if(con.AccountId!=null){
                    accIds.add(con.AccountId);
                    conVsAccMap.put(con.Id,con.AccountId);
                }
            }
        }

        if(!accIds.isEmpty()){
            for(Account acc:[SELECT Id from Account WHERE Id IN:accIds AND Account_Type__c includes ('Ship-To')]){
                shipToAccids.add(acc.Id);
            }
            for(Account acc:[SELECT Id from Account WHERE Id IN:accIds AND Account_Type__c includes ('Sold-To')]){
                soldToAccids.add(acc.Id);
            }
        }
        
        if(!shipToAccids.isEmpty() || !contIds.isEmpty()){
            for(AccountContactRelation acr:
                [SELECT Id, ContactId, AccountId FROM AccountContactRelation WHERE
                 ContactId IN: contIds AND AccountId IN:shipToAccids
                 ORDER by createddate desc]){
                     if(!mapOfAccWithContactIds.containsKey(acr.AccountId)){
                         mapOfAccWithContactIds.put(acr.AccountId, new set<Id>{acr.ContactId});
                     }else{
                         mapOfAccWithContactIds.get(acr.AccountId).add(acr.ContactId);
                     }
                 }
        }
        
        for(Case cs : (List<Case>) newItems){
            if( cs.RecordTypeId == recordTypeIdD1Case && cs.ContactId !=null && cs.AccountId !=null
               && shipToAccids.contains(cs.AccountId) && ( !mapOfAccWithContactIds.containsKey(cs.AccountId) ||
                                                          (mapOfAccWithContactIds.containsKey(cs.AccountId) && !mapOfAccWithContactIds.get(cs.AccountId).contains(cs.ContactId)))){
                cs.AccountId.addError(System.label.C360_CaseTriggerErrorMessage);
            }
        }

        if(!shipToAccids.isEmpty() && shipToAccids.size()>0){
            //CUS-332 - added PNR_Sold_To__r.Account_Type__c includes ('Sold-To')
            //151180 - added conditions for IsInvalid = false
            for(PNR_Partner_Function__c pf :  [SELECT Id,PNR_Customer_No__c, PNR_Sold_To__c FROM PNR_Partner_Function__c
                                               WHERE PNR_Customer_No__c IN: shipToAccids  AND PNR_Type__c= 'Ship-To' AND
                                               PNR_Sold_To__r.Account_Type__c includes ('Sold-To') AND IsInvalid__c = FALSE
                                               ORDER BY createddate DESC]){
                if(!pfMap.containskey(pf.PNR_Customer_No__c)){
                    pfMap.put(pf.PNR_Customer_No__c, pf.PNR_Sold_To__c);
                }
            }
        }
        //152905
        if(!accIds.isEmpty() && accIds.size()>0){
            for(PNR_Partner_Function__c pf :  [SELECT Id,PNR_Customer_No__c, PNR_Sold_To__c FROM PNR_Partner_Function__c
                                               WHERE PNR_Sold_To__c IN: accIds  AND PNR_Type__c= 'Ship-To' AND IsInvalid__c = false
                                               ORDER BY createddate DESC]){
                if(!pfShipToMap.containskey(pf.PNR_Sold_To__c)){
                    pfShipToMap.put(pf.PNR_Sold_To__c, pf.PNR_Customer_No__c);
                }
            }
        }
        
        for(Case cs : (List<Case>) newItems){
            Id caseAccountId = cs.AccountId !=null ? cs.AccountId : ((cs.ContactId!=null && conVsAccMap.containskey(cs.ContactId)) ? conVsAccMap.get(cs.ContactId) : null);
            
            if(cs.RecordTypeId == recordTypeIdD1Case  && caseAccountId !=null
               && shipToAccids.contains(caseAccountId) && !soldToAccids.contains(caseAccountId)
               && pfMap.containskey(caseAccountId)){
                cs.AssociatedAccount__c = pfMap.get(caseAccountId);
            }
            //152905
            else if(cs.RecordTypeId == recordTypeIdD1Case  && caseAccountId !=null
               && soldToAccids.contains(caseAccountId)
               && pfShipToMap.containskey(caseAccountId)){
                cs.AssociatedAccount__c = caseAccountId;
                cs.AccountId = pfShipToMap.get(caseAccountId);
            }
        }
    }

    //CUS-98 change -> End
    //CUS-115 change -> Start
    /*
* @description: Logistic rep can only change case owner and cannot edit Case fields.
* Service rep cannot edit case when status is closed.
* This method will check the respective custom permission and gives edit access accordingly.
* */
    public static void validateUserOnEdit(List<SObject> newItems,Map<Id, SObject> oldItems){
        Map<Id, Case> oldCaseItems = (Map<Id, Case>)oldItems;
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        Boolean isLogisticsRep = FeatureManagement.checkPermission(System.Label.C360_Logistics_rep);
        Boolean isServiceTeam = FeatureManagement.checkPermission(System.Label.C360_Service_Team);
        
        for(Case cs:(List<Case>)newItems){
            if(oldCaseItems.get(cs.Id).RecordTypeId==recordTypeIdD1Case && isLogisticsRep  
               && System.Label.C360_Ireland_Country_Codes.contains(cs.Country__c)  && 
               !(oldCaseItems.get(cs.Id).OwnerId != cs.OwnerId)){
                   cs.addError(System.Label.C360_Logistics_rep_error1);
               }
            else if( isServiceTeam && oldCaseItems.get(cs.Id).RecordTypeId==recordTypeIdD1Case && System.Label.C360_Ireland_Country_Codes.contains(cs.Country__c)
                    && oldCaseItems.get(cs.Id).Status == System.Label.CC_Customer_Concern_Status_Closed ){
                        cs.addError(System.Label.C360_Logistics_rep_error2);
                    }
        }
    }
    //CUS-115 change -> End
    
    /*
* @description  : CUS-265 - Fast track_Case Agent Assignment_SFDC
* @return       : void
* @param        : List<SObject>
*/ 
    
    public static void validateOnCreateAndEdit(List<SObject> newItems){
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        set<Id> serviceTeamUserIds = new Set<Id>();
        Map<Id,Case> validCaseMapWithCaseAgentID = new Map<Id,Case>();
        
        for(Case cs:(List<Case>)newItems){
            if(cs.RecordTypeId == recordTypeIdD1Case && cs.C360_Case_Agent__c !=null && Schema.sObjectType.Case.fields.C360_Case_Agent__c.isAccessible() ){
                validCaseMapWithCaseAgentID.put(cs.C360_Case_Agent__c,cs);
            }
        }
        
        if (!validCaseMapWithCaseAgentID.isEmpty() && (Schema.sObjectType.PermissionSetAssignment.isAccessible() || Schema.sObjectType.User.isAccessible())){
            for(PermissionSetAssignment access: [SELECT  AssigneeId FROM PermissionSetAssignment 
                                                 WHERE permissionsetgroup.DeveloperName =:System.Label.C360_ServiceTeam_PermissionSetGroup
                                                 AND AssigneeId IN:validCaseMapWithCaseAgentID.keySet()]){
                                                     serviceTeamUserIds.add(access.AssigneeId); 
                                                 }
            validateOnCreateAndEditSubMethod(validCaseMapWithCaseAgentID,serviceTeamUserIds);                     
        }
        
    }
        /*
    * @description  : Added to resolve PMD Issue for 145789 bug
    * @return       : void
    * @param        : List<SObject>
    */ 
    public static void  validateOnCreateAndEditSubMethod(Map<Id,Case> validCaseMapWithCaseAgentID ,set<Id> serviceTeamUserIds){ //PMD Issue
        Set <String> setUserAvailableCountry = new Set <String> ();//added for 144853
        for(User userRec: [SELECT  Id,Available_Countries__c FROM User WHERE Id IN:validCaseMapWithCaseAgentID.keySet()]){
            if (String.isNotBlank(userRec.Available_Countries__c)){
                setUserAvailableCountry.addAll(userRec.Available_Countries__c.split(';'));//added for 144853
            }
        }
        for(Case cs : validCaseMapWithCaseAgentID.values()){
            //added else if for 145789 bug
            if((!serviceTeamUserIds.contains(cs.C360_Case_Agent__c)) ){
                cs.C360_Case_Agent__c.addError(System.Label.CUS_CaseAgent_ValidationMsg);
            }
            //added else if for 145789 bug
            else if ( String.isNotBlank(cs.Country__c) && !setUserAvailableCountry.contains(cs.Country__c) && serviceTeamUserIds.contains(cs.C360_Case_Agent__c)) {
                cs.C360_Case_Agent__c.addError(System.Label.Error_for_case_agents_field);//added for 144853
            }
        }
        
    }
    /*
    * @description: Closed by field got updated with logged user when case moved to closed status.
    * @return		: void
    * @param		:List<Case> newItems, Map<id,Case> oldItems
    */
    public static void updateClosedBy(List<sObject> newItems, Map<id,sObject> oldItems){
        Map<id,Case> oldCaseMap = (Map<id,Case>)oldItems;
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        for(Case newCase : (List<Case>)newItems){
            Case oldCase = oldCaseMap.get(newCase.Id);
            if(newCase.RecordTypeId == recordTypeIdD1Case 
               && String.isNotBlank(newCase.Country__c)
               && System.Label.C360_Ireland_Country_Codes.contains(newCase.Country__c) 
               && oldCase.Status != System.Label.CC_Customer_Concern_Status_Closed 
               && newCase.Status == System.Label.CC_Customer_Concern_Status_Closed ){
                   newCase.C360_Closed_By__c = UserInfo.getUserId();
               }
        }
        
    }
    
    /*
    * @description	: CUS-404 - CASE agent - autofilled with the name of the creator
    * @return		: void
    * @param		:List<Case> newItems, Map<id,Case> oldItems
    */  
    public static void updateCaseAgent(List<Case> newItems, Map<Id, Case> oldItems) {
    Id recordTypeIdD1Case = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName()
        .get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
    List<Case> filteredCaseRecord = new List<Case>();
    Set<Id> caseOwnerIds = new Set<Id>();
    Set<Id> serviceTeamUserIds = new Set<Id>();
    Map<Id, Case> oldCaseMap = (Map<Id, Case>) oldItems;

    for (Case caseItem : newItems) {
        if (oldCaseMap == null || (oldCaseMap != null && oldCaseMap.containsKey(caseItem.Id) &&
            oldCaseMap.get(caseItem.Id).OwnerId != caseItem.OwnerId &&
            oldCaseMap.get(caseItem.Id).C360_Case_Agent__c == null) &&
            caseItem.RecordTypeId == recordTypeIdD1Case) {
            filteredCaseRecord.add(caseItem);
            caseOwnerIds.add(caseItem.OwnerId);
        }
    }

    if (!caseOwnerIds.isEmpty()) {
        List<PermissionSetAssignment> permissionSetAssignments = [SELECT AssigneeId
            FROM PermissionSetAssignment
            WHERE permissionsetgroup.DeveloperName = :System.Label.C360_ServiceTeam_PermissionSetGroup
                AND AssigneeId IN :caseOwnerIds];

        for (PermissionSetAssignment accessRep : permissionSetAssignments) {
            serviceTeamUserIds.add(accessRep.AssigneeId);
        }
    }

    for (Case caseRep : filteredCaseRecord) {
        if (serviceTeamUserIds.contains(caseRep.OwnerId)) {
            caseRep.C360_Case_Agent__c = caseRep.OwnerId;
        }
    }
}
    
    /*
* @description	: [CUS-405]-  Validate list of case types / Sales Org
* @return		: void
* @param		:List<Case> newItems, Map<id,Case> oldItems
*/  
    public static void validationOnCase(List<Case> newItems, Map<id,Case> oldItems){
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        Boolean isTeamLeader = FeatureManagement.checkPermission(System.Label.C360_Admin);
        Boolean isServiceTeam = FeatureManagement.checkPermission(System.Label.C360_Service_Team);
        List<Case> filteredCase = new List<Case>();
        Set<String> caseTypeSubTypeIE = new  Set<String>();
        Set<String> caseTypeSubTypeNIR = new  Set<String>();
        //Map <String, Decimal> mapCaseTypeSubTypeWithTime = new Map <String, Decimal> ();
        
        for(Case cmp : newItems){
            if((oldItems == NULL || (oldItems != NULL && oldItems.containsKey(cmp.id) && (cmp.Type != oldItems.get(cmp.id).Type || cmp.D1_Subject__c != oldItems.get(cmp.id).D1_Subject__c))) 
               && cmp.RecordTypeId == recordTypeIdD1Case && (isTeamLeader || isServiceTeam)){
                   filteredCase.add(cmp);
               }
        }
        if (filteredCase != null && filteredCase.Size()>0){
            for(Customer_360_Entitlement_Setting__mdt meta : Customer_360_Entitlement_Setting__mdt.getAll().values()){
                if(meta.C360_IsActive__c){
                    if(meta.C360_Country_Code__c.split('_').contains(System.Label.C360_Country_Code_IE)){
                        caseTypeSubTypeIE.add(meta.C360_Type_Sub_Type__c);
                    } 
                    if(meta.C360_Country_Code__c.split('_').contains(System.Label.C360_Country_Code_NIR)){
                        caseTypeSubTypeNIR.add(meta.C360_Type_Sub_Type__c);
                    }
                }
            }
            for(Case updatedCase : filteredCase){
                if((updatedCase.Country__c == System.Label.C360_Country_Code_IE && !caseTypeSubTypeIE.contains(updatedCase.Type + '-' + updatedCase.D1_Subject__c)) || 
                   (updatedCase.Country__c == System.Label.C360_Country_Code_NIR && !caseTypeSubTypeNIR.contains(updatedCase.Type + '-' + updatedCase.D1_Subject__c))){
                       updatedCase.addError(System.Label.C360_Case_Type_Sub_Type_Error_Message);
                   }
            }
        }
    }
    /*
* @description  : CUS-254 - This method is used to create entitlements record for IE and NIR Accounts
* @return       : void
* @param        : List<sObject> 
*/      
    public static void createEntitlements(List<sObject> newItems){
        Id d1RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        Map<String,String> customMetaSetup = new map<String,String>();
        Map<String,Id> entitlementMap = new Map<String,Id>();
        Map<Id,Entitlement> accWithExistingEntitlement = new map<Id,Entitlement>();
        Map<Id,Entitlement> accWithNewEntitlement = new map<Id,Entitlement>();
        Set<Id> accountIds = new Set<Id>();
        Map<Id,Account> accountMap = new map<Id,Account>();
        List<String> countryCodes = new List<String>();
        //List<String> caseTypes = new List<String>();
        //List<String> caseSubTypes = new List<String>();
        Set<String> caseTypeSubType = new  Set<String>();
        //Map <String, Decimal> mapCaseTypeSubTypeWithTime = new Map <String, Decimal> ();
        
        for(Case cs:(List<Case>)newItems){
            if(cs.RecordTypeId == d1RecordTypeId){
                accountIds.add(cs.AccountId);
            }
        }
        
        if(!accountIds.isEmpty()){
            for(Account acc:[select Id,Name,RecordType.Name FROM Account WHERE Id IN:accountIds]){
                accountMap.put(acc.Id, acc);
            }
            
            for(Customer_360_Entitlement_Setting__mdt meta :
                Customer_360_Entitlement_Setting__mdt.getAll().values()){
                    if(!customMetaSetup.containsKey(meta.Label)){
                        customMetaSetup.put(meta.Label, meta.C360_Country_Code__c);
                        countryCodes.addAll(meta.C360_Country_Code__c.split('_'));
                    }
                    if(meta.C360_Milestone_Time_In_Minutes__c >1 ){
                        //caseTypes.add(meta.C360_Type_Sub_Type__c.split('-')[0]);
                        //caseSubTypes.add(meta.C360_Type_Sub_Type__c.split('-')[1]);
                        caseTypeSubType.add(meta.C360_Type_Sub_Type__c);
                        //mapCaseTypeSubTypeWithTime.put(meta.C360_Type_Sub_Type__c,meta.C360_Milestone_Time_In_Minutes__c);
                    }
                }
            
            for(SlaProcess sla : [SELECT Id, Name, IsActive, SobjectType, BusinessHoursId 
                                  FROM SlaProcess 
                                  WHERE IsActive =true AND IsVersionDefault=true
                                  AND Name IN: customMetaSetup.keySet() 
                                  Order by VersionNumber DESC]){
                                      entitlementMap.put(sla.name,sla.Id);
                                  }
            for(Entitlement ent: [SELECT Id, Name, AccountId, StartDate, EndDate, SlaProcessId, BusinessHoursId  
                                  FROM Entitlement WHERE AccountId IN:accountIds AND Status='Active'
                                  AND SlaProcessId IN:entitlementMap.values()
                                 ]){
                                     accWithExistingEntitlement.put(ent.AccountId,ent);
                                 }
            
            for(Case cs:(List<Case>)newItems){
                if(countryCodes.contains(cs.Country__c) &&
                   cs.RecordTypeId == d1RecordTypeId && !entitlementMap.isEmpty() &&
                   !accWithExistingEntitlement.containsKey(cs.AccountId) &&
                   caseTypeSubType.contains(cs.Type + '-' + cs.D1_Subject__c)){
                       Entitlement newEntitlementInstance = new Entitlement();
                       newEntitlementInstance.AccountId = cs.AccountId;
                       newEntitlementInstance.SlaProcessId = entitlementMap.values()[0];
                       newEntitlementInstance.Name = 'C360_'+accountMap.get(cs.AccountId).Name;
                       newEntitlementInstance.StartDate = Date.Today();
                       accWithNewEntitlement.put(cs.AccountId,newEntitlementInstance);
                   }
            }
            if(!accWithNewEntitlement.isEmpty()){
                Insert accWithNewEntitlement.values();
            }
            
            for(Case cs:(List<Case>)newItems){
                if(cs.RecordTypeId == d1RecordTypeId &&
                   caseTypeSubType.contains(cs.Type + '-' + cs.D1_Subject__c)){
                       cs.EntitlementId = accWithExistingEntitlement.containsKey(cs.AccountId)?
                           accWithExistingEntitlement.get(cs.AccountId).Id:accWithNewEntitlement.containsKey(cs.AccountId)?
                               accWithNewEntitlement.get(cs.AccountId).Id:null;
                   }
                
                /*
// New Change For Case Priority
if (cs.RecordTypeId == d1RecordTypeId && mapCaseTypeSubTypeWithTime.containsKey(cs.Type + '-' + cs.D1_Subject__c) && mapCaseTypeSubTypeWithTime.get(cs.Type + '-' + cs.D1_Subject__c) == 60) {
cs.Priority ='3-High';
}*/
                else if(cs.RecordTypeId == d1RecordTypeId && 
                        (!caseTypeSubType.contains(cs.Type + '-' + cs.D1_Subject__c))){
                            cs.EntitlementId = null;
                        }
            }
        }
    }
    /*
* @description  : CUS-255 - When case status is changed to Closed, Milestone will be completed using this method
* @return       : void
* @param        : Map<Id, SObject>, Map<Id, SObject> 
*/  //CUS-255 -> start
    public static void completeCaseMilestoneOnCaseStatusUpdate(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Case> oldCaseRecordMap = (Map<Id, Case>)oldItems;
        Map<Id, Case> newCaseRecordMap = (Map<Id, Case>)newItems;
        Set <Id> setCaseIdToCompleMilestone = new Set <Id> ();
        List<CaseMilestone> casesMileStoneToUpdate = new List<CaseMilestone>();
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        
        for (Case caseUpdated : newCaseRecordMap.values()) {
            if (caseUpdated.Status != oldCaseRecordMap.get(caseUpdated.Id).Status && 
                caseUpdated.Status == System.Label.C360_Status_Closed && 
                caseUpdated.RecordTypeId == recordTypeIdD1Case) {
                    setCaseIdToCompleMilestone.add(caseUpdated.Id);
                }
        }
        
        if (!setCaseIdToCompleMilestone.isEmpty()){
            for (CaseMilestone milestone : [
                SELECT Id,
                CompletionDate
                FROM CaseMilestone
                WHERE CaseId IN :setCaseIdToCompleMilestone AND CompletionDate = null
            ]){
                milestone.CompletionDate = System.now();
                casesMileStoneToUpdate.add(milestone);
            }
        }
        
        if (!casesMileStoneToUpdate.isEmpty()) {
            update casesMileStoneToUpdate;
        }
    }
    //CUS-255 -> end
    /*
* @description  : CUS-256 - MileStone will be again start on reopened case status
* @return       : void
* @param        : Map<Id, SObject>, Map<Id, SObject> 
*/  
    public static void reOpenCaseMilestoneOnCaseStatus(Map<Id, SObject> newItems, Map<Id, SObject> oldItems) {
        Map<Id, Case> oldCaseRecordMap = (Map<Id, Case>)oldItems;
        Map<Id, Case> newCaseRecordMap = (Map<Id, Case>)newItems;
        Set <Id> setCaseIdToCompleMilestone = new Set <Id> ();
        Id recordTypeIdD1Case =  Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(System.Label.C360_D1_Case_RecordType).getRecordTypeId();
        
        for (Case caseUpdated : newCaseRecordMap.values()) {
            if (caseUpdated.Status != oldCaseRecordMap.get(caseUpdated.Id).Status && 
                oldCaseRecordMap.get(caseUpdated.Id).Status==System.Label.C360_Status_Closed &&
                caseUpdated.Status == system.Label.C360_Re_Opened && caseUpdated.RecordTypeId == recordTypeIdD1Case) {
                    setCaseIdToCompleMilestone.add(caseUpdated.Id);
                }
        }
        
        if(!setCaseIdToCompleMilestone.isEmpty()){
            D1_CaseTriggerHelper.updateMilestone(setCaseIdToCompleMilestone);
        }
    }
    @future
    public static void updateMilestone(set<Id> setCaseIdToCompleMilestone){
        
        List<CaseMilestone> cmsToUpdate = new List<CaseMilestone>();
        //Milestone completion logic
        for (CaseMilestone cms : [select Id, completionDate from CaseMilestone where caseId iN :setCaseIdToCompleMilestone]) {
            cms.completionDate = null;
            cmsToUpdate.add(cms);
        }
        if (!cmsToUpdate.isEmpty()) {
            update cmsToUpdate;
        }
    }
    /*
* @description	: CUS-439 - Case Visibility for Logistic Users
* @return		: void
* @param		: Map<Id, SObject>, Map<Id, SObject>, String Operation
*/ 
    public static void assignDiageoOneCasesToTerritory (Map<Id, SObject> mapNewCases, Map<Id, SObject> mapOldCases, String operationName) {
        Map<Id, Case> newCaseRecordMap = (Map<Id, Case>)mapNewCases;
        Map<Id, Case> oldCaseRecordMap = (Map<Id, Case>)mapOldCases;
        List <Group> listGroupForLogisctic = new List <Group> ();
        Map <Id, String> mapGrpIdWIthName = new Map <Id, String> ();
        Id diageoOneCaseRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        Group territoryROI = [select id,DeveloperName  from Group where Type =: System.Label.C360_Territory AND DeveloperName =: System.Label.C360_Logistic_Territory_IE LIMIT 1];
        Group territoryNIR = [select id,DeveloperName  from Group where Type =: System.Label.C360_Territory AND DeveloperName =: System.Label.C360_Logistic_Territory_NIR LIMIT 1];
        listGroupForLogisctic.add(territoryROI);
        listGroupForLogisctic.add(territoryNIR);
        
        for (Group logsticGrp : listGroupForLogisctic) {
            mapGrpIdWIthName.put(logsticGrp.Id, logsticGrp.DeveloperName);
        }
        
        List <Id> validCaseIds = new List <Id> ();
        List <CaseShare> shareRecordtoInsertList= new List<CaseShare>();
        List <CaseShare> shareRecordtoDeleteList= new List<CaseShare>();
        //List <Case> caseList = new List <Case> ();
        
        for(Case caseRec: newCaseRecordMap.values()){
            
            if (caseRec.recordTypeId == diageoOneCaseRecordTypeId && (operationName == 'Insert' || 
                                                                      (operationName == 'Update' && caseRec.AccountId != null && caseRec.AccountId != oldCaseRecordMap.get(caseRec.Id).AccountId && caseRec.Country__c != oldCaseRecordMap.get(caseRec.Id).Country__c) ||
                                                                      (operationName == 'Update' && caseRec.AccountId != null && caseRec.OwnerId != oldCaseRecordMap.get(caseRec.Id).OwnerId))) { //Check For RecordTypes
                                                                          for(Customer_360_Entitlement_Setting__mdt metadataRec :
                                                                              Customer_360_Entitlement_Setting__mdt.getAll().values()){
                                                                                  if(String.isNotBlank(caseRec.Type) && String.isNotBlank(caseRec.D1_Subject__c) && metadataRec.C360_Type_Sub_Type__c.contains(caseRec.Type) && //Comparing caseRec With meta data
                                                                                     metadataRec.C360_Type_Sub_Type__c.contains(caseRec.D1_Subject__c) && 
                                                                                     metadataRec.C360_IsLogisticRep__c && 
                                                                                     metadataRec.C360_Country_Code__c.contains(caseRec.Country__c)){
                                                                                         validCaseIds.add(caseRec.Id);
                                                                                     }
                                                                              }
                                                                      }
        }
        
        if (!validCaseIds.isEmpty()) {
            for(Case caseRecordToTerr : newCaseRecordMap.values()) {
                if (validCaseIds.contains(caseRecordToTerr.Id)) {
                    CaseShare caseShareForIE = new CaseShare();
                    caseShareForIE.CaseId = caseRecordToTerr.Id ;
                    caseShareForIE.CaseAccessLevel = 'Edit';
                    caseShareForIE.RowCause ='Manual';
                    if (caseRecordToTerr.Country__c == System.Label.C360_Country_Code_IE){
                        caseShareForIE.UserOrGroupId = territoryROI.Id;
                        shareRecordtoInsertList.add(caseShareForIE);
                    }else if(caseRecordToTerr.Country__c  == System.Label.C360_Country_Code_NIR) {
                        caseShareForIE.UserOrGroupId = territoryNIR.Id;
                        shareRecordtoInsertList.add(caseShareForIE);
                    }
                }
            }
            
        }
        if (!shareRecordtoInsertList.isEmpty()) {
            insert shareRecordtoInsertList ;
        }
        if (operationName == 'Update') {
            Map <Id, String> mapCaseIdWithCountryCode = new Map <Id, String> ();
            for (Case caseUpdated : newCaseRecordMap.values()) {
                if (caseUpdated.RecordTypeId == diageoOneCaseRecordTypeId && caseUpdated.AccountId != null && caseUpdated.AccountId != oldCaseRecordMap.get(caseUpdated.Id).AccountId && caseUpdated.Country__c != oldCaseRecordMap.get(caseUpdated.Id).Country__c ) {
                    mapCaseIdWithCountryCode.put(caseUpdated.Id, caseUpdated.Country__c);
                }
            }
            if (mapCaseIdWithCountryCode != null) {
                for(CaseShare caseShareRecordForLogisctic: [SELECT Id, CaseId, UserOrGroupId,userorgroup.name FROM CaseShare WHERE CaseId IN: mapCaseIdWithCountryCode.keySet() AND UserOrGroupId IN :mapGrpIdWIthName.keySet()]) {
                    String tempCountryName = mapCaseIdWithCountryCode.get(caseShareRecordForLogisctic.CaseId);
                    if (!mapGrpIdWIthName.get(caseShareRecordForLogisctic.UserOrGroupId).contains(tempCountryName) ) {
                        shareRecordtoDeleteList.add(caseShareRecordForLogisctic);
                    }                
                }
            } 
            if (shareRecordtoDeleteList != null) {
                delete shareRecordtoDeleteList;
            }           
        }
    }
    /*
* @description	: 143374: Fasttrack_ SLA with 1hour should be Priority High
* @return		: void
* @param		: List<SObject>, Map<Id, SObject>, String Operation
*/ 
    public static void setUpCasePriority(List<Case> newItems, Map<id,Case> oldItems){
        Id recordTypeIdD1Case=Schema.SObjectType.Case.getRecordTypeInfosByDeveloperName().get(Label.C360_D1_Case_RecordType).getRecordTypeId();
        Map <String, Customer_360_Entitlement_Setting__mdt> mapCaseTypeSubTypeWithTime = new Map <String, Customer_360_Entitlement_Setting__mdt> ();
        for(Customer_360_Entitlement_Setting__mdt meta :
            Customer_360_Entitlement_Setting__mdt.getAll().values()){
                if(meta.C360_Milestone_Time_In_Minutes__c >1 ){
                    mapCaseTypeSubTypeWithTime.put(meta.C360_Type_Sub_Type__c,meta);
                }
            }
        for(Case cs:(List<Case>)newItems){
            String newCaseTypeSubType = cs.Type + '-' + cs.D1_Subject__c;
            if(cs.RecordTypeId == recordTypeIdD1Case &&
               mapCaseTypeSubTypeWithTime.containsKey(newCaseTypeSubType) &&
               mapCaseTypeSubTypeWithTime.get(newCaseTypeSubType).C360_Country_Code__c.split('_').contains(cs.Country__c))
            {
                if(mapCaseTypeSubTypeWithTime.get(newCaseTypeSubType).C360_Milestone_Time_In_Minutes__c == 60){
                    cs.Priority = System.Label.C360_D1_Case_Priority_High;
                }else if(Trigger.isUpdate && newCaseTypeSubType != String.valueOf(oldItems.get(cs.Id).Type + '-' + oldItems.get(cs.Id).D1_Subject__c)
                         && mapCaseTypeSubTypeWithTime.get(newCaseTypeSubType).C360_Milestone_Time_In_Minutes__c > 60){
                             cs.Priority = System.Label.C360_D1_Case_Priority_Med;
                         }
            }
        }
        
    }
}