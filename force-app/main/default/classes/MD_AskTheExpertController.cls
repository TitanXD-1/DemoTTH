/*ClassName: MD_AskTheExpertController
Controller: Acts as a controller for MD_AskTheExpertComponent
Author: Deepesh Rao
*/
public class MD_AskTheExpertController {
/*Purpose: Creates a AskTheExpert case with My Diageo Cases record type.
* Author: Deepesh Rao
* Parameters: String
* Story Number: MCM-34
* Name: createCase(String caseQuestion)
*/
    @AuraEnabled
    public static void createCase(string caseQuestion)
    {
        Group askTheExpertQueue = [select id,Name from Group where Name=:label.MD_AskTheExpertQueueName];//Query on groups to fetch the relevant queue
        AccountContactRelation loggedOutletContact;// AccountContact instance to access Account and Contact fieldds
        List<Case> newlyCreatedCases = new list<Case>();//Case list used for inserting the new cases
        loggedOutletContact = MD_UserSessionUtil.getOutletContact();//Existing logic to fetch logged in user account and contact
        Case createAskTheExpertCase = new case();//new case creation
        createAskTheExpertCase.RecordTypeId = Schema.SObjectType.Case.getRecordTypeInfosByName().get('My Diageo Cases').getRecordTypeId();
        createAskTheExpertCase.AccountId = loggedOutletContact.AccountId;//logged in user's AccountId
        createAskTheExpertCase.ContactId = loggedOutletContact.ContactId;//logged in user's ContacttId
        createAskTheExpertCase.Description = caseQuestion;//Question mapped to description
        createAskTheExpertCase.Type = Label.MD_AskTheExpertPicklistValue;//value: Ask The Expert
        createAskTheExpertCase.MD_Subject__c = Label.MD_AskTheExpertPicklistValue;//value: Ask The Expert
        createAskTheExpertCase.Reason = Label.MD_AskTheExpertQueriesValue;//value: Ask The Expert Queries
        createAskTheExpertCase.Status = Label.MD_AskTheExpertStatus;//value: Processed
        createAskTheExpertCase.Origin = Label.MD_AskTheExpertOrigin;//value: Web
        createAskTheExpertCase.OwnerId = askTheExpertQueue.Id;//Owner queue assignment
        newlyCreatedCases.add(createAskTheExpertCase);//adding the newly created cases to the list
        if(!newlyCreatedCases.isEmpty())//Checking list is empty or not
        {
            insert newlyCreatedCases;//Inserting new case of type "Ask The Expert"    
        }
    }  
}