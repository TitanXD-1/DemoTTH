/*
* @Class Name: EDGE_OperatorKPIAchivementOperations

* @Author              Version       Date           Detail
*  Sandip Ghosh      	V1.0        10/09/2020     [ES20-8498]
*  Anand Uppalapati     V2.0        08/03/2022     [ES20-12266]
*  Joshraj Sen          V3.0        08/07/2023     155189
*/
public class EDGE_OperatorKPIAchivementOperations {
    
    public static List<Account_KPI_Achievement__c> calculateKPIAchivements(Set<Id> operatorIdSet,List<Account> outlets, String countryCode){//Map<Id, Territory__c> territoryMap, Map<Id, Territory_Cycle__c> territoryWithCycleMap,
        
        Map<String, Id> kpiAchivementMap = new Map<String, Id>();
        Map<Id, Integer> operatorWithOutletsNumberMap = new Map<Id, Integer>();
        List<Account_KPI_Achievement__c> kpiAchivementsToUpsert = new List<Account_KPI_Achievement__c>();
        Map<String, List<String>> kpiAchivementFieldsMap = new Map<String, List<String>>();
        Map<String, Market_Cycle__c> marketCycleMap = new Map<String, Market_Cycle__c>();
        Map<Id, Map<String, Decimal>> operatorWithOutletKPIsMap = new Map<Id, Map<String, Decimal>>();
        Map<String, Operator_KPI_Fields_Mapping__mdt> kpiFieldsMap = new Map<String, Operator_KPI_Fields_Mapping__mdt>();
        Map<Id,Account> opIdToOperatorMap = new Map<Id,Account>();
        Map<String,String> kpiTypeToCalcTypeMap = new Map<String,String>();
        
        //Fetching Market Settings for Country
        if(Schema.SObjectType.Market_Setting__c.isAccessible() && Schema.SObjectType.Geography__c.isAccessible() ){
            
            List<Market_Setting__c> marketSettingList = [Select Id, Geography__c,Outlet_Execution_Score__c, Minimum_Activation_Standards__c, Minimum_Product_Assortment__c, Distribution__c,
                                                         Share_Of_Space__c, New_Product_Distribution__c from Market_Setting__c
                                                         WHERE Geography__r.Code__c = :countryCode LIMIT 1];
            
            //Mapping Market Cycle with Country Code
            if(Schema.SObjectType.Market_Cycle__c.isAccessible()){
                for(Market_Cycle__c marketCycle : [Select Id, Geography__r.Code__c, Start_Date__c, End_Date__c FROM Market_Cycle__c WHERE Geography__r.Code__c =:countryCode and Active__c = TRUE]){
                    marketCycleMap.put(marketCycle.Geography__r.Code__c, marketCycle);
                }
            }
            
            //Iterating over Sales Area KPI Fields Mapping
            if(Schema.SObjectType.Operator_KPI_Fields_Mapping__mdt.isAccessible()){//Territory_Target_Fields__c, Territory_Cycle_Target_Field__c,
                for(Operator_KPI_Fields_Mapping__mdt kpiMap : [SELECT MasterLabel, Account_KPI_Field__c, Operation_Type__c, Calculation_Type__c, Relationship__c, Market_Settings_Reference__c, Check_for_Null__c, KPI_Achievement_Type__c, Dependent_Field__c, Fraction_Variant__c, Contains_Operator_KPI_Fields__c,Operator_KPI_Numerator_Field__c,Operator_KPI_Denominator_Field__c,Operator_KPI_Field__c FROM Operator_KPI_Fields_Mapping__mdt WHERE KPI_Achievement_Type__c != null AND Active__c = True]){
                    //Mapping Account KPI fields with KPI Mapping instance
                    kpiFieldsMap.put(kpiMap.Account_KPI_Field__c, kpiMap);
                    
                    //Mapping KPI Achivements Types with Account KPI Fields (1:N Relationship can exist)
                    if(kpiAchivementFieldsMap.containsKey(kpiMap.KPI_Achievement_Type__c)){
                        kpiAchivementFieldsMap.get(kpiMap.KPI_Achievement_Type__c).add(kpiMap.Account_KPI_Field__c);
                    }else{
                        kpiAchivementFieldsMap.put(kpiMap.KPI_Achievement_Type__c, new List<String> { kpiMap.Account_KPI_Field__c } );
                    }           
                }
            }
            //System.debug('outlets = '+ outlets);
            for(Account outlet : outlets){
                Id operatorId = outlet.Operator__c; 
                //Mapping Territory with number of Outlets
                if(operatorWithOutletsNumberMap.containsKey(operatorId)){
                    operatorWithOutletsNumberMap.put(operatorId, operatorWithOutletsNumberMap.get(operatorId) + 1);
                }else{
                    operatorWithOutletsNumberMap.put(operatorId, 1);
                }
                
                //Iterating over field names from Sales Area KPI Fields Mappings Metadata
                for(String fieldName : kpiFieldsMap.keySet()){
                    String calcType = '';
                    Decimal fieldVal = 0.00;
                    Operator_KPI_Fields_Mapping__mdt kpiMapItem = kpiFieldsMap.get(fieldName);
                    
                    //Getting calculation type from Market Settings on Condition
                    if(kpiMapItem.Market_Settings_Reference__c != null){
                        calcType = string.valueOf(marketSettingList[0].get(kpiMapItem.Market_Settings_Reference__c));
                        kpiTypeToCalcTypeMap.put(kpiMapItem.KPI_Achievement_Type__c,calcType);
                    }else{
                        calcType = kpiMapItem.Calculation_Type__c;
                    }

                    //Fetching field value Depends on dependent field and calculation type on Outlet from Mapping
                    if(calcType != 'Calculative'){ // For Calculative type of KPI Achievement
                        if(kpiMapItem.Dependent_Field__c != null){
                            if((Decimal)outlet.get(kpiMapItem.Dependent_Field__c) != null){
                                fieldVal = (Decimal)outlet.get(fieldName);
                            }else{
                                fieldVal = null;
                            }
                        }else{
                            fieldVal = (Decimal)outlet.get(fieldName);
                        }
                    }else{
                        if(marketCycleMap != null && marketCycleMap.size() > 0 && (Date)outlet.get(fieldName) != null && (Date)outlet.get(fieldName) >= marketCycleMap.get(countryCode).Start_Date__c && (Date)outlet.get(fieldName) <= marketCycleMap.get(countryCode).End_Date__c){
                            fieldVal = 1;
                        }
                    }
                    
                    //Mapping Territory with KPI Names and Values depends on Calculation Type
                    if(operatorWithOutletKPIsMap.containsKey(operatorId)){
                        if(operatorWithOutletKPIsMap.get(operatorId).containsKey(fieldName)){
                            operatorWithOutletKPIsMap.get(operatorId).put(fieldName, operatorWithOutletKPIsMap.get(operatorId).get(fieldName) + EDGE_KPIAchivementOperations.checkValue(fieldVal, calcType));
                        }else{
                            operatorWithOutletKPIsMap.get(operatorId).put(fieldName, EDGE_KPIAchivementOperations.checkValue(fieldVal, calcType));
                        }
                    }else{
                        operatorWithOutletKPIsMap.put(operatorId, new Map<String, Decimal> {fieldName => EDGE_KPIAchivementOperations.checkValue(fieldVal, calcType)});
                    }
                }
            }
            
            for(Account_KPI_Achievement__c kpiAchive : [SELECT Id, Account__c, KPI_Type__c FROM Account_KPI_Achievement__c WHERE Account__c IN :operatorIdSet]){ /*AND recordType.developerName = 'Territory_KPI'*/
                kpiAchivementMap.put(kpiAchive.Account__c + '_' + kpiAchive.KPI_Type__c, kpiAchive.Id);
            }
            
            String territoryRecType = KPI_Achivement__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Territory KPI').getRecordTypeId();
            
            //Iterating over Territory Ids and KPI Achievement Types to Create KPI Achivement Records
            for(Id operatorId : operatorWithOutletKPIsMap.keySet()){
                for(String achivementType : kpiAchivementFieldsMap.keySet()){
                    String key = operatorId + '_' + achivementType;
                    Account_KPI_Achievement__c kpiAchive = new Account_KPI_Achievement__c(Id = kpiAchivementMap.containsKey(key) ? kpiAchivementMap.get(key) : null);
                    if(kpiAchive.Id == null){
                        kpiAchive.Account__c = operatorId;
                    }
                    kpiAchive.KPI_Type__c = achivementType;
                    Account operatorRec = null;
                    if(!opIdToOperatorMap.containsKey(operatorId)){
                        operatorRec = new Account(Id=operatorId);
                        opIdToOperatorMap.put(operatorRec.Id,operatorRec);
                    }else{
                        operatorRec = opIdToOperatorMap.get(operatorId);
                    }
                    String numeratorFieldName = '';
                    String denominatorFieldName = '';
                    String kpiFieldName = '';
                    
                    if(kpiAchivementFieldsMap.get(achivementType).size() > 1 && 
                       ((achivementType == 'Distribution' && marketSettingList[0].get('Distribution__c')=='Progressive')
                       || (achivementType != 'Distribution')))        //ES20-12266
                    {// KPI with both Numerator and Denominator like Distribution, Planned Call Compliance
                        for(String fieldName : kpiAchivementFieldsMap.get(achivementType)){
                            Operator_KPI_Fields_Mapping__mdt kpiMapItem = kpiFieldsMap.get(fieldName);
                            //System.debug('@fieldName'+fieldName);
                            kpiAchive.Total_Denominator__c = kpiMapItem.Fraction_Variant__c == 'Denominator' ? operatorWithOutletKPIsMap.get(operatorId).get(fieldName) : kpiAchive.Total_Denominator__c;
                            kpiAchive.Actual_Numerator__c = kpiMapItem.Fraction_Variant__c == 'Numerator' ? operatorWithOutletKPIsMap.get(operatorId).get(fieldName) : kpiAchive.Actual_Numerator__c;
                            
                            if(kpiMapItem.Contains_Operator_KPI_Fields__c != null){
                                numeratorFieldName = kpiMapItem.Operator_KPI_Numerator_Field__c;
                                denominatorFieldName = kpiMapItem.Operator_KPI_Denominator_Field__c;
                                kpiFieldName = kpiMapItem.Operator_KPI_Field__c;
                            }
                        }
                        kpiAchive.Actual__c = kpiAchive.Total_Denominator__c > 0 ? (kpiAchive.Actual_Numerator__c / kpiAchive.Total_Denominator__c) * 100 :0;
                        //System.debug('kpiAchive.Actual__c'+kpiAchive.Actual__c);
                        if(numeratorFieldName != null){
                            operatorRec.put(numeratorFieldName,kpiAchive.Actual_Numerator__c);
                        }
                        if(denominatorFieldName != null){
                            operatorRec.put(denominatorFieldName,kpiAchive.Total_Denominator__c);
                        }
                        if(kpiFieldName != null){
                            operatorRec.put(kpiFieldName,kpiAchive.Actual__c);
                        }
                    }else{// KPI with only one record like MAS, MPA, OES-Binary
                        string fieldName;
                        if(kpiAchivementFieldsMap.get(achivementType).size() > 1 && achivementType=='Distribution'){ //ES20-12266
                            
                            fieldName= EDGE_Constant.Distribution;//kpiAchivementFieldsMap.get(achivementType)[2];
                        }
                        else{
                            fieldName = kpiAchivementFieldsMap.get(achivementType)[0];
                        }
                        Operator_KPI_Fields_Mapping__mdt kpiMapItem = kpiFieldsMap.get(fieldName);
                        String calculationType = kpiTypeToCalcTypeMap.containskey(kpiMapItem.KPI_Achievement_Type__c) ? kpiTypeToCalcTypeMap.get(kpiMapItem.KPI_Achievement_Type__c) : kpiMapItem.Calculation_Type__c;
                        
                        if(kpiMapItem.Operation_Type__c == 'Average'){
                            
                            if(calculationType != 'Binary'){//Average & not Binary like Progressive
                                kpiAchive.Actual__c = (operatorWithOutletKPIsMap.get(operatorId).get(fieldName) / operatorWithOutletsNumberMap.get(operatorId)) * 100;
                            }else{//Average & Binary
                                kpiAchive.Actual__c = (operatorWithOutletKPIsMap.get(operatorId).get(fieldName) / operatorWithOutletsNumberMap.get(operatorId));
                            }
                            kpiAchive.Total_Denominator__c = operatorWithOutletsNumberMap.get(operatorId);
                            kpiAchive.Actual_Numerator__c = operatorWithOutletKPIsMap.get(operatorId).get(fieldName);
                            
                        }else{//Not Average
                            kpiAchive.Actual__c = operatorWithOutletKPIsMap.get(operatorId).get(fieldName);
                            kpiAchive.Total_Denominator__c = operatorWithOutletsNumberMap.get(operatorId);
                            kpiAchive.Actual_Numerator__c = operatorWithOutletKPIsMap.get(operatorId).get(fieldName);
                        }
                        if(kpiMapItem.Contains_Operator_KPI_Fields__c != null && kpiMapItem.Operator_KPI_Field__c != null){
                            operatorRec.put(kpiMapItem.Operator_KPI_Field__c,kpiAchive.Actual__c);
                        }
                        if(kpiMapItem.Contains_Operator_KPI_Fields__c != null){
                            numeratorFieldName = kpiMapItem.Operator_KPI_Numerator_Field__c;
                            denominatorFieldName = kpiMapItem.Operator_KPI_Denominator_Field__c;
                        }
                        if(numeratorFieldName != null){
                            operatorRec.put(numeratorFieldName,kpiAchive.Actual_Numerator__c);
                        }
                        if(denominatorFieldName != null){
                            operatorRec.put(denominatorFieldName,kpiAchive.Total_Denominator__c);
                        }
                    }                    
                    
                    kpiAchivementsToUpsert.add(kpiAchive);
                }
            }
            
        }
        System.debug('opIdToOperatorMap = '+ opIdToOperatorMap);
        if(opIdToOperatorMap.keySet().size() > 0 && Schema.SObjectType.Account.isUpdateable()){
            Database.update(opIdToOperatorMap.values(),false);
        }
        return  kpiAchivementsToUpsert;
    }
}