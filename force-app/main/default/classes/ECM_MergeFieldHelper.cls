/*
* @Name: ECM_MergeFieldHelper
* @description: This is Class to fetch the data for the text which contains Merge Field
* @History   

VERSION    AUTHOR                   DATE              DETAIL
1.0      Pradeep Kumar Reddy       28/04/2020        Initial Development
1.1      Veerendra Billakurthi     12/11/2021        Fix for ECM-4976 - Added RoundingMode function to decimal values
1.2      Veerendra Billakurthi     22/03/2022        Commented ECM-4976 related code for ECM-5386
1.3		 Saurav Prasad			   10/11/2022		 ECM-6306 : PF translation in Contract PDF
1.4		 Saurav Prasad			   05/12/2022		 ECM-6339 : Amounts in PDF to be in currency standard
1.5		 Tanishq/Pratik Somani	   19/12/2022		 ECM-6338 : Additional Clause, Distributor fields to be blank on Contract PDF
*/ 
public with sharing class ECM_MergeFieldHelper {
    public static String getMergeText(String messageBody, Map<String,List<SObject>> objectRecordsMap, String dateFormat, String contractCountry,map<String,ECM_GAS_Market_Translation__mdt> metaDataRecords,map<String,String> objFieldMap,String languageForGAS,map<String,List<String>> fieldSetMap){
        //Added as part of ECM-5386->Start
        boolean rounding = false;
        //
        if(Test.isRunningTest())
        {
            rounding = true;
        }
        else
        {
            //user us = [SELECT Id,Available_Countries__c FROM User where id=:userinfo.getUserId() ];
            List<Market_Setting__c> marketObjsLst= [SELECT Id, Name__c,Geography__r.Code__c,ECM_Rounding_Off_Decimals_in_PDF__c FROM Market_Setting__c where Geography__r.Code__c =:contractCountry and ECM_Contract_Management_Market__c=true and (ECM_Contract_Creation_Page__c !=''or ECM_Contract_Creation_Page__c != null) limit 1];
            if(!marketObjsLst.isEmpty()){
        		rounding= marketObjsLst[0].ECM_Rounding_Off_Decimals_in_PDF__c;
        }
        }

        //Added as part of ECM-5386->end
        String body = '';
        if(messageBody != null){
            Integer curPos = 0;
            Pattern mergeField = Pattern.compile('\\{![a-zA-Z0-9_\\.]*\\}');
            //System.debug('mergeField @'+mergeField);
            Matcher m = mergeField.matcher(messageBody);
            //System.debug('Matcher m @'+m);
            while(m.find()){
                body += messageBody.substring(curPos, m.start());
                //System.debug('body @'+body);
                String fieldName = messageBody.substring(m.start()+2,m.end()-1);
                //System.debug('fieldName @'+fieldName);
                String[] relations = fieldName.split('\\.');   
                //System.debug('relations @'+relations);
                try {
                    list<SObject> tmpList = objectRecordsMap.get(relations[0]);
                    String fieldData = '';
                    if(tmpList!=Null && tmpList.Size()>0){
                        for(SObject tmp : tmpList){
                            /*System.debug('tmp @'+tmp);
                            System.debug('getFormat @'+getDateFormat(relations[0],relations[1]));
                            System.debug('data @'+tmp.get(relations[1]));*/
                            if(getDateFormat(relations[0],relations[1]) == 'date'){
                                date dte = date.valueof(tmp.get(relations[1]));
                                DateTime dt = DateTime.newInstance(dte.year(), dte.month(),dte.day());
                                if(dateFormat == null){
                                    fieldData += dt.format('dd/MM/yyyy')+',';
                                }
                                else{
                                    fieldData += dt.format(dateFormat)+',';
                                }   
                            }
                            else if(getDateFormat(relations[0],relations[1]) == 'datetime'){
                                datetime dt = datetime.valueof(tmp.get(relations[1]));    
                                if(dateFormat == null){
                                    fieldData += dt.format('dd/MM/yyyy')+',';
                                }
                                else{
                                    fieldData += dt.format(dateFormat)+',';
                                }   
                            }
                            //added as part of ECM-4976,ECM-5386
                            else if((getDateFormat(relations[0],relations[1]) =='DOUBLE') && (rounding)){
                                Decimal dec = (Decimal)tmp.get(relations[1]);
                                //fieldData += dec==null?dec+',':gasMarketFieldFormatting(relations,contractCountry)?dec.setScale(2,RoundingMode.HALF_UP).format()+',':dec.setScale(0,RoundingMode.HALF_UP)+','; 
                                //ECM-6338 Replace null with blank
                                fieldData += dec==null?''+',':gasMarketFieldFormatting(relations,contractCountry,fieldSetMap)?dec.setScale(2,RoundingMode.HALF_UP).format()+',':dec.setScale(0,RoundingMode.HALF_UP)+','; 
                            }
                            else if((getDateFormat(relations[0],relations[1]) =='TotalGP')&& (rounding)){
                                string myInt = string.valueOf(tmp.get(relations[1]));
                                Decimal strToDec = decimal.valueOf(myInt);
                                //fieldData += strToDec.setScale(0,RoundingMode.HALF_UP)+',';
                                fieldData += strToDec==null?'':strToDec.setScale(0,RoundingMode.HALF_UP)+','; //ECM-6338 Replace null with blank 
                            }
                            //End of ECM-4976,ECM-5386
                            else{
                                //ECM-6306
                                fieldData += gasMarketTranslation(objFieldMap, metaDataRecords, relations, tmp, contractCountry, languageForGAS,fieldSetMap)+',';
                            }
                        }  
                    }
                  
                    body += fieldData.removeEnd(',');
                } catch(Exception ex){
                    system.debug(ex);
                    system.debug('Line Number @'+ex.getLineNumber());
                    //body += '[Invalid merge field: ' + m.group() + ']';
                    body += '';
                }
                curPos = m.end();
            }
            body += messageBody.substring(curPos);
        }
        return body;
    }
    public static String getDateFormat(String objectName, String fieldName){
        String datatype = '';
        SObjectType obj = ((SObject)(Type.forName('Schema.'+objectName).newInstance())).getSObjectType();
        DescribeSObjectResult descResult = obj.getDescribe();        
        if(descResult.fields.getMap().get(fieldName).getDescribe().getType() == Schema.DisplayType.DATE){
            datatype = 'date';
        }
        if(descResult.fields.getMap().get(fieldName).getDescribe().getType() == Schema.DisplayType.DATETIME){
            datatype = 'datetime';
        }if(descResult.fields.getMap().get(fieldName).getDescribe().getType() == Schema.DisplayType.Double
            ||descResult.fields.getMap().get(fieldName).getDescribe().getType() == Schema.DisplayType.CURRENCY
           ||descResult.fields.getMap().get(fieldName).getDescribe().getType() == Schema.DisplayType.Percent){
            datatype = 'DOUBLE';
        }
        if (descResult.fields.getMap().get(fieldName).getDescribe().getLabel() == 'Total GP'){
            datatype = 'TotalGP';
            
            
        }
        return datatype;
    }
    /*
     * @JIRA Story	: ECM-6339 : Amounts in PDF to be in currency standard
     * @Author		: Saurav Prasad
     * @description	: validates if field need currency formatting
     * @return		: Boolean
     * @param		: String [], String
     */ 
    public static Boolean gasMarketFieldFormatting(String[] relations,String contractCountry,map<String,List<String>> fieldSetMap){
        Boolean isGAS =System.Label.ECM_GAS_Market_CountryCodes.contains(contractCountry);
        String objectName =relations[0];
        String fieldName=relations[1];
        String fieldSetName ='';
        /*System.debug('fieldName in Format @'+fieldName);
        System.debug('objectName in Format @'+objectName);*/
        if(isGAS){
            //ECM-6718
            if(fieldSetMap.containsKey(objectName) && fieldSetMap.get(objectName).contains(fieldName)){
                 return true;
            }
            /*Map<String, Schema.SObjectType> GlobalDescribeMap = Schema.getGlobalDescribe(); 
            Schema.SObjectType SObjectTypeObj = GlobalDescribeMap.get(objectName);
            Schema.DescribeSObjectResult DescribeSObjectResultObj = SObjectTypeObj.getDescribe();
            for(ECM_Contract_PDF_Formatting_Setting__mdt mdtRec:
                ECM_Contract_PDF_Formatting_Setting__mdt.getAll().values()){
                    if(mdtRec.ECM_IsActive__c &&
                       objectName == mdtRec.ECM_Object_Api_Name__c && 
                       mdtRec.ECM_Country_Code__c.split(',').contains(contractCountry)){
                           fieldSetName =mdtRec.Field_Set_Api_Name__c;
                           break;
                       }
                }
            System.debug('fieldSetName @ '+fieldSetName);*/
           /* if(String.isNotBlank(fieldSetName)){
                Schema.FieldSet fieldSetObj = DescribeSObjectResultObj.FieldSets.getMap().get(fieldSetName);
                for(Schema.FieldSetMember field : fieldSetObj.getFields()){
                    System.debug('fieldName @'+fieldName);
                    System.debug('field.getFieldPath() @'+field.getFieldPath());
                    System.debug('condition FieldSet @'+(fieldName == field.getFieldPath()));
                    if(fieldName == field.getFieldPath()){
                        System.debug('returning true');
                        return true;
                    } 
                }
                return false;
            }
            return false;*/
        }
        return false;
    }
    /*
     * @JIRA Story	: ECM-6306 : PF translation in Contract PDF
     * @Author		: Saurav Prasad
     * @description	: returns translation value for Payment frequency - type for GAS market - Translation added German, French & Italian
     * @return		: String
     * @param		: Map<String,String>, Map<String,ECM_GAS_Market_Translation__mdt>, String[], SObject, String, String
     */ 
    public static String gasMarketTranslation(Map<String,String> objFieldMap,Map<String,ECM_GAS_Market_Translation__mdt>metaDataRecords,String[] relations,SObject tmp,String contractCountry,String languageForGAS,map<String,List<String>> fieldSetMap){
        Boolean isGAS =System.Label.ECM_GAS_Market_CountryCodes.contains(contractCountry);
        Boolean hasTranslation = false;
        Boolean hasMultiPFTypes = false;
        //ECM-6339
        Boolean isformattingrequired = gasMarketFieldFormatting(relations,contractCountry,fieldSetMap);
        //contains parent field instance
        Decimal parentFieldFormat = isformattingrequired && relations[1].contains('__r') &&
            String.valueOf(tmp.getSobject(relations[1].substringbefore('.')).get(relations[1].substringAfter('.'))) !=null? 
            Decimal.valueOf(String.valueOf(tmp.getSobject(relations[1].substringbefore('.')).get(relations[1].substringAfter('.')))):null;
        //contains field instance
        Decimal fieldFormat = isformattingrequired && !relations[1].contains('__r') && String.valueOf(tmp.get(relations[1]))!=null?
            Decimal.valueOf(String.valueOf(tmp.get(relations[1]))):null;
        Decimal formattedToCurrencyStandard = parentFieldFormat!=null?parentFieldFormat:fieldFormat!=null?fieldFormat:null;
        String translationKey = '';
        String multiPFTypeTranslation = '';
        /*system.debug('objFieldMap @ '+objFieldMap);
        system.debug('relations @ '+relations);
        System.debug('Key Condition @'+objFieldMap.containsKey(relations[0]));*/
        if(isGAS && objFieldMap.containsKey(relations[0]) 
           && objFieldMap.get(relations[0]).split(',').contains(relations[1])){
               hasTranslation = true;
               translationKey = String.valueOf(relations[1].contains('__r')?
                                               tmp.getSobject(relations[1].substringbefore('.')).get(relations[1].substringAfter('.')):
                                               tmp.get(relations[1]))+'_'+languageForGAS;
              /* System.debug('Key Split @'+(relations[0]+'-'+relations[1]));
               System.debug('Condition split @'+System.Label.ECM_GAS_Translation_Split.contains(relations[0]+'-'+relations[1]));*/
               if(System.Label.ECM_GAS_Translation_Split.contains(relations[0]+'-'+relations[1])){
                   Integer count=0;
                   if(tmp.get(relations[1])!=null){
                       for(String str:String.valueOf(tmp.get(relations[1])).split('/')){
                           multiPFTypeTranslation += metaDataRecords.containsKey(str+'_'+languageForGAS)?
                               metaDataRecords.get(str+'_'+languageForGAS).ECM_Translation__c:'';
                           count+=1;
                           if(count != String.valueOf(tmp.get(relations[1])).split('/').size()){
                               multiPFTypeTranslation += multiPFTypeTranslation!=''?'/':'';
                           }
                       }
                       hasMultiPFTypes = true;
                   }
               }
           }
        
        /*system.debug('hasTranslation @'+hasTranslation);
        system.debug('key @'+translationKey);
        system.debug('containsData @'+metaDataRecords.containsKey(translationKey));*/
       /* System.debug('Time229: '+ Limits.getCPUTime());
        System.debug('Limits.getLimitCpuTime230 - '+ Limits.getLimitCpuTime());*/
		//ECM-6338 Replace null with blank for relations field
        return String.valueOf(hasTranslation && !hasMultiPFTypes && metaDataRecords.containsKey(translationKey)?metaDataRecords.get(translationKey).ECM_Translation__c:
                              hasMultiPFTypes?multiPFTypeTranslation :
                              relations[1].contains('__r') && !isformattingrequired?tmp.getSobject(relations[1].substringbefore('.')).get(relations[1].substringAfter('.')):
                              isformattingrequired	&& formattedToCurrencyStandard!=null?
                              formattedToCurrencyStandard.setScale(2).format():
                              relations[1].contains('__r')?tmp.getSobject(relations[1].substringbefore('.')).get(relations[1].substringAfter('.')):
                              tmp.get(relations[1])==null?'':tmp.get(relations[1]));
    }
}