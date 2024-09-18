/*
 * @class: PNR_CasesForSelectedInvoiceCls
 * @description: This class returns list of cases for a particular invoice, here in this we are getting case ID from case detail page.
 * @author: Sai Kiran Sagaram
 * This class is written for PION-1594 change.
 * */
public class  PNR_CasesForSelectedInvoiceCls {
    /*
     * @description: this method returns list of cases
     * */
	@auraenabled
    public static List<Case> getDuplicateCases(String caseId)
    {
        /*variable declaration start*/
        List<Case> caseList = new List<Case>();
        Case csVar = new Case();
        list<Case> caseRec = new list<Case>();
        /*variable declaration end*/
        if(caseId !=null)
        {
            caseRec = [Select Id,CaseNumber, Reference_Invoice__c from Case where Id=:caseId LIMIT 1];
            if(caseRec.size()>0){
                Case obj = caseRec[0];
                csVar.Reference_Invoice__c = obj.Reference_Invoice__c;
                if(!String.isBlank(obj.Reference_Invoice__c))
                {
                    caseList = [Select Id,CaseNumber,AccountId,Account.Name,Status,Type, Claimed_Amount__c, CurrencyIsoCode from Case where Reference_Invoice__c =:obj.Reference_Invoice__c AND Id !=:caseId];
                } 
            }  
        }
        if(caseList.size()>0){
            return caseList;
        }
        //If there is no reference invoice attached to a particular, we have show custom error message.
        else if(String.isBlank(csVar.Reference_Invoice__c)){
            return null;
        }
            return null;     
    }
}