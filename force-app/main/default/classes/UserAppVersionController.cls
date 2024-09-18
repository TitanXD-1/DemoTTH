public class UserAppVersionController {
    public List<UserApp_Sync_Version__c> AppVersionSalesList {get;set;}
    public List<UserApp_Sync_Version__c> AppVersionListQuality {get;set;}
    public List<UserApp_Sync_Version__c> AppVersionListAndroidSales {get;set;}
    
    public  UserAppVersionController()
    {
    /*
    //Initializing variables         
    Integer activeUserCount=0;
    Integer activeUserLatestVersion =0;  
    Integer activeUser=0;
    Integer TotalNumberOfUser=0; 
    Integer TotalActiveUser=0; 
    Integer count=0;
    Integer activeUserLogin=0;
    Integer userCount=0;
    decimal per =0.0;    
    
    //Initializing Maps    
    Map<String,Integer> usercountMap = new Map<String,Integer>();
    Map<String,Integer> latestAppMap = new Map<String,Integer>();
    Map<String,String> countryCodeMap = new Map<String,String>();
    
    //Creating Map for Country name and its country code    
    Schema.DescribeSObjectResult objSchema = User.sObjectType.getDescribe();
	Map<String, Schema.SObjectField> fieldMap = objSchema.fields.getmap();
	List<Schema.Picklistentry> fld =fieldmap.get('Available_Countries__c').getDescribe().getpicklistValues();
    for(Schema.Picklistentry pl : fld)
	{
        if(!countryCodeMap.containskey(pl.getValue()))
        {
   			 countryCodeMap.put(pl.getValue(),pl.getLabel());
                   	
        }
	}
    
    
    //Extracting Latest App Version and Latest Release Date from custom setting     
    AppVersionList= new List<AppWrpClass>();
    UserAppVersionSetting__c uavs= UserAppVersionSetting__c.getOrgDefaults();
    Datetime dt = uavs.LatestReleaseDate__c;
    String latestAppVersion=uavs.Latest_App_Version__c;
        
    
    List<Id> UserID = new List<Id>();
   	//Querying list of user's who are active and have profile as Sales Rep or Sales Manager
   	List<User> UserList= [SELECT Id,Available_Countries__c,IsActive,Profile.Name,Default_Country__c  FROM User where Profile.Name like '%Sales%' and IsActive=true];
        
    //Creating User and Country Map to identify their markets   
    Map<Id,String> userCountryMap =new  Map<Id,String>();
	for(User u:UserList)
    {
        if(userCountryMap.containsKey(u.Id)==false)
        {
            if(u.Default_Country__c != null)
                userCountryMap.put(u.Id, u.Default_Country__c);
            else
            	userCountryMap.put(u.Id, u.Available_Countries__c);
        }
    }
     System.debug('userCountryMap#'+userCountryMap);
    //Extracting List of user and the app version they are using     
    List<AggregateResult> syncList2 =[Select max(CreatedDate) createdDate,OwnerId ownerId, max(Version_Sync__c) versionSync, Owner.Name ownerName  from Sync_Stat__c where createdDate>:dt and OwnerId IN:UserList group by OwnerId,Owner.Name ];
    System.debug('SyncList#2 size'+ syncList2.size());
        
        //Checking if the user is on latest app version or not for calculating percentage later
        if(!syncList2.isEmpty() && syncList2!= null){
            for(AggregateResult ar : syncList2)
            {
                System.debug('SyncList#2'+ ar);
                String cc=userCountryMap.get((Id)(ar.get('ownerId'))); 
                Id user=(ID)ar.get('ownerId');
                String maxVersion=(String)ar.get('versionSync');
               
                //checking if user is on latest app version
                if(maxVersion.equals(latestAppVersion))
                {
                    if(!latestAppMap.containskey(cc))
                    latestAppMap.put(cc,1);
               		 else
               		 {
                    activeUserLatestVersion=latestAppMap.get(cc)+1;
                    latestAppMap.put(cc,activeUserLatestVersion); 
                	}
                }
                
                //checking if user synced after release of latest app version
                if(!usercountMap.containskey(cc))
                    usercountMap.put(cc,1);
                else
                {
                    activeUserCount=usercountMap.get(cc)+1;
                    usercountMap.put(cc,activeUserCount); 
                }
            }
        }
        
 
        //Calculating percentage of user using Latest App Version country wise
        for(String keyId: usercountMap.keyset())
        {
            if(latestAppMap.keyset().contains(keyId))
            {
                 TotalNumberOfUser=usercountMap.get(keyId); //Total number of Active users
                 TotalActiveUser=latestAppMap.get(keyId); //Total number of Active user on latest App Version
                 per=(TotalActiveUser*100)/TotalNumberOfUser;
          		String countryName=countryCodeMap.get(keyId);
                
                System.debug('Country counts '+countryName+' '+ TotalNumberOfUser+' '+TotalActiveUser);
                AppVersionList.add(new AppWrpClass(countryName,latestAppVersion,TotalNumberOfUser,per));
                
            }
            else if(!latestAppMap.keyset().contains(keyId))
            {
                
                 TotalNumberOfUser=usercountMap.get(keyId); //Total number of Active users
                 TotalActiveUser=0; //Total number of Active user on latest App Version
                 per=(TotalActiveUser*100)/TotalNumberOfUser;
          		String countryName=countryCodeMap.get(keyId);
                System.debug('Country counts '+countryName+' '+ TotalNumberOfUser+' '+TotalActiveUser);
                AppVersionList.add(new AppWrpClass(countryName,latestAppVersion,TotalNumberOfUser,per));
            }
        }
        */
        
        AppVersionSalesList = [Select App_Version__c,Country__c,Platform__c,Type__c,Unique_Key__c,Users_Synced__c,Users_Synced_Percent__c from UserApp_Sync_Version__c where Unique_Key__c Like '%Sales_iOS'];
        AppVersionListQuality =[Select App_Version__c,Country__c,Platform__c,Type__c,Unique_Key__c,Users_Synced__c,Users_Synced_Percent__c from UserApp_Sync_Version__c where Unique_Key__c Like  '%Quality%'];
		AppVersionListAndroidSales = [Select App_Version__c,Country__c,Platform__c,Type__c,Unique_Key__c,Users_Synced__c,Users_Synced_Percent__c from UserApp_Sync_Version__c where Unique_Key__c Like '%Sales_Android'];
    }
    
    
    /*
    	//method to send csv with user not on latest app version
        public static Blob sendEmailAttach()
        {
            
            UserAppVersionSetting__c uavs= UserAppVersionSetting__c.getOrgDefaults();
   			Datetime dt = uavs.LatestReleaseDate__c;
    		String latestAppVersion=uavs.Latest_App_Version__c;
            
            List<WrpClass> UserResult = new  List<WrpClass>();
            
            List<User> UserList= [SELECT Id,Available_Countries__c,IsActive,Profile.Name  FROM User where Profile.Name like '%Sales%' and IsActive=true];
            UserList= [SELECT Id,Available_Countries__c,IsActive,Profile.Name  FROM User where Profile.Name like '%Sales%' and IsActive=true];
            //Extracting user who are not using latest app version after the Latest Release
            List<AggregateResult> syncList =[Select max(CreatedDate) createdDate,OwnerId ownerId, max(Version_Sync__c) versionSync, Owner.Name ownerName  from Sync_Stat__c where createdDate>:dt and OwnerId IN:UserList  group by OwnerId,Owner.Name];
            System.debug('SyncList#1 size'+ syncList.size());
            
            //Creating User and Country Map to identify their markets
            Map<Id,String> userCountryMap =new  Map<Id,String>();
			for(User u:UserList)
    		{
       			 if(userCountryMap.containsKey(u.Id)==false)
        		{
            		 userCountryMap.put(u.Id, u.Available_Countries__c);
        		}
    		}

            if(!syncList.isEmpty() && syncList!= null){
            for(AggregateResult ar : syncList)
            {
                String userMaxVersion=(String)ar.get('versionSync');
                if(!userMaxVersion.equals(latestAppVersion))
                {
                	System.debug('SyncList#1'+ syncList);
                	String cc=userCountryMap.get((Id)(ar.get('ownerId'))); 
                	UserResult.add(new WrpClass(ar,cc));
                }
                
            }
       	 }
		
        System.debug('Users'+UserResult);
            
        //Creation of CSV file    
        String csvFileString = Label.AppVersionHeading+'\n';
        if(UserResult.size()>0)
        {
            for(WrpClass row:UserResult)
            {
                csvFileString+=row.OwnerId+','+row.OwnerName+','+row.VersionSync+','+row.CreatedDate+','+row.Country+'\n';
            }
        }
        
        
           
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(csvFileString );
        return csvBlob ;
        }
    	*/
        /*public static Blob sendEmailAttachment(Map<Id,String> UserAppVersionMap,String latestAppVersion,String latestAndroidAppVersion,Map<Id,String> userCountryMap,Map<Id,String> UserNameMap,Map<Id,Datetime> UserAppSyncDateMap)
        {
            /*
            UserAppVersionSetting__c uavs= UserAppVersionSetting__c.getOrgDefaults();
   			Datetime dt = uavs.LatestReleaseDate__c;
    		String latestAppVersion=uavs.Latest_App_Version__c;
            
            List<WrpClass> UserResult = new  List<WrpClass>();
            
            List<User> UserList= [SELECT Id,Available_Countries__c,IsActive,Profile.Name  FROM User where Profile.Name like '%Sales%' and IsActive=true];
            UserList= [SELECT Id,Available_Countries__c,IsActive,Profile.Name  FROM User where Profile.Name like '%Sales%' and IsActive=true];
            //Extracting user who are not using latest app version after the Latest Release
            List<AggregateResult> syncList =[Select max(CreatedDate) createdDate,OwnerId ownerId, max(Version_Sync__c) versionSync, Owner.Name ownerName  from Sync_Stat__c where createdDate>:dt and OwnerId IN:UserList  group by OwnerId,Owner.Name];
            System.debug('SyncList#1 size'+ syncList.size());
            
            //Creating User and Country Map to identify their markets
            Map<Id,String> userCountryMap =new  Map<Id,String>();
			for(User u:UserList)
    		{
       			 if(userCountryMap.containsKey(u.Id)==false)
        		{
            		 userCountryMap.put(u.Id, u.Available_Countries__c);
        		}
    		}

            if(!syncList.isEmpty() && syncList!= null){
            for(AggregateResult ar : syncList)
            {
                String userMaxVersion=(String)ar.get('versionSync');
                if(!userMaxVersion.equals(latestAppVersion))
                {
                	System.debug('SyncList#1'+ syncList);
                	String cc=userCountryMap.get((Id)(ar.get('ownerId'))); 
                	UserResult.add(new WrpClass(ar,cc));
                }
                
            }
       	 }
            Map<Id,String> latestAppMap = new Map<Id,String>();
            Map<Id,String> allAppMap = new Map<Id,String>();
            List<Id> usrIDlist = new List<Id>();
            for(String usr : UserAppVersionMap.keyset()){
                if(UserAppVersionMap.get(usr)==latestAppVersion || UserAppVersionMap.get(usr)==latestAndroidAppVersion){
                    latestAppMap.put(usr, UserAppVersionMap.get(usr));
                }
                else{
                    allAppMap.put(usr, UserAppVersionMap.get(usr));
                }
            }
            
            for(String usr : allAppMap.keyset()){
                system.debug('usr-'+userCountryMap.get(usr));
                if(!latestAppMap.keyset().contains(usr) && !usrIDlist.contains(usr)){
                    UserResult.add(new WrpClass(usr,UserNameMap.get(usr),UserAppVersionMap.get(usr),UserAppSyncDateMap.get(usr),userCountryMap.get(usr)));
                    usrIDlist.add(usr);
                    }
                }
         
        System.debug('Users'+UserResult);
            
        //Creation of CSV file    
        String csvFileString = Label.AppVersionHeading+'\n';
        if(UserResult.size()>0)
        {
            for(WrpClass row:UserResult)
            {
                csvFileString+=row.OwnerId+','+row.OwnerName+','+row.VersionSync+','+row.CreatedDate+','+row.Country+'\n';
            }
        }
        
           
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(csvFileString );
        return csvBlob ;
        }*/

    public static Blob sendEmailAttachment(Map<Id,EDGE_UserAppSyncVersionBatch.UserWrapper> UserWrapperMap, String latestAppVersion,String latestAndroidAppVersion)
        {
            Map<Id,String> latestAppMap = new Map<Id,String>();
            Map<Id,String> allAppMap = new Map<Id,String>();
            List<Id> usrIDlist = new List<Id>();
            List<EDGE_UserAppSyncVersionBatch.UserWrapper> listToUpdate = new List<EDGE_UserAppSyncVersionBatch.UserWrapper>();
            
            for(String usr : UserWrapperMap.keySet()){
                EDGE_UserAppSyncVersionBatch.UserWrapper usrObj = UserWrapperMap.get(usr);
                if(usrObj.VersionSync == latestAppVersion || usrObj.VersionSync == latestAndroidAppVersion){
                    latestAppMap.put(usrObj.OwnerId,usrObj.VersionSync);
                }
                else{
                    if(!latestAppMap.containskey(usrObj.OwnerId)){
                        listToUpdate.add(usrObj);
                    }
                }
            }
            
        //Creation of CSV file    
        String csvFileString = Label.AppVersionHeading+'\n';
        if(listToUpdate.size()>0)
        {
            for(EDGE_UserAppSyncVersionBatch.UserWrapper row: listToUpdate)
            {
                csvFileString+=row.OwnerId+','+row.OwnerName+','+row.VersionSync+','+row.CreatedDate+','+row.Country+'\n';
            }
        }
        
           
        Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
        blob csvBlob = Blob.valueOf(csvFileString );
        return csvBlob ;
        }
    
    
    public static void sendEmail(blob getcsvBlob){
        try{
            //Get Email Id from Custom Setting
            
            UserAppVersionSetting__c userappversionSetting = UserAppVersionSetting__c.getOrgDefaults();
            
            
            //Get Email Template
            EmailTemplate emailTemplate = [select Id, Body from EmailTemplate where DeveloperName = 'App_Version_Status_Template'];
            
            //Set Subject
            string emailSubject = 'Market App Version Details' + ' - ' + Date.Today().format();
            
            
            
            if(userappversionSetting != null){
                List<string> emailIds = new List<string>();
                string tempStr = '';
                if(userappversionSetting.Email__c != null && userappversionSetting.Email__c != '')
                    tempStr += userappversionSetting.Email__c;
                
                if(userappversionSetting.Email1__c != null && userappversionSetting.Email1__c != '')
                    tempStr += userappversionSetting.Email1__c;
                
                //Creating Email Ids List
                if(tempStr != '')
                    emailIds = tempStr.split(';');
                //Email
                if(emailIds.size()>0){
                    //Newly Added
                    Messaging.EmailFileAttachment csvAttc = new Messaging.EmailFileAttachment();
                    blob csvBlob = getcsvBlob;
                    string csvname= 'Users Not On Latest Version.csv';
                    csvAttc.setFileName(csvname);
                    csvAttc.setBody(csvBlob);
                    Messaging.SingleEmailMessage email = new Messaging.SingleEmailMessage();
                    email.setToAddresses(emailIds);
                    email.setTemplateId(emailTemplate.Id);
                    email.setTargetObjectId(UserInfo.getUserId());
                    email.saveAsActivity = false;
                    email.setFileAttachments(new Messaging.EmailFileAttachment[]{csvAttc});
                    Messaging.SingleEmailMessage[] messages = new List<Messaging.SingleEmailMessage> {email};
                        Messaging.SendEmailResult[] results = Messaging.sendEmail(messages);
                    if (results[0].success) {
                        system.debug('@@Email has been sent successfully');
                        EDGE_UtilityClass.printGovLimits(48);
                    }
                    else {
                        system.debug('@@Email failed to send: ' + results[0].errors[0].message);
                    }
                }
            }
        }
        catch(Exception ex){
            system.debug('@@Exception' + ex);
        }	
        
    }
    /*	
     public class WrpClass{
        public Id OwnerId{ get;set; }
        public String OwnerName{ get;set; }
        public String VersionSync{ get;set; }
        public Datetime CreatedDate{ get;set; }
        public String Country{ get;set; }
        
         public WrpClass(String id,String name,String SyncVersion,Datetime dt,String CountryCode){
             OwnerId = id;
        	OwnerName = name;
            VersionSync = SyncVersion;
       		CreatedDate = dt;
        	Country = CountryCode;
         }
     } */
        /*
        public WrpClass(AggregateResult ar,String Country) {
      		OwnerId = (Id)ar.get('ownerId');
            OwnerName=(String)ar.get('ownerName');
            VersionSync = (String)ar.get('versionSync');
            CreatedDate = (Datetime)ar.get('createdDate');
            this.Country=Country;
            
        }
     }
        Public class AppWrpClass{
        public string Country{get;set;}
        public string app{get;set;}
        public string platform{get;set;}
        public string latestappVersion1{get;set;}
        public Integer activeUserLogin{get;set;}
        public decimal per1{get;set;}
        
        
        Public AppWrpClass(string Country1,string latestappVersion1,integer activeUserLogin1,decimal per1)
        {
            this.Country = Country1;
            this.app ='EDGE 365';
            this.platform='iOS';
            this.latestappVersion1=latestappVersion1;
            this.activeUserLogin=activeUserLogin1;
            this.per1=per1;
        }
    }*/

}