public class EDGE_TravelLogBookGenBatchHelper {
    
    public static String batchFrequency = '';
    public static Set<Id> allTravelLogBookIds = new Set<Id>();
    static Map<Integer,String> monthNameMap = new Map<Integer, String>{1 =>'Jan', 2=>'Feb', 3=>'Mar', 4=>'Apr', 5=>'May',6=>'June', 7=>'July', 8=>'Aug', 
            9=>'Sept',10=>'Oct',11=>'Nov', 12=>'Dec'};
    static Map<Id, Date> pInfoIdToStartDateMap = new Map<Id, Date>();
    static Map<Id, Date> pInfoIdToEndDateMap = new Map<Id, Date>();
    static final String TRAVEL_LOGBOOK_STR = 'Travel Logbook';
    static Date mktSettingLastTrvlLogDate;
    static Map<Id, Boolean> travelLogMailStatusMap = new Map<Id, Boolean>();
    
    /*******************************************************************
    Method  : generateTravelLogBook
    Purpose : This method will insert Travel log books based on the Personal
  Information in conext */
    public static Map<Id, Boolean> generateTravelLogBook(List<Personal_Information__c> scope,  Boolean triggerContext){
        
        System.debug('generateTravelLogBook > triggerContext = '+ triggerContext);
        List<Travel_Logbook__c> traveLogBookList = new List<Travel_Logbook__c>();
        //Map<Id, Id> travlLogToTrvLogBookMap = new Map<Id, Id>();
        Set<Id> trvlLogBookIds = new Set<Id>();
        Map<Id,Id> personInfoCountryMap = new Map<Id,Id>();
        Map<Id, List<Travel_Log__c>> pInfoIdToTLMap = new  Map<Id, List<Travel_Log__c>>();
        Map<Id, Personal_Information__c> personalInfoIdToRecMap = new Map<Id, Personal_Information__c>();
        Map<Id,Market_Setting__c> carChangeApprovalMap = new Map<Id,Market_Setting__c>();
        
        for(Personal_Information__c pInfoRec : scope){ 
            personalInfoIdToRecMap.put(pInfoRec.Id,pInfoRec);
            personInfoCountryMap.put(pInfoRec.Id,pInfoRec.Geography__c);
        }
        
        carChangeApprovalMap = populateCarChangeApprovalMap(personInfoCountryMap);
        
        Date rangeStartDate;
        Date rangeEndDate;
        
        if(scope != null && scope.size() > 0){
            Personal_Information__c personInforec = scope[0];
            System.debug('personInforec.Geography__c = '+ personInforec.Geography__c);
            if(carChangeApprovalMap.containsKey(personInforec.Geography__c)){
                if(carChangeApprovalMap.get(personInforec.Geography__c) != null){
                    mktSettingLastTrvlLogDate =  carChangeApprovalMap.get(personInforec.Geography__c).Last_Travel_Log_Date__c; 
                }
            }
        }
        
        if(!triggerContext){//Batch context
            if(String.isNotBlank(batchFreQuency)){
                if(batchFreQuency.equalsIgnoreCase('Monthly')){
                    rangeStartDate = System.today().addMonths(-1).toStartofMonth();
                }else if(batchFreQuency.equalsIgnoreCase('Quarterly')){
                    rangeStartDate = System.today().addMonths(-4).toStartofMonth();
                }
                rangeEndDate = System.today().toStartofMonth().addDays(-1);
            } 
        }else{//Trigger context
            rangeStartDate =  mktSettingLastTrvlLogDate; 
            rangeEndDate = System.today();
        }
        
        System.debug('rangeStartDate = '+ rangeStartDate);
        System.debug('rangeEndDate = '+ rangeEndDate);
        
        for(Travel_Log__c travelLog : [Select Id, Odometer_Start_Reading__c, Odometer_End_Reading__c,Start_Date__c, End_Date__c, 
                                       Purpose_of_Trip__c,Trip_Description__c,Distance_Traveled__c,Personal_Information__r.Id, 
                                       Personal_Information__r.Min_Start_Date__c, Personal_Information__r.Geography__c,Personal_Information__r.Registration_Number__c
                                       FROM Travel_Log__c
                                       where  Personal_Information__c in :scope and 
                                       Start_Date__c >= :rangeStartDate AND Start_Date__c <= :rangeEndDate
                                       and Reported__c = false])
        {
            
            Id pInfoId = travelLog.Personal_Information__r.Id;
            
            if(!pInfoIdToTLMap.containsKey(pInfoId)){
                pInfoIdToTLMap.put(pInfoId, new List<Travel_Log__c>{travelLog});
                pInfoIdToStartDateMap.put(pInfoId, travelLog.Start_Date__c);
                pInfoIdToEndDateMap.put(pInfoId, travelLog.End_Date__c);
            }else{
                pInfoIdToTLMap.get(pInfoId).add(travelLog);
                if(pInfoIdToStartDateMap.get(pInfoId) > travelLog.Start_Date__c){
                    pInfoIdToStartDateMap.put(pInfoId, travelLog.Start_Date__c);
                }
                if(pInfoIdToEndDateMap.get(pInfoId) < travelLog.End_Date__c){
                    pInfoIdToEndDateMap.put(pInfoId, travelLog.End_Date__c);
                }
            }
        }
        
        System.debug('pInfoIdToTLMap = '+ pInfoIdToTLMap);        
        
        for(Id pInfoId : pInfoIdToTLMap.keySet()){
            
            Personal_Information__c personInfo = personalInfoIdToRecMap.get(pInfoId);
            Travel_Logbook__c traveLogBook = new Travel_Logbook__c();
            
            Date startDate = pInfoIdToStartDateMap.get(pInfoId) != null ? pInfoIdToStartDateMap.get(pInfoId) : System.Today();
            Date endDate = pInfoIdToEndDateMap.get(pInfoId) != null ? pInfoIdToEndDateMap.get(pInfoId) : System.Today();
            traveLogBook.Start_Date__c = startDate;
            traveLogBook.End_Date__c = endDate;
            traveLogBook.Name = 'Logbook'+'_'+startDate.day() +' '+ monthNameMap.get(startDate.month()) +'-'+ endDate.day()+' '+ monthNameMap.get(endDate.month());
            traveLogBook.Personal_Information__c = personInfo.Id;
            traveLogBook.Registration_Number__c =  personInfo.Registration_Number__c;
            System.debug('traveLogBook = '+ traveLogBook);
            traveLogBookList.add(traveLogBook) ;
        }
        
        for(Personal_Information__c pInfoRec : scope){ 
            personalInfoIdToRecMap.put(pInfoRec.Id,pInfoRec);
            personInfoCountryMap.put(pInfoRec.Id,pInfoRec.Geography__c);
        }
        if(traveLogBookList.size() > 0){
            Database.insert(traveLogBookList);
        }
        updateTravelLogs(traveLogBookList,  pInfoIdToTLMap, personInfoCountryMap, scope, triggerContext);
        return travelLogMailStatusMap;
    }
    
    /*******************************************************************
    Method  : updateTravelLogs
    Purpose : This method will popultae Travel log books id on the Travel 
  log book records in context*/
    public static Map<Id, Id> updateTravelLogs(List<Travel_Logbook__c> traveLogBookList,  Map<Id, List<Travel_Log__c>> pInfoIdToTLMap, Map<Id,Id> personInfoCountryMap, List<Personal_Information__c> personalInfoList, Boolean triggerContext){
        
        List<Travel_Log__c> traveLogList = new List<Travel_Log__c>();
        Map<Id, Id> trvlIdToCountryIdMap = new Map<Id, Id>();
        Map<Id,Market_Setting__c> carChangeApprovalMap = new Map<Id,Market_Setting__c>();
        Set<Id> trvlLogBookIds = new Set<Id>();
    Map<Id, Id> travlLogToTrvLogBookMap = new Map<Id, Id>();
        
        carChangeApprovalMap = populateCarChangeApprovalMap(personInfoCountryMap); //EDGE_PersonalInformationTriggerHelper
        
        if(traveLogBookList.size() > 0){
            
            for(Travel_Logbook__c trvlLogBook : traveLogBookList){
                
                trvlLogBookIds.add(trvlLogBook.Id);                
                Id personInfoId = trvlLogBook.Personal_Information__c;                
                
                if(pInfoIdToTLMap.containsKey(personInfoId)){
                    for(Travel_Log__c trvlLog : pInfoIdToTLMap.get(trvlLogBook.Personal_Information__c)){
                        trvlLog.Travel_Logbook__c = trvlLogBook.Id;
                        //trvlLog.Reported__c = true;
                        traveLogList.add(trvlLog);
                        if(!trvlIdToCountryIdMap.containsKey(trvlLogBook.Id)){
                            if(trvlLogBook.Id != null && trvlLog.Personal_Information__r.Geography__c != null){
                                trvlIdToCountryIdMap.put(trvlLogBook.Id, trvlLog.Personal_Information__r.Geography__c);
                            }
                        }
                        travlLogToTrvLogBookMap.put(trvlLog.Id, trvlLogBook.Id);
                        //travelLogBookIds.add(trvlLogBook.Id);
                    }
                }
            }
            
            System.debug('traveLogList = '+ traveLogList);
            System.debug('travlLogToTrvLogBookMap = '+ travlLogToTrvLogBookMap);
            if(traveLogList.size() > 0){
                Database.update(traveLogList);
            }
        }
        createCSVFiles(personalInfoList,carChangeApprovalMap, travlLogToTrvLogBookMap, pInfoIdToTLMap, triggerContext, trvlLogBookIds, trvlIdToCountryIdMap );
        return trvlIdToCountryIdMap;
    }
    
    /*******************************************************************
    Method  : createCSVFiles
    Purpose : This method will create CSV files based on the Travel log &
  log book records in context and store in Salesforce Files*/
    public static void createCSVFiles(List<Personal_Information__c> personalInfoList, Map<Id,Market_Setting__c> carChangeApprovalMap, Map<Id, Id> travlLogToTrvLogBookMap, Map<Id, List<Travel_Log__c>> travelLogPersnInfoMap, Boolean triggerContext, Set<Id> trvlLogBookIds, Map<Id, Id> trvlIdToCountryIdMap){
        
        Set<Id> personInfoIdsSet = new Set<Id>();
        Set<Id> userIdsSet = new Set<Id>();
        List<Travel_log__c> travelLogList = new List<Travel_log__c>();
        List<Travel_log__c> travelLogToUpdate = new List<Travel_log__c>();
        List<string> taxManagerEmailList = new List<string>(); 
        Map<Id,String> userNameMap = new Map<Id,String>();
        //Map<Id,List<Travel_log__c>> travelLogPersnInfoMap = new Map<Id,List<Travel_log__c>>();
        String header, finalstr,emailstr ,unit;
        Boolean trackerUnit;
        Map<Id, Id> cvIdTotrvlLogBookIdMap = new Map<Id, Id>();
        
        List<ContentVersion> conVerToBeInserted = new List<ContentVersion>();
        List<Id> contentVersionIds = new List<Id>();
        Map<Id, ContentVersion> travelLogBookToCV = new Map<Id, ContentVersion>();       
        
        if(personalInfoList != null && personalInfoList.size() > 0){
            for(Personal_Information__c personinfo :personalInfoList ){            
                personInfoIdsSet.add(personinfo.Id);
                userIdsSet.add(personinfo.User__c);
            }
        }
        if(userIdsSet != null){
            for(User usrId : [SELECT id, Name from user where id IN : userIdsSet]){
                userNameMap.put(usrId.id , usrId.Name);
            }
        }
        if(personalInfoList != null && personalInfoList.size() > 0){
            
            for(Personal_Information__c personInforec : personalInfoList){
                
                Id trvlLogBookId = null;
                Double businessDistance = 0;
                Double personalDistance = 0;
                
                if(carChangeApprovalMap.containsKey(personInforec.Geography__c)){
                    if(carChangeApprovalMap.get(personInforec.Geography__c) != null){
                    emailstr =  carChangeApprovalMap.get(personInforec.Geography__c).Fleet_Manager__c;                    
                        trackerUnit = carChangeApprovalMap.get(personInforec.Geography__c).Display_in_Kilometer__c;
                    }
                }               
                System.debug('travelLogPersnInfoMap = '+ travelLogPersnInfoMap);
                system.debug('triggerContext '+triggerContext);
                if(travelLogPersnInfoMap != null && travelLogPersnInfoMap.containsKey(personInforec.id)){
                    
                    Id pInfoId = personInforec.id;
                    
                    Date startDate;
                Date endDate; 
                    
                    if(triggerContext){
                         startDate = pInfoIdToStartDateMap.get(pInfoId) != null ? pInfoIdToStartDateMap.get(pInfoId) : mktSettingLastTrvlLogDate;
                  endDate = System.Today();
                        system.debug('trigger');
                    }else{//Batch context
                        startDate = pInfoIdToStartDateMap.get(pInfoId) != null ? pInfoIdToStartDateMap.get(pInfoId) : System.today().addMonths(-1).toStartofMonth();
                  endDate =   System.today().toStartofMonth().addDays(-1);  
                        system.debug('batch');
                    }
                    system.debug('endDate '+endDate);
                    Datetime myStartDateTime = Datetime.newInstance(startDate.year(), startDate.month(),startDate.day());
                    String myStartDate = myStartDateTime.day()+'/'+ myStartDateTime.month()+'/'+myStartDateTime.year(); //myStartDateTime.format('MM/DD/YYYY');                    
                    Datetime myEndDateTime = Datetime.newInstance(endDate.year(), endDate.month(),endDate.day());
                    String myEndDate = myEndDateTime.day()+'/'+ myEndDateTime.month()+'/'+myEndDateTime.year();

                    
                    header = 'Driver Name '+ ',' + userNameMap.get(personInforec.User__c) +'\n' ;
                    header += 'Car Registration Number'+','+ personInforec.Registration_Number__c+  '\n';
                    header += 'Daily Kilometres/Miles Tracker'+',' + myStartDate + ' to '+ myEndDate + '\n\n\n' ;
                    header += 'Travel Log Details \n';
                    header += 'Travel Start Date,Travel End Date,Odometer Start,Odometer End,Purpose,Description,Distance \n';
                    finalstr = header ;
                    
                    for(Travel_log__c trvLog : travelLogPersnInfoMap.get(personInforec.id)){

                        trvLog.Reported__c = true ; 
                        //trvLog.Start_Date__c.format()
                        String travelrecordString = '"'+trvLog.Start_Date__c.format()+'","'+trvLog.End_Date__c.format()+'","'+ (trvLog.Odometer_Start_Reading__c != null ? trvLog.Odometer_Start_Reading__c : 0)+'","'+ (trvLog.Odometer_End_Reading__c != null ? trvLog.Odometer_End_Reading__c : 0) +'","'+ (trvLog.Purpose_of_Trip__c != null ? trvLog.Purpose_of_Trip__c : '') +'","'+ (trvLog.Trip_Description__c != null ? trvLog.Trip_Description__c : '') +'","'+ (trvLog.Distance_Traveled__c != null ?  trvLog.Distance_Traveled__c : 0) +'"\n';
                        finalstr = finalstr + travelrecordString; 
                        travelLogToUpdate.add(trvLog);
                        //System.debug('travlLogToTrvLogBookMap = '+ travlLogToTrvLogBookMap);
                        trvlLogBookId = travlLogToTrvLogBookMap.get(trvLog.Id);                        
                        
                        //if(trvLog.Odometer_End_Reading__c != null && trvLog.Odometer_Start_Reading__c != null){
                        if(trvLog.Purpose_of_Trip__c == 'Business' && trvLog.Distance_Traveled__c != null){
                            businessDistance += trvLog.Distance_Traveled__c; // trvLog.Odometer_End_Reading__c - trvLog.Odometer_Start_Reading__c;                            
                        }
                        if(trvLog.Purpose_of_Trip__c == 'Personal' && trvLog.Distance_Traveled__c != null){
                            personalDistance += trvLog.Distance_Traveled__c; //trvLog.Odometer_End_Reading__c - trvLog.Odometer_Start_Reading__c;                            
                        }
                        //}
                    }
                    if(trackerUnit != null){
                        unit = trackerUnit ? 'KM' : 'Miles';
                    }
                    
                    /*Double totalDistance = businessDistance + personalDistance;
                    finalstr += '\n\n ,,,,Total Distance Travelled '+','+ personInforec.Total_Distance__c +' '+ Unit;
                    finalstr += '\n ,,,,Total Business Distance'+','+ personInforec.Total_Business_Distance__c +' '+ Unit;
                    finalstr += '\n ,,,,Total Personal Distance'+','+ personInforec.Total_Personal_Distance__c +' '+ Unit;
                    //finalstr += '\n ,,,,Business %'+','+ (totalDistance > 0 ? (businessDistance/(totalDistance))*100 : 0);
                    finalstr += '\n ,,,,Business %'+','+personInforec.Business_Percentage__c ;*/
                    
                    Double totalDistance = businessDistance + personalDistance;
                    finalstr += '\n\n ,,,,Total Distance Travelled '+','+ totalDistance +' '+ Unit;
                    finalstr += '\n ,,,,Total Business Distance'+','+ businessDistance +' '+ Unit;
                    finalstr += '\n ,,,,Total Personal Distance'+','+ personalDistance +' '+ Unit;
                    finalstr += '\n ,,,,Business %'+','+ (totalDistance > 0 ? (businessDistance/(totalDistance))*100 : 0);
                    
                    System.debug('finalstr = '+ finalstr);
                    
                    if(trvlLogBookId != null){
                        ContentVersion cv = createContentVersion(finalstr);
                        conVerToBeInserted.add(cv);
                        if(cv != null){
                            travelLogBookToCV.put(trvlLogBookId,cv);
                        }
                    }
                }                
            }
        }
        Database.update(travelLogToUpdate);
        
        if(conVerToBeInserted.size() > 0){
            Database.insert(conVerToBeInserted);
        }
        System.debug('conVerToBeInserted = '+ conVerToBeInserted);
        System.debug('travelLogBookToCV = '+ travelLogBookToCV);
        
        for(Id trvlLogBookId : travelLogBookToCV.keySet()){
            ContentVersion contentVersion = travelLogBookToCV.get(trvlLogBookId);
            if(contentVersion != null){
                cvIdTotrvlLogBookIdMap.put(contentVersion.Id, trvlLogBookId);
            }
        }
        
        for(ContentVersion contentVersion : conVerToBeInserted){
            contentVersionIds.add(contentVersion.Id);
        }
        System.debug('contentVersionIds = '+ contentVersionIds);
        
        if(contentVersionIds.size() > 0){
            createContentVersionLinks(contentVersionIds, cvIdTotrvlLogBookIdMap);
        }
        sendEmails(trvlLogBookIds,trvlIdToCountryIdMap, carChangeApprovalMap);
    }
    
    /*******************************************************************
    Method  : createContentVersionLinks
    Purpose : This method will create Content Version links with the provided
  content version records and populate Travel log book record with the 
  respective Content Version Document and Versions Id*/
    private static void createContentVersionLinks(List<Id> contentVersionIds, Map<Id, Id> cvIdTotrvlLogBookIdMap){
        
    System.debug('contentVersionIds = '+ contentVersionIds);
        System.debug('cvIdTotrvlLogBookIdMap = '+ cvIdTotrvlLogBookIdMap);
        
        if(contentVersionIds.size() > 0){
            //Used to retrieve the Content Document Id that has been created
            List<ContentVersion> lstUpdateContentVer = [SELECT ID, ContentDocumentId, VersionData FROM ContentVersion WHERE ID in :contentVersionIds];
            List<ContentDocumentLink> contentVerLinks = new List<ContentDocumentLink>();
            
            //Create the content version link depend on Content version
            for(ContentVersion contentVersion : lstUpdateContentVer){
                ContentDocumentLink conDocLnkObj = new ContentDocumentLink ();
                conDocLnkObj.LinkedEntityId = cvIdTotrvlLogBookIdMap.get(contentVersion.Id);
                conDocLnkObj.ContentDocumentId = contentVersion.ContentDocumentId;
                conDocLnkObj.shareType = 'V';
                contentVerLinks.add(conDocLnkObj);
                //System.debug('conDocLnkObj = '+ conDocLnkObj);
            }
            System.debug('contentVerLinks = '+ contentVerLinks);
            if(contentVerLinks.size() > 0){
                Database.insert(contentVerLinks);
            }
        }
    }
    
    /*******************************************************************
    Method  : createContentVersion
    Purpose : This method will create Content Version with the provided
  CSV string*/
    private static ContentVersion createContentVersion(String csvFinalString){
        
        ContentVersion contentVersion = new ContentVersion();                
        contentVersion.Title = TRAVEL_LOGBOOK_STR;
        contentVersion.PathOnClient = TRAVEL_LOGBOOK_STR + '.csv';
        contentVersion.RecordTypeId = Schema.SObjectType.ContentVersion.getRecordTypeInfosByName().get('Travel Logbook').getRecordTypeId();
        contentVersion.Content_Type__c = TRAVEL_LOGBOOK_STR;
        contentVersion.VersionData = Blob.valueOf(csvFinalString);
        contentVersion.IsMajorVersion = true;
        return contentVersion;
    }

    /*******************************************************************
    Method  : sendEmails
    Purpose : Send Emails to end users based on the content stored in
  Content Versions associated with Travel Log books */
    public static void sendEmails(Set<Id> trvlLogBookIds, Map<Id, Id> trvlIdToCountryIdMap, Map<Id,Market_Setting__c> carChangeApprovalMap){
        
        Map<Id, Messaging.Emailfileattachment> fileAttachmentMap = new Map<Id, Messaging.Emailfileattachment>();
        
        System.debug('sendEmails > trvlLogBookIds = '+ trvlLogBookIds);
        if(trvlLogBookIds.size()> 0){
            fileAttachmentMap = getAttachments(trvlLogBookIds);
            System.debug('fileAttachmentMap = '+ fileAttachmentMap);
            for(Id trvlLogId : fileAttachmentMap.keySet()){
                Messaging.Emailfileattachment emailFileAttac = fileAttachmentMap.get(trvlLogId);
                Id countryId = trvlIdToCountryIdMap.get(trvlLogId);
                System.debug('countryId = '+ countryId);                
                if(countryId != null  && carChangeApprovalMap.get(countryId) != null){
                    String emailstr =  carChangeApprovalMap.get(countryId).Fleet_Manager__c;                    
                    if(emailstr != null){
                    	List<String> emailAddress = emailstr.split(',');
                    	Boolean mailStatus = sendCsvAttachment(emailFileAttac, emailAddress);
                        travelLogMailStatusMap.put(trvlLogId, mailStatus);
                    }
                }
            }  
        }
    }
    
    /*******************************************************************
    Method  : sendCsvAttachment
    Purpose : Send Email with the help of SingleEmailMessage */
    public static Boolean sendCsvAttachment(Messaging.Emailfileattachment csvAttc, List<String> emailAddress){
        
        Boolean anyErrorOccured = false;
        try{
          Messaging.reserveMassEmailCapacity(1);
        }catch(HandledException handledEx){
            System.debug('handledEx = '+ handledEx);
            anyErrorOccured = true;
        }
        if(!anyErrorOccured){
            Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
            email.setSubject('Travel Log');
            email.setToAddresses(emailAddress);
            email.setPlainTextBody('');
            //email.setPlainTextBody('Please find the travel log attached.');
            email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
            System.debug('email = '+ email);
            Messaging.SendEmailResult[] emailResult = Messaging.sendEmail(new Messaging.SingleEmailMessage[] {email});
        }
        return anyErrorOccured;
    }
    
    /*******************************************************************
    Method  : getAttachments
    Purpose : Gets CSV content version files associated with Travel Log Books
  and to be sent with e-mail*/
    public static Map<Id, Messaging.Emailfileattachment> getAttachments(Set<Id> trvlLogBookIds){
        
        List<contentDocumentLink> cdList = new List<contentDocumentLink>();        
        List<Messaging.Emailfileattachment> fileAttachments = new List<Messaging.Emailfileattachment>();
        Map<Id, Id> codDocIdToTLId = new Map<Id, Id>();
        Map<Id, Messaging.Emailfileattachment> fileAttachmentMap = new Map<Id, Messaging.Emailfileattachment>();
        Set<ID> contentDocSet = new Set<ID>();
        
        System.debug('trvlLogBookIds = '+ trvlLogBookIds);
        
        if(trvlLogBookIds != null && Schema.sObjectType.contentDocumentLink.isAccessible()){
            cdList =  [SELECT LinkedEntityid, ContentDocumentid FROM contentDocumentLink WHERE LinkedEntityid IN :trvlLogBookIds];  
        }
        
        System.debug('cdList = '+ cdList);
        
        for(contentDocumentLink cDLink : cdList ){            
            if(!contentDocSet.Contains(cDLink.LinkedEntityid)){               
                contentDocSet.add(cDLink.ContentDocumentid);
            }else{                
                contentDocSet.add(cDLink.ContentDocumentid);
            }
            codDocIdToTLId.put(cDLink.ContentDocumentid, cDLink.LinkedEntityid);
        }
        
        System.debug('contentDocSet = '+ contentDocSet);
        
        if(contentDocSet.size() > 0){
            for (ContentVersion cversion : [SELECT title,PathOnClient,ContentDocumentId, FileType, versiondata FROM contentversion WHERE ContentDocumentId IN :contentDocSet]){            
                Messaging.Emailfileattachment emailFileAttac = new Messaging.Emailfileattachment();
                emailFileAttac.setFileName( cversion.title + '.' + cversion.FileType);
                emailFileAttac.setBody(cversion.versiondata);
                Id trvlLogId = codDocIdToTLId.get(cversion.ContentDocumentId);
                System.debug('emailFileAttac = '+ emailFileAttac);
                fileAttachmentMap.put(trvlLogId, emailFileAttac);
            }
        }
        
        return fileAttachmentMap;
    }
    
    /*******************************************************************
    Method  : markTravelLogBooksEmailSent
    Purpose : Marks for which Travel Log books e-mail has been sent*/
    public static void markTravelLogBooksEmailSent(Set<Id> travelLogBookIds){
        System.debug('markTravelLogBooksEmailSent > travelLogBookIds = '+ travelLogBookIds);
        //updating the processed Travel Log Books
        if(travelLogBookIds != null && travelLogBookIds.size() > 0 && Schema.sObjectType.Travel_Logbook__c.isUpdateable()){
            List<Travel_Logbook__c> travelLogBooks = new List<Travel_Logbook__c>();
            for(Id travelLogBkId : travelLogBookIds){
                Travel_Logbook__c travelLogBook = new Travel_Logbook__c(Id=travelLogBkId);
                travelLogBook.Reported__c = true;
                travelLogBooks.add(travelLogBook);
            }
            Database.update(travelLogBooks,false);
        }
    }
    
    public static Map<Id,Market_Setting__c> populateCarChangeApprovalMap(Map<Id,Id> personInfoCountryMap){
        Map<Id,Market_Setting__c> carChangeApprovalMap = new Map<Id,Market_Setting__c>();
        for(Market_Setting__c marketset : [SELECT Id,Car_Change_Approval__c,Display_in_Kilometer__c,Geography__c,Fleet_Manager__c, Last_Travel_Log_Date__c FROM Market_Setting__c WHERE Geography__c IN : personInfoCountryMap.values()]){
            carChangeApprovalMap.put(marketset.Geography__c,marketset);
        }
        return carChangeApprovalMap;
    }

}