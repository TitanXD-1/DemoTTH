@isTest
public class MD_FeatureController_Test {
    
    testmethod private static void getFeatureTest() {
        
        
        Map<String, DiageoCMS__Cluster__c> clusters = TestFactory_MD_Cluster_c.createTestClusterStructure();
        
        DiageoCMS__Content__c conObj = new DiageoCMS__Content__c();
        conObj.Name = 'ES_LoginBanner1';
        conObj.DiageoCMS__BannerFrameType__c = 'Custom';
        conObj.DiageoCMS__Title__c = 'Bienvenido a MYDIAGEO';
        conObj.DiageoCMS__Extract__c = 'Aquí podrás encontrar todo el contenido acerca de nuestros productos.';
        insert conObj;
        
        DiageoCMS__Component__c comObj = new DiageoCMS__Component__c();
        comObj.DiageoCMS__ExternalId__c = 'ComponentTest1';
        comObj.DiageoCMS__Title__c = 'Title ComponentTest1';
        comObj.DiageoCMS__Cluster__c = clusters.get('ClusterRoot').Id;
        comObj.DiageoCMS__CustomHeight__c = 100;
        comObj.RecordTypeId = Schema.SObjectType.DiageoCMS__Component__c.getRecordTypeInfosByDeveloperName().get('Banner').getRecordTypeId();
        insert comObj;
        
        DiageoCMS__ContentAssignment__c conAssignObj = new DiageoCMS__ContentAssignment__c();
        conAssignObj.DiageoCMS__Content__c = conObj.id;
        conAssignObj.DiageoCMS__Component__c = comObj.id;
        insert conAssignObj;
        
        DiageoCMS__Tag__c TagRecords = new DiageoCMS__Tag__c();
        TagRecords.Name = 'test Tag';
        TagRecords.DiageoCMS__ExternalId__c = 'ES_Test_Tag';
        TagRecords.DiageoCMS__Status__c = 'Active';
        
        insert TagRecords;
        
        DiageoCMS__TagAssignment__c TagAssign = new DiageoCMS__TagAssignment__c();
        TagAssign.DiageoCMS__Component__c = comObj.Id;
        TagAssign.DiageoCMS__Tag__c = TagRecords.Id;  
        insert TagAssign;
        
        DiageoCMS__TagAssignment__c TagAssignCon = new DiageoCMS__TagAssignment__c();
        TagAssignCon.DiageoCMS__Content__c = conObj.Id;
        TagAssignCon.DiageoCMS__Tag__c = TagRecords.Id;  
        insert TagAssignCon;
        
        DiageoCMS__MediaElement__c createMediaElement = new DiageoCMS__MediaElement__c();
        createMediaElement.Name = 'Test Media';
        createMediaElement.DiageoCMS__ExternalId__c = 'Test_Media';
        createMediaElement.DiageoCMS__Status__c = 'Active';
        createMediaElement.DiageoCMS__FileURLDesktop__c = 'https://edge--edgedev3--c.documentforce.com/sfc/dist/version/download/?oid=00D6E0000004yyL&ids=0686E000000hFdR&d=%2Fa%2F6E000000Ct3h%2Fg7XwcwPxBJ4k2LVA3f7hZHcv8BNQeLJpX3PZS7xDg4k&asPdf=false';
        createMediaElement.DiageoCMS__FileURLMobile__c = 'https://edge--edgedev3--c.documentforce.com/sfc/dist/version/download/?oid=00D6E0000004yyL&ids=0686E000000hFdI&d=%2Fa%2F6E000000Ct3e%2F7obnlo2uQhCuNJdw1RBKaguJ9gK2oD_KdgYkVBoBdm0&asPdf=false';
        createMediaElement.DiageoCMS__FileURLTablet__c = 'https://edge--edgedev3--c.documentforce.com/sfc/dist/version/download/?oid=00D6E0000004yyL&ids=0686E000000hFdH&d=%2Fa%2F6E000000Ct3d%2FbV9KKsmsDXhZ4wE272vAirckme_rDM_o8e9zmj.jecw&asPdf=false';
        Insert createMediaElement;
        
        DiageoCMS__MediaElementAssignment__c CreateMediaElementAssignment = new DiageoCMS__MediaElementAssignment__c();
        CreateMediaElementAssignment.DiageoCMS__Content__c = conObj.Id;
        CreateMediaElementAssignment.DiageoCMS__ExternalId__c = 'Test_Media_Element_Assignment';
        CreateMediaElementAssignment.DiageoCMS__MediaElement__c = createMediaElement.Id;
        Insert CreateMediaElementAssignment;
       
        List<MD_Feature__c > featureLst = new List<MD_Feature__c >();
        
        MD_Feature__c  feaObj = new MD_Feature__c ();
        feaObj.Content__c = conObj.id;
        feaObj.Feature_Description__c = 'Test';
        feaObj.Feature_Icon__c = 'far fa-chart-line fa-3x';
        feaObj.Feature_Title__c = 'Acceda a excelente contenido para hacer crecer su negocio';
        feaObj.Order__c = 1;
        insert feaObj;

        featureLst.add(feaObj); 
        MD_FeatureController featureObj = new MD_FeatureController();
        MD_BannerDisplayController BannerDisplay = new MD_BannerDisplayController();
        Test.startTest();
        MD_FeatureController.getFeature(comObj.DiageoCMS__ExternalId__c);
        MD_BannerDisplayController.GetimageDetails(comObj.DiageoCMS__ExternalId__c,'DESKTOP');
        MD_BannerDisplayController.GetimageDetails(comObj.DiageoCMS__ExternalId__c,'PHONE');
        MD_BannerDisplayController.GetimageDetails(comObj.DiageoCMS__ExternalId__c,'TABLET');
        MD_BannerDisplayController.getCustomHeight(comObj.DiageoCMS__ExternalId__c);
        
        Test.stopTest();
        
    }
    
}