public with sharing class D1NavigationMenuItem {
   
    @AuraEnabled
    public static Map<String, String> getNavigationMenuOptions(String menuName){
        Map<String, String> menuOptions = new Map<String, String>();
        List<NavigationLinkSet> linkSets = getNavigationMenu(null);
        for(NavigationLinkSet menu: linkSets){
            menuOptions.put(menu.Id, menu.MasterLabel);
        }

        return menuOptions;
    }
    @AuraEnabled
    public static List<NavigationLinkSet> getNavigationMenu(String menuName){
        
        String networkId = [Select Id, Name from Network where name ='DiageoOne'].Id;//NOPMD
        String query = 'SELECT Id,MasterLabel FROM NavigationLinkSet Where ';
        if(menuName != null){
            query += ' Id =: menuName  AND NetworkId =:networkId ';
        }else{
            query += ' NetworkId =:networkId';
        }

        List<NavigationLinkSet> linkSets = Database.query(query);
        
       
        return linkSets;
    }
    @AuraEnabled
    public static Map<String, String> getNavigationMenuItem(String menuNameId){
        Map<String, String> menuOptions = new Map<String, String>();
        List<NavigationMenuItem> menuItems = [SELECT Id, Label, Target, Type, DefaultListViewId, AccessRestriction,
                                                    ParentId,
                                                    Position,
                                                    Status,
                                                    TargetPrefs
                                                FROM NavigationMenuItem
                                                WHERE NavigationLinkSetId = :menuNameId and status = 'Live'
                                            ];
    
        for(NavigationMenuItem item: menuItems){
            menuOptions.put(item.Id, item.Label);
        }

        return menuOptions;   
    }

    @AuraEnabled //get AccessType Picklist Values
    public static Map<String, String> getAccessType(){
        Map<String, String> options = new Map<String, String>();
        Schema.DescribeFieldResult fieldResult = D1NavigationMenuItemToRoles__c.Access_Type__c.getDescribe();
        List<Schema.PicklistEntry> pList = fieldResult.getPicklistValues();
        for (Schema.PicklistEntry p: pList) {
            //Put Picklist Value & Label in Map
            options.put(p.getValue(), p.getLabel());
        }
        return options;
    }
    @AuraEnabled
    public static EditRecordWrapper getEditRecordData(String recordId){
        
        EditRecordWrapper editRecord = new EditRecordWrapper();
        List<D1NavigationMenuItemToRoles__c> navigations = [Select id, Menu_Id__c,Menu_Label__c, Menu_Item_Id__c,Menu_Item_Label__c,Access_Type__c from D1NavigationMenuItemToRoles__c where ID =:recordId ];
        for(D1NavigationMenuItemToRoles__c item: navigations){
            editRecord.navigationMenu = item.Menu_Label__c;
            editRecord.navigationMenuId = item.Menu_Id__c;
            editRecord.navigationMenuItem = item.Menu_Item_Label__c;
            editRecord.navigationMenuItemId = item.Menu_Item_Id__c;
            editRecord.navigationAccessType = item.Access_Type__c;
            editRecord.isEditRecord = true;

        }
        return editRecord;
    }

    public class EditRecordWrapper{
        @AuraEnabled public String navigationMenu {get;set;}
        @AuraEnabled public String navigationMenuId {get;set;}
        @AuraEnabled public String navigationMenuItem {get;set;}
        @AuraEnabled public String navigationMenuItemId {get;set;}
        @AuraEnabled public String navigationAccessType {get;set;}
        @AuraEnabled public boolean isEditRecord {get;set;}
    }
}