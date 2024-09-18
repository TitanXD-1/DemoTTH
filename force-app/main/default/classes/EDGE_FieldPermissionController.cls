/*
* @description EDGE_FieldPermissionController
* @Purpose: This is to handle EDGE_FieldPermissionCreationUpdation component
* @history
                                                           
VERSION  	AUTHOR             DATE              DETAIL
1.0        Dinesh Sharma     10/03/2021       Initial Development(ES20-9141)
2.0        Monalisa Halder   11/03/2021       ES20-9226
3.0        Monalisa Halder   08/04/2021       ES20-10091
4.0        Monalisa Halder   08/05/2021       ES20-10090
5.0        Monalisa Halder   27/07/2021       ES20-10866
6.0		   Joshraj Sen		 17/12/2021       ES20-10869
7.0        Anand Uppalapati  28/12/2021       ES20-11063
8.0		   Rajarshi Lahiri   28/01/2022		  ES20-12026(Bug)
9.0        Joshraj Sen       21/02/2022       ES20-12118
10.0	   Doman Murmu		 21/12/2023		  148590
**/
public class EDGE_FieldPermissionController {
  
/**Global String**/
    private static String basicPermissionRecordTypeId = Field_Permission__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Basic Permission Set').getRecordTypeId();
    private static String fullPermissionRecordTypeId = Field_Permission__c.sObjectType.getDescribe().getRecordTypeInfosByName().get('Full Permission Set').getRecordTypeId();    

    /**
    * @description getFinalFieldDependencySettings
    * @Purpose : query the metadata records
    * @return  map
	* @param string
    */
    @AuraEnabled
    public static Map<String,Map<String,List<String>>> getFinalFieldDependencySettings(String fpsType){
        Map<String,Map<String,List<String>>> objectFieldsDependentMap = new Map<String,Map<String,List<String>>>();
        //List<Field_Permission_Dependency__mdt> fieldDependencyList = new List<Field_Permission_Dependency__mdt>();
        Map<String,String> objApiToLabels=new Map<String,String>();
        Map<String,String> fieldApiToLabels=new Map<String,String>();
        //Map<String,List<String>> fieldDependencyMap = new Map<String,List<String>>();
        List<String> typeList = new List<String>();
        for(Field_Permission_Dependency__mdt fieldDependencySetting : [SELECT Id, MasterLabel,Field_Permission_Type__c , Object__c, 
                                                                       Field__c, Dependent_Fields__c, Permission__c, Show_in_Custom_Screen__c,Parent_Field__c      
                                                                       FROM Field_Permission_Dependency__mdt where Show_in_Custom_Screen__c  = true ORDER BY Object__c,Field__c ASC]){	//148590 - added Object__c in ORDER BY
         
        if(fieldDependencySetting.Field_Permission_Type__c  != null){
        	typeList = fieldDependencySetting.Field_Permission_Type__c .split(';');
        }
        Schema.DescribeFieldResult fieldResult1 = Field_Permission__c.Related_Object__c.getDescribe();  
        List<Schema.PicklistEntry> ple1 = fieldResult1.getPicklistValues();  
        for (Schema.PicklistEntry f : ple1) {  
            objApiToLabels.put(f.getValue(),f.getLabel());  
        }
        
        Schema.DescribeFieldResult fieldResult2 = Field_Permission__c.Field__c.getDescribe();  
        List<Schema.PicklistEntry> ple2 = fieldResult2.getPicklistValues();  
        for (Schema.PicklistEntry f : ple2) {  
            fieldApiToLabels.put(f.getValue(),f.getLabel());  
        }                                                                     
        List<String> dependentFieldList = new List<String>();
        dependentFieldList.add(fieldDependencySetting.Object__c);
        //dependentFieldList.add(fieldDependencySetting.Dependent_Fields__c != null ? fieldDependencySetting.Dependent_Fields__c : '');
        dependentFieldList.add(fieldDependencySetting.Permission__c != null ? fieldDependencySetting.Permission__c : '');
        for(String type :typeList){
            if(type != fpsType){
                continue;
            }
            if(!objectFieldsDependentMap.containsKey(type)){
                objectFieldsDependentMap.put( type, new Map<String,List<String>>() );
                
            }
            objectFieldsDependentMap.get(type).put(fieldDependencySetting.Field__c,dependentFieldList);
            if(fieldDependencySetting.Parent_Field__c!=null){
                objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add(fieldDependencySetting.Parent_Field__c);
                objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add(fieldApiToLabels.get(fieldDependencySetting.Field__c));
				//String objApiName=objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c)[0];
                objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add(objApiToLabels.get(fieldDependencySetting.Object__c)) ;
				objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add('Dependent Field');
                
            }
            
            else{
                //objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add('Independent Field');
                objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add('NA');
                objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add(fieldApiToLabels.get(fieldDependencySetting.Field__c));
				//String objApiName=objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c)[0];
                objectFieldsDependentMap.get(type).get(fieldDependencySetting.Field__c).add(objApiToLabels.get(fieldDependencySetting.Object__c)) ;
                
            }

        }                                                                 
        
       }
       return objectFieldsDependentMap;
    }

	 /**
    * @description getFieldPermissionRecords
    * @Purpose : Get field permission existing records - with permission and dependent fields from each field persmission set 
    * @return  map
	* @param id,string
    */
   	
    @auraEnabled
    public static Map<String,Map<String,List<String>>> getFieldPermissionRecords(Id fieldPermissionSetId,String fpsType){
        Map<String,Map<String,List<String>>> objectFieldsDependentMap = getFinalFieldDependencySettings(fpsType);
       
        for(Field_Permission__c  fieldPermissionRec :[Select Id,Field__c, Field_Permission_Set__c,Permission__c,
                                                      Field_Permission_Set__r.Type__c,Parent_Field_PL__c,
                                                       Related_Object__c,Dependent_Fields__c, Unique_ID__c  
                                                      from Field_Permission__c where Field_Permission_Set__c =: fieldPermissionSetId 
                                                     and  Field_Permission_Set__r.Type__c =: fpsType]){
            List<String> permissionsDepFieldList = new List<String>();
            permissionsDepFieldList.add(fieldPermissionRec.Permission__c != null ? fieldPermissionRec.Permission__c : '');
            //System.debug('permissionsDepFieldList'+permissionsDepFieldList);
            //System.debug('Parent Field'+fieldPermissionRec.Parent_Field_PL__c);
            String fieldName = fieldPermissionRec.Field__c;
                                                         
            if(objectFieldsDependentMap.containsKey(fieldPermissionRec.Field_Permission_Set__r.Type__c) && 
               objectFieldsDependentMap.get(fieldPermissionRec.Field_Permission_Set__r.Type__c).get(fieldName) != null)
            {
                
                    objectFieldsDependentMap.get(fieldPermissionRec.Field_Permission_Set__r.Type__c).get(fieldName).addAll(permissionsDepFieldList) ;
            }
           
			
            /*if(fieldPermissionRec.Parent_Field_PL__c ==null && objectFieldsDependentMap.containsKey(fieldPermissionRec.Field_Permission_Set__r.Type__c) && 
               objectFieldsDependentMap.get(fieldPermissionRec.Field_Permission_Set__r.Type__c).get(fieldName) != null)
            {                                           
                objectFieldsDependentMap.get(fieldPermissionRec.Field_Permission_Set__r.Type__c).get(fieldName).add('FieldLabel') ;
            }*/
			
        }
        
        system.debug(LoggingLevel.DEBUG,'@@objectFieldsDependentMap' +objectFieldsDependentMap);
        return objectFieldsDependentMap;
    }
    /**
    * @description getFieldPermissionRecords
    * @Purpose : Quering the existing records 
    * @return  map
	* @param id,string
    */
   	 
    @auraEnabled
    public static  Map<String, Field_Permission__c> getFieldPermissionSetRelatedRec (Id fieldPermissionSetId, string type){
       Map<String, Field_Permission__c> fieldNamePermissionMap = new Map<String, Field_Permission__c>(); 
       for(Field_Permission__c  fieldPermissionRec :[Select Id,Field__c, Field_Permission_Set__c, Field_Permission_Set__r.Type__c,
                                                     Permission__c,Related_Object__c,Dependent_Fields__c,Unique_ID__c,Parent_Field_PL__c
                                                     from Field_Permission__c where Field_Permission_Set__c =: fieldPermissionSetId
                                                     and Field_Permission_Set__r.Type__c =: type]){
        
      		fieldNamePermissionMap.put(fieldPermissionRec.Field__c,fieldPermissionRec);
       
        }
         return  fieldNamePermissionMap;
     }
    
    /**
    * @description getFieldPermissionRecords
    * @Purpose : Insert and update Field Permission records for each Field Permission Set 
    * @param id,map,string
    */
    
    @AuraEnabled
    public static void insertUpdateFieldPermission(Id fieldPermissionSetId, Map<String,List<String>> fieldPermissionMap, String type){
        Map<String, Field_Permission__c> fieldNamePermissionMap = getFieldPermissionSetRelatedRec(fieldPermissionSetId,type);
        List<Field_Permission__c> insertFieldPermissionList = new List<Field_Permission__c>();
        List<Field_Permission__c> updateFieldPermissionList = new List<Field_Permission__c>();
        System.debug(LoggingLevel.DEBUG,'@FieldPerm'+fieldPermissionMap);
        for(String fieldName :fieldPermissionMap.keySet()){
            Field_Permission__c fieldPermRec = new Field_Permission__c();
            fieldPermRec.Field__c = fieldName;
            System.debug(LoggingLevel.DEBUG,'Field value'+fieldName);
            fieldPermRec.Field_Permission_Set__c = fieldPermissionSetId;
            if(!fieldPermissionMap.get(fieldName)[0].equals('Dependent Field')){
                fieldPermRec.Permission__c = fieldPermissionMap.get(fieldName)[0];
            }
            else{
                 if(!fieldPermissionMap.get(fieldName)[2].equals('NA')){
                        String parentPermission=fieldPermissionMap.get(fieldPermissionMap.get(fieldName)[2])[0];
                        fieldPermRec.Permission__c = parentPermission;
                }
            }
            fieldPermRec.Related_Object__c = fieldPermissionMap.get(fieldName)[1];
            //System.debug('Parentpermission'+fieldNamePermissionMap.get(fieldName));
               
            
            

            if(type == 'Prospect' || type == 'Default Prospect'){
                fieldPermRec.RecordTypeId =  basicPermissionRecordTypeId;   
            }else {
                fieldPermRec.RecordTypeId =  fullPermissionRecordTypeId;       
            }
            if(fieldNamePermissionMap.containsKey(fieldName)){
                if((fieldPermRec.Permission__c != fieldNamePermissionMap.get(fieldName).Permission__c || 
                    fieldPermRec.Dependent_Fields__c != fieldNamePermissionMap.get(fieldName).Dependent_Fields__c )){
                        fieldPermRec.Id = fieldNamePermissionMap.get(fieldName).Id;
                        fieldPermRec.Unique_ID__c = fieldNamePermissionMap.get(fieldName).Unique_ID__c;
                        updateFieldPermissionList.add(fieldPermRec);
                  }
            }
            else{
                insertFieldPermissionList.add(fieldPermRec);
            }
        }
        if(insertFieldPermissionList != null && insertFieldPermissionList.size()>0 && Schema.sObjectType.Field_Permission__c.isCreateable()){
            Database.insert(insertFieldPermissionList,true);     
        }
        if(updateFieldPermissionList != null && updateFieldPermissionList.size()>0 && Schema.sObjectType.Field_Permission__c.isUpdateable()){
            Database.update(updateFieldPermissionList,true);     
        }
    }
   
}