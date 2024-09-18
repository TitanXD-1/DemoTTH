@isTest
public class Test_MD_FormRegistrationController {
    
    @testSetup static void setup() {
        DiageoCMS.MockupFactory.generateAcceleratorSetting();
    }
    
    
    static testMethod void getFormData(){
        List<DiageoCMS__Cluster__c> globalClusters = DiageoCMS.MockupFactory.createCluster('GlobalClusterTest', null, 1, 'ClusterRoot', 'GlobalClusterTest');
        List<DiageoCMS__Cluster__c> leafClusters = DiageoCMS.MockupFactory.createCluster('Spain', globalClusters.get(0).Id, 1, 'ClusterLeaf', 'ES');  
        leafClusters[0].Name='Spain';
        leafClusters[0].DiageoCMS__ExternalId__c='ES';
        update leafClusters;
        List<MD_FormRegistrationController.ClusterWrapper> clusters = MD_FormRegistrationController.getClusterData();
        
        DiageoCMS__Form__c form = new DiageoCMS__Form__c(name='ES_Registration', DiageoCMS__ExternalID__c='ES_Registration', DiageoCMS__RetrievalClass__c='testRetrieval', DiageoCMS__Status__c='Active', DiageoCMS__Cluster__c = leafClusters.get(0).Id);
        insert form;
        DiageoCMS__FormSection__c formSection = new DiageoCMS__FormSection__c(name='testSection', DiageoCMS__SectionTitle__c='testSection', DiageoCMS__ExternalID__c='testSection', DiageoCMS__Form__c=form.id);
        insert formSection;
        DiageoCMS__FormValidation__c formValidation = new DiageoCMS__FormValidation__c(name='testVal', DiageoCMS__errormessage__c= '');
        insert formValidation;
        DiageoCMS__FormElement__c formField = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField', DiageoCMS__ExternalID__c='testField', DiageoCMS__FieldAPIName__c='Name', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                            DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        DiageoCMS__FormElement__c formField2 = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField2', DiageoCMS__ExternalID__c='testField2', DiageoCMS__FieldAPIName__c='lastModifiedDate', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                             DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        insert new List<DiageoCMS__FormElement__c>{formField, formField2};
        Test.startTest();
        DiageoCMS.GeneralForm form2 = MD_FormRegistrationController.getFormData('ES', clusters[0].ClusterId);
        Test.stopTest();
        System.assertNotEquals(null, form2);
    }
    
    static testMethod void getAdditionalFormData(){
        List<DiageoCMS__Cluster__c> globalClusters = DiageoCMS.MockupFactory.createCluster('GlobalClusterTest', null, 1, 'ClusterRoot', 'GlobalClusterTest');
        List<DiageoCMS__Cluster__c> leafClusters = DiageoCMS.MockupFactory.createCluster('Spain', globalClusters.get(0).Id, 1, 'ClusterLeaf', 'ES');  
        leafClusters[0].Name='Spain';
        leafClusters[0].DiageoCMS__ExternalId__c='ES';
        update leafClusters;
        List<MD_FormRegistrationController.ClusterWrapper> clusters = MD_FormRegistrationController.getClusterData();
        
        DiageoCMS__Form__c form = new DiageoCMS__Form__c(name='ES_Registration_additionalinformation', DiageoCMS__ExternalID__c='ES_Registration_additionalinformation', DiageoCMS__RetrievalClass__c='testRetrieval', DiageoCMS__Status__c='Active', DiageoCMS__Cluster__c = leafClusters.get(0).Id);
        insert form;
        DiageoCMS__FormSection__c formSection = new DiageoCMS__FormSection__c(name='testSection', DiageoCMS__SectionTitle__c='testSection', DiageoCMS__ExternalID__c='testSection', DiageoCMS__Form__c=form.id);
        insert formSection;
        DiageoCMS__FormValidation__c formValidation = new DiageoCMS__FormValidation__c(name='testVal', DiageoCMS__errormessage__c= '');
        insert formValidation;
        DiageoCMS__FormElement__c formField = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField', DiageoCMS__ExternalID__c='testField', DiageoCMS__FieldAPIName__c='Name', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                            DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        DiageoCMS__FormElement__c formField2 = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField2', DiageoCMS__ExternalID__c='testField2', DiageoCMS__FieldAPIName__c='lastModifiedDate', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                             DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        insert new List<DiageoCMS__FormElement__c>{formField, formField2};
        Test.startTest();
        DiageoCMS.GeneralForm form2 = MD_FormRegistrationController.getAdditionalFormData('ES', clusters[0].ClusterId);
        Test.stopTest();
        System.assertNotEquals(null, form2);
    }
    
    
    static testMethod void saveContact(){
        List<DiageoCMS__Cluster__c> globalClusters = DiageoCMS.MockupFactory.createCluster('GlobalClusterTest', null, 1, 'ClusterRoot', 'GlobalClusterTest');
        List<DiageoCMS__Cluster__c> leafClusters = DiageoCMS.MockupFactory.createCluster('Spain', globalClusters.get(0).Id, 1, 'ClusterLeaf', 'ES');  
        leafClusters[0].Name='Spain';
        leafClusters[0].DiageoCMS__ExternalId__c='ES';
        update leafClusters;
        
        DiageoCMS__Form__c form = new DiageoCMS__Form__c(name='ES_Registration', DiageoCMS__ExternalID__c='ES_Registration', DiageoCMS__RetrievalClass__c='testRetrieval',DiageoCMS__SaveClass__c='testSaveClass', DiageoCMS__Status__c='Active', DiageoCMS__Cluster__c = leafClusters.get(0).Id);
        insert form;
        DiageoCMS__FormSection__c formSection = new DiageoCMS__FormSection__c(name='testSection', DiageoCMS__SectionTitle__c='testSection', DiageoCMS__ExternalID__c='testSection', DiageoCMS__Form__c=form.id);
        insert formSection;
        DiageoCMS__FormValidation__c formValidation = new DiageoCMS__FormValidation__c(name='testVal', DiageoCMS__errormessage__c= '');
        insert formValidation;
        DiageoCMS__FormElement__c formField = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField', DiageoCMS__ExternalID__c='testField', DiageoCMS__FieldAPIName__c='Name', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                            DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        DiageoCMS__FormElement__c formField2 = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField2', DiageoCMS__ExternalID__c='testField2', DiageoCMS__FieldAPIName__c='lastModifiedDate', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                             DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        insert new List<DiageoCMS__FormElement__c>{formField, formField2};
            
        DiageoCMS.GeneralForm form2 = MD_FormRegistrationController.getFormData('ES', leafClusters[0].Id);
        
        Account ac = new Account(Name='TestAccount');
        Contact con = new Contact(Email='TestContact', Mobile__c='+34123123', MobilePrefix__c= '+34');
        MD_GeneralFormWrapper.FormSettings form3 = new  MD_GeneralFormWrapper.FormSettings(form2.FormSettings);
        Test.startTest();
        DiageoCMS.FormResponseWrapper response = MD_FormRegistrationController.saveContact(JSON.serialize(form3), JSON.serialize(con), JSON.serialize(ac), 'ES');
        Test.stopTest();
    }
    
    static testMethod void saveContactExtended(){
        List<DiageoCMS__Cluster__c> globalClusters = DiageoCMS.MockupFactory.createCluster('GlobalClusterTest', null, 1, 'ClusterRoot', 'GlobalClusterTest');
        List<DiageoCMS__Cluster__c> leafClusters = DiageoCMS.MockupFactory.createCluster('Spain', globalClusters.get(0).Id, 1, 'ClusterLeaf', 'ES');  
        leafClusters[0].Name='Spain';
        leafClusters[0].DiageoCMS__ExternalId__c='ES';
        update leafClusters;
        
        DiageoCMS__Form__c form = new DiageoCMS__Form__c(name='ES_Registration', DiageoCMS__ExternalID__c='ES_Registration', DiageoCMS__RetrievalClass__c='testRetrieval',DiageoCMS__SaveClass__c='testSaveClass', DiageoCMS__Status__c='Active', DiageoCMS__Cluster__c = leafClusters.get(0).Id);
        insert form;
        DiageoCMS__FormSection__c formSection = new DiageoCMS__FormSection__c(name='testSection', DiageoCMS__SectionTitle__c='testSection', DiageoCMS__ExternalID__c='testSection', DiageoCMS__Form__c=form.id);
        insert formSection;
        DiageoCMS__FormValidation__c formValidation = new DiageoCMS__FormValidation__c(name='testVal', DiageoCMS__errormessage__c= '');
        insert formValidation;
        DiageoCMS__FormElement__c formField = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField', DiageoCMS__ExternalID__c='testField', DiageoCMS__FieldAPIName__c='Name', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                            DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        DiageoCMS__FormElement__c formField2 = new DiageoCMS__FormElement__c(DiageoCMS__formvalidation__c = formValidation.id, name='testField2', DiageoCMS__ExternalID__c='testField2', DiageoCMS__FieldAPIName__c='lastModifiedDate', DiageoCMS__FieldLabel__c='testField', DiageoCMS__FieldType__c='Text', DiageoCMS__FormSection__c=formSection.id, DiageoCMS__Status__c='Active',
                                                                             DiageoCMS__HelpText__c='testField', DiageoCMS__ObjectAPIName__c='Account');
        insert new List<DiageoCMS__FormElement__c>{formField, formField2};
            
        DiageoCMS.GeneralForm form2 = MD_FormRegistrationController.getFormData('ES', leafClusters[0].Id);
        
        Account ac = new Account(Name='TestAccount');
        Contact con = new Contact(Email='TestContact', Mobile__c='+34123123', MobilePrefix__c = '+34');
        MD_GeneralFormWrapper.FormSettings form3 = new  MD_GeneralFormWrapper.FormSettings(form2.FormSettings);
        Test.startTest();
        DiageoCMS.FormResponseWrapper response = MD_FormRegistrationController.saveContactExtended(JSON.serialize(form3), JSON.serialize(con), JSON.serialize(ac),'1234', 'ES');
        Test.stopTest();
    }
    
    
    
}