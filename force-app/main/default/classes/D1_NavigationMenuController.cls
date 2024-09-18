/**
* @name : D1_NavigationMenuController
* @description : Navigation Menu
* @history 
* VERSION     AUTHOR         DATE           DETAIL
* 1.0         Ajay           03/06/21       Initial Development (NCP-1706)
* 2.0         Kapil Baliyan  16/06/21		  NCP-2472
**/
public with sharing class D1_NavigationMenuController {

    /**
     * Fetch Navigation Menu
     * @param {String} jsonRequest 
     * @param {String} navigationLinkSetLabel
     * @param {String} publishStatusValue
     */
    @AuraEnabled(cacheable = true)
    public static Object getNavigationMenu(String jsonRequest, String navigationLinkSetLabel, String publishStatusValue){

        //Parse Request
        RequestWrapper request = parseRequest(jsonRequest, navigationLinkSetLabel, publishStatusValue);

        //Fetch Navigation Menu Items 
        ConnectApi.NavigationMenuItemCollection menuDetails = ConnectApi.NavigationMenu.getCommunityNavigationMenu(
                                                                request.communityId, 
                                                                request.navigationLinkSetId, 
                                                                null, 
                                                                request.publishStatus, 
                                                                request.includeImageUrl, 
                                                                request.addHomeMenuItem, 
                                                                request.menuItemTypesToSkip);

        //Fetch Navigation Menu Permission
        Map<String, String> mapOfMenuItemPermission = calculateMenuItemPermission(request);
        
        return new Map<String, Object>{
            'menuDetails' => menuDetails,
            'mapOfMenuItemPermission' => mapOfMenuItemPermission
        };
    }

    /**
     * Parse Request params & consolidate all params to request object 
     * @param {String} jsonRequest 
     * @param {String} navigationLinkSetLabel
     * @param {String} publishStatusValue
     */
    private static RequestWrapper parseRequest(String jsonRequest, String navigationLinkSetLabel, String publishStatusValue){
        RequestWrapper request = (RequestWrapper) JSON.deserialize(jsonRequest, RequestWrapper.class);
        request.navigationLinkSetLabel = navigationLinkSetLabel;
        request.publishStatusValue = publishStatusValue;

        if(String.isEmpty(request.communityId)){
            throw new AuraHandledException('Community Id is required');
        }

        if(String.isEmpty(request.navigationLinkSetLabel) && String.isEmpty(request.navigationLinkSetId)){
            throw new AuraHandledException('Either navigationLinkSetLabel or navigationLinkSetId is required');
        }

        if(String.isEmpty(request.navigationLinkSetId)){
            List<NavigationLinkSet> navigationMenus = [SELECT Id,DeveloperName 
                                                        FROM NavigationLinkSet
                                                        WHERE MasterLabel = :request.navigationLinkSetLabel 
                                                        AND NetworkId = :request.communityId
                                                        LIMIT 1];
            if(navigationMenus.isEmpty()){
                throw new AuraHandledException('Invalid Navigation menu');
            }

            request.navigationLinkSetId = navigationMenus[0].Id;
        }

        if(!String.isEmpty(request.publishStatusValue)){
            request.publishStatus = resolvePublishStatus(request.publishStatusValue);
        }
        
        if(request.menuItemTypesToSkipValues != null){
            request.menuItemTypesToSkip = resolveMenuItemToSkip(request.menuItemTypesToSkipValues);
        }

        if(String.isEmpty(request.language)){
            request.language = UserInfo.getLanguage();
        }

        return request;
    }

    /**
     * Calculate Menu Item Permission @returns {'MenuItem' => 'Permission Name'}
     * @param {RequestWrapper} request
     */
    private static Map<String, String> calculateMenuItemPermission(RequestWrapper request){

        Map<String, String> mapOfMenuItemPermission = new Map<String, String>();
        Set<Id> setOfMenuItemIds = new Set<Id>();
        
        //Calculate permission from D1NavigationMenuItemToRoles__c
        for(D1NavigationMenuItemToRoles__c itemPermission:[ SELECT Id, Menu_Id__c, Menu_Item_Id__c, Menu_Item_Label__c, Access_Type__c
                                                            FROM D1NavigationMenuItemToRoles__c
                                                            WHERE Menu_Id__c =: request.navigationLinkSetId ]
        ){
            setOfMenuItemIds.add(itemPermission.Menu_Item_Id__c);
            mapOfMenuItemPermission.put(itemPermission.Menu_Item_Label__c, itemPermission.Access_Type__c);
        }

        //Replace permission key from Translation
        for(NavigationMenuItemLocalization translatedItemPermission: [ SELECT Id, Value, Parent.Label
                                                                       FROM NavigationMenuItemLocalization
                                                                       WHERE Language =: request.language
                                                                       AND ParentId IN: setOfMenuItemIds ]
        ){
            String accessType = mapOfMenuItemPermission.remove(translatedItemPermission.Parent.Label);
            mapOfMenuItemPermission.put(translatedItemPermission.Value, accessType);
        }

        return mapOfMenuItemPermission;
    }

    /**
     * Resolve Publish Status
     * @param {RequestWrapper} publishStatus
     */
    private static ConnectApi.PublishStatus resolvePublishStatus(String publishStatus) {
        for (ConnectApi.PublishStatus status : ConnectApi.PublishStatus.values()) {
            if(status.name() == publishStatus){
                return status;
            }
        }
        return null;
    }

    /**
     * @description Resolve Menu Item to skip
     * @param {List<String>} menuItemsToSkip
     */
    private static List<ConnectApi.NavigationMenuItemType> resolveMenuItemToSkip(List<String> menuItemsToSkip) {
        Set<String> menuItemsToSkipSet = new Set<String>(menuItemsToSkip);

        List<ConnectApi.NavigationMenuItemType> result = new List<ConnectApi.NavigationMenuItemType>();
        for (ConnectApi.NavigationMenuItemType type : ConnectApi.NavigationMenuItemType.values()) {
            if(menuItemsToSkipSet.contains(type.name())){
                result.add(type);
            }
        }
        return result;
    }
    /**
     * @description getNavigationMenuDetails 
     * @param  isGuestUser    isGuestUser 
     * @param  publishedState publishedState 
     * @param  countryCode    countryCode 
     * @param  language       language 
     * @return {Map}          menuItemList ,menuItemPermissionMap
     */
    @AuraEnabled(cacheable=true)
    public static Object getNavigationMenuDetails(boolean isGuestUser, string publishedState, string countryCode, string language){
        List<MenuItems> menuItemsList = new List<MenuItems>();
        Map<String, String> menuItemPermissionMap = new Map<String, String>();
        string menuName = '';
        //Get the Menu Name based on Guest User/Logged In User
        if(isGuestUser){
            List<D1_Setting__c> d1Setting  = [SELECT Id, Navigation_Menu_Name__c FROM D1_Setting__c WHERE Market__r.Code__c =:countryCode AND Language__c =:language LIMIT 1];
            if(d1Setting != null && d1Setting.size()>0){
                menuName = d1Setting.get(0).Navigation_Menu_Name__c != null ? d1Setting.get(0).Navigation_Menu_Name__c : System.Label.D1_DefaultGuestMenu;
            }
        }else{
            List<User> loggedInUser = [SELECT Id, D1_User_Type_Id__c FROM User WHERE Id =:UserInfo.getUserId() LIMIT 1];
            String userTypeId = loggedInUser.get(0).D1_User_Type_Id__c;
            if(String.isNotBlank(userTypeId)){
                List<D1_User_Type__c> userType = [SELECT Id, Navigation_Menu_Name__c FROM D1_User_Type__c WHERE Id =:userTypeId LIMIT 1];
                menuName = userType.get(0).Navigation_Menu_Name__c != NULL ? userType.get(0).Navigation_Menu_Name__c : System.Label.D1_DefaultAuthenticatedMenu; 
            }
        }
        
        if(String.isNotBlank(menuName)){
            // find the link set belonging to the navigation menuName and active networkId
            List<NavigationLinkSet> linkSets = [SELECT Id FROM NavigationLinkSet WHERE MasterLabel = :menuName];
            Id linkSetId = linkSets.get(0).Id;
            
            menuItemsList = getNavigationMenuItems(linkSetId, publishedState, null);
            menuItemPermissionMap = getNavigationMenuItemPermission(linkSetId);
        }
        
        return new Map<String, Object>{
            'menuItemsList' => menuItemsList,
            'menuItemPermissionMap' => menuItemPermissionMap
        };
    }
    
    //Added by KB
    /**
     * 
     * @param linkSetId 
     * @param publishedState 
     * @param menuName 
     * @return `List<MenuItems>`
     */   
    @AuraEnabled(cacheable=true) 
    public static List<MenuItems> getNavigationMenuItems(Id linkSetId, String publishedState, string menuName) {
        Map<Id, MenuItems> menuItemsMap = new Map<Id, MenuItems>();
        
        if(string.isNotBlank(menuName)){
            // find the link set belonging to the navigation menuName and active networkId
            List<NavigationLinkSet> linkSets = [SELECT Id FROM NavigationLinkSet WHERE MasterLabel = :menuName];
            linkSetId = linkSets.get(0).Id;
        }
        
        // collect all the menu items belonging to the link set
        // published state is either Draft or Live
        for(NavigationMenuItem menuItem : [SELECT Id, toLabel(Label), Target, Type, DefaultListViewId, AccessRestriction, ParentId, Position, Status, 
                                            TargetPrefs, NavigationLinkSetId FROM NavigationMenuItem
                                            WHERE NavigationLinkSetId = :linkSetId AND Status = :publishedState ORDER BY ParentId, Position])
        {
            MenuItems menuItems = createMenuItem(menuItem);
            if(menuItem.ParentId != null){
                MenuItems parentMenuItem = menuItemsMap.get(menuItem.ParentId);
                parentMenuItem.hasSubMenu = true;
                List<MenuItems> subMenuItemList = parentMenuItem.subMenu;
                subMenuItemList.add(menuItems);
                parentMenuItem.subMenu = subMenuItemList;
                
                menuItemsMap.put(menuItem.ParentId, parentMenuItem);
            }else{
                menuItemsMap.put(menuItem.Id, menuItems);
            }
        }

        return menuItemsMap.values();
    }
    
    //Added By KB
    /**
     * 
     * @param linkSetId 
     * @return  `Map<String, String>`
     */
    public static Map<String, String> getNavigationMenuItemPermission(String linkSetId){

        Map<String, String> menuItemPermissionMap = new Map<String, String>();
        
        //Calculate permission from D1NavigationMenuItemToRoles__c
        for(D1NavigationMenuItemToRoles__c itemPermission : [SELECT Id, Menu_Id__c, Menu_Item_Id__c, Menu_Item_Label__c, 
                                                             Sub_Menu_Item_Id__c, Sub_Menu_Item_Label__c, Access_Type__c
                                                             FROM D1NavigationMenuItemToRoles__c
                                                             WHERE Menu_Id__c =:linkSetId ORDER BY Menu_Item_Id__c, Sub_Menu_Item_Id__c])
        {
            //Add Sub Menu Item Ids
            if(String.isNotBlank(itemPermission.Sub_Menu_Item_Id__c)){
                menuItemPermissionMap.put(itemPermission.Sub_Menu_Item_Id__c, itemPermission.Access_Type__c);
            }else{
                //Add Menu Item Ids
                menuItemPermissionMap.put(itemPermission.Menu_Item_Id__c, itemPermission.Access_Type__c);
            }
        }

        return menuItemPermissionMap;
    }

    /**
     * @description Helper method
     * @param mItem 
     * @return  `MenuItems`
     */    
    private static MenuItems createMenuItem(NavigationMenuItem mItem){
        MenuItems menuItem = new MenuItems();
        menuItem.id = mItem.Id;
        menuItem.actionType = mItem.Type;
        menuItem.actionValue = mItem.Target;
        menuItem.label = mItem.Label;
        menuItem.target = mItem.TargetPrefs;
        menuItem.parentId = mItem.ParentId;
        menuItem.defaultListViewId = mItem.DefaultListViewId;
        menuItem.accessRestriction = mItem.AccessRestriction;
        menuItem.hasSubMenu = false;
        menuItem.subMenu = new List<menuItems>();
        
        return menuItem;
    }

    //Request Wrapper Class    
    public class RequestWrapper{
        //@required 
        String communityId;
        //@optional
        String navigationLinkSetId;
        Boolean includeImageUrl;
        Boolean addHomeMenuItem;
        List<String> menuItemTypesToSkipValues;
        String language;
        //@updated from other request params
        String navigationLinkSetLabel;
        String publishStatusValue;
        //@calculated
        ConnectApi.PublishStatus publishStatus;
        List<ConnectApi.NavigationMenuItemType> menuItemTypesToSkip;
    }

    //Wrapper Class
    public class MenuItems {
        @AuraEnabled public string id;
        @AuraEnabled public string actionType;
        @AuraEnabled public string actionValue;
        @AuraEnabled public string label;
        @AuraEnabled public string target;
        @AuraEnabled public string parentId;
        @AuraEnabled public string defaultListViewId;
        @AuraEnabled public string accessRestriction;
        @AuraEnabled public boolean hasSubMenu;
        @AuraEnabled public MenuItems[] subMenu;
    }
}