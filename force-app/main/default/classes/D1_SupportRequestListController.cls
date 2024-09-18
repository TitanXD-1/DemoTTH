public with sharing class D1_SupportRequestListController {

    private static String homePageType = 'Diageo One HomePage';

    public class RequestListTableHeader{
        @AuraEnabled public String header;
        @AuraEnabled public String fieldApiName;
        @AuraEnabled public String fieldType;
        @AuraEnabled public String styleClass;
        public RequestListTableHeader(String header, String fieldApiName, String fieldType, String styleClass){
            this.header = header;
            this.fieldApiName = fieldApiName;
            this.fieldType = fieldType;
            this.styleClass = styleClass;
        }
    }
   
    @AuraEnabled()
    public static Map<String,Object> getRequestList(String tableType, Boolean showAllOpenCases, String userType,String sapOrderNumber){
        User userRecord = [Select id, ContactId, Available_Countries__c, LanguageLocaleKey from User where Id = :UserInfo.getUserId()];
        
        D1_HelpAndSupportTableMapping__mdt mappingRecord = [ SELECT Id,Table_Columns__c  FROM D1_HelpAndSupportTableMapping__mdt
                                                             WHERE D1_User_Locale_Setting__r.Country_Code__c =:userRecord.Available_Countries__c
                                                             AND D1_User_Locale_Setting__r.LanguageLocaleKey__c =:userRecord.LanguageLocaleKey 
                                                             AND Table_Type__c =:tableType AND User_Type__c =:userType LIMIT 1];

        List<String> tableRows = mappingRecord.Table_Columns__c.split(';');
        Set<String> allFields = new Set<String>();
        List<RequestListTableHeader> tableHeaders = new List<RequestListTableHeader>();
        for(String tableRow : tableRows){
            List<String> labelNameList = tableRow.split(':');
            string labelName = labelNameList[1].trim().containsIgnoreCase('toLabel') ? labelNameList[1].trim().removeStart('toLabel(').removeEnd(')') : labelNameList[1].trim();
            tableHeaders.add( new RequestListTableHeader(labelNameList[0].trim(), labelName , labelNameList[2].trim(),labelNameList[3].trim() ) );
            //tableHeaders.add( new RequestListTableHeader(labelNameList[0].trim(), labelNameList[1].trim(), labelNameList[2].trim(),labelNameList[3].trim() ) );
            allFields.add(labelNameList[1].trim());
        }

        if(tableType == homePageType){//NCP-8250
            allFields.add('Status');
        }

        List<Case> caseList = new List<Case>();
        if( tableType == 'Customer Service' ){
            caseList = getEdgeQualityCaseList(userRecord, allFields, showAllOpenCases);
        }else if( tableType == 'Diageo One'){
            caseList = getDiageoQualityCaseList(userRecord, allFields, showAllOpenCases);
        }else if (tableType == 'Related Queries' && sapOrderNumber!=null){
            caseList = getAllCaseList(userRecord, allFields, showAllOpenCases, sapOrderNumber);
        }else{
            caseList = getAllCaseList(userRecord, allFields, showAllOpenCases, tableType == homePageType);
        }

        Map<String,Object> result = new Map<String,Object>();
        result.put('tableHeaders', tableHeaders);
        result.put('caseList', caseList);
        return result;
    }  
    public static List<Case> getAllCaseList(User usr, Set<String> allFields, Boolean showAllOpenCases, Boolean isHomePage){
        Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }

        Id userId = usr.Id;//NOPMD
        Id userContactId = usr.ContactId;//NOPMD
        Id d1RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();//NOPMD
        Id d1KegReturnRecTypId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Keg Return').getRecordTypeId();//NOPMD
        Id d1DirectDisputes = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        Id technicalIssue = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Technical Issue').getRecordTypeId();//NOPMD

        allFields.add('Id');
        allFields.add('RecordTypeId');
        allFields.add('D1_Batch_Number__c');
        allFields.add('D1_Order_Number__c');
        allFields.add('D1_Document_no__c');
        allFields.add('D1_Invoice_Number__c');
        allFields.add('D1_Delivery_Number__c');

        String queryFields = String.join(new List<String>(allFields), ',');
        String query = 'SELECT '+queryFields+' FROM Case '
        + ' WHERE (CreatedById = :userId OR ContactId =:userContactId) AND (RecordTypeId = :d1RecordTypeId OR RecordTypeId = :d1KegReturnRecTypId OR RecordTypeId = :d1DirectDisputes OR RecordTypeId = :technicalIssue) AND Origin IN (\'Diageo One\',\'Email\',\'Phone\',\'Web\',\'EDGE 365 Global\') '
        + (showAllOpenCases? ' AND (IsClosed = false) ' : '')
        + ' AND (Type NOT IN (\'Quality Issues\' , \'Quality & Equipment Issues\')) '
        + ' ORDER By CreatedDate DESC '
        + (isHomePage? ' LIMIT 5' : '');
		//added origin values in the query CUS-98
        List<Case> caseList = (List<Case>) Database.query(query);

        /*caseList = [SELECT Id, RecordTypeId, CaseNumber, toLabel(Type), toLabel(D1_Subject__c), Description, Status, CreatedDate,D1_Batch_Number__c, D1_Order_Number__c, D1_Document_no__c, D1_Invoice_Number__c, D1_Delivery_Number__c FROM Case
                    WHERE (CreatedById = :UserInfo.getUserId() OR ContactId =:usr.ContactId) AND (RecordTypeId = :d1RecordTypeId OR RecordTypeId = :d1KegReturnRecTypId OR RecordTypeId = :d1DirectDisputes OR RecordTypeId = :technicalIssue) AND Origin = 'Diageo One'
                    WITH SECURITY_ENFORCED ORDER By CreatedDate DESC];*/

        for(Case cs: caseList){
            if(cs.RecordTypeId == d1DirectDisputes){
                if(cs.Status!= 'Closed'){
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
    public static List<Case> getAllCaseList(User usr, Set<String> allFields, Boolean showAllOpenCases,String sapOrderNumber){//NCP-6846
        Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }
        allFields.add('RecordTypeId');
        String queryFields = String.join(new List<String>(allFields), ',');
        
        String query = 'SELECT '+queryFields+' FROM Case '
        + ' WHERE (D1_Order_Number__c =:sapOrderNumber)'
        + ' ORDER By CreatedDate DESC ';
        Id d1DirectDisputes = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Direct Disputes').getRecordTypeId();
        List<Case> caseList = (List<Case>) Database.query(query);
        for(Case cs: caseList){
            if(cs.RecordTypeId == d1DirectDisputes){
                if(cs.Status!= 'Closed'){
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

    public static List<Case> getEdgeQualityCaseList(User usr, Set<String> allFields, Boolean showAllOpenCases){
        Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }

        Id qualityRecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Quality').getRecordTypeId();//NOPMD
        
        allFields.add('Id');
        allFields.add('RecordTypeId');

        String queryFields = String.join(new List<String>(allFields), ',');
        String query = 'SELECT '+queryFields+' FROM Case '
        + ' WHERE RecordTypeId = :qualityRecordTypeId '
        + (showAllOpenCases? ' AND (IsClosed = false)' : ' AND ((IsClosed = false) OR (IsClosed = true AND ClosedDate >= LAST_N_DAYS:7)) ')
        + ' ORDER By CreatedDate DESC ';
        
        List<Case> caseList = (List<Case>) Database.query(query);

        for(Case cs: caseList){
            cs.Status = valueLabelMap.get(cs.Status);
        }
        return caseList;
    }

    public static List<Case> getDiageoQualityCaseList(User usr, Set<String> allFields, Boolean showAllOpenCases){
        Schema.DescribeFieldResult fieldResult = Case.Status.getDescribe();
        List<Schema.PicklistEntry> picklistValues = fieldResult.getPicklistValues();
        Map<String ,String> valueLabelMap = new Map<String,String>();
        for(PicklistEntry p:picklistValues){
            valueLabelMap.put(p.getValue(),p.getLabel());
        }

        Id d1RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('Diageo One Cases').getRecordTypeId();//NOPMD
        
        allFields.add('Id');
        allFields.add('RecordTypeId');
		//added origin values in the query CUS-98
        String queryFields = String.join(new List<String>(allFields), ',');
        String query = 'SELECT '+queryFields+' FROM Case '
        + ' WHERE RecordTypeId = :d1RecordTypeId AND Origin IN (\'Diageo One\',\'Email\',\'Phone\',\'Web\',\'EDGE 365 Global\') AND (Type IN (\'Quality Issues\' , \'Quality & Equipment Issues\')) '
        + (showAllOpenCases? ' AND (IsClosed = false)' : '')
        + ' ORDER By CreatedDate DESC ';
        
        List<Case> caseList = (List<Case>) Database.query(query);

        for(Case cs: caseList){
            cs.Status = valueLabelMap.get(cs.Status);
        }
        return caseList;
    }
}