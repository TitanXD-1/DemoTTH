@isTest
public class D1NavigationMenuItemTest {
    @isTest
    public static void testNavigation(){
       	
        
        NavigationMenuItem menuItem = [select id,Label,NavigationLinkSetId, NavigationLinkSet.MasterLabel,Status,NavigationLinkSet.NetworkId,ParentId
                                       FROM NavigationMenuItem
                                      WHERE NavigationLinkSetId !=null
                                      AND Type !='Event'
                                      LIMIT 1];
        
        D1NavigationMenuItemToRoles__c navRole = new D1NavigationMenuItemToRoles__c(
            Menu_Id__c= menuItem.NavigationLinkSetId,
            Menu_Item_Id__c= menuItem.Id,
            Menu_Item_Label__c = menuItem.Label,
            Access_Type__c = 'Ordering'
        );
        insert navRole;
        Test.startTest();
        Map<String, String> menuOption = new Map<String, String>();
        menuOption = D1NavigationMenuItem.getNavigationMenuOptions(menuItem.NavigationLinkSet.MasterLabel);
        System.assert(menuOption != NULL, 'menu option not found');
        D1NavigationMenuItem.getNavigationMenu(menuItem.NavigationLinkSet.MasterLabel);
        Map<String, String> menuItems = new Map<String, String>();
        menuItems = D1NavigationMenuItem.getNavigationMenuItem(menuItem.NavigationLinkSetId);
        System.assert(menuItems != NULL, 'menu item not found');
        Map<String, String> option = new Map<String, String>();
        option = D1NavigationMenuItem.getAccessType();
        System.assert(option != NULL, 'access type not found');
        D1NavigationMenuItem.getEditRecordData(navRole.Id);
        Test.stopTest();
        
    }

}