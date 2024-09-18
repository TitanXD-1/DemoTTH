/**
@name Edge_CaseIntegrationWithSNOW

@history                                                            

-------                                                            
VERSION   AUTHOR            DATE              DETAIL
1.0     Dinesh Sharma     19/07/2021        Class implemented to send the Case details to Service Now [ES20-9229]
1.1     Shivam Chauhan    18/10/2023        146993 - Migrating Authentication Mechanism to oAuth 2.0_SFDC_Tech Debt

**/


public without sharing class EDGE_CaseIntegrationWithSNOW  implements Queueable,Database.AllowsCallouts {  
    public static final String EDGE_MULESOFT_CREATEINCIDENT = 'EDGE_Mulesoft_Incidention_Creation';//146993
    Map<Id,Case> caseRecordMap = new Map<Id,Case>() ;

    //public static Map<Id, String> userToCountryMap = new Map<Id, String>();

    public static final string APPFORDIAGEOONE= 'Applicable_for_Diageo_One__c';
    public static final string APPFOREDGEGLOBAL= 'Applicable_for_EDGE_365__c';
    public static final string EDGEGLOBAL= system.Label.EDGE_365_Global;
    public static final String DEFAULTASSIGNGROUP= system.Label.Case_Default_Assignment_Group;
    //public static final String ENDPOINT= system.Label.Service_Now_End_Point;
    //public static final string CLIENTID= system.Label.Service_Now_Client_Id ;
    //public static final string CLIENTSECRET= system.Label.Service_Now_Client_Secret;
    public static final String DEFAULTCONTACTLANGUAGE= 'en';
    public static final string TOTALALLOWEDCALLOUTSSTR= system.Label.Service_Now_Total_Allowed_Callouts ;
    
    public EDGE_CaseIntegrationWithSNOW(Map<Id,Case> newItems){
        this.caseRecordMap = newItems;
    }
    


        /**
    * @method   execute
    * @description This method makes callout to SNOW with Case details
    * @return null
    * @param bc
    */
    public void execute(QueueableContext bc){
        
       // Map<Id,Case> caseRecordMap = (Map<id,Case>)newItems;   

        Map<Id,String> caseIncidentMap = new Map<Id,String>();
        Map<Id,List<String>> caseReturnedFieldMap = new Map<Id,List<String>>();
        list<Id> caseListNotProcessed = new list<Id>();
        Integer totalCallOutsPerformed = 0;
        Integer totalAllowedCallOuts = Integer.valueOf(TOTALALLOWEDCALLOUTSSTR);

        string request = '';
        string response = '';
        
        if(caseRecordMap != null){
            caseIncidentMap = getSNOWIncidentDetail(caseRecordMap);
        }

        try{

        if(caseIncidentMap != null && caseIncidentMap.size() > 0){
            
            for(Id ide : caseIncidentMap.keySet() ){
               
                HttpRequest req = new HttpRequest();

                   //  req.setEndpoint(endPoint);
           
                req.setEndpoint('callout:' + EDGE_MULESOFT_CREATEINCIDENT); //146993
                    req.setMethod('POST');
                    string requestBody = caseIncidentMap.get(ide);

                req.setBody(requestBody);
              //  req.setHeader('client_id',clientId);
            //    req.setHeader('client_secret',clientSecret);
                req.setHeader('Content-Type', 'application/json');
				req.setTimeout(120000);

                    request = requestBody;
                    

                if(!Test.isRunningTest()){
                    Http http = new Http();
                    if(Limits.getCallouts() < Limits.getLimitCallouts() &&  totalCallOutsPerformed < totalAllowedCallOuts){
                        HTTPResponse res = http.send(req);
                        totalCallOutsPerformed++;
                        if(res.getStatusCode() == 200){
                            caseReturnedFieldMap.put(ide,new list<String> {});
                            Map<String,object> returnedValueMap = (Map<String,object>) JSON.deserializeUntyped(res.getBody());
                            string incNumber = (string)returnedValueMap.get('number');
                            string sysId = (string)returnedValueMap.get('sys_id');
                            caseReturnedFieldMap.get(ide).add(incNumber);
                            caseReturnedFieldMap.get(ide).add(sysId);  



                                response = returnedValueMap.values().toString();
                                
                                D1_CustomLoggingUtility.logMessage('EDGE_CaseIntegrationWithSNOW', 'execute', 'SUCCESS','','', request != null ? request : '', res.getBody());
                            }else{
                                D1_CustomLoggingUtility.logMessage('EDGE_CaseIntegrationWithSNOW', 'execute', res.getStatus()+';'+res.getStatusCode(),'','',  request != null ? request : '', res.getBody());


                        }
                    }else{
                        caseListNotProcessed.add(ide);
                    }
            } 
                
            }
        }


        }catch(exception ex){
            D1_CustomLoggingUtility.logMessage('EDGE_CaseIntegrationWithSNOW', 'execute', ex.getCause()+';'+ex.getLineNumber()+';'+ex.getMessage(),ex.getStackTraceString(),ex.getTypeName(), request != NULL ?request:'', response != NULL ? response:'');
            
        }


        if(caseReturnedFieldMap != null && caseReturnedFieldMap.size() > 0){
            updateCaseRecord(caseReturnedFieldMap);
        }
     
    }

        /**
    * @method   getSNOWIncidentDetail (ES20-9229)
    * @description This method creates a JSON string format for case details to 
              be sent to SNOW
    * @return map
    * @param mao
    */ 

    public static Map<Id,String> getSNOWIncidentDetail(Map<Id,Case> caseRecordMap){
        
        set<Id> userCreatedBySet = new set<Id>();
        Map<String,Incident_Interface_Attributes_Setup__mdt> caseAttributeMap = new Map<String,Incident_Interface_Attributes_Setup__mdt>();
        List<Case> caseRec = new List<Case>(); 
        Map<Id,String> caseIncidentMap = new Map<Id,String>();
       // List<String> allowedSNOwCountryList = new List<String>();
        
        for(Case obj :caseRecordMap.values()){
            userCreatedBySet.add(obj.CreatedById);
        }
        //Get User Id and User Language Code in a Map
        Map<String,Incident_Configuration_Item_Setup__mdt> incConfigItemSetupMap = new Map<String,Incident_Configuration_Item_Setup__mdt>();
        Map<Id,String> userIdLanguageMap = fetchLanguageCode(userCreatedBySet);
        Map<String, String> fetchDerievedValueMap = fetchAssignmentGroupConfigItem(userCreatedBySet, incConfigItemSetupMap);
        Map<Id, String> userToCountryMap = fetchUserCountry(userCreatedBySet);
        


        
        For(Incident_Interface_Attributes_Setup__mdt iNAttri : [Select Id,MasterLabel,Applicable_for_Diageo_One__c,Applicable_for_EDGE_365__c,Fixed_Value__c,
                                                                Middleware_field_Name__c,SFDC_Field_Name__c,Object_API_Name__c,
                                                                Derived_From_Other_Sources__c FROM Incident_Interface_Attributes_Setup__mdt]){
            
            if(!caseAttributeMap.containsKey(iNAttri.Middleware_field_Name__c)){
                caseAttributeMap.put(iNAttri.Middleware_field_Name__c,iNAttri);
            }
        }
        
        if(caseRecordMap != null){
        	caseRec = [Select Id,Description,Subject,Status,Origin,Account.Name,SuppliedEmail,CreatedById,CreatedBy.Email,CreatedBy.Name,CreatedBy.LanguageLocaleKey from Case where Id IN :caseRecordMap.keySet()];
        }
        
        if(caseRec != null && caseRec.size() > 0 && caseAttributeMap !=null && caseAttributeMap.size() > 0 ){
            
            for( Case cc : caseRec){
                
                String applicableCase =  (cc.Origin == EDGEGLOBAL) ? APPFOREDGEGLOBAL : APPFORDIAGEOONE;
                JSONGenerator gen = JSON.createGenerator(true);
                gen.writeStartObject();
                
                for(string middleWareName : caseAttributeMap.keySet() ){
                    
                    Incident_Interface_Attributes_Setup__mdt incidentAttr = caseAttributeMap.get(middleWareName);
                    Incident_Configuration_Item_Setup__mdt conFigItemMetadata = incConfigItemSetupMap.get(cc.Origin);

                    Boolean applicableForSelection;
                    
                    if(incidentAttr != null){
                         applicableForSelection = (Boolean)incidentAttr.get(applicableCase);
                    }
                    
                    if(applicableForSelection == true && incidentAttr.Fixed_Value__c == null 
                       && incidentAttr.Derived_From_Other_Sources__c == false)
                    {
                        string fieldValue = '';
                        string fieldName = incidentAttr.SFDC_Field_Name__c;
                        
                        if(fieldName.contains('.')){
                            string parentId = fieldName.substringBefore('.');
                            string childField = fieldName.substringAfter('.');
                            if(parentId != null && childField != null && cc.getSobject(parentId) != NULL){
                                fieldValue = (String)cc.getSobject(parentId).get(childField);
                            }
                        }else{
                            if(fieldName != null){
                                fieldValue = (string)cc.get(fieldName);
                            }
                        }
                        if(middleWareName == 'Impacted Applications'){
							fieldValue = conFigItemMetadata == null? '' : conFigItemMetadata.Sub_Category__c;
						} 
                        
                        gen.writeStringField(middleWareName, fieldValue == null?'':fieldValue);
                    }
                    else if(applicableForSelection == true && !string.isBlank(incidentAttr.Fixed_Value__c ))
                    { 
                        string fixedValue = (string)incidentAttr.Fixed_Value__c;
                        gen.writeStringField(middleWareName,fixedValue);
                    }
                    else if(applicableForSelection == true && incidentAttr.Derived_From_Other_Sources__c == true)
                    {
                        string derivedValues;
                        
                        if(middleWareName == 'Assignment Group'){
                            string key = userToCountryMap.get(cc.createdById)+'_'+cc.CreatedBy.LanguageLocaleKey.substringBefore('_')+'_'+cc.Origin;
                              derivedValues = fetchDerievedValueMap.containsKey(key) ? fetchDerievedValueMap.get(key) : DEFAULTASSIGNGROUP;
                        }else if(middleWareName == 'Configuration Item'){
							derivedValues = conFigItemMetadata == null? '' : conFigItemMetadata.Configuration_Item__c;
						}else if(middleWareName == 'Language Code'){
							derivedValues = userIdLanguageMap == null || userIdLanguageMap.isEmpty() ? DEFAULTCONTACTLANGUAGE : userIdLanguageMap.get(cc.CreatedById);
						}
                        if(derivedValues != null){
                            gen.writeStringField(middleWareName,derivedValues);
                        }else{
                            gen.writeStringField(middleWareName,'');
                        }
                    }
                    else{
                        gen.writeStringField(middleWareName,'');
                    }
                }
                
                gen.writeEndObject();
                string jsonString = gen.getAsString();
                caseIncidentMap.put(cc.Id,jsonString);
                    
            }
            
        } 
        return caseIncidentMap;
    }
    

   /**
    * @method   fetchUserCountry  ES20-10644
    * @description fetch user country
    *          Case 1 - User country = Available_Countries__c if there's only one value in Available_Countries__c
    *          Case 2 - User country = Default_Country__c if there are multiple values in Available_Countries__c and Default_Country__c has value
    *          Case 3 - User country = first entry of Available_Countries__c if there are multiple values in Available_Countries__c and Default_Country__c has no value
    * @return map
    * @param set

    */

    public static Map<Id, String> fetchUserCountry(Set<Id> userIdSet){
        
        Map<Id, String> userToCountryMap = new Map<Id, String>();
        
        if(userIdSet != null){
            for(User u : [SELECT Id, Available_Countries__c, Default_Country__c FROM User WHERE Id IN : userIdSet])
            {
                List<String> assignedCountriesList = new List<String>();
                String userCountry = '';
                
                if(u.Available_Countries__c != null){
                    assignedCountriesList.addAll(u.Available_Countries__c.split(';'));
                }
                
                if(assignedCountriesList!=null && assignedCountriesList.size()>0)
                {
                    if(assignedCountriesList.size()==1) {//case 1
                        userCountry = assignedCountriesList.get(0);
                    }
                    else if(assignedCountriesList.size()>1 && u.Default_Country__c!=null) {//case 2
                        userCountry = u.Default_Country__c;
                    }
                    else if(assignedCountriesList.size()>1 && u.Default_Country__c==null){ //case 3
                        userCountry = assignedCountriesList.get(0);            
                    }
                }
                if(!String.isBlank(userCountry)){
                    userToCountryMap.put(u.Id,userCountry);
                }  
            }
        } 
        return userToCountryMap;
    }   

   
    

    /**
    * @method   fetchLanguageCode ES20-10566
    * @description This method is used to return a MAP of Userid and first 2 string of Language Code
    * @return map
    * @param set
    
    **/  
    public static Map<Id,String> fetchLanguageCode(Set<Id> userCreatedBySet){


        Map<Id, String> userLanguageCode = new Map<Id, String>();
        
        if(userCreatedBySet != null && userCreatedBySet.Size()>0){
            for(User uId : [Select Id, LanguageLocaleKey FROM user WHERE id IN :userCreatedBySet]){
                String lCode = '';
                if(!String.isBlank(uid.languageLocalekey )){
                    lCode  = uid.languageLocalekey.substring(0,2);  
                }
                
                if(!userLanguageCode.containsKey(uId.Id)){
                    userLanguageCode.put(uId.Id,lCode); 
                }
            }
            
        } 
        return userLanguageCode;
    }
    
        

    /**
    * @method   fetchAssignmentGroupConfigItem ES20-10568
    * @description This method is used to return a MAP composite key and value of 
					language code, assignment group, configuration item
    * @return set,map
    * @param set
    */

    public static Map<String, String>  fetchAssignmentGroupConfigItem(Set<Id> userCreatedBySet , Map<String,Incident_Configuration_Item_Setup__mdt> incConfigItemSetupMap){
        Map<String, String> langAssignGrpConfigItemMap = new Map<String, String>();   
		//Map<String,String> assignmentGroupMap = new Map<String,String>();       
        
        for(Incident_Configuration_Item_Setup__mdt configMdt :[select App_Name__c , Configuration_Item__c , Sub_Category__c  from
                                                              Incident_Configuration_Item_Setup__mdt])
        {
                                                                  
          incConfigItemSetupMap.put(configMdt.App_Name__c,configMdt);  
        }
        
        for(Incident_Assignment_Group_Setup__mdt  assignGroup :[Select Id,App_Name__c, Assignment_Group__c, Country_Code__c, 
                                                                Language__c from Incident_Assignment_Group_Setup__mdt])
        {
            String assignGrpkey = assignGroup.Country_Code__c + '_' + assignGroup.Language__c + '_' + assignGroup.App_Name__c;                                                         
        	langAssignGrpConfigItemMap.put(assignGrpkey,assignGroup.Assignment_Group__c);
                                                    
        }
        


        return langAssignGrpConfigItemMap;
    }
   
    /*******************************************************************

    * @method   updateCaseRecord ES20-9229
    * @description This method is used to update case record post SNOW callout
    * @return void
    * @param map
	*/

    public static void updateCaseRecord(Map<id,list<String>> caseReturnedFieldMap){
        
        list<Case> caseToUpdate = new List<Case>();
        list<Case> caseRecordFetched = new List<Case>();
        if(caseReturnedFieldMap != null && caseReturnedFieldMap.size() > 0){
            caseRecordFetched = [select Id, Inc_Req_Number__c , sys_id__c FROM Case Where Id IN : caseReturnedFieldMap.keySet()];
            
            for(Case ca : caseRecordFetched ){
                ca.Inc_Req_Number__c = caseReturnedFieldMap.get(ca.id)[0];
                ca.sys_id__c = caseReturnedFieldMap.get(ca.Id)[1];
                caseToUpdate.add(ca);
            }
        }
        
        if(caseToUpdate != null && caseToUpdate.size() > 0){
            database.update(caseToUpdate) ;
        }
    }
    
}