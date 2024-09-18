/*
 * Class Name : EDGE_SalesOrganisationTriggerHelper
 * @description: This is Sales Organisation Trigger Helper
 * @history
 * VERSION    AUTHOR                DATE              DETAIL
* 1.0        CST Team 		19/05/2021        Initial Development
*/
public without sharing class EDGE_SalesOrganisationTriggerHelper {
    
   
    /*
	* @description : checkAndGenerateSharing
	* @return : void
	* @param : List<Sales_Organisation__c>
	*/


    public static void checkAndGenerateSharing(List<Sales_Organisation__c> newItems){
        //List<Sales_Organisation__c> newItems = new List<Sales_Organisation__c>();
       // newItems = (List<Sales_Organisation__c>) sObjs;
        EDGE_SharingUtil.validateCreatePermission(newItems, 'Country__c');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Up', 'Read');
        EDGE_SharingUtil.generateSharingFromGeography(newItems, 'Country__c', 'Down', 'Edit');        
    }
    

    /*
	* @description : validateAndReGenerateSharing
	* @return : void
	* @param : List<Sales_Organisation__c>,Map<Id, SObject>
	*/


    public static void validateAndReGenerateSharing(List<Sales_Organisation__c> newItems,Map<Id,SObject> oldItems){

        Map<Id, Sales_Organisation__c > mapOldItems;
        List<Sales_Organisation__c > lstNewChangeGeography = new List<Sales_Organisation__c >();
        List<Sales_Organisation__c > lstOldChangeGeography = new List<Sales_Organisation__c >();
        
        EDGE_SharingUtil.validateEditPermission(newItems);
        
       /* if(oldItems != null){
            mapOldItems = (Map<Id,Sales_Organisation__c>)oldItems;
        }
        */
        for(Sales_Organisation__c  objSales : newItems){
            Sales_Organisation__c salesOrgObj = new Sales_Organisation__c();
            salesOrgObj = oldItems.containsKey(objSales.Id)?(Sales_Organisation__c)oldItems.get(objSales.Id):null;
            if(salesOrgObj != null && objSales.Country__c != salesOrgObj.Country__c){
                lstNewChangeGeography.add(objSales);
                lstOldChangeGeography.add(salesOrgObj);
            }
        }
        
        if(lstNewChangeGeography != null && lstNewChangeGeography.size()>0){
            EDGE_SharingUtil.validateCreatePermission(lstNewChangeGeography, 'Country__c');
            EDGE_SharingUtil.updateSharingRecords(lstNewChangeGeography, lstOldChangeGeography, 'Country__c');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Up', 'Read');
            EDGE_SharingUtil.generateSharingFromGeography(lstNewChangeGeography, 'Country__c', 'Down', 'Edit');
        }       
    }
    
    
    /*
*@Method  : createPublicGroup
*@Purpose : Create and Update group name 
*/       
    public static void createSalesOrgPublicGroup(Map<Id,SObject> newItems){
        List<Group> groupLst=new List<Group>();
        List<Group> groups=new List<Group>();
        Set<String> groupName = new Set<String>();
        List<Sales_Organisation__c> newOrgs=new List<Sales_Organisation__c>();
        Map<Id,String> mapSalesOrgGroup = new Map<Id,String>();
        Map<String,Id> mapGroupSalesOrg = new Map<String,Id>();
        List<SObject> listOfSharesToInsert = new List<SObject>();
        Schema.SObjectType shareType;
        try{
          //PION-1698 : retrieving the salesorg record type to eliminate public groups creation for pioneer regional groups
          Map<ID, Schema.RecordTypeInfo> rtMap = Schema.SObjectType.Sales_Organisation__c.getRecordTypeInfosById();
          
            if(newItems != null && newItems.size()>0){                
                newOrgs=(List<Sales_Organisation__c>)newItems.values();              
                for(Sales_Organisation__c salesOrg:newOrgs){
                    groupName.add('SO_('+salesOrg.Code__c+')_Read');
                    groupName.add('SO_('+salesOrg.Code__c+')_Write');

                    //groupName.add('SO_('+salesOrg.Code__c+')_Write');

                    mapGroupSalesOrg.put('SO_'+salesOrg.Code__c+'_Read', salesOrg.Id);
                }
                if(groupName != null && groupName.size()>0){
                    for(Group grp : [SELECT Id FROM Group where Name IN :groupName]){
                        groupLst.add(grp);
                    } 
                } 
                if(groupLst.size()==0){
                    for(Sales_Organisation__c so:newOrgs){
                        if(rtMap.get(so.RecordTypeId).getDeveloperName() != 'Regional_Group'){
                        Group gp1=new Group();
                        gp1.name='SO_('+String.valueOf(so.Code__c)+')_Read';
                        Group gp2=new Group();
                        gp2.name='SO_('+String.valueOf(so.Code__c)+')_Write';
                        groups.add(gp2);
                        groups.add(gp1);
                    }    
                }          
            }
            }
            if(groups.size()>0 && groups!=null)
                insert groups; 
            
            
           if(mapGroupSalesOrg != null && mapGroupSalesOrg.size()>0 && Schema.sObjectType.Group.isAccessible()){
                for(Group objGroup: [SELECT Id, DeveloperName FROM Group WHERE DeveloperName IN: mapGroupSalesOrg.keySet()]){
                    mapSalesOrgGroup.put(mapGroupSalesOrg.get(objGroup.DeveloperName), objGroup.Id);
                }            
            } 
            
            //Used to create the list of Share record per Share Object
            if(mapSalesOrgGroup != null && mapSalesOrgGroup.size()>0){
				for(Sales_Organisation__c salesOrg:newOrgs){                           
                            shareType = Schema.getGlobalDescribe().get('Sales_Organisation__Share');
                            SObject shareRecord = shareType.newSObject();
                            shareRecord.put('ParentId', salesOrg.Id);
                            shareRecord.put('UserOrGroupId', mapSalesOrgGroup.get(salesOrg.Id));
                            shareRecord.put('RowCause', 'Sales_Org_Sharing__c');
                            shareRecord.put('AccessLevel', 'Read');
                            listOfSharesToInsert.add(shareRecord);                                                                            
                } 
                
                if(listOfSharesToInsert != null && listOfSharesToInsert.size()>0 && shareType.getDescribe().isCreateable()){
                    insert listOfSharesToInsert;
                }
            }
  
        }
        catch(Exception excption){
            List<SObject> errorItem= newItems.values();
            System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
            new EDGE_GenericException(excption, errorItem[0]);
        }
    }
    
    /*
*@Method  : deletePublicGroup
*@Purpose : Delete group name 
*/ 
    public static void deleteSalesOrgPublicGroup(Map<Id,sObject> oldItems)
    {
        List<Group> groups=new List<Group>();
        List<Sales_Organisation__c> oldOrgs=new List<Sales_Organisation__c>();
        Set<String> groupName = new Set<String>();
        if(oldItems != null && oldItems.size()>0)
        {
            oldOrgs=(List<Sales_Organisation__c>)oldItems.values();
            for(Sales_Organisation__c salesOrg:oldOrgs)
            {
                groupName.add('SO_('+salesOrg.Code__c+')_Read');
                groupName.add('SO_('+salesOrg.Code__c+')_Write');
            }
            if(groupName != null && groupName.size()>0){
                for(Group grp : [SELECT Id FROM Group where Name IN :groupName]){
                    groups.add(grp);
                } 
            } 
            if(groups != null && groups.size()>0)
            {
                try{
                    delete groups;
                }                
                catch(Exception excption){
                    List<SObject> errorItem= oldItems.values();
                    System.debug('Exception:::'+excption.getLineNumber()+excption.getCause()+excption.getMessage());
                    new EDGE_GenericException(excption, errorItem[0]);                    
                }
            }            
        }  
    }
}