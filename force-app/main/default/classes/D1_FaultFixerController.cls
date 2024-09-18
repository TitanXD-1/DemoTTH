/*
* @name D1_FaultFixerController
* @description D1_FaultFixerController Class for Fault Fixer related lwc
* @history
* VERSION     AUTHOR              DATE              DETAIL
* 1.0         Mukesh Kanth        22/02/20
* 1.0         Gaurav              24/02/20
* 1.0		  Ajay				  25/02/21        NCP-1871
* 2.0         Ajay                13/09/21        NCP-4264
* */ 
public without sharing class D1_FaultFixerController {

    /**
     * Sl.NO        SECTIONS                Description            Page
     *  
     *  1.      SECTION-CATEGORY            Fault Fixer            Page 1
     *  2.      SECTION-ISSUE               Fault Fixer Issues     Page 2
     *  3.      SECTION-GUIDED_HELP         Guided Help            Page 3
     *  4.      SECTION-TROUBLESHOOTING     Troubleshooting        Page 4
     *  5.      SECTION-SUCCESS/FAILURE     Success/Failure        Page 4
     **/

    /**ooooooooooooooooooooooooooooooooooooooooooooo
     *  SECTION-CATEGORY
     **ooooooooooooooooooooooooooooooooooooooooooooo*/

    public static String faultFixerCategpryRT        = 'Category';
    public static String faultFixerSubcategoryRT     = 'Sub_Category';
    public static String faultFixerIssueRT           = 'Issue';
    public static String faultFixerDiagonsisRT       = 'Diagnosis';

    final static String RECORD_TYPE_CATEGORY ='Category';
    final static String RECORD_TYPE_SUB_CATEGORY ='Sub Category';
    final static String RECORD_TYPE_ISSUE ='Issue';
    final static String RECORD_TYPE_DIAGNOSIS ='Diagnosis';
    final static String RECORD_TYPE_TROUBLESHOOTING_STEPS ='Troubleshooting Steps';

    /*
    * @name D1_FaultFixerController
    * @description Wrapper for Fault Fixer Landing Page data
    */
    public class FFLanding_InitWrapper{
        @AuraEnabled public String faultFixerTitle                          {get;set;}
        @AuraEnabled public List<FFLanding_CategoryWrapper> categoryList       {get;set;}

        public FFLanding_InitWrapper( String faultFixerTitle, List<FFLanding_CategoryWrapper> categoryList ){
            this.faultFixerTitle = faultFixerTitle;
            this.categoryList = categoryList;
        }
    }

    /*
    * @name FFLanding_CategoryWrapper
    * @description Wrapper for Fault Fixer Landing Page Category data
    */
    public class FFLanding_CategoryWrapper{
        @AuraEnabled public Id categoryId                           {get;set;}
        @AuraEnabled public String title                            {get;set;}
        @AuraEnabled public Integer subCategoryCount                {get;set;}
        @AuraEnabled public List<FFLanding_SubcatagoryWrapper> subCategoryList   {get;set;}

        public FFLanding_CategoryWrapper( D1_Fault_Fixer__c category ,Integer subCategoryCount){
            this.categoryId = category.Id;
            this.title = category.Display_Title__c;
            this.subCategoryCount = subCategoryCount;

            subCategoryList = new List<FFLanding_SubcatagoryWrapper>();
        }
    }

    /*
    * @name FFLanding_SubcatagoryWrapper
    * @description Wrapper for Fault Fixer Landing Page Sub Category data
    */
    public class FFLanding_SubcatagoryWrapper{
        @AuraEnabled public Id subCategoryId        {get;set;}
        @AuraEnabled public String title            {get;set;}
        @AuraEnabled public String contentId        {get;set;}
        @AuraEnabled public String imageURL         {get;set;}

        public FFLanding_SubcatagoryWrapper( D1_Fault_Fixer__c subCategory ){
            this.subCategoryId = subCategory.Id;
            this.title = subCategory.Display_Title__c;
            this.contentId = subCategory.Sub_Category_Image_Content_ID__c;
        }
    }

    
    /**
     * @description Get UserType Info
     * @return D1_User_Type__c
     */
    private static D1_User_Type__c getUserType(){
        List<User> userList = [SELECT D1_User_Type_Id__c FROM User WHERE id=: UserInfo.getUserId()];
        if(userList.isEmpty()){
            throw new AuraHandledException('Access denied(User)');
        }

        List<D1_User_Type__c> d1UserTypeList = [SELECT Fault_Fixer_Label__c, D1_Setting__r.Market__c 
                                                FROM D1_User_Type__c 
                                                WHERE Id =:userList[0].D1_User_Type_Id__c];
        if(d1UserTypeList.isEmpty()){
            throw new AuraHandledException('Invalid configuration(User Type)');
        }

        return d1UserTypeList[0];
    }

    /**
     * @description Prepare Fault Fixer Landing Page data
     * @return Instance of FFLanding_InitWrapper Inner class.
     */
    @AuraEnabled(cacheable=true)
    public static FFLanding_InitWrapper getFaultFixerLandingPageInitInfo( ){
        try{

            D1_User_Type__c d1UserType = getUserType();
            Set<Id> faultFixerCategoryIds = new Set<Id>();
            for( D1_Content_Assignment__c contentAssignment : [SELECT D1_Fault_Fixer__c 
                                                               FROM D1_Content_Assignment__c 
                                                               WHERE Geography__c =:d1UserType.D1_Setting__r.Market__c
                                                               AND D1_Fault_Fixer__r.RecordType.DeveloperName =:faultFixerCategpryRT] ){
                faultFixerCategoryIds.add(contentAssignment.D1_Fault_Fixer__c);
            }
            
            Set<String> contentIds = new Set<String>();
            List<FFLanding_SubcatagoryWrapper> allSubCategories = new List<FFLanding_SubcatagoryWrapper>();
            List<FFLanding_CategoryWrapper> categoryList = new List<FFLanding_CategoryWrapper>();

            for( D1_Fault_Fixer__c category : [ SELECT id,  Display_Title__c,
                                                (   SELECT id, Display_Title__c, Sub_Category_Image_Content_ID__c 
                                                    FROM D1_Fault_Fixers__r 
                                                    WHERE Active__c = true 
                                                    AND RecordType.DeveloperName = :faultFixerSubcategoryRT 
                                                    ORDER BY Order__c ASC)
                                                FROM D1_Fault_Fixer__c 
                                                WHERE Active__c = true 
                                                AND Id IN:faultFixerCategoryIds 
                                                ORDER BY Order__c ASC] ){
                if( !category.D1_Fault_Fixers__r.isEmpty() ){

                    FFLanding_CategoryWrapper categoryWrapperObj = new FFLanding_CategoryWrapper(category, category.D1_Fault_Fixers__r.size());
                    categoryList.add(categoryWrapperObj);

                    for( D1_Fault_Fixer__c subCategory : category.D1_Fault_Fixers__r ){
                        FFLanding_SubcatagoryWrapper subCategoryWrapper = new FFLanding_SubcatagoryWrapper(subCategory);
                        categoryWrapperObj.subCategoryList.add( subCategoryWrapper );

                        if( String.isNotBlank(subCategory.Sub_Category_Image_Content_ID__c) ){
                            contentIds.add( subCategory.Sub_Category_Image_Content_ID__c );
                            allSubCategories.add(subCategoryWrapper);
                        }
                    }
                }
            }

            String contentType = 'cms_image';
            String contentNodeName = 'source';
            if( !contentIds.isEmpty() ){
                Map<String,Object> contentInfoMap = D1_ContentController.getManagedContentInfoByIds(null, new List<String>(contentIds), null, null, null, contentType, new set<String>{contentNodeName} );
                
                for(FFLanding_SubcatagoryWrapper subcategoryObj: allSubCategories){
                    Map<String,Object> nodeInfoMap = (Map<String,Object>)contentInfoMap.get( subcategoryObj.contentId );
                    if(nodeInfoMap !=null){
                        subcategoryObj.imageURL = ((ConnectApi.ManagedContentMediaSourceNodeValue)nodeInfoMap.get( contentNodeName )).url;
                    }
                }
            }

            return new FFLanding_InitWrapper(d1UserType.Fault_Fixer_Label__c, categoryList);
        }catch( Exception e ){
            throw new AuraHandledException('Failed to load Categories'+e.getMessage()+' -- '+e.getStackTraceString());
        }
    }


    /**ooooooooooooooooooooooooooooooooooooooooooooo
     *  SECTION-ISSUE
     **ooooooooooooooooooooooooooooooooooooooooooooo*/

    /**
     * @name FFSubCategory_InitWrapper
     * @description Wrapper for Fault Fixer Sub Category Page data
     */
    public class FFSubCategory_InitWrapper{
        @AuraEnabled public Id subCategoryId        {get;set;}
        @AuraEnabled public String faultFixerTitle  {get;set;}
        @AuraEnabled public String title            {get;set;}
        @AuraEnabled public String description      {get;set;}
        @AuraEnabled public String issueTitle       {get;set;}
        @AuraEnabled public List<FFSubCategory_IssueWrapper> issuesList    {get;set;}

        public FFSubCategory_InitWrapper( String faultFixerTitle, D1_Fault_Fixer__c subCategory, List<D1_Fault_Fixer__c> subCategoryIssues ){
            this.faultFixerTitle = faultFixerTitle;
            this.subCategoryId = subCategory.Id;
            this.title = subCategory.Display_Title__c;
            this.description = subCategory.Description__c;
            this.issueTitle = subCategory.Issue_Title__c;

            issuesList = new List<FFSubCategory_IssueWrapper>();
            for( D1_Fault_Fixer__c issue : subCategoryIssues ){
                issuesList.add( new FFSubCategory_IssueWrapper(issue) );
            }
        }
    }

    /**
     * @name FFSubCategory_IssueWrapper
     * @description Wrapper for Fault Fixer Sub Category Page Issue data
     */
    public class FFSubCategory_IssueWrapper{
        @AuraEnabled public Id issueId              {get;set;}
        @AuraEnabled public String title            {get;set;}
        @AuraEnabled public Boolean hasDiagnosis    {get;set;}

        @AuraEnabled public List<FFSubCategory_DiagnosisWrapper> diagnosisList    {get;set;}

        public FFSubCategory_IssueWrapper( D1_Fault_Fixer__c issue ){
            this.issueId = issue.Id;
            this.title = issue.Display_Title__c;
            this.hasDiagnosis = (issue.D1_Fault_Fixers__r.isEmpty()? false:true);
            
            diagnosisList = new List<FFSubCategory_DiagnosisWrapper>();
            for( D1_Fault_Fixer__c diagnosis : issue.D1_Fault_Fixers__r ){
                diagnosisList.add( new FFSubCategory_DiagnosisWrapper(diagnosis) );
            }
        }
    }

    /**
     * @name FFSubCategory_DiagnosisWrapper
     * @description Wrapper for Fault Fixer Sub Category Page Diagnosis data
     */
    public class FFSubCategory_DiagnosisWrapper{
        @AuraEnabled public Id diagnosisId      {get;set;}
        @AuraEnabled public String title        {get;set;}

        public FFSubCategory_DiagnosisWrapper( D1_Fault_Fixer__c diagnosis ){
            this.diagnosisId = diagnosis.Id;
            this.title = diagnosis.Display_Title__c;
        }
    }

    /**
     * @description Prepare Fault Fixer Subcategory Page data
     * @param subCategoryId sub category Id
     * @return FFSubCategory_InitWrapper
     */
    @AuraEnabled(cacheable=true)
    public static FFSubCategory_InitWrapper getFaultFixerSubCatPageInitInfo( String subCategoryId ){
        if(String.isEmpty(subCategoryId)){
            throw new AuraHandledException('Invalid SubCategory');
        }

        try{
            
            D1_User_Type__c d1UserType = getUserType();
            D1_Fault_Fixer__c subCategory = [SELECT id, Display_Title__c, Description__c, Issue_Title__c FROM D1_Fault_Fixer__c WHERE Id =:subCategoryId ];

            List<D1_Fault_Fixer__c> issuesList = [ SELECT id,  Display_Title__c, Description__c,
                                                    ( SELECT id, Display_Title__c, Description__c 
                                                      FROM D1_Fault_Fixers__r 
                                                      WHERE Active__c = True 
                                                      AND RecordType.DeveloperName =: faultFixerDiagonsisRT 
                                                      ORDER BY Order__c ASC)
                                                    FROM D1_Fault_Fixer__c 
                                                    WHERE Active__c = True 
                                                    AND Parent__c =: subCategoryId 
                                                    AND RecordType.DeveloperName =: faultFixerIssueRT 
                                                    ORDER BY Order__c ASC];
            
            return new FFSubCategory_InitWrapper(d1UserType.Fault_Fixer_Label__c, subCategory, issuesList);
        }catch( Exception e ){
            throw new AuraHandledException('Failed to load Issues');
        }
    }

    
    /**ooooooooooooooooooooooooooooooooooooooooooooo
     *  SECTION-GUIDED_HELP 
     *  SECTION-TROUBLESHOOTING
     **ooooooooooooooooooooooooooooooooooooooooooooo*/

    /**
     * Fault Fixer Diagnostic, Troubleshoot Page Section & Breadcrumb setup
     * @author Ajay 
     * @userstory NCP-1871,NCP-1873,NCP-2101
     */

    /**
     * @description DiagnosticOrIssueWrapper
     */
    public class DiagnosticOrIssueWrapper{
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String description{get;set;}
        @AuraEnabled public String recordType{get;set;}
        @AuraEnabled public String subCategoryName{get;set;}
        @AuraEnabled public Id subCategoryId{get;set;}

        @AuraEnabled public List<TroubleshootWrapper> troubleshootingSteps{get;set;}

        public DiagnosticOrIssueWrapper(D1_Fault_Fixer__c diagnosticOrIssue){
            this.id = diagnosticOrIssue.id;
            this.name = diagnosticOrIssue.Display_Title__c == null ? '' : diagnosticOrIssue.Display_Title__c;
            this.description = diagnosticOrIssue.Description__c == null ? '' : diagnosticOrIssue.Description__c;
            this.recordType = diagnosticOrIssue.RecordType.Name;

            if(diagnosticOrIssue.RecordType.Name == RECORD_TYPE_ISSUE){
                this.subCategoryName = diagnosticOrIssue.Parent__r.Display_Title__c == null ? '' : diagnosticOrIssue.Parent__r.Display_Title__c;
                this.subCategoryId = diagnosticOrIssue.Parent__r.id;
            }else{
                this.subCategoryName = diagnosticOrIssue.Parent__r.Parent__r.Display_Title__c == null ? '' : diagnosticOrIssue.Parent__r.Parent__r.Display_Title__c;
                this.subCategoryId = diagnosticOrIssue.Parent__r.Parent__r.id;
            }
        }
    }

    /**
     *  @description TroubleshootWrapper
     */
    public class TroubleshootWrapper{
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String description{get;set;}
        @AuraEnabled public Decimal timeRequired{get;set;}
        @AuraEnabled public Boolean isSelected{get;set;}

        public TroubleshootWrapper(D1_Fault_Fixer__c troubleshoot, Boolean isSelected){
            this.id = troubleshoot.id;
            this.name = troubleshoot.Display_Title__c == null ? '' : troubleshoot.Display_Title__c;
            this.description = troubleshoot.Description__c == null ? '' : troubleshoot.Description__c;
            this.timeRequired = troubleshoot.Time_to_Consume__c == null ? 0 : troubleshoot.Time_to_Consume__c;
            this.isSelected = isSelected == true;
        }
    }

    /**
     *  @description TroubleshootContentDetail
     */
    public class TroubleshootContentDetail{
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String content{get;set;}
        @AuraEnabled public String imageUrl{get;set;}
    }

    /**
     *  @description TroubleshootContent
     */
    public class TroubleshootContent{
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String description{get;set;}
        @AuraEnabled public String decisionQuestion{get;set;}

        @AuraEnabled public List<TroubleshootContentDetail> contents{get;set;}

        public TroubleshootContent(D1_Fault_Fixer__c troubleshoot){
            this.id = troubleshoot.id;
            this.name = troubleshoot.Display_Title__c == null ? '' : troubleshoot.Display_Title__c;
            this.description = troubleshoot.Description__c == null ? '' : troubleshoot.Description__c;
            this.decisionQuestion = troubleshoot.Troubleshoot_Decision_Making_Question__c == null ? '' : troubleshoot.Troubleshoot_Decision_Making_Question__c;
            this.contents = new List<TroubleshootContentDetail>();
        }
    }

    /**
     *  @description BreadCrumbWrapper
     */
    public class BreadCrumbWrapper{
        @AuraEnabled public Id id{get;set;}
        @AuraEnabled public String name{get;set;}
        @AuraEnabled public String recordType{get;set;}

        BreadCrumbWrapper(Id id, String name, String recordType){
            this.id = id;
            this.name = name;
            this.recordType = recordType;
        }
    }

    /**
     * @description Retrieve Diaganostic or Issue Object 
     * @author Ajay NCP-1871
     * @param  diagnosticOrIssueOrIssueId
     * @return DiagnosticOrIssueWrapper
     */
    @AuraEnabled(cacheable=true)
    public static DiagnosticOrIssueWrapper getDiagnosticOrIssuePageInfo(String diagnosticOrIssueOrIssueId){
        if(String.isEmpty(diagnosticOrIssueOrIssueId)){
            throw new AuraHandledException('Invalid parameter(diagnosticOrIssueOrIssueId)');
        }
        
        diagnosticOrIssueOrIssueId = String.escapeSingleQuotes(diagnosticOrIssueOrIssueId);
        List<D1_Fault_Fixer__c> diagnosticOrIssuesOrIssues = [SELECT id,Display_Title__c,Description__c,RecordType.Name,
                                                                    Parent__r.Id, Parent__r.Display_Title__c,               
                                                                    Parent__r.Parent__r.Id, Parent__r.Parent__r.Display_Title__c
                                                                    FROM D1_Fault_Fixer__c
                                                                    WHERE Id=:diagnosticOrIssueOrIssueId
                                                                    AND Active__c = true];
        if(diagnosticOrIssuesOrIssues.isEmpty()){
            throw new AuraHandledException('Access denied(diagnosticOrIssuesOrIssues)');
        }

        return getDiagnosticOrIssueWrapper(diagnosticOrIssuesOrIssues[0], null);
    }

    /**
     * Retrieve Diaganostic or Issue Object from Troubleshoot Id
     * @author Ajay NCP-1871
     * @param {String} troubleshootId
     * @return {DiagnosticOrIssueWrapper}
     */
    @AuraEnabled(cacheable=true)
    public static DiagnosticOrIssueWrapper getDiagnosticOrIssueFromTroubleshoot(String troubleshootId){
        if(String.isEmpty(troubleshootId)){
            throw new AuraHandledException('Invalid parameter');
        }

        troubleshootId = String.escapeSingleQuotes(troubleshootId);
        List<D1_Fault_Fixer__c> troubleshoots = [SELECT Parent__r.id,Parent__r.Display_Title__c,Parent__r.Description__c,Parent__r.RecordType.Name,
                                                        Parent__r.Parent__r.Id, Parent__r.Parent__r.Display_Title__c,                  
                                                        Parent__r.Parent__r.Parent__r.Id, Parent__r.Parent__r.Parent__r.Display_Title__c
                                                        FROM D1_Fault_Fixer__c
                                                        WHERE Id=:troubleshootId
                                                        AND Active__c = true];
        if(troubleshoots.isEmpty()){
            throw new AuraHandledException('Access denied');
        }

        return getDiagnosticOrIssueWrapper(troubleshoots[0].Parent__r, troubleshootId);
    }

    /**
     * @description Setup Diagnostic or Issue Object
     * @author Ajay NCP-1871
     * @param sfDiagnosticOrIssueOrIssueObj salesforce DiagnosticOrIssueOrIssueObj
     * @param selectedTroubleshootId Id
     * @return DiagnosticOrIssueWrapper
     */
    private static DiagnosticOrIssueWrapper getDiagnosticOrIssueWrapper(D1_Fault_Fixer__c sfDiagnosticOrIssueOrIssueObj, Id selectedTroubleshootId){
        DiagnosticOrIssueWrapper diagnosticOrIssueOrIssueObj = new DiagnosticOrIssueWrapper(sfDiagnosticOrIssueOrIssueObj);
        
        List<TroubleshootWrapper> troubleshootingSteps = new List<TroubleshootWrapper>();
        for (D1_Fault_Fixer__c troubleshootStep : [ SELECT Id,Display_Title__c,Description__c,Time_to_Consume__c
                                                    FROM D1_Fault_Fixer__c
                                                    WHERE Parent__c =: diagnosticOrIssueOrIssueObj.id
                                                    AND Active__c = true
                                                    ORDER BY Order__c ASC]) 
        {
            troubleshootingSteps.add( new TroubleshootWrapper(troubleshootStep,selectedTroubleshootId == troubleshootStep.id));
        }

        diagnosticOrIssueOrIssueObj.troubleshootingSteps = troubleshootingSteps;
        return diagnosticOrIssueOrIssueObj;
    }

    /**
     * @description Retrieve Troubleshoot content
     * @author Ajay NCP-1871
     * @param troubleshootId
     * @param communityId
     * @param language
     * @param contentType
     * @return TroubleshootContent
     */
    @AuraEnabled(cacheable=true)
    public static TroubleshootContent getTroubleshootStepContent(String troubleshootId, String communityId, String language, String contentType){
        final String contentType1 = 'Troubleshoot_Content';
        
        if(String.isEmpty(troubleshootId) || String.isEmpty(communityId)){
            throw new AuraHandledException('Invalid parameter');
        }

        language = String.isEmpty(language) ? UserInfo.getLanguage() : language;
        contentType = String.isEmpty(contentType) ? contentType1 : contentType;

        troubleshootId = String.escapeSingleQuotes(troubleshootId);
        communityId = String.escapeSingleQuotes(communityId);
        language = String.escapeSingleQuotes(language);
        contentType = String.escapeSingleQuotes(contentType);

        List<D1_Fault_Fixer__c> troubleshoots = [SELECT id,Display_Title__c,Description__c,Content_IDs__c,Troubleshoot_Decision_Making_Question__c
                                                FROM D1_Fault_Fixer__c
                                                WHERE Id=:troubleshootId
                                                AND Active__c = true];
        
        if(troubleshoots.isEmpty()){
            throw new AuraHandledException('Access denied');
        }

        D1_Fault_Fixer__c troubleshoot = troubleshoots[0];
        TroubleshootContent troubleshootContentObj = new TroubleshootContent(troubleshoot);
        
        if(String.isEmpty(troubleshoot.Content_IDs__c)){
            return troubleshootContentObj;
        }
        troubleshoot.Content_IDs__c = troubleshoot.Content_IDs__c.trim();

        List<Id> requestedContentIds = troubleshoot.Content_IDs__c.split(';');
        ConnectApi.ManagedContentVersionCollection collection = ConnectApi.ManagedContent.getManagedContentByIds(communityId,
            requestedContentIds,
            null,
            null,
            language,
            contentType
            );

        troubleshootContentObj.contents = processTroubleshootCMSContent(collection, requestedContentIds);
        return troubleshootContentObj;
    }

    /**
     * @description Helper, Process Troubleshoot CMS content & setup TroubleshootContentDetail wrapper list
     * @author Ajay NCP-1871
     * @param collection   CMS collection
     * @param requestedContentIds content Ids
     * @return List<TroubleshootContentDetail>
     */
    @testVisible
    private static List<TroubleshootContentDetail> processTroubleshootCMSContent(ConnectApi.ManagedContentVersionCollection collection,  List<Id> requestedContentIds ){
        List<List<String>> contentFields = new List<List<String>>();
        contentFields.add(new List<String>{'Troubleshoot_step_Heading_1','Troubleshoot_step_Description_1','Troubleshoot_step_Image_1'});
        contentFields.add(new List<String>{'Troubleshoot_step_Heading_2','Troubleshoot_step_Description_2','Troubleshoot_step_Image_2'});
        contentFields.add(new List<String>{'Troubleshoot_step_Heading_3','Troubleshoot_step_Description_3','Troubleshoot_step_Image_3'});
        contentFields.add(new List<String>{'Troubleshoot_step_Heading_4','Troubleshoot_step_Description_4','Troubleshoot_step_Image_4'});
        contentFields.add(new List<String>{'Troubleshoot_step_Heading_5','Troubleshoot_step_Description_5','Troubleshoot_step_Image_5'});
        List<TroubleshootContentDetail> contents = new List<TroubleshootContentDetail>();

        if(collection == null
        || collection.items ==null
        || collection.items.isEmpty() ){
           return contents; 
        }

        Map<Id, ConnectApi.ManagedContentVersion> mapOfContentIdItem = new Map<Id, ConnectApi.ManagedContentVersion>();
        for (ConnectApi.ManagedContentVersion item : collection.items) {
            mapOfContentIdItem.put(item.managedContentId, item);
        }

        for (Id contentId: requestedContentIds) {
            ConnectApi.ManagedContentVersion item = mapOfContentIdItem.get(contentId);
            if(item == null){
                continue;
            }

            Map<String, ConnectApi.ManagedContentNodeValue> contentNodes = item.contentNodes;
            for (List<String> fields : contentFields) {
                addToTroubleshootContentDetail(
                    contents,
                    contentNodes.get(fields[0]),
                    contentNodes.get(fields[1]),
                    contentNodes.get(fields[2])
                );
            }
        }
        
        return contents;
    }

    /**
     * @description Helper method adds Troubleshoot content details to source if content have value
     * @author Ajay NCP-1871
     * @param source
     * @param name
     * @param content
     * @param image
     * @return List<TroubleshootContentDetail> source
     */
    private static List<TroubleshootContentDetail> addToTroubleshootContentDetail(
        List<TroubleshootContentDetail> source,
        ConnectApi.ManagedContentNodeValue name,
        ConnectApi.ManagedContentNodeValue content,
        ConnectApi.ManagedContentNodeValue image
    ){
        TroubleshootContentDetail obj = new TroubleshootContentDetail();

        obj.name = ((ConnectApi.ManagedContentTextNodeValue)name)?.value;
        obj.content = ((ConnectApi.ManagedContentTextNodeValue)content)?.value;
        obj.imageUrl = ((ConnectApi.ManagedContentMediaNodeValue)image)?.url;

        if(!String.isEmpty(obj.name) || !String.isEmpty(obj.content) || !String.isEmpty(obj.imageUrl)){
            source.add(obj);
        }
        return source;
    }

   /**
     * @description Retrieve Breadcrumb information from fault fixer Id
     * NOTE: Returned Breadcrumb list will in reverse order with respect to display
     * @author Ajay NCP-1871 
     * @param faultFixerId
     * @return List<BreadCrumbWrapper>
     */
    @AuraEnabled(cacheable=true)
    public static List<BreadCrumbWrapper> getFaultFixerBreadCrumbs(Id faultFixerId){
        faultFixerId = String.escapeSingleQuotes(faultFixerId);
        
        List<D1_Fault_Fixer__c> faultFixers = [
            SELECT 
            id, Display_Title__c, RecordType.Name, 
            Parent__r.id, Parent__r.Display_Title__c, Parent__r.RecordType.Name,
            Parent__r.Parent__r.id, Parent__r.Parent__r.Display_Title__c, Parent__r.Parent__r.RecordType.Name,
            Parent__r.Parent__r.Parent__r.id, Parent__r.Parent__r.Parent__r.Display_Title__c, Parent__r.Parent__r.Parent__r.RecordType.Name
            FROM D1_Fault_Fixer__c 
            WHERE id=:faultFixerId
            AND Active__c = true
        ];

        List<BreadCrumbWrapper> breadcrumbs = new List<BreadCrumbWrapper>();
        if(faultFixers.isEmpty()){
            return breadcrumbs;
        }

        D1_Fault_Fixer__c faultFixer = faultFixers[0];
        
        breadcrumbs.add(new BreadCrumbWrapper(faultFixer.id, faultFixer.Display_Title__c, faultFixer.RecordType.Name));
        breadcrumbs.add(new BreadCrumbWrapper(faultFixer.Parent__r.id, faultFixer.Parent__r.Display_Title__c, faultFixer.Parent__r.RecordType.Name));
        breadcrumbs.add(new BreadCrumbWrapper(faultFixer.Parent__r.Parent__r.id, faultFixer.Parent__r.Parent__r.Display_Title__c, faultFixer.Parent__r.Parent__r.RecordType.Name));
        breadcrumbs.add(new BreadCrumbWrapper(faultFixer.Parent__r.Parent__r.Parent__r.id, faultFixer.Parent__r.Parent__r.Parent__r.Display_Title__c, faultFixer.Parent__r.Parent__r.Parent__r.RecordType.Name));

        List<BreadCrumbWrapper> finalBreadCrumbs = new List<BreadCrumbWrapper>();
        Boolean isDiagnosticsExist = false;

        for (BreadCrumbWrapper breadCrumb : breadcrumbs) {
            switch on breadCrumb.recordType {
                when  'Troubleshooting Steps'{
                    finalBreadCrumbs.add(breadCrumb);
                }
                when 'Diagnosis'{
                    isDiagnosticsExist = true;
                    finalBreadCrumbs.add(breadCrumb);
                }
                when 'Issue'{
                    if(isDiagnosticsExist == false){
                        finalBreadCrumbs.add(breadCrumb);
                    }
                }
                when 'Sub Category'{
                    finalBreadCrumbs.add(breadCrumb);
                }
            }
        }

        return finalBreadCrumbs;
    }

    /**ooooooooooooooooooooooooooooooooooooooooooooo
     *  SECTION-SUCCESS/FAILURE
     **ooooooooooooooooooooooooooooooooooooooooooooo*/

    /**
     * @description Troubleshoot Success/Failure info
     */
    public class FFHome_TroubleShootWrapper{
        @AuraEnabled public String sucessMsg            {get;set;}
        @AuraEnabled public String FailureMsg           {get;set;}
        @AuraEnabled public List<String> ContentIDs     {get;set;}
        @AuraEnabled public Integer ContentIDsSize      {get;set;}
    }


    /**
     * @description TroubleshootSuccessPage info
     * @return FFHome_TroubleShootWrapper
     */
    @AuraEnabled(cacheable=true)
    public static FFHome_TroubleShootWrapper getTroubleshootSuccessPageInfo(String troubleshootStepId){
        FFHome_TroubleShootWrapper troubleShootWrapper = new FFHome_TroubleShootWrapper();
        List<String> contentIds = new List<String>();
        String subCategoryId;

        if(String.isEmpty(troubleshootStepId)){
            throw new AuraHandledException('troubleshootStepId is blank');
        }

        troubleshootStepId = String.escapeSingleQuotes(troubleshootStepId);
        D1_Fault_Fixer__c troubleshootStepRecord = [SELECT id,Thank_You_Message__c,Failure_Message__c,
                                                    Parent__r.Parent__r.Parent__r.RecordType.Name,Parent__r.Parent__r.Parent__r.Content_IDs__c,
                                                    Parent__r.Parent__r.RecordType.Name,Parent__r.Parent__r.Content_IDs__c,Parent__r.RecordType.Name,
                                                    Parent__r.Parent__c,Parent__r.Parent__r.Parent__c
                                                    FROM D1_Fault_Fixer__c 
                                                    WHERE id=:troubleshootStepId 
                                                    AND Active__c = True];

        if(troubleshootStepRecord == null){
            throw new AuraHandledException('No record found');
        }

        if(troubleshootStepRecord.Parent__r.Parent__r.RecordType.Name == 'Sub Category'){
            subCategoryId = troubleshootStepRecord.Parent__r.Parent__c;
        }else if(troubleshootStepRecord.Parent__r.Parent__r.Parent__r.RecordType.Name == 'Sub Category'){
                subCategoryId = troubleshootStepRecord.Parent__r.Parent__r.Parent__c;
        }     

        for (D1_Fault_Fixer__c relatedSubCategory : [SELECT id, Name, Content_IDs__c 
                                                     FROM D1_Fault_Fixer__c 
                                                     WHERE Parent__c=:subCategoryId 
                                                     AND Active__c = True 
                                                     AND RecordType.Name ='Related Content'
                                                     ORDER BY Name]) 
        {
            String contentIdsStr =  relatedSubCategory.Content_IDs__c;
            if(!String.isEmpty(contentIdsStr)){
                contentIdsStr = contentIdsStr.trim();
                contentIds.addAll(contentIdsStr.split(';'));
            }
        }                    

        troubleShootWrapper.ContentIDs = contentIds;
        troubleShootWrapper.ContentIDsSize = contentIds.size();
        troubleShootWrapper.sucessMsg = troubleshootStepRecord.Thank_You_Message__c;
        troubleShootWrapper.FailureMsg = troubleshootStepRecord.Failure_Message__c;

        return troubleShootWrapper;
    }

    /**
     * @description getFaultFixerHierarchicalRecordData Get All parent information for GA tracking
     * @userStory NCP-4264
     * @param  faultFixerId faultFixerId object id
     * @return              configuration
     */ 
    @AuraEnabled(cacheable=true)
    public static Map<String, Object> getFaultFixerHierarchicalRecordData(Id faultFixerId){
        faultFixerId = String.escapeSingleQuotes(faultFixerId);
        
        List<D1_Fault_Fixer__c> faultFixers = [
            SELECT 
            Display_Title__c, RecordType.Name, Order__c, 
            Parent__r.Display_Title__c, Parent__r.RecordType.Name, 
            Parent__r.Parent__r.Display_Title__c, Parent__r.Parent__r.RecordType.Name, 
            Parent__r.Parent__r.Parent__r.Display_Title__c, Parent__r.Parent__r.Parent__r.RecordType.Name, 
            Parent__r.Parent__r.Parent__r.Parent__r.Display_Title__c, Parent__r.Parent__r.Parent__r.Parent__r.RecordType.Name
            FROM D1_Fault_Fixer__c 
            WHERE Id=: faultFixerId
            AND Active__c = true
            LIMIT 1
        ];

        if(faultFixers.isEmpty()){
            throw new AuraHandledException('Invalid parameter');
        }

        D1_Fault_Fixer__c faultFixer = faultFixers[0];
        Map<String, String> mapOfRecordTypeDisplayData = new Map<String, String>();

        addToHierarchicalMap(mapOfRecordTypeDisplayData, faultFixer);// Troubleshooting Step
        addToHierarchicalMap(mapOfRecordTypeDisplayData, faultFixer.Parent__r);// Diagnostics
        addToHierarchicalMap(mapOfRecordTypeDisplayData, faultFixer.Parent__r.Parent__r);// Issue
        addToHierarchicalMap(mapOfRecordTypeDisplayData, faultFixer.Parent__r.Parent__r.Parent__r);// Sub Category
        addToHierarchicalMap(mapOfRecordTypeDisplayData, faultFixer.Parent__r.Parent__r.Parent__r.Parent__r);// Category

        return new Map<String, Object>{
            'objectRecordType' => faultFixer.RecordType.Name,
            'step'=> faultFixer.Order__c,
            'mapOfRecordTypeDisplayData' => mapOfRecordTypeDisplayData
        };
    }

    /**
     * @description addToHierarchicalMap 
     * @param  sourceMap     sourceMap 
     * @param  faultFixerObj faultFixerObj 
     */
    private static void addToHierarchicalMap(Map<String, String> sourceMap, D1_Fault_Fixer__c faultFixerObj){
        if(faultFixerObj != null){
            sourceMap.put(faultFixerObj.RecordType.Name, faultFixerObj.Display_Title__c);
        }   
    }

}

/**
 
System.debug(
    D1_FaultFixerController.getFaultFixerLandingPageInitInfo1()
);

System.debug(
    D1_FaultFixerController.getFaultFixerHierarchicalRecordData('a4f7Z00000088qvQAA')
);
 */