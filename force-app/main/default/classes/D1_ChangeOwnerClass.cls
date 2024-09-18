/*
 * @Name: D1_ChangeOwnerClass
 * @discription: Class for change owner button on Account page 
 * History                                                            
 * --                                                            
 * VERSION   AUTHOR            DATE              DETAIL
 * 1         Abhishek          22-02-21
 **/
public without sharing class D1_ChangeOwnerClass {
    /**
     * @description 
     * @param accountId 
     * @return  `string`
     */    
    @AuraEnabled
    public static string changeOwner(Id accountId) {
        try {
            boolean isD1mdms = featuremanagement.checkpermission('D1_Account_Delete_Permission');
            if(isD1mdms == true) {
                Account accToUpd = new Account(Id = accountId);
                accToUpd.ownerId = UserInfo.getUserId();
                update accToUpd;
                return 'True';
            } else {
                return 'False';
            }
        } catch(Exception ex) {
            return ex.getMessage();
        }
    }
}