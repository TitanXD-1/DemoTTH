/**
* @description EDGE_SupplierOutletTriggerHelper
* @history
                                                         
VERSION   AUTHOR                            DATE              DETAIL
1.0    Kapil Baliyan                        06/02/2019      Initial Development
1.1    Anuja Chatterjee/Saurav Paul         06-mar-2019     ES20-408
1.2    Manikant Prasad                      24-dec-2019     ES20-6592 (UpdateLastModMasterFld)
1.3    Monalisa Halder                      31/01/2020		ES20-9212 
1.4    Monalisa Halder     					24/02/2022		ES20-11303
1.5    Monalisa Halder                      12/03/2022		ES20-12274
1.6    Vikash Chaudhary                     20/09/2022		NCP-7326
1.7    Rajarshi Lahiri/Shivam Chauhan		05/04/2022		ES20-13958
**/
public with sharing class EDGE_SupplierOutletTriggerHelper {
    
    /**
    * @description checkPrimarySuppOutlt
    * @Purpose  This method will check only one Distributor/Wholesaler can be identified as the primary source of supply.
    * @return  
	* @param map
    */
    
    public static void checkPrimarySuppOutlt(List<SObject> suppOutltList, Map<Id,SObject> oldMap, Boolean isUpdate){
        //Variables
        Set<Id> outletIdSet = new Set<Id>(); 
        Set<Id> distWholeslrIdSet = new Set<Id>();
        List<Supplier_Outlet__c> exstnSupOutltList = new List<Supplier_Outlet__c>();
        Map<Id,List<Supplier_Outlet__c>> exstnSupOutltMap = new Map<Id,List<Supplier_Outlet__c>>();
        List<Account> lstOutletWithDistributor = new List<Account>();
        //Variables
        
        
        for(SObject sObj : suppOutltList){
            Supplier_Outlet__c suppOutObj = (Supplier_Outlet__c)sObj;
            //Checking for Update logic
            if(isUpdate && oldMap!= null && suppOutObj.isPrimary__c && oldMap.containsKey(suppOutObj.Id)){
                Supplier_Outlet__c oldSuppOutObj = (Supplier_Outlet__c)oldMap.get(suppOutObj.Id);
                if((suppOutObj.isPrimary__c && suppOutObj.isPrimary__c != oldSuppOutObj.isPrimary__c)/*|| 
                   (oldSuppOutObj.Distributor_Wholesaler__c != suppOutObj.Distributor_Wholesaler__c || 
                    oldSuppOutObj.Outlet__c != suppOutObj.Outlet__c)*/
                  ){                        
                      outletIdSet.add(suppOutObj.Outlet__c);
                      distWholeslrIdSet.add(suppOutObj.Distributor_Wholesaler__c);
                  }
            }else if(!isUpdate && suppOutObj.isPrimary__c){ //Checking for new create logic
                outletIdSet.add(suppOutObj.Outlet__c);
                distWholeslrIdSet.add(suppOutObj.Distributor_Wholesaler__c);
            }
        }
                
        //Getting existing Supplier_Outlet record
        if(!outletIdSet.isEmpty()){
            if(Schema.sObjectType.Supplier_Outlet__c.isAccessible()){
                exstnSupOutltList = [SELECT Id,Distributor_Wholesaler__c,Outlet__c,isPrimary__c 
                                     FROM Supplier_Outlet__c
                                     WHERE Outlet__c IN : outletIdSet and isPrimary__c= TRUE ];
            }
        }
        
        for(Supplier_Outlet__c supOut : exstnSupOutltList){
            if(exstnSupOutltMap.containsKey(supOut.Outlet__c)){
                exstnSupOutltMap.get(supOut.Outlet__c).add(supOut);
            }else{
                exstnSupOutltMap.put(supOut.Outlet__c, new List<Supplier_Outlet__c>{supOut});
            }
        }
        
        //Check for Duplicate IsPrimary else update the Primary Distributor
        if(!exstnSupOutltList.isEmpty()){
            for(SObject sObj : suppOutltList){                
                Supplier_Outlet__c suppOutltObj = (Supplier_Outlet__c)sObj;
                if(exstnSupOutltMap.containsKey(suppOutltObj.outlet__c) && suppOutltObj.isPrimary__c){
                    suppOutltObj.addError(Label.Primary_Supplier_Outlet_Error); 
                } else if(!exstnSupOutltMap.containsKey(suppOutltObj.outlet__c) && suppOutltObj.isPrimary__c){
                    Account updateOutlet = new Account(Id = suppOutltObj.Outlet__c);
                    updateOutlet.Primary_Distributor__c = suppOutltObj.Distributor_Wholesaler__c;
                    lstOutletWithDistributor.add(updateOutlet);                        
                }
            }
        } else {
            for(SObject sObj : suppOutltList){ 
                Supplier_Outlet__c suppOutltObj = (Supplier_Outlet__c)sObj;
                if(suppOutltObj.isPrimary__c){
                    Account updateOutlet = new Account(Id = suppOutltObj.Outlet__c);
                    updateOutlet.Primary_Distributor__c = suppOutltObj.Distributor_Wholesaler__c;
                    lstOutletWithDistributor.add(updateOutlet);                        
                } else if(isUpdate && oldMap!= null && !suppOutltObj.isPrimary__c && oldMap.containsKey(suppOutltObj.Id)){
                    Supplier_Outlet__c oldSuppOutObj = (Supplier_Outlet__c)oldMap.get(suppOutltObj.Id);
                    if(oldSuppOutObj.isPrimary__c != suppOutltObj.isPrimary__c){
                        Account updateOutlet = new Account(Id = suppOutltObj.Outlet__c);
                        updateOutlet.Primary_Distributor__c = null;
                        lstOutletWithDistributor.add(updateOutlet); 
                    }
                    
                }                   
            }
        } 
        
        if(lstOutletWithDistributor != null && lstOutletWithDistributor.size()>0){
            Database.update(lstOutletWithDistributor, false);
        }
    }
    
    /**
    * @description validateFieldsPerFS
    * @Purpose  Static Method to get Field Permission per field
    * @return  
	* @param map
    */
    public static void validateFieldsPerFS(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        
        String relatedObjectName = 'Supplier_Outlet__c';
        Map<Id, Id> supOtltIdToCountryIdMap = new Map<Id, Id>();
        Map<Id, Id> supOtltIdToAccRecTypeIdMap = new Map<Id, Id>();
        Schema.DescribeSObjectResult sObjectDescReslt = Schema.SObjectType.Supplier_Outlet__c ;
        
        for(Supplier_Outlet__c suppOutletRec : [Select Id , Outlet__r.Country__c , Outlet__r.RecordTypeId from Supplier_Outlet__c where Id in :newItems.keySet()]){
           supOtltIdToCountryIdMap.put(suppOutletRec.Id, suppOutletRec.Outlet__r.Country__c);
           supOtltIdToAccRecTypeIdMap.put(suppOutletRec.Id, suppOutletRec.Outlet__r.RecordTypeId);
        }
        
        EDGE_ValidationWrapper edgeValWrapper = new EDGE_ValidationWrapper();
        edgeValWrapper.newItems = newItems;
        edgeValWrapper.oldItems = oldItems;
        edgeValWrapper.sObjectDescReslt = sObjectDescReslt;
        edgeValWrapper.relatedObjectName = relatedObjectName;
        edgeValWrapper.childRecIdToCountryIdMap = supOtltIdToCountryIdMap;
        edgeValWrapper.childRecIdToAccRecTypeIdMap = supOtltIdToAccRecTypeIdMap;
        
        EDGE_UtilityClass.validateFieldsPerFS(edgeValWrapper); 
    }
    

    
	/**
    * @description createFieldChangeRequest
    * @Purpose  Create Field Change Request for approval process(ES20-9212 )
    * @return  
	* @param map
    */
    
    public static void createFieldChangeRequest(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){ 
        Map<String,Field_Permission__c> fieldPermissionOtherMap = new Map<String,Field_Permission__c>();
        Id profileId= Userinfo.getProfileId();
        String profileName=[SELECT Id,Name FROM Profile WHERE Id=:profileId].Name;
        if(profileName== 'Sales Representative' && !EDGE_UtilityClass.stopTriggerToRun){
            Id managerID = [SELECT Id,ManagerId FROM User WHERE Id=: UserInfo.getUserId()].ManagerId;        
            MAP<Id,Account> ouletCountryMap = new MAP<Id,Account>();
            List<Field_Change_Request__c> fcrInsertList = new List<Field_Change_Request__c>();       
            Set<Id> outletIdSet = new Set<Id>();
            Map<String,String> outletSuppFieldSetMAP  = new Map<String,String>();
            
            EDGE_UtilityClass.populateFieldPermissionMaps('Supplier_Outlet__c', null,null,fieldPermissionOtherMap, null, null);
                                         
            for(SObject sObj : newItems.values()){
                Supplier_Outlet__c newSupplierOutlet = (Supplier_Outlet__c)sObj;
                outletIdSet.add(newSupplierOutlet.Outlet__c); 
            }
            ouletCountryMap = new Map<Id,Account>([SELECT ID,Country__c FROM Account WHERE Id IN :outletIdSet]);
             
            for(SObject sObj : newItems.values()){
                Supplier_Outlet__c newSuppOutlet = (Supplier_Outlet__c)sObj;
                Supplier_Outlet__c oldSuppOutlet;
                if(oldItems!= null && oldItems.containsKey(newSuppOutlet.Id)){
                    oldSuppOutlet = (Supplier_Outlet__c)oldItems.get(newSuppOutlet.Id);
                } 
                //instantiate FieldChangeRequest                
                for(String field: fieldPermissionOtherMap.keySet()){
                    System.debug('field = '+ field);
                    System.debug('newSuppOutlet.get(field) = '+ newSuppOutlet.get(field));
                    System.debug('oldSuppOutlet.get(field) = '+ oldSuppOutlet.get(field));
                    if(newSuppOutlet.get(field) != oldSuppOutlet.get(field)){ //add outlet check                   
                        Field_Change_Request__c fcr = new Field_Change_Request__c();
                        fcr.MDM_Approval_required__c = false;
                        fcr.Sales_manager_approval_required__c = false;
                        //String key = '';
                        if(ouletCountryMap.get(newSuppOutlet.Outlet__c) != null){
                            fcr.Geography__c = ouletCountryMap.get(newSuppOutlet.Outlet__c).Country__c;
                           // key = ouletCountryMap.get(newSuppOutlet.Outlet__c).Country__c+'_'+metaDataApprovalMap.get(field);      
                        } 
                        
                        if(fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_Sales_Manager_Required)){                                                           
                                fcr.Sales_manager_approval_required__c = true;
                        }else if(fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Sales_Manager_Required)){                           
                            System.debug('In here ');
                            fcr.MDM_Approval_required__c = true;
                            fcr.Sales_manager_approval_required__c = true;
                        }else if(fieldPermissionOtherMap.get(field)!=null && fieldPermissionOtherMap.get(field).Permission__c.containsIgnoreCase(System.Label.EDGE_MDM_Approval_Required)){
                            fcr.MDM_Approval_required__c = true;
                        }
                        fcr.Approver__c = managerID;
                        fcr.Field_Name__c = field;                    
                        fcr.New_Value__c = String.valueOf(newSuppOutlet.get(field));
                        fcr.Old_Value__c = String.valueOf(oldSuppOutlet.get(field));
                        fcr.Changed_By__c = UserInfo.getUserId();
                        fcr.Supplier_Outlet__c = newSuppOutlet.Id;
                        //fcr.Status__c = 'New';//ES20-13958
                        fcr.Object_Type__c = 'Supplier_Outlet__c';
                        if(EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field)!= null){
                            fcr.Field_Type__c = EDGE_UtilityClass.getFieldType(fcr.Object_Type__c,field);    
                        }
                        if(fcr.Field_Type__c == 'REFERENCE'){

                           // ES20-12274
                            /*Id newId = (Id)newSuppOutlet.get(field);
                            String objectName = newId.getSObjectType().getDescribe().getName();*/
                            String objectName = '';
                            Id newId = (Id)newSuppOutlet.get(field);
                            Id oldId = (Id)oldSuppOutlet.get(field);  
                            if(newId != null){
                                objectName = newId.getSObjectType().getDescribe().getName();     
                            }else if(oldId != null){
                                objectName = oldId.getSObjectType().getDescribe().getName(); 
                            }

                            //25-Feb
                            fcr.Lookup_Object_Type__c = objectName;
                            
            			}
                        
                        if(fcr.MDM_Approval_required__c == true || fcr.Sales_manager_approval_required__c == true){
                        fcrInsertList.add(fcr);
                        newSuppOutlet.put(field,oldSuppOutlet.get(field)); // reassign the old value 
                    }
                }
                }
            }// big for
            Database.SaveResult[] srList = new Database.SaveResult[]{};
            if(!fcrInsertList.isEmpty() && Schema.sObjectType.Field_Change_Request__c.isCreateable()){
                srList = Database.insert(fcrInsertList,false); 
            }
            if(!srList.isEmpty()){
                for(Database.saveResult sr : srList){
                    if(sr.isSuccess()){
                        System.debug('FCR Inserted');    
                    }  
                    else{
                        for(Database.Error err : sr.getErrors()){
                            System.debug('****error****'+err.getMessage()+'*****'+err.getFields());
                        }
                    }
                }     
            }
        }
    }
    /**
    * @description removePrimarySupplier
    * @Purpose  This method will remove primary supplier from Outlet
    * @return  
	* @param List
    */
   
    public static void removePrimarySupplier(List<Supplier_Outlet__c> oldItems){
        List<Account> lstOutletWithDistributor = new List<Account>();
        if(oldItems != null){
            for(Supplier_Outlet__c supplierOutlet : oldItems){
                if(supplierOutlet.isPrimary__c){
                    Account updateOutlet = new Account(Id = supplierOutlet.Outlet__c);
                    updateOutlet.Primary_Distributor__c = null;
                    lstOutletWithDistributor.add(updateOutlet);
                }
            }
            
            if(lstOutletWithDistributor != null && lstOutletWithDistributor.size()>0){
                Database.update(lstOutletWithDistributor, false);                
            }
        }
    }
    /**
    * @description UpdateLastModMasterFld
    * @Purpose  if the value of the feilds containing in the FieldSet is
              changed then the 'Last Modify Master Data' field will be updated with current date and time .
    * @return  
	* @param Map
    */
    
    public static void updateLastModMasterFld(Map<Id, SObject> newItems, Map<Id, SObject> oldItems){
        // Variables
        Set<Id> suppOutIdSet = new Set<Id>();    
        Set<Id> outletIdSet = new Set<id>();
        Set<String> fieldsSet = new Set<String>();
        List<Account> accList = new List<Account>();
        Map<Id,List<String>> suppFieldValueMap = new Map<Id,List<String>>();
        Map<Id,Supplier_Outlet__c> oldsuppOutMap,newsuppOutMap;
        
        if(oldItems !=null){
            oldsuppOutMap = (Map<Id,Supplier_Outlet__c>) oldItems;            
        }
        if(newItems != null){
            newsuppOutMap= (Map<Id,Supplier_Outlet__c>) newItems;
        }        
        for(Schema.FieldSetMember fld : SObjectType.Supplier_Outlet__c.fieldSets.getMap().get('Master_Data_Fields_of_Supplier_outlet').getFields()){
            fieldsSet.add(fld.fieldpath);
        } 
        if(newsuppOutMap != null && !newsuppOutMap.isEmpty()){
            for( Id suppOutId : newsuppOutMap.keySet()){
                for(String fieldName : fieldsSet){
                    if(newsuppOutMap.get(suppOutId) != null && newsuppOutMap.get(suppOutId).get(fieldName) != oldsuppOutMap.get(suppOutId).get(fieldName)){
                        outletIdSet.add(newsuppOutMap.get(suppOutId).outlet__c);
                        break;
                    }                
                }
            } 
        }        
        if(outletIdSet !=null && !outletIdSet.isEmpty()){
            for( Account acc : [select id , sos_beer_target__c,Last_Modify_Data_Master__c from Account where id IN:outletIdSet]){
                acc.Last_Modify_Data_Master__c = system.now();
                accList.add(acc);
            }
        }
        if(Schema.sObjectType.Account.isUpdateable() && accList.size() >0 ){
            Database.update(accList);   
        }
        
    }
    /**
    * @description syncPreferredWholesaler
    * @Purpose  This method will sync between EDGE Primary wholesaler record and preferred wholesaler record.  
    */
    public static void syncPreferredWholesaler(Map<Id, sObject> mapOldItem, List<sObject> newList){
        Boolean isUpdate = mapOldItem != null ? true : false;
        for(sObject supplierOutlet : newList){
            Supplier_Outlet__c suppOutObj = (Supplier_Outlet__c)supplierOutlet;
            
            if(isUpdate && mapOldItem != null && mapOldItem.containsKey(suppOutObj.Id)){
                Supplier_Outlet__c oldSuppOutObj = (Supplier_Outlet__c)mapOldItem.get(suppOutObj.Id);
                if(suppOutObj.isPrimary__c != oldSuppOutObj.isPrimary__c && suppOutObj.isPrimary__c){
                    suppOutObj.Preferred_Wholesaler__c = true;
                }else if(suppOutObj.isPrimary__c != oldSuppOutObj.isPrimary__c && !suppOutObj.isPrimary__c){
                    suppOutObj.Preferred_Wholesaler__c = false;
                }
            }else if(!isUpdate && suppOutObj.isPrimary__c){ //If isPrimary is true mark Preferred Wholesaler as true
                suppOutObj.Preferred_Wholesaler__c = true;
            }
        }
    } 
   
}