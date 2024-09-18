/*
Name: EDGE_ApprovalRequestController


History                                                            

VERSION   AUTHOR            DATE              DETAIL
1.0       Mayukh S Roy     29/06/2023         298232 
*/

public with sharing class EDGE_GenerateApprovalLinkController {
    public String recordID {get; set;}
    public String urlStr{
        get{
            return generateApprovalURL(recordID);
        }
    }
    public static String generateApprovalURL(String recordID){
        String url='';
        List <sobject> workItemLst = [SELECT id FROM ProcessInstanceWorkitem WHERE processInstance.TargetObjectId=:recordID WITH SECURITY_ENFORCED];
        if(workItemLst.size() > 0){
            url='https://'+ System.URL.getSalesforceBaseUrl().getHost() + '/p/process/ProcessInstanceWorkitemWizardStageManager?id=' + workItemLst[0].id;
        }
        return url;
    }
}