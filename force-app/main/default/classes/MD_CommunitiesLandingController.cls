/**
 * An apex page controller that takes the user to the right start page based on credentials or lack thereof
 */
public without sharing class MD_CommunitiesLandingController {
    
    // Code we will invoke on page load.
    public PageReference forwardToStartPage() {
        System.debug('CG - in CommunitiesLandingController.fowardToStartPage() method. userId: ' + UserInfo.getUserId());
        String userId = UserInfo.getUserId();

        try{
            successLoginActions(userId);
        }catch(Exception ignored) {
            System.debug('CG - in CommunitiesLandingController.successLoginActions() method. EXCEPTION: ' + userId);
        }

        return Network.communitiesLanding();
    }
    
    public MD_CommunitiesLandingController() {}

    @TestVisible
    private void successLoginActions(Id userId){
        User currentUser = MD_UserSessionUtil.getUser();

        System.debug('CG - in MD_CommunitiesLandingController.successLoginActions() method. currentUser: ' + currentUser);

        if(currentUser != null){
            System.debug('CG - in CommunitiesLandingController.successLoginActions() method. userId: ' + currentUser.Id);
            
            /* harakaki - CMS integration - BEGIN */
            String countryCode = MD_UserSessionUtil.getDefaultCookieValue(currentUser.Id);
            
            if(String.isNotEmpty(countryCode)) {
                System.debug('CG - in CommunitiesLandingController.successLoginActions() method. countryCode: ' + countryCode);

                List<DiageoCMS__Cluster__c> rootClusters = [SELECT Id FROM DiageoCMS__Cluster__c 
                                                            WHERE RecordType.DeveloperName = 'ClusterRoot'
                                                            LIMIT 1];

                List<DiageoCMS__Cluster__c> clusters = [SELECT Id FROM DiageoCMS__Cluster__c 
                                                            WHERE DiageoCMS__ExternalId__c = :countryCode 
                                                            LIMIT 1];
                if(clusters.size() > 0) {
                    Id clusterId = clusters.get(0).Id;

                    System.debug('CG - in CommunitiesLandingController.successLoginActions() method. clusters: ' + clusters);
                    
                    Id contactId = currentUser.ContactId;
                    Id accountId = currentUser.Contact.MD_CurrentOutlet__c != null ? currentUser.Contact.MD_CurrentOutlet__c : null;
                    
                    DiageoCMS.CMSUserSettingsUtils.updateUserSettings(userId, clusterId, accountId, contactId, userId);

                    System.debug('CG - in CommunitiesLandingController.successLoginActions() method. currentUser.DiageoCMS__ClusterUsers__r.size(): ' + currentUser.DiageoCMS__ClusterUsers__r.size());

                    if(currentUser.DiageoCMS__ClusterUsers__r.size() < 1) {
                        DiageoCMS__ClusterUser__c clusterUser = new DiageoCMS__ClusterUser__c();
                        clusterUser.DiageoCMS__AccessLevel__c = 'Read Only';
                        clusterUser.DiageoCMS__Cluster__c = rootClusters.get(0).Id;
                        clusterUser.DiageoCMS__User__c = userId;

                        insert clusterUser;

                        System.debug('CG - in MD_CommunitiesLandingController.successLoginActions() method. clusterUser.Id: ' + clusterUser.Id);
                    }
                }
            }
            /* harakaki - CMS integration - END */

            MD_UserSessionUtil.userIdlogin = currentUser.Id;
            MD_UserSessionUtil.setSessionSettingsFields(currentUser.Id);
            MD_UserSessionUtil.updateUserSessionSettings();
            MD_UserSessionUtil.setContactFields(true);
        }
    }
}