/*
* @name: D1_HelpSupportController
* @discription: D1_HelpSupportController Class for Help and Support page 
* @history
* VERSION     AUTHOR           DATE       DETAIL
* 1.0         Ayush           10/06/20    getTopicsSubTopics (NCP-635)
* 1.0         Ayush           10/09/20    getLinks (NCP-637)
* 1.0         Gaurav          22/02/21    getUserTypeInfo (NCP-1836)
* 1.1         Abhishek        11/03/21    Reopen Case (NCP-2387)
* 1.2         Mukesh Kanth    25/03/21    Updated getCaseList method to replace AccountId with effectiveAccountid for multiple sold to(NCP-2051)
* 1.3         Rushikesh       24/05/21    NCP-2915 (createCaseFeed)
* 1.4         Sayan Samaddar  25/05/2021  NCP-2847(Direct Disputes)
* 1.5         Amar Deep       22/09/2021  NCP-3906
* 2.0         Kapil Baliyan   14/04/2022  NCP-6489 (getLinks)
* 3.0         Kapil Baliyan   02/05/2022  NCP-6488
* 4.0         Sayan Samaddar  01/06/2022  NCP-6736
* 5.0         Sayan Samaddar  14/06/2022  NCP-6842, NCP-6841
* 6.0         Pratap Sen      27/06/2022  NCP-8210/ADO-114677 (Added getTopicsSubTopicsNew)
* 7.0         Rajesh kumar    28/06/2023  NCP-8214/ADO-114681 
*/

public without sharing class D1_HelpSupportController {

    @AuraEnabled
    public static String articleName(String articleId){
        String articleName ='';
        
        if(string.isNotBlank(articleId)){
            List<Knowledge__kav> knowledge = [SELECT Id, toLabel(Article_Types__c) FROM Knowledge__kav WHERE Id=:articleId];
            articleName = knowledge[0].Article_Types__c;
        }
        
        return articleName;
    }
    
    @AuraEnabled()
    public static List<Case> getCaseList(){
        User usr = [SELECT Id, ContactId FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }
        Id d1RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();
        Id d1KegReturnRecTypId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Keg Return').getRecordTypeId();
        Id d1DirectDisputes = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        Id technicalIssue = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();
        List<Case> caseList = new List<Case>();
        caseList = [SELECT Id, RecordTypeId, CaseNumber, toLabel(Type), toLabel(D1_Subject__c), Description, Status,IsClosed, CreatedDate,D1_Batch_Number__c, D1_Order_Number__c, D1_Document_no__c, D1_Invoice_Number__c, D1_Delivery_Number__c FROM Case
                    WHERE (CreatedById = :UserInfo.getUserId() OR ContactId =:usr.ContactId) AND (RecordTypeId = :d1RecordTypeId OR RecordTypeId = :d1KegReturnRecTypId OR RecordTypeId = :d1DirectDisputes OR RecordTypeId = :technicalIssue) AND Origin = 'Diageo One'
                    WITH SECURITY_ENFORCED ORDER By CreatedDate DESC];
        for(Case cs: caseList){
            if(cs.RecordTypeId == d1DirectDisputes){
                if(!cs.IsClosed){
                    cs.Status = valueLabelMap.get('Open');
                }
                else{
                    cs.Status = valueLabelMap.get(cs.Status);
                }
            }
            else{
                cs.Status = valueLabelMap.get(cs.Status);
            }
        }
        return caseList;
    }

    
    //Wrapper Class
    public class KnowledgeWrapper {
        @AuraEnabled public String id {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String url {get; set;}
    }
    
    //Wrapper Class
    public class TopicWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String name {get; set;}
        @AuraEnabled public List<KnowledgeWrapper> subTopicList {get; set;}
    }

    //Wrapper Class
    public class ReasonForCancellationOptionsWrapper {
        @AuraEnabled public String label {get; set;}
        @AuraEnabled public String name {get; set;}
    }

    //Wrapper Class - 8211
    public class CaseTypeAndSubTypeWrp{
        @AuraEnabled public String usrType {get; set;}
        @AuraEnabled public Set<String> caseTypes {get; set;}
        @AuraEnabled public Set<String> caseSubTypes {get; set;}
        @AuraEnabled public List<TopicWrapper> listOftypeSubtypeMap {get; set;}
    }

    @AuraEnabled
    public static void createAttachment(Id caseId,Id contentDocId){
        String libraryName = 'Case';
        ContentWorkspace contentWorkSpc = [SELECT Id FROM ContentWorkspace where name = :libraryName LIMIT 1];

        ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
        newWorkspaceDoc.ContentWorkspaceId = contentWorkSpc.Id; 
        newWorkspaceDoc.ContentDocumentId = contentDocId;
        insert newWorkspaceDoc;        
        
        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = caseId;
        cdl.ContentDocumentId = contentDocId;
        cdl.shareType = 'V';
        Insert cdl; 
    }
    @AuraEnabled
    public static Case getCaseDetail(Id caseRecId){
        return [SELECT Id, Status,Case_Sub_Type__r.Name,IsClosed, createdDate, CaseNumber, toLabel(D1_Subject__c), toLabel(Type), Description, ClosedDate ,Number_of_Kegs_Requested__c,RecordType.Name,D1_Shipping_Account__c,D1_Batch_Number__c,D1_Order_Number__c,D1_Document_no__c,D1_Invoice_Number__c,D1_Delivery_Number__c,D1_Number_Of_Items_To_Return__c FROM Case WHERE Id = :caseRecId LIMIT 1];
    }
    @AuraEnabled
    public static Map<String,Object> getCaseDetailBasedOnMapping(Id caseRecId){//NCP-6735
        User userRecord = D1_MyUserDetailsCtrl.getUser();
        
        String query='SELECT RecordType.name,';

        Case caseRec = [select id,RecordType.name,Type from  case where Id =:caseRecId limit 1];
        String tableType = caseRec.RecordType.name=='Quality' ? 'Customer Service Detail':'Diageo One Detail';
        if( tableType =='Diageo One Detail' && (caseRec.Type =='Quality Issues'|| caseRec.Type =='Quality & Equipment Issues') ){
            tableType ='Diageo One Quality Detail';
        }
        String userType = userRecord.D1_User_Type__c =='Outlet/Retailers'? 'In-Direct':'Direct';
        D1_HelpAndSupportTableMapping__mdt mappingRecord = [ SELECT Id,Table_Columns__c  FROM D1_HelpAndSupportTableMapping__mdt
                                                             WHERE D1_User_Locale_Setting__r.Country_Code__c =:userRecord.Available_Countries__c
                                                             AND D1_User_Locale_Setting__r.LanguageLocaleKey__c =:userRecord.LanguageLocaleKey 
                                                             AND Table_Type__c =:tableType AND User_Type__c =:userType  LIMIT 1];
        List<String> tableRows = mappingRecord.Table_Columns__c.split(';');
        
        for(String tableRow : tableRows){
            List<String> labelNameList = tableRow.split(':');
            query+=labelNameList[1].trim()+',';
        }
        query=query.removeEnd(',');
        query+=' FROM Case WHERE Id =:caseRecId LIMIT 1';
        Case caseRecord = Database.query(query);

        return processTableRows(caseRecord,tableRows,tableType);
    }
    @AuraEnabled
    public static Map<String,Object> processTableRows(Case caseRecord,List<String> tableRows,String tableType){//NCP-6735
        Map<String,Object> fieldLabelValueMapping = new Map<String,Object>();
        Schema.DisplayType fielddataType;
        Schema.SObjectType caseObj = Schema.getGlobalDescribe().get('Case');
        Map<String, Schema.SObjectField> fieldMap = caseObj.getDescribe().fields.getMap();
        String value;
        
        for(String tableRow : tableRows){
            List<String> labelNameList = tableRow.split(':');
            if(!labelNameList[1].contains('.')){
                string labelName = labelNameList[1].trim().containsIgnoreCase('toLabel') ? labelNameList[1].trim().removeStart('toLabel(').removeEnd(')') : labelNameList[1].trim();
                fielddataType = fieldMap.get(labelName).getDescribe().getType();
                value=String.ValueOf(caseRecord.get(labelName));
            }
            Boolean isReferenceField =true;
            if(value!=null && fielddataType!=null){
                if( fielddataType == Schema.DisplayType.String) {
                    fieldLabelValueMapping.put(labelNameList[0],value);     
                    isReferenceField=false;  
                }
                if( fielddataType == Schema.DisplayType.PICKLIST) {
                    string labelName = labelNameList[1].trim().containsIgnoreCase('toLabel') ? labelNameList[1].trim().removeStart('toLabel(').removeEnd(')') : labelNameList[1].trim();
                    Map<String,String> valueLabelMap = getTranslatedPicklistMap('Case',labelName);
                    if(labelName =='Status' && caseRecord.RecordType.name == 'Direct Disputes'){
                        value =(Value!= 'Closed')? valueLabelMap.get('Open'):valueLabelMap.get(caseRecord.Status);
                    }
                    else{
                        Value = valueLabelMap.get(value);
                    }
                    fieldLabelValueMapping.put(labelNameList[0],value);
                    isReferenceField=false;  
                }
                
                if( fielddataType == Schema.DisplayType.Integer) {
                    fieldLabelValueMapping.put(labelNameList[0],integer.valueof(value));
                    isReferenceField=false; 
                }
                if( (fielddataType == Schema.DisplayType.Date || fielddataType == Schema.DisplayType.DateTime)) {
                    fieldLabelValueMapping.put(labelNameList[0], Date.ValueOf(value).format());      
                    isReferenceField=false;  
                }
                if( fielddataType == Schema.DisplayType.Currency ||
                    fielddataType == Schema.DisplayType.Double){
                        fieldLabelValueMapping.put(labelNameList[0], Decimal.valueOf(value));
                        isReferenceField=false; 
                }   
                if( fielddataType == Schema.DisplayType.TextArea){
                    fieldLabelValueMapping.put(labelNameList[0], value);
                    isReferenceField=false; 
                }
            }
            if(value==null && !labelNameList[1].contains('.')){
                isReferenceField=false; 
            }
            if(isReferenceField) {
                //sObject sObj = Schema.getGlobalDescribe().get('Case').newSObject() ;
                if(tableType =='Customer Service Detail' && labelNameList[1].containsIgnoreCase('CreatedBy.name')){
                    fieldLabelValueMapping.put(labelNameList[0],System.label.D1_Customer_Service_Label_Case_Detail); 
                }
                else{
                    Object obj = getSobjectField(caseRecord,labelNameList[1]);
                    if(obj != null){//NCP-7805
                        if(labelNameList[1].containsIgnoreCase('D1_Equipment_Issue__r.Name')){ 
                            obj = String.valueOf(obj).substringBefore('[').trim();
                        }
                    fieldLabelValueMapping.put(labelNameList[0],obj);   
                }     
            }
            }
            fielddataType=null;
        }
        return fieldLabelValueMapping;
    }
    @AuraEnabled
    public static Object getSobjectField(Case caseObj, String fieldRef) {//NCP-6735
        List<String> fieldList  = fieldRef.split('\\.');
        Sobject sObjNode =caseObj;
        for (Integer i=0; i < fieldList.size() -1; i++) { //get the sObject reference of all chained fields like field1.field2.field3
            sObjNode   = (Sobject) sObjNode.getSobject(fieldList[i]);  // intermediate fields are sobjects
            if (sObjNode == null) { //US 150154:PMD Fix
                return null;
            }
        }
        return sObjNode.get(fieldList[fieldList.size()-1]); //will return the value by getting value of lastStringName from previous Object reference
    }
    @AuraEnabled
    public static Map<String,String> getTranslatedPicklistMap(String objectName,String apiName){//NCP-6735
        Schema.SObjectType caseObj = Schema.getGlobalDescribe().get(objectName);
        Map<String, Schema.SObjectField> fieldMap = caseObj.getDescribe().fields.getMap();
        Schema.DescribeFieldResult fieldResult = fieldMap.get(apiName).getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }
        return valueLabelMap;
    }
    @AuraEnabled
    public static FeedItem createCaseFeed(Id caseRecId, String feedBody, Boolean isClosed){        
        Savepoint sp = Database.setSavepoint();
        FeedItem caseFeed = new FeedItem();
        caseFeed.ParentId = caseRecId;
        caseFeed.Body = feedBody;
        if(UserInfo.getUserType() == 'PowerCustomerSuccess'){            
            caseFeed.Visibility = 'AllUsers';
        }
        Case caseRec;
        try {
            if (isClosed) {
                caseRec = new Case(Id = caseRecId, Status='Re-Opened', D1_CaseFeedLastUpdated__c = system.now() );  // NCP-2915              
            }else{                                                                                                  // NCP-2915
                caseRec = new Case(Id = caseRecId, D1_CaseFeedLastUpdated__c = system.now());                       // NCP-2915
            }                                                                                                       // NCP-2915
            update caseRec;                                                                                         // NCP-2915
            insert caseFeed;
            return caseFeed;
        } catch (Exception ex) {
            Database.rollback(sp);
            return null;
        }                
    }

    @AuraEnabled
    public static void createFeedAttachment(Id feedId, Id contentDocId, Id caseRecId){
        String libraryName = 'Case';
       
        ContentWorkspace contentWorkSpc = [SELECT Id FROM ContentWorkspace where name = :libraryName LIMIT 1];

        ContentWorkspaceDoc newWorkspaceDoc = new ContentWorkspaceDoc();
        newWorkspaceDoc.ContentWorkspaceId = contentWorkSpc.Id; 
        newWorkspaceDoc.ContentDocumentId = contentDocId;
        insert newWorkspaceDoc;        

        ContentDocumentLink cdl = New ContentDocumentLink();
        cdl.LinkedEntityId = caseRecId;
        cdl.ContentDocumentId = contentDocId;
        cdl.shareType = 'V';
        Insert cdl; 
                
        Id contentVersionId = [SELECT Id from ContentVersion where ContentDocumentId = :contentDocId].Id;
        FeedAttachment feedContent = new FeedAttachment();
        feedContent.FeedEntityId = feedId;
        feedContent.RecordId = contentVersionId;
        feedContent.Type = 'CONTENT'; 
        insert feedContent;       
    }

    @AuraEnabled
    public static void removeContentDocument(Id contentDocId){
        delete [SELECT Id FROM ContentDocument WHERE Id = :contentDocId];
    }

    /*  
    * @userstory:  NCP-1836
    * @discription:  get user related D1_User_Type__c record
    * @Param: none
    * @returns: User related D1_User_Type__c record
    * @throws: Nil   
    */
    @AuraEnabled
    public static D1_User_Type__c getUserTypeInfo(){
        List<User> userList = [Select D1_User_Type_Id__c,Name,LanguageLocaleKey,Available_Countries__c from user where D1_User_Type_Id__c !=Null AND id=:UserInfo.getUserId()];
        if( !userList.isEmpty() ){
            List<D1_User_Type__c> d1UserTypeList = [SELECT Enable_Fault_Fixer__c,Fault_Fixer_Label__c,User_Type__c,D1_Setting__r.Market__r.Code__c
                                                    FROM D1_User_Type__c 
                                                    WHERE Id =:userList[0].D1_User_Type_Id__c];
            
            if( !d1UserTypeList.isEmpty() ){
                return d1UserTypeList[0];
            }
        }

        return null;
    }
    //Commenting getDescribeDataCategoryGroupStructureResults() & getAllCategories() as part of NCP-8210
    /*   
    //Method used to create mapping between Topic & Sub-Topic
    public static Map< string, List<String>> getDescribeDataCategoryGroupStructureResults(){    
        List<DescribeDataCategoryGroupResult> describeCategoryResult;
        List<DescribeDataCategoryGroupStructureResult> describeCategoryStructureResult;
        List<DataCategory> dataCategories = new List<DataCategory>();
        List<string> topicName =  new List<string>();
        Map< string, List<String>> mapTopicSubTopic = new Map< string, List<String>>(); 
        try {
            List<String> objType = new List<String>();
            objType.add('KnowledgeArticleVersion');
            describeCategoryResult = Schema.describeDataCategoryGroups(objType);
            List<DataCategoryGroupSobjectTypePair> pairs = new List<DataCategoryGroupSobjectTypePair>();
            
            for(DescribeDataCategoryGroupResult singleResult : describeCategoryResult){
                DataCategoryGroupSobjectTypePair p = new DataCategoryGroupSobjectTypePair();
                p.setSobject(singleResult.getSobject());
                p.setDataCategoryGroupName('Topics');
                pairs.add(p);
            }
            
            describeCategoryStructureResult = Schema.describeDataCategoryGroupStructures(pairs, false);
            
            for(DescribeDataCategoryGroupStructureResult singleResult : describeCategoryStructureResult){
               
                DataCategory [] toplevelCategories = singleResult.getTopCategories();
                for(DataCategory category : toplevelCategories) {
                    DataCategory [] childCategories = category.getChildCategories();
                    
                    for(DataCategory str : childCategories ){
                        dataCategories.add(str);
                        topicName.add(str.getName());
                    }
                }
                    
                List<DataCategory> allCategories = getAllCategories(dataCategories);
                for(DataCategory category : allCategories) {
                    if(topicName.indexOf(category.getName()) == -1){
                        break;
                    }

                    DataCategory [] childCategories = category.getChildCategories();
                    List<string> categories = new List<string>();
                    List<String> subTopicCategories = new List<String>();
                    for(DataCategory str : childCategories ){
                        categories.add(str.getName());                          
                        subTopicCategories.add(str.getLabel());                            
                    }
                    mapTopicSubTopic.put(category.getLabel(),subTopicCategories);
                }
            }
            
        } catch (Exception e){
            throw new AuraHandledException(e.getMessage());
        }
        return mapTopicSubTopic;
    }

    //Method used to create
    private static DataCategory[] getAllCategories(DataCategory [] categories){
        if(categories.isEmpty()){
            return new DataCategory[]{};
        } else {
            DataCategory [] categoriesClone = categories.clone();
            DataCategory category = categoriesClone[0];
            DataCategory[] allCategories = new DataCategory[]{category};
            categoriesClone.remove(0);
            categoriesClone.addAll(category.getChildCategories());
            allCategories.addAll(getAllCategories(categoriesClone));
            return allCategories;
        }
    }
    */

    /*  
    * @userstory:  NCP-8210 / ADO - 114677
    * @discription:  New Controller for fetching Topics and sub-Topics for Help and Support
    * @Param: none
    * @return: Map of Topics and SubTopics 
    */
    @AuraEnabled
    public static caseTypeAndSubTypeWrp getTopicsSubTopicsNew(){
        caseTypeAndSubTypeWrp wrapRec = new caseTypeAndSubTypeWrp();
        wrapRec.usrType = '';
        wrapRec.caseTypes = new Set<String>();
        wrapRec.caseSubTypes = new Set<String>();
        wrapRec.listOftypeSubtypeMap = new List<TopicWrapper>();
        
        try{
            //Query & Set required User Data
            User currUsr = [SELECT D1_User_Type__c, D1_User_Type_Id__c, Available_Countries__c, LanguageLocaleKey 
                            FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
            
            String userCountry = currUsr.Available_Countries__c.split(';')[0]; //If Multiple Countries assigned, take first one
            wrapRec.usrType = currUsr.D1_User_Type__c;

            //Get Available Case Type & Sub Types From D1 User Type Record assigned with User Lang & Market specificed D1Setting
            List<D1_User_Type__c> d1UserType = new List<D1_User_Type__c>();
            Set<String> caseTypeAvl;
            Set<String> caseSubTypeAvl;

            d1UserType = [SELECT Id, Case_Type__c, Case_Subtype__c FROM D1_User_Type__c 
                          WHERE Id =: currUsr.D1_User_Type_Id__c AND Case_Type__c != NULL AND Case_Subtype__c != NULL];
            
            if(d1UserType.isEmpty()){
                return wrapRec;
            }
            else{
                caseTypeAvl = new Set<String>(d1UserType[0].Case_Type__c.split(';'));
                caseSubTypeAvl = new Set<String>(d1UserType[0].Case_Subtype__c.split(';'));
            }

            //Get Knowledge Articles Tagged with Market DataCategories only - Fields DataCategoryGroupName & DataCategoryName cant be added in Query Filter
            //Publish Status Online and IsMasterLanguage = true will give us the latest version of Knowledge article available in primary language
            Set<Id> articlesAvlForMarket = new Set<Id>();
            for(Knowledge__DataCategorySelection dataCatRec : [SELECT Id, ParentId, DataCategoryGroupName, DataCategoryName FROM Knowledge__DataCategorySelection
                                                               WHERE ParentId != NULL AND Parent.PublishStatus = 'Online' AND Parent.IsMasterLanguage = true])
            {
                if(dataCatRec.DataCategoryGroupName == 'Market' && dataCatRec.DataCategoryName == userCountry){
                    articlesAvlForMarket.add(dataCatRec.ParentId);
                }
            } 
            
            //As SubType cannot be empty in Knowledge Article, so market should avail subtype in User Type, process only if market added type & subtype
            if(!articlesAvlForMarket.isEmpty() && !caseTypeAvl.isEmpty() && !caseSubTypeAvl.isEmpty()){
                Boolean hasFinanPerm = FeatureManagement.checkPermission('Financial_Documents');
                Boolean hasOrderPerm = FeatureManagement.checkPermission('Ordering');
                Boolean hasPOSPerm = FeatureManagement.checkPermission('POS_Equipment_Ordering');
                Boolean hasTOPerm = FeatureManagement.checkPermission('Transfer_Orders');

                //Filter case type values based upon user permission 
                if(caseTypeAvl.contains('My Financials') && !hasFinanPerm){
                    caseTypeAvl.remove('My Financials');
                }
                if(caseTypeAvl.contains('My Orders') && !(hasOrderPerm || hasPOSPerm || hasTOPerm)){
                    caseTypeAvl.remove('My Orders');
                }
                
                //Get Details of knowledge Articles which are applicable for User Market & whose Type & SubType belongs to Market Available Type & SubType
                Map<Id,Knowledge__kav> knwArticleMap = new Map<Id,Knowledge__kav>([SELECT Id, UrlName, Case_Type__c, Article_Types__c
                                                                                   FROM Knowledge__kav WHERE Id IN: articlesAvlForMarket 
                                                                                   AND Case_Type__c IN: caseTypeAvl AND Article_Types__c IN: caseSubTypeAvl]);
                
                //Get Latest Translated Article versions, PublishStatus = 'Online' will ensure latest Translated version
                Map<Id, Id> translatedVrsnMap = new Map<Id, Id>();
                for(KnowledgeArticleVersion knwVrsn : [SELECT Id, MasterVersionId FROM KnowledgeArticleVersion WHERE PublishStatus = 'Online' 
                                                       AND Language =: currUsr.LanguageLocaleKey AND MasterVersionId IN :knwArticleMap.keySet()])
                {
                    translatedVrsnMap.put(knwVrsn.MasterVersionId, knwVrsn.Id);
                }

                //Get Translation Map for case type & subtypes
                Map<String,String> caseTypeTrnsl = getTranslatedPicklistMap('Knowledge__kav','Case_Type__c');
                Map<String,String> caseSubTypeTrnsl = getTranslatedPicklistMap('Knowledge__kav','Article_Types__c');

                //Prepare Topic Wrapper Map
                Map<String, TopicWrapper> topicWrpMap = new Map<String, TopicWrapper>();
                for(String knwRecId : knwArticleMap.keySet()){
                    Knowledge__kav knwArticle = knwArticleMap.get(knwRecId);

                    TopicWrapper topicWrp;
                    if(topicWrpMap.containsKey(knwArticle.Case_Type__c)){
                        topicWrp = topicWrpMap.get(knwArticle.Case_Type__c);
                    }
                    else{
                        topicWrp = new TopicWrapper();
                        topicWrp.name = knwArticle.Case_Type__c;
                        topicWrp.label = caseTypeTrnsl.get(knwArticle.Case_Type__c); //Take translated Label if available
                        topicWrp.subTopicList = new List<KnowledgeWrapper>();
                    }

                    KnowledgeWrapper subTopicWrp = new KnowledgeWrapper();
                    subTopicWrp.id = translatedVrsnMap.containsKey(knwRecId) ? translatedVrsnMap.get(knwRecId) : knwRecId; //Take Translted version if available, else the one in primary lang
                    subTopicWrp.name = knwArticle.Article_Types__c;
                    subTopicWrp.label = caseSubTypeTrnsl.get(knwArticle.Article_Types__c); //Take translated Label if available
                    subTopicWrp.url = knwArticle.UrlName;

                    topicWrp.subTopicList.add(subTopicWrp);
                    topicWrpMap.put(knwArticle.Case_Type__c, topicWrp);
                }

                wrapRec.caseTypes = caseTypeAvl;
                wrapRec.caseSubTypes = caseSubTypeAvl;
                wrapRec.listOftypeSubtypeMap = topicWrpMap.values();
            }
            return wrapRec;
        }
        catch(Exception ex){
            throw new AuraHandledException(ex.getMessage()+' line '+ex.getLineNumber());
        }
    }


    //Commenting getTopicsSubTopics() as part of NCP-8210
    /*  
    * @userstory:  NCP-3906
    * @discription:  Controller for fetching Topics and sub-Topics for Help and Support
    * @Param: none
    * @return: Map of Topics and SubTopics
    * @Throws: Nil   
    */
    /*
    @AuraEnabled
    public static List<TopicWrapper> getTopicsSubTopics(){
        try {
            Boolean hasFinancialPermission = FeatureManagement.checkPermission('Financial_Documents');
            Boolean hasOrderingPermission = FeatureManagement.checkPermission('Ordering');
            Boolean hasPOSOrderingPermission = FeatureManagement.checkPermission('POS_Equipment_Ordering');
            Boolean hasTransferOrderingPermission = FeatureManagement.checkPermission('Transfer_Orders');
            Set<Id> topicAssignmentIds = new Set<Id>();
            string language = ''; 
            string userType = '';
            List<String> listAvailableCountry = new List<String>();
            
            Map<Id, String> topicMap = new Map<Id, String>();
            String networkId = [SELECT Id FROM Network WHERE Name = 'DiageoOne'].Id;
            String topicNameFilter = System.label.Country_UserType_Topic_Name_Filter; //GB;Direct;InDirect;NIR;IE;DE;ES
            List<String> listOfTopicNameFilter = topicNameFilter.split(';');
            //Get User Details
            List<User> userList = [SELECT D1_User_Type__c,Available_Countries__c,LanguageLocaleKey FROM User WHERE D1_User_Type__c!=null AND Id =:UserInfo.getUserId()]; //'0057Z000007rscdQAA' :UserInfo.getUserId()
            if(userList.size()>0){
                language = userList[0].LanguageLocaleKey;
                listAvailableCountry = userList[0].Available_Countries__c.split(';');
                
                if(userList[0].D1_User_Type__c == 'Outlet/Retailers'){
                    userType = 'InDirect';
                }else if(userList[0].D1_User_Type__c == 'Direct Buyer'){
                    userType = 'Direct';
                }            
            }
            
            //Topic & Sub-Topic Map 
            Map<String, List<String>> topicSubTopicMap = getDescribeDataCategoryGroupStructureResults();
            
            //KB: Can we not put country code filter in query itself instead of query only 1000 and then checking
            //Implementation restriction: TopicAssignment only allows security evaluation for non-admin users when either (1) LIMIT is specified and at most 1000 or (2) WHERE is specified and filter on Id or Entity
            //Get Country Specific List of Knwoledge Ids NCP-6489
            for(TopicAssignment topicAssRecd : [SELECT EntityId, Topic.Name, NetworkId FROM TopicAssignment WHERE NetworkId =:networkId AND Topic.Name IN :listAvailableCountry AND EntityType = 'Knowledge' ORDER BY CreatedDate DESC LIMIT 1000]){ //LIMIT 1000
                topicAssignmentIds.add(topicAssRecd.EntityId);
            }
            
            //Get Market and User Type Related Knowledge Articles (Filter Published Article applicable to User Type)
            Map<Id, KnowledgeArticleVersion> knowledgeArticleMap = new Map<Id, KnowledgeArticleVersion>([SELECT Title, ArticleNumber, UrlName, Id, IsMasterLanguage, ArticleMasterLanguage, Language FROM KnowledgeArticleVersion WHERE PublishStatus = 'Online' AND Id IN (SELECT EntityId FROM TopicAssignment WHERE EntityId IN :topicAssignmentIds AND Topic.Name =:userType) AND IsMasterLanguage=true]);
            if(Test.isRunningTest()){
                knowledgeArticleMap = new Map<Id, KnowledgeArticleVersion>([SELECT Title, ArticleNumber, UrlName, Id FROM KnowledgeArticleVersion WHERE Id in (SELECT EntityId FROM TopicAssignment WHERE EntityId IN :topicAssignmentIds AND Topic.Name =:userType)]);
            }

            //Get All related tags of Knowledge Article for that Market
            Map<Id, List<String>> knowledgeTopicMap = new Map<Id, List<String>>();
            List<String> topicAssignmentList = new List<String>();
            for(TopicAssignment topicAssignment : [SELECT Id, EntityId, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId IN :knowledgeArticleMap.keySet() AND EntityType = 'Knowledge' AND NetworkId =:networkId ORDER BY EntityId ]){//0DB3W000000CaTNWA0 : networkId
                Boolean orderDisabled = (topicAssignment.Topic.Name == 'My Orders' && !(hasOrderingPermission || hasPOSOrderingPermission || hasTransferOrderingPermission));                
                Boolean finalcialDisabled = (topicAssignment.Topic.Name == 'My Financials' && !hasFinancialPermission);
                if (!(orderDisabled || finalcialDisabled)){   
                    topicMap.put(topicAssignment.TopicId, topicAssignment.Topic.Name);
                    topicAssignmentList.add(topicAssignment.Topic.Name);
                }
                
                //Create Knwoledge Article Map with Topic Names excluding Country & User Type Topics (My Account, Account Management)
                if(!listOfTopicNameFilter.contains(topicAssignment.Topic.Name)){
                    if(knowledgeTopicMap.containsKey(topicAssignment.EntityId)){
                        knowledgeTopicMap.get(topicAssignment.EntityId).add(topicAssignment.Topic.Name);
                    }else{
                        knowledgeTopicMap.put(topicAssignment.EntityId, new List<String>{topicAssignment.Topic.Name});
                    }              
                }
            }
            
            //Converting knowledgeTopicMap to topicKnowledgeArticleMap
            Map<String, Id> topicKnowledgeArticleMap = new Map<String, Id>();
            for(Id knowledgeId : knowledgeTopicMap.keySet()){
                List<String> topicSet = knowledgeTopicMap.get(knowledgeId);
                List<String> topicList = new List<String>();
                List<String> subTopicList = new List<String>();
                
                for(String str : topicSet){
                    if(topicSubTopicMap.containsKey(str)){
                        topicList.add(str);
                        if(str == 'Product Information'){
                            subTopicList.add(str);
                        }
                    }else{
                        subTopicList.add(str);
                    }
                }
                if(Test.isRunningTest()){
                   topicList.add('General'); 
                }
                
                for(String topic : topicList){
                    for(String subtopic : subTopicList) {
                        string topicSubTopicKey = topic + '_' + subtopic;
                        topicKnowledgeArticleMap.put(topicSubTopicKey, knowledgeId); 
                    }
                }
            }
                
            //Get Topic Localization
            Map<String, String> topicLocalizationMap = new Map<String, String>();
            for(TopicLocalization topicLocalization : [SELECT ParentId, Parent.Name, Value FROM TopicLocalization WHERE Language =: language AND ParentId IN :topicMap.keySet()]){
                topicLocalizationMap.put(topicLocalization.Parent.Name, topicLocalization.Value);
            }

            //Get Translated Knowledge Article (NCP-6488)
            Map<Id, Id> translatedKnowledgeArticleMap = new Map<Id, Id>();
            for(KnowledgeArticleVersion know : [SELECT Title, ArticleNumber, UrlName, Id, IsMasterLanguage, ArticleMasterLanguage, Language, MasterVersionId FROM KnowledgeArticleVersion 
                                                WHERE PublishStatus = 'Online' AND Language =:language AND MasterVersionId IN :knowledgeTopicMap.keySet()])
            {
                translatedKnowledgeArticleMap.put(know.MasterVersionId, know.Id);
            }
            
           
            
            
            //Create Wrapper
            List<TopicWrapper> topicWrapperList = new List<TopicWrapper>();
            for(String topic : topicSubTopicMap.keySet()){
                if(topicAssignmentList.contains(topic)){
                    String topicName = topic;
                    if(topicLocalizationMap.size()>0 && topicLocalizationMap.containsKey(topic)){
                        topicName = topicLocalizationMap.get(topic);
                    }
                    List<KnowledgeWrapper> knowledgeWrapperList = new List<KnowledgeWrapper>();
                    for(String subTopic : topicSubTopicMap.get(topic)){
                        string key = topic + '_' + subTopic;
                        //Check this key in topicKnowledgeArticleMap to get associated Knowledge Id
                        if(topicKnowledgeArticleMap.containsKey(key)){
                            Id articleId = topicKnowledgeArticleMap.get(key);
                            String SubTopicName = subTopic;
                            if(topicLocalizationMap.size()>0 && topicLocalizationMap.containsKey(subTopic)){
                                SubTopicName = topicLocalizationMap.get(subTopic);
                            } 
                            //Create KnwoledgeWrapper Instance
                            KnowledgeWrapper knowledgeWrapper = new KnowledgeWrapper();
                            //knowledgeWrapper.id = topicKnowledgeArticleMap.get(key);
                            knowledgeWrapper.id = translatedKnowledgeArticleMap.containsKey(articleId) ? translatedKnowledgeArticleMap.get(articleId) : articleId; //NCP-6488
                            knowledgeWrapper.name = subTopic;
                            knowledgeWrapper.label = SubTopicName;
                            knowledgeWrapper.url = knowledgeArticleMap.get(articleId).UrlName;
                            
                            knowledgeWrapperList.add(knowledgeWrapper);
                        }
                    }
                    //Create TopicWrapper Instance
                    if(knowledgeWrapperList.size()> 0){
                        TopicWrapper topicWrapper = new TopicWrapper();
                        topicWrapper.label = topicName;
                        topicWrapper.name = topic;
                        topicWrapper.subTopicList = knowledgeWrapperList;
                        
                        //Add TopicWrapper to topicWrapperList
                        topicWrapperList.add(topicWrapper);
                    }
                }
            }
            return topicWrapperList;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    */

    /*  
    * @userstory:  NCP-3906, NCP-6489 [Rewrite this method]
    * @discription:  Controller for fetching Links of Sub Topics for Help and Support Article Detail
    * @Param: articleId
    * @return: Map of Topics and SubTopics
    * @Throws: Nil   
    */

    @AuraEnabled
    public static TopicWrapper getLinks(String articleId, String topicName){
        try {
            TopicWrapper topicWrapperr = new TopicWrapper();
            Map<Id, String> topicNameMap = new Map<Id, String>();
            List<String> topicNameList = new List<String>();
            
            /*  
             @ commenting below code(for NCP-8214) as this is not required as per new architecture design to show suggested knowledge article 
                    
             Get Network Id
             String networkId = [SELECT Id FROM Network WHERE Name = 'DiageoOne'].Id;

             Get List of Topic Assignment for current Article
             for(TopicAssignment topicAssignment : [SELECT Id, EntityId, TopicId, Topic.Name FROM TopicAssignment WHERE EntityId =:articleId AND EntityType = 'Knowledge' AND NetworkId =: networkId]){
             topicNameMap.put(topicAssignment.TopicId, topicAssignment.Topic.Name);
             }

             Create TopicNameList
             topicNameList = topicNameMap.values();
            */

            //Get List of all Topic and associated Sub-Topic
            caseTypeAndSubTypeWrp typeSubtypeWrap = getTopicsSubTopicsNew();
            List<TopicWrapper> topicWrapperList = typeSubtypeWrap.listOftypeSubtypeMap;  // NCP-8214 Calling new method to get list of topic and sub topic.

            //Filter related Topic and Sub-Topic List
            for(TopicWrapper topicWrapper : topicWrapperList){
                if((String.isBlank(topicName) || (String.isNotBlank(topicName) && topicName == topicWrapper.label))){
                    List<KnowledgeWrapper> subTopicList = new List<KnowledgeWrapper>();
                    for(KnowledgeWrapper knowledgeWrapper : topicWrapper.subTopicList){
                        if(knowledgeWrapper.id != articleId){
                            subTopicList.add(knowledgeWrapper);
                        }
                    }
                    topicWrapperr = topicWrapper;
                    topicWrapperr.subTopicList = subTopicList;

                    break;
                }
            }

            return topicWrapperr;
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
    }
    /*  
    * @userstory:  NCP-6841,NCP-6842
    * @discription: Retrieving the pick up options related to Reason For Cancellation
    * @Param: Nil
    * @return: List<ReasonForCancellationOptionsWrapper>
    * @Throws: Nil   
    */
    @AuraEnabled
    public static List<ReasonForCancellationOptionsWrapper> getPickUpOptionsList(){
        User usr = [SELECT Id,Available_Countries__c,LanguageLocaleKey FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        List<Pick_Up_Options__c> listOptions = [SELECT id,Name,RecordType.Name,Geography__r.Code__c from Pick_Up_Options__c 
                                                where RecordType.Name= 'Reason For Cancellation' 
                                                AND Status__c = 'Active'
                                                AND Geography__r.Code__c=:usr.Available_Countries__c ORDER BY Name ASC];
        List<Pick_Up_Options__c> translatedListOptions = D1_TranslationsUtility.updateTranslationsInRecords(listOptions);
        List<ReasonForCancellationOptionsWrapper> reasonForCancellationOptionsWrapperList = new List<ReasonForCancellationOptionsWrapper>();

        for(Pick_Up_Options__c option : translatedListOptions){
            ReasonForCancellationOptionsWrapper reasonForCancellationOptionsWrapperRecord = new ReasonForCancellationOptionsWrapper();
            reasonForCancellationOptionsWrapperRecord.label = option.Name.substringBefore(' [');
            reasonForCancellationOptionsWrapperRecord.name = option.Name;

            reasonForCancellationOptionsWrapperList.add(reasonForCancellationOptionsWrapperRecord);
        }
        if(reasonForCancellationOptionsWrapperList.size()>0){
            return reasonForCancellationOptionsWrapperList;
        }
        return null;
    }
    /*  
    * @userstory:  NCP-6841,NCP-6842
    * @discription: Set up the pick up options related to Reason For Cancellation to store value in record
    * @Param: String
    * @return: ID
    * @Throws: Nil   
    */
    @AuraEnabled
    public static ID getPickUpOptionsRecord(String selReasonInput){
        User usr = [SELECT Id,Available_Countries__c,LanguageLocaleKey FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
        String updatedValue = selReasonInput ;
        //+ ' [' + usr.Available_Countries__c + ']';
        List<Pick_Up_Options__c> newRecordList = [SELECT id,Name,RecordType.Name,Geography__r.Code__c from Pick_Up_Options__c 
                                        where RecordType.Name= 'Reason For Cancellation' 
                                        AND Status__c = 'Active'
                                        AND Geography__r.Code__c=:usr.Available_Countries__c];
        List<Pick_Up_Options__c> translatedListOptions = D1_TranslationsUtility.updateTranslationsInRecords(newRecordList);

        for(Pick_Up_Options__c val : translatedListOptions){
            if(val.Name == updatedValue){
                return val.Id;
            }
        }
        return null;
    }
}