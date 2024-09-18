/**
* @name: D1_NavigationController
* @description : Controller class for Aura Cmp D1_NavigationMenuItemCmp
* @history 
* VERSION     AUTHOR           DATE           DETAIL
* 1.0         Vikas Panwar     14/06/2021  	Initial Development
* 2.0 	    Rubeena Naaz     21/06/2021     NCP-2472
**/
public with sharing class D1_NavigationController {
   
    /**
     * @description Method to get Navigation Menu Options
     * @param {menuName}
     * @return {Map} menuOptions
     **/
    @AuraEnabled
    public static Map<String, String> getNavigationMenuOptions(String menuName){
        Map<String, String> menuOptions = new Map<String, String>();
        List<NavigationLinkSet> linkSets = getNavigationMenu(null);
        for(NavigationLinkSet menu: linkSets){
            menuOptions.put(menu.Id, menu.MasterLabel);
        }

        return menuOptions;
    }
   
    /**
     * @description Method to get Navigation Menu
     * @param {menuName}
     * @return {List} linkSets
     **/
    public static List<NavigationLinkSet> getNavigationMenu(String menuName){
        String networkId;
        networkId = [SELECT Id, Name FROM Network WHERE Name = 'DiageoOne'].Id;
        String query = 'SELECT Id, MasterLabel FROM NavigationLinkSet Where ';
        if(menuName != null){
            query += ' Id =:menuName AND NetworkId =:networkId ';
        }else{
            query += ' NetworkId =:networkId';
        }
        List<NavigationLinkSet> linkSets = Database.query(query);

        return linkSets;
    }
    /**
     * @description Method to get Navigation Menu Item
     * @param {menuNameId}
     * @param {menuItemId}
     * @return {Map} menuOptions
     **/
    
    @AuraEnabled
    public static Map<String, String> getNavigationMenuItem(String menuNameId, string menuItemId){
        Map<String, String> menuOptions = new Map<String, String>();
        string status = 'Live'; //NOPMD
        string queryStr = 'SELECT Id, Label, Target, Type, ParentId FROM NavigationMenuItem WHERE ';
        queryStr += ' NavigationLinkSetId = :menuNameId AND Status =:status';
        if(string.isNotBlank(menuItemId)){
            queryStr += ' AND ParentId =:menuItemId';
        }else{
            queryStr += ' AND ParentId = null';
        }
        queryStr += ' ORDER BY Position';

        
        List<NavigationMenuItem> menuItems = Database.query(queryStr);
        if(!menuItems.isEmpty()){
            for(NavigationMenuItem item: menuItems){
                menuOptions.put(item.Id, item.Label);
            }
        }
        return menuOptions;   
    }

    /**
     * @description Method to get AccessType Picklist Values
     * @return {Map} options
     **/
    @AuraEnabled 
    public static Map<String, String> getAccessType(){
        final String defaultAccess ='Default Access';
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = D1NavigationMenuItemToRoles__c.Access_Type__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            options.put(p.getValue(), p.getLabel());
        }
        options.remove(defaultAccess);
        return options;
    }
}