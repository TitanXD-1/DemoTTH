public class ECM_FileUploaderCSVController {
    @AuraEnabled
    public static string processData(String fileData,String sobjectName,List<String> selectfields) {
        
        System.debug('fileData:::'+filedata);
        System.debug('sobjectName:::'+sobjectName);
        System.debug('fields:::'+selectfields);
        Map<string, ECM_Payment_Summary__c> paymentNamelist = processDataPaymentSummery(fileData,selectfields);
        system.debug('paymentNamelist==='+paymentNamelist);
        if(paymentNamelist==Null){
            return 'FAILURE';
        }
        Schema.SObjectType Paymentobj = Schema.getGlobalDescribe().get('ECM_Payment_Summary__c');
        try{
            Map <String, String> labelToAPIName = new Map <String, String> ();            
            Map<String, Schema.SObjectField> fieldsMap = Paymentobj.getDescribe().fields.getMap();
            for (Schema.SObjectField field : fieldsMap.values())
            {
                //system.debug('obj field =='+field.getDescribe().getLabel());
                if(selectfields.contains(field.getDescribe().getLabel())){                   
                    labelToAPIName.put(field.getDescribe().getLabel(), field.getDescribe().getName());
                    String APINAME = labelToAPIName.get(field.getDescribe().getLabel());
                    System.debug('*** fieldTypeName = ' + APINAME); 
                }
            }
           // Map<String, Schema.SObjectType> schemaMap = Schema.getGlobalDescribe();
            //Schema.SObjectType Paymentobj = schemaMap.get('ECM_Payment_Summary__c');
            Map<String, Schema.SObjectField> fieldMap = Paymentobj.getDescribe().fields.getMap();
            
            if(fileData!=null){ 
                String[] fileLines = new String[]{};
                    fileLines = fileData.split('\n');
                
                //for content
                List<sObject> myList = new List<sObject>();
                for (Integer i=1,j=fileLines.size();i<j;i++){
                    String[] inputvalues = new String[]{};
                        inputvalues = fileLines[i].split(',');
                    sObject obj = Paymentobj.newSObject();
                    system.debug('=header'+inputvalues.size());
                    integer rowsize=inputvalues.size();
                    
                    for(integer l=0;l<rowsize;l++){
                        system.debug(selectfields+'fields.get(l)'+selectfields.get(l));
                        
                        if(String.isNotBlank(inputvalues[l]))
                        {
                            String value= inputvalues[l].length()>255 ? inputvalues[l].substring(0,254) : inputvalues[l];
                            system.debug('value'+ value);
                            system.debug('selectfields.get(l)=='+selectfields.get(l));
                            if(fieldMap.get(labelToAPIName.get(selectfields.get(l))).getDescribe().isAutoNumber()){
                                obj.put('Id',string.valueof(paymentNamelist.get(value).Id));       
                                
                            }else{
                                Schema.DisplayType fielddataType = fieldMap.get(labelToAPIName.get(selectfields.get(l))).getDescribe().getType();
                                if(fielddataType == Schema.DisplayType.String || fielddataType == Schema.DisplayType.PICKLIST) {
                                    obj.put(labelToAPIName.get(selectfields.get(l)),value);       
                                    system.debug('type='+fielddataType);
                                }
                                if(fielddataType == Schema.DisplayType.ID) {
                                    obj.put(labelToAPIName.get(selectfields.get(l)),value);       
                                    system.debug('type='+fielddataType);
                                }
                                
                                if(fielddataType == Schema.DisplayType.Integer) {
                                    obj.put(labelToAPIName.get(selectfields.get(l)),integer.valueof(value));
                                    system.debug('type='+fielddataType);
                                }
                                
                                if(fielddataType == Schema.DisplayType.Date) {
                                    system.debug('string ='+value);
                                    date dt = Date.parse(value.trim());
                                    system.debug('date ='+dt);                                
                                    obj.put(labelToAPIName.get(selectfields.get(l)), (Date)dt/*Date.valueOf(dtstr)*/);      
                                }
                                if(fielddataType == Schema.DisplayType.DateTime) {
                                    date dt = Date.parse(value);
                                    Datetime todayDateTime = dt;
                                    string dtstr = todayDateTime.format('YYYY-MM-DD');
                                    system.debug('date=='+dtstr);
                                    obj.put(labelToAPIName.get(selectfields.get(l)), Date.valueOf(dtstr));       
                                }if(fielddataType == Schema.DisplayType.Currency ||
                                    fielddataType == Schema.DisplayType.Double){
                                        obj.put(labelToAPIName.get(selectfields.get(l)), Decimal.valueOf(value));
                                    }
                                system.debug('==='+obj);
                            }
                        }else{
                            obj.put(labelToAPIName.get(selectfields.get(l)),Null);
                        }
                    }
                    myList.add(obj);                    
                }
                system.debug('insert=='+myList);
                ECM_FileUploaderCSVBatch csvBT = new ECM_FileUploaderCSVBatch(myList);
                Id batchId = Database.executeBatch(csvBT, 1000);
                
            }
            return 'SUCCESS';
        }catch(Exception e){
            System.debug('exception'+e);              
            return 'FAILURE';
        }
        
    }
    @AuraEnabled
    public static Map<string,ECM_Payment_Summary__c> processDataPaymentSummery(String fileData,List<String> selectfields) {
        List<String> paymentNamelist = new List<String>(); 
        Schema.SObjectType targetType = Schema.getGlobalDescribe().get('ECM_Payment_Summary__c');
        try{
            Map <String, String> labelToAPIName = new Map <String, String> ();            
            Map<String, Schema.SObjectField> fieldsMap = targetType.getDescribe().fields.getMap();
            Map<String, Schema.SObjectField> fieldMap = targetType.getDescribe().fields.getMap();
            for (Schema.SObjectField field : fieldsMap.values())
            {
                if(selectfields.contains(field.getDescribe().getLabel())){                   
                    labelToAPIName.put(field.getDescribe().getLabel(), field.getDescribe().getName());
                    String APINAME = labelToAPIName.get(field.getDescribe().getLabel());
                    System.debug('*** fieldTypeName = ' + APINAME); 
                }
            }
            
            if(fileData!=null){ 
                String[] fileLines = new String[]{};
                    fileLines = fileData.split('\n');                
                //for content
                for (Integer i=1,j=fileLines.size();i<j;i++){
                    String[] inputvalues = new String[]{};
                        inputvalues = fileLines[i].split(',');
                    sObject obj = targetType.newSObject();
                    system.debug('=header'+inputvalues.size());
                    integer rowsize=inputvalues.size();
                    
                    for(integer l=0;l<rowsize;l++){
                        system.debug(selectfields+'fields.get(l)'+selectfields.get(l));
                        
                        if(String.isNotBlank(inputvalues[l]))
                        {
                            String value= inputvalues[l].length()>255 ? inputvalues[l].substring(0,254) : inputvalues[l];
                            system.debug('value'+ value);
                            system.debug('selectfields.get(l)=='+selectfields.get(l));
                            if(fieldMap.get(labelToAPIName.get(selectfields.get(l))).getDescribe().isAutoNumber()){
                                if(selectfields.get(l) == 'Payment Summary Name'){
                                    paymentNamelist.add(value);  
                                }
                            }
                        }                        
                    }                   
                    
                }
                system.debug('insert=='+paymentNamelist);                
            }
            Map<string, ECM_Payment_Summary__c> mapPaymentSumDetails = new  Map<string, ECM_Payment_Summary__c>();
            for(ECM_Payment_Summary__c paysumrec: [select Id,Name from ECM_Payment_Summary__c where Name IN:paymentNamelist]){
                mapPaymentSumDetails.put(paysumrec.Name, paysumrec);
            }
            return mapPaymentSumDetails;
        }catch(Exception e){
            System.debug('exception'+e);               
            return Null;
        }
        
    }
    @AuraEnabled
    public static List<string> getselectOptions() {
        list<string> ObjStr = new list<string>();
        list<string> ObjOpt = new list<string>();
        Map<String, Schema.SObjectType> ObjNames = new Map<String, Schema.SObjectType>();
        ObjNames = Schema.getGlobalDescribe();
        ObjStr = new list<string>();
        ObjStr.addAll(ObjNames.keyset());
        ObjStr.sort();
        ObjOpt = new list<string>();
        // ObjOpt.add('--NONE--');
        for(string s:ObjStr){
            ObjOpt.add(s);   
        }      
        return ObjOpt;
    }
    
}