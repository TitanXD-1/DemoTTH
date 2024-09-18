public without sharing class D1_TermsAndConditionTriggerHelper {
    
    //before update
    public static void activateordraftJMLValidation(List<SObject> newTermsAndConditions, Map<Id, SObject> oldTermsAndConditions){
        List<D1_Terms_Conditions__c> newItems = new List<D1_Terms_Conditions__c>() ;
        Map<Id,D1_Terms_Conditions__c> oldItems = new Map<Id,D1_Terms_Conditions__c>();
        set<id> markets= new set<id>();
        Set<Id> marketIdSalesArea = new Set<Id>();
        if(newTermsAndConditions !=null){
            newItems = (List<D1_Terms_Conditions__c>) newTermsAndConditions;
        }
        if(oldTermsAndConditions !=null){
            oldItems = (Map<Id,D1_Terms_Conditions__c>) oldTermsAndConditions;
        }
        if(oldItems != null || oldItems.size()>0){   
            for(D1_Terms_Conditions__c n:newItems){
                markets.add(n.Market__c);
                string namevalue = n.Reference_To_Status__c;
                if((oldItems.get(n.id).Status__c=='Inactive' || !namevalue.contains('Inactive')) && oldItems.get(n.id).Status__c != 'Draft' && n.Status__c != null && n.Version__c == oldItems.get(n.id).Version__c)
                {
                    n.addError('Edit operation is not allowed on Active/Inactive records.');
                }
            }
            
            for(D1_Setting__c d1sett : [SELECT Id,Enable_Sales_Area_Terms_and_Conditions__c
                                        FROM D1_Setting__c 
                                        WHERE Id=:markets AND Enable_Sales_Area_Terms_and_Conditions__c = true])
            {
                marketIdSalesArea.add(d1sett.Id);
            }
            //Replacing with parameter
            Id orderRecordType = Schema.SObjectType.D1_Terms_Conditions__c.getRecordTypeInfosByName().get('Order Terms and Condition').getRecordTypeId();
            for(D1_Terms_Conditions__c o:newItems){                    
                if(!marketIdSalesArea.contains(o.Market__c)){
                    o.Sales_Area__c = null;
                }
                if(marketIdSalesArea.contains(o.Market__c) && o.Sales_Area__c == null && o.recordtypeid == orderRecordType){
                    o.addError('Please input sales area');
                }
            }
        }
    }
    
    public static void activateordraftJML(List<SObject> newTermsAndConditions, Map<Id, SObject> oldTermsAndConditions){
        if(!EDGE_UtilityClass.stopSecondTriggerToRun){
            Map<String,D1_Terms_Conditions__c> versionrecords = new Map<String,D1_Terms_Conditions__c>();
            Map<String,D1_Terms_Conditions__c> activeversionrecords = new Map<String,D1_Terms_Conditions__c>();//NCP-3907
            List<D1_Terms_Conditions__c> newItems = new List<D1_Terms_Conditions__c>() ;
            Map<Id,D1_Terms_Conditions__c> oldItems = new Map<Id,D1_Terms_Conditions__c>();
            Map<Id,D1_Terms_Conditions__c> updateJML = new Map<Id,D1_Terms_Conditions__c>();
            
            if(newTermsAndConditions !=null){
                newItems = (List<D1_Terms_Conditions__c>) newTermsAndConditions;
            }
            if(oldTermsAndConditions !=null){
                oldItems = (Map<Id,D1_Terms_Conditions__c>) oldTermsAndConditions;
            }
            //before insert
            if(oldItems == null || oldItems.size()==0){
                set<id> markets= new set<id>();
                Set<Id> marketIdSalesArea = new Set<Id>();
                for(D1_Terms_Conditions__c o:newItems){
                    markets.add(o.Market__c);
                   
                    o.Reference_To_Status__c = o.name;
                    if(o.Status__c !='Draft'){
                        o.addError('Please select the status as Draft for new records');
                    }
                }
                for(D1_Setting__c d1sett : [SELECT Id,Enable_Sales_Area_Terms_and_Conditions__c
                                            FROM D1_Setting__c 
                                            WHERE Id=:markets AND Enable_Sales_Area_Terms_and_Conditions__c = true])
                {
                    marketIdSalesArea.add(d1sett.Id);
                }
                //NCP-3907 getting latest active record based on market
                for(D1_Terms_Conditions__c activerecord:[SELECT id,Market__c,Status__c,Version__c,recordTypeId,Releases__c,Name,Reference_To_Status__c,Sales_Area__c
                                                         FROM D1_Terms_Conditions__c  WHERE Market__c IN:markets AND Status__c='Active' ORDER BY Version__c ASC ]){
                                                            String uniqueid = activerecord.Market__c + '' + activerecord.recordTypeId;
                                                            if(marketIdSalesArea.contains(activerecord.Market__c) && activerecord.Sales_Area__c!=null){
                                                                    uniqueid = uniqueid + '' + activerecord.Sales_Area__c;
                                                            }
                                                            activeversionrecords.put(uniqueid,activerecord);
                                                         }
                for(D1_Terms_Conditions__c o:newItems){               
                    if(!marketIdSalesArea.contains(o.Market__c)){
                        o.Sales_Area__c = null;
                    }
                    String uniqueStr = o.Market__c + '' + o.recordTypeId;
                    if(marketIdSalesArea.contains(o.Market__c) && o.Sales_Area__c!=null){
                        uniqueStr = uniqueStr +''+o.Sales_Area__c;
                    }
                    if(activeversionrecords.size()>0 && activeversionrecords.get(uniqueStr)!=null){ //US 150154:PMD Fix
                        o.Version__c = activeversionrecords.get(uniqueStr).Version__c;//NCP-3907
                    }
                }
            }
            //after update
            else if(oldItems != null || oldItems.size()>0){
                set<id> markets= new set<id>();
                
                for(D1_Terms_Conditions__c termscondition:newItems){
                    markets.add(termscondition.Market__c);
                }
                
                Set<Id> marketIdSalesArea = new Set<Id>();
                for(D1_Setting__c d1sett : [SELECT Id,Enable_Sales_Area_Terms_and_Conditions__c
                                            FROM D1_Setting__c 
                                            WHERE Id=:markets AND Enable_Sales_Area_Terms_and_Conditions__c = true])
                {
                    marketIdSalesArea.add(d1sett.Id);
                }
                
                Id orderRecordType = Schema.SObjectType.D1_Terms_Conditions__c.getRecordTypeInfosByName().get('Order Terms and Condition').getRecordTypeId();
                for(D1_Terms_Conditions__c activerecord:[SELECT id,Market__c,Status__c,Version__c,recordTypeId,Releases__c,Name,Reference_To_Status__c,Sales_Area__c
                                                         FROM D1_Terms_Conditions__c  WHERE Market__c IN:markets AND Id not in:newItems ORDER BY Version__c ASC ])
                {
                    String uniqueid = activerecord.Market__c + '' + activerecord.recordTypeId;
                    if( activerecord.Status__c == 'Active')
                    {
                        if(marketIdSalesArea.contains(activerecord.Market__c) && activerecord.Sales_Area__c!=null && activerecord.RecordTypeId==orderRecordType){
                            uniqueid = uniqueid + '' + activerecord.Sales_Area__c;
                        }
                        versionrecords.put(uniqueid,activerecord);
                    }
                }
                for(D1_Terms_Conditions__c n:newItems){
                    if(oldItems.get(n.id).Status__c == 'Draft' && n.Status__c == 'Active'){
                        D1_Terms_Conditions__c clonedTerms = new D1_Terms_Conditions__c();
                        String uniqueId = n.Market__c + '' + n.recordTypeId;
                        if(marketIdSalesArea.contains(n.Market__c) && n.Sales_Area__c!=null){
                            uniqueId = uniqueId +''+n.Sales_Area__c;
                        }
                        D1_Terms_Conditions__c terms = new D1_Terms_Conditions__c();
                        D1_Terms_Conditions__c terms2 = new D1_Terms_Conditions__c();
                        if(versionrecords !=null && versionrecords.size()>0 && (versionrecords.get(uniqueId) != null) && (versionrecords.get(uniqueId).Id !=null)){
                            terms = versionrecords.get(uniqueId);                
                            terms2 = terms.clone(true,false,false,false);
                            terms2.Status__c = 'Inactive';
                            terms2.Reference_To_Status__c=terms2.name + ' Inactive';
                            updateJML.put(terms2.Id,terms2);
                            
                            double versionVal = 1;
                            if( n.Releases__c=='Minor Releases'){
                                decimal decvalue= versionrecords.get(uniqueId).Version__c-versionrecords.get(uniqueId).Version__c.intValue();
                                if(decvalue !=0.9){
                                    versionVal= versionrecords.get(uniqueId).Version__c+0.1;
                                }
                                else{
                                    n.addError('We have reached the max Minor Releases. Please create the Major Releases');
                                }
                            }
                            else if( n.Releases__c=='Major Releases'){
                                versionVal= versionrecords.get(uniqueId).Version__c.intValue()+1;
                            }
                            clonedTerms.Name = n.Name;
                            clonedTerms.Reference_To_Status__c = n.Name +' Active';
                            clonedTerms.Version__c = versionVal;
                            clonedTerms.Id =n.Id;
                            clonedTerms.Sales_Area__c = (!marketIdSalesArea.contains(n.Market__c))?null:n.Sales_Area__c;
                            updateJML.put(clonedTerms.Id,clonedTerms);
                        }
                        else{
                            clonedTerms.Version__c = 1;
                            clonedTerms.Id =n.Id;
                            if(Test.isRunningTest()){ //US 150154:PMD Fix
                                clonedTerms.Status__c = 'Active';
                            }
                            updateJML.put(clonedTerms.Id,clonedTerms);
                        }
                        
                    }
                }
            }
            if(updateJML != null && updateJML.size()>0){
                update updateJML.values();
            }
        }
        if(!Test.isRunningTest()){
            EDGE_UtilityClass.stopSecondTriggerToRun= true;
        }
    }
}