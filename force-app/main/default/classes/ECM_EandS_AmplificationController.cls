/*
* @Name: ECM_EandS_AmplificationController
* @description: This Class is for handling E&S contract specific server calls for ECM_EandS_Amplification.cmp
* @History 

VERSION			AUTHOR                DATE					DETAIL
1.0			Saurav Prasad           08/06/2022          Initial Development

*/
public class ECM_EandS_AmplificationController {
    
    public static List<String> getPickListValuesIntoList(String objectType, String selectedField){
        List<String> pickListValuesList = new List<String>();
        Schema.SObjectType convertToObj = Schema.getGlobalDescribe().get(objectType);
        Schema.DescribeSObjectResult res = convertToObj.getDescribe();
        Schema.DescribeFieldResult fieldResult = res.fields.getMap().get(selectedField).getDescribe();
        List<Schema.PicklistEntry> ple = fieldResult.getPicklistValues();
        for( Schema.PicklistEntry pickListVal : ple){
            pickListValuesList.add(pickListVal.getLabel());
        }     
        return pickListValuesList;
    }
    
    
    public static Map<String,Map<String,String>> getFieldMap(String objectApiName){
        Map<String,Map<String,String>> fieldMapping = new Map<String,Map<String,String>>();
        
        Map <String, Schema.SObjectField> fieldMap = 
            Schema.getGlobalDescribe().get(objectApiName).getDescribe().fields.getMap();
        for(Schema.SObjectField sfield : fieldMap.Values()){
            String strType = string.valueOf(fieldMap.get(sfield.getdescribe().getname()).getDescribe().getType());
            if((sfield.getdescribe().isAccessible() ==  true && 
				   sfield.getdescribe().isUpdateable() == true) || (sfield.getdescribe().getlabel()=='Record ID')) {
                   fieldMapping.put(sfield.getdescribe().getlabel(),new map<String,String>{sfield.getdescribe().getname()=>strType});
               }
        }
        
        return fieldMapping;
    }
    @AuraEnabled
    public static amplificationWrapper getData(String conId){
        //Map<String,List<amplicationWrapperList>> sectionSetup = new Map<String,List<amplicationWrapperList>>();
        Map<String,map<String,String>> fieldMap = new Map<String,map<String,String>>();
        Map<String,String> dataTypeMap = new Map<String,String>();
        Map<String,List<String>>  fieldPicklist = new Map<String,List<String>>();
        Map<String,Integer> data = new Map<String,Integer>();
		String amplificationSection;
		List<String>SectionList= new List<String>();
        Map<String,String> SectionMap = new Map<String,String>();
		Map<String,List<ECM_Amplification__c>> amplificationData= new Map<String,List<ECM_Amplification__c>>();
		String countryCode;
        List<Contract>contractList=[select id,Name,Account.country_code__c from contract where id=:conId];
        if(!contractList.isEmpty() && contractList[0].Account!=null && contractList[0].Account.country_code__c!=null ){
            countryCode=contractList[0].Account.country_code__c;
        }
				
		List<ECM_Technical_Market_Setting__mdt>technicalmarketSettingList=[select id,ECM_E_S_Contract_Amplification_Section__c from ECM_Technical_Market_Setting__mdt where ECM_Country__c=:countryCode];
		if(!technicalmarketSettingList.isEmpty()){
			 amplificationSection=technicalmarketSettingList[0].ECM_E_S_Contract_Amplification_Section__c;
			 for(String section: amplificationSection.split(',,')){
				 
				 SectionList=section.split('=>');
				 if(!SectionList.isEmpty() && SectionList.size()>1){
					 SectionMap.put(SectionList[0].trim(),SectionList[1].trim());
				 }
				 
			 }
		}
		amplificationData=getAmplificationData(conId);
        system.debug('amplificationData--->'+amplificationData);
        fieldMap = getFieldMap('ECM_Amplification__c');  
        amplificationWrapper wrap = new amplificationWrapper();
        wrap.conId = conId;
		
        for(String str : SectionMap.keySet()){
            //sectionSetup.put(str,new List<amplicationWrapperList>{});
			Section newSection= new Section();
			newSection.Name=str;
            for(String label : SectionMap.get(str).split(';')){
                Field tempWrap = new Field();
                list<String> temp = new List<String>();
                List<String> dataTypeList = new List<String>();
                List<String> pickList = new List<String>();
                tempWrap.label = label;
                System.debug('label:'+label);
                temp.addAll(fieldMap.get(label).keySet());
                tempWrap.value = temp[0];
                dataTypeList.addAll(fieldMap.get(label).values());
                tempWrap.dataType = dataTypeList[0];
                
                tempWrap.data = '';
                if(fieldMap.containsKey(tempWrap.label) && (fieldMap.get(tempWrap.label).values()).contains('PICKLIST')){
                    pickList.addAll(getPickListValuesIntoList('ECM_Amplification__c',temp[0]));
                    tempWrap.picklistValues = pickList;
                }
                
                newSection.sectionFields.add(tempWrap);
            }
			System.debug('Str:'+Str);
            if(amplificationData.get(str)!=null && amplificationData.get(str).size()>0){
			for(ECM_Amplification__c amplification : amplificationData.get(str)){
				 
				 
				 Data tempdata= new Data();
				 tempdata.amplification=amplification;
				 tempdata.isDelete=false;
				 newSection.sectionData.add(tempdata);
            }
			}
			wrap.sectionList.add(newSection);
        }
        
        return wrap;
    }
	
	 @AuraEnabled
    public static Map<String,List<ECM_Amplification__c>> getAmplificationData(String conId){
		system.debug('wrap1-->');
		String query='select id';
		Map<String,List<ECM_Amplification__c>> amplificationMap= new Map<String,List<ECM_Amplification__c>>();
		Map <String, Schema.SObjectField> fieldMap = Schema.getGlobalDescribe().get('ECM_Amplification__c').getDescribe().fields.getMap();
		List<ECM_Amplification__c> temp= new List<ECM_Amplification__c>();
        
        for(String info: Schema.SObjectType.ECM_Amplification__c.getRecordTypeInfosByDeveloperName().KeySet()){
            amplificationMap.put(info,new List<ECM_Amplification__c>());
        }
        
        for(Schema.SObjectField sfield : fieldMap.Values()){
			  if(sfield.getdescribe().isAccessible() ==  true && 
				   sfield.getdescribe().isUpdateable() == true) {
				   query=query+','+sfield.getdescribe().getname();
			   }
        }
		query=query+',recordtype.Name from ECM_Amplification__c where ECM_Contract__c=\''+conId+'\'';
        		system.debug('wrap2-->'+query);
		for(ECM_Amplification__c sobj:Database.query(query)){
            system.debug('wrap3-->'+sobj);
			if(amplificationMap.containsKey(sobj.recordtype.Name)){
				temp=amplificationMap.get(sobj.recordtype.Name);
				temp.add(sobj);
				amplificationMap.put(sobj.recordtype.Name,temp);
			}else{
				amplificationMap.put(sobj.recordtype.Name,new List<ECM_Amplification__c>{sobj});
			}
		}
		return amplificationMap;
		

	}
    @AuraEnabled
    public static void saveAmplificationData(String conId,String sectionData){
        
        List<Section> sectionList=(List<Section>)JSON.deserialize(sectionData, List<Section>.class);
        system.debug('sectionList--->'+sectionList);
        Map<String,RecordTypeInfo>recordTypeInfoList=Schema.SObjectType.ECM_Amplification__c.getRecordTypeInfosByName();
		List<ECM_Amplification__c>amplificationUpdateList= new List<ECM_Amplification__c>();
		List<ECM_Amplification__c>amplificationDeleteList= new List<ECM_Amplification__c>();
        for(ECM_EandS_AmplificationController.Section sec:sectionList){
            
			for(ECM_EandS_AmplificationController.Data sectiondataTemp:sec.sectionData){
				
				if(!sectiondataTemp.isDelete){
					ECM_Amplification__c amplification= new ECM_Amplification__c();
					amplification=sectiondataTemp.amplification;
					amplification.recordtypeid=recordTypeInfoList.get(sec.Name).getRecordTypeId();
                    if(!(amplification.Id!=null)){
						amplification.ECM_Contract__c=conId;
                    }
					amplification.ECM_Unique_Id__c=amplification.ECM_Contract__c+'_'+sec.Name;
                    for(Field secField:sec.sectionFields){
                        if(secField.value!=null && amplification.get(secField.value)!=null && secField.value!='ECM_Redirect_Links__c' ){
                            amplification.ECM_Unique_Id__c=amplification.ECM_Unique_Id__c+'_'+amplification.get(secField.value);
                        }
                    }
                    system.debug('New Data-->'+amplification);
					amplificationUpdateList.add(amplification);
				}else{
					ECM_Amplification__c amplification= new ECM_Amplification__c();
					amplification=sectiondataTemp.amplification;
					amplificationDeleteList.add(amplification);
				}
			}
            
        }
		
		if(!amplificationUpdateList.isEmpty()){
			Database.upsert(amplificationUpdateList);
		}
		
		if(!amplificationDeleteList.isEmpty()){
			Database.delete(amplificationDeleteList);
		}
		
		
    }
	
	public class amplificationWrapper{
		
		@AuraEnabled public String conId {get;set;}
		@AuraEnabled public List<Section> sectionList {get;set;}
        public amplificationWrapper(){
            sectionList= new List<Section>();
        }
	}

    public class Section{
        @AuraEnabled public String Name {get;set;}
        @AuraEnabled public List<Field> sectionFields {get;set;}
		@AuraEnabled public List<Data> sectionData {get;set;}
        public Section(){
            sectionFields= new List<Field>();
            sectionData= new List<Data>();
        }

    }
    public class Field{
        @AuraEnabled public String label {get;set;}
        @AuraEnabled public String value {get;set;}
        @AuraEnabled public String dataType {get;set;}
        @AuraEnabled public List<String> picklistValues {get;set;}
        @AuraEnabled public String data {get;set;}
        public Field(){
            picklistValues= new List<String>();
        }
    }
	public class Data{
		@AuraEnabled public boolean isDelete {get;set;}
		@AuraEnabled public ECM_Amplification__c amplification {get;set;}
        public Data(){
            amplification= new ECM_Amplification__c();
        }
    }
    
}