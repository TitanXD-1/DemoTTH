/** 
 * @Name: D1_AnnouncementBanner
 * 
 * @discription : To Display announcement at D1 portal
 * @History                                                            
 * -------                                                            
 * VERSION     AUTHOR              DATE              DETAIL
 * 1.0         Rushikesh Bodkhe    27/04/2021        Initial Development (NCP-3705)
 * 2.0          Sayan              27/04/2022           NCP-6458
 * 3.0          Shivam Chauhan     24/06/2022           NCP-6930
 **/
public class D1_AnnouncementBanner {
    /**
     * @description 
     * @return  `List<Notification__c>`
     * @exception 
     */    
    @AuraEnabled(cacheable=true)
    public static List<Notification__c> getAnnouncement(){
        List<Notification__c> notificationList = new List<Notification__c>();
        try {
            string publicgroup = system.Label.D1_publicgroups;
            List<String> notificationGroup = publicgroup.split(',');
           
            GroupMember grpMem = [SELECT Group.DeveloperName FROM GroupMember WHERE UserOrGroupId =: UserInfo.getUserId() 
                                  AND Group.DeveloperName IN :notificationGroup LIMIT 1]; 
                                  
            User currentUser = [SELECT LanguageLocaleKey  from user where Id =: UserInfo.getUserId()];//NCP-6458
            
            if(grpMem != null){
                notificationList  = [SELECT Id, Short_Description__c, URL__c FROM Notification__c 
                                    WHERE Status__c = 'Active' AND Recordtype.DeveloperName ='Diageo_One_Announcements'
                                    AND Group_Name__c =:grpMem.Group.DeveloperName
                                    AND Language__c =:currentUser.LanguageLocaleKey LIMIT 1];
            }
            
        }catch(Exception ex) {
            throw new AuraHandledException(ex.getMessage());
        }
        return notificationList;
    }   
}