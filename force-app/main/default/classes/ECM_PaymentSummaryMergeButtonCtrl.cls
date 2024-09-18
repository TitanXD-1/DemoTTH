/*
*@Name: ECM_PaymentSummaryMergeButtonCtrl
*@Description: This is class for fetch required data for components "ECM_PaymentSummaryMergeButton"
*@History                                                                                                                       

VERSION			AUTHOR					DATE				DETAIL
*1.0		Saurav Prasad             29/12/2022         Initial Development for ECM-6595
*1.1		Suvendu Roy               30/12/2022         Merging Payment Summary and Payment Summary Item for selected records
*/
public with sharing class  ECM_PaymentSummaryMergeButtonCtrl {
    
    public class PSMergeWrapper{
        @AuraEnabled public List<ECM_Payment_Summary__c> psList {get;set;}
        @AuraEnabled public ECM_Payment_Summary__c triggeredPsRecord{get;set;}
        @AuraEnabled public List<String> fieldSetMap{get;set;}
        public PSMergeWrapper(){
            this.psList = new List<ECM_Payment_Summary__c>();
            this.triggeredPsRecord = new ECM_Payment_Summary__c();
            this.fieldSetMap = new List<String>();
        }
    }
/** 
* @description	:	ECM-6595 - Fetching Payment summary List for same contact, status open and Volumn-Based Type
* @return		:	PSMergeWrapper
* @param event	:	String, String
**/
    @AuraEnabled
    public static PSMergeWrapper getPaymentSummaryDetails(String paymentSummaryId,String sObjectName){
        //Declaration
        List<Schema.FieldSetMember> fields = Schema.SObjectType.ECM_Payment_Summary__c.fieldSets.ECM_PS_Merge_Fields.getFields();
        List<String> fieldSets = new List<String>();
        ECM_Payment_Summary__c psRec = new ECM_Payment_Summary__c();
        List<ECM_Payment_Summary__c> psRecList = new List<ECM_Payment_Summary__c>();
        ECM_Technical_Market_Setting__mdt technicalMkt ;
        String volumePSOpen = System.Label.ECM_Open_Apex;
        String volumePSType = System.Label.ECM_PSType_VolumeBased;
        PSMergeWrapper psWrap = new PSMergeWrapper();
        String singlePS ='';
        String query;
        String condition = String.isNotBlank(volumePSOpen) && String.isNotBlank(volumePSType)?' WHERE ECM_Payment_Summary_Status__c=:volumePSOpen AND ECM_Type__c=:volumePSType':'';
        String securityEnforced = ' WITH SECURITY_ENFORCED';

        query = fieldSetMapping(query,fields,fieldSets);
        System.debug(LoggingLevel.INFO,'fieldSets @'+fieldSets);
        System.debug(LoggingLevel.INFO,'query @'+query);
        query += ' Id, Name,ECM_Country_Code__c,ECM_Contract__r.OwnerId FROM '+String.escapeSingleQuotes(sObjectName)+' '+condition;
        singlePS +=query+' AND Id=:paymentSummaryId '+securityEnforced;
        System.debug(LoggingLevel.INFO,'singlePS @'+singlePS);
        for(ECM_Payment_Summary__c ps : Database.query(String.escapeSingleQuotes(singlePS))){
            psRec = ps;
        }
        System.debug(LoggingLevel.DEBUG,'psRec @'+psRec);
        System.debug(LoggingLevel.INFO,'psRec ID@'+psRec.Id);
        if(String.isBlank(psRec.Id)){
            return psWrap;
        }
        //Fetch Technical market setttings
        technicalMkt = getTechnicalMarketSetting(psRec);
        System.debug(LoggingLevel.DEBUG,'technicalMkt @'+technicalMkt);
        if(!technicalMkt.ECM_Enable_Volume_Based_PS_Merge__c){
            return null;
        }
        //Adding the PSWrapper Structure
        psWrap.triggeredPsRecord = psRec;
        psWrap.fieldSetMap = fieldSets;
        String conId = psRec.ECM_Contract__c;
        query +=String.isNotBlank(conId)?' AND ECM_Contract__c=:conId '+securityEnforced+' ORDER BY ECM_Start_Period__c ASC':'';
        System.debug(LoggingLevel.INFO,'query @'+query);
        for(ECM_Payment_Summary__c ps:Database.query(String.escapeSingleQuotes(query))){
            psRecList.add(ps);
        }
        psWrap.psList = psRecList;
        return psWrap;
    }
    /** 
    * @description	:	ECM-6595 - Fetching Payment summary List for same contact, status open and Volumn-Based Type
    * @return		:	ECM_Technical_Market_Setting__mdt
    * @param event	:	ECM_Payment_Summary__c
    **/ 
    public static ECM_Technical_Market_Setting__mdt getTechnicalMarketSetting(ECM_Payment_Summary__c psRec){
        for(ECM_Technical_Market_Setting__mdt techMkt : ECM_Technical_Market_Setting__mdt.getAll().values()){
            if(psRec.ECM_Country_Code__c == techMkt.ECM_Country__c){
                return techMkt;
            }
        }
        return null;
    }

    public static String fieldSetMapping(String query, List<Schema.FieldSetMember>fields, List<String> fieldSets){
         query= 'SELECT ';
         //Dynamic Query
        for(Schema.FieldSetMember field : fields) {
            System.debug(LoggingLevel.INFO,'fields name @'+field.getLabel()+'- field API @'+field.getFieldPath());
            query += field.getFieldPath() + ', ';
            if(System.Label.ECM_PS_MergeTable_Headers.contains(field.getLabel())){
                String dataType = string.valueOf(field.getType()).equalsIgnoreCase('PICKLIST')?'text':
                string.valueOf(field.getType()).equalsIgnoreCase('DATE')?'date':string.valueOf(field.getType()).toLowerCase();        
                fieldSets.add(field.getLabel()+'-'+field.getFieldPath()+'-'+dataType);
            }
        }
        return query;
    }
/** 
* @description	:	ECM-6610 - Merging Payment Summary List to a single Payment summary
* @return		:	String
* @param event	:	List<ECM_Payment_Summary__c>
**/
    @AuraEnabled
    public static String mergePaymentSummary (List<ECM_Payment_Summary__c> selectedPSList){
        List <Id> selectedPSIdList = new List<Id>();
        String conId = selectedPSList[0].ECM_Contract__c;
        Date startDate = selectedPSList[0].ECM_Start_Period__c;
        Date endDate = selectedPSList[0].ECM_End_Period__c;
        Decimal totalPS =0;
        Decimal forecastPS=0;
        List<Schema.FieldSetMember> fieldSetPaySum = Schema.SObjectType.ECM_Payment_Summary__c.fieldSets.ECM_PS_Merge_Fields.getFields();
        ECM_Payment_Summary__c newPsRec = new ECM_Payment_Summary__c();
        
        for(ECM_Payment_Summary__c psRec :selectedPSList){
            startDate = (psRec.ECM_Start_Period__c < startDate)?psRec.ECM_Start_Period__c:startDate;
            endDate = (psRec.ECM_End_Period__c > endDate)?psRec.ECM_End_Period__c:endDate;
            totalPS += psRec.ECM_Total_Amount_Confirmed__c!=null?psRec.ECM_Total_Amount_Confirmed__c:0;
            forecastPS += psRec.ECM_Total_Amount_Forecasted__c != null?psRec.ECM_Total_Amount_Forecasted__c:0;
            selectedPSIdList.add(psRec.Id);
        }
        
        
        for(ECM_Payment_Summary__c ps : [SELECT Id FROM ECM_Payment_Summary__c 
                                         WHERE ECM_Parent_Payment_Summary__c=:null 
                                         AND ECM_Type__c=:System.Label.ECM_PSType_VolumeBased 
                                         AND ECM_Contract__c=:conId
                                         AND ECM_Start_Period__c >= :startDate
                                         AND ECM_End_Period__c <= :endDate
                                         AND Id NOT IN :selectedPSIdList WITH SECURITY_ENFORCED]){
                                             return 'isConsecutive';
                                         }
        
        structureNewPS(newPsRec,fieldSetPaySum,selectedPSList[0]);   
        newPsRec.ECM_Start_Period__c = startDate;
        newPsRec.ECM_End_Period__c =  endDate;
        newPsRec.ECM_Total_Amount_Confirmed__c =  totalPS;
        newPsRec.ECM_Total_Amount_Forecasted__c =  forecastPS;
        if(ECM_Payment_Summary__c.SObjectType.getDescribe().isAccessible()){
               insert newPsRec; //Inserting new Payment Summary
               System.debug(LoggingLevel.DEBUG,newPsRec);
           }
        for(ECM_Payment_Summary__c psRec : selectedPSList){ 
            psRec.ECM_Parent_Payment_Summary__c = newPsRec.Id;
            psRec.ECM_Payment_Summary_Status__c = 'Cancelled';
        }
        update selectedPSList;
        mergePaymentSummaryItem(selectedPSIdList,newPsRec);
        return newPsRec.Id;
        
    }
    public static void structureNewPS(ECM_Payment_Summary__c newPsRec,List<Schema.FieldSetMember>fieldSetPaySum,ECM_Payment_Summary__c singlePaySum){
        for(Schema.FieldSetMember field : fieldSetPaySum) {
            if(!System.Label.ECM_PS_Adding_Fields_To_Merge.containsIgnoreCase(field.getFieldPath())){
                newPsRec.put(field.getFieldPath(),singlePaySum.get(field.getFieldPath()));
            }
        }
    }
    
/** 
* @description	:	ECM-6610 - Merging Payment Summary Item List to a single Payment Summary Item
* @return		:	Void
* @param event	:	List<Id>,ECM_Payment_Summary__c
**/
    public static void mergePaymentSummaryItem (List<Id> selectedPSIdList, ECM_Payment_Summary__c newPsRec){
        List<Schema.FieldSetMember> fieldSetPaySumItem = Schema.SObjectType.ECM_Payment_Summary_Item__c.fieldSets.ECM_PSI_Merge_Fields.getFields();
        List<String> fieldListPSI = new List<String>();
        Map<Id,ECM_Payment_Summary_Item__c> conItemMap = new Map<Id,ECM_Payment_Summary_Item__c>();
        String queryPSI = 'SELECT ';
        for(Schema.FieldSetMember field : fieldSetPaySumItem) {
            queryPSI += field.getFieldPath() + ', ';
            fieldListPSI.add(field.getFieldPath());
        }
        queryPSI +='Id FROM ECM_Payment_Summary_Item__c WHERE ECM_Payment_Summary__c IN :selectedPSIdList ORDER BY ECM_Payment_Summary__c'; 
        
        for(ECM_Payment_Summary_Item__c psItem : Database.query(String.escapeSingleQuotes(queryPSI))){
            if(!conItemMap.containsKey(psItem.ECM_Contract_Item__c) && String.isNotBlank(psItem.ECM_Contract_Item__c)){
                ECM_Payment_Summary_Item__c newPSItem = new ECM_Payment_Summary_Item__c();
                newPSItem.ECM_Payment_Summary__c = newPsRec.Id;
                for(String field : fieldListPSI){
                    newPSItem.put(field, psItem.get(field));
                }
                conItemMap.put(psItem.ECM_Contract_Item__c,newPSItem);
            }else{
                ECM_Payment_Summary_Item__c oldPSItem = conItemMap.get(psItem.ECM_Contract_Item__c);
                for(String field : fieldListPSI){
                    if(System.Label.ECM_PSI_Adding_Fields_To_Merge.containsIgnoreCase(field) &&
                       psItem.get(field) != null){
                           Decimal tempVal = 0;
                           tempVal  = oldPSItem.get(field) != null?
                               Decimal.valueOf(String.valueOf(psItem.get(field))) + Decimal.valueOf(String.valueOf(oldPSItem.get(field))) :
                           Decimal.valueOf(String.valueOf(psItem.get(field)));
                           oldPSItem.put(field, tempVal);
                       }
                }
                conItemMap.put(psItem.ECM_Contract_Item__c,oldPSItem);
            }
        }
        
        if(!conItemMap.values().isEmpty()){
            insert conItemMap.values(); //Inserting new Payment Summary Items
        }
    }
}