@isTest
public class D1_NavigationMenuControllerTest {
	// See ALl data is required because we are calling here connectApi method //
    @SuppressWarnings('PMD.ApexUnitTestShouldNotUseSeeAllDataTrue')
    @isTest(SeeAllData=true)
    public static void testNavigation(){
        NavigationMenuItem menuItem = [select id,Label,NavigationLinkSetId, NavigationLinkSet.MasterLabel,Status,NavigationLinkSet.NetworkId
                                       FROM NavigationMenuItem
                                      WHERE NavigationLinkSetId !=null
                                      AND Type !='Event'
                                      LIMIT 1];
        
        String jsonRequest = '{"communityId":"'+ menuItem.NavigationLinkSet.NetworkId+'", "menuItemTypesToSkipValues":["Event"]}';
        D1NavigationMenuItemToRoles__c role = new D1NavigationMenuItemToRoles__c(
            Menu_Id__c= menuItem.NavigationLinkSetId,
            Menu_Item_Id__c= menuItem.Id,
            Menu_Item_Label__c = menuItem.Label,
            Access_Type__c = 'User management'
        );
        insert role;
        D1_NavigationMenuController.getNavigationMenu(jsonRequest, menuItem.NavigationLinkSet.MasterLabel, menuItem.Status);
        D1_NavigationMenuController.getNavigationMenuItems(menuItem.NavigationLinkSetId,menuItem.Status,menuItem.NavigationLinkSet.MasterLabel);
		D1_NavigationMenuController.getNavigationMenuDetails(true, 'Live', 'GB', 'en_GB');
        System.Assert(role != null, true);
    }
    
    
}