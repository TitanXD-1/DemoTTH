/**************************************************************************************
Apex Class Name  :  MD_GeneralSettings.cls  
Version          :  1.0
Created Date     :  22/05/2018
Release          :  R1
Function         :  Util class that exposes the Custom Setting 'CP_GeneralSettings' values
Modification Log :
-----------------------------------------------------------------------------
* Developer                   Date                   Description
* ----------------------------------------------------------------------------
* Julio Enrique             22/05/2018              Original Version
* Hernan Arakaki            19/08/2018              ECOM 949 - Empties: Collect Excess Kegs component
* Hernan Arakaki            19/08/2018              ECOM 956 - Empties: Keg Request submission process
******************************************************************************/
public class MD_GeneralSettings {
    
    private static MD_GeneralSettings__c settings{get{
        if(settings == null){
            settings = MD_GeneralSettings__c.getOrgDefaults();
        }
        return settings;
    }set;}

    public static String getServiceURL(){
        return settings.ServiceURL__c;
    }
    public static String getDiscoverURL(){
        return settings.DiscoverURL__c;
    }
    public static String getLogoutURL(){
        return settings.LogoutURL__c;
    }
    public static String getCheckoutUrl(){
        return settings.CheckoutURL__c;
    }
    public static String getShopUrl(){
        return settings.ShopURL__c;
    }
    public static String getOutletDetailUrl(){
        return settings.OutletDetailURL__c;
    }
    public static String getMyProfilelUrl(){
        return settings.MyProfileURL__c;
    }
    public static String getMyInvoiceUrl(){
        return settings.MyProfileURL__c;
    }
    public static String getOrderHistoryUrl(){
        return settings.OrderHistoryURL__c;
    }
    public static String getAccountDocumentsUrl() {
        return settings.AccountDocumentsURL__c;
    }
    public static String getMyQueriesUrl(){
        return settings.MyQueriesURL__c;
    }
    public static String getHomeUrl(){
        return settings.HomeURL__c;
    }
    public static String getMyUsersURL(){
        return settings.MyUsersURL__c;
    }
    public static String getCommunityImageURL(){
        return settings.CommunityImageURL__c;
    }
    public static String getBackendImageURL(){
        return settings.BackendImageURL__c;
    }
    public static String getBaseURL(){
        return URL.getSalesforceBaseUrl().toExternalForm();
    }
    public static String getSalesOrderHeaderURL() {
        return settings.SalesOrderHeaderURL__c;
    }

    public static String getUserDetailURL() {
        return settings.UserDetailURL__c;
    }

    public static String getContentURL() {
        return settings.ContentURL__c;
    }

    public static String getCollectMyEmptiesURL() {
        return settings.CollectMyEmptiesURL__c;
    }
    //ECOM-949 - BEGIN
    public static String getKegCollectionMaxQuantity (){
        return String.valueOf(settings.KegCollectionMaxQuantity__c);
    }
    public static String getKegCollectionMinQuantity (){
        return String.valueOf(settings.KegCollectionMinQuantity__c);
    }
    //ECOM-949 - END
    //ECOM-956 - BEGIN
    public static String getCollectEmptiesImageKegDevName (){
        return settings.DiageoKegImage__c;
    }
    //ECOM-956 - END
}