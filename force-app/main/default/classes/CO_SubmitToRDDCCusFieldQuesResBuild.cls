/*
@Name: CO_SubmitToRDDCCusFieldQuesResBuild

@Purpose: This class is used to build custom field and questionnaire response to send it to RDDC

@History                                                                                                           
VERSION    AUTHOR            DATE              DETAIL
1.0		   Jayashree R       8-2-2023        Initial Development
*/
public class CO_SubmitToRDDCCusFieldQuesResBuild {
    public static CO_RDDCWrapper.CustomFieldsWrapper generateCustomFieldObj(sObject crObj,CO_RDDC_Custom_Fields_Mapping__mdt rddcCustomField){
        CO_RDDCWrapper.CustomFieldsWrapper cusFieldObj;
        String fValue = (String)fetchFieldValue(crObj, rddcCustomField.API_Name__c);
        if(fValue != null){
            if(rddcCustomField.Field_Type__c != null &&  rddcCustomField.Field_Type__c == 'Text'){
                cusFieldObj = new CO_RDDCWrapper.CustomFieldsWrapper();
                cusFieldObj.value = fValue;
                cusFieldObj.name = rddcCustomField.Name__c;
            }else if(rddcCustomField.Field_Type__c != null &&  rddcCustomField.Field_Type__c == 'Picklist'){
                cusFieldObj = new CO_RDDCWrapper.CustomFieldsWrapper();
                cusFieldObj.value = new String[]{fValue};
                    cusFieldObj.name = rddcCustomField.Name__c;
                
            }else if(rddcCustomField.Field_Type__c != null &&  rddcCustomField.Field_Type__c == 'Multi Picklist'){
                cusFieldObj = new CO_RDDCWrapper.CustomFieldsWrapper();
                String[] plValues = fValue.split(';');
                cusFieldObj.value = plValues;
                cusFieldObj.name = rddcCustomField.Name__c;
            }
            
        }
        return cusFieldObj;
    }
    
    public static Map<String, List<RDDCOptionValue>> getOptionValueMappings(){
        List<CO_RDDC_Option_Value_Mapping__mdt> optionValueMappings =  CO_RDDC_Option_Value_Mapping__mdt.getAll().values();
        Map<String, List<RDDCOptionValue>> quesOptValMap = new Map<String, List<RDDCOptionValue>>();
        for(CO_RDDC_Option_Value_Mapping__mdt optVal : optionValueMappings){
            if(quesOptValMap.containsKey(optVal.Question_Id__c.trim())){
                List<RDDCOptionValue> optionValueList = quesOptValMap.get(optVal.Question_Id__c.trim());
                RDDCOptionValue optValObj = new RDDCOptionValue();
                optValObj.optionId = optVal.Option_Id__c.trim();
                optValObj.value = optVal.Value__c.trim();
                optionValueList.add(optValObj);
                quesOptValMap.put(optVal.Question_Id__c.trim(), optionValueList);
            }else{
                RDDCOptionValue optValObj = new RDDCOptionValue();
                optValObj.optionId = optVal.Option_Id__c.trim();
                optValObj.value = optVal.Value__c.trim();
                quesOptValMap.put(optVal.Question_Id__c.trim(), new List<RDDCOptionValue>{optValObj});
            }
            
        } 
        return quesOptValMap;
    }
    
    public static CO_RDDCWrapper.QuestionWrapper generateQuestionObj(sObject crObj,CO_RDCC_Questionnaire_Response_Mapping__mdt rddcQuesRes, List<RDDCOptionValue> quesOptValMap){
        CO_RDDCWrapper.QuestionWrapper rddcQuesObj;   
        String fValue = (String)fetchFieldValue(crObj, rddcQuesRes.API_Name__c);
        if(fValue != null && rddcQuesRes.Field_Type__c == 'Text'){
            rddcQuesObj = new CO_RDDCWrapper.QuestionWrapper();
            rddcQuesObj.questionId = rddcQuesRes.DeveloperName;
            rddcQuesObj.answers = fValue; 
        }else if(fValue != null &&  (rddcQuesRes.Field_Type__c == 'Picklist' || rddcQuesRes.Field_Type__c == 'Multi Picklist') ){
            rddcQuesObj = new CO_RDDCWrapper.QuestionWrapper();
            rddcQuesObj.questionId = rddcQuesRes.DeveloperName;
            rddcQuesObj.answers = getPLOptionIds(fValue,quesOptValMap);
        } 
        return rddcQuesObj;
    }
    
    
    public static List<String> getPLOptionIds(String fValue,List<RDDCOptionValue> quesOptValMap){
        List<String> optionIds = new List<String>();
        if(quesOptValMap != null){
            for(String plVal : fValue.split(';')){
                for(RDDCOptionValue optVal : quesOptValMap){
                    if(optVal.value == plVal){
                        optionIds.add(optVal.OptionId);
                        break;
                    }
                }
            }
        }
        return optionIds;
    }
    
    public static Object fetchFieldValue(sObject crObj, String apiName){
        Object fieldValue;
        if(!apiName.contains('.') && crObj.get(apiName) != null){
            fieldValue = crObj.get(apiName);
        }else{
            List<String> referenceFields = apiName.split('\\.');
            sObject obj = crObj;
            integer i = 0;
            while(i <= referenceFields.size() - 1 ){
                String refField = referenceFields[i];
                if(i <= referenceFields.size() - 2 ){
                    obj = obj.getSobject(refField);
                }else{
                    if(obj.get(refField) != null){
                        fieldValue = obj.get(refField);
                    }
                } 
                i++;
            }
        }
        return fieldValue;
    }
    
    
    public class RDDCOptionValue{
        public String optionId;
        public String value;
    }
    
}