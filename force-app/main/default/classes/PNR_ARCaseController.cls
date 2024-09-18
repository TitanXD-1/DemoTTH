/**********************************************************************
Name: PNR_ARCaseController
=======================================================================
Req: This is the helper class for PNR_ARCaseComponent lightning component. 
=======================================================================
History                                                            
------------------------------------------------------------------------                                                          
VERSION   AUTHOR            DATE              DETAIL
1.0  	  Saurav Paul	    07/12/2019      Initial Development

***********************************************************************/
public with sharing class PNR_ARCaseController {
    //This method will return Case Type
    @AuraEnabled
    public static List<String> getCaseTypeLst(String caseRecType){
        List<Instruction_to_users__mdt> helpTxtLst = new List<Instruction_to_users__mdt>();
        List<String> caseTypeList = new List<String>();
        if(String.isNotBlank(caseRecType) 
           && Schema.sObjectType.Instruction_to_users__mdt.isAccessible()){
               helpTxtLst = [SELECT Id,Case_RecordType__c,Case_Type__c,Instruction__c 
                             FROM Instruction_to_users__mdt
                             WHERE Case_RecordType__c = : caseRecType
                            ];
               if(!helpTxtLst.isEmpty()){
                   for(Instruction_to_users__mdt mdtObj : helpTxtLst){
                       caseTypeList.add(mdtObj.Case_Type__c);
                   }
                   caseTypeList.sort();
                   return caseTypeList;
               }
           }
        return null;
    }
    //This method will return Instruction for Users
    @AuraEnabled
    public static String getHelpTextMsg(String caseRecType, String caseType){
        List<Instruction_to_users__mdt> helpTxtLst = new List<Instruction_to_users__mdt>();
        List<String> hlpTxtList = new List<String>();
        if(String.isNotBlank(caseRecType) 
           && String.isNotBlank(caseType)
           && Schema.sObjectType.Instruction_to_users__mdt.isAccessible()){
               helpTxtLst = [SELECT Id,Case_RecordType__c,Case_Type__c,Instruction__c 
                             FROM Instruction_to_users__mdt
                             WHERE Case_RecordType__c =: caseRecType
                             AND Case_Type__c =: caseType
                             LIMIT 1
                            ];
               String hlpMsg = helpTxtLst[0].Instruction__c;
               return hlpMsg;
           }
        return null;
    }
    //This will return Recordtype Name
    @AuraEnabled        
    public static string getRecTypeName(Id caseId){
        if(Schema.sObjectType.Case.isAccessible()){
            List<case> caseList = [SELECT Id, RecordTypeId, RecordType.Name FROM Case WHERE Id =:caseId];
            if(!caseList.isEmpty()){
                return caseList[0].RecordType.Name;
            }
        }
        return null;
    }
    //This will return Case Type value
    @AuraEnabled        
    public static string setCaseType(Id caseId){
        if(Schema.sObjectType.Case.isAccessible()){
            List<case> caseList = [SELECT Id, Type, RecordType.Name FROM Case WHERE Id =:caseId];
            if(!caseList.isEmpty()){
                return caseList[0].Type;
            }
        }
        return null;
    }
}