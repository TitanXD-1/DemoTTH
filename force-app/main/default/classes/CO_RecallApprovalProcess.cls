/*
@Name: CO_RecallApprovalProcess
@Purpose: This class is used by the recall the approval process when the 
		 data manager changes the customer request from IN REVIEW to IN QUERY
@History                                                                                                                       
VERSION    AUTHOR            DATE              DETAIL
1.0       Jayashree R       11-25-2022        Initial Development
*/

public with sharing class CO_RecallApprovalProcess implements Messaging.InboundEmailHandler {
    
    /*
     * Method Name: recallApproval
     * Purpose: this method is used to send a email to email services 
     *          for recalling the approval process
     **/
    @InvocableMethod(label='Recall Approval Process' description='Recall the approval process of customer request record')    
    public static void recallApproval(List<Id> recId)   
    {       
        List<ProcessInstanceWorkitem> piwi = [SELECT Id, ProcessInstanceId, ProcessInstance.TargetObjectId FROM ProcessInstanceWorkitem WHERE ProcessInstance.TargetObjectId =: recId[0] WITH SECURITY_ENFORCED];
        //Approval.ProcessWorkitemRequest req = new Approval.ProcessWorkitemRequest();
        Messaging.SingleEmailMessage oMessage = new Messaging.SingleEmailMessage();
        try {
            // find our email service to use, as convention we prefixed it with class name 
            EmailServicesAddress oEmailServiceAddress = [
                SELECT e.SystemModstamp, e.RunAsUserId, e.LocalPart, e.LastModifiedDate, e.LastModifiedById, e.IsActive, e.Id, e.FunctionId, e.EmailDomainName, e.CreatedDate, e.CreatedById, e.AuthorizedSenders 
                FROM EmailServicesAddress e
                WHERE e.IsActive = true and developerName= 'CORecallApprovalProcess'
            ].get(0); 
            oMessage.toAddresses = new String[] {
                oEmailServiceAddress.LocalPart + '@' + oEmailServiceAddress.EmailDomainName
                    };
          System.debug(LoggingLevel.DEBUG,'=== ItoAddresses' + oMessage.toAddresses);
           Map<String, Object> oParameterMap = new Map<String, Object>{'sAction' => 'mApprovalRecallActionWithAdminPermissions', 'sApprovalID' =>  piwi.get(0).Id};
                
            oMessage.subject = '=== ID_Item.mApprovalRecallAction(...): `JSON.serialize(oParameterMap)=' + JSON.serialize(oParameterMap) + '`'; // using subject is not safe because SF can modify it sometimes (ex. prefixing `Sandbox`  
            oMessage.plainTextBody = JSON.serialize(oParameterMap);
            Messaging.SendEmailResult[] oResults = Messaging.sendEmail(new List<Messaging.SingleEmailMessage> {oMessage});
            
            System.debug(LoggingLevel.DEBUG,'=== ID_Item.mApprovalRecallAction(...): `oResults' + String.valueOf(oResults) + '`');
            
            System.debug(LoggingLevel.DEBUG,'<<< ID_Item.mApprovalRecallAction(...)');
            if (oResults[0].success) {
                System.debug(LoggingLevel.DEBUG,'---'+New Map<String, Object>{'bSuccess' => true, 'oResults' => JSON.serialize(String.valueOf(oResults))});
            } else {
                System.debug(LoggingLevel.DEBUG,'---'+new Map<String, Object>{'bSuccess' => false, 'oResults' => JSON.serialize(String.valueOf(oResults))});
            }
        }
        catch (Exception ex) {
            System.debug(LoggingLevel.DEBUG,'Exception>>>>'+ex.getMessage());
            System.debug(LoggingLevel.DEBUG,'Stack Trace>>>>'+ex.getStackTraceString());
        }
    }
    
     /*
     * Method Name: handleInboundEmail
     * Purpose: this method is used to receive the email sent to email service
     * 			and recall the approver process from system admin context  
     */
    public static Messaging.InboundEmailResult handleInboundEmail(Messaging.inboundEmail oInboundEmail, Messaging.InboundEnvelope oInboundEnvelope){
        System.debug(LoggingLevel.DEBUG,'>>> ID_Item.handleInboundEmail(...)');
        Messaging.InboundEmailResult oInboundEmailResult = new Messaging.InboundEmailResult();
        
        Map<String,Object> oParameterMap = new Map<String, Object>{'sAction' => 'UNKNOWN'};
            try {
                oParameterMap = (Map<String, Object>)JSON.deserializeUntyped(oInboundEmail.plainTextBody); 
                // expected string input format is "{'sAction': 'fooBar', 'sApprovalID': 'foo', ...}"
            } 
        catch (QueryException e) {
            System.debug(LoggingLevel.DEBUG,'=== ID_Item.handleInboundEmail(...): ERROR: `e=' + e + '`');
            System.debug(LoggingLevel.DEBUG,'<<< ID_Item.handleInboundEmail(...)');
            return oInboundEmailResult;
        }
        try {
            if (oParameterMap.get('sAction') == 'mApprovalRecallActionWithAdminPermissions') {
                String sApprovalID = (String)oParameterMap.get('sApprovalID');
                Approval.ProcessWorkitemRequest oPWR = new Approval.ProcessWorkitemRequest(); 
                oPWR.setComments('Recalled by `' + oInboundEnvelope.fromAddress + '`');
                oPWR.setAction('Removed');
                //if (Test.isRunningTest() == false) {
                    oPWR.setWorkItemId(sApprovalID);
                    Approval.ProcessResult oPR = Approval.process(oPWR);
                    System.debug(LoggingLevel.DEBUG,oPR.isSuccess());
               // }
                
            }
            
        }
        catch (QueryException e) {
            System.debug(LoggingLevel.DEBUG,'=== ID_Item.handleInboundEmail(...): ERROR: `e=' + e + '`');
        }
        oInboundEmailResult.success = true;
        System.debug(LoggingLevel.DEBUG,'<<< ID_Item.handleInboundEmail(...)');
        return oInboundEmailResult;
    }
}