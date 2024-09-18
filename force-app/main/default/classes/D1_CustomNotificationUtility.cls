/*
 * @name: D1_CustomNotificationUtility
 * @discription: Utility Class for sending custom notification via apex
 * @History                                                                                                                       
 * VERSION     AUTHOR              DATE            DETAIL
 * 1.0         Kapil Baliyan       25/07/2021      Initial Development(NCP-)
 * 2.0         Narayana            28/12/2021      NCP-5633
 * 3.0         Kapil Baliyan       29/06/2022      NCP-6983
 **/
public without sharing class D1_CustomNotificationUtility {
    /**
     * @description 
     * @param contactIds 
     * @param notificationName 
     * @param title 
     * @param body 
     * @param targetId 
     * @param targetPageRef 
     * @param labelParams 
     * @param titleLabelParams 
     */    
    @Future(callout=true)
    public static void notifyUsers(Set<String> contactIds, String notificationName, String title, String body, String targetId, String targetPageRef, List<String> labelParams,List<String> titleLabelParams) {
        // Get the Id for our custom notification type
        CustomNotificationType notificationType = [SELECT Id, DeveloperName FROM CustomNotificationType WHERE DeveloperName =:notificationName];
        
        if(notificationType != null){
            //Get List of Recipient
            
            Map<String, User> recipientUsersMap = new Map<String, User>([SELECT Id, LanguageLocaleKey FROM User WHERE ContactId IN :contactIds AND IsActive = TRUE]);
            
            //Get Language from users
            //String language = 'en_GB';
            Map<String, Set<String>> languageUserMap = new Map<String, Set<String>>();
            if(recipientUsersMap != null && recipientUsersMap.size()>0){
                for(User usr : recipientUsersMap.values()){
                    //language = usr.LanguageLocaleKey;
                    //break;
                    /**NCP-6983*/
                    if(languageUserMap.containsKey(usr.LanguageLocaleKey)){
                        languageUserMap.get(usr.LanguageLocaleKey).add(usr.Id);
                    }else{
                        languageUserMap.put(usr.LanguageLocaleKey, new Set<String>{usr.Id});
                    }
                }
            }
            
            // NCP-7146
            string labelParam1Val = '';
            if(labelParams!=null && labelParams.size()>1) {
                labelParam1Val = labelParams[1];
            }
            
            //NCP-6983 : Iterate over languageUserMap keyset to get language specific translation and send notification to user who belongs to that language
            if(languageUserMap != null && languageUserMap.size()>0){
                for(String language : languageUserMap.keySet()){
                    //Create labelNames List
                    List<String> labelNames = new List<String>{title, body};
                    // NCP-7146
                    if(labelParams!=null && labelParams.size()>1 && (labelParam1Val =='D1_Order_Status_Approved'||labelParam1Val =='D1_Order_Status_Rejected')){//NCP-5633
                        labelNames.add(labelParam1Val);
                    }

                    //Get Translated Title & Body based on recipient language
                    Map<String, String> labelToTranslatedStrMap = EDGE_UtilityClass.translate(labelNames, language);

                    //Replace status with translated status fetched from VF page // NCP-7146
                    if(labelParams!=null && labelParams.size()>1 && (labelParam1Val =='D1_Order_Status_Approved'|| labelParam1Val =='D1_Order_Status_Rejected')){//NCP-5633
                        labelParams[1] = labelToTranslatedStrMap.get(labelParam1Val) ;
                    }
                    string notificationBody = labelParams != null ? string.format(labelToTranslatedStrMap.get(body), labelParams) : labelToTranslatedStrMap.get(body);
                    string notificationTitle = titleLabelParams != null ? string.format(labelToTranslatedStrMap.get(title), titleLabelParams) : labelToTranslatedStrMap.get(title);
                    
                    // Create a new custom notification
                    Messaging.CustomNotification notification = new Messaging.CustomNotification();

                    // Set the contents for the notification
                    notification.setTitle(notificationTitle);
                    notification.setBody(notificationBody);

                    // Set the notification type and target
                    notification.setNotificationTypeId(notificationType.Id);

                    //Set targetId or targetPageRef
                    if(String.isNotBlank(targetId)){
                        notification.setTargetId(targetId);
                    }

                    if(String.isNotBlank(targetPageRef)){
                        Map<String, Object> communityPageRef = new Map<String, Object>{
                            'type' => 'standard__webPage',
                            'attributes' => new Map<String, Object>{
                                'url' => '/' + targetPageRef
                            }
                        };
                        String targetPageReff = JSON.serialize(communityPageRef);
                        notification.setTargetPageRef(targetPageReff);
                    }

                    // Actually send the notification
                    try {
                        notification.send(languageUserMap.get(language));
                    }
                    catch (Exception e) {
                        System.debug(LoggingLevel.ERROR, e.getMessage());
                    }
                }
            }
        }
    }
}