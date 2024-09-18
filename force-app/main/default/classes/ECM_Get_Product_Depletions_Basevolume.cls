/**********************************************************************
Name: ECM_Get_Product_Depletions_Basevolume
=======================================================================
Purpose: This Class is used to fetch the Depletion records to get consolidated volume with the product and outlet combinations
=======================================================================
History                                                            
-------                                                            
VERSION    AUTHOR                DATE              DETAIL
1.0                           03/03/2020        Initial Development
2.0      Anivesh Muppa        02/03/2021       Modified as per INC19779930

***********************************************************************/
public without sharing class ECM_Get_Product_Depletions_Basevolume { 
    public static Map < id, decimal > ECM_Get_Product_Depletions_Basevolume(List < ECM_Contract_Item__c > selectedrecords, contract contra,Date deplition_startdate, boolean isAus) {
        map < string, ECM_Contract_Item__c > set_string_selected_contractitem = new map < string, ECM_Contract_Item__c > ();
        map < string, ECM_Contract_Item__c > set_string_exsisiting_contractitem = new map < string, ECM_Contract_Item__c > ();
        Map < id, decimal > product_BaseVol = new Map < id, decimal > (); //new List<Depletions__c>();
        Set < id > matchingproductrecords = new Set < id > ();
       
        if (selectedrecords.size() > 0) {
            date startdate = deplition_startdate;
            startdate = Date.newInstance(startdate.year() - 1, startdate.month(), startdate.day());
            date enddate; //Date.newInstance(enddate.year()-1, enddate.month(), enddate.day());
            if(isAus){
                enddate = deplition_startdate.toStartOfMonth();
                startdate = startdate.toStartOfMonth();
            }
            else{
                enddate = deplition_startdate - 1;
            }

            set < id > outletids = new set < id > ();
            list < contract > groupcontracts = new list < contract > ();
            list < contract > con = new List<contract>();
            if(isAus){
                if(contra.RecordType.Name == 'Group'){
                    if((contra.ECM_Channel__c == 'Hybrid' || contra.Account.Hybrid__c) && contra.Account.Parent_Outlet__c != null){
                        if(contra.Account.Parent_Outlet__r.Hybrid__c && contra.Account.Parent_Outlet__r.Parent_Outlet__c == null){
                            outletids.add(contra.Account.Parent_Outlet__c);
                        }
                    }
                    if(contra.ECM_Channel__c == 'On-Premise' || !contra.Account.Hybrid__c){
                        outletids.add(contra.AccountId);
                    }
                }
                else{
                    if(contra.ECM_Channel__c == 'On-Premise' || !contra.Account.Hybrid__c){
                        outletids.add(contra.AccountId);
                    }else{
                        //regarding INC19779930
                        if((contra.ECM_Channel__c == 'Hybrid' || contra.Account.Hybrid__c) && contra.Account.Parent_Outlet__c != null){
                            outletids.add(contra.AccountId);
                        }                         
                        // outletids.add(contra.AccountId);
                    }
                }
                
            }
            if(!isAus){
                outletids.add(contra.AccountId);
                System.debug('Entered');
                
            }
            set<id> newOutletIds = new set<Id>();
            if(isAus){
                if(contra.RecordType.Name == 'Group'){
                    for (Outlet_Contract__c groupoutlet: [select id, Outlet__c, Contract__c, Outlet__r.Hybrid__c,Outlet__r.Parent_Outlet__c,Outlet__r.Parent_Outlet__r.Hybrid__c,Outlet__r.Parent_Outlet__r.Parent_Outlet__c from Outlet_Contract__c where Contract__c =: contra.id]) {
                        if((contra.ECM_Channel__c == 'Hybrid' || groupoutlet.Outlet__r.Hybrid__c) && groupoutlet.Outlet__r.Parent_Outlet__c != null){
                            if(groupoutlet.Outlet__r.Parent_Outlet__r.Hybrid__c && groupoutlet.Outlet__r.Parent_Outlet__r.Parent_Outlet__c == null){
                                newOutletIds.add(groupoutlet.Outlet__r.Parent_Outlet__c);
                            }
                        }
                        if(contra.ECM_Channel__c == 'On-Premise' || !groupoutlet.Outlet__r.Hybrid__c){
                            newOutletIds.add(groupoutlet.Outlet__c);
                        }
                    }
                }
            }
            if(newOutletIds.size()==0){
                if(!isAus){
                    for(Outlet_Contract__c groupoutlet :[select id,Outlet__c,Outlet__r.Hybrid__c,Outlet__r.Parent_Outlet__c,Contract__c from Outlet_Contract__c where Contract__c=:contra.id]){
                        outletids.add(groupoutlet.Outlet__c);
                    }
                }
            }
            else{
                outletids.addAll(newOutletIds);
            }
            //regarding INC19779930
            if(contra.RecordType.Name == 'Group'){
                con = [select id, Contract_End_Date__c, StartDate from contract where AccountId in: outletids  ORDER BY lastmodifieddate desc];         
            }else{
                con = [select id, Contract_End_Date__c, StartDate from contract where AccountId =: contra.AccountId  ORDER BY lastmodifieddate desc];  
            }

            system.debug('conids++' + con);
            // contra.ECM_Select_UoM__c='9LC EU';
            if (con.size() > 0) {
                for (ECM_Contract_Item__c items: [select id, ECM_Contract__r.AccountId,ECM_Product__r.Product__r.Name, ECM_Product__r.Product__c, ECM_Contract__r.ECM_Agreement_Type__c, ECM_Contract__r.Contract_End_Date__c from ECM_Contract_Item__c where ECM_Contract__c in: con]) { //.AccountId =: selectedrecords.ECM_Contract__r.AccountId and id not in:selectedrecords
                    string uniqueid;
                    system.debug('prod === '+items.ECM_Product__r.Product__r.Name);
                  // if(contra.RecordType.Name == 'Group' || contra.ECM_Agreement_Type__r.Geography__r.Name=='Australia'){
                    uniqueid = items.ECM_Product__r.Product__c;
                    /*
                   } else{
                       system.debug('UniqueProductid' + items.ECM_Product__r.Product__c);
                    uniqueid = items.ECM_Contract__r.AccountId+''+ items.ECM_Contract__r.ECM_Agreement_Type__c+''+ items.ECM_Product__r.Product__c;                    
                   }
                    */
                   set_string_exsisiting_contractitem.put(uniqueid, items);
                }
            }
            
            system.debug('set_string_exsisiting_contractitem' + set_string_exsisiting_contractitem);
            if (set_string_exsisiting_contractitem.size() > 0) {
                for (ECM_Contract_Item__c items: selectedrecords) {
                    string uniqueid;
                  //if(contra.RecordType.Name == 'Group' || contra.ECM_Agreement_Type__r.Geography__r.Name=='Australia'){
                    uniqueid = items.ECM_Product__r.Product__c;
                    /*
                   } else{
                    uniqueid = items.ECM_Contract__r.AccountId+''+ items.ECM_Contract__r.ECM_Agreement_Type__c + '' + items.ECM_Product__r.Product__c;
                    
                   }*/                    
                    if (set_string_exsisiting_contractitem.containskey(uniqueid)) {
                        matchingproductrecords.add(set_string_exsisiting_contractitem.get(uniqueid).ECM_Product__r.Product__c);
                    }
                }
            }
            system.debug('matchingproductrecords' + matchingproductrecords);            
            //regarding INC19779930
            if(isAus){
                if(contra.RecordType.Name != 'Group'){
                    if((contra.ECM_Channel__c == 'Hybrid' || contra.Account.Hybrid__c) && contra.Account.Parent_Outlet__c != null){
                        outletids.clear();
                        outletids.add(contra.Account.Parent_Outlet__c); 
                    }
                }
            }
            system.debug('outletids'+ outletids);
            if (matchingproductrecords.size() > 0) {
                for (Depletions__c dep: [select id, ECM_Volume__c,ECM_Product__r.Name, ECM_Outlet__c, ECM_Start_Period__c, ECM_End_Period__c, ECM_Product__c from Depletions__c where ECM_Product__c in: matchingproductrecords and ECM_Outlet__c in: outletids and ECM_Volume__c != null ]) {
                    system.debug('StartDate'+ startdate + 'enddate'+ enddate);
                    if (dep.ECM_Start_Period__c >= StartDate && dep.ECM_End_Period__c <= enddate) {
                        system.debug(dep.ECM_Product__r.Name);
                        system.debug(dep.Id);
                        if (product_BaseVol.containsKey(dep.ECM_Product__c)) {
                            Decimal Basevolumesum = product_BaseVol.get(dep.ECM_Product__c) + dep.ECM_Volume__c;
                            product_BaseVol.put(dep.ECM_Product__c, Basevolumesum);
                        } else {
                            product_BaseVol.put(dep.ECM_Product__c, dep.ECM_Volume__c);
                        }

                    }
                }
            }
        }
        return product_BaseVol;
    }

}