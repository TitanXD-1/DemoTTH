/*
* @Name: ECM_EandSTableGenerateController
* @Purpose: Contents all the methods to construct all the E&S table
* @History:                                                                                                                       
* VERSION        AUTHOR            DATE              DETAIL
* 1.0         Pratap Sen                         Initial Development
* 1.1         Pratik Somani      30/08/2022      ECM-6052 - Event Table
* 1.2         Ravi Kant          05/09/2022      ECM-6054 - Parity,Ticket & Branding Table
* 1.3         Pratik/Pratap      14/09/2022      ECM-6053,ECM-6055,ECM-6056,ECM-6057 - Pourage,Activation,Amplification,Investment,Event-Investment Tables
* 1.4		  Saurav Prasad		 29/09/2023		 146480	-	Discounts/Rebates table to reflect changes under defect 142557
* 1.5		  Doman Murmu		 18/10/2023		 147344
*/
public without sharing class ECM_EandSTableGenerateController { 
    /*Map of Template Section ES table Type/Amplification Settings value with it's Table Wrapper*/
    public static Map<String,tableWrapper> tableDataMap = new Map<String,tableWrapper>();

    /*Map of Column Name - Field API Name, Column Names, Table Header Names for all Tables*/ 
    private static Map<String,Map<String,String>> colsWithFieldAPI = new Map<String,Map<String,String>>();
    private static Map<String,List<String>> colmnNm = new Map<String,List<String>>();
    private static Map<String,String> headerNm = new Map<String,String>();

    /*
    * Name : prepareTableData
    * @description : Prepares table contents for all E&S tables (Event,Contract Item,Amplification,Event Additional Information)
    * @return : Map<String,tableWrapper>
    * @param : conRec - Contract Record, cntry - Country Code String, templateSecVal - List<String> - Template section E&S picklist field values
    */ 
    public static Map<String,tableWrapper> prepareTableData(Contract conRec, String cntry){
        System.debug('@@@Resource ES Start: CPU '+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime()+' Heap '+Limits.getHeapSize()+'/'+Limits.getLimitHeapSize()+
                    ' Query '+Limits.getQueries()+'/'+Limits.getLimitQueries());

        /*Map & List of filtered data*/
        Map<String,eventInvestmentWrapper> eventInvMap = new Map<String,eventInvestmentWrapper>();
        Map<String,String> ciType = new Map<String,String>();
        List<investmentWrapper> invWrapperList = new List<investmentWrapper>();
        List<ECM_Event_Additional_Information__c> eventInfoList = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> actvByOrg_Branding = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> actvByDiageo_BrandingMr = new List<ECM_Event_Additional_Information__c>();
        List<ECM_Event_Additional_Information__c> BrandingMr = new List<ECM_Event_Additional_Information__c>();	//147344
        
        /*Map & List to Store Queried data*/
        Map<String,List<ECM_Event_Additional_Information__c>> eventInfoMap = new Map<String,List<ECM_Event_Additional_Information__c>>(); 
        List<ECM_Event__c> eventList = new List<ECM_Event__c>();
        List<ECM_Amplification__c> amplificationList = new List<ECM_Amplification__c>();
        List<ECM_Contract_Item__c> ciList = new List<ECM_Contract_Item__c>();
        List<String> evntInfoRecTypesToGrp = new List<String>();
        List<String> evntInvTypes = new List<String>();
        investmentWrapper invWrp;
        Decimal disCounts = 0, reBates = 0, invAmnt;

        /*Query column names & field mapping*/
        for(ECM_EnS_Table_Setting__mdt mdt : [SELECT DeveloperName,Object_Name__c,Field_Mapping__c,Table_Header__c FROM ECM_EnS_Table_Setting__mdt 
                                              WHERE Country_Code__c =: cntry])
        {
            //fill column names with Field API Name Mappings
            if(Label.ECM_RecordsWithFieldMapping.contains(mdt.Object_Name__c) && mdt.Field_Mapping__c != null){ //Amplification,Activation
                colsWithFieldAPI.put(mdt.DeveloperName, (Map<String,String>)JSON.deserialize(mdt.Field_Mapping__c, Map<String,String>.class));
            } else {
                colmnNm.put(mdt.Object_Name__c, mdt.Field_Mapping__c.split(','));
            }
            
            //fill table header names - for Amplification use DeveloperName as key cause it holds the record type name
            if(mdt.Object_Name__c == 'Amplification'){
                headerNm.put(mdt.DeveloperName, mdt.Table_Header__c); 
            } else {
                headerNm.put(mdt.Object_Name__c, mdt.Table_Header__c); 
            }
            
            //Fills Product Strategy Mapping for Pourage Table
            if(mdt.Object_Name__c == 'Pourage Type'){
                ciType = (Map<String,String>)JSON.deserialize(mdt.Field_Mapping__c, Map<String,String>.class);
            }
        }
        
        //Prepare Event Table
        eventList = [SELECT Id,ECM_Event_Name__c,ECM_Event_Date__c FROM ECM_Event__c WHERE ECM_Contract__c =: conRec.Id];
        if(!eventList.isEmpty()){
            createEventTable(eventList);
        }

        //Prepare Amplification Tables
        for(ECM_Amplification__c amp : [SELECT Id,RecordType.Name,ECM_Asset_Format__c,ECM_Asset_Productions__c,
                                        ECM_Banners__c,ECM_Brand__c,ECM_Content_Inclusions__c,ECM_Contract__c,
                                        ECM_Diageo_Influencers__c,ECM_Diageo_Press_Office__c,ECM_Diageo_Retail_Customers__c,ECM_Diageo_Social__c,
                                        ECM_Diageo_Websites_Apps__c,ECM_Hashtags__c,ECM_Home_Page_Banners__c,ECM_If_Paid_budget_budget_Owner__c,
                                        ECM_Logo_Inculsion__c,ECM_Media_Platform__c,ECM_Organic__c,ECM_Paid_Boosted__c,ECM_Posts__c,
                                        ECM_Push_Notifications__c,ECM_Redirect_Links__c,ECM_Run_of_Site_Banners__c
                                        FROM 
                                        ECM_Amplification__c
                                        WHERE 
                                        ECM_Contract__c =: conRec.Id]){
                                            if(amp.ECM_Redirect_Links__c != null){
                                                amp.ECM_Redirect_Links__c = breakURLinMultiLine(amp.ECM_Redirect_Links__c);
                                            }
                                            amplificationList.add(amp);
                                        }
        if(!amplificationList.isEmpty()){
            createAmpTables(amplificationList);
        }
        
        //Map Product Strategy for Pourage Table AND Calculate rebates & Discount for Investment Table
        for(ECM_Contract_Item__c ci : [SELECT Id,ECM_MAT_Final__c,ECM_Exclusive__c,ECM_Product__r.ECM_Pickup_Option__r.Name,ECM_Product_Category__c,
                                       ECM_TSDD_Original__c,ECM_TSDD_Override__c,ECM_TotalSKU_SpecificRebate__c
                                       FROM ECM_Contract_Item__c 
                                       WHERE ECM_Contract__c =: conRec.Id 
                                       AND ECM_Product__c != null AND ECM_Product__r.ECM_Pickup_Option__c != null 
                                       AND ECM_Product_Category__c != null ORDER BY ECM_Product__r.ECM_Pickup_Option__r.Name]){
            //Calculate Discount & Rebates for Investment Table
            disCounts += (ci.ECM_TSDD_Override__c != null && ci.ECM_TSDD_Override__c >= 0)? ci.ECM_TSDD_Override__c : ci.ECM_TSDD_Original__c;
            reBates += ci.ECM_TotalSKU_SpecificRebate__c;
            
            //Map Product Strategies with E&S Specific Naming
            ci.ECM_Product__r.ECM_Pickup_Option__r.Name = ci.ECM_Product__r.ECM_Pickup_Option__r.Name.substringBefore('[').trim();
            if(ciType.containsKey(ci.ECM_Product__r.ECM_Pickup_Option__r.Name.toLowerCase())){
                ci.ECM_Product__r.ECM_Pickup_Option__r.Name = ciType.get(ci.ECM_Product__r.ECM_Pickup_Option__r.Name.toLowerCase());
            }
            ciList.add(ci);
        }
        invWrapperList.add(new investmentWrapper(Label.ECM_InvestmentTableStaticRowNames.split(',')[0],disCounts.setScale(2))); //Label[0] = Discounts
        invWrapperList.add(new investmentWrapper(Label.ECM_InvestmentTableStaticRowNames.split(',')[1],reBates.setScale(2))); //Label[1] = Rebates
        if(!ciList.isEmpty()){
            createPourageTable(ciList);
        }

        evntInvTypes = Label.ECM_EventInvestmentTypes.split(',');
        for(ECM_Event_Additional_Information__c evtInf : [SELECT Id,RecordType.Name,ECM_Information_Type__c,ECM_Information_Type__r.Name,
                                                          ECM_Information_Type__r.RecordType.Name,ECM_Information_Type__r.ECM_Activation_Category__c,
                                                          ECM_Information_Type__r.ECM_Activation_Category__r.Name,ECM_Quantity__c,ECM_Description__c,
                                                          ECM_Information_Type__r.ECM_Branding_Categorisation__c,
                                                          ECM_Information_Type__r.ECM_Sub_Branding_Categorisation__c,
                                                          ECM_Investment__c,ECM_Investment__r.ECM_Investment_Type__c,
                                                          ECM_Event__c,ECM_Event__r.ECM_Percent_Sponsorship_Fee_Allocation__c,ECM_Event__r.ECM_Event_Name__c,
                                                          ECM_Amount_Per_Investment_Per_Event__c,ECM_Investment_Amount__c,ECM_Investment_Percentage__c,ECM_Investment_Type__c
                                                          FROM 
                                                          ECM_Event_Additional_Information__c
                                                          WHERE 
                                                          ECM_Contract__c =: conRec.Id ORDER BY Recordtype.Name ASC])
        { 
            //Prepare Data for 'Event Investment' Table                                                   
            if(evtInf.RecordType.Name == Label.ECM_EventInvestmentRecTypeName && evtInf.ECM_Event__c != null && evtInf.ECM_Investment__c != null){
                eventInvestmentWrapper eventInvestdata;
                if(eventInvMap.containsKey(evtInf.ECM_Event__r.ECM_Event_Name__c)){
                    eventInvestdata = eventInvMap.get(evtInf.ECM_Event__r.ECM_Event_Name__c);
                }
                else{
                    eventInvestdata = new eventInvestmentWrapper();
                    eventInvestdata.eventName = evtInf.ECM_Event__r.ECM_Event_Name__c;
                    eventInvestdata.sponserPer = evtInf.ECM_Event__r.ECM_Percent_Sponsorship_Fee_Allocation__c;
                }
                //fill Wrapper for Event Investement
                if(evtInf.ECM_Investment__r.ECM_Investment_Type__c == evntInvTypes[0]){ //Onsite(ex pourage)
                    eventInvestdata.onsitePourage = evtInf.ECM_Amount_Per_Investment_Per_Event__c; 
                }
                else if(evtInf.ECM_Investment__r.ECM_Investment_Type__c == evntInvTypes[1]){ //Pourage(Including Volume)
                    eventInvestdata.pourage = evtInf.ECM_Amount_Per_Investment_Per_Event__c; 
                }
                else if(evtInf.ECM_Investment__r.ECM_Investment_Type__c == evntInvTypes[2]){ //Amplification
                    eventInvestdata.amplification = evtInf.ECM_Amount_Per_Investment_Per_Event__c; 
                }
                else if(evtInf.ECM_Investment__r.ECM_Investment_Type__c == evntInvTypes[3]){ //Activation
                    eventInvestdata.activation = evtInf.ECM_Amount_Per_Investment_Per_Event__c; 
                }     
                eventInvMap.put(evtInf.ECM_Event__r.ECM_Event_Name__c, eventInvestdata);
            }
            else if(evtInf.RecordType.Name == Label.ECM_InvestmentRecTypeName){
                invAmnt = (evtInf.ECM_Investment_Amount__c != null)? evtInf.ECM_Investment_Amount__c.setScale(2) : 0.00;
                invWrp = new investmentWrapper(evtInf.ECM_Investment_Type__c,invAmnt);
                invWrp.invPrcnt =  evtInf.ECM_Investment_Percentage__c;
                invWrapperList.add(invWrp);
            }
            else{
                //Remove Country Code from Information Types & Group by Record Type Name
                if(evtInf.ECM_Information_Type__c != null){
                    evtInf.ECM_Information_Type__r.Name = evtInf.ECM_Information_Type__r.Name.substringBefore('[').trim();
                }
                if(evtInf.ECM_Information_Type__r.ECM_Activation_Category__c != null){
                    evtInf.ECM_Information_Type__r.ECM_Activation_Category__r.Name = evtInf.ECM_Information_Type__r.ECM_Activation_Category__r.Name.substringBefore('[').trim();
                }
                if(eventInfoMap.containsKey(evtInf.RecordType.Name)){
                    eventInfoMap.get(evtInf.RecordType.Name).add(evtInf);
                }
                else{
                    eventInfoMap.put(evtInf.RecordType.Name,new List<ECM_Event_Additional_Information__c>{evtInf});
                }
            }
        }
		/*Prepare Total Investment distribution and Event Specific Sponsorship fees allocation table*/ 
        if(!eventInvMap.isEmpty()){
            createEventInvestmentTable(eventInvMap, conRec);
        } 
        if(!invWrapperList.isEmpty()){
            createInvesmentTable(invWrapperList);
        }
        /*Prepare Activation Table With EAI of Activation By Organiser & Activation By Diageo Record Type*/ 
        evntInfoRecTypesToGrp = Label.ECM_ActivationScreenRecordTypes.split(','); //Activation By Organiser, Activation By Diageo
        if(eventInfoMap.containsKey(evntInfoRecTypesToGrp[0])){
            actvByOrg_Branding = eventInfoMap.get(evntInfoRecTypesToGrp[0]);
        }
        if(eventInfoMap.containsKey(evntInfoRecTypesToGrp[1])){
            actvByDiageo_BrandingMr = eventInfoMap.get(evntInfoRecTypesToGrp[1]);
        }
        if(!actvByOrg_Branding.isEmpty() || !actvByDiageo_BrandingMr.isEmpty()){
            createActivationTable(actvByOrg_Branding, actvByDiageo_BrandingMr, conRec);
        }
        /*Create Parity & Ticketing Table*/
        if(eventInfoMap.containsKey('Parity')){
            eventInfoList = eventInfoMap.get('Parity');
            createParityTable(eventInfoList);
        }
        if(eventInfoMap.containsKey('Ticket')){
            eventInfoList = eventInfoMap.get('Ticket');
            createTicketingTable(eventInfoList);
        }
        /*Prepare Branding Table With EAI of Branding & Branding Merchandise Record Type*/ 
        evntInfoRecTypesToGrp = Label.ECM_BrandingScreenRecordTypes.split(','); //Branding,Branding Merchandise
        if(eventInfoMap.containsKey(evntInfoRecTypesToGrp[0])){
            actvByOrg_Branding = eventInfoMap.get(evntInfoRecTypesToGrp[0]);
        }
        if(eventInfoMap.containsKey(evntInfoRecTypesToGrp[1])){
            BrandingMr = eventInfoMap.get(evntInfoRecTypesToGrp[1]);	//147344
        }
        if(!actvByOrg_Branding.isEmpty() || !BrandingMr.isEmpty()){
            createBrandingTable(actvByOrg_Branding, BrandingMr);
        }

        System.debug('@@@Resource ES End: CPU '+Limits.getCpuTime()+'/'+Limits.getLimitCpuTime()+' Heap '+Limits.getHeapSize()+'/'+Limits.getLimitHeapSize()+
        ' Query '+Limits.getQueries()+'/'+Limits.getLimitQueries());

		return tableDataMap;        
    }

    /*
    * @Name : createEventTable
    * @description : Strucutres Event Table
    * @return : void
    * @param : eventList - List of Event Records
    */ 
    public static void createEventTable(List<ECM_Event__c> eventList){
        List<tableCell> tableRow;

        tableWrapper eventTable = new tableWrapper();
        eventTable.headerName = headerNm.containsKey('Event')?headerNm.get('Event') : null;
        eventTable.colNames = colmnNm.containsKey('Event')?colmnNm.get('Event') : new List<String>(); 
        for(ECM_Event__c it : eventList){
            tableRow = new List<tableCell>{new tableCell(it.ECM_Event_Name__c),
                						   new tableCell(String.valueOf(it.ECM_Event_Date__c))};
            eventTable.tableContent.add(tableRow);
        }
        tableDataMap.put('Event',eventTable);
    }

    /*
    * @Name : createInvesmentTable
    * @description : Strucutres Investment Table
    * @return : void
    * @param : invWrapperList - List wrappers containing investment amount & it's type
    */
     public static void createInvesmentTable(List<investmentWrapper> invWrapperList){
        List<List<tableCell>> rowsWithNullPrcntVal = new  List<List<tableCell>>();
        List<tableCell> tableRow = new List<tableCell>();
        List<String> secondColNames;
        Decimal totalIndicativeFund = 0;

        tableWrapper investmentTable = new tableWrapper();
        investmentTable.headerName = headerNm.containsKey('Investment')? headerNm.get('Investment') : null;
        investmentTable.colNames = colmnNm.containsKey('Investment')? colmnNm.get('Investment') : new List<String>();
        
        /*Add 1st Row with fixed text*/
        secondColNames = colmnNm.containsKey('Investment Column Description')? colmnNm.get('Investment Column Description') : new List<String>();
        for(String clNm : secondColNames){
            tableRow.add(new tableCell(clNm));
        }
        investmentTable.tableContent.add(tableRow);

        for(investmentWrapper invData : invWrapperList)
        {         
            totalIndicativeFund += invData.invAmount;
            if(invData.invPrcnt == null){
                  tableRow = new List<tableCell> {new tableCell(invData.invType),
                	   					    	  new tableCell(String.valueOf(invData.invAmount))}; 
                  tableRow[0].colSpan = 2; 
                  rowsWithNullPrcntVal.add(tableRow);    
            }
            else{
                 tableRow = new List<tableCell> {new tableCell(invData.invType),
                                                new tableCell(String.valueOf(Integer.valueOf(invData.invPrcnt)) +'%'),
     	   					    			    new tableCell(String.valueOf(invData.invAmount))}; 
                 investmentTable.tableContent.add(tableRow);//Rows with percent value should come first hence adding them first in table body
            }
           
        }
        investmentTable.tableContent.addAll(rowsWithNullPrcntVal);//Rows without percent value should come later hence adding them now in table body
        tableRow = new List<tableCell> {new tableCell(Label.ECM_InvestmentTableStaticRowNames.split(',')[2]),
                                        new tableCell(String.valueOf(totalIndicativeFund))}; //Label[2] = Indicative Total
        tableRow[0].colSpan = 2;  
        investmentTable.tableContent.add(tableRow);
        tableDataMap.put('Investment', investmentTable);
    }

    /*
    * @Name : createEventInvestmentTable
    * @description : Strucutres Event-Investment Table
    * @return : void
    * @param : eventInvMap - Map of wrappers with event specific sponsorship amount distribution
    */
    public static void createEventInvestmentTable(Map<String,eventInvestmentWrapper> eventInvMap, Contract Con){
        List<tableCell> tableRow;
        Decimal totalIndicativeFund;

        tableWrapper eventInvestmentTable = new tableWrapper();
        eventInvestmentTable.headerName = headerNm.containsKey('Event Investment')?headerNm.get('Event Investment') : null;
        eventInvestmentTable.colNames = colmnNm.containsKey('Event Investment')?colmnNm.get('Event Investment'): new List<String>(); 
        for(eventInvestmentWrapper eventInv : eventInvMap.values()){         
            totalIndicativeFund = ((Con.ECM_Indicative_Total_Funding__c*eventInv.sponserPer)/100) - eventInv.activation;
            tableRow = new List<tableCell> {new tableCell(eventInv.eventName),
                                            new tableCell(String.valueOf(eventInv.sponserPer) + '%'),
                	   					    new tableCell(String.valueOf(eventInv.pourage)),
                 							new tableCell(String.valueOf(eventInv.amplification)),
                                            new tableCell(String.valueOf(eventInv.onsitePourage)),
                						    new tableCell(String.valueOf(totalIndicativeFund))};
            eventInvestmentTable.tableContent.add(tableRow);
        }
        tableDataMap.put('Event Investment', eventInvestmentTable);
    }

    /*
    * @Name : createAmpTables
    * @description : Strucutres Amplification Tables of all record type & Groups Specific tables against a single key
    * @return : void
    * @param : amplificationList - List of Amplification records
    */
    public static void createAmpTables(List<ECM_Amplification__c> amplificationList){
        Map<String,String> fieldMap;
        List<tableCell> tableRow;
        String fldApi;
        String fldVal; 
        
        for(ECM_Amplification__c amp : amplificationList){
            tableRow = new List<tableCell>();
            fieldMap = colsWithFieldAPI.containsKey(amp.RecordType.Name)?colsWithFieldAPI.get(amp.RecordType.Name):null;
            tableWrapper ampTable;
            if(tableDataMap.containsKey(amp.RecordType.Name)){
                ampTable = tableDataMap.get(amp.RecordType.Name);
            }
            else{
                ampTable = new tableWrapper();
                ampTable.headerName = headerNm.containsKey(amp.RecordType.Name)?headerNm.get(amp.RecordType.Name) : null;
                if(fieldMap != null){
                    ampTable.colNames = new List<String>(fieldMap.keySet());
                }
            }
            if(ampTable != null && ampTable.colNames != null){
                for(String fldNm : ampTable.colNames){
                    fldApi = fieldMap.get(fldNm);
                    fldVal = (fldApi != null && fldApi != '')?(String)amp.get(fldApi):'';
                    tableRow.add(new tableCell(fldVal));
                }
            }
            ampTable.tableContent.add(tableRow);
            tableDataMap.put(amp.RecordType.Name, ampTable);
        }
        /*To Group App,Social & eDM table for ES table type App*/
        tableWrapper ampWrp;
        List<String> ampGrp = Label.ECM_AmpRecordTypesToGroup.split(','); //App,Social,eDM
        for(String ampKey : ampGrp){
            if(tableDataMap.containsKey(ampKey)){
                if(ampWrp == null){
                    ampWrp = tableDataMap.get(ampKey);
                    ampWrp.ampGrpCol = new List<List<String>>();
                    ampWrp.ampGrpCntnt = new List<List<List<tableCell>>>();
                }
                else{
                    if(!tableDataMap.get(ampKey).tableContent.isEmpty()){
                        ampWrp.ampGrpCol.add(new List<String>(tableDataMap.get(ampKey).colNames));
                        ampWrp.ampGrpCntnt.add(new List<List<tableCell>>(tableDataMap.get(ampKey).tableContent));
                    }   
                }
            }
        }
        if(ampWrp != null){
            tableDataMap.put('App', ampWrp);
        }
    }

    /*
    * @Name : createPourageTable
    * @description : Strucutres Pourage Table
    * @return : void
    * @param : ciList - List of contract item records
    */
    public static void createPourageTable(List<ECM_Contract_Item__c> ciList){
        Map<String,ciVal> categoryWiseVolume = new Map<String,ciVal>();
        Map<String,ciVal> typeWiseVolume = new Map<String,ciVal>();
        List<String> exclusivityVal = Label.ECM_ExclusivityValforPourageTable.split(','); //Yes,No
        List<tableCell> tableRow;
        String totalVolTxt = Label.ECM_PourageTableTotalVolText; //@ Total :
        String key;
        String prodType;
        String prodCategory;
        ciVal tempVal;
        tableCell endCell;

        tableWrapper pourageTable = new tableWrapper();
        pourageTable.headerName = headerNm.containsKey('Pourage')?headerNm.get('Pourage') : null;
        pourageTable.colNames = colmnNm.containsKey('Pourage')?colmnNm.get('Pourage'): new List<String>();
            
        for(ECM_Contract_Item__c it : ciList){
            key = it.ECM_Product__r.ECM_Pickup_Option__r.Name;
            if(typeWiseVolume.containsKey(key)){
                tempVal = typeWiseVolume.get(key);
                tempVal.amountNum = tempVal.amountNum + it.ECM_MAT_Final__c;
                typeWiseVolume.put(key,tempVal);
            }
            else{
                typeWiseVolume.put(key, new ciVal(it.ECM_MAT_Final__c,0));
            }
            if(categoryWiseVolume.containsKey(key + '_' + it.ECM_Product_Category__c)){
                tempVal = categoryWiseVolume.get(key + '_' + it.ECM_Product_Category__c);
                tempVal.amountNum = tempVal.amountNum + it.ECM_MAT_Final__c;
                if(tempVal.countNum != 1){
                    tempVal.countNum = (it.ECM_Exclusive__c ? 1 : 0);
                }
                categoryWiseVolume.put(key + '_' + it.ECM_Product_Category__c,tempVal);
            }
            else{
                categoryWiseVolume.put(key + '_' + it.ECM_Product_Category__c, new ciVal(it.ECM_MAT_Final__c,(it.ECM_Exclusive__c ? 1 : 0)));
                tempVal = typeWiseVolume.get(key);
                tempVal.countNum +=1;
                typeWiseVolume.put(key,tempVal);
            }
        }

        for(String keys : categoryWiseVolume.keySet()){
            prodType = keys.split('_')[0];
            prodCategory = keys.split('_')[1];
            tableRow = new List<tableCell>();
            
            if(typeWiseVolume.containsKey(prodType)){
                tableRow.add(new tableCell(prodType));
                tableRow[0].rowSpan = typeWiseVolume.get(prodType).countNum;
                endCell = new tableCell(totalVolTxt.replace('@',prodType)+' '+String.valueOf(typeWiseVolume.get(prodType).amountNum)); // Type Total: 123
                endCell.rowSpan = typeWiseVolume.get(prodType).countNum;
                typeWiseVolume.remove(prodType);
            }

            tableRow.add(new tableCell(prodCategory));
            tableRow.add(new tableCell(categoryWiseVolume.get(keys).countNum == 1 ? exclusivityVal[0]:exclusivityVal[1]));
            tableRow.add(new tableCell(String.valueOf(categoryWiseVolume.get(keys).amountNum)));
            
            if(endCell != null){
                tableRow.add(endCell);
                endCell = null;
            }
            pourageTable.tableContent.add(tableRow);
        }
        tableDataMap.put('Pourage',pourageTable);
    }

    /*
    * @Name : createActivationTable
    * @description : Strucutres Activation Table
    * @return : void
    * @param : actvByOrg - List of EAI records with 'Activation By Organizer' record Type
    * @param : actvByDiageo - List of EAI records with 'Activation By Diageo' record Type, con - Contract Record
    */
    public static void createActivationTable(List<ECM_Event_Additional_Information__c> actvByOrg, List<ECM_Event_Additional_Information__c> actvByDiageo, Contract con){
        Map<String,String> actfldMap = colsWithFieldAPI.containsKey('Activation')?colsWithFieldAPI.get('Activation') : new Map<String,String>();
        List<String> tableSecNames = Label.ECM_ActivationTableSecNames.split(','); //Inclusions Provided By Organiser,Inclusions Provided By Diageo
        String fieldVal;
        String apiNm;

        tableWrapper actvTable = new tableWrapper();
        actvTable.headerName = headerNm.containsKey('Activation')?headerNm.get('Activation') : null;
        actvTable.activationVals = new List<List<tableCell>>();
        for(String colNm : actfldMap.keySet()){
            apiNm = actfldMap.get(colNm);
            fieldVal = (String)con.get(apiNm);
            actvTable.activationVals.add(new List<tableCell>{new tableCell(colNm),new tableCell(fieldVal)});
        }
        if(!actvByOrg.isEmpty()){
            actvTable = prepareActivation(actvByOrg, tableSecNames[0], actvTable);
        }
        if(!actvByDiageo.isEmpty()){
            actvTable = prepareActivation(actvByDiageo, tableSecNames[1], actvTable);
        }
        tableDataMap.put('Activation',actvTable);
    }

    /*
    * @Name : prepareActivation
    * @description : prepares table content for 2nd & 3rd section of Activation Table
    * @return : void
    * @param : eventInfoList - List of EAI records, secName - Table section Name, eventInfoTable - Table Wrapper where the content will be added
    */
    public static tableWrapper prepareActivation(List<ECM_Event_Additional_Information__c> eventInfoList, String secName, tableWrapper eventInfoTable){
        List<List<tableCell>> temp;
        List<tableCell> tableRow;
        Map<String,List<List<tableCell>>> activationMap = new Map<String,List<List<tableCell>>>();
        
        tableRow = new List<tableCell>{new tableCell(secName)};
            tableRow[0].rowSpan = eventInfoList.size();
        
        for(ECM_Event_Additional_Information__c it : eventInfoList){
            if(it.ECM_Information_Type__c != null && it.ECM_Information_Type__r.ECM_Activation_Category__c != null){
                if(activationMap.containsKey(it.ECM_Information_Type__r.ECM_Activation_Category__r.Name)){
                    activationMap.get(it.ECM_Information_Type__r.ECM_Activation_Category__r.Name).add(new List<tableCell>{new tableCell(it.ECM_Information_Type__r.Name),
                        new tableCell(it.ECM_Description__c)});
                }
                else{
                    activationMap.put(it.ECM_Information_Type__r.ECM_Activation_Category__r.Name,new List<List<tableCell>>{new List<tableCell>{new tableCell(it.ECM_Information_Type__r.Name),
                        new tableCell(it.ECM_Description__c)}});
                }
            }
        }
        
        for(String key : activationMap.keySet()){
            if(tableRow.size() == 1){
                tableRow.add(new tableCell(key));
                temp = activationMap.get(key);
                tableRow[1].rowSpan = temp.size();
            }
            else{
                tableRow = new List<tableCell>();
                tableRow.add(new tableCell(key));
                temp = activationMap.get(key);
                tableRow[0].rowSpan = temp.size();
            }
            tableRow.addAll(temp[0]);
            eventInfoTable.tableContent.add(tableRow);
            
            for(Integer I = 1; I<temp.size(); I++){
                tableRow = new List<tableCell>();
                tableRow.addAll(temp[I]);
                eventInfoTable.tableContent.add(tableRow);
            }
        }
        return eventInfoTable;
    }

    /*
    * @Name : createParityTable
    * @description : Structures Parity Table
    * @return : void
    * @param : eventInfoList - List of EAI records
    */
    public static void createParityTable(List<ECM_Event_Additional_Information__c> eventInfoList){
        List<tableCell> tableRow;

        tableWrapper eventInfoTable = new tableWrapper();
        eventInfoTable.headerName = headerNm.containsKey('Parity')?headerNm.get('Parity') : null;
        eventInfoTable.colNames = colmnNm.containsKey('Parity')?colmnNm.get('Parity'): new List<String>();

        for(ECM_Event_Additional_Information__c it : eventInfoList){
            if(String.isNotEmpty(it.ECM_Description__c) && it.ECM_Description__c.containsIgnoreCase('(x)') && it.ECM_Quantity__c !=null){
                it.ECM_Description__c = it.ECM_Description__c.replace('(x)', String.valueOf(it.ECM_Quantity__c));
            }
            tableRow = new List<tableCell>{new tableCell(it.ECM_Information_Type__r.Name),
                                           new tableCell(it.ECM_Description__c)};
            eventInfoTable.tableContent.add(tableRow);
        }
        tableDataMap.put('Parity',eventInfoTable);
    }
        
    /*
     * @Name: createTicketingTable
     * @description: setup data for ticketing table
     * @param: eventInfoList [data of event addtional information]
     * @param: tableDataMap [map for event additional inforamtion type with tabale data]
     */
    public static void createTicketingTable(List<ECM_Event_Additional_Information__c> eventInfoList){
        List<tableCell> tableRow;

        tableWrapper eventInfoTable = new tableWrapper();
        eventInfoTable.headerName = headerNm.containsKey('Ticket')?headerNm.get('Ticket') : null;
        eventInfoTable.colNames = colmnNm.containsKey('Ticket')?colmnNm.get('Ticket'): new List<String>();

        for(ECM_Event_Additional_Information__c it : eventInfoList){
            tableRow = new List<tableCell>{new tableCell(it.ECM_Information_Type__r.Name)};
            tableRow.add(new tableCell(String.valueOf(it.ECM_Quantity__c)));
            tableRow.add(new tableCell(it.ECM_Description__c));
            eventInfoTable.tableContent.add(tableRow);
        }
        tableDataMap.put('Ticket',eventInfoTable);
    }

    /*
     * @Name: createBrandingTable
     * @description: setup data for branding table
     * @param: eventInfoList [data of event addtional information]
     * @param: tableDataMap [map for event additional inforamtion type with branding data]
     */
    public static void createBrandingTable(List<ECM_Event_Additional_Information__c> brandingList, List<ECM_Event_Additional_Information__c> brandingMrList){
        tableWrapper eventInfoTable = new tableWrapper();
        eventInfoTable.headerName = headerNm.containsKey('Branding')?headerNm.get('Branding') : null;    
        eventInfoTable.colNames = colmnNm.containsKey('Branding')?colmnNm.get('Branding'): new List<String>();
        List<String> brandingCategory = Label.ECM_BrandingCategories.split(',');
        List<String> brandingSubCategory = Label.ECM_BrandingSubCategories.split(',');
        
        brandingSubCategory sce = new brandingSubCategory();
        sce.subCategory = brandingSubCategory[0]+':'; //Electronic

        brandingSubCategory scs = new brandingSubCategory();
        scs.subCategory = brandingSubCategory[1]+':'; //Static
        
        brandingCategory bd = new brandingCategory();
        bd.category = brandingCategory[0]; //Diageo Naming Rights
        
        brandingCategory bt = new brandingCategory();
        bt.category = brandingCategory[1]; //Total Alcohol Signage %
        
        brandingCategory bm = new brandingCategory();
        bm.category = brandingCategory[2]; //Menu Boards
    
        brandingCategory bbm = new brandingCategory();
        bbm.category = brandingCategory[3]; //Branded Merchandise
        

        for(ECM_Event_Additional_Information__c it : brandingList){
            if(it.ECM_Information_Type__r.ECM_Branding_Categorisation__c == brandingCategory[0]
                && it.ECM_Description__c !=null){ //Diageo Naming Rights
                List<tableCell> tableRowbd = new List<tableCell>();
                tableRowbd.add(new tableCell(String.valueOf(it.ECM_Description__c)));//146480
                bd.tableContent.add(tableRowbd);
                bd.totalrows +=1;
            }
            if(it.ECM_Information_Type__r.ECM_Branding_Categorisation__c == brandingCategory[1] 
                && it.ECM_Information_Type__r.Name !=null){ //Total Alcohol Signage %
                List<tableCell> tableRowbt = new List<tableCell>();
                tableRowbt.add(new tableCell(it.ECM_Information_Type__r.Name));
                tableRowbt.add(new tableCell(String.valueOf(it.ECM_Description__c)));//146480
                bt.tableContent.add(tableRowbt);
                bt.totalrows += 1;
            }
            if(it.ECM_Information_Type__r.ECM_Branding_Categorisation__c == brandingCategory[2]){//Menu Boards
                if(it.ECM_Information_Type__r.ECM_Sub_Branding_Categorisation__c == brandingSubCategory[0] 
                    && it.ECM_Information_Type__r.Name !=null){//Electronic
                    List<tableCell> scetableRow = new List<tableCell>();
                    scetableRow.add(new tableCell(it.ECM_Information_Type__r.Name));
                    scetableRow.add(new tableCell(String.valueOf(it.ECM_Description__c)));//146480
                    sce.tableContent.add(scetableRow);
                    sce.totalrows +=1;
                    bm.totalrows +=1;
                }
                if(it.ECM_Information_Type__r.ECM_Sub_Branding_Categorisation__c == brandingSubCategory[1]
                    && it.ECM_Information_Type__r.Name !=null){//Static
                    List<tableCell> scstableRow = new List<tableCell>();
                    scstableRow.add(new tableCell(it.ECM_Information_Type__r.Name));
                    scstableRow.add(new tableCell(String.valueOf(it.ECM_Description__c)));//146480
                    scs.tableContent.add(scstableRow);
                    scs.totalrows +=1;
                    bm.totalrows +=1;
                }
            }
        }
        for(ECM_Event_Additional_Information__c it : brandingMrList){
            if(it.ECM_Information_Type__r.Name !=null){
                List<tableCell> tableRowbbm = new List<tableCell>();
                tableRowbbm.add(new tableCell(it.ECM_Information_Type__r.Name));
                tableRowbbm.add(new tableCell(String.valueOf(it.ECM_Description__c)));//146480
                bbm.tableContent.add(tableRowbbm);
                bbm.totalrows +=1;
            }
        }
        List<brandingSubCategory> lstSubCats = new List<brandingSubCategory>{sce, scs};
        bm.subCategoriedData = lstSubCats;
        List<brandingCategory>lstbrandingCategories = new list<brandingCategory>{bd, bt, bm, bbm};
        eventInfoTable.brandingVals = lstbrandingCategories;
        tableDataMap.put('Branding',eventInfoTable);
    }
    
    /*
    * @Name: breakURLinMultiLine
    * @description: add white spaces in long URL string to have word-wrap in PDF
    * @param: urlLnk - String
    * @return: String
    */
    public static String breakURLinMultiLine(String urlLnk){
        Integer lenEachLine = Integer.valueOf(Label.ECM_maxCharForAmpTableURL);
        if(urlLnk.length() <= lenEachLine){
            return urlLnk;
        }
        String retStr = '';
        Integer endIndx;
        for(Integer i=0; i<urlLnk.length(); i += lenEachLine){
            endIndx = (i+lenEachLine < urlLnk.length())? i+lenEachLine : urlLnk.length();
            retStr = retStr + ' ' + urlLnk.substring(i,endIndx-1);
        }
        return retStr;
    }
    
    /*tableWrapper - Strucures all data for a single Table*/
    public class tableWrapper{
        public String headerName {get;set;} /*Header Name of Table*/
        public List<String> colNames {get;set;} /*Column Names of Table*/
        public List<List<tableCell>> activationVals {get;set;} /*Contains Contract Level field values for Activation Table*/
        public List<List<tableCell>> tableContent {get;set;} /*Table Body Content - List of Rows, Each row is List of tableCells*/
        public List<brandingCategory> brandingVals {get;set;} /*Content of each branding category for Branding Table*/
        /*To Group Amp tables*/
        public List<List<String>> ampGrpCol {get;set;}
        public List<List<List<tableCell>>> ampGrpCntnt {get;set;}

        tableWrapper(){
            tableContent = new List<List<tableCell>>();
        }
    }

    /*Constructs each cell of table body*/ 
    public class tableCell{
        public String cellVal {get;set;} /*Content to be displayed in a table cell*/
        public Integer rowSpan {get;set;} 
        public Integer colSpan {get;set;}
        tableCell(String val){
            cellVal = val;
            rowSpan = 1;
            colSpan = 1;
        }
    }

    /*Constructs each cell of column - used in vfc controller*/
    public class colCell{
        public String boldVal {get;set;} /*Text to be displayed in bold*/
        public String nonBoldVal {get;set;} /*Text not to be displayed in bold*/
        public colCell(String val){
            if(val.contains('@')){
                boldVal = val.split('@')[0];
                nonBoldVal = val.split('@')[1];
            }
            else{
                boldVal = val;
            }
        }
    }

    /*Constructs Branding table sections*/
    public class brandingCategory{
        public String category {get;set;}
        public Integer totalrows {get;set;}
        public List<brandingSubCategory> subCategoriedData{get;set;}
        public List<List<tableCell>> tableContent {get;set;}
        brandingCategory(){
            totalrows = 0;
            tableContent = new List<List<tableCell>>();
        }
    }

    /*Constructs Branding table sub-sections*/
    public class brandingSubCategory{
        public String subCategory {get;set;}
        public Integer totalrows {get;set;}
        public List<List<tableCell>> tableContent {get;set;}
        brandingSubCategory(){
            totalrows = 0;
            tableContent = new List<List<tableCell>>();
        }
    }
    
    /*Event investment Wrapper*/
    public class eventInvestmentWrapper{
        public String eventName {get;set;}
        public Decimal sponserPer {get;set;}
        public Decimal pourage {get;set;}
        public Decimal onsitePourage {get;set;}
        public Decimal activation {get;set;}
        public Decimal amplification {get;set;} 
    }

    /*Investment Wrapper to hold Inv data from CI & EAI*/
    public class investmentWrapper{
        public String invType {get;set;}
        public Decimal invAmount {get;set;}
        public Decimal invPrcnt {get;set;}
        investmentWrapper(String type, Decimal amnt){
            invType = type;
            invAmount = amnt;
        }
    }

    /*Volume Sum & grouping Exclusivity for products*/
    public class ciVal{
        public Decimal amountNum {get;set;}
        public Integer countNum {get;set;}
        ciVal(Decimal amnt, Integer cnt){
            countNum = cnt;
            amountNum = amnt;
        }
    }
}