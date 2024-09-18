@isTest
public class D1_NavigationControllerTest {
	@isTest
    public static void testNavigationMenuOption(){
       	
        
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
        D1_NavigationController.getNavigationMenuOptions(menuItem.NavigationLinkSet.MasterLabel);
        D1_NavigationController.getNavigationMenu(menuItem.NavigationLinkSet.MasterLabel);
        D1_NavigationController.getNavigationMenuItem(menuItem.NavigationLinkSetId,menuItem.ParentId);
        Map<String, String> acsType = new Map<String, String>();
        acsType = D1_NavigationController.getAccessType();
        System.assert(acsType != NULL, 'Access type not found');
        Test.stopTest();
        
    }
}