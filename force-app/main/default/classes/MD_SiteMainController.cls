/**************************************************************************************
Apex Class Name  :  MD_SiteMainController 
Version          :  1.0
Created Date     :  11/04/2018
Release          :  R1
Function         :  It retrieves all the data needed by the CP_BaseTheme component
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Julio enrique             19/04/2018              Original Version
* Hernan Arakaki            22/08/2018              INC6254608 - MyDiageo.com - footer not appearing when logged-in
* Angel Rodriguez           03/10/2018              ECOM-814 - Analytics - Advanced Analytics Tracking for MyDiageo
* Hernan Arakaki            08/10/2018              ECOM-814 - Analytics - Advanced Analytics Tracking for MyDiageo - Fix
* Angel Rodriguez           03/10/2018              ECOM-814 - Analytics - Advanced Analytics Tracking for MyDiageo
* Elena Schwarzbock         09/11/2018              ECOM-1333 - Dynamic Navigations Component 
******************************************************************************/
public without sharing class MD_SiteMainController {
    
    public String clusterId {get;set;}
    public Boolean doPostLogin {get;set;}
    public String countryCode {get;set;}
    
    public MD_UserInfoWrapper userInfo {get;set;}

    public MD_SiteMainController() {
        MD_PostLoginController instance = new MD_PostLoginController(false);
        doPostLogin = instance.doPostLogin;
        countryCode = instance.countryCode;
        userInfo = new MD_UserInfoWrapper();
    }

    @auraEnabled
    public static String getRedirectURL(){
        Profile loggedProfile = [SELECT UserLicense.Name FROM Profile WHERE Id =: UserInfo.getProfileId()];
        if (loggedProfile.UserLicense.Name == Label.MD_MyDiageUserLicense){
            return MD_GeneralSettings.getBaseURL();
        }
        return '';
    }
    
    @AuraEnabled
    public static Object initPageTemplate(Boolean resolveCluster) {

        if(MD_UserSessionUtil.isLoggedUser()){
            MD_SiteMainController instance = new MD_SiteMainController();

            if(resolveCluster) {
                System.debug('CG - in MD_SiteMainController.initPageTemplate() method. instance.countryCode: ' + instance.countryCode);
                String clusterExternalId = instance.countryCode != null ? instance.countryCode : MD_UserSessionUtil.getUser().Contact.MD_CurrentOutlet__r.Country__r.Code__c;

                List<DiageoCMS__Cluster__c> clusters = [SELECT Id, DiageoCMS__ExternalId__c FROM DiageoCMS__Cluster__c WHERE DiageoCMS__ExternalId__c = :clusterExternalId];
                if(clusters.size() > 0) {
                    instance.clusterId = clusters.get(0).Id;
                    instance.countryCode = clusters.get(0).DiageoCMS__ExternalId__c;
                }
            }

            return JSON.serialize(instance);
        }else{
            List<MD_ClusterWrapper> clusterList = new List<MD_ClusterWrapper>();

            for(MD_ClusterWrapper cw : getClusterByIsCountry()) {
                if (cw.value == 'ES') {
                    clusterList.add(cw);
                }
            }
            
            return JSON.serialize(clusterList);
        }
    }

    @AuraEnabled
    public static Object initPageTemplateGuest(){
        MD_SiteMainController instance = new MD_SiteMainController();
        return JSON.serialize(instance);
    }
    
    @AuraEnabled
    public static String getSidebarExternalId(String urlPath, String device, String clusterId){
        if(clusterId == null || clusterId.trim() == ''){
            clusterId = DiageoCMS.ClusterUtils.getClusterIdFromMappingObject(UserInfo.getUserId(), Network.getNetworkId());
        }
        Set<String> parentClusterIds = DiageoCMS.ClusterUtils.getClustersParents(clusterId);
        List<DiageoCMS__Menu__c> menuList = [SELECT DiageoCMS__ParentMenu__c 
                                             	FROM DiageoCMS__Menu__c 
                                             	WHERE DiageoCMS__ParentMenu__c != null 
                                             		AND DiageoCMS__Navigation__r.DiageoCMS__URL__c = :urlPath
                                             		AND (DiageoCMS__DisplayOn__c = 'Both'
                                                  	OR DiageoCMS__DisplayOn__c = :device)
                                                    AND DiageoCMS__ComponentName__c = null];
        Set<Id> menuIds = new Set<Id>();
        for(DiageoCMS__Menu__c m : menuList){
            menuIds.add(m.DiageoCMS__ParentMenu__c);
        }
        List<DiageoCMS__MenuAssignment__c> assignmentList = [SELECT DiageoCMS__Component__r.DiageoCMS__ExternalId__c 
                                                             	FROM DiageoCMS__MenuAssignment__c 
                                                             	WHERE DiageoCMS__Menu__c IN :menuIds 
                                                             		AND (DiageoCMS__Menu__r.DiageoCMS__DisplayOn__c = 'Both'
                                                                  		OR DiageoCMS__Menu__r.DiageoCMS__DisplayOn__c = :device)
                                                            		AND DiageoCMS__Menu__r.DiageoCMS__Cluster__c IN :parentClusterIds
                                                            		AND DiageoCMS__Component__r.ShowInSidebar__c = true];
        if(!assignmentList.isEmpty()){
            return assignmentList.get(0).DiageoCMS__Component__r.DiageoCMS__ExternalId__c;
        }
        return null;
    }
    
    
    

    /*
    * @Author : Angel Rodriguez
    * @description : To get a list of CP_Cluster__c when the field IsCountry__c it's true
    * @returns : A List<CP_ClusterWrapper>
    */
    public static List<MD_ClusterWrapper> getClusterByIsCountry(){
        List<MD_ClusterWrapper> clusterList = new List<MD_ClusterWrapper>();
        
        /* CMS Implementation */
        for(DiageoCMS__Cluster__c cluster: [SELECT Id, Name, DiageoCMS__ExternalId__c 
                                                FROM DiageoCMS__Cluster__c 
                                                WHERE RecordType.DeveloperName = 'ClusterLeaf']){
            clusterList.add(new MD_ClusterWrapper(cluster.Name,cluster.DiageoCMS__ExternalId__c, cluster.Id));
        }
        
        return clusterList;
    }

    //ECOM-814 - Analytics - Advanced Analytics Tracking for MyDiageo
    public class MD_UserInfoWrapper {
        public String userId {get;set;}
        public String accountType {get;set;}
        public String userLanguage {get;set;}
        public String userCountry {get;set;}

        public MD_UserInfoWrapper(){
            this.userId = System.UserInfo.getUserId();
            this.userLanguage = System.UserInfo.getLanguage();
            AccountContactRelation accountTypeOutlet = MD_UserSessionUtil.getOutletContact();
            if(accountTypeOutlet != null) {
                this.userCountry = accountTypeOutlet.Account.BillingCountry;
                this.accountType = accountTypeOutlet.MD_Role__c;
            }
        }
    }

    public class MD_ClusterWrapper {
        public String clusterId {get;set;}
        public String label {get;set;}
        public String value {get;set;}
        public String lowerValue {get;set;}

        public MD_ClusterWrapper(String label, String value, String clusterId){
            this.clusterId = clusterId;
            this.value = value;
            this.label = label;
            this.lowerValue = value.toLowerCase();
        }
    }
    //ECOM-814 - Analytics - Advanced Analytics Tracking for MyDiageo

}