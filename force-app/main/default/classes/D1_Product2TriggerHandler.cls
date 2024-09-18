/**
 * @name D1_Product2TriggerHandler
 * @history                                                                                                                       
 * VERSION   AUTHOR            DATE              DETAIL
 * 1.0       Praveen           15/12/2020        NCP-1402
 * 1.1       Mukesh Kanth      09/02/2021        NCP-1942 (updateProductCardTitle)
 * 1.2 	  Darshi Arpitha    22/02/2021        NCP-2259  (set Hierarchies)
 * 1.3 	  Darshi Arpitha    08/03/2021        NCP-2339
 * 2         Ajay              25/05/2021        NCP-3357(setupProductCategory)
**/
public class D1_Product2TriggerHandler {
    /**
     * @description setProductHierarchies method
     * @param {List<Product2>} newItems 
     */    
    public static void setProductHierarchies(List<Product2> newItems){
        
        Set<String> brandHierarchyCodeSet = new Set<String>();
        Set<String> volConfigHierarchyCodeSet = new Set<String>();
        Map<String, Product__c> customProdMap = new Map<String,Product__c>();//to store all Product__c
        Map<String, Product_Volume_Configuration__c> volConfigMap = new Map<String, Product_Volume_Configuration__c>();//to store all Product_Volume_Configuration__c
        Id brandVariantId = Schema.SObjectType.Product__c.getRecordTypeInfosByName().get('Brand Variant').getRecordTypeId();//RecordTypeId of Brand Variant
        Id skuId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();
        
        //get Hierachy_Code__c from each record based on it's length
        if(!newItems.isEmpty()){
            
            for(Product2 newprod : newItems){
                
                //if any of the below fields are empty then populate them
                if(newprod.Brand_Variant__c == null ||newprod.D1_Category__c == null ||newprod.D1_Type__c == null ||newprod.D1_Brand__c == null || newprod.Level_6__c == null || newprod.D1_Size__c == null ||newprod.Level_7__c == null )
                {
                    String codeStr = newprod.Hierarchy__c;
                    if(String.isNotBlank(codeStr) && codeStr.length() == 18 && newprod.RecordTypeId == skuId){
                        //this is L5 product
                        brandHierarchyCodeSet.add(codeStr.substring(0,12));
                        //this is L6 product code
                        volConfigHierarchyCodeSet.add(codeStr.substring(12,15) + '6');
                        //this is L7 product code
                        volConfigHierarchyCodeSet.add(codeStr.substring(15,18) + '7');
                    }
                }
                
            }
        }
        
        //Get Brand Variant Product
        if(!brandHierarchyCodeSet.isEmpty()){
            
            //NCP-2339 Starts
            String productStatusLabel = System.Label.D1_Product_Status; //fetch Product Status Label
            Set<String> statusValues = new Set<String>();
            String sourceSystemlabel = System.Label.D1_Product_Source; //fetch Product Source Label
            Set<String> sourceValues = new Set<String>();
            
            if(productStatusLabel != null && sourceSystemlabel != null)
            {
                //loop to split the Label values 
                for(String str : productStatusLabel.split(';'))
                {
                    statusValues.add(str);
                }
                for(String str : sourceSystemlabel.split(';'))
                {
                    sourceValues.add(str);
                }
            }
            //NCP-2339 Ends
            
            for(Product__c customProd : [SELECT Id, SAP_Hierarchy_code__c, Classification__c, Category__c, Brand_Formula__c FROM Product__c 
                                         WHERE SAP_Hierarchy_code__c =:brandHierarchyCodeSet AND RecordTypeId =:brandVariantId
                                         AND UPI_Status__c IN: statusValues AND Source_System__c IN: sourceValues])
            {
                customProdMap.put(customProd.SAP_Hierarchy_code__c, customProd);
            }
        }
        
        //Get Product Volume Config
        if(!volConfigHierarchyCodeSet.isEmpty()){
            for(Product_Volume_Configuration__c volConfig : [SELECT Id, Type__c, Code__c, IntegrationID__c,Name FROM Product_Volume_Configuration__c 
                                                             WHERE IntegrationID__c =:volConfigHierarchyCodeSet])
            {
                volConfigMap.put(volConfig.IntegrationID__c, volConfig);
            }
        }
        
        //for each record link the Product__c and Product_Volume_Configuration__c
        if(!newItems.isEmpty()){
            for(Product2 prod : newItems){
                if(String.isNotBlank(prod.Hierarchy__c) && prod.RecordTypeId == skuId){
                    string hierarchyCode = prod.Hierarchy__c;
                    string brandVariantCode = hierarchyCode.substring(0,12);
                    string l6Code = hierarchyCode.substring(12,15) + '6';
                    string l7Code = hierarchyCode.substring(15,18) + '7';
                    
                    //Assign Brand Variant to Product
                    if(customProdMap!=null && customProdMap.containsKey(brandVariantCode)){
                        Product__c customProd = customProdMap.get(brandVariantCode);
                        prod.Brand_Variant__c = customProd.Id;
                        prod.D1_Category__c = customProd.Classification__c;
                        prod.D1_Type__c = customProd.Category__c;
                        prod.D1_Brand__c = customProd.Brand_Formula__c;
                    }
                    //Assign Product Volume Config (L6)
                    if(volConfigMap!=null && volConfigMap.containsKey(l6Code)){
                        prod.Level_6__c = volConfigMap.get(l6Code).Id;
                        prod.D1_Size__c = volConfigMap.get(l6Code).Name;
                    }
                    //Assign Product Volume Config (L7)
                    if(volConfigMap!=null && volConfigMap.containsKey(l7Code)){
                        prod.Level_7__c = volConfigMap.get(l7Code).Id;
                    }
                }
            }
        }
    }
    
     /**
     * @description Setup Product Category Product
     * @param {List<Product2>} newProducts product2list
     * @param {Map<id, sObject>} oldItems product2OldMap
     */
    public static void setupProductCategory(List<Product2> newProducts, Map<id, sObject> oldItems){
        final String parentCategory1 = 'Product';
        
        Map<id, Product2> oldProductsMap = oldItems == null ? null : (Map<id, Product2>) oldItems;
        Boolean isVerifyOldItems = oldProductsMap !=null;

        List<Product2> productsToProcess = new List<Product2>();
        Set<Id> productsToProcessIdSet = new Set<Id>();
        Set<String> categoriesToQuery = new Set<String>();
        for (Product2 newProduct2 : newProducts) {
            if((isVerifyOldItems == false && newProduct2.D1_Category__c !=null)
                || (isVerifyOldItems == true && newProduct2.D1_Category__c != oldProductsMap.get(newProduct2.Id).get('D1_Category__c'))
            ){
                productsToProcess.add(newProduct2);
                productsToProcessIdSet.add(newProduct2.Id);
                categoriesToQuery.add(newProduct2.D1_Category__c);
            }
        }
        
        if(productsToProcess.isEmpty()){
            return;
        }

        List<ProductCatalog> catalogues = [SELECT Id FROM ProductCatalog WHERE Name =: System.Label.D1_Commerse_CatalogName];
        
        Map<String, Id> mapOfCategoryNameToId = new Map<String, Id>();
        categoriesToQuery.add(parentCategory1);
        for(ProductCategory category: [SELECT id,Name 
                                       FROM ProductCategory
                                       WHERE Name IN :categoriesToQuery
                                      ]
        ){
            mapOfCategoryNameToId.put(category.Name, category.Id);
        }

        if(catalogues.isEmpty() || !mapOfCategoryNameToId.containsKey(parentCategory1)){
            throw new customException('Catalog or Parent category Not found');
        }

        ProductCatalog catalog = catalogues[0];
        ProductCategory parentCategory = new ProductCategory(Id= mapOfCategoryNameToId.get(parentCategory1), Name = parentCategory1);

        Set<String> requiredCategories = categoriesToQuery;
        Set<String> existingCategories = mapOfCategoryNameToId.keySet();
        Set<String> insertCategories = removeAll(requiredCategories, existingCategories);
        
        List<ProductCategory> categoriesToInsert = new List<ProductCategory>();
        for (String categoryName : insertCategories) {
            categoriesToInsert.add(createProductCategory(catalog.Id, parentCategory.Id, categoryName));
        }

        if(!categoriesToInsert.isEmpty()){
            //Insert Product Category
            insert categoriesToInsert;
            for (ProductCategory category : categoriesToInsert) {
                mapOfCategoryNameToId.put(category.Name, category.Id);
            }
        }

        List<ProductCategoryProduct> productCategoriesToDelete = new List<ProductCategoryProduct>();
        for (ProductCategoryProduct productCategory : [SELECT Id, ProductId, Product.D1_Category__c, ProductCategoryId, ProductCategory.Name 
                                                       FROM ProductCategoryProduct  
                                                       WHERE ProductId IN: productsToProcessIdSet
                                                       AND CatalogId =: catalog.Id]
        ) {
            if(validateIsAutoCreatedProductCategory(productCategory, oldProductsMap)){
                productCategoriesToDelete.add(productCategory);
            }
        }

        List<ProductCategoryProduct> productCategoriesToInsert = new List<ProductCategoryProduct>();
        for(Product2 product: productsToProcess){
            productCategoriesToInsert.add(createProductCategoryProduct(product.Id, mapOfCategoryNameToId.get(product.D1_Category__c)));
        }

        if(!productCategoriesToDelete.isEmpty()){
            delete productCategoriesToDelete;
        }

        if(!productCategoriesToInsert.isEmpty()){
            insert productCategoriesToInsert;
        }

    }

    /**
     * @description Verify 'ProductCategoryProduct' is created by Trigger
     *              Admin can create ProductCategoryProduct like 'Best Seller, New, Keg', Those should not be deleted if category updates
     *              Verified by checking 'D1_Category__c' field value
     * @param {ProductCategoryProduct} productCategory
     * @param {oldProductsMap} oldProductsMap
     * @return {Boolean}
     */
    public static Boolean validateIsAutoCreatedProductCategory(ProductCategoryProduct productCategory, Map<Id, Product2> oldProductsMap){
        if(oldProductsMap?.get(productCategory.ProductId)?.D1_Category__c == productCategory.ProductCategory.Name){
            return true;
        }

        return false;
    }
    
    /**
     * @description createProductCategory method
     * @param catalogId 
     * @param categoryId 
     * @param categoryName 
     * @return  `ProductCategory`
     */    
    public static ProductCategory createProductCategory(Id catalogId, Id categoryId, string categoryName){
        ProductCategory category = new ProductCategory();
        category.catalogId = catalogId;
        category.ParentCategoryId = categoryId;
        category.Name = categoryName; 
        
        return category;
    }
    
    /**
     * @description createProductCategoryProduct method
     * @param productId 
     * @param categoryId 
     * @return  `ProductCategoryProduct`
     */    
    public static ProductCategoryProduct createProductCategoryProduct(Id productId, Id categoryId){
        ProductCategoryProduct productCategory = new ProductCategoryProduct();
        productCategory.ProductCategoryId = categoryId;
        productCategory.ProductId = productId;
        
        
        return productCategory; 
        
    }
    
    /**
     * @description This method is use to populated 'Product Card Title' with the first 70 characters of the Product Name
     *              when a Product with record type SKU is created or updated on the Product2 object.
     * @param newProducts 
     * @param oldItems 
     */    
    public static void updateProductCardTitle(List<Product2> newProducts, Map<id, SObject> oldItems){
        Map<Id, Product2> oldProducts;
        Id productRecordTypeId = Schema.SObjectType.Product2.getRecordTypeInfosByName().get('SKU').getRecordTypeId();   
        if(oldItems != null){
            oldProducts = (Map<Id, Product2>)oldItems;
        }
        for(Product2 prod : newProducts){
            if(prod.RecordTypeId == productRecordTypeId && 
               ((oldItems == null && prod.Name != null) || (oldItems!= null && prod.Name != oldProducts.get(prod.Id).Name))){
                   if(prod.Name.length()<70){
                       prod.Product_Card_Title__c = prod.Name;
                   }else{
                       prod.Product_Card_Title__c = prod.Name.substring(0,70);
                   }
               }
        }
    }

    /**
     * @description Remove items from Source if contains target (No Source/ Target change)
     * @param {Set} source
     * @param {Set} target
     * @return {Set} source - target
     */
    private static Set<String> removeAll(Set<String> source, Set<String> target){
        Set<String> copy = new Set<String>(source);
        copy.removeAll(target);
        return copy;
    }

    /**
     * Custom Exception
     */
    public class CustomException extends Exception {}
}