global class MD_SchemaUtil {

    /**
     * Gets the objects fields by name for the given object type 
     * If the object does not exist returns null
     **/
    global static Map<String, Schema.SobjectField> getObjectFields(Schema.DescribeSObjectResult objectType) {
        Map<String, Schema.SobjectField> objectFields = objectType.fields.getMap();
        List<Account> accs = new List<Account>();
        return objectFields;

    }

    /**
     * Gets a object descirbe by its name
     * If the object associated for the given name does not exists return null
     **/
    global static Schema.DescribeSObjectResult getObjectDescribeByName(String objectName) {
        Schema.SObjectType objectType = Schema.getGlobalDescribe().get(objectName);
        System.debug('objectType: ' + objectType);

        if (objectType == null) {
            return null;
        }
        Schema.DescribeSObjectResult objectDescribe = objectType.getDescribe();
        return objectDescribe;
    }

    /**
     * Gets an object field by object name and field name
     * @param objectName
     * @param fieldName
     * @return field or null if does not exist
     */
    global static Schema.SObjectField getObjectField(String objectName, String fieldName) {
        Schema.DescribeSObjectResult objectDescribe = getObjectDescribeByName(objectName);
        if (objectDescribe == null) {
            return null;
        }
        Map<String, Schema.SobjectField> objectFields = getObjectFields(objectDescribe);
        if (objectFields == null) {
            return null;
        }
        Schema.SObjectField objectField = objectFields.get(fieldName);
        return objectField;
    }

    global static List<SelectOption> getOperatorsForField(Schema.SobjectField field) {
        System.debug('in SchemaUtils.getOperatorsForField()');
        
        System.debug('field: ' + field);
        
        Schema.DescribeFieldResult describeField = field.getDescribe();
        
        System.debug('describeField: ' + describeField);
        
        Schema.DisplayType fieldType = describeField.getType();
        
        System.debug('fieldType: ' + fieldType);
        
        return getOperatorsForFieldType(fieldType);
    }

    global static List<SelectOption> getOperatorsForFieldType(Schema.DisplayType fieldType) {
        Map<String, SelectOption> operatorsMap = new Map<String, SelectOption>();
		/* MIGRATION - Commented
        for (Schema.PicklistEntry operatorsPickListValue : CP_Criteria__c.Operator__C.getDescribe().getPicklistValues()) {
            operatorsMap.put(operatorsPickListValue.getValue(), new SelectOption(operatorsPickListValue.getValue(), operatorsPickListValue.getLabel()));
        }
		   MIGRATION - Commented */
        List<SelectOption> result = new List<SelectOption>();
        if (fieldType == DisplayType.DATE || fieldType == DisplayType.DATETIME || fieldType == DisplayType.INTEGER  || fieldType == DisplayType.DOUBLE
            || fieldType == DisplayType.CURRENCY) {
            result.add(operatorsMap.get('='));
            result.add(operatorsMap.get('>'));
            result.add(operatorsMap.get('<'));
            result.add(operatorsMap.get('<='));
            result.add(operatorsMap.get('>='));
            result.add(operatorsMap.get('!='));
        } else if (fieldType == DisplayType.PICKLIST) {
            result.add(operatorsMap.get('='));
            result.add(operatorsMap.get('!='));
        } else if (fieldType == DisplayType.BOOLEAN) {
            result.add(operatorsMap.get('='));
        } else if (fieldType == DisplayType.MULTIPICKLIST) {
            result.add(operatorsMap.get('Contains'));
        } else {
            result.add(operatorsMap.get('='));
            result.add(operatorsMap.get('Contains'));
            result.add(operatorsMap.get('Starts with'));
        }
        return result;
    }

}