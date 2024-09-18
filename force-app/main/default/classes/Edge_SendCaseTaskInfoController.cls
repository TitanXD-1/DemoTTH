/**
* @Name: EDGE_SendCaseTaskInfoController 
* @ES20-11514 - Chatter notification to Users on Assignment of Case Tasks
* @History                                                            
* 	@VERSION     AUTHOR              DATE              DETAIL
*	1.0 -    Anamika Shukla   25/11/2021     ES20-11514 (Chatter notification to Users on Assignment of Case Tasks)

*/


public with sharing class Edge_SendCaseTaskInfoController {
    
    @AuraEnabled
    public static Case_Task__c fetchCasetaskInfo(String caseTaskId) {
        Case_Task__c caseTaskInfo = new Case_Task__c();
        try{
            if(Schema.sObjectType.Case_Task__c.isAccessible()){
                caseTaskInfo = [SELECT Account__c,Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry,
                            Account__r.BillingLatitude, Account__r.BillingLongitude,Achievement_Status__c,Actioned_Within_SLA__c, Asset__c, Call__c,Case_Task_Notes__c,
                            Case_Task_Type__r.Name,Case__c,Case__r.CaseNumber, Case__r.Case_Type__r.Name,Case__r.Case_Sub_Type__r.Name,Closed_Date_Time__c,Case__r.Due_Date_Time__c,

                            Case_Task__c.Account__r.Name,Case__r.Case_Notes__c,Contractor_Name__c,Country__c,Id,Name,Product_Name_MAP__c,Product__c,Quantity_Cleaned__c,

                            Quantity__c,Reason_Code__c,Reason_Comments__c,Resolution_Code__c,User_Assigned_To__c,User_Assigned_To__r.Name FROM Case_Task__c WHERE Id = :caseTaskId];
            }
            
            
        }
        catch(Exception ex){
            system.debug('Exception Message =====>: ' + ex.getMessage());
            caseTaskInfo = null;
        }
        return caseTaskInfo;
    }
    
    //Name : sendChatterMessages
    //Description : return true or false status for FeetItemPost
    @AuraEnabled
    public static Boolean sendChatterMessages(String caseTaskId) {
        Case_Task__c caseTaskInfo = new Case_Task__c();
        if(Schema.sObjectType.Case_Task__c.isAccessible()){
            caseTaskInfo = [SELECT Account__c,Account__r.BillingStreet,Account__r.BillingCity,Account__r.BillingState, Account__r.BillingPostalCode, Account__r.BillingCountry,
                            Account__r.BillingLatitude, Account__r.BillingLongitude,Achievement_Status__c,Actioned_Within_SLA__c, Asset__c, Call__c,Case_Task_Notes__c,
                            Case_Task_Type__r.Name,Case__c,Case__r.CaseNumber, Case__r.Case_Type__r.Name,Case__r.Case_Sub_Type__r.Name,Closed_Date_Time__c,Case__r.Due_Date_Time__c,

                            Case_Task__c.Account__r.Name,Case__r.Case_Notes__c,Contractor_Name__c,Country__c,Id,Name,Product_Name_MAP__c,Product__c,Quantity_Cleaned__c,

                            Quantity__c,Reason_Code__c,Reason_Comments__c,Resolution_Code__c,User_Assigned_To__c,User_Assigned_To__r.Name FROM Case_Task__c WHERE Id = :caseTaskId];
        }    
        
        //calling the method to call the chatter api
        boolean isSuccess = false;
        boolean isError = false;
        
        String UserId = '';
        
        if(caseTaskInfo.User_Assigned_to__c != null) {
            
            String recordId = String.ValueOf(caseTaskInfo.Id);
            //get the 15 digit id value
            if(recordId.length() == 18)   
                recordId = recordId.substring(0,15);     
            
            UserId = String.ValueOf(caseTaskInfo.User_Assigned_to__c);
            
            // get the required chatter post in teh accepted format through the method
            String ChatterPostText = createChatterPost(caseTaskInfo);
            
            //truncating it is required and marking the warning that the chatter post exceeded the limit
            if(ChatterPostText != null && ChatterPostText != '' && ChatterPostText.length() > 1000) {
                ChatterPostText = ChatterPostText.subString(0,1000);
            }
            
            ConnectApi.FeedItemInput feedItemInput = new ConnectApi.FeedItemInput();
            ConnectApi.MentionSegmentInput mentionSegmentInput = new ConnectApi.MentionSegmentInput();
            ConnectApi.MessageBodyInput messageBodyInput = new ConnectApi.MessageBodyInput();
            ConnectApi.TextSegmentInput textSegmentInput = new ConnectApi.TextSegmentInput();
            
            messageBodyInput.messageSegments = new List<ConnectApi.MessageSegmentInput>();
            // Mention a group.
            mentionSegmentInput.id = UserId;
            messageBodyInput.messageSegments.add(mentionSegmentInput);
            
            textSegmentInput.text = ChatterPostText;
            messageBodyInput.messageSegments.add(textSegmentInput);
            
            feedItemInput.body = messageBodyInput;
            feedItemInput.feedElementType = ConnectApi.FeedElementType.FeedItem;
            
            // Use a record ID for the subject ID.
            feedItemInput.subjectId = recordId;
            
            try {
                //Create FeedItemPost
                ConnectApi.FeedElement feedElement = ConnectApi.ChatterFeeds.postFeedElement(null, feedItemInput);
            } catch(Exception e){
                system.debug('Call Out Error :' + e.getMessage()); // avoiding the user seeing salesforce error and instead showing custom error
                isSuccess = false;
                isError = true;
            }
            
            if(!isError) // if there hasnt been an error show success
                isSuccess = true;
            
        } else {
            isSuccess = false;
        }
        
        return isSuccess;
    }
    
    public Static String createChatterPost(Case_Task__c casetaskInfo) {
        
        //creating the chatter post
        String chatterPost = '';

        chatterPost += '- Task alert' ;
        chatterPost +='\n';
        //Outlet name
        if(casetaskInfo.Account__c != null) {
            chatterPost += casetaskInfo.Account__r.Name;
            chatterPost +='\n';
        }
        //BillingStreet
        if(casetaskInfo.Account__r.BillingStreet != null){
            chatterPost += casetaskInfo.Account__r.BillingStreet;
            chatterPost +='\n';
        }
        //BillingCity
        if(casetaskInfo.Account__r.BillingCity != null){
            chatterPost += casetaskInfo.Account__r.BillingCity;
            chatterPost +='\n';
        }
        //BillingState
        if(casetaskInfo.Account__r.BillingState != null){
            chatterPost += casetaskInfo.Account__r.BillingState;
            chatterPost +='\n';
        }
        
        //BillingPostalCode
        if(casetaskInfo.Account__r.BillingPostalCode != null){
            chatterPost += casetaskInfo.Account__r.BillingPostalCode;
            chatterPost +='\n';
        }
        
        //BillingCountry
        if(casetaskInfo.Account__r.BillingCountry != null){
            chatterPost += casetaskInfo.Account__r.BillingCountry;
            chatterPost +='\n';
        }
        
        chatterPost += 'Case Task Type';
        chatterPost += ' : ';
        //checking if the task name is not null
        if(casetaskInfo.Case_Task_Type__c != null) {
            //getting the task name label
            chatterPost += casetaskInfo.Case_Task_Type__r.Name;
        }
        
        chatterPost +='\n';
        
        //getting the due date time label
        chatterPost += 'Due Date Time';
        chatterPost += ' : ';
        
        //checking if the field is non null
        if(casetaskInfo.Case__r.Due_Date_Time__c != null) {
            chatterPost += casetaskInfo.Case__r.Due_Date_Time__c;
        }
        
        chatterPost +='\n';
        
        //getting the Case Id label
        chatterPost += 'Case Id';
        chatterPost += ' : ';
        
        //checking if the field is non null
        if(casetaskInfo.Case__c != null) {
            chatterPost += casetaskInfo.Case__r.CaseNumber;  
        }
        chatterPost +='\n';
        
        //get the case type label
        chatterPost += 'Case Type';
        chatterPost += ' : ';
        
        //checking if the case type value is non null
        if(casetaskInfo.Case__c != null) {
            chatterPost += casetaskInfo.Case__r.Case_Type__r.Name;
        }
        chatterPost +='\n';
        
        //get the case type label
        chatterPost += 'Case Sub Type';
        chatterPost += ' : ';
        
        //checking if the case type value is non null
        if(casetaskInfo.Case__c != null) {
            chatterPost += casetaskInfo.Case__r.Case_Sub_Type__r.Name;
        }
        chatterPost +='\n';
        
        //case notes label
        chatterPost += 'Case Notes';
        chatterPost += ' : ';
        
        //checking if the case notes is not null
        if(casetaskInfo.Case__c != null) {
            if(casetaskInfo.Case__r.Case_Notes__c != null){
                chatterPost += casetaskInfo.Case__r.Case_Notes__c;
            }
        }
        chatterPost +='\n';
        
        //case notes label
        chatterPost += 'Task Comments';
        chatterPost += ' : ';
        
        //checking if the Task Comments is not null
        if(casetaskInfo.Case__c != null) {
            if(casetaskInfo.Case_Task_Notes__c != null){
                chatterPost += casetaskInfo.Case_Task_Notes__c;
            }
        }
        
        //checking if our post is non null
        if(chatterPost != null)
            return chatterPost;
        else
            return '';
    }
}