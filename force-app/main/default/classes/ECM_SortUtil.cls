/*
@Name: ECM_SortUtil
@Description: This Class is used for sorting records based on field name with ASCENDING or DESCENDING Order
@History                                                            

*VERSION		AUTHOR					DATE				DETAIL
*1.0		Saurav Prasad			18/10/2023			126383  : [ECM-6905] Product Order on PDF Output 
*/
public class ECM_SortUtil implements Comparable {
    
    public enum SortOrder { ASCENDING, DESCENDING }
    public enum Type { TYPE_STRING, TYPE_INTEGER, TYPE_DECIMAL, TYPE_INVALID }
    
    sObject record;
    SortOrder sortOrderValue;
    String fieldName;
    Type valueType;
    
    public ECM_SortUtil(SortOrderWrap singleWrap, SortOrder sortOrderValue, Type valueType) {
        this.record = singleWrap.record;
        this.sortOrderValue = sortOrderValue;
        this.fieldName = singleWrap.fieldName;
        this.valueType = valueType;
    }
    
    public Integer compareTo(Object anotherObject) {
        sObject anotherRecord = ((ECM_SortUtil) anotherObject).record;
        if(valueType.equals(Type.TYPE_STRING)) {
            return compareStrings(String.valueOf(record.get(fieldName)), String.valueOf(anotherRecord.get(fieldName)));
        } else if(valueType.equals(Type.TYPE_INTEGER)) {
            return compareIntegers(Integer.valueOf(record.get(fieldName)), Integer.valueOf(anotherRecord.get(fieldName)));
        } else if(valueType.equals(Type.TYPE_DECIMAL)) {
            return compareDecimals(Decimal.valueOf(String.valueOf(record.get(fieldName))), Decimal.valueOf(String.valueOf(anotherRecord.get(fieldName))));
        }
        return -1;
    }
    
    public Integer compareStrings(String sourceValue, String destinationValue) {
        if(sortOrderValue.equals(SortOrder.ASCENDING)) {
            if(sourceValue < destinationValue) {
                return -1;
            } else if(sourceValue.equals(destinationValue)) {
                return 0;
            } else {
                return 1;
            }
        } else {
            if(sourceValue < destinationValue) {
                return 1;
            } else if(sourceValue.equals(destinationValue)) {
                return 0;
            } else {
                return -1;
            }
        }
    }
    
    
    public Integer compareIntegers(Integer sourceValue, Integer destinationValue) {
        if(sortOrderValue.equals(SortOrder.ASCENDING)) {
            if(sourceValue < destinationValue) {
                return -1;
            } else if(sourceValue == destinationValue) {
                return 0;
            } else {
                return 1;
            }
        } else {
            if(sourceValue < destinationValue) {
                return 1;
            } else if(sourceValue == destinationValue) {
                return 0;
            } else {
                return -1;
            }
        }
    }
    
    public Integer compareDecimals(Decimal sourceValue, Decimal destinationValue) {
        if(sortOrderValue.equals(SortOrder.ASCENDING)) {
            if(sourceValue < destinationValue) {
                return -1;
            } else if(sourceValue == destinationValue) {
                return 0;
            } else {
                return 1;
            }
        } else {
            if(sourceValue < destinationValue) {
                return 1;
            } else if(sourceValue == destinationValue) {
                return 0;
            } else {
                return -1;
            }
        }
    }
    
    public static void sortRecords(SortOrderWrap mainWrap, SortOrder sortOrderValue, Type valueType) {
        List<ECM_SortUtil> sortUtils = new List<ECM_SortUtil>();
        List<sObject> records = new List<sObject>();
        for(sObject record : mainWrap.records ) {
            SortOrderWrap loopWrap = new SortOrderWrap();
            loopWrap.record = record;
            loopWrap.fieldName = mainWrap.fieldName;
            sortUtils.add(new ECM_SortUtil(loopWrap, sortOrderValue, valueType));
        }
        sortUtils.sort();
        mainWrap.records.clear();
        for(ECM_SortUtil sortUtil : sortUtils) {
            records.add(sortUtil.record);
        }
        mainWrap.records = records;
    }

    public class SortOrderWrap {
        public List<sObject> records;
        public String fieldName;
        public sObject record;

        public sortOrderWrap(){
            this.records = new List<sObject>();
            this.fieldName = '';
        }
    }
}