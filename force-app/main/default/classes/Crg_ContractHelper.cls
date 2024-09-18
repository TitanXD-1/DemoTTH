/*
Name: Crg_ContractHelper
*
Purpose: Contract Record creation with Cold Room Grant Record Type
*
History                                                            
*                                                            
VERSION     AUTHOR              DATE                DETAIL
1.0         SaiKiran            27/12/2023          Contract Record creation with Cold Room Grant Record Type
1.2			Saurav Prasad		22/01/2024			149936 - CRG: Editing Draft Contract_SFDC
2.1         Saurav Prasad       29/01/2024          150507 - CRG Contracts Referring to - ECM_Overall_Investment_Figure__c For Approval mail triggering
2.1			Saurav Prasad       30/01/2024          150544 - QA_Defect: Unable to Cancel the CRG contract in Screen 1 & Screen 2
2.2			Saurav Prasad		19/03/2024			151023 - CRG Enhancements: Outlet search/auto-populate_SFDC
*/
public without sharing class Crg_ContractHelper {
    
    @AuraEnabled
    public static Contract getContract(String contractid){
        System.debug(LoggingLevel.Debug,'contractid @'+contractid);
        //151023 - added  ECM_Outlets_selected_Legal_Name__c,Account.ECM_Legal_Name__c
        return [SELECT Id,ECM_Overall_Investment_Figure__c,AccountId,Name,ContractNumber,ECM_Last_saved_page__c,Contract_End_Date__c,ECM_Duration__c,Status,
                StartDate,recordTypeId,ECM_Agreement_Type__c,ECM_Agreement_Type__r.Geography__c,CreatedBy.Name,Account.Name,ECM_Overall_Investment_Amount__c,OwnerId,
                Recordtype.Name,ECM_Agreement_Type__r.Geography__r.Name,Account.Country_Code__c,ECM_Agreement_Type__r.ECM_Generate_Contract_Name__c,
                ECM_Primary_Spirit_Distributor__c, ECM_Secondary_Spirit_Distributor__c, ECM_Primary_Beer_Distributor__c,
                CRG_Refrigeration_Contractor__c,CRG_Outlet_Trade_Affiliation__c,CRG_Type_of_Equipment__c,CRG_Equipment_Status__c,CRG_Power_provided_for_Surge_20X__c,
                CRG_Water_provided_for_Surge_20X__c,CRG_Installation_Date__c,CRG_Total_Number_of_Diageo_Taps__c,CRG_Total_Number_of_Brands_in_Outlet__c,
                CRG_Total_Number_of_Diageo_Brands__c,CRG_Total_Cost_of_Refrigeration_ex_Vat__c,CRG_Total_Investment__c,CRG_Payment_Method__c,CRG_Payment_Frequency__c,
                CRG_Notes_Comments__c,CRG_Contract_Type__c,ECM_Outlets_selected_Legal_Name__c,Account.ECM_Legal_Name__c
                FROM contract WHERE Id=:contractid WITH SECURITY_ENFORCED];
                    }
    
    @AuraEnabled
    public static Contract saveContract(String dataFromComponent){
        
        Contract  contractRecord = (Contract)JSON.deserialize(dataFromComponent,Contract.class);
        //150507
        contractRecord.ECM_Overall_Investment_Figure__c=contractRecord.CRG_Total_Investment__c;
        if(Schema.sObjectType.Contract.IsCreateable() && Schema.sObjectType.Contract.isUpdateable()){
            upsert contractRecord;
        }
        
        return getContract(contractRecord.Id);
        
    }
    @AuraEnabled
    public static ObjectWrapper saveContractForSubmit(String dataFromComponent){
        Contract contractRecord = saveContract(dataFromComponent);
        Account acc = new Account();
        Market_Setting__c marketObjs = new Market_Setting__c();
        string errormessage='';
        
        ObjectWrapper wrap = new ObjectWrapper();
        
        acc = [SELECT id,Name,operator__r.ECM_Legal_Name__c,Person_Responsible__r.Manager.DelegatedApproverId,
                     ECM_Legal_Name__c,Person_Responsible__c,Operator__r.Person_Responsible__c,Independent_of_Operator__c,
                     Direct_Customer__c,Global_Segment__c,Global_Sub_Segment__c,Local_Segment1__c,Local_Segment2__c,Outlet_Visit_Prioritisation_Grade__c,
                     Outlet_Visit_Prioritisation_Grade__r.Name,Local_Segment1__r.Name,BillingState,SAP_Sold_to__c,VAT_Number__c,New_VAT__c,
                     SAP_Ship_to__c,Sales_Org__c,Person_Responsible__r.ManagerId,Person_Responsible__r.DelegatedApproverId,Hybrid__c,
                     Global_Channel__c,Parent_Outlet__c,Email_for_contracts_payments__c,Country__c,Country__r.Code__c 
                     FROM Account WHERE Id=:contractRecord.AccountId WITH SECURITY_ENFORCED];
        
        marketObjs = [SELECT Id, Name,Geography__r.Code__c,ECM_Mandatory_field_for_Contract__c,
                      ECM_Contract_Creation_Page__c FROM Market_Setting__c WHERE Geography__c =: acc.Country__c WITH SECURITY_ENFORCED Limit 1];
        
        wrap.conId = contractRecord.Id;
        wrap.contractRec = contractRecord;
        wrap.accountRec = acc;
        wrap.marketSetting = marketObjs;
        
        if(!String.isBlank(marketObjs.ECM_Mandatory_field_for_Contract__c)){
        errormessage = validateMandatory(marketObjs,acc);
        }
        
        if(String.isBlank(errormessage)){
            wrap.status = CRG_ContractApprovalHelper.submitForApproval(contractRecord);
        }
        wrap.message = errormessage;
        
        return wrap;
    }
    //151023 - for static code fix 
    public static String validateMandatory(Market_Setting__c marketObjs, Account acc){
        String errormessage = '';
        
        if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('SAP Sold to') && string.isBlank(acc.SAP_Sold_to__c)){ 
            errormessage += ':'+System.Label.ECM_SAP_Number_Validation;//'customer SAP number is missing from customer record, cannot submit for approval';
        }
        if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('VAT number') && String.isBlank(acc.New_VAT__c)){
            errormessage += System.Label.ECM_VAT_number;//':Tax registration number is missing from customer record, cannot submit for approval';
        }
        if (marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Legal Name') && String.isBlank(acc.ECM_Legal_Name__c)){ 
            errormessage += System.Label.ECM_Legal_Name_Validation;
        }
        if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('SAP Ship to') && String.isBlank(acc.SAP_Ship_to__c)){
            errormessage += System.Label.ECM_SAP_Ship_To ;
        }
        if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Customer email for Contract') && String.isBlank(acc.Email_for_contracts_payments__c)){
            errormessage += System.Label.ECM_Email_for_contracts_payments_Validation ;
        }
        if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Sales org') && String.isBlank(acc.Sales_Org__c)){ 
            errormessage += System.Label.ECM_Sales_Org ;
        }
        if(marketObjs.ECM_Mandatory_field_for_Contract__c.contains('Tax Identification number') && String.isBlank(acc.VAT_Number__c)){ 
            errormessage += System.Label.ECM_Tax_Registration_Number_Validation;
        }
        return errormessage;
        
    }
    //150544
    @AuraEnabled
    public static void cancelOffer(String recordId){
        if(!String.isBlank(recordId)){
            Contract con = new Contract(Id = recordId, Status = 'Cancelled');
            if(Schema.sObjectType.Contract.isUpdateable()){
                update con; 
            }
        }
    }
    
    // wrapper class
    public class ObjectWrapper{
        @AuraEnabled
        public string conId {get;set;}
        @AuraEnabled
        public Contract contractRec{get;set;}
        @AuraEnabled
        public string message{get;set;}
        @AuraEnabled
        public string status{get;set;}
        @AuraEnabled
        public Account accountRec{get;set;}
        @AuraEnabled
        public Market_Setting__c marketSetting{get;set;}
        public objectWrapper(){
            this.conId = '';
            this.contractRec = new Contract();
            this.message = '';
            this.status = '';
            this.accountRec = new Account();
            this.marketSetting = new Market_Setting__c();
        }
        
    }
    /*
    @AuraEnabled
    public static Contract createContractRecord (String dataFromComponent, String outletPaymentRecordFieldValues, String buttonClicked) {
        Contract dataToReturn = new Contract();
         String mandatoryField ='';
        String errormessage = '';
        String vals = system.label.CRG_Field_Mapping_with_Api;
        Map<String,Schema.SObjectField> mfields = Schema.Account.SObjectType.getDescribe().fields.getMap();
        
        if(outletPaymentRecordFieldValues != null){
            ContractRecordFieldsWrapper  contractFields= (ContractRecordFieldsWrapper)JSON.deserialize(dataFromComponent,ContractRecordFieldsWrapper.class);
          
            OutletPaymentRecordFieldsWrapper contractPaymentFields = (OutletPaymentRecordFieldsWrapper)JSON.deserialize(outletPaymentRecordFieldValues,OutletPaymentRecordFieldsWrapper.class);
            
            accountWrapper accwrap = getAccountById(contractFields.selectedOutlet);
            
          
            
            // Check Marketing setting values
            if (buttonClicked == 'In Approval Process' && contractFields.selectedOutlet != null) {
                mandatoryField  = checkMarketingSettingFieldValues(contractFields.selectedOutlet);
               
                if(!String.isBlank(MandatoryField)) {
                    for(String fields: vals.split(';')){
                        List<String> parts = fields.split(':');
                        String fieldApi = parts[1];
                        String fieldName = parts[0];

                        
                        if(mandatoryField.contains(fieldName) && (String.isBlank((String)accwrap.acc.get(fieldApi)) || (String)accwrap.acc.get(fieldApi) == null) ){
                           
                            errormessage += mfields.get(fieldApi).getDescribe().getLabel()+', ';
                        }
                    }
                }
                
                if(errormessage != ''){
                    errormessage = errormessage.removeEnd(', ');
                    errormessage += ' '+System.label.CRG_Error_Message;
                    throw new AuraHandledException(errormessage+'');
                }
            } 
            
            
            // All checks passed - Create contract Record OR Clicked - Save For Later
            if (buttonClicked == 'Draft' || (buttonClicked == 'In Approval Process' && !String.isBlank(mandatoryField))) {
                dataToReturn = insertContractRecord (contractFields,contractPaymentFields,'Draft') ;
            }
        }
        if(buttonClicked == 'In Approval Process'){
            CRG_ContractApprovalHelper.submitForApproval(dataToReturn);
        }    
        return dataToReturn;
    }
    
    
    public static Contract insertContractRecord (ContractRecordFieldsWrapper  contractFields, OutletPaymentRecordFieldsWrapper contractPaymentFields, String contractStatus) {
        
        //try {
        Contract newContractRecord = new Contract ();
        newContractRecord.Name = contractFields.contractName ;
        newContractRecord.AccountId = contractFields.selectedOutlet ;
        newContractRecord.ECM_Outlets_selected_Legal_Name__c = contractFields.legalName;
        newContractRecord.Status = contractStatus;
        newContractRecord.StartDate = contractFields.contrStartDate;
        newContractRecord.Contract_End_Date__c = contractFields.contrEndData;
        newContractRecord.ECM_Duration__c = contractFields.selectedDuration;
        newContractRecord.ECM_Agreement_Type__c = contractFields.agreementType;
        newContractRecord.ECM_Primary_Beer_Distributor__c = contractFields.selectedBeerDistribution ;
        newContractRecord.ECM_Primary_Spirit_Distributor__c = contractFields.primarySpiritDistributorValue ;
        newContractRecord.ECM_Secondary_Spirit_Distributor__c = contractFields.secondarySpiritDistributorValue;
        newContractRecord.CRG_Contract_Type__c = 'Outlet';
        newContractRecord.recordTypeId = Schema.SObjectType.Contract.getRecordTypeInfosByDeveloperName().get('CRG_Cold_Room_Grant').getRecordTypeId();
        
        //Payment Fields
        newContractRecord.CRG_Refrigeration_Contractor__c = contractPaymentFields.refrigerationContractorValue;
        newContractRecord.CRG_Outlet_Trade_Affiliation__c = contractPaymentFields.outletTradeAffiliationValue;
        newContractRecord.CRG_Type_of_Equipment__c = contractPaymentFields.typeOfEquipmentOptionValue;
        newContractRecord.CRG_Equipment_Status__c = contractPaymentFields.equipmentStatusValue;
        newContractRecord.CRG_Power_provided_for_Surge_20X__c = contractPaymentFields.powerprovidedforSurge20X_Value;
        newContractRecord.CRG_Water_provided_for_Surge_20X__c = contractPaymentFields.waterprovidedforSurge20X_Value;
        newContractRecord.CRG_Installation_Date__c = contractPaymentFields.installationDateValue;
        newContractRecord.CRG_Total_Number_of_Diageo_Taps__c = contractPaymentFields.totalNumberofDiageoTapsValue;
        newContractRecord.CRG_Total_Number_of_Brands_in_Outlet__c = contractPaymentFields.totalNumberofBrandsInOutletValue;
        newContractRecord.CRG_Total_Number_of_Diageo_Brands__c = contractPaymentFields.totalNumberOfDiageoBrandsValue;
        newContractRecord.CRG_Total_Cost_of_Refrigeration_ex_Vat__c = contractPaymentFields.totalCostOfRefrigerationValue;
        newContractRecord.CRG_Total_Investment__c = contractPaymentFields.diageoInvestmentEurosValue;
        newContractRecord.OwnerId=UserInfo.getUserId();
        newContractRecord.ECM_Overall_Investment_Figure__c=newContractRecord.CRG_Total_Investment__c;
        newContractRecord.CRG_Payment_Method__c = contractPaymentFields.paymentMethodValue;
        newContractRecord.CRG_Payment_Frequency__c	 = contractPaymentFields.paymentFrequencyValue;
        newContractRecord.CRG_Notes_Comments__c = contractPaymentFields.notesCommentsValue;
        if(Schema.sObjectType.Contract.isCreateable()){
        insert newContractRecord;
        }
        return newContractRecord;
     
    }
    
    public static String checkMarketingSettingFieldValues (Id accountOuteltId) {
        
        Boolean messageToReturnAfterCheckingPLVs = true;
        Market_Setting__c marketSettingRecord = new Market_Setting__c();
        String geographyCountryId = [Select Id, Country__c From Account where Id =:accountOuteltId Limit 1].Country__c;
       // if(Schema.sObjectType.Market_Setting__c.isAccessible()){
            marketSettingRecord = [SELECT Id, Name__c,Geography__r.Code__c,ECM_Mandatory_field_for_Contract__c,ECM_Contract_Creation_Page__c FROM Market_Setting__c WHERE Geography__c =: geographyCountryId Limit 1 ];
        //}
        messageToReturnAfterCheckingPLVs = areAllValuesSelected ('Market_Setting__c', 'ECM_Mandatory_field_for_Contract__c', marketSettingRecord.Id);
        // return messageToReturnAfterCheckingPLVs ;
        System.debug(LoggingLevel.Debug,'Value of Record '+marketSettingRecord.ECM_Mandatory_field_for_Contract__c);
        return marketSettingRecord.ECM_Mandatory_field_for_Contract__c;
    }
 
    public class ContractRecordFieldsWrapper{
        @AuraEnabled public string contractName;
        @AuraEnabled public string legalName;
        @AuraEnabled public Id selectedOutlet;
        @AuraEnabled public Date contrStartDate;
        @AuraEnabled public Date contrEndData;
        @AuraEnabled public Decimal selectedDuration;
        @AuraEnabled public Id agreementType;
        @AuraEnabled public Id selectedBeerDistribution;
        @AuraEnabled public Id primarySpiritDistributorValue;
        @AuraEnabled public Id secondarySpiritDistributorValue;
    }
    
    public class OutletPaymentRecordFieldsWrapper{
        @AuraEnabled public String refrigerationContractorValue;
        @AuraEnabled public String outletTradeAffiliationValue;
        @AuraEnabled public String typeOfEquipmentOptionValue;
        @AuraEnabled public String equipmentStatusValue ;
        @AuraEnabled public Boolean powerprovidedforSurge20X_Value;
        @AuraEnabled public Boolean waterprovidedforSurge20X_Value;
        @AuraEnabled public Date installationDateValue;
        @AuraEnabled public Decimal totalNumberofDiageoTapsValue;
        @AuraEnabled public Decimal totalNumberofBrandsInOutletValue;
        @AuraEnabled public Decimal totalNumberOfDiageoBrandsValue ;
        @AuraEnabled public Decimal totalCostOfRefrigerationValue ;
        @AuraEnabled public Decimal diageoInvestmentEurosValue ;
        @AuraEnabled public String paymentMethodValue ;
        @AuraEnabled public String paymentFrequencyValue ;
        @AuraEnabled public String notesCommentsValue ;
    }
    public class AccountWrapper{
        @AuraEnabled public List<Account> personResponsible{get;set;}
        @AuraEnabled public Account acc{get;set;}
    }
    
    
    public static Boolean areAllValuesSelected(String objectName, String fieldName, Id recordId) {
        // Get the record with the specified Id
        SObject record = Database.query(String.escapeSingleQuotes('SELECT ' + fieldName + ' FROM ' + objectName + ' WHERE Id = :recordId LIMIT 1'));
        
        
        // Check if the record and the field exist
        if (record != null && record.get(fieldName) != null) {
            
            Set<String> allPicklistValues = new Set<String>();
            for (Schema.PicklistEntry picklistEntry : Schema.getGlobalDescribe().get(objectName).getDescribe().fields.getMap().get(fieldName).getDescribe().getPicklistValues()) {
                allPicklistValues.add(picklistEntry.getValue());
            }
            String selectedPicklistValues = (String)record.get(fieldName);
            List<String> selectedValuesList = new List<String>(selectedPicklistValues.split(';'));
            for (String selectedValue : allPicklistValues) {
                if (!selectedValuesList.contains(selectedValue)) {
                    return false;
                }
            }
        }
        return true;
    }
    public static accountWrapper getAccountById(String accId) {
        accountWrapper accWr=new accountWrapper();
        //get account. All we really want is the name, to verify that we have a real account.
        Account act = new Account();
        if(accId != null){
            act = [Select id,Name,operator__r.ECM_Legal_Name__c,Person_Responsible__r.Manager.DelegatedApproverId,ECM_Legal_Name__c,Person_Responsible__c,Operator__r.Person_Responsible__c,Independent_of_Operator__c,
                   Direct_Customer__c,Global_Segment__c,Global_Sub_Segment__c,Local_Segment1__c,Local_Segment2__c,Outlet_Visit_Prioritisation_Grade__c,Outlet_Visit_Prioritisation_Grade__r.Name,Local_Segment1__r.Name,
                   BillingState,SAP_Sold_to__c,VAT_Number__c,New_VAT__c,SAP_Ship_to__c,Sales_Org__c,Person_Responsible__r.ManagerId,Person_Responsible__r.DelegatedApproverId,Hybrid__c,Global_Channel__c,Parent_Outlet__c,
                   Email_for_contracts_payments__c from Account where id=:accId WITH SECURITY_ENFORCED];
        }
        
        accWr.personResponsible = [Select id,Name,ECM_Legal_Name__c,operator__r.ECM_Legal_Name__c,Person_Responsible__c,Person_Responsible__r.ManagerId,Person_Responsible__r.DelegatedApproverId from Account where RecordType.Name='Owner/Operator' AND Person_Responsible__c =:userinfo.getUserId()];
        accWr.acc = act;
        
        return accWr;
    }
*/
}