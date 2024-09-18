public class CC_DuplicateCasesController {
	@auraenabled
    public static List<Case> getDuplicateCases(String caseId)
    {
        List<Case> caseList = new List<Case>();
        if(caseId !=null)
        {
            Case obj = [Select Id,CaseNumber, CC_LOT_Code__c from Case where Id=:caseId LIMIT 1];
            //changes made by Saranga for CHG0190317 regarding duplicate LOT codes with NA
            if((!String.isBlank(obj.CC_LOT_Code__c)) && (obj.CC_LOT_Code__c != 'na') && (obj.CC_LOT_Code__c != 'NA') && (obj.CC_LOT_Code__c != 'n/a') && (obj.CC_LOT_Code__c != 'N/A'))
            {
                caseList = [Select id,CaseNumber,CC_LOT_Code__c,(Select id,Name from Investigations__r) from Case where CC_LOT_Code__c =:obj.CC_LOT_Code__c AND Id !=:caseId];
            }
               
        }
        if(caseList.size()>0)
            return caseList;
        else
            return null;
    }
}