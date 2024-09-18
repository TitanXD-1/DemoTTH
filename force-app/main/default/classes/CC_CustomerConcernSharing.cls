public class CC_CustomerConcernSharing {
    @InvocableMethod
    public static void createSharingRecords(List<Id> concernId) {
        List<CC_Customer_Concern__Share> insertCCShareList= new List<CC_Customer_Concern__Share>();
        List<CC_Customer_Concern__c> customerConcern = [select Id, CreatedById
                                                        from CC_Customer_Concern__c
                                                       	Where ID IN : concernId];
        for(CC_Customer_Concern__c cc:customerConcern)
        {
            CC_Customer_Concern__Share concenShare = new CC_Customer_Concern__Share();
            concenShare.ParentId = cc.Id;
            concenShare.AccessLevel = 'Read';
            concenShare.UserOrGroupId = cc.CreatedById;
            insertCCShareList.add(concenShare);
        }
        
        if(insertCCShareList.size() > 0)
            insert insertCCShareList;
    }
}