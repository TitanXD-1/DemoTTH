/*
* @Name: CRG_CreateContractController
* @description: This is Class for fetch data realted CRG Contract creation 
* @History                                                            

VERSION			AUTHOR				DATE	.				DETAIL
1.0			Suvendu				20/12/2023				Initial Development
2.0			Suvendu				09/02/2024				CRG: Contract Approved to Close logic
2.1			Saurav Prasad		19/03/2024				151023 - CRG Enhancements: Outlet search/auto-populate_SFDC
3.0			Doman Murmu			30/08/2024				155795: Agreement Type Sorting Cold Room Grant
*/
/**
* @description Controller class for CRG Contract
*/
public with sharing class CRG_CreateContractController {

    /**
     * @description Get related Agreement Type
     * @param accountId
     * @return List<ECM_Contract_Type__c>
     */
    @AuraEnabled(cacheable=true)
    public static list<ECM_Contract_Type__c> getContractTypesOutlet(String accountId){
        List<ECM_Contract_Type__c> ecmContractType = new list<ECM_Contract_Type__c>();
        set<Id> agreementTypeIds = new set<Id>();
        Account accObj = new Account();
        if(!(String.isBlank(accountId))){
            accObj = [SELECT Id,Independent_of_Operator__c,Name,Operator__c,Local_Segment1__c FROM Account where Id =: accountId WITH SECURITY_ENFORCED];
            NoSharing ns = new NoSharing();
            List<ECM_Role_Agreement__c> eraList = ns.noSharingMethod();
            if(eraList.size()>0){
                for(ECM_Role_Agreement__c era : eraList){
                    agreementTypeIds.add(era.Agreement_Type__c);
                }
            }
        }
        if(agreementTypeIds.size()>0 && accObj!= null){
                if(!(String.isBlank(accObj.Operator__c))){ 
                    ecmContractType = [SELECT id,CRG_Cold_Room_Grant__c,ECM_E_S_Event_Date_Gap__c,Geography__r.Code__c,ECM_Aggrement_Duration__c,ECM_Local_Segment1__c,Name,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Number_of_Retro_Months__c,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where ECM_Visible__c = true AND ECM_Allow_Independent__c = true AND CRG_Cold_Room_Grant__c = true AND( ECM_Local_Segment1__c=null OR ECM_Local_Segment1__c=:accObj.Local_Segment1__c) AND Id IN: agreementTypeIds WITH SECURITY_ENFORCED ORDER BY Name];	//155795
                }
                else if(accObj.Independent_of_Operator__c){
                    ecmContractType = [SELECT id,CRG_Cold_Room_Grant__c,ECM_E_S_Event_Date_Gap__c,Geography__r.Code__c,Name,ECM_Aggrement_Duration__c,ECM_Local_Segment1__c,ECM_Ad_Hoc__c,ECM_Min_Duration__c,ECM_Max_Duration__c,ECM_generate_contract_name__c,ECM_Abbreviation__c, ECM_Visible__c ,ECM_Allow_Independent__c,ECM_Number_of_Retro_Months__c,ECM_Activation_Spend__c FROM ECM_Contract_Type__c where ECM_Visible__c = true AND CRG_Cold_Room_Grant__c = true AND( ECM_Local_Segment1__c=null OR ECM_Local_Segment1__c=:accObj.Local_Segment1__c) AND Id IN: agreementTypeIds WITH SECURITY_ENFORCED ORDER BY Name]; //155795
                }
            }
        system.debug(LoggingLevel.DEBUG,ecmContractType);
        
        return ecmContractType;
    }

    /**
     * @description Get related Supplier Outlets
     * @param accId
     * @return List<Supplier_Outlet__c>
     */
    @AuraEnabled
    public static List<Supplier_Outlet__c> getSupplierOutlets(String accId)
    {
        try{
            Map<Id,Supplier_Outlet__c> supplierOutletMap = new Map<Id,Supplier_Outlet__c>();            
            for(Supplier_Outlet__c item: [Select Id,Name,Distributor_Wholesaler__c,
            Distributor_Wholesaler__r.Name from Supplier_Outlet__c 
            where outlet__c = :accId WITH SECURITY_ENFORCED]){
                if(!supplierOutletMap.containsKey(item.Distributor_Wholesaler__c)){
                    supplierOutletMap.put(item.Distributor_Wholesaler__c, item);
                }
            }
            if(!supplierOutletMap.isEmpty()){
                return supplierOutletMap.values();
            }
        }
        catch(exception e){
            system.debug(LoggingLevel.DEBUG,'error'+e.getMessage());
        }
        return null;
    }
    
    /**
     * @description Validate Contract
     * @param dataFromComponent
     * @return String
     */
    @AuraEnabled
    public static String validatedContract(String dataFromComponent){
        ID recordTypeId = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();
        ECM_Contract_Type__c aggType = new ECM_Contract_Type__c();
        List<Contract> draftConList = new List<Contract>();
        List<Contract> otherStatusConList = new List<Contract>();
        List<string> statusList = new List<string> {'Approved','In Approval Process'};
           
        Contract  contractRecord = (Contract)JSON.deserialize(dataFromComponent,Contract.class);
        if(contractRecord.ECM_Agreement_Type__c!=null){
            aggType = [SELECT Id, Name,CRG_Allow_Multiple_CRG_contracts__c, ECM_Allow_Multiple_Agreements__c FROM ECM_Contract_Type__c WHERE Id =:contractRecord.ECM_Agreement_Type__c WITH SECURITY_ENFORCED LIMIT 1];
            if(aggType.CRG_Allow_Multiple_CRG_contracts__c){
                return 'Success';
            }
        }
        
        for(Contract con :
            [SELECT Id, Name, Status,AccountId FROM Contract 
             WHERE AccountId =:contractRecord.AccountId	 
             And Status = 'Draft' AND recordtypeid =:recordTypeId 
             AND ECM_Agreement_Type__c =:contractRecord.ECM_Agreement_Type__c WITH SECURITY_ENFORCED]){
                 if(con.Status == 'Draft'){
                     draftConList.add(con);
                 }else if(statusList.contains(con.Status)){
                     otherStatusConList.add(con);
                 }
             }
        if(draftConList.Size()>0){
            return 'DraftError';
        }else if(!aggType.ECM_Allow_Multiple_Agreements__c){
            return getErrorForElseBlock(otherStatusConList,contractRecord);
        }else{
            return 'Success';
        }
    }
    
    /**
     * @description Get Error
     * @param otherStatusConList
     * @param contractRecord
     * @return String
     */
    public static string getErrorForElseBlock(List<Contract> otherStatusConList,Contract  contractRecord){
            for(Contract conRec : otherStatusConList){
                if(conRec.Contract_End_Date__c >= contractRecord.StartDate){
                    return 'ApprovedError';
                }
            }
            return 'Success';
    }
    
    /**
    * @description Fetch data related to Agreement Type
    */
    public without sharing class NoSharing {
        
         /**
         * @description Fetch related Role Agreement associated with User's Business Role
         * @return List<ECM_Role_Agreement__c>
         */
        public List<ECM_Role_Agreement__c> noSharingMethod() {
            User_Business_Role__c usb=[SELECT Id,name,user__r.name,Business_Role__c,Business_Role__r.name from User_Business_Role__c where user__c =: userinfo.getUserId() WITH SECURITY_ENFORCED];
            return [SELECT Id,name,Agreement_Type__r.name,Agreement_Type__c,Business_Role__c from ECM_Role_Agreement__c where Business_Role__c =: usb.Business_Role__c WITH SECURITY_ENFORCED];
        }
    }
    
    /**
     * @description Change Cold Room Grant Contract Status
     * @param recordId
     * @return String
     */    
    @AuraEnabled
    public static String changeCRGContractStatus(String recordId){
        String recordTypeID = Schema.getGlobalDescribe().get('Contract').getDescribe().getRecordTypeInfosByName().get('Cold Room Grant').getRecordTypeId();
        Contract conRec = new Contract(); 
        Id profileId=userinfo.getProfileId();
        List <String> profileNames = new List <String>{'System Administrator', 'CIO User', 'EDGE BAU USER'};
        String profileName=[Select Id,Name from Profile where Id=:profileId].Name;
        if(!profileNames.contains(profileName)){
            return 'ProfileAccessError';
        }else{
            conRec = [SELECT Id, Status,ContractNumber FROM Contract WHERE Id=: recordId AND RecordTypeID=: recordTypeID WITH SECURITY_ENFORCED LIMIT 1];
        }
        if(conRec != null ){
            if(conRec.Status == 'Approved' && Schema.sObjectType.Contract.fields.Status.isUpdateable()){
                conRec.Status = 'Closed';
                update conRec;
                return conRec.ContractNumber+'Success';
            }else{
                return 'notApproved';
            }
        }
        return 'noRecordFound';
    }
}